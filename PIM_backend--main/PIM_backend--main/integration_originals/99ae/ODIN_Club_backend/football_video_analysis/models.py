from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple


BBox = Tuple[float, float, float, float]
Point = Tuple[float, float]


@dataclass
class Detection:
    class_name: str
    confidence: float
    bbox: BBox
    class_id: Optional[int] = None

    @property
    def center(self) -> Point:
        x1, y1, x2, y2 = self.bbox
        return ((x1 + x2) / 2.0, (y1 + y2) / 2.0)

    @property
    def footpoint(self) -> Point:
        x1, _y1, x2, y2 = self.bbox
        return ((x1 + x2) / 2.0, y2)


@dataclass
class TrackedObject:
    track_id: int
    class_name: str
    confidence: float
    bbox: BBox
    center: Point
    footpoint: Point
    velocity_px_s: Point = (0.0, 0.0)
    speed_px_s: float = 0.0
    team_name: Optional[str] = None
    team_confidence: float = 0.0
    raw_team_label: Optional[str] = None
    raw_team_confidence: float = 0.0


@dataclass
class FrameState:
    frame_index: int
    timestamp_s: float
    players: List[TrackedObject]
    ball: Optional[TrackedObject]
    width: int
    height: int
    possessor_track_id: Optional[int] = None
    possessor_team_name: Optional[str] = None
    possession_confidence: float = 0.0
    notes: List[str] = field(default_factory=list)


@dataclass
class PossessionSegment:
    segment_id: int
    start_frame: int
    end_frame: int
    start_timestamp_s: float
    end_timestamp_s: float
    track_id: Optional[int]
    team_name: Optional[str]
    confidence: float

    @property
    def duration_s(self) -> float:
        return max(0.0, self.end_timestamp_s - self.start_timestamp_s)


@dataclass
class EventRecord:
    event_type: str
    frame_index: int
    timestamp_s: float
    team_name: Optional[str]
    confidence: float
    actor_track_id: Optional[int] = None
    receiver_track_id: Optional[int] = None
    teams_involved: List[str] = field(default_factory=list)
    details: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AnalysisConfig:
    video_path: str
    team_1_name: str
    team_1_shirt_color: str
    team_2_name: str
    team_2_shirt_color: str
    output_json_path: str
    enable_offside: bool = False
    analysis_preset: str = "balanced"  # balanced | best
    tracker_backend: str = "auto"  # auto | simple | bytetrack
    ultralytics_tracker_config: str = "bytetrack.yaml"
    yolo_weights: str = "auto"
    player_conf_threshold: float = 0.35
    ball_conf_threshold: float = 0.10
    frame_stride: int = 1
    max_frames: Optional[int] = None
    player_track_max_age_frames: int = 25
    ball_track_max_age_frames: int = 8
    possession_distance_px: float = 95.0
    possession_confirm_frames: int = 3
    possession_release_frames: int = 4
    pass_gap_max_frames: int = 20
    shot_speed_spike_px_s: float = 650.0
    shot_min_gap_frames: int = 18
    shot_goal_zone_ratio: float = 0.16
    contact_distance_px: float = 55.0
    contact_overlap_iou_threshold: float = 0.02
    contact_relative_speed_px_s: float = 220.0
    contact_cooldown_frames: int = 12
    possession_loss_window_frames: int = 15
    team_label_history: int = 12
    goal_directions: Dict[str, str] = field(default_factory=dict)
    ball_class_id: int = 32  # COCO sports ball for Ultralytics default models.
    person_class_id: int = 0
    offside_calibration_keep_best_sample: bool = False

    def teams(self) -> List[str]:
        return [self.team_1_name, self.team_2_name]
