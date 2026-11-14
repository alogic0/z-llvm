#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -- "$1")
behavior_binary=$(realpath -- "$2")
behavior_fixture=$(mktemp -d /tmp/zllvm-behavior-storage-cli-XXXXXXXX)
# The collector also checks relative run paths in live process arguments.
# Distinct batches keep simultaneous protocol fixtures from holding each other.
behavior_batch=${behavior_fixture##*/}
behavior_evidence=local-state/validations/behavior/$behavior_batch
behavior_temporary=local-state/tmp/validations/behavior/$behavior_batch
behavior_finish() {
    behavior_status=$?
    if (( behavior_status != 0 )); then tail -n 20 "$behavior_fixture/"*.log >&2 || true; fi
    chmod -R u+w -- "$behavior_fixture"
    rm -r --one-file-system -- "$behavior_fixture"
}
trap behavior_finish EXIT
mkdir -p "$behavior_fixture/"{src,docs,tools,bin,upstream/test,upstream/lib}
printf '0.17.0\n' > "$behavior_fixture/.zigversion"
printf 'pub fn main() void {}\n' > "$behavior_fixture/src/main.zig"
printf '{"schema":1,"minimum_idle_hours":0}\n' > "$behavior_fixture/docs/storage_cleanup_policy.json"
printf '# fixture storage owner\n' > "$behavior_fixture/tools/clean-storage"
printf '// fixture upstream input\n' > "$behavior_fixture/upstream/test/behavior.zig"
printf 'fixture libc\n' > "$behavior_fixture/libc.txt"
printf 'fixture backend identity\n' > "$behavior_fixture/backend"
# Simulate the frozen-source identity only inside this isolated protocol test.
# No real upstream build or acceptance is claimed by these fixtures.
cat > "$behavior_fixture/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$1" = -C
case "$3" in
  rev-parse) printf '1c08b09d1c847f4f02c8216e3b62df323861a437\n' ;;
  diff) exit 0 ;;
  *) exit 2 ;;
esac
EOF
cat > "$behavior_fixture/frontend" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$1" = test
while (( $# )); do
    case "$1" in
      --cache-dir) local_cache=$2; shift ;;
      --global-cache-dir) global_cache=$2; shift ;;
      -femit-bin=*) executable=${1#-femit-bin=} ;;
    esac
    shift
done
work=${executable%/behavior}
test "$local_cache" = "$work/local-cache"
test "$global_cache" = "$work/global-cache"
test "$TMPDIR" = "$work/temp"
mkdir -p "$local_cache/o" "$global_cache/o"
printf 'private compiler cache\n' > "$local_cache/o/cache"
printf 'private global cache\n' > "$global_cache/o/cache"
cat > "$executable" <<'EXECUTABLE'
#!/usr/bin/env bash
printf '1/2 first...OK\n2/2 second...SKIP\n' >&2
EXECUTABLE
chmod 755 "$executable"
if [[ -n ${ZLLVM_WHOLE_CAPTURE_ROOT:-} ]]; then
    test "$ZLLVM_EVIDENCE_ROOT/captures" = "$ZLLVM_WHOLE_CAPTURE_ROOT"
    test "$ZLLVM_TEMPORARY_ROOT" = "$work"
    test "$ZLLVM_REQUIRE_MANAGED_STORAGE" = 1
    test "$ZLLVM_WHOLE_PROFILE_EVENTS" = 1
    mkdir -p "$ZLLVM_WHOLE_CAPTURE_ROOT/123" "$work/captures/123"
    printf 'unique captured input\n' > "$ZLLVM_WHOLE_CAPTURE_ROOT/123/input.ll"
    printf 'raw compiler events\n' > "$ZLLVM_WHOLE_CAPTURE_ROOT/123/profile.events.jsonl"
    printf '{"object_complete":false}\n' > "$ZLLVM_WHOLE_CAPTURE_ROOT/123/invocation.json"
    printf 'partial object\n' > "$work/captures/123/local.o"
    exit 7
fi
case "$work" in */failed/*) exit 7;; esac
EOF
chmod 755 "$behavior_fixture/bin/git" "$behavior_fixture/frontend"
for behavior_case in passed pipeline failed local-failed legacy; do
    behavior_run=$behavior_evidence/$behavior_case
    behavior_work=$behavior_temporary/$behavior_case/.workspaces/validation
    behavior_options=()
    behavior_managed=1
    behavior_route=llvm
    if [[ $behavior_case == pipeline ]]; then behavior_options=(--retain-products --reference-report "$behavior_fixture/$behavior_evidence/passed/report.json"); fi
    if [[ $behavior_case == local-failed ]]; then behavior_route=local; behavior_options=(--zllvm "$behavior_fixture/backend" --profile-events); fi
    if [[ $behavior_case == legacy ]]; then behavior_run=legacy; behavior_work=legacy; behavior_managed=0; fi
    behavior_actual=0
    env PATH="$behavior_fixture/bin:$PATH" ZLLVM_PROJECT_ROOT="$behavior_fixture" ZLLVM_REQUIRE_MANAGED_STORAGE="$behavior_managed" \
        "$behavior_binary" --output-root "$behavior_fixture/$behavior_run" --compiler "$behavior_fixture/frontend" \
        --zig-source "$behavior_fixture/upstream" --libc-file "$behavior_fixture/libc.txt" --mode ReleaseSafe --route "$behavior_route" \
        "${behavior_options[@]}" > "$behavior_fixture/$behavior_case.log" 2>&1 || behavior_actual=$?
    behavior_expected=0
    if [[ $behavior_case == failed || $behavior_case == local-failed ]]; then behavior_expected=1; fi
    test "$behavior_actual" = "$behavior_expected"
    test -f "$behavior_fixture/$behavior_work/behavior"
    test -f "$behavior_fixture/$behavior_run/report.json"
    test -f "$behavior_fixture/$behavior_run/commands.json"
    if [[ $behavior_case != legacy ]]; then
        test ! -e "$behavior_fixture/$behavior_run/local-cache"
        test ! -e "$behavior_fixture/$behavior_run/behavior"
        test -f "$behavior_fixture/$behavior_run/validation.storage-layout.json"
    fi
    if (( behavior_actual == 0 )); then
        "${JQZ:-jqz}" -e '.status == "passed" and .tests == 2 and .outcomes[1].outcome == "SKIP"' "$behavior_fixture/$behavior_run/report.json" > /dev/null
    else
        "${JQZ:-jqz}" -e '.status == "failed" and .error == "BehaviorCompileFailed"' "$behavior_fixture/$behavior_run/report.json" > /dev/null
    fi
    sha256sum "$behavior_fixture/$behavior_run/report.json" "$behavior_fixture/$behavior_run/commands.json" > "$behavior_fixture/$behavior_case.sha256"
    ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/collect-$behavior_case.log" 2>&1
    if [[ $behavior_case == passed ]]; then test ! -e "$behavior_fixture/$behavior_work"; else test -f "$behavior_fixture/$behavior_work/behavior"; fi
    sha256sum --check --status "$behavior_fixture/$behavior_case.sha256"
done
test -f "$behavior_fixture/$behavior_evidence/local-failed/captures/123/input.ll"
test -f "$behavior_fixture/$behavior_evidence/local-failed/captures/123/profile.events.jsonl"
test -f "$behavior_fixture/$behavior_temporary/local-failed/.workspaces/validation/captures/123/local.o"
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" release-workspace --layout "$behavior_evidence/pipeline/validation.storage-layout.json" --reason 'Named outcome comparison and consumers completed' > "$behavior_fixture/release.log" 2>&1
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/release-apply.log" 2>&1
test ! -e "$behavior_fixture/$behavior_temporary/pipeline/.workspaces/validation"
sha256sum --check --status "$behavior_fixture/pipeline.sha256"
# A completed failure retains products until diagnosis, then permits an explicit
# release without rewriting the original failure report or diagnostic logs.
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" release-workspace --layout "$behavior_evidence/failed/validation.storage-layout.json" --reason 'Fixture compile failure diagnosed; no remaining consumer' > "$behavior_fixture/failure-release.log" 2>&1
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/failure-release-apply.log" 2>&1
test ! -e "$behavior_fixture/$behavior_temporary/failed/.workspaces/validation"
sha256sum --check --status "$behavior_fixture/failed.sha256"
test -f "$behavior_fixture/$behavior_temporary/local-failed/.workspaces/validation/captures/123/local.o"
if ZLLVM_PROJECT_ROOT="$behavior_fixture" "$behavior_binary" --output-root "$behavior_fixture/unmanaged-retention" --mode ReleaseSafe --route llvm --retain-products > "$behavior_fixture/reject.log" 2>&1; then exit 1; fi
test ! -e "$behavior_fixture/unmanaged-retention"
printf 'Eight behavior storage CLI checks passed: separate products, passed collection, pipeline retention/release with named reference outcomes, failed retention, reviewed failure release, local capture mapping and raw evidence, legacy compatibility and unmanaged pipeline rejection.\n'
