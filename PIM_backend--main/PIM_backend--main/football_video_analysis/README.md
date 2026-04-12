# Football Video Analysis (Python, CPU-only)

Offline football video analysis module for macOS using Ultralytics YOLO + lightweight tracking + heuristic event detection.

## Features

- Player + ball detection with pretrained Ultralytics YOLO
- Stable player `track_id` assignment (lightweight IoU/centroid tracker)
- Team classification by shirt color preset (HSV, torso crop, per-track label smoothing)
- Possession segmentation
- Event detection:
  - `pass` (`completed` flag in details)
  - `shot`
  - `contact_event` (never labels as foul)
  - `offside_likely` (optional, only if calibration succeeds)
- JSON output with `metadata`, `events`, `team_stats`
- CLI with JSON progress output (for Flutter `Process` listeners)

## Install (macOS CPU)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r /Users/makbook/Desktop/pimV1\ copy/football_video_analysis/requirements.txt
```

Notes:
- Uses CPU inference only (`device="cpu"`).
- First run may download YOLO weights if you pass `yolov8n.pt` and it is not cached. For fully offline operation, provide a local weights file path via `--yolo-weights`.

## CLI Usage

```bash
python3 -m football_video_analysis \
  --video-path /absolute/path/match_footage_001.mp4 \
  --team-1-name "London FC" \
  --team-1-shirt-color blue \
  --team-2-name "Arsenal" \
  --team-2-shirt-color red \
  --output-json-path /absolute/path/result.json \
  --analysis-preset best \
  --enable-offside \
  --goal-direction "London FC=right" \
  --goal-direction "Arsenal=left" \
  --progress-json
```

## JSON Output Shape

Top-level shape is:

```json
{
  "metadata": {},
  "events": [],
  "team_stats": {}
}
```

Event types emitted:
- `pass`
- `shot`
- `contact_event`
- `offside_likely` (optional, only when enabled and calibration succeeds)

## Flutter Integration Mapping (screens shared in prompt)

- Match Setup screen:
  - Map form fields directly to CLI args (`video_path`, team names/colors, `analysis_preset`, `enable_offside`, `output_json_path`).
  - Add a toggle/selector for `analysis_preset`: `balanced` (faster) vs `best` (better tracking/event quality, slower on CPU).
- AI Analysis progress screen:
  - Spawn the CLI as a process and parse `--progress-json` stdout lines.
  - Use fields like `phase`, `progress`, `frames_processed`, `players_detected`, `ball_detected`.
- Match Overview / Timeline screen:
  - Read `team_stats` for possession %, pass accuracy, shots.
  - Read `events` for timeline cards.
  - `metadata.flutter_overview` provides convenience aggregates and preview data for UI cards.

## Color Presets

Supported shirt presets are defined in `color.py` (examples: `red`, `blue`, `green`, `yellow`, `white`, `black`, `navy`, `sky_blue`).

## Important Heuristic Limits

- This module is heuristic and not VAR-grade officiating.
- `contact_event` is intentionally generic and **not** a foul detector.
- `offside_likely` only appears when pitch calibration succeeds; otherwise offside is disabled and a note is added to `metadata.notes`.
- `analysis_preset=best` uses ByteTrack player tracking when available and falls back automatically to the simple tracker if needed (this fallback is recorded in metadata/notes).
