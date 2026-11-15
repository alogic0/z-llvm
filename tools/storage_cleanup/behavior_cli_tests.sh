#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -- "$1")
behavior_binary=$(realpath -- "$2")
audit_binary=$(realpath -- "$3")
backend_binary=$(realpath -- "$4")
behavior_fixture=$(mktemp -d /tmp/zllvm-behavior-storage-cli-XXXXXXXX)
export ZLLVM_STORAGE_ROOT="$behavior_fixture"
unset ZLLVM_REQUIRE_MANAGED_STORAGE ZLLVM_EVIDENCE_ROOT ZLLVM_TEMPORARY_ROOT ZLLVM_RUN_ROOT ZLLVM_TEMP_ROOT
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
    if [[ -n ${ZLLVM_EVIDENCE_ROOT:-} ]]; then
        test "$ZLLVM_EVIDENCE_ROOT/captures" = "$ZLLVM_WHOLE_CAPTURE_ROOT"
        test "$ZLLVM_TEMPORARY_ROOT" = "$work"
        test "$ZLLVM_REQUIRE_MANAGED_STORAGE" = 1
    fi
    test "$ZLLVM_WHOLE_PROFILE_EVENTS" = 1
    if [[ $work == */local-failed/* ]]; then
        mkdir -p "$ZLLVM_WHOLE_CAPTURE_ROOT/123" "$work/captures/123"
        printf 'unique captured input\n' > "$ZLLVM_WHOLE_CAPTURE_ROOT/123/input.ll"
        printf 'raw compiler events\n' > "$ZLLVM_WHOLE_CAPTURE_ROOT/123/profile.events.jsonl"
        printf '{"object_complete":false}\n' > "$ZLLVM_WHOLE_CAPTURE_ROOT/123/invocation.json"
        printf 'partial object\n' > "$work/captures/123/local.o"
        exit 7
    fi
    cat > "$TMPDIR/probe.ll" <<'IR'
target triple = "x86_64-unknown-linux-gnu"
define i64 @probe(i64 %x) {
entry:
  %y = add i64 %x, 1
  ret i64 %y
}
IR
    if [[ $ZLLVM_PIPELINE == preopt ]]; then
        test "$ZLLVM_ZIG_MODE" = ReleaseSafe
        behavior_probe=$(realpath --relative-to "$PWD" "$TMPDIR/probe.ll")
        "$ZLLVM_EXE" --passes=zig-release-safe-accepted --input-limit=67108864 "$behavior_probe" > "$work/optimized.ll"
        behavior_optimized=$(realpath --relative-to "$PWD" "$work/optimized.ll")
        "$ZLLVM_EXE" --emit=obj --target=x86_64-unknown-linux-gnu --input-limit=67108864 "$behavior_optimized" > "$work/delivered.o"
    else
        "$ZLLVM_EXE" --emit=obj --target=x86_64-unknown-linux-gnu "$TMPDIR/probe.ll" > "$work/delivered.o"
    fi
    printf 'local proxy delivered an object\n' > "$ZLLVM_MARKER_PATH"
fi
case "$work" in */failed/*) exit 7;; esac
EOF
chmod 755 "$behavior_fixture/bin/git" "$behavior_fixture/frontend"
cat > "$behavior_fixture/optimizer-failure" <<'EOF'
#!/usr/bin/env bash
case "$1" in --passes=*) printf 'partial optimizer output\n'; printf 'injected optimizer failure\n' >&2; exit 7;; *) exit 93;; esac
EOF
chmod 755 "$behavior_fixture/optimizer-failure"
cat > "$behavior_fixture/census.jsonl" <<'EOF'
{"event":"function","function":"probe","selected":true}
{"event":"complete","examined":1,"selected":1,"failed":0}
EOF
for behavior_case in passed pipeline failed local-failed legacy local-passed legacy-local preopt-reference preopt-passed preopt-failed; do
    behavior_run=$behavior_evidence/$behavior_case
    behavior_work=$behavior_temporary/$behavior_case/.workspaces/validation
    behavior_options=()
    behavior_managed=1
    behavior_route=llvm
    if [[ $behavior_case == pipeline ]]; then behavior_options=(--retain-products --reference-report "$behavior_fixture/$behavior_evidence/passed/report.json"); fi
    if [[ $behavior_case == local-failed ]]; then behavior_route=local; behavior_options=(--zllvm "$behavior_fixture/backend" --profile-events); fi
    if [[ $behavior_case == local-passed || $behavior_case == legacy-local ]]; then behavior_route=local; behavior_options=(--zllvm "$backend_binary" --profile-events); fi
    if [[ $behavior_case == local-passed ]]; then behavior_options+=(--retain-products); fi
    if [[ $behavior_case == preopt-reference ]]; then behavior_options=(--test-filter probe); fi
    if [[ $behavior_case == preopt-passed || $behavior_case == preopt-failed ]]; then
        read -r behavior_reference_sha _ < <(sha256sum "$behavior_fixture/$behavior_evidence/preopt-reference/report.json")
        behavior_route=local
        behavior_options=(--zllvm "$backend_binary" --local-pipeline preopt --profile-events --test-filter probe --retain-products --reference-report "$behavior_fixture/$behavior_evidence/preopt-reference/report.json" --reference-sha256 "$behavior_reference_sha")
        if [[ $behavior_case == preopt-failed ]]; then behavior_options[1]="$behavior_fixture/optimizer-failure"; fi
    fi
    if [[ $behavior_case == legacy || $behavior_case == legacy-local ]]; then behavior_run=$behavior_case; behavior_work=$behavior_case; behavior_managed=0; fi
    behavior_actual=0
    env PATH="$behavior_fixture/bin:$PATH" ZLLVM_PROJECT_ROOT="$behavior_fixture" ZLLVM_REQUIRE_MANAGED_STORAGE="$behavior_managed" \
        "$behavior_binary" --output-root "$behavior_fixture/$behavior_run" --compiler "$behavior_fixture/frontend" \
        --zig-source "$behavior_fixture/upstream" --libc-file "$behavior_fixture/libc.txt" --mode ReleaseSafe --route "$behavior_route" \
        "${behavior_options[@]}" > "$behavior_fixture/$behavior_case.log" 2>&1 || behavior_actual=$?
    behavior_expected=0
    if [[ $behavior_case == failed || $behavior_case == local-failed || $behavior_case == preopt-failed ]]; then behavior_expected=1; fi
    test "$behavior_actual" = "$behavior_expected"
    test -f "$behavior_fixture/$behavior_work/behavior"
    test -f "$behavior_fixture/$behavior_run/report.json"
    test -f "$behavior_fixture/$behavior_run/commands.json"
    if (( behavior_managed == 1 )); then
        test ! -e "$behavior_fixture/$behavior_run/local-cache"
        test ! -e "$behavior_fixture/$behavior_run/behavior"
        test -f "$behavior_fixture/$behavior_run/validation.storage-layout.json"
    fi
    if (( behavior_actual == 0 )); then
        "${JQZ:-jqz}" -e '.status == "passed" and .tests == 2 and .outcomes[1].outcome == "SKIP"' "$behavior_fixture/$behavior_run/report.json" > /dev/null
    else
        "${JQZ:-jqz}" -e '.status == "failed" and .error == "BehaviorCompileFailed"' "$behavior_fixture/$behavior_run/report.json" > /dev/null
    fi
    if [[ $behavior_case == preopt-passed ]]; then
        "${JQZ:-jqz}" -e 'length(.optimizations) == 1 and .optimizations[0].optimization_complete == true and .optimizations[0].object_complete == false and .captures[0].object_delivered == true and .stage_chains_complete == true and .reference_outcomes_match == true' "$behavior_fixture/$behavior_run/report.json" > /dev/null
        test -f "$behavior_fixture/$behavior_run/space.json"
    fi
    if [[ $behavior_case == preopt-failed ]]; then
        "${JQZ:-jqz}" -e 'length(.optimizations) == 1 and length(.captures) == 0 and .optimizations[0].optimization_complete == false and .optimizations[0].output_delivered == false and .optimizations[0].returncode == 7' "$behavior_fixture/$behavior_run/report.json" > /dev/null
    fi
    if [[ $behavior_case == local-passed || $behavior_case == legacy-local || $behavior_case == preopt-passed ]]; then
        "${JQZ:-jqz}" -e 'length(.captures) == 1 and .captures[0].object_complete == true' "$behavior_fixture/$behavior_run/report.json" > /dev/null
        behavior_capture=$("${JQZ:-jqz}" -r '.captures[0].directory' "$behavior_fixture/$behavior_run/report.json")
        behavior_object=$("${JQZ:-jqz}" -r '.captures[0].object.path' "$behavior_fixture/$behavior_run/report.json")
        test -f "$behavior_object"
        env ZLLVM_PROJECT_ROOT="$behavior_fixture" "$audit_binary" --capture-root "$behavior_fixture/$behavior_run" \
            --capture-directory "$behavior_capture" --census "$behavior_fixture/census.jsonl" \
            --output-root "$behavior_fixture/$behavior_run/audit" > "$behavior_fixture/audit-$behavior_case.log" 2>&1
        "${JQZ:-jqz}" -e '.status == "passed" and .definitions == 1' "$behavior_fixture/$behavior_run/audit/report.json" > /dev/null
        if [[ $behavior_case == preopt-passed ]]; then
            behavior_optimized=$("${JQZ:-jqz}" -r '.optimizations[0].output.path' "$behavior_fixture/$behavior_run/report.json")
            mv -- "$behavior_optimized" "$behavior_optimized.saved"
            printf 'changed optimizer output\n' > "$behavior_optimized"
            behavior_chain_actual=0
            env ZLLVM_PROJECT_ROOT="$behavior_fixture" "$audit_binary" --capture-root "$behavior_fixture/$behavior_run" \
                --capture-directory "$behavior_capture" --census "$behavior_fixture/census.jsonl" \
                --output-root "$behavior_fixture/$behavior_run/audit-chain-changed" > "$behavior_fixture/audit-chain-changed.log" 2>&1 || behavior_chain_actual=$?
            test "$behavior_chain_actual" = 1
            "${ZIGREP:-zigrep}" --no-config -q -F OptimizerArtifactChanged "$behavior_fixture/audit-chain-changed.log"
            rm -- "$behavior_optimized"
            mv -- "$behavior_optimized.saved" "$behavior_optimized"
        fi
        if (( behavior_managed == 1 )); then
            test ! -e "$behavior_capture/local.o"
            # A valid evidence copy cannot substitute for a missing managed
            # product. Keep reports and commands unchanged for this control.
            cp -- "$behavior_object" "$behavior_capture/local.o"
            mv -- "$behavior_object" "$behavior_object.saved"
            behavior_audit_actual=0
            env ZLLVM_PROJECT_ROOT="$behavior_fixture" "$audit_binary" --capture-root "$behavior_fixture/$behavior_run" \
                --capture-directory "$behavior_capture" --census "$behavior_fixture/census.jsonl" \
                --output-root "$behavior_fixture/$behavior_run/audit-missing" > "$behavior_fixture/audit-missing.log" 2>&1 || behavior_audit_actual=$?
            test "$behavior_audit_actual" = 1
            "${ZIGREP:-zigrep}" --no-config -q -F FileNotFound "$behavior_fixture/audit-missing.log"
            mv -- "$behavior_object.saved" "$behavior_object"
            rm -- "$behavior_capture/local.o"
        else
            test "$behavior_object" = "$behavior_capture/local.o"
        fi
    fi
    sha256sum "$behavior_fixture/$behavior_run/report.json" "$behavior_fixture/$behavior_run/commands.json" > "$behavior_fixture/$behavior_case.sha256"
    ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/collect-$behavior_case.log" 2>&1
    if [[ $behavior_case == passed || $behavior_case == preopt-reference ]]; then test ! -e "$behavior_fixture/$behavior_work"; else test -f "$behavior_fixture/$behavior_work/behavior"; fi
    sha256sum --check --status "$behavior_fixture/$behavior_case.sha256"
done
for behavior_guard in reference reserve; do
    behavior_run=$behavior_evidence/preopt-guard-$behavior_guard
    behavior_guard_options=()
    read -r behavior_reference_sha _ < <(sha256sum "$behavior_fixture/$behavior_evidence/preopt-reference/report.json")
    behavior_guard_error=ReferenceIdentityChanged
    if [[ $behavior_guard == reference ]]; then behavior_reference_sha=0000000000000000000000000000000000000000000000000000000000000000; else behavior_guard_options=(--reserve-bytes 2000000000000); behavior_guard_error=InsufficientAdmissionSpace; fi
    behavior_guard_actual=0
    env PATH="$behavior_fixture/bin:$PATH" ZLLVM_PROJECT_ROOT="$behavior_fixture" ZLLVM_REQUIRE_MANAGED_STORAGE=1 \
        "$behavior_binary" --output-root "$behavior_fixture/$behavior_run" --compiler "$behavior_fixture/frontend" \
        --zig-source "$behavior_fixture/upstream" --libc-file "$behavior_fixture/libc.txt" --mode ReleaseSafe --route local \
        --zllvm "$backend_binary" --local-pipeline preopt --test-filter probe --reference-report "$behavior_fixture/$behavior_evidence/preopt-reference/report.json" \
        --reference-sha256 "$behavior_reference_sha" "${behavior_guard_options[@]}" > "$behavior_fixture/guard-$behavior_guard.log" 2>&1 || behavior_guard_actual=$?
    test "$behavior_guard_actual" = 1
    "${JQZ:-jqz}" -r '.error' "$behavior_fixture/$behavior_run/report.json" | "${ZIGREP:-zigrep}" --no-config -q -F -x "$behavior_guard_error"
    if [[ $behavior_guard == reserve ]]; then "${JQZ:-jqz}" -e '.status == "failed" and .resource_stop == true and .failure_stage == "disk-admission"' "$behavior_fixture/$behavior_run/report.json" > /dev/null; fi
    test ! -e "$behavior_fixture/$behavior_run/compile.stderr"
    ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" release-workspace --layout "$behavior_run/validation.storage-layout.json" --reason 'Intentional reference or disk-admission failure verified before compilation; no remaining consumer' > "$behavior_fixture/guard-$behavior_guard-release.log" 2>&1
    ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/guard-$behavior_guard-collect.log" 2>&1
done
for behavior_guard in llvm Debug; do
    behavior_guard_options=(--mode ReleaseSafe --route llvm)
    if [[ $behavior_guard == Debug ]]; then behavior_guard_options=(--mode Debug --route local --zllvm "$backend_binary"); fi
    if ZLLVM_PROJECT_ROOT="$behavior_fixture" "$behavior_binary" --output-root "$behavior_fixture/reject-$behavior_guard" --local-pipeline preopt "${behavior_guard_options[@]}" > "$behavior_fixture/reject-$behavior_guard.log" 2>&1; then exit 1; fi
    test ! -e "$behavior_fixture/reject-$behavior_guard"
done
test -f "$behavior_fixture/$behavior_evidence/local-failed/captures/123/input.ll"
test -f "$behavior_fixture/$behavior_evidence/local-failed/captures/123/profile.events.jsonl"
test -f "$behavior_fixture/$behavior_temporary/local-failed/.workspaces/validation/captures/123/local.o"
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" release-workspace --layout "$behavior_evidence/pipeline/validation.storage-layout.json" --reason 'Named outcome comparison and consumers completed' > "$behavior_fixture/release.log" 2>&1
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/release-apply.log" 2>&1
test ! -e "$behavior_fixture/$behavior_temporary/pipeline/.workspaces/validation"
sha256sum --check --status "$behavior_fixture/pipeline.sha256"
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" release-workspace --layout "$behavior_evidence/local-passed/validation.storage-layout.json" --reason 'Managed capture audit and missing-object control completed' > "$behavior_fixture/audit-release.log" 2>&1
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/audit-release-apply.log" 2>&1
test ! -e "$behavior_fixture/$behavior_temporary/local-passed/.workspaces/validation"
sha256sum --check --status "$behavior_fixture/local-passed.sha256"
for behavior_case in preopt-passed preopt-failed; do
    ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" release-workspace --layout "$behavior_evidence/$behavior_case/validation.storage-layout.json" --reason 'Preopt stage/audit checks or injected optimizer failure diagnosed; all consumers completed' > "$behavior_fixture/$behavior_case-release.log" 2>&1
    ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/$behavior_case-release-apply.log" 2>&1
    test ! -e "$behavior_fixture/$behavior_temporary/$behavior_case/.workspaces/validation"
    sha256sum --check --status "$behavior_fixture/$behavior_case.sha256"
done
# A completed failure retains products until diagnosis, then permits an explicit
# release without rewriting the original failure report or diagnostic logs.
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" release-workspace --layout "$behavior_evidence/failed/validation.storage-layout.json" --reason 'Fixture compile failure diagnosed; no remaining consumer' > "$behavior_fixture/failure-release.log" 2>&1
ZLLVM_PROJECT_ROOT="$behavior_fixture" "$cleanup_binary" --minimal --apply > "$behavior_fixture/failure-release-apply.log" 2>&1
test ! -e "$behavior_fixture/$behavior_temporary/failed/.workspaces/validation"
sha256sum --check --status "$behavior_fixture/failed.sha256"
test -f "$behavior_fixture/$behavior_temporary/local-failed/.workspaces/validation/captures/123/local.o"
if ZLLVM_PROJECT_ROOT="$behavior_fixture" "$behavior_binary" --output-root "$behavior_fixture/unmanaged-retention" --mode ReleaseSafe --route llvm --retain-products > "$behavior_fixture/reject.log" 2>&1; then exit 1; fi
test ! -e "$behavior_fixture/unmanaged-retention"
printf 'Eleven behavior storage CLI checks passed: separate products, passed collection, pipeline retention/release with named reference outcomes, failed retention, reviewed failure release, local capture mapping and raw evidence, legacy compatibility, unmanaged pipeline rejection, managed real capture audit, legacy real capture audit and missing managed object rejection despite a valid evidence copy.\n'
printf 'Preopt CLI checks passed: separate real optimizer/object delivery, pinned reference outcomes, independent chain/object audit and mutation rejection, partial-output optimizer failure without emission, invalid route/mode rejection, wrong-reference rejection and stronger disk-reserve admission.\n'
