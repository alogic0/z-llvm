#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -- "$1")
cleanup_runner=$(realpath -- "$2")
cleanup_launcher=$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")/../run-validation")
cleanup_fixture=$(mktemp -d /tmp/zllvm-worktree-cli-XXXXXXXX)
cleanup_owner=$cleanup_fixture/owner
cleanup_source=$cleanup_fixture/source-worktree
cleanup_finish() {
    cleanup_status=$?
    if (( cleanup_status != 0 )); then tail -n 15 "$cleanup_fixture/"*.log >&2 || true; fi
    chmod -R u+w -- "$cleanup_fixture"
    rm -r --one-file-system -- "$cleanup_fixture"
}
trap cleanup_finish EXIT
mkdir -p "$cleanup_owner/src" "$cleanup_owner/docs" "$cleanup_owner/tools"
printf '0.17.0\n' > "$cleanup_owner/.zigversion"
printf 'pub fn main() void {}\n' > "$cleanup_owner/src/main.zig"
printf '// launcher fixture\n' > "$cleanup_owner/tools/run_checked.zig"
printf '// launcher fixture\n' > "$cleanup_owner/tools/run_native_canary.zig"
cp -- "$cleanup_launcher" "$cleanup_owner/tools/run-validation"
printf '{"schema":1,"minimum_idle_hours":0}\n' > "$cleanup_owner/docs/storage_cleanup_policy.json"
cat > "$cleanup_owner/tools/clean-storage" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$1" = __finish-job
"$CLEANUP_TEST_BINARY" --minimal --apply || true
exit "$2"
EOF
cat > "$cleanup_owner/tools/produce" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$PWD" = "$CLEANUP_SOURCE_ROOT"
test "$ZLLVM_STORAGE_ROOT" = "$CLEANUP_STORAGE_ROOT"
mkdir -p "$ZIG_LOCAL_CACHE_DIR" "$ZIG_GLOBAL_CACHE_DIR"
printf 'temporary product\n' > "$ZLLVM_TEMP_ROOT/product"
printf 'private cache\n' > "$ZIG_LOCAL_CACHE_DIR/object"
printf 'external-source diagnostic\n'
exit "${CLEANUP_TEST_EXIT:-0}"
EOF
chmod 755 "$cleanup_owner/tools/clean-storage" "$cleanup_owner/tools/produce"
git -C "$cleanup_owner" init -q
git -C "$cleanup_owner" add .
git -C "$cleanup_owner" -c user.name=StorageTest -c user.email=storage-test@example.invalid commit -qm fixture
git -C "$cleanup_owner" worktree add -q --detach "$cleanup_source"
cleanup_invoke() {
    env -u TMPDIR -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR \
        ZLLVM_PROJECT_ROOT="$cleanup_source" ZLLVM_STORAGE_ROOT="$cleanup_owner" ZLLVM_REQUIRE_MANAGED_STORAGE=1 \
        CLEANUP_SOURCE_ROOT="$cleanup_source" CLEANUP_STORAGE_ROOT="$cleanup_owner" CLEANUP_TEST_BINARY="$cleanup_binary" \
        "$cleanup_runner" "$@"
}
for cleanup_case in passed failed; do
    cleanup_run=local-state/validations/worktree/batch/$cleanup_case
    cleanup_expected=0
    if [[ $cleanup_case == failed ]]; then cleanup_expected=7; fi
    cleanup_actual=0
    CLEANUP_TEST_EXIT=$cleanup_expected cleanup_invoke --output-root "$cleanup_owner/$cleanup_run" check -- "$cleanup_source/tools/produce" > "$cleanup_fixture/$cleanup_case.log" 2>&1 || cleanup_actual=$?
    test "$cleanup_actual" = "$cleanup_expected"
    test -f "$cleanup_owner/$cleanup_run/check.json"
    test -f "$cleanup_owner/$cleanup_run/check.storage-layout.json"
    test ! -e "$cleanup_source/local-state"
    "${JQZ:-jqz}" -e --arg cwd "$cleanup_source" '.cwd == $cwd' "$cleanup_owner/$cleanup_run/check.json" > /dev/null
    if [[ $cleanup_case == passed ]]; then
        test ! -e "$cleanup_owner/local-state/tmp/validations/worktree/batch/$cleanup_case/.workspaces/check"
    else
        test -f "$cleanup_owner/local-state/tmp/validations/worktree/batch/$cleanup_case/.workspaces/check/product"
    fi
done
# Nested checked tools retain the explicit owner and are collected after the parent closes.
cleanup_run=$cleanup_owner/local-state/validations/worktree/batch/nested
cleanup_invoke --output-root "$cleanup_run" outer -- "$cleanup_runner" --output-root "$cleanup_run/child" inner -- "$cleanup_source/tools/produce" > "$cleanup_fixture/nested.log" 2>&1
test -f "$cleanup_run/child/inner.storage-layout.json"
test ! -e "$cleanup_owner/local-state/tmp/validations/worktree/batch/nested/.workspaces/outer"
test ! -e "$cleanup_owner/local-state/tmp/validations/worktree/batch/nested/child/.workspaces/inner"
# Managed admission must fail before invoking commands or creating mixed output.
for cleanup_bad in "$cleanup_source/local-state/isolated/run" "$cleanup_owner/local-state/isolated/run"; do
    if cleanup_invoke --output-root "$cleanup_bad" rejected -- touch "$cleanup_fixture/should-not-run" > "$cleanup_fixture/rejected.log" 2>&1; then exit 1; fi
    test ! -e "$cleanup_bad"
    test ! -e "$cleanup_fixture/should-not-run"
done
mkdir -p "$cleanup_owner/local-state/validations/worktree/batch"
ln -s "$cleanup_source" "$cleanup_owner/local-state/validations/worktree/batch/alias"
if cleanup_invoke --output-root "$cleanup_owner/local-state/validations/worktree/batch/alias/escape" rejected -- true > "$cleanup_fixture/alias.log" 2>&1; then exit 1; fi
test ! -e "$cleanup_source/escape"
# A source identity is descriptive; collection cannot extend into that checkout.
printf 'keep source artifact\n' > "$cleanup_source/keep.o"
env ZLLVM_PROJECT_ROOT="$cleanup_owner" "$cleanup_binary" --minimal --apply > "$cleanup_fixture/repeat.log" 2>&1
test -f "$cleanup_source/keep.o"
test ! -e "$cleanup_owner/local-state/storage-cleanup/pending.json"
# Exercise the tracked launcher without recompiling a fixture. Its bootstrap
# must exec the runner so no waiting launcher argv falsely pins the finished run.
cat > "$cleanup_fixture/zig" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  build-exe)
    for arg in "$@"; do
      if [[ $arg == -femit-bin=* ]]; then cp -- "$CLEANUP_TEST_RUNNER" "${arg#-femit-bin=}"; exit 0; fi
    done
    exit 2 ;;
  run) exec "$CLEANUP_SOURCE_ROOT/tools/produce" ;;
  *) exit 2 ;;
esac
EOF
chmod 755 "$cleanup_fixture/zig"
env -u TMPDIR -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR \
    ZIG="$cleanup_fixture/zig" CLEANUP_TEST_RUNNER="$cleanup_runner" \
    CLEANUP_SOURCE_ROOT="$cleanup_source" CLEANUP_STORAGE_ROOT="$cleanup_owner" CLEANUP_TEST_BINARY="$cleanup_binary" \
    "$cleanup_owner/tools/run-validation" --project-root "$cleanup_source" --storage-root "$cleanup_owner" \
    --output-root local-state/validations/worktree/batch/launcher check run_native_canary > "$cleanup_fixture/launcher.log" 2>&1
test -f "$cleanup_owner/local-state/validations/worktree/batch/launcher/check.storage-layout.json"
test ! -e "$cleanup_owner/local-state/tmp/validations/worktree/batch/launcher/.workspaces/check"
test ! -e "$cleanup_source/local-state"
# Custom scripts get the same managed layout and literal argv forwarding.
cat > "$cleanup_source/tools/custom command" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$PWD" = "$CLEANUP_SOURCE_ROOT"
test "$ZLLVM_REQUIRE_MANAGED_STORAGE" = 1
printf '%s' "$1" > "$ZLLVM_RUN_ROOT/argument.txt"
printf 'temporary object\n' > "$ZLLVM_TEMP_ROOT/output.o"
printf 'custom diagnostic\n'
EOF
chmod 755 "$cleanup_source/tools/custom command"
cleanup_literal='spaces * ; $(must-not-run)'
for cleanup_case in command command-pipeline; do
    cleanup_retention=()
    if [[ $cleanup_case == command-pipeline ]]; then cleanup_retention=(--retain-products); fi
    cleanup_run=local-state/validations/worktree/batch/$cleanup_case
    cleanup_work=local-state/tmp/validations/worktree/batch/$cleanup_case/.workspaces/check
    env -u TMPDIR -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR \
        ZIG="$cleanup_fixture/zig" CLEANUP_TEST_RUNNER="$cleanup_runner" \
        CLEANUP_SOURCE_ROOT="$cleanup_source" CLEANUP_TEST_BINARY="$cleanup_binary" \
        "$cleanup_owner/tools/run-validation" --project-root "$cleanup_source" --storage-root "$cleanup_owner" "${cleanup_retention[@]}" \
        --output-root "$cleanup_run" check --command "$cleanup_source/tools/custom command" "$cleanup_literal" > "$cleanup_fixture/$cleanup_case.log" 2>&1
    test "$(cat "$cleanup_owner/$cleanup_run/argument.txt")" = "$cleanup_literal"
    test -f "$cleanup_owner/$cleanup_run/check.json"
    if [[ $cleanup_case == command ]]; then test ! -e "$cleanup_owner/$cleanup_work"; else test -f "$cleanup_owner/$cleanup_work/output.o"; fi
done
cleanup_actual=0
ZIG="$cleanup_fixture/zig" "$cleanup_owner/tools/run-validation" --output-root local-state/validations/worktree/batch/empty check --command > "$cleanup_fixture/empty-command.log" 2>&1 || cleanup_actual=$?
test "$cleanup_actual" = 2
test ! -e "$cleanup_owner/local-state/validations/worktree/batch/empty"
test ! -e "$cleanup_source/local-state"
printf 'Eleven worktree CLI checks passed: source cwd, passed collection, failed retention, nested ownership, unmanaged roots, symlink escape, external source preservation, native launcher collection, literal custom command arguments, custom pipeline retention and empty command rejection.\n'
