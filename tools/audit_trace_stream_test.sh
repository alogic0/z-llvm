#!/usr/bin/env bash
set -euo pipefail
trace_binary=${1:?expected auditor executable}
trace_fixture=${ZLLVM_TEMP_ROOT:?managed temporary root required}/trace-fixtures
trace_query=${JQZ:-/home/oleg/bin/jqz}
mkdir -p "$trace_fixture"
cat > "$trace_fixture/complete.jsonl" <<'JSON'
{"schema":"compilation-events-v1","sequence":0,"elapsed_ns":0,"event":"profile_begin","function":null,"phase":"other","details":{}}
{"schema":"compilation-events-v1","sequence":1,"elapsed_ns":1,"event":"profile_end","function":null,"phase":"other","details":{"succeeded":true,"counters":{"selected_functions":0,"failed_functions":0}}}
JSON
cat > "$trace_fixture/failed.jsonl" <<'JSON'
{"schema":"compilation-events-v1","sequence":0,"elapsed_ns":0,"event":"profile_begin","function":null,"phase":"other","details":{}}
{"schema":"compilation-events-v1","sequence":1,"elapsed_ns":1,"event":"function_begin","function":"broken","phase":"other","details":{}}
{"schema":"compilation-events-v1","sequence":2,"elapsed_ns":2,"event":"function_end","function":"broken","phase":"other","details":{"name":"broken","counters":{"selected_functions":0,"failed_functions":1}}}
{"schema":"compilation-events-v1","sequence":3,"elapsed_ns":3,"event":"profile_end","function":null,"phase":"other","details":{"succeeded":false,"counters":{"selected_functions":0,"failed_functions":1}}}
JSON
head -n 1 "$trace_fixture/complete.jsonl" > "$trace_fixture/incomplete.jsonl"
cp "$trace_fixture/incomplete.jsonl" "$trace_fixture/unterminated.jsonl"
printf '{' >> "$trace_fixture/unterminated.jsonl"
sed 's/profile_begin/unknown_event/' "$trace_fixture/complete.jsonl" > "$trace_fixture/corrupt.jsonl"
cat "$trace_fixture/complete.jsonl" "$trace_fixture/incomplete.jsonl" > "$trace_fixture/after-end.jsonl"
for trace_case in complete failed incomplete unterminated corrupt after-end; do
  "$trace_binary" --input "$trace_fixture/$trace_case.jsonl" --output "$trace_fixture/$trace_case.json"
  test "$("$trace_query" -r '.sha256' "$trace_fixture/$trace_case.json")" = "$(sha256sum "$trace_fixture/$trace_case.jsonl" | cut -d ' ' -f1)"
  test "$("$trace_query" '.whole_stream_read and .stream_metadata_unchanged and .retirement_ready == false' "$trace_fixture/$trace_case.json")" = true
done
test "$("$trace_query" '.whole_stream_semantically_valid and .complete and .succeeded and .records == 2' "$trace_fixture/complete.json")" = true
test "$("$trace_query" '.whole_stream_semantically_valid and .complete and .succeeded == false and .failed == 1 and .failed_functions[0].name == "broken"' "$trace_fixture/failed.json")" = true
test "$("$trace_query" '.status == "incomplete_stream" and .prefix_semantically_valid and .complete == false and .error_record.code == "MissingProfileEnd"' "$trace_fixture/incomplete.json")" = true
test "$("$trace_query" '.status == "invalid_stream" and .newline_complete == false and .error_record.code == "UnterminatedRecord"' "$trace_fixture/unterminated.json")" = true
test "$("$trace_query" '.status == "invalid_stream" and .error_record.code == "UnsupportedEventKind" and .records == 2' "$trace_fixture/corrupt.json")" = true
test "$("$trace_query" '.status == "invalid_stream" and .error_record.code == "EventAfterProfileEnd" and .records == 3' "$trace_fixture/after-end.json")" = true
ln -s complete.jsonl "$trace_fixture/symlink.jsonl"
# A deliberately invalid filesystem fixture must not block workspace collection.
trap 'rm -f -- "$trace_fixture/symlink.jsonl"' EXIT
if "$trace_binary" --input "$trace_fixture/symlink.jsonl" --output "$trace_fixture/symlink.json" > "$trace_fixture/symlink.stdout" 2> "$trace_fixture/symlink.stderr"; then exit 1; fi
test ! -e "$trace_fixture/symlink.json"
trace_output_hash=$(sha256sum "$trace_fixture/complete.json")
if "$trace_binary" --input "$trace_fixture/failed.jsonl" --output "$trace_fixture/complete.json" > "$trace_fixture/overwrite.stdout" 2> "$trace_fixture/overwrite.stderr"; then exit 1; fi
test "$(sha256sum "$trace_fixture/complete.json")" = "$trace_output_hash"
printf 'Passed: complete success/failure, incomplete, unterminated, corrupt, after-end, symlink refusal and output overwrite refusal.\n'
