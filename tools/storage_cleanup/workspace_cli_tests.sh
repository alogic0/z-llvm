#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -- "$1")
cleanup_runner=$(realpath -- "$2")
cleanup_fixture=$(mktemp -d /tmp/zllvm-workspace-cli-XXXXXXXX)
cleanup_finish() {
    cleanup_status=$?
    if (( cleanup_status != 0 )); then tail -n 18 "$cleanup_fixture/"*.log >&2 || true; fi
    chmod -R u+w -- "$cleanup_fixture"
    rm -r -- "$cleanup_fixture"
}
trap cleanup_finish EXIT
mkdir -p "$cleanup_fixture/src" "$cleanup_fixture/docs" "$cleanup_fixture/tools"
printf '0.17.0\n' > "$cleanup_fixture/.zigversion"
printf 'pub fn main() void {}\n' > "$cleanup_fixture/src/main.zig"
printf '{"schema":1,"minimum_idle_hours":0}\n' > "$cleanup_fixture/docs/storage_cleanup_policy.json"
cat > "$cleanup_fixture/tools/clean-storage" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$1" = __finish-job
"$CLEANUP_TEST_BINARY" --minimal --apply
exit "$2"
EOF
cat > "$cleanup_fixture/tools/produce" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$ZIG_LOCAL_CACHE_DIR/o" "$ZIG_GLOBAL_CACHE_DIR/o" "$TMPDIR"
printf 'temporary compiler\n' > "$ZIG_LOCAL_CACHE_DIR/o/compiler"
printf 'temporary global cache\n' > "$ZIG_GLOBAL_CACHE_DIR/o/object"
printf 'temporary executable\n' > "$ZLLVM_TEMP_ROOT/test-exe"
printf 'transient file\n' > "$TMPDIR/test"
printf 'retained command diagnostic\n'
if [[ ${CLEANUP_RAW_TRACE:-0} == 1 ]]; then printf 'unique raw trace\n' > "$ZLLVM_TEMP_ROOT/profile.events.jsonl"; fi
exit "${CLEANUP_TEST_EXIT:-0}"
EOF
chmod 755 "$cleanup_fixture/tools/clean-storage" "$cleanup_fixture/tools/produce"
for cleanup_case in success failure held raw; do
    cleanup_run="local-state/validations/test/batch/$cleanup_case"
    cleanup_work="local-state/tmp/validations/test/batch/$cleanup_case/.workspaces/check"
    cleanup_code=0
    cleanup_raw=0
    if [[ $cleanup_case == failure ]]; then cleanup_code=7; fi
    if [[ $cleanup_case == raw ]]; then cleanup_raw=1; fi
    mkdir -p "$cleanup_fixture/$cleanup_run" "$cleanup_fixture/local-state/storage-cleanup"
    printf 'unique retained input\n' > "$cleanup_fixture/$cleanup_run/input.ll"
    if [[ $cleanup_case == held ]]; then
        "${JQZ:-jqz}" -n --arg path "$cleanup_run" '{schema:1,paths:[$path]}' > "$cleanup_fixture/local-state/storage-cleanup/holds.json"
    else
        printf '{"schema":1,"paths":[]}\n' > "$cleanup_fixture/local-state/storage-cleanup/holds.json"
    fi
    cleanup_actual=0
    env -u TMPDIR -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR \
        ZLLVM_PROJECT_ROOT="$cleanup_fixture" CLEANUP_TEST_BINARY="$cleanup_binary" CLEANUP_TEST_EXIT="$cleanup_code" CLEANUP_RAW_TRACE="$cleanup_raw" \
        "$cleanup_runner" --output-root "$cleanup_fixture/$cleanup_run" check -- "$cleanup_fixture/tools/produce" > "$cleanup_fixture/$cleanup_case.log" 2>&1 || cleanup_actual=$?
    test "$cleanup_actual" = "$cleanup_code"
    test -f "$cleanup_fixture/$cleanup_run/check.storage-layout.json"
    test -f "$cleanup_fixture/$cleanup_run/check.json"
    test -s "$cleanup_fixture/$cleanup_run/check.log"
    test "$(cat "$cleanup_fixture/$cleanup_run/input.ll")" = 'unique retained input'
    test ! -e "$cleanup_fixture/$cleanup_run/local-cache"
    if [[ $cleanup_case == success ]]; then
        test ! -e "$cleanup_fixture/$cleanup_work"
    else
        test -f "$cleanup_fixture/$cleanup_work/test-exe"
    fi
done
# An explicit cache override stays caller-owned; defaults still use scratch.
cleanup_run=local-state/validations/test/batch/override
env -u TMPDIR -u ZIG_GLOBAL_CACHE_DIR ZIG_LOCAL_CACHE_DIR="$cleanup_fixture/shared-cache" \
    ZLLVM_PROJECT_ROOT="$cleanup_fixture" CLEANUP_TEST_BINARY="$cleanup_binary" \
    "$cleanup_runner" --output-root "$cleanup_fixture/$cleanup_run" check -- "$cleanup_fixture/tools/produce" > "$cleanup_fixture/override.log" 2>&1
test -f "$cleanup_fixture/shared-cache/o/compiler"
test ! -e "$cleanup_fixture/local-state/tmp/validations/test/batch/override/.workspaces/check"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply > "$cleanup_fixture/repeat.log" 2>&1
test ! -e "$cleanup_fixture/local-state/storage-cleanup/pending.json"
test -f "$cleanup_fixture/local-state/tmp/validations/test/batch/failure/.workspaces/check/test-exe"
test -f "$cleanup_fixture/local-state/tmp/validations/test/batch/raw/.workspaces/check/profile.events.jsonl"
# The release command preserves the failed producer's result and refuses holds.
printf '{"schema":1,"paths":["local-state/validations/test/batch/failure"]}\n' > "$cleanup_fixture/local-state/storage-cleanup/holds.json"
if ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" release-workspace --layout local-state/validations/test/batch/failure/check.storage-layout.json --reason 'Resolved fixture failure' > "$cleanup_fixture/release-held.log" 2>&1; then exit 1; fi
test ! -e "$cleanup_fixture/local-state/validations/test/batch/failure/check.workspace-release.json"
printf '{"schema":1,"paths":[]}\n' > "$cleanup_fixture/local-state/storage-cleanup/holds.json"
sha256sum "$cleanup_fixture/local-state/validations/test/batch/failure/check.json" "$cleanup_fixture/local-state/validations/test/batch/failure/check.log" > "$cleanup_fixture/failure.sha256"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" release-workspace --layout local-state/validations/test/batch/failure/check.storage-layout.json --reason 'Resolved fixture failure' > "$cleanup_fixture/release.log" 2>&1
test -f "$cleanup_fixture/local-state/tmp/validations/test/batch/failure/.workspaces/check/test-exe"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply > "$cleanup_fixture/release-apply.log" 2>&1
test ! -e "$cleanup_fixture/local-state/tmp/validations/test/batch/failure/.workspaces/check"
sha256sum --check --status "$cleanup_fixture/failure.sha256"
test -f "$cleanup_fixture/local-state/tmp/validations/test/batch/raw/.workspaces/check/profile.events.jsonl"
printf 'Eight workspace CLI checks passed: successful collection, failed retention, evidence hold, raw-trace guard, explicit cache override, repeat, held release refusal and reviewed failure release.\n'
