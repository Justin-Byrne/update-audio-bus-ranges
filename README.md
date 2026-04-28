# update_audio_bus_ranges

Utility for updating Godot audio bus range definitions from a transient-analysis CSV summary.

## Status

Standalone repository extracted from a larger local project.

Current release: `v0.1.0`

Intended for controlled project-file rewrites where transient-analysis output needs to be folded back into authored Godot configuration code.

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

## Notes

- the script rewrites the target GDScript file in place
- CI validates shell syntax and static analysis
