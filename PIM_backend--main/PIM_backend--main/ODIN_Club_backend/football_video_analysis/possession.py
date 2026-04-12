from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

from .models import FrameState, PossessionSegment
from .tracking import euclidean


@dataclass
class _RawPossessionCandidate:
    track_id: Optional[int]
    team_name: Optional[str]
    confidence: float


class PossessionEstimator:
    def __init__(
        self,
        distance_threshold_px: float = 95.0,
        confirm_frames: int = 3,
        release_frames: int = 4,
    ) -> None:
        self.distance_threshold_px = distance_threshold_px
        self.confirm_frames = confirm_frames
        self.release_frames = release_frames

    def _candidate_for_frame(self, frame: FrameState) -> _RawPossessionCandidate:
        if frame.ball is None or not frame.players:
            return _RawPossessionCandidate(None, None, 0.0)

        ball_point = frame.ball.center
        nearest = None
        nearest_dist = float("inf")
        for player in frame.players:
            dist = euclidean(player.footpoint, ball_point)
            if dist < nearest_dist:
                nearest = player
                nearest_dist = dist

        if nearest is None or nearest_dist > self.distance_threshold_px:
            return _RawPossessionCandidate(None, None, 0.0)

        dist_conf = max(0.0, 1.0 - (nearest_dist / max(1.0, self.distance_threshold_px)))
        label_conf = nearest.team_confidence if nearest.team_name else 0.15
        confidence = max(0.0, min(1.0, (dist_conf * 0.7) + (label_conf * 0.3)))
        return _RawPossessionCandidate(nearest.track_id, nearest.team_name, confidence)

    def estimate(self, frames: List[FrameState]) -> List[PossessionSegment]:
        if not frames:
            return []

        raw = [self._candidate_for_frame(frame) for frame in frames]

        active_track_id: Optional[int] = None
        active_team_name: Optional[str] = None
        active_conf_samples: List[float] = []
        active_segment_start_idx: Optional[int] = None
        pending_track_id: Optional[int] = None
        pending_team_name: Optional[str] = None
        pending_count = 0
        missing_count = 0
        segments: List[PossessionSegment] = []

        def close_segment(last_frame_idx_inclusive: int) -> None:
            nonlocal active_track_id, active_team_name, active_conf_samples, active_segment_start_idx
            if active_segment_start_idx is None:
                return
            start_frame = frames[active_segment_start_idx]
            end_frame = frames[last_frame_idx_inclusive]
            avg_conf = (
                sum(active_conf_samples) / len(active_conf_samples)
                if active_conf_samples
                else 0.0
            )
            segments.append(
                PossessionSegment(
                    segment_id=len(segments) + 1,
                    start_frame=start_frame.frame_index,
                    end_frame=end_frame.frame_index,
                    start_timestamp_s=start_frame.timestamp_s,
                    end_timestamp_s=end_frame.timestamp_s,
                    track_id=active_track_id,
                    team_name=active_team_name,
                    confidence=max(0.0, min(1.0, avg_conf)),
                )
            )
            active_track_id = None
            active_team_name = None
            active_conf_samples = []
            active_segment_start_idx = None

        for idx, frame in enumerate(frames):
            candidate = raw[idx]
            current_frame_track = active_track_id
            current_frame_team = active_team_name
            current_frame_conf = active_conf_samples[-1] if active_conf_samples else 0.0

            if candidate.track_id is None:
                pending_track_id = None
                pending_team_name = None
                pending_count = 0
                if active_track_id is not None:
                    missing_count += 1
                    if missing_count >= self.release_frames:
                        close_segment(max(0, idx - 1))
                        current_frame_track = None
                        current_frame_team = None
                        current_frame_conf = 0.0
                else:
                    missing_count = 0
            else:
                missing_count = 0
                if candidate.track_id == active_track_id:
                    active_conf_samples.append(candidate.confidence)
                    pending_track_id = None
                    pending_team_name = None
                    pending_count = 0
                    current_frame_track = active_track_id
                    current_frame_team = active_team_name
                    current_frame_conf = candidate.confidence
                else:
                    if candidate.track_id == pending_track_id:
                        pending_count += 1
                    else:
                        pending_track_id = candidate.track_id
                        pending_team_name = candidate.team_name
                        pending_count = 1

                    if pending_count >= self.confirm_frames:
                        if active_track_id is not None:
                            close_segment(max(0, idx - 1))
                        active_track_id = candidate.track_id
                        active_team_name = candidate.team_name
                        active_segment_start_idx = idx
                        active_conf_samples = [candidate.confidence]
                        pending_track_id = None
                        pending_team_name = None
                        pending_count = 0
                        current_frame_track = active_track_id
                        current_frame_team = active_team_name
                        current_frame_conf = candidate.confidence
                    else:
                        # Hold previous possessor until the new one is confirmed.
                        current_frame_track = active_track_id
                        current_frame_team = active_team_name
                        current_frame_conf = (
                            active_conf_samples[-1] if active_conf_samples else 0.0
                        )

            frame.possessor_track_id = current_frame_track
            frame.possessor_team_name = current_frame_team
            frame.possession_confidence = current_frame_conf

        if active_track_id is not None and active_segment_start_idx is not None:
            close_segment(len(frames) - 1)

        return segments
