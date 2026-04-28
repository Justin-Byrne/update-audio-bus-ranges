#!/bin/bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 master_summary.csv Level*Configuration.gd" >&2
	exit 1
fi

csv_path="$1"
gd_path="$2"

if [ ! -f "$csv_path" ]; then
	echo "error: CSV file not found: $csv_path" >&2
	exit 1
fi

if [ ! -f "$gd_path" ]; then
	echo "error: GDScript file not found: $gd_path" >&2
	exit 1
fi

tmp_output="$(mktemp)"
tmp_report="$(mktemp)"

cleanup() {
	rm -f "$tmp_output" "$tmp_report"
}

trap cleanup EXIT

awk -v report_path="$tmp_report" '
function trim(value) {
	gsub(/^[[:space:]]+/, "", value)
	gsub(/[[:space:]]+$/, "", value)
	return value
}

function csv_unquote(value) {
	value = trim(value)
	if (value ~ /^".*"$/) {
		value = substr(value, 2, length(value) - 2)
		gsub(/""/, "\"", value)
	}
	return value
}

function parse_csv_fields(line, fields,    i, ch, next_ch, field, count, in_quotes) {
	field = ""
	count = 0
	in_quotes = 0

	for (i = 1; i <= length(line); i++) {
		ch = substr(line, i, 1)
		if (in_quotes) {
			if (ch == "\"") {
				next_ch = substr(line, i + 1, 1)
				if (next_ch == "\"") {
					field = field "\""
					i++
				} else {
					in_quotes = 0
				}
			} else {
				field = field ch
			}
		} else {
			if (ch == "\"") {
				in_quotes = 1
			} else if (ch == ",") {
				count++
				fields[count] = field
				field = ""
			} else {
				field = field ch
			}
		}
	}

	count++
	fields[count] = field
	return count
}

function load_csv(csv_file,    line, field_count, fields, i, header_name, row_file_name, row_lo_hz, row_hi_hz) {
	if ((getline line < csv_file) <= 0) {
		print "error: CSV file is empty: " csv_file > "/dev/stderr"
		exit 1
	}

	field_count = parse_csv_fields(line, fields)
	for (i = 1; i <= field_count; i++) {
		header_name = trim(fields[i])
		header_index[header_name] = i
	}

	if (!("file_name" in header_index) || !("top_band_lo_hz" in header_index) || !("top_band_hi_hz" in header_index)) {
		print "error: CSV header must include file_name, top_band_lo_hz, and top_band_hi_hz" > "/dev/stderr"
		exit 1
	}

	while ((getline line < csv_file) > 0) {
		delete fields
		field_count = parse_csv_fields(line, fields)

		row_file_name = csv_unquote(fields[header_index["file_name"]])
		row_lo_hz = trim(fields[header_index["top_band_lo_hz"]])
		row_hi_hz = trim(fields[header_index["top_band_hi_hz"]])

		if (row_file_name == "") {
			continue
		}

		if (row_lo_hz == "" || row_hi_hz == "" || row_lo_hz !~ /^[-+]?[0-9]*\.?[0-9]+$/ || row_hi_hz !~ /^[-+]?[0-9]*\.?[0-9]+$/) {
			print "error: invalid frequency values for " row_file_name > "/dev/stderr"
			exit 1
		}

		csv_lo[row_file_name] = sprintf("%.1f", row_lo_hz + 0)
		csv_hi[row_file_name] = sprintf("%.1f", row_hi_hz + 0)
		csv_seen[row_file_name] = 1
	}

	close(csv_file)
}

function write_report(    key) {
	print "Summary" > report_path
	print "- CSV entries loaded: " csv_count >> report_path
	print "- Updated entries: " updated_count >> report_path
	print "- CSV entries not found in GDScript: " missing_csv_count >> report_path
	print "- GDScript audio entries without CSV matches: " missing_gd_count >> report_path

	for (key in updated_names) {
		print "- Updated file: " key >> report_path
	}
	for (key in missing_csv_names) {
		print "- Missing in GDScript: " key >> report_path
	}
	for (key in missing_gd_names) {
		print "- Missing in CSV: " key >> report_path
	}
}

BEGIN {
	csv_count = 0
	updated_count = 0
	missing_csv_count = 0
	missing_gd_count = 0

	load_csv(ARGV[1])

	for (csv_name in csv_seen) {
		csv_count++
	}

	delete ARGV[1]
	in_audio_bus_definitions = 0
}

{
	line = $0

	if (line ~ /@export var audio_bus_definitions: Array\[AudioBusDefinition\] = \[/) {
		in_audio_bus_definitions = 1
		print line
		next
	}

	if (in_audio_bus_definitions && line ~ /^[[:space:]]*\]/) {
		in_audio_bus_definitions = 0
		print line
		next
	}

	if (in_audio_bus_definitions && line ~ /AudioBusDefinition\.new\(/) {
		file_name = ""

		if (match(line, /"[^"]+\.(ogg|wav|mp3)"/)) {
			audio_path = substr(line, RSTART + 1, RLENGTH - 2)
			file_name = audio_path
			sub(/^.*\//, "", file_name)
		}

		if (file_name != "") {
			gd_seen[file_name] = 1

			if (file_name in csv_seen) {
				replacement = "Vector2 (" csv_lo[file_name] ", " csv_hi[file_name] ")"
				original_line = line
				sub(/Vector2[[:space:]]*\([[:space:]]*[-+]?[0-9]*\.?[0-9]+[[:space:]]*,[[:space:]]*[-+]?[0-9]*\.?[0-9]+[[:space:]]*\)/, replacement, line)

				if (line != original_line) {
					if (!(file_name in updated_names)) {
						updated_names[file_name] = 1
						updated_count++
					}
				}

				csv_matched[file_name] = 1
			} else {
				if (!(file_name in missing_gd_names)) {
					missing_gd_names[file_name] = 1
					missing_gd_count++
				}
			}
		}
	}

	print line
}

END {
	for (csv_name in csv_seen) {
		if (!(csv_name in csv_matched)) {
			missing_csv_names[csv_name] = 1
			missing_csv_count++
		}
	}

	write_report()
}
' "$csv_path" "$gd_path" > "$tmp_output"

cat "$tmp_output" > "$gd_path"
cat "$tmp_report"
