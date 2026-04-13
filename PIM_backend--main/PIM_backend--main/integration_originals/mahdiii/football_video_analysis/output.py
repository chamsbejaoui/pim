from __future__ import annotations

import json
import os
from typing import Any, Dict, Iterable, List, Mapping, Sequence

from .models import EventRecord, FrameState, PossessionSegment


def _round(value: float, digits: int = 3) -> float:
    return round(float(value), digits)


def _event_to_dict(event: EventRecord) -> Dict[str, Any]:
    return {
        "event_type": event.event_type,
        "frame_index": event.frame_index,
        "timestamp_s": _round(event.timestamp_s, 3),
        "team_name": event.team_name,
        "confidence": _round(event.confidence, 3),
        "actor_track_id": event.actor_track_id,
        "receiver_track_id": event.receiver_track_id,
        "teams_involved": event.teams_involved,
        "details": event.details,
    }


def aggregate_team_stats(
    team_names: Sequence[str],
    events: Sequence[EventRecord],
    possession_segments: Sequence[PossessionSegment],
    total_duration_s: float,
) -> Dict[str, Dict[str, Any]]:
    stats: Dict[str, Dict[str, Any]] = {
        team_name: {
            "passes_attempted": 0,
            "passes_completed": 0,
            "shots": 0,
            "contact_event": 0,
            "offside_likely": 0,
            "possession_seconds": 0.0,
            "possession_pct": 0.0,
            "pass_accuracy_pct": 0.0,
        }
        for team_name in team_names
    }

    for event in events:
        if event.event_type == "pass" and event.team_name in stats:
            team_stat = stats[event.team_name]
            team_stat["passes_attempted"] += 1
            if bool(event.details.get("completed")):
                team_stat["passes_completed"] += 1
        elif event.event_type == "shot" and event.team_name in stats:
            stats[event.team_name]["shots"] += 1
        elif event.event_type == "contact_event":
            # Count involvement for both teams in the collision.
            for team_name in set(event.teams_involved):
                if team_name in stats:
                    stats[team_name]["contact_event"] += 1
        elif event.event_type == "offside_likely" and event.team_name in stats:
            stats[event.team_name]["offside_likely"] += 1

    for seg in possession_segments:
        if seg.team_name in stats:
            stats[seg.team_name]["possession_seconds"] += max(0.0, seg.duration_s)

    for team_name, team_stat in stats.items():
        attempted = team_stat["passes_attempted"]
        completed = team_stat["passes_completed"]
        team_stat["pass_accuracy_pct"] = _round((completed / attempted * 100.0) if attempted else 0.0, 2)
        team_stat["possession_pct"] = _round(
            (team_stat["possession_seconds"] / total_duration_s * 100.0) if total_duration_s > 0 else 0.0,
            2,
        )
        team_stat["possession_seconds"] = _round(team_stat["possession_seconds"], 2)
    return stats


def _timeline_preview(events: Sequence[EventRecord], limit: int = 20) -> List[Dict[str, Any]]:
    items: List[Dict[str, Any]] = []
    for event in sorted(events, key=lambda e: e.timestamp_s)[:limit]:
        minute = int(event.timestamp_s // 60)
        second = int(event.timestamp_s % 60)
        items.append(
            {
                "event_type": event.event_type,
                "team_name": event.team_name,
                "timestamp_label": f"{minute:02d}:{second:02d}",
                "confidence": _round(event.confidence, 2),
            }
        )
    return items


def build_output_payload(
    *,
    metadata: Mapping[str, Any],
    frames: Sequence[FrameState],
    possession_segments: Sequence[PossessionSegment],
    events: Sequence[EventRecord],
    notes: Iterable[str],
) -> Dict[str, Any]:
    total_duration_s = 0.0
    if frames:
        total_duration_s = max(0.0, frames[-1].timestamp_s - frames[0].timestamp_s)

    team_names = [team["name"] for team in metadata.get("teams", []) if isinstance(team, dict) and "name" in team]
    team_stats = aggregate_team_stats(team_names, events, possession_segments, total_duration_s)

    # Flutter-oriented convenience fields are nested under metadata to preserve the required top-level shape.
    flutter_overview = {
        "possession": {
            team: team_stats[team]["possession_pct"] for team in team_names if team in team_stats
        },
        "pass_accuracy": {
            team: team_stats[team]["pass_accuracy_pct"] for team in team_names if team in team_stats
        },
        "total_shots": {
            team: team_stats[team]["shots"] for team in team_names if team in team_stats
        },
        "timeline_preview": _timeline_preview(events),
    }

    out: Dict[str, Any] = {
        "metadata": dict(metadata),
        "events": [_event_to_dict(event) for event in events],
        "team_stats": team_stats,
    }
    out["metadata"]["notes"] = list(dict.fromkeys([str(n) for n in notes if n]))
    out["metadata"]["flutter_overview"] = flutter_overview
    out["metadata"]["processing_summary"] = {
        "frames_processed": len(frames),
        "events_detected": len(events),
        "possession_segments": len(possession_segments),
        "players_locked_peak": max((len(f.players) for f in frames), default=0),
        "ball_detected_frames": sum(1 for f in frames if f.ball is not None),
    }
    return out


def write_output_json(output_path: str, payload: Mapping[str, Any]) -> None:
    parent = os.path.dirname(os.path.abspath(output_path))
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
