#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -e -- "${1:?pass the compiled cleanup binary}")
cleanup_launcher=$(realpath -e -- "$(dirname -- "${BASH_SOURCE[0]}")/../clean-storage")
cleanup_fixture=$(mktemp -d /tmp/zllvm-storage-cli-XXXXXXXX)
cleanup_cli_finish() {
    cleanup_cli_status=$?
    if (( cleanup_cli_status != 0 )); then
        printf 'CLI qualification failed with status %s. Captured diagnostics:\n' "$cleanup_cli_status" >&2
        tail -n 12 "$cleanup_fixture/"*.log >&2 || true
    fi
    rm -r -- "$cleanup_fixture"
}
trap cleanup_cli_finish EXIT
mkdir -p "$cleanup_fixture/src" "$cleanup_fixture/local-state/storage-cleanup"
printf '0.17.0\n' > "$cleanup_fixture/.zigversion"
printf 'pub fn main() void {}\n' > "$cleanup_fixture/src/main.zig"
printf '{"schema":1,"current_manifests":[]}\n' > "$cleanup_fixture/policy.json"
printf '{"deliberately_interrupted":true}\n' > "$cleanup_fixture/local-state/storage-cleanup/pending.json"
if ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --policy policy.json > "$cleanup_fixture/pending.log" 2>&1; then
    printf 'FAIL: pending cleanup was ignored\n' >&2; exit 1
fi
"${ZIGREP:-zigrep}" --no-config -q -F 'An interrupted cleanup needs review' "$cleanup_fixture/pending.log"
test -f "$cleanup_fixture/local-state/storage-cleanup/pending.json"
rm -- "$cleanup_fixture/local-state/storage-cleanup/pending.json"
exec 8> "$cleanup_fixture/local-state/storage-cleanup/cleanup.lock"
flock --shared 8
if ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --policy policy.json > "$cleanup_fixture/locked.log" 2>&1; then
    printf 'FAIL: shared reader lock did not block deletion\n' >&2; exit 1
fi
"${ZIGREP:-zigrep}" --no-config -q -F 'another collector or a reader/build holds' "$cleanup_fixture/locked.log"
flock --unlock 8
exec 8>&-
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --policy policy.json > "$cleanup_fixture/empty.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'Cleanup complete:' "$cleanup_fixture/empty.log"
cleanup_run="$cleanup_fixture/local-state/validations/cli/build"
cleanup_source="$cleanup_fixture/local-state/validations/cli/source"
mkdir -p "$cleanup_run/zig-local-cache/o" "$cleanup_source" "$cleanup_fixture/toolchain"
printf 'private generated object\n' > "$cleanup_run/zig-local-cache/o/test.o"
printf 'retained compiler\n' > "$cleanup_run/z_llvm"
printf 'successful build log\n' > "$cleanup_run/build.stdout"
: > "$cleanup_run/build.stderr"
printf 'pub fn main() void {}\n' > "$cleanup_source/main.zig"
printf 'toolchain\n' > "$cleanup_fixture/toolchain/zig"
cleanup_compiler_sha=$(sha256sum "$cleanup_run/z_llvm"); cleanup_compiler_sha=${cleanup_compiler_sha%% *}
cleanup_source_sha=$(sha256sum "$cleanup_source/main.zig"); cleanup_source_sha=${cleanup_source_sha%% *}
cleanup_zig_sha=$(sha256sum "$cleanup_fixture/toolchain/zig"); cleanup_zig_sha=${cleanup_zig_sha%% *}
cat > "$cleanup_run/report.json" <<EOF
{"status":"passed","source_root":"$cleanup_source","source_sha256":{"main.zig":"$cleanup_source_sha"},"compiler":"$cleanup_run/z_llvm","compiler_sha256":"$cleanup_compiler_sha","zig":"$cleanup_fixture/toolchain/zig","zig_sha256":"$cleanup_zig_sha","commands":[{"outcome":"completed","actual_returncode":0,"argv":["zig","build-exe","--cache-dir","$cleanup_run/zig-local-cache","-Mroot=$cleanup_source/main.zig","-femit-bin=$cleanup_run/z_llvm"],"stdout":"$cleanup_run/build.stdout","stderr":"$cleanup_run/build.stderr"}]}
EOF
# The ordinary 24-hour policy holds this newly completed cache.
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --policy policy.json > "$cleanup_fixture/recent.log"
test -f "$cleanup_run/zig-local-cache/o/test.o"
"${ZIGREP:-zigrep}" --no-config -q -F 'TooRecent' "$cleanup_fixture/local-state/retirements"
printf '%064d  %s\n' 0 "$cleanup_source/main.zig" > "$cleanup_fixture/current.sha256"
printf '{"schema":1,"current_manifests":["current.sha256"]}\n' > "$cleanup_fixture/bad-current-policy.json"
if ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy bad-current-policy.json > "$cleanup_fixture/bad-current.log" 2>&1; then
    printf 'FAIL: bad current integrity manifest permitted collection\n' >&2; exit 1
fi
test -f "$cleanup_run/zig-local-cache/o/test.o"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy policy.json > "$cleanup_fixture/minimal.log"
test ! -e "$cleanup_run/zig-local-cache"
test -f "$cleanup_run/z_llvm"
test -f "$cleanup_source/main.zig"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 1;' "$cleanup_fixture/minimal.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy policy.json > "$cleanup_fixture/repeat.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 0;' "$cleanup_fixture/repeat.log"
mkdir -p "$cleanup_fixture/docs"
cp -- "$cleanup_fixture/policy.json" "$cleanup_fixture/docs/storage_cleanup_policy.json"
cleanup_job_status=0
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_launcher" maintain -- bash -c '
    if flock --nonblock --exclusive "$1" true; then exit 91; fi
    exit 7
' _ "$cleanup_fixture/local-state/storage-cleanup/cleanup.lock" > "$cleanup_fixture/maintain-failure.log" 2>&1 || cleanup_job_status=$?
test "$cleanup_job_status" -eq 7
"${ZIGREP:-zigrep}" --no-config -q -F 'Cleanup complete:' "$cleanup_fixture/maintain-failure.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_launcher" maintain -- true > "$cleanup_fixture/maintain-success.log" 2>&1
"${ZIGREP:-zigrep}" --no-config -q -F 'Cleanup complete:' "$cleanup_fixture/maintain-success.log"
test -d "$cleanup_fixture/local-state/tmp/storage-cleanup-build/local-cache"
test -d "$cleanup_fixture/local-state/tmp/storage-cleanup-build/global-cache"
test ! -e "$cleanup_fixture/local-state/storage-cleanup/tool-cache"
test ! -e "$cleanup_fixture/local-state/storage-cleanup/tool-global-cache"
test -x "$cleanup_fixture/local-state/storage-cleanup/clean-storage"
cleanup_released="$cleanup_fixture/local-state/validations/cli/batch/released"
mkdir -p "$cleanup_released"
printf 'obsolete diagnostic detail from a passed experiment\n' > "$cleanup_released/old.log"
printf '{"status":"passed"}\n' > "$cleanup_released/successor.json"
cleanup_old_sha=$(sha256sum "$cleanup_released/old.log"); cleanup_old_sha=${cleanup_old_sha%% *}
cleanup_report_sha=$(sha256sum "$cleanup_run/report.json"); cleanup_report_sha=${cleanup_report_sha%% *}
cleanup_successor_sha=$(sha256sum "$cleanup_released/successor.json"); cleanup_successor_sha=${cleanup_successor_sha%% *}
printf '%s  %s\n%s  %s\n' "$cleanup_old_sha" local-state/validations/cli/batch/released/old.log "$cleanup_source_sha" local-state/validations/cli/source/main.zig > "$cleanup_fixture/historical.sha256"
cleanup_manifest_sha=$(sha256sum "$cleanup_fixture/historical.sha256"); cleanup_manifest_sha=${cleanup_manifest_sha%% *}
# Pin discovery uses docs/ and the validation/retirement roots.
mv -- "$cleanup_fixture/historical.sha256" "$cleanup_fixture/docs/historical.sha256"
cat > "$cleanup_fixture/request.json" <<EOF
{"schema":"zllvm-storage-release-v1","state":"superseded","run_root":"local-state/validations/cli/batch/released","reason":"Accepted successor; preserve inputs and results","producer":{"path":"local-state/validations/cli/build/report.json","sha256":"$cleanup_report_sha"},"successor":{"path":"local-state/validations/cli/batch/released/successor.json","sha256":"$cleanup_successor_sha"},"retained":[{"path":"local-state/validations/cli/build/report.json","sha256":"$cleanup_report_sha","role":"build"},{"path":"local-state/validations/cli/build/report.json","sha256":"$cleanup_report_sha","role":"result"},{"path":"local-state/validations/cli/source/main.zig","sha256":"$cleanup_source_sha","role":"source"},{"path":"local-state/validations/cli/source/main.zig","sha256":"$cleanup_source_sha","role":"input"}],"artifacts":[{"path":"local-state/validations/cli/batch/released/old.log","sha256":"$cleanup_old_sha","kind":"log"}],"retired_pins":[{"manifest":{"path":"docs/historical.sha256","sha256":"$cleanup_manifest_sha"},"reference":"local-state/validations/cli/batch/released/old.log","target":{"path":"local-state/validations/cli/batch/released/old.log","sha256":"$cleanup_old_sha"},"reason":"Verified passed successor replaces this log only"}]}
EOF
cleanup_job_status=0
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_launcher" maintain --release-request request.json -- bash -c 'exit 7' > "$cleanup_fixture/failed-release.log" 2>&1 || cleanup_job_status=$?
test "$cleanup_job_status" -eq 7
test ! -e "$cleanup_released/storage-release.json"
test -f "$cleanup_released/old.log"
# The completed command names the run. Its wrapper must shed this argv before
# collection, while a genuinely active parent command still protects the run.
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_launcher" maintain --release-request request.json -- bash -c 'test -d "$1"' _ "$cleanup_released" > "$cleanup_fixture/completed-release.log" 2>&1
test -f "$cleanup_released/storage-release.json"
test ! -e "$cleanup_released/old.log"
test -f "$cleanup_source/main.zig"
test -f "$cleanup_fixture/docs/historical.sha256"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" inventory --policy policy.json > "$cleanup_fixture/inventory.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'Inventory:' "$cleanup_fixture/inventory.log"
"${ZIGREP:-zigrep}" --no-config -q -F '"unresolved_bytes"' "$cleanup_fixture/local-state/retirements"
if ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_launcher" maintain --release-request nonexistent.json -- true > "$cleanup_fixture/rejected-release.log" 2>&1; then
    printf 'FAIL: rejected publication returned success\n' >&2; exit 1
fi
cleanup_disposable="$cleanup_fixture/local-state/validations/cli/batch/disposable"
mkdir -p "$cleanup_disposable"
printf '\177ELFtemporary compiler fixture\n' > "$cleanup_disposable/z_llvm"
cleanup_disposable_sha=$(sha256sum "$cleanup_disposable/z_llvm"); cleanup_disposable_sha=${cleanup_disposable_sha%% *}
printf '{"status":"passed","compiler":"%s/z_llvm","compiler_sha256":"%s","source_root":"missing-old-sources"}\n' "$cleanup_disposable" "$cleanup_disposable_sha" > "$cleanup_disposable/report.json"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" release-build --build local-state/validations/cli/batch/disposable/report.json --reason 'Temporary compiler requires no source reconstruction' --policy policy.json > "$cleanup_fixture/disposable-release.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy policy.json > "$cleanup_fixture/disposable-apply.log"
test ! -e "$cleanup_disposable/z_llvm"
test -f "$cleanup_disposable/report.json"
cleanup_private="$cleanup_fixture/local-state/validations/cli/batch/private-units"
mkdir -p "$cleanup_private/src" "$cleanup_private/evidence/zig-local-Debug-v1/o"
printf 'copied project marker\n' > "$cleanup_private/.zigversion"
printf 'retained test source\n' > "$cleanup_private/src/main.zig"
printf 'temporary test executable\n' > "$cleanup_private/evidence/zig-local-Debug-v1/o/test"
printf 'one failed test; retain this diagnostic\n' > "$cleanup_private/evidence/unit.log"
cat > "$cleanup_private/evidence/unit.json" <<EOF
{"status":"finished","outcome":"completed","actual_returncode":1,"started_ns":1,"finished_ns":2,"cwd":"$cleanup_private","log":"$cleanup_private/evidence/unit.log","argv":["zig","test","--cache-dir","evidence/zig-local-Debug-v1","-Mroot=src/tests.zig"]}
EOF
cat > "$cleanup_fixture/caches.json" <<EOF
{"schema":"zllvm-private-cache-plan-v1","runs":[{"producer":"local-state/validations/cli/batch/private-units/evidence/unit.json","run_root":"local-state/validations/cli/batch/private-units","working_directory":"local-state/validations/cli/batch/private-units"}]}
EOF
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" prepare-caches --caches caches.json --reason 'Closed private test cache; diagnostics remain' --policy policy.json > "$cleanup_fixture/cache-plan.log"
cleanup_cache_review=$(tail -n 1 "$cleanup_fixture/cache-plan.log")
cleanup_cache_requests="${cleanup_cache_review%/cache-plan-review.json}/requests.json"
test -f "$cleanup_private/evidence/zig-local-Debug-v1/o/test"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --requests "$cleanup_cache_requests" --policy policy.json > "$cleanup_fixture/cache-apply.log"
test ! -e "$cleanup_private/evidence/zig-local-Debug-v1"
test -f "$cleanup_private/src/main.zig"
test -f "$cleanup_private/evidence/unit.json"
test -f "$cleanup_private/evidence/unit.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 1;' "$cleanup_fixture/cache-apply.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --requests "$cleanup_cache_requests" --policy policy.json > "$cleanup_fixture/cache-repeat.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 0;' "$cleanup_fixture/cache-repeat.log"
cleanup_trace_compiler="$cleanup_fixture/local-state/validations/cli/batch/trace-compiler"
cleanup_trace_run="$cleanup_fixture/local-state/validations/cli/batch/trace"
mkdir -p "$cleanup_trace_compiler" "$cleanup_trace_run"
printf '\177ELFretired compiler fixture\n' > "$cleanup_trace_compiler/z_llvm"
printf 'completed build\n' > "$cleanup_trace_compiler/build.stdout"
: > "$cleanup_trace_compiler/build.stderr"
cleanup_trace_compiler_sha=$(sha256sum "$cleanup_trace_compiler/z_llvm"); cleanup_trace_compiler_sha=${cleanup_trace_compiler_sha%% *}
cat > "$cleanup_trace_compiler/report.json" <<EOF
{"status":"passed","compiler":"$cleanup_trace_compiler/z_llvm","compiler_sha256":"$cleanup_trace_compiler_sha","source_root":"$cleanup_source","source_sha256":{"main.zig":"$cleanup_source_sha"},"zig":"$cleanup_fixture/toolchain/zig","zig_sha256":"$cleanup_zig_sha","commands":[{"outcome":"completed","actual_returncode":0,"argv":["zig","build-exe","-Mroot=$cleanup_source/main.zig","-femit-bin=$cleanup_trace_compiler/z_llvm"],"stdout":"$cleanup_trace_compiler/build.stdout","stderr":"$cleanup_trace_compiler/build.stderr"}]}
EOF
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" release-build --build local-state/validations/cli/batch/trace-compiler/report.json --reason 'Closed compiler before trace compaction' --policy policy.json > "$cleanup_fixture/trace-build-release.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy policy.json > "$cleanup_fixture/trace-build-apply.log"
test ! -e "$cleanup_trace_compiler/z_llvm"
cleanup_trace_report=$(tail -n 1 "$cleanup_fixture/trace-build-apply.log")
cleanup_trace_report=${cleanup_trace_report#Cleanup complete: }
cleanup_retirement_absolute=$("${JQZ:-jqz}" -r 'where(.status == "complete" and .action.kind == "build_output" and .action.status == "removed" and .action.path == "local-state/validations/cli/batch/trace-compiler/z_llvm") | input_filename()' "$cleanup_fixture/${cleanup_trace_report%/report.json}"/record-*.json)
test -f "$cleanup_retirement_absolute"
cleanup_retirement=${cleanup_retirement_absolute#"$cleanup_fixture/"}
printf 'audited raw fixture\n' > "$cleanup_trace_run/profile.events.jsonl"
printf 'original input\n' > "$cleanup_trace_run/input.ll"
printf 'original failed compilation diagnostic\n' > "$cleanup_trace_run/producer.log"
printf '{"status":"finished","actual_returncode":1,"log":"%s/producer.log"}\n' "$cleanup_trace_run" > "$cleanup_trace_run/producer.json"
printf '{"backend":{"path":"%s/z_llvm","sha256":"%s"}}\n' "$cleanup_trace_compiler" "$cleanup_trace_compiler_sha" > "$cleanup_trace_run/report.json"
printf '{"status":"failed","diagnostic":"retained original failure"}\n' > "$cleanup_trace_run/backend.json"
cleanup_raw_sha=$(sha256sum "$cleanup_trace_run/profile.events.jsonl"); cleanup_raw_sha=${cleanup_raw_sha%% *}
cleanup_input_sha=$(sha256sum "$cleanup_trace_run/input.ll"); cleanup_input_sha=${cleanup_input_sha%% *}
cleanup_producer_sha=$(sha256sum "$cleanup_trace_run/producer.json"); cleanup_producer_sha=${cleanup_producer_sha%% *}
cleanup_top_sha=$(sha256sum "$cleanup_trace_run/report.json"); cleanup_top_sha=${cleanup_top_sha%% *}
cleanup_backend_sha=$(sha256sum "$cleanup_trace_run/backend.json"); cleanup_backend_sha=${cleanup_backend_sha%% *}
cat > "$cleanup_trace_run/audit.json" <<EOF
{"schema":"zllvm-native-event-audit-v1","status":"verified","path":"local-state/validations/cli/batch/trace/profile.events.jsonl","sha256":"$cleanup_raw_sha","whole_stream_read":true,"whole_stream_semantically_valid":true,"report_binding_verified":true,"complete":true,"stream_metadata_unchanged":true,"recorded_hash_matches":true,"producer":{"path":"local-state/validations/cli/batch/trace/producer.json","sha256":"$cleanup_producer_sha"},"top_report":{"path":"local-state/validations/cli/batch/trace/report.json","sha256":"$cleanup_top_sha"},"backend_report":{"path":"local-state/validations/cli/batch/trace/backend.json","sha256":"$cleanup_backend_sha"},"input":{"path":"local-state/validations/cli/batch/trace/input.ll","sha256":"$cleanup_input_sha"},"core_source":"local-state/validations/cli/source/main.zig","core_sha256":"$cleanup_source_sha","driver_source":"local-state/validations/cli/source/main.zig","driver_sha256":"$cleanup_source_sha"}
EOF
cat > "$cleanup_fixture/traces.json" <<EOF
{"schema":"zllvm-trace-retirement-plan-v1","traces":[{"audit":"local-state/validations/cli/batch/trace/audit.json","build":"local-state/validations/cli/batch/trace-compiler/report.json","compiler_retirement":"$cleanup_retirement"}]}
EOF
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" prepare-traces --traces traces.json --reason 'Complete audit retains retired compiler identity' --policy policy.json > "$cleanup_fixture/trace-plan.log"
cleanup_trace_requests=$(tail -n 1 "$cleanup_fixture/trace-plan.log")
cleanup_trace_requests=${cleanup_trace_requests#tools/clean-storage --requests }
test -f "$cleanup_trace_run/profile.events.jsonl"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --requests "$cleanup_trace_requests" --policy policy.json > "$cleanup_fixture/trace-apply.log"
test ! -e "$cleanup_trace_run/profile.events.jsonl"
test -f "$cleanup_trace_run/input.ll"
test -f "$cleanup_trace_run/producer.log"
test -f "$cleanup_trace_run/audit.json"
test -f "$cleanup_source/main.zig"
test -f "$cleanup_fixture/$cleanup_retirement"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 1;' "$cleanup_fixture/trace-apply.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --requests "$cleanup_trace_requests" --policy policy.json > "$cleanup_fixture/trace-repeat.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 0;' "$cleanup_fixture/trace-repeat.log"
bash "$(dirname -- "${BASH_SOURCE[0]}")/generated_cli_tests.sh" "$cleanup_binary"
printf 'Twenty-three isolated CLI checks passed, including complete capture aliases, generated-output batches, retired compiler identities, preserved failure diagnostics, private caches, pin retirement, maintenance leases and repeated collection.\n'
