from __future__ import annotations

import os
import time
from typing import Any, Callable, Dict, List, Optional, Sequence

try:
    import cv2  # type: ignore
    import numpy as np  # type: ignore
except Exception:  # pragma: no cover
    cv2 = None
    np = None

try:
    from ultralytics import YOLO  # type: ignore
except Exception:  # pragma: no cover
    YOLO = None

from .color import TeamColorClassifier
from .events import EventDetector, PitchCalibrator, PitchCalibrationResult
from .models import AnalysisConfig, Detection, FrameState
from .output import build_output_payload, write_output_json
from .possession import PossessionEstimator
from .tracking import DetectionTracker, UltralyticsByteTrackHybridTracker


ProgressCallback = Callable[[Dict[str, Any]], None]


class UltralyticsDetector:
    def __init__(
        self,
        weights_path: str,
        person_class_id: int = 0,
        ball_class_id: int = 32,
        player_conf_threshold: float = 0.35,
        ball_conf_threshold: float = 0.10,
    ) -> None:
        if YOLO is None:
            raise RuntimeError(
                "Ultralytics is not installed. Install dependencies: pip install ultralytics opencv-python numpy"
            )
        self.model = YOLO(weights_path)
        self.person_class_id = person_class_id
        self.ball_class_id = ball_class_id
        self.player_conf_threshold = player_conf_threshold
        self.ball_conf_threshold = ball_conf_threshold

    def detect(self, frame_bgr) -> List[Detection]:
        min_conf = min(self.player_conf_threshold, self.ball_conf_threshold)
        results = self.model.predict(
            source=frame_bgr,
            verbose=False,
            device="cpu",
            conf=min_conf,
            classes=[self.person_class_id, self.ball_class_id],
        )
        detections: List[Detection] = []
        if not results:
            return detections

        result = results[0]
        boxes = getattr(result, "boxes", None)
        if boxes is None or len(boxes) == 0:
            return detections

        xyxy = boxes.xyxy.cpu().numpy()
        confs = boxes.conf.cpu().numpy()
        clss = boxes.cls.cpu().numpy().astype(int)
        for bbox_arr, conf, cls_id in zip(xyxy, confs, clss):
            x1, y1, x2, y2 = [float(v) for v in bbox_arr.tolist()]
            if cls_id == self.person_class_id:
                if conf < self.player_conf_threshold:
                    continue
                detections.append(
                    Detection(
                        class_name="player",
                        confidence=float(conf),
                        bbox=(x1, y1, x2, y2),
                        class_id=cls_id,
                    )
                )
            elif cls_id == self.ball_class_id:
                if conf < self.ball_conf_threshold:
                    continue
                detections.append(
                    Detection(
                        class_name="ball",
                        confidence=float(conf),
                        bbox=(x1, y1, x2, y2),
                        class_id=cls_id,
                    )
                )
        return detections


class FootballVideoAnalyzer:
    def __init__(self, config: AnalysisConfig) -> None:
        self.config = config
        self._requested_analysis_preset = config.analysis_preset
        self._requested_tracker_backend = config.tracker_backend
        self._requested_yolo_weights = config.yolo_weights
        self._apply_analysis_preset_defaults()
        self._validate_config()

    def _apply_analysis_preset_defaults(self) -> None:
        preset = (self.config.analysis_preset or "balanced").strip().lower()
        self.config.analysis_preset = preset
        self.config.tracker_backend = (self.config.tracker_backend or "auto").strip().lower()
        self.config.yolo_weights = (self.config.yolo_weights or "auto").strip()

        if self.config.tracker_backend == "auto":
            self.config.tracker_backend = "bytetrack" if preset == "best" else "simple"

        if self.config.yolo_weights.lower() == "auto":
            self.config.yolo_weights = "yolov8s.pt" if preset == "best" else "yolov8n.pt"

        if preset == "best":
            # "best" prioritizes tracking stability / event accuracy over throughput.
            self.config.offside_calibration_keep_best_sample = True

    def _validate_config(self) -> None:
        if not self.config.video_path:
            raise ValueError("video_path is required.")
        if not self.config.output_json_path:
            raise ValueError("output_json_path is required.")
        if self.config.team_1_name.strip() == self.config.team_2_name.strip():
            raise ValueError("team_1_name and team_2_name must be different.")
        if self.config.frame_stride < 1:
            raise ValueError("frame_stride must be >= 1.")
        if self.config.possession_confirm_frames < 1:
            raise ValueError("possession_confirm_frames must be >= 1.")
        if self.config.analysis_preset not in {"balanced", "best"}:
            raise ValueError("analysis_preset must be one of: balanced, best")
        if self.config.tracker_backend not in {"simple", "bytetrack"}:
            raise ValueError("tracker_backend must resolve to one of: simple, bytetrack")

    def _emit_progress(self, callback: Optional[ProgressCallback], payload: Dict[str, Any]) -> None:
        if callback is not None:
            callback(payload)

    def analyze(self, progress_callback: Optional[ProgressCallback] = None) -> Dict[str, Any]:
        if cv2 is None:
            raise RuntimeError("OpenCV is required. Install: pip install opencv-python numpy ultralytics")
        if not os.path.exists(self.config.video_path):
            raise FileNotFoundError(f"Video not found: {self.config.video_path}")

        cap = cv2.VideoCapture(self.config.video_path)
        if not cap.isOpened():
            raise RuntimeError(f"Failed to open video: {self.config.video_path}")

        fps = float(cap.get(cv2.CAP_PROP_FPS) or 0.0)
        if fps <= 0:
            fps = 25.0
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)

        detector = UltralyticsDetector(
            weights_path=self.config.yolo_weights,
            person_class_id=self.config.person_class_id,
            ball_class_id=self.config.ball_class_id,
            player_conf_threshold=self.config.player_conf_threshold,
            ball_conf_threshold=self.config.ball_conf_threshold,
        )
        simple_tracker = DetectionTracker(
            player_max_age_frames=self.config.player_track_max_age_frames,
            ball_max_age_frames=self.config.ball_track_max_age_frames,
        )
        bytetrack_tracker: Optional[UltralyticsByteTrackHybridTracker] = None
        tracker_backend_requested = (self._requested_tracker_backend or "auto")
        tracker_backend_effective = "simple"
        tracker_backend_status_counts: Dict[str, int] = {}
        bytetrack_fallback_noted = False
        bytetrack_init_failed: Optional[str] = None
        if self.config.tracker_backend == "bytetrack":
            try:
                bytetrack_tracker = UltralyticsByteTrackHybridTracker(
                    yolo_model=detector.model,
                    person_class_id=self.config.person_class_id,
                    ball_class_id=self.config.ball_class_id,
                    player_conf_threshold=self.config.player_conf_threshold,
                    ball_conf_threshold=self.config.ball_conf_threshold,
                    player_max_age_frames=self.config.player_track_max_age_frames,
                    ball_max_age_frames=self.config.ball_track_max_age_frames,
                    tracker_config=self.config.ultralytics_tracker_config,
                )
                tracker_backend_effective = "bytetrack"
            except Exception as exc:
                bytetrack_init_failed = str(exc)
                tracker_backend_effective = "simple"
        color_classifier = TeamColorClassifier(
            team_1_name=self.config.team_1_name,
            team_1_color=self.config.team_1_shirt_color,
            team_2_name=self.config.team_2_name,
            team_2_color=self.config.team_2_shirt_color,
            history_size=self.config.team_label_history,
        )
        possession_estimator = PossessionEstimator(
            distance_threshold_px=self.config.possession_distance_px,
            confirm_frames=self.config.possession_confirm_frames,
            release_frames=self.config.possession_release_frames,
        )

        pitch_calibrator = PitchCalibrator() if self.config.enable_offside else None
        pitch_calibration_result = PitchCalibrationResult()
        notes: List[str] = []
        frames: List[FrameState] = []

        processed_count = 0
        original_frame_index = -1
        last_progress_emit_time = 0.0
        start_time = time.time()

        self._emit_progress(
            progress_callback,
            {
                "phase": "init",
                "progress": 0.0,
                "message": "Starting video analysis",
                "video_path": self.config.video_path,
                "fps": fps,
                "total_frames": total_frames,
                "analysis_preset": self.config.analysis_preset,
                "analysis_preset_requested": (self._requested_analysis_preset or "balanced"),
                "tracker_backend_requested": tracker_backend_requested,
                "tracker_backend_effective": tracker_backend_effective,
            },
        )
        if bytetrack_init_failed:
            notes.append(
                f"ByteTrack tracker init failed; using simple tracker fallback. Reason: {bytetrack_init_failed}"
            )

        try:
            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                original_frame_index += 1

                if original_frame_index % self.config.frame_stride != 0:
                    continue
                if self.config.max_frames is not None and processed_count >= self.config.max_frames:
                    break

                if pitch_calibrator is not None:
                    sample_interval = 20 if self.config.offside_calibration_keep_best_sample else 45
                    should_try_calibration = (
                        processed_count < 10
                        or processed_count % sample_interval == 0
                    )
                    if should_try_calibration and (
                        self.config.offside_calibration_keep_best_sample
                        or not pitch_calibrator.result.enabled
                    ):
                        pitch_calibration_result = pitch_calibrator.try_calibrate(
                            frame,
                            original_frame_index,
                            keep_best=self.config.offside_calibration_keep_best_sample,
                        )

                tracker_status = "simple"
                if bytetrack_tracker is not None:
                    try:
                        players, ball, tracker_status = bytetrack_tracker.update(
                            frame,
                            frame_index=original_frame_index,
                            fps=fps,
                        )
                        tracker_backend_effective = "bytetrack"
                        tracker_backend_status_counts[tracker_status] = (
                            tracker_backend_status_counts.get(tracker_status, 0) + 1
                        )
                        if tracker_status in {"simple_fallback", "bytetrack+fallback"} and not bytetrack_fallback_noted:
                            notes.append(
                                "ByteTrack partially fell back to simple tracking on some frames (missing tracker IDs)."
                            )
                            bytetrack_fallback_noted = True
                    except Exception as exc:
                        notes.append(
                            f"ByteTrack runtime failed at frame {original_frame_index}; switched to simple tracker. Reason: {exc}"
                        )
                        bytetrack_tracker = None
                        tracker_backend_effective = "simple"
                        tracker_status = "simple"
                        detections = detector.detect(frame)
                        players, ball = simple_tracker.update(detections, frame_index=original_frame_index, fps=fps)
                else:
                    detections = detector.detect(frame)
                    players, ball = simple_tracker.update(detections, frame_index=original_frame_index, fps=fps)
                color_classifier.annotate_players(frame, players)

                frame_state = FrameState(
                    frame_index=original_frame_index,
                    timestamp_s=float(original_frame_index) / fps,
                    players=players,
                    ball=ball,
                    width=width,
                    height=height,
                )
                frames.append(frame_state)
                processed_count += 1

                now = time.time()
                if progress_callback is not None and (now - last_progress_emit_time > 0.5 or processed_count == 1):
                    ratio = 0.0
                    if total_frames > 0:
                        ratio = min(0.98, original_frame_index / float(total_frames))
                    elapsed = max(1e-6, now - start_time)
                    self._emit_progress(
                        progress_callback,
                        {
                            "phase": "detect_track",
                            "progress": round(ratio, 4),
                            "frames_processed": processed_count,
                            "current_frame_index": original_frame_index,
                            "total_frames": total_frames,
                            "fps_effective": round(processed_count / elapsed, 2),
                            "players_detected": len(players),
                            "ball_detected": ball is not None,
                            "tracker_backend_effective": tracker_backend_effective,
                            "tracker_status": tracker_status,
                        },
                    )
                    last_progress_emit_time = now
        finally:
            cap.release()

        if not frames:
            raise RuntimeError("No frames were processed. Check video path/codec and frame_stride.")

        possession_segments = possession_estimator.estimate(frames)

        event_detector = EventDetector(
            fps=fps,
            frame_width=width,
            frame_height=height,
            team_names=self.config.teams(),
            pass_gap_max_frames=self.config.pass_gap_max_frames,
            shot_speed_spike_px_s=self.config.shot_speed_spike_px_s,
            shot_min_gap_frames=self.config.shot_min_gap_frames,
            shot_goal_zone_ratio=self.config.shot_goal_zone_ratio,
            contact_distance_px=self.config.contact_distance_px,
            contact_overlap_iou_threshold=self.config.contact_overlap_iou_threshold,
            contact_relative_speed_px_s=self.config.contact_relative_speed_px_s,
            contact_cooldown_frames=self.config.contact_cooldown_frames,
            possession_loss_window_frames=self.config.possession_loss_window_frames,
            goal_directions=self.config.goal_directions,
            offside_enabled=self.config.enable_offside,
            pitch_calibration=pitch_calibration_result,
        )
        events, event_notes = event_detector.detect(frames, possession_segments)
        notes.extend(event_notes)

        if self.config.enable_offside and not pitch_calibration_result.enabled:
            if pitch_calibration_result.notes:
                notes.extend(pitch_calibration_result.notes)
            else:
                notes.append("Offside requested but calibration was not successful; offside_likely was disabled.")

        elapsed_total_s = max(1e-6, time.time() - start_time)
        metadata = {
            "video_path": self.config.video_path,
            "output_json_path": self.config.output_json_path,
            "fps": round(fps, 3),
            "frame_width": width,
            "frame_height": height,
            "video_frame_count_reported": total_frames,
            "frames_processed": len(frames),
            "frame_stride": self.config.frame_stride,
            "processing_elapsed_s": round(elapsed_total_s, 3),
            "processing_fps_effective": round(len(frames) / elapsed_total_s, 2),
            "runtime": {
                "device": "cpu",
                "cuda": False,
                "macos_offline_ready": True,
                "yolo_weights": self.config.yolo_weights,
                "yolo_weights_requested": (self._requested_yolo_weights or "auto"),
                "detector": "ultralytics",
                "tracker_backend_requested": tracker_backend_requested,
                "tracker_backend_effective": tracker_backend_effective,
                "tracker_backend_status_counts": tracker_backend_status_counts,
            },
            "teams": [
                {"name": self.config.team_1_name, "shirt_color_preset": self.config.team_1_shirt_color},
                {"name": self.config.team_2_name, "shirt_color_preset": self.config.team_2_shirt_color},
            ],
            "analysis_options": {
                "analysis_preset": self.config.analysis_preset,
                "tracker_backend": self.config.tracker_backend,
                "enable_offside_requested": self.config.enable_offside,
                "offside_enabled": bool(self.config.enable_offside and pitch_calibration_result.enabled),
                "goal_directions": self.config.goal_directions,
                "offside_calibration_keep_best_sample": self.config.offside_calibration_keep_best_sample,
            },
            "offside_calibration": {
                "enabled": pitch_calibration_result.enabled,
                "confidence": round(float(pitch_calibration_result.confidence), 3),
                "source_frame_index": pitch_calibration_result.source_frame_index,
            },
            # Flutter UI mapping hints for the screens shared by the user.
            "flutter_contract": {
                "match_setup_inputs": [
                    "video_path",
                    "team_1_name",
                    "team_1_shirt_color",
                    "team_2_name",
                    "team_2_shirt_color",
                    "analysis_preset",
                    "enable_offside",
                    "output_json_path",
                ],
                "analysis_progress_stdout": True,
                "overview_source": "team_stats + events + metadata.flutter_overview",
            },
        }

        payload = build_output_payload(
            metadata=metadata,
            frames=frames,
            possession_segments=possession_segments,
            events=events,
            notes=notes,
        )
        write_output_json(self.config.output_json_path, payload)

        self._emit_progress(
            progress_callback,
            {
                "phase": "done",
                "progress": 1.0,
                "frames_processed": len(frames),
                "events_detected": len(events),
                "output_json_path": self.config.output_json_path,
            },
        )
        return payload


__all__ = ["AnalysisConfig", "FootballVideoAnalyzer"]
