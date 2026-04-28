# update_audio_bus_ranges

Utility for updating Godot audio bus range definitions from a transient-analysis CSV summary.

## What It Does

- reads `master_summary.csv`
- reads a target `Level*Configuration.gd` file
- matches audio entries by filename
- rewrites `Vector2(...)` bus range values using CSV frequency bands
- prints a summary report of updated and unmatched entries

## Layout

- `scripts/update_audio_bus_ranges.sh`
- `docs/`

## Requirements

- `bash`
- `awk`

## Usage

```bash
./scripts/update_audio_bus_ranges.sh master_summary.csv LevelConfiguration.gd
```
