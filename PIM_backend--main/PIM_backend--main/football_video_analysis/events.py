from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence, Tuple

try:
    import cv2  # type: ignore
    import numpy as np  # type: ignore
except Exception:  # pragma: no cover
    cv2 = None
    np = None

from .models import EventRecord, FrameState, PossessionSegment
from .tracking import bbox_iou, euclidean


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def _frame_map(frames: Sequence[FrameState]) -> Dict[int, FrameState]:
    return {f.frame_index: f for f in frames}


def _find_frame(frames: Sequence[FrameState], frame_index: int) -> Optional[FrameState]:
    mapping = _frame_map(frames)
    return mapping.get(frame_index)


def _find_nearest_frame(frames: Sequence[FrameState], frame_index: int, window: int = 3) -> Optional[FrameState]:
    if not frames:
        return None
    best = None
    best_delta = 1_000_000
    for frame in frames:
        delta = abs(frame.frame_index - frame_index)
        if delta <= window and delta < best_delta:
            best = frame
            best_delta = delta
    return best


@dataclass
class PitchCalibrationResult:
    enabled: bool = False
    confidence: float = 0.0
    homography: Optional[Any] = None
    source_frame_index: Optional[int] = None
    notes: List[str] = field(default_factory=list)

    def project_point(self, point_xy: Tuple[float, float]) -> Optional[Tuple[float, float]]:
        if not self.enabled or self.homography is None or np is None:
            return None
        pts = np.array([[[float(point_xy[0]), float(point_xy[1])]]], dtype=np.float32)
        transformed = cv2.perspectiveTransform(pts, self.homography) if cv2 is not None else None
        if transformed is None:
            return None
        x = float(transformed[0, 0, 0])
        y = float(transformed[0, 0, 1])
        return (x, y)


class PitchCalibrator:
    """
    Simple heuristic pitch calibration:
    - green pitch segmentation
    - Hough line extraction on the pitch mask
    - derive a rectangular field ROI and map to a normalized 105x68 pitch
    """

    def __init__(self) -> None:
        self.result = PitchCalibrationResult()

    def _compute_candidate(self, frame_bgr, frame_index: int) -> PitchCalibrationResult:
        if cv2 is None or np is None:
            return PitchCalibrationResult(
                enabled=False,
                confidence=0.0,
                homography=None,
                source_frame_index=frame_index,
                notes=["Offside disabled: OpenCV/NumPy unavailable for pitch calibration."],
            )

        h, w = frame_bgr.shape[:2]
        hsv = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2HSV)
        pitch_mask = cv2.inRange(hsv, (30, 35, 25), (95, 255, 255))
        kernel = np.ones((5, 5), np.uint8)
        pitch_mask = cv2.morphologyEx(pitch_mask, cv2.MORPH_OPEN, kernel)
        pitch_mask = cv2.morphologyEx(pitch_mask, cv2.MORPH_CLOSE, kernel)

        pitch_ratio = float(np.count_nonzero(pitch_mask)) / float(max(1, pitch_mask.size))
        if pitch_ratio < 0.18:
            return PitchCalibrationResult(
                enabled=False,
                confidence=0.0,
                homography=None,
                source_frame_index=frame_index,
                notes=["Offside calibration not ready: insufficient visible pitch area."],
            )

        edges = cv2.Canny(pitch_mask, 50, 150)
        min_line_len = max(35, int(w * 0.07))
        max_line_gap = max(8, int(w * 0.03))
        lines = cv2.HoughLinesP(
            edges,
            rho=1,
            theta=np.pi / 180.0,
            threshold=70,
            minLineLength=min_line_len,
            maxLineGap=max_line_gap,
        )
        if lines is None or len(lines) < 4:
            return PitchCalibrationResult(
                enabled=False,
                confidence=0.0,
                homography=None,
                source_frame_index=frame_index,
                notes=["Offside calibration not ready: field lines were not detected."],
            )

        line_segments: List[Tuple[int, int, int, int, float]] = []
        endpoints_x: List[int] = []
        endpoints_y: List[int] = []
        for line in lines:
            x1, y1, x2, y2 = line[0]
            length = float(((x2 - x1) ** 2 + (y2 - y1) ** 2) ** 0.5)
            if length < min_line_len:
                continue
            line_segments.append((x1, y1, x2, y2, length))
            endpoints_x.extend([x1, x2])
            endpoints_y.extend([y1, y2])

        if len(line_segments) < 4 or not endpoints_x or not endpoints_y:
            return PitchCalibrationResult(
                enabled=False,
                confidence=0.0,
                homography=None,
                source_frame_index=frame_index,
                notes=["Offside calibration not ready: too few usable field lines."],
            )

        x_low, x_high = np.percentile(np.array(endpoints_x), [5, 95]).tolist()
        y_low, y_high = np.percentile(np.array(endpoints_y), [8, 92]).tolist()

        # Anchor top/bottom to the visible pitch to reduce crowd/stands influence.
        ys, xs = np.where(pitch_mask > 0)
        if len(xs) < 50:
            return PitchCalibrationResult(
                enabled=False,
                confidence=0.0,
                homography=None,
                source_frame_index=frame_index,
                notes=["Offside calibration not ready: pitch mask unstable."],
            )

        mask_x_low, mask_x_high = np.percentile(xs, [2, 98]).tolist()
        mask_y_low, mask_y_high = np.percentile(ys, [2, 98]).tolist()
        left = float(max(0.0, min(x_low, mask_x_low)))
        right = float(min(float(w - 1), max(x_high, mask_x_high)))
        top = float(max(0.0, min(y_low, mask_y_low)))
        bottom = float(min(float(h - 1), max(y_high, mask_y_high)))

        if (right - left) < w * 0.35 or (bottom - top) < h * 0.2:
            return PitchCalibrationResult(
                enabled=False,
                confidence=0.0,
                homography=None,
                source_frame_index=frame_index,
                notes=["Offside calibration not ready: field ROI too small."],
            )

        src = np.array(
            [
                [left, bottom],
                [right, bottom],
                [right, top],
                [left, top],
            ],
            dtype=np.float32,
        )
        dst = np.array(
            [
                [0.0, 68.0],
                [105.0, 68.0],
                [105.0, 0.0],
                [0.0, 0.0],
            ],
            dtype=np.float32,
        )
        H = cv2.getPerspectiveTransform(src, dst)
        line_score = _clamp01(len(line_segments) / 24.0)
        geometry_score = _clamp01(((right - left) / max(1.0, w)) * 0.8 + ((bottom - top) / max(1.0, h)) * 0.2)
        confidence = _clamp01((pitch_ratio * 0.35) + (line_score * 0.35) + (geometry_score * 0.30))

        return PitchCalibrationResult(
            enabled=confidence >= 0.50,
            confidence=confidence,
            homography=H if confidence >= 0.50 else None,
            source_frame_index=frame_index,
            notes=[] if confidence >= 0.50 else ["Offside calibration confidence too low; disabled."],
        )

    def try_calibrate(
        self,
        frame_bgr,
        frame_index: int,
        keep_best: bool = False,
    ) -> PitchCalibrationResult:
        if not keep_best and self.result.enabled and self.result.confidence >= 0.55:
            return self.result

        candidate = self._compute_candidate(frame_bgr, frame_index)

        # keep_best=True continues sampling and retains the strongest successful calibration.
        if keep_best:
            current_score = float(self.result.confidence) if self.result.enabled else -1.0
            candidate_score = float(candidate.confidence) if candidate.enabled else -1.0
            if candidate_score > current_score:
                self.result = candidate
            elif (not self.result.enabled) and candidate.notes:
                self.result.notes = candidate.notes
            return self.result

        self.result = candidate
        return self.result


class EventDetector:
    def __init__(
        self,
        fps: float,
        frame_width: int,
        frame_height: int,
        team_names: Sequence[str],
        pass_gap_max_frames: int = 20,
        shot_speed_spike_px_s: float = 650.0,
        shot_min_gap_frames: int = 18,
        shot_goal_zone_ratio: float = 0.16,
        contact_distance_px: float = 55.0,
        contact_overlap_iou_threshold: float = 0.02,
        contact_relative_speed_px_s: float = 220.0,
        contact_cooldown_frames: int = 12,
        possession_loss_window_frames: int = 15,
        goal_directions: Optional[Dict[str, str]] = None,
        offside_enabled: bool = False,
        pitch_calibration: Optional[PitchCalibrationResult] = None,
    ) -> None:
        self.fps = fps
        self.frame_width = frame_width
        self.frame_height = frame_height
        self.team_names = list(team_names)
        self.pass_gap_max_frames = pass_gap_max_frames
        self.shot_speed_spike_px_s = shot_speed_spike_px_s
        self.shot_min_gap_frames = shot_min_gap_frames
        self.shot_goal_zone_ratio = shot_goal_zone_ratio
        self.contact_distance_px = contact_distance_px
        self.contact_overlap_iou_threshold = contact_overlap_iou_threshold
        self.contact_relative_speed_px_s = contact_relative_speed_px_s
        self.contact_cooldown_frames = contact_cooldown_frames
        self.possession_loss_window_frames = possession_loss_window_frames
        self.goal_directions = {k: v.lower() for k, v in (goal_directions or {}).items()}
        self.offside_enabled = offside_enabled
        self.pitch_calibration = pitch_calibration or PitchCalibrationResult()

    def detect(
        self,
        frames: Sequence[FrameState],
        possession_segments: Sequence[PossessionSegment],
    ) -> Tuple[List[EventRecord], List[str]]:
        notes: List[str] = []
        events: List[EventRecord] = []
        if not frames:
            return events, notes

        passes = self._detect_passes(frames, possession_segments)
        shots = self._detect_shots(frames)
        contacts = self._detect_contact_events(frames)
        events.extend(passes)
        events.extend(shots)
        events.extend(contacts)

        if self.offside_enabled:
            if self.pitch_calibration.enabled and self.pitch_calibration.homography is not None:
                events.extend(self._detect_offside_likely(frames, passes))
            else:
                notes.extend(self.pitch_calibration.notes or ["Offside requested but calibration failed; disabled."])

        events.sort(key=lambda e: (e.frame_index, e.timestamp_s, e.event_type))
        return events, notes

    def _detect_passes(
        self,
        frames: Sequence[FrameState],
        segments: Sequence[PossessionSegment],
    ) -> List[EventRecord]:
        events: List[EventRecord] = []
        if len(segments) < 2:
            return events

        for prev_seg, next_seg in zip(segments, segments[1:]):
            if prev_seg.track_id is None or next_seg.track_id is None:
                continue
            if prev_seg.track_id == next_seg.track_id:
                continue
            gap_frames = max(0, next_seg.start_frame - prev_seg.end_frame)
            if gap_frames > self.pass_gap_max_frames:
                continue
            if prev_seg.team_name is None:
                continue

            completed = bool(
                prev_seg.team_name is not None
                and next_seg.team_name is not None
                and prev_seg.team_name == next_seg.team_name
            )
            gap_score = _clamp01(1.0 - (gap_frames / max(1.0, self.pass_gap_max_frames)))
            same_team_bonus = 0.10 if completed else 0.0
            conf = _clamp01(
                ((prev_seg.confidence + next_seg.confidence) / 2.0) * 0.65
                + (gap_score * 0.25)
                + same_team_bonus
            )

            frame = _find_nearest_frame(frames, next_seg.start_frame, window=5)
            receiver_team = next_seg.team_name
            teams_involved = [t for t in [prev_seg.team_name, receiver_team] if t]
            details = {
                "completed": completed,
                "from_track_id": prev_seg.track_id,
                "to_track_id": next_seg.track_id,
                "from_team": prev_seg.team_name,
                "to_team": receiver_team,
                "gap_frames": gap_frames,
                "start_frame": prev_seg.end_frame,
                "end_frame": next_seg.start_frame,
            }
            if frame and frame.ball:
                details["ball_position_px"] = {
                    "x": round(frame.ball.center[0], 2),
                    "y": round(frame.ball.center[1], 2),
                }

            events.append(
                EventRecord(
                    event_type="pass",
                    frame_index=next_seg.start_frame,
                    timestamp_s=next_seg.start_timestamp_s,
                    team_name=prev_seg.team_name,
                    confidence=conf,
                    actor_track_id=prev_seg.track_id,
                    receiver_track_id=next_seg.track_id,
                    teams_involved=teams_involved,
                    details=details,
                )
            )
        return events

    def _get_ball_speed_map(self, frames: Sequence[FrameState]) -> Dict[int, float]:
        speed_map: Dict[int, float] = {}
        prev_frame: Optional[FrameState] = None
        prev_pos: Optional[Tuple[float, float]] = None
        for frame in frames:
            if frame.ball is None:
                prev_frame = None
                prev_pos = None
                continue
            if prev_frame is not None and prev_pos is not None:
                dt = max(1e-6, frame.timestamp_s - prev_frame.timestamp_s)
                dist = euclidean(frame.ball.center, prev_pos)
                speed_map[frame.frame_index] = dist / dt
            else:
                speed_map[frame.frame_index] = float(frame.ball.speed_px_s)
            prev_frame = frame
            prev_pos = frame.ball.center
        return speed_map

    def _infer_goal_direction_from_motion(
        self,
        frames: Sequence[FrameState],
        frame_idx: int,
    ) -> Optional[str]:
        window = 4
        relevant = [f for f in frames if abs(f.frame_index - frame_idx) <= window and f.ball is not None]
        if len(relevant) < 2:
            return None
        relevant.sort(key=lambda f: f.frame_index)
        dx = relevant[-1].ball.center[0] - relevant[0].ball.center[0]  # type: ignore[union-attr]
        if abs(dx) < 5:
            return None
        return "right" if dx > 0 else "left"

    def _find_team_possession_near(self, frames: Sequence[FrameState], frame_idx: int, window: int = 5) -> Optional[str]:
        candidates: List[Tuple[int, str]] = []
        for frame in frames:
            if abs(frame.frame_index - frame_idx) <= window and frame.possessor_team_name:
                candidates.append((abs(frame.frame_index - frame_idx), frame.possessor_team_name))
        if not candidates:
            return None
        candidates.sort(key=lambda x: x[0])
        return candidates[0][1]

    def _detect_shots(self, frames: Sequence[FrameState]) -> List[EventRecord]:
        events: List[EventRecord] = []
        if not frames:
            return events

        speed_map = self._get_ball_speed_map(frames)
        last_shot_frame = -10_000
        frame_lookup = _frame_map(frames)

        for frame in frames:
            if frame.ball is None:
                continue
            speed = speed_map.get(frame.frame_index, frame.ball.speed_px_s)
            if speed < self.shot_speed_spike_px_s:
                continue
            if frame.frame_index - last_shot_frame < self.shot_min_gap_frames:
                continue

            poss_team = frame.possessor_team_name or self._find_team_possession_near(frames, frame.frame_index, window=6)
            if poss_team is None:
                continue

            goal_direction = self.goal_directions.get(poss_team)
            if goal_direction not in {"left", "right"}:
                goal_direction = self._infer_goal_direction_from_motion(frames, frame.frame_index)
            if goal_direction not in {"left", "right"}:
                continue

            future_frames = [
                f for f in frames
                if frame.frame_index <= f.frame_index <= frame.frame_index + 10 and f.ball is not None
            ]
            if len(future_frames) < 2:
                continue
            xs = [f.ball.center[0] for f in future_frames if f.ball is not None]
            if not xs:
                continue
            end_x = max(xs) if goal_direction == "right" else min(xs)
            goal_zone_px = self.frame_width * self.shot_goal_zone_ratio
            enters_goal_zone = (
                end_x >= self.frame_width - goal_zone_px
                if goal_direction == "right"
                else end_x <= goal_zone_px
            )
            if not enters_goal_zone:
                continue

            direction_motion = (end_x - frame.ball.center[0]) if goal_direction == "right" else (frame.ball.center[0] - end_x)
            direction_score = _clamp01(direction_motion / max(1.0, self.frame_width * 0.15))
            speed_score = _clamp01(speed / max(1.0, self.shot_speed_spike_px_s * 1.5))
            conf = _clamp01((speed_score * 0.55) + (direction_score * 0.25) + (0.2 if frame.possessor_team_name else 0.1))

            events.append(
                EventRecord(
                    event_type="shot",
                    frame_index=frame.frame_index,
                    timestamp_s=frame.timestamp_s,
                    team_name=poss_team,
                    confidence=conf,
                    actor_track_id=frame.possessor_track_id,
                    teams_involved=[poss_team],
                    details={
                        "ball_speed_px_s": round(float(speed), 2),
                        "goal_direction": goal_direction,
                        "goal_zone_ratio": self.shot_goal_zone_ratio,
                        "ball_start_x_px": round(float(frame.ball.center[0]), 2),
                        "ball_end_x_px_est": round(float(end_x), 2),
                    },
                )
            )
            last_shot_frame = frame.frame_index
        return events

    def _detect_contact_events(self, frames: Sequence[FrameState]) -> List[EventRecord]:
        events: List[EventRecord] = []
        if not frames:
            return events

        frame_lookup = _frame_map(frames)
        last_pair_frame: Dict[Tuple[int, int], int] = {}

        for idx, frame in enumerate(frames):
            if len(frame.players) < 2:
                continue

            for i, p1 in enumerate(frame.players):
                for p2 in frame.players[i + 1 :]:
                    if p1.team_name is None or p2.team_name is None:
                        continue
                    if p1.team_name == p2.team_name:
                        continue

                    pair_key = tuple(sorted((p1.track_id, p2.track_id)))
                    if frame.frame_index - last_pair_frame.get(pair_key, -10_000) < self.contact_cooldown_frames:
                        continue

                    overlap = bbox_iou(p1.bbox, p2.bbox)
                    distance = euclidean(p1.footpoint, p2.footpoint)
                    if overlap < self.contact_overlap_iou_threshold and distance > self.contact_distance_px:
                        continue

                    rvx = p1.velocity_px_s[0] - p2.velocity_px_s[0]
                    rvy = p1.velocity_px_s[1] - p2.velocity_px_s[1]
                    rel_speed = float((rvx * rvx + rvy * rvy) ** 0.5)
                    if rel_speed < self.contact_relative_speed_px_s:
                        continue

                    # Possession-loss condition: within K frames, possessor changes or vanishes.
                    possession_lost = False
                    possessor_track = frame.possessor_track_id
                    possessor_team = frame.possessor_team_name
                    if possessor_track in pair_key:
                        for future in frames[idx + 1 : idx + 1 + self.possession_loss_window_frames]:
                            if future.possessor_track_id != possessor_track or future.possessor_team_name != possessor_team:
                                possession_lost = True
                                break
                    if not possession_lost:
                        continue

                    event_team = possessor_team if possessor_team else None
                    conf = _clamp01(
                        (_clamp01(rel_speed / (self.contact_relative_speed_px_s * 1.8)) * 0.45)
                        + (_clamp01(overlap / max(1e-6, self.contact_overlap_iou_threshold * 3.0)) * 0.2)
                        + (_clamp01((self.contact_distance_px - min(distance, self.contact_distance_px)) / max(1.0, self.contact_distance_px)) * 0.2)
                        + 0.15
                    )
                    events.append(
                        EventRecord(
                            event_type="contact_event",
                            frame_index=frame.frame_index,
                            timestamp_s=frame.timestamp_s,
                            team_name=event_team,
                            confidence=conf,
                            actor_track_id=possessor_track,
                            receiver_track_id=None,
                            teams_involved=[p1.team_name, p2.team_name],
                            details={
                                "players": [
                                    {"track_id": p1.track_id, "team_name": p1.team_name},
                                    {"track_id": p2.track_id, "team_name": p2.team_name},
                                ],
                                "bbox_overlap_iou": round(float(overlap), 4),
                                "distance_px": round(float(distance), 2),
                                "relative_speed_px_s": round(float(rel_speed), 2),
                                "possession_lost_within_frames": self.possession_loss_window_frames,
                            },
                        )
                    )
                    last_pair_frame[pair_key] = frame.frame_index
        return events

    def _resolve_attack_direction_for_pass(
        self,
        frames: Sequence[FrameState],
        pass_event: EventRecord,
    ) -> Optional[str]:
        team_name = pass_event.team_name
        if team_name and self.goal_directions.get(team_name) in {"left", "right"}:
            return self.goal_directions[team_name]
        return self._infer_goal_direction_from_motion(frames, pass_event.frame_index)

    def _detect_offside_likely(
        self,
        frames: Sequence[FrameState],
        pass_events: Sequence[EventRecord],
    ) -> List[EventRecord]:
        events: List[EventRecord] = []
        if not self.pitch_calibration.enabled or self.pitch_calibration.homography is None:
            return events

        frame_lookup = _frame_map(frames)

        for pass_event in pass_events:
            if pass_event.event_type != "pass":
                continue
            if not bool(pass_event.details.get("completed")):
                continue
            if pass_event.team_name is None:
                continue
            receiver_track_id = pass_event.receiver_track_id
            if receiver_track_id is None:
                continue

            frame = frame_lookup.get(pass_event.frame_index) or _find_nearest_frame(frames, pass_event.frame_index, window=3)
            if frame is None or frame.ball is None:
                continue

            receiver = next((p for p in frame.players if p.track_id == receiver_track_id), None)
            if receiver is None:
                continue

            attacking_team = pass_event.team_name
            defending_players = [
                p for p in frame.players
                if p.team_name is not None and p.team_name != attacking_team
            ]
            if len(defending_players) < 2:
                continue

            attack_direction = self._resolve_attack_direction_for_pass(frames, pass_event)
            if attack_direction not in {"left", "right"}:
                continue

            receiver_pitch = self.pitch_calibration.project_point(receiver.footpoint)
            ball_pitch = self.pitch_calibration.project_point(frame.ball.center)
            if receiver_pitch is None or ball_pitch is None:
                continue

            defender_xs: List[float] = []
            for defender in defending_players:
                proj = self.pitch_calibration.project_point(defender.footpoint)
                if proj is not None:
                    defender_xs.append(proj[0])
            if len(defender_xs) < 2:
                continue

            if attack_direction == "right":
                defender_xs.sort(reverse=True)
                second_last_defender_x = defender_xs[1]
                reference_x = max(ball_pitch[0], second_last_defender_x)
                margin = receiver_pitch[0] - reference_x
                in_opponent_half = receiver_pitch[0] > 52.5
            else:
                defender_xs.sort()
                second_last_defender_x = defender_xs[1]
                reference_x = min(ball_pitch[0], second_last_defender_x)
                margin = reference_x - receiver_pitch[0]
                in_opponent_half = receiver_pitch[0] < 52.5

            if not in_opponent_half:
                continue
            if margin <= 0.6:
                continue

            margin_score = _clamp01(margin / 4.0)
            team_conf = receiver.team_confidence if receiver.team_name == attacking_team else 0.3
            conf = _clamp01(
                (self.pitch_calibration.confidence * 0.55)
                + (margin_score * 0.3)
                + (team_conf * 0.15)
            )
            events.append(
                EventRecord(
                    event_type="offside_likely",
                    frame_index=pass_event.frame_index,
                    timestamp_s=pass_event.timestamp_s,
                    team_name=attacking_team,
                    confidence=conf,
                    actor_track_id=pass_event.actor_track_id,
                    receiver_track_id=receiver_track_id,
                    teams_involved=[attacking_team],
                    details={
                        "pass_frame_index": pass_event.frame_index,
                        "attack_direction": attack_direction,
                        "receiver_pitch_x_m": round(float(receiver_pitch[0]), 2),
                        "ball_pitch_x_m": round(float(ball_pitch[0]), 2),
                        "second_last_defender_pitch_x_m": round(float(second_last_defender_x), 2),
                        "offside_margin_m": round(float(margin), 2),
                        "calibration_confidence": round(float(self.pitch_calibration.confidence), 3),
                    },
                )
            )
        return events
