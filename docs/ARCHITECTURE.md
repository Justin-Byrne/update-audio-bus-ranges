# Architecture

## Overview

`update_audio_bus_ranges.sh` is a shell wrapper around an embedded `awk` transformation.

## Flow

1. Validate `CSV` and `GDScript` inputs.
2. Parse CSV headers and rows in `awk`.
3. Match `file_name` entries to `AudioBusDefinition.new(...)` entries in GDScript.
4. Replace frequency `Vector2(...)` ranges in-place.
5. Emit a summary report.

## Design Notes

- uses in-place rewrite via temporary files
- depends on filename matching, not a separate ID field
- intentionally keeps parsing logic self-contained in one script
