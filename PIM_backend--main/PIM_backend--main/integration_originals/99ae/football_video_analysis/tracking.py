from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

from .models import BBox, Detection, TrackedObject


def bbox_iou(a: BBox, b: BBox) -> float:
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    ix1 = max(ax1, bx1)
    iy1 = max(ay1, by1)
    ix2 = min(ax2, bx2)
    iy2 = min(ay2, by2)
    iw = max(0.0, ix2 - ix1)
    ih = max(0.0, iy2 - iy1)
    inter = iw * ih
    if inter <= 0:
        return 0.0
    a_area = max(0.0, ax2 - ax1) * max(0.0, ay2 - ay1)
    b_area = max(0.0, bx2 - bx1) * max(0.0, by2 - by1)
    denom = a_area + b_area - inter
    return inter / denom if denom > 0 else 0.0


def bbox_center(b: BBox) -> Tuple[float, float]:
    x1, y1, x2, y2 = b
    return ((x1 + x2) / 2.0, (y1 + y2) / 2.0)


def bbox_footpoint(b: BBox) -> Tuple[float, float]:
    x1, _y1, x2, y2 = b
    return ((x1 + x2) / 2.0, y2)


def euclidean(a: Tuple[float, float], b: Tuple[float, float]) -> float:
    dx = a[0] - b[0]
    dy = a[1] - b[1]
    return (dx * dx + dy * dy) ** 0.5


@dataclass
class _TrackState:
    track_id: int
    bbox: BBox
    confidence: float
    class_name: str
    last_seen_frame: int
    center: Tuple[float, float]
    footpoint: Tuple[float, float]
    velocity_px_s: Tuple[float, float] = (0.0, 0.0)
    speed_px_s: float = 0.0
    hits: int = 1


class IoUTracker:
    def __init__(
        self,
        class_name: str,
        max_age_frames: int,
        min_iou: float,
        max_center_distance_px: float,
        start_track_id: int = 1,
    ) -> None:
        self.class_name = class_name
        self.max_age_frames = max_age_frames
        self.min_iou = min_iou
        self.max_center_distance_px = max_center_distance_px
        self._tracks: Dict[int, _TrackState] = {}
        self._next_track_id = start_track_id

    def _prune(self, frame_index: int) -> None:
        stale_ids = [
            tid
            for tid, track in self._tracks.items()
            if frame_index - track.last_seen_frame > self.max_age_frames
        ]
        for tid in stale_ids:
            del self._tracks[tid]

    def update(
        self,
        detections: List[Detection],
        frame_index: int,
        fps: float,
    ) -> List[TrackedObject]:
        self._prune(frame_index)

        candidates = [d for d in detections if d.class_name == self.class_name]
        track_ids = list(self._tracks.keys())
        unmatched_track_ids = set(track_ids)
        unmatched_detection_ids = set(range(len(candidates)))
        matches: List[Tuple[int, int]] = []

        scored_pairs: List[Tuple[float, int, int]] = []
        for det_idx, det in enumerate(candidates):
            det_center = det.center
            for track_id in track_ids:
                track = self._tracks[track_id]
                iou = bbox_iou(track.bbox, det.bbox)
                if iou < self.min_iou:
                    continue
                dist = euclidean(track.center, det_center)
                if dist > self.max_center_distance_px:
                    continue
                # Greedy score: IoU dominates, distance is a tie-breaker.
                score = iou - (dist / max(1.0, self.max_center_distance_px)) * 0.15
                scored_pairs.append((score, det_idx, track_id))

        scored_pairs.sort(reverse=True, key=lambda x: x[0])
        for _score, det_idx, track_id in scored_pairs:
            if det_idx not in unmatched_detection_ids or track_id not in unmatched_track_ids:
                continue
            matches.append((det_idx, track_id))
            unmatched_detection_ids.remove(det_idx)
            unmatched_track_ids.remove(track_id)

        for det_idx, track_id in matches:
            det = candidates[det_idx]
            track = self._tracks[track_id]
            prev_center = track.center
            frame_delta = max(1, frame_index - track.last_seen_frame)
            cx, cy = det.center
            vx = (cx - prev_center[0]) * fps / frame_delta
            vy = (cy - prev_center[1]) * fps / frame_delta
            speed = (vx * vx + vy * vy) ** 0.5
            track.bbox = det.bbox
            track.confidence = det.confidence
            track.last_seen_frame = frame_index
            track.center = det.center
            track.footpoint = det.footpoint
            track.velocity_px_s = (vx, vy)
            track.speed_px_s = speed
            track.hits += 1

        for det_idx in sorted(unmatched_detection_ids):
            det = candidates[det_idx]
            track_id = self._next_track_id
            self._next_track_id += 1
            self._tracks[track_id] = _TrackState(
                track_id=track_id,
                bbox=det.bbox,
                confidence=det.confidence,
                class_name=det.class_name,
                last_seen_frame=frame_index,
                center=det.center,
                footpoint=det.footpoint,
            )

        visible_tracks: List[TrackedObject] = []
        for track in self._tracks.values():
            if track.last_seen_frame != frame_index:
                continue
            visible_tracks.append(
                TrackedObject(
                    track_id=track.track_id,
                    class_name=track.class_name,
                    confidence=track.confidence,
                    bbox=track.bbox,
                    center=track.center,
                    footpoint=track.footpoint,
                    velocity_px_s=track.velocity_px_s,
                    speed_px_s=track.speed_px_s,
                )
            )
        return visible_tracks


class DetectionTracker:
    def __init__(
        self,
        player_max_age_frames: int = 25,
        ball_max_age_frames: int = 8,
    ) -> None:
        self.player_tracker = IoUTracker(
            class_name="player",
            max_age_frames=player_max_age_frames,
            min_iou=0.1,
            max_center_distance_px=140.0,
        )
        self.ball_tracker = IoUTracker(
            class_name="ball",
            max_age_frames=ball_max_age_frames,
            min_iou=0.0,
            max_center_distance_px=180.0,
        )

    def update(
        self,
        detections: List[Detection],
        frame_index: int,
        fps: float,
    ) -> Tuple[List[TrackedObject], Optional[TrackedObject]]:
        players = self.player_tracker.update(detections, frame_index, fps)
        balls = self.ball_tracker.update(detections, frame_index, fps)
        ball = None
        if balls:
            balls.sort(key=lambda b: (b.confidence, -b.speed_px_s), reverse=True)
            ball = balls[0]
        players.sort(key=lambda p: p.track_id)
        return players, ball


class UltralyticsByteTrackHybridTracker:
    """
    Uses Ultralytics ByteTrack for player IDs (best accuracy/stability option),
    while keeping a lightweight IoU tracker for the ball.
    Falls back to IoU player tracking when tracker IDs are unavailable.
    """

    def __init__(
        self,
        yolo_model: Any,
        person_class_id: int = 0,
        ball_class_id: int = 32,
        player_conf_threshold: float = 0.35,
        ball_conf_threshold: float = 0.10,
        player_max_age_frames: int = 25,
        ball_max_age_frames: int = 8,
        tracker_config: str = "bytetrack.yaml",
    ) -> None:
        self.model = yolo_model
        self.person_class_id = person_class_id
        self.ball_class_id = ball_class_id
        self.player_conf_threshold = player_conf_threshold
        self.ball_conf_threshold = ball_conf_threshold
        self.tracker_config = tracker_config

        self.ball_tracker = IoUTracker(
            class_name="ball",
            max_age_frames=ball_max_age_frames,
            min_iou=0.0,
            max_center_distance_px=180.0,
        )
        self.player_fallback_tracker = IoUTracker(
            class_name="player",
            max_age_frames=player_max_age_frames,
            min_iou=0.1,
            max_center_distance_px=140.0,
            start_track_id=1_000_000,
        )
        self._player_motion_state: Dict[int, Tuple[Tuple[float, float], int]] = {}

    def _prune_motion_state(self, frame_index: int, max_age_frames: int = 45) -> None:
        stale = [
            tid for tid, (_center, last_seen) in self._player_motion_state.items()
            if frame_index - last_seen > max_age_frames
        ]
        for tid in stale:
            del self._player_motion_state[tid]

    def _tracked_player_from_box(
        self,
        track_id: int,
        bbox: BBox,
        confidence: float,
        frame_index: int,
        fps: float,
    ) -> TrackedObject:
        center = bbox_center(bbox)
        foot = bbox_footpoint(bbox)
        prev = self._player_motion_state.get(track_id)
        vx = vy = speed = 0.0
        if prev is not None:
            prev_center, prev_frame = prev
            frame_delta = max(1, frame_index - prev_frame)
            vx = (center[0] - prev_center[0]) * fps / frame_delta
            vy = (center[1] - prev_center[1]) * fps / frame_delta
            speed = (vx * vx + vy * vy) ** 0.5
        self._player_motion_state[track_id] = (center, frame_index)
        return TrackedObject(
            track_id=track_id,
            class_name="player",
            confidence=confidence,
            bbox=bbox,
            center=center,
            footpoint=foot,
            velocity_px_s=(vx, vy),
            speed_px_s=speed,
        )

    def update(
        self,
        frame_bgr,
        frame_index: int,
        fps: float,
    ) -> Tuple[List[TrackedObject], Optional[TrackedObject], str]:
        min_conf = min(self.player_conf_threshold, self.ball_conf_threshold)
        results = self.model.track(
            source=frame_bgr,
            persist=True,
            verbose=False,
            device="cpu",
            conf=min_conf,
            classes=[self.person_class_id, self.ball_class_id],
            tracker=self.tracker_config,
        )
        detections: List[Detection] = []
        if not results:
            players = self.player_fallback_tracker.update([], frame_index, fps)
            balls = self.ball_tracker.update([], frame_index, fps)
            ball = balls[0] if balls else None
            return players, ball, "bytetrack_empty"

        result = results[0]
        boxes = getattr(result, "boxes", None)
        if boxes is None or len(boxes) == 0:
            players = self.player_fallback_tracker.update([], frame_index, fps)
            balls = self.ball_tracker.update([], frame_index, fps)
            ball = balls[0] if balls else None
            return players, ball, "bytetrack_empty"

        xyxy = boxes.xyxy.cpu().numpy()
        confs = boxes.conf.cpu().numpy()
        clss = boxes.cls.cpu().numpy().astype(int)
        ids = None
        if getattr(boxes, "id", None) is not None:
            try:
                ids = boxes.id.cpu().numpy().astype(int)
            except Exception:
                ids = None

        tracked_players: List[TrackedObject] = []
        untracked_player_dets: List[Detection] = []
        ball_dets: List[Detection] = []

        for idx, (bbox_arr, conf, cls_id) in enumerate(zip(xyxy, confs, clss)):
            x1, y1, x2, y2 = [float(v) for v in bbox_arr.tolist()]
            bbox = (x1, y1, x2, y2)

            if cls_id == self.person_class_id:
                if conf < self.player_conf_threshold:
                    continue
                det = Detection(
                    class_name="player",
                    confidence=float(conf),
                    bbox=bbox,
                    class_id=int(cls_id),
                )
                detections.append(det)
                track_id = None
                if ids is not None and idx < len(ids):
                    track_id = int(ids[idx]) + 1  # force positive/non-zero IDs
                if track_id is None or track_id <= 0:
                    untracked_player_dets.append(det)
                else:
                    tracked_players.append(
                        self._tracked_player_from_box(
                            track_id=track_id,
                            bbox=bbox,
                            confidence=float(conf),
                            frame_index=frame_index,
                            fps=fps,
                        )
                    )
            elif cls_id == self.ball_class_id:
                if conf < self.ball_conf_threshold:
                    continue
                det = Detection(
                    class_name="ball",
                    confidence=float(conf),
                    bbox=bbox,
                    class_id=int(cls_id),
                )
                detections.append(det)
                ball_dets.append(det)

        self._prune_motion_state(frame_index)

        # Supplement players lacking tracker IDs with fallback IoU tracker in a separate ID range.
        fallback_players = self.player_fallback_tracker.update(untracked_player_dets, frame_index, fps)
        players = tracked_players + fallback_players
        players.sort(key=lambda p: p.track_id)

        balls = self.ball_tracker.update(ball_dets, frame_index, fps)
        ball = None
        if balls:
            balls.sort(key=lambda b: (b.confidence, -b.speed_px_s), reverse=True)
            ball = balls[0]

        backend = "bytetrack"
        if tracked_players and fallback_players:
            backend = "bytetrack+fallback"
        elif not tracked_players:
            backend = "simple_fallback"
        return players, ball, backend
