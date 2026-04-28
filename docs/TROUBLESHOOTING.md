# Troubleshooting

## Header validation failed

The CSV must include:

- `file_name`
- `top_band_lo_hz`
- `top_band_hi_hz`

## Nothing updated

Verify the file basenames in CSV and GDScript actually match.

## Broken target file

Restore from version control and verify the target still matches the expected `AudioBusDefinition.new(...)` pattern.
