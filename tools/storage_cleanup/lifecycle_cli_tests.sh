#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -- "$1")
cleanup_runner=$(realpath -- "$2")
cleanup_fixture=$(mktemp -d /tmp/zllvm-lifecycle-cli-XXXXXXXX)
cleanup_finish() {
    cleanup_status=$?
    if (( cleanup_status != 0 )); then tail -n 14 "$cleanup_fixture/"*.log >&2 || true; fi
    chmod -R u+w -- "$cleanup_fixture"
    rm -rf -- "$cleanup_fixture"
}
trap cleanup_finish EXIT
mkdir -p "$cleanup_fixture/src" "$cleanup_fixture/docs" "$cleanup_fixture/tools"
printf '0.17.0\n' > "$cleanup_fixture/.zigversion"
printf 'pub fn main() void {}\n' > "$cleanup_fixture/src/main.zig"
printf '{"schema":1,"minimum_idle_hours":0}\n' > "$cleanup_fixture/docs/storage_cleanup_policy.json"
# The production wrapper is covered by cli_tests.sh. Avoid recompiling it in
# each producer fixture; this shim exercises the same terminal exec protocol.
cat > "$cleanup_fixture/tools/clean-storage" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$1" = __finish-job
"$CLEANUP_TEST_BINARY" --minimal --apply
exit "$2"
EOF
cat > "$cleanup_fixture/tools/zig" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$1" = test
test "$2" = --cache-dir
mkdir -p "$3/o"
printf 'temporary test executable\n' > "$3/o/test"
printf 'original completed test diagnostic\n'
if [[ ${CLEANUP_BREAK_FINISH:-0} == 1 ]]; then chmod 500 "$ZLLVM_PROJECT_ROOT/local-state/storage-cleanup/jobs"; fi
exit "${CLEANUP_TEST_EXIT:-0}"
EOF
chmod 755 "$cleanup_fixture/tools/clean-storage" "$cleanup_fixture/tools/zig"
for cleanup_code in 0 7; do
    cleanup_run="$cleanup_fixture/local-state/validations/test/batch/job-$cleanup_code"
    cleanup_actual=0
    ZLLVM_PROJECT_ROOT="$cleanup_fixture" CLEANUP_TEST_BINARY="$cleanup_binary" CLEANUP_TEST_EXIT="$cleanup_code" \
        "$cleanup_runner" --output-root "$cleanup_run" test -- "$cleanup_fixture/tools/zig" test --cache-dir "$cleanup_run/zig-local-cache" > "$cleanup_fixture/job-$cleanup_code.log" 2>&1 || cleanup_actual=$?
    test "$cleanup_actual" = "$cleanup_code"
    test ! -e "$cleanup_run/zig-local-cache"
    test -f "$cleanup_run/test.json"
    test -s "$cleanup_run/test.log"
done
cleanup_run="$cleanup_fixture/local-state/validations/test/batch/failed-bookkeeping"
cleanup_actual=0
ZLLVM_PROJECT_ROOT="$cleanup_fixture" CLEANUP_TEST_BINARY="$cleanup_binary" CLEANUP_TEST_EXIT=7 CLEANUP_BREAK_FINISH=1 \
    "$cleanup_runner" --output-root "$cleanup_run" test -- "$cleanup_fixture/tools/zig" test --cache-dir "$cleanup_run/zig-local-cache" > "$cleanup_fixture/bookkeeping.log" 2>&1 || cleanup_actual=$?
test "$cleanup_actual" = 7
test -f "$cleanup_run/zig-local-cache/o/test"
"${ZIGREP:-zigrep}" --no-config -q -F 'storage completion deferred' "$cleanup_fixture/bookkeeping.log"
chmod 700 "$cleanup_fixture/local-state/storage-cleanup/jobs"
cleanup_run=local-state/validations/test/batch/shared
mkdir -p "$cleanup_fixture/$cleanup_run"
printf 'identical immutable IR\n' > "$cleanup_fixture/$cleanup_run/one.ll"
cp -- "$cleanup_fixture/$cleanup_run/one.ll" "$cleanup_fixture/$cleanup_run/two.ll"
cleanup_sha=$(sha256sum "$cleanup_fixture/$cleanup_run/one.ll"); cleanup_sha=${cleanup_sha%% *}
printf '%s  %s\n' "$cleanup_sha" "$cleanup_run/one.ll" > "$cleanup_fixture/current.sha256"
printf '{"schema":1,"minimum_idle_hours":0,"current_manifests":["current.sha256"]}\n' > "$cleanup_fixture/docs/storage_cleanup_policy.json"
"${JQZ:-jqz}" -n --arg sha "$cleanup_sha" --arg one "$cleanup_run/one.ll" --arg two "$cleanup_run/two.ll" '{schema:"zllvm-shared-inputs-v1",inputs:[{sha256:$sha,paths:[$one,$two]}]}' > "$cleanup_fixture/inputs.json"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" share-inputs --inputs inputs.json > "$cleanup_fixture/share-review.log" 2>&1
test "$(stat -c %i "$cleanup_fixture/$cleanup_run/one.ll")" != "$(stat -c %i "$cleanup_fixture/$cleanup_run/two.ll")"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" share-inputs --inputs inputs.json --apply > "$cleanup_fixture/share-apply.log" 2>&1
test "$(stat -c %i "$cleanup_fixture/$cleanup_run/one.ll")" = "$(stat -c %i "$cleanup_fixture/$cleanup_run/two.ll")"
test "$(stat -c %a "$cleanup_fixture/$cleanup_run/one.ll")" = 444
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" share-inputs --inputs inputs.json --apply > "$cleanup_fixture/share-repeat.log" 2>&1
test ! -e "$cleanup_fixture/local-state/storage-cleanup/pending.json"
printf 'Six lifecycle/input CLI checks passed: successful and failed producers, failed completion bookkeeping, read-only review, shared migration and repeat.\n'
