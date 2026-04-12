from __future__ import annotations

from collections import Counter, defaultdict, deque
from dataclasses import dataclass
from typing import Deque, Dict, Iterable, List, Optional, Sequence, Tuple

try:
    import cv2  # type: ignore
    import numpy as np  # type: ignore
except Exception:  # pragma: no cover - import guarded for environments without deps
    cv2 = None
    np = None

from .models import TrackedObject


@dataclass(frozen=True)
class HSVColorPreset:
    name: str
    hue_ranges: Tuple[Tuple[int, int], ...] = ()
    sat_min: int = 40
    sat_max: int = 255
    val_min: int = 40
    val_max: int = 255
    low_saturation_mode: Optional[str] = None  # "white" or "black"


COLOR_PRESETS: Dict[str, HSVColorPreset] = {
    "red": HSVColorPreset("red", hue_ranges=((0, 10), (170, 179)), sat_min=60, val_min=45),
    "blue": HSVColorPreset("blue", hue_ranges=((95, 130),), sat_min=50, val_min=40),
    "navy": HSVColorPreset("navy", hue_ranges=((95, 130),), sat_min=35, val_min=20, val_max=140),
    "sky_blue": HSVColorPreset("sky_blue", hue_ranges=((85, 110),), sat_min=35, val_min=80),
    "cyan": HSVColorPreset("cyan", hue_ranges=((80, 100),), sat_min=45, val_min=70),
    "green": HSVColorPreset("green", hue_ranges=((35, 85),), sat_min=50, val_min=40),
    "yellow": HSVColorPreset("yellow", hue_ranges=((20, 35),), sat_min=55, val_min=60),
    "orange": HSVColorPreset("orange", hue_ranges=((10, 22),), sat_min=60, val_min=60),
    "purple": HSVColorPreset("purple", hue_ranges=((130, 165),), sat_min=45, val_min=35),
    "pink": HSVColorPreset("pink", hue_ranges=((145, 175),), sat_min=35, val_min=70),
    "white": HSVColorPreset("white", sat_max=60, val_min=120, low_saturation_mode="white"),
    "black": HSVColorPreset("black", sat_max=120, val_max=70, low_saturation_mode="black"),
    "gray": HSVColorPreset("gray", sat_max=50, val_min=60, val_max=180, low_saturation_mode="white"),
}


def normalize_color_key(color_name: str) -> str:
    return color_name.strip().lower().replace(" ", "_").replace("-", "_")


def hue_in_ranges(hue: int, ranges: Sequence[Tuple[int, int]]) -> bool:
    return any(lo <= hue <= hi for lo, hi in ranges)


def circular_hue_distance_to_ranges(hue: int, ranges: Sequence[Tuple[int, int]]) -> float:
    if not ranges:
        return 90.0
    best = 180.0
    for lo, hi in ranges:
        if lo <= hue <= hi:
            return 0.0
        for edge in (lo, hi):
            diff = abs(hue - edge)
            diff = min(diff, 180 - diff)
            if diff < best:
                best = diff
    return best


class TeamColorClassifier:
    def __init__(
        self,
        team_1_name: str,
        team_1_color: str,
        team_2_name: str,
        team_2_color: str,
        history_size: int = 12,
    ) -> None:
        self.team_presets = {
            team_1_name: self._get_preset(team_1_color),
            team_2_name: self._get_preset(team_2_color),
        }
        self.history_size = history_size
        self._label_history: Dict[int, Deque[Tuple[str, float]]] = defaultdict(
            lambda: deque(maxlen=self.history_size)
        )

    def available_color_presets(self) -> List[str]:
        return sorted(COLOR_PRESETS.keys())

    def _get_preset(self, color_name: str) -> HSVColorPreset:
        key = normalize_color_key(color_name)
        if key not in COLOR_PRESETS:
            supported = ", ".join(sorted(COLOR_PRESETS.keys()))
            raise ValueError(f"Unsupported shirt color '{color_name}'. Supported presets: {supported}")
        return COLOR_PRESETS[key]

    def _extract_shirt_crop(self, frame, bbox: Tuple[float, float, float, float]):
        if cv2 is None or np is None:
            raise RuntimeError("OpenCV and NumPy are required for color classification.")
        x1, y1, x2, y2 = [int(v) for v in bbox]
        h, w = frame.shape[:2]
        x1 = max(0, min(w - 1, x1))
        x2 = max(0, min(w, x2))
        y1 = max(0, min(h - 1, y1))
        y2 = max(0, min(h, y2))
        if x2 <= x1 or y2 <= y1:
            return None

        box_h = y2 - y1
        upper_h = max(2, int(box_h * 0.4))
        shirt_y2 = min(h, y1 + upper_h)

        # Focus on middle torso to reduce shorts/arms/background spill.
        box_w = x2 - x1
        inset = int(box_w * 0.12)
        cx1 = min(x2 - 1, x1 + inset)
        cx2 = max(cx1 + 1, x2 - inset)
        crop = frame[y1:shirt_y2, cx1:cx2]
        if crop.size == 0:
            return None
        return crop

    def _dominant_hsv(self, crop) -> Optional[Tuple[int, float, float]]:
        if cv2 is None or np is None:
            return None
        hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
        h = hsv[:, :, 0]
        s = hsv[:, :, 1]
        v = hsv[:, :, 2]

        # Exclude near-black shadows and near-white highlights for hue extraction.
        hue_mask = (s >= 30) & (v >= 30)
        if int(hue_mask.sum()) > 20:
            hue_vals = h[hue_mask]
            hist = np.bincount(hue_vals.flatten(), minlength=180)
            dominant_hue = int(hist.argmax())
        else:
            dominant_hue = int(np.median(h))

        sat_med = float(np.median(s))
        val_med = float(np.median(v))
        return dominant_hue, sat_med, val_med

    def _score_preset(self, hsv_stats: Tuple[int, float, float], preset: HSVColorPreset) -> float:
        hue, sat, val = hsv_stats
        sat = float(sat)
        val = float(val)

        if preset.low_saturation_mode == "white":
            sat_score = max(0.0, 1.0 - sat / max(1.0, preset.sat_max))
            val_score = 1.0 if val >= preset.val_min else max(0.0, val / max(1.0, preset.val_min))
            return (sat_score * 0.55) + (val_score * 0.45)
        if preset.low_saturation_mode == "black":
            val_score = max(0.0, 1.0 - val / max(1.0, preset.val_max))
            sat_penalty = 1.0 if sat <= preset.sat_max else max(0.0, 1.0 - (sat - preset.sat_max) / 255.0)
            return (val_score * 0.7) + (sat_penalty * 0.3)

        sat_ok = 1.0 if preset.sat_min <= sat <= preset.sat_max else max(
            0.0,
            1.0 - min(abs(sat - preset.sat_min), abs(sat - preset.sat_max)) / 255.0,
        )
        val_ok = 1.0 if preset.val_min <= val <= preset.val_max else max(
            0.0,
            1.0 - min(abs(val - preset.val_min), abs(val - preset.val_max)) / 255.0,
        )
        hue_dist = circular_hue_distance_to_ranges(hue, preset.hue_ranges)
        hue_score = max(0.0, 1.0 - hue_dist / 45.0)
        return hue_score * 0.65 + sat_ok * 0.2 + val_ok * 0.15

    def classify_bbox(
        self,
        frame,
        bbox: Tuple[float, float, float, float],
    ) -> Tuple[Optional[str], float]:
        crop = self._extract_shirt_crop(frame, bbox)
        if crop is None:
            return None, 0.0
        hsv_stats = self._dominant_hsv(crop)
        if hsv_stats is None:
            return None, 0.0

        scores = {
            team_name: self._score_preset(hsv_stats, preset)
            for team_name, preset in self.team_presets.items()
        }
        ranked = sorted(scores.items(), key=lambda kv: kv[1], reverse=True)
        if not ranked:
            return None, 0.0
        top_team, top_score = ranked[0]
        second_score = ranked[1][1] if len(ranked) > 1 else 0.0
        confidence = max(0.0, min(1.0, top_score - (second_score * 0.45)))
        if top_score < 0.35:
            return None, 0.0
        return top_team, confidence

    def smooth_track_label(
        self,
        track_id: int,
        raw_label: Optional[str],
        raw_confidence: float,
    ) -> Tuple[Optional[str], float]:
        if raw_label:
            self._label_history[track_id].append((raw_label, raw_confidence))

        history = self._label_history.get(track_id)
        if not history:
            return None, 0.0

        counts = Counter(label for label, _conf in history)
        majority_label, majority_count = counts.most_common(1)[0]
        conf_values = [conf for label, conf in history if label == majority_label]
        avg_conf = sum(conf_values) / max(1, len(conf_values))
        vote_ratio = majority_count / max(1, len(history))
        confidence = max(0.0, min(1.0, (avg_conf * 0.7) + (vote_ratio * 0.3)))
        return majority_label, confidence

    def annotate_players(self, frame, players: Iterable[TrackedObject]) -> None:
        for player in players:
            raw_label, raw_conf = self.classify_bbox(frame, player.bbox)
            smoothed_label, smoothed_conf = self.smooth_track_label(player.track_id, raw_label, raw_conf)
            player.raw_team_label = raw_label
            player.raw_team_confidence = raw_conf
            player.team_name = smoothed_label
            player.team_confidence = smoothed_conf
