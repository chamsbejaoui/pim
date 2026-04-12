from __future__ import annotations

import argparse
import json
import sys
from typing import Dict

from .analyzer import AnalysisConfig, FootballVideoAnalyzer
from .color import COLOR_PRESETS


def _parse_goal_direction_overrides(values) -> Dict[str, str]:
    result: Dict[str, str] = {}
    for item in values or []:
        if "=" not in item:
            raise ValueError(
                f"Invalid --goal-direction value '{item}'. Expected format TEAM_NAME=left|right"
            )
        team_name, direction = item.split("=", 1)
        direction = direction.strip().lower()
        if direction not in {"left", "right"}:
            raise ValueError(
                f"Invalid goal direction '{direction}' for team '{team_name}'. Use left or right."
            )
        result[team_name.strip()] = direction
    return result


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="football-video-analysis",
        description="Offline football video analysis (YOLO + tracking + team color + event heuristics).",
    )
    parser.add_argument("--video-path", required=True, help="Input video path")
    parser.add_argument("--team-1-name", required=True, help="Team 1 name")
    parser.add_argument(
        "--team-1-shirt-color",
        required=True,
        help=f"Preset shirt color for team 1. Supported: {', '.join(sorted(COLOR_PRESETS.keys()))}",
    )
    parser.add_argument("--team-2-name", required=True, help="Team 2 name")
    parser.add_argument(
        "--team-2-shirt-color",
        required=True,
        help=f"Preset shirt color for team 2. Supported: {', '.join(sorted(COLOR_PRESETS.keys()))}",
    )
    parser.add_argument("--output-json-path", required=True, help="Result JSON output path")
    parser.add_argument(
        "--analysis-preset",
        choices=["balanced", "best"],
        default="balanced",
        help="Analysis preset. 'best' enables higher-accuracy tracking/calibration defaults (slower on CPU).",
    )
    parser.add_argument(
        "--enable-offside",
        action="store_true",
        help="Enable offside_likely heuristic (requires pitch calibration; auto-disables on failure).",
    )
    parser.add_argument(
        "--yolo-weights",
        default=None,
        help="Ultralytics YOLO weights path (CPU inference). If omitted, preset-based default is used.",
    )
    parser.add_argument(
        "--tracker-backend",
        choices=["simple", "bytetrack"],
        default=None,
        help="Tracking backend override. If omitted, preset-based default is used.",
    )
    parser.add_argument("--frame-stride", type=int, default=1, help="Process every Nth frame (default: 1)")
    parser.add_argument("--max-frames", type=int, default=None, help="Optional frame cap for testing")
    parser.add_argument(
        "--goal-direction",
        action="append",
        default=[],
        metavar="TEAM=left|right",
        help="Optional per-team goal direction override; repeat for both teams.",
    )
    parser.add_argument(
        "--progress-json",
        action="store_true",
        help="Print machine-readable progress JSON lines to stdout (useful for Flutter Process listeners).",
    )
    return parser


def main(argv=None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        goal_directions = _parse_goal_direction_overrides(args.goal_direction)
    except ValueError as exc:
        parser.error(str(exc))
        return 2

    config = AnalysisConfig(
        video_path=args.video_path,
        team_1_name=args.team_1_name,
        team_1_shirt_color=args.team_1_shirt_color,
        team_2_name=args.team_2_name,
        team_2_shirt_color=args.team_2_shirt_color,
        enable_offside=bool(args.enable_offside),
        analysis_preset=args.analysis_preset,
        output_json_path=args.output_json_path,
        yolo_weights=args.yolo_weights or "auto",
        tracker_backend=args.tracker_backend or "auto",
        frame_stride=args.frame_stride,
        max_frames=args.max_frames,
        goal_directions=goal_directions,
    )
    analyzer = FootballVideoAnalyzer(config)

    def _progress(payload):
        if args.progress_json:
            sys.stdout.write(json.dumps(payload) + "\n")
            sys.stdout.flush()

    payload = analyzer.analyze(progress_callback=_progress if args.progress_json else None)

    # Keep the terminal summary compact while the full details live in the JSON file.
    print(
        json.dumps(
            {
                "status": "ok",
                "output_json_path": args.output_json_path,
                "events_detected": len(payload.get("events", [])),
                "team_stats_keys": sorted((payload.get("team_stats") or {}).keys()),
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
