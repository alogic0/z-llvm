#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -- "$1")
cleanup_runner=$(realpath -- "$2")
cleanup_evidence=${3:-}
if [[ -n $cleanup_evidence ]]; then
    [[ $cleanup_evidence == /* ]]
    mkdir "$cleanup_evidence"
fi
cleanup_fixture=$(mktemp -d "${TMPDIR:-/tmp}/zllvm-workspace-cli-XXXXXXXX")
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
test -z "${ZLLVM_RUN_ROOT+x}"
test -z "${ZLLVM_TEMP_ROOT+x}"
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
printf 'kept analysis\n' > "$ZLLVM_RUN_ROOT/analysis.txt"
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
    test "$(cat "$cleanup_fixture/$cleanup_run/analysis.txt")" = 'kept analysis'
    "${JQZ:-jqz}" -e --arg evidence "$cleanup_fixture/$cleanup_run" --arg work "$cleanup_fixture/$cleanup_work" \
        '.storage.evidence_root == $evidence and .storage.temporary_root == $work and .storage.lifetime == "validation" and length(.storage.caller_owned_overrides) == 0' \
        "$cleanup_fixture/$cleanup_run/check.json" > /dev/null
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
"${JQZ:-jqz}" -e --arg path "$cleanup_fixture/shared-cache" \
    'length(.storage.caller_owned_overrides) == 1 and .storage.caller_owned_overrides[0].variable == "ZIG_LOCAL_CACHE_DIR" and .storage.caller_owned_overrides[0].path == $path' \
    "$cleanup_fixture/$cleanup_run/check.json" > /dev/null
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
# Pipeline products survive a successful producer until the owner closes its consumers.
cleanup_run=local-state/validations/test/batch/pipeline
cleanup_work=local-state/tmp/validations/test/batch/pipeline/.workspaces/check
env -u TMPDIR -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR \
    ZLLVM_PROJECT_ROOT="$cleanup_fixture" CLEANUP_TEST_BINARY="$cleanup_binary" \
    "$cleanup_runner" --retain-products --output-root "$cleanup_fixture/$cleanup_run" check -- "$cleanup_fixture/tools/produce" > "$cleanup_fixture/pipeline.log" 2>&1
test -f "$cleanup_fixture/$cleanup_work/test-exe"
"${JQZ:-jqz}" -e '.lifetime == "pipeline" and .state == "retained"' "$cleanup_fixture/$cleanup_run/check.storage-layout.json" > /dev/null
"${JQZ:-jqz}" -e '.storage.lifetime == "pipeline"' "$cleanup_fixture/$cleanup_run/check.json" > /dev/null
sha256sum "$cleanup_fixture/$cleanup_run/check.json" "$cleanup_fixture/$cleanup_run/check.log" "$cleanup_fixture/$cleanup_run/analysis.txt" > "$cleanup_fixture/pipeline.sha256"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" release-workspace --layout "$cleanup_run/check.storage-layout.json" --reason 'All comparison consumers completed' > "$cleanup_fixture/pipeline-release.log" 2>&1
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply > "$cleanup_fixture/pipeline-apply.log" 2>&1
test ! -e "$cleanup_fixture/$cleanup_work"
sha256sum --check --status "$cleanup_fixture/pipeline.sha256"
# Retention must not silently fall back to a mixed, unmanaged output directory.
cleanup_actual=0
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_runner" --retain-products --output-root "$cleanup_fixture/unmanaged" check -- touch "$cleanup_fixture/should-not-run" > "$cleanup_fixture/unmanaged.log" 2>&1 || cleanup_actual=$?
test "$cleanup_actual" = 2
test ! -e "$cleanup_fixture/unmanaged"
test ! -e "$cleanup_fixture/should-not-run"
printf 'Eleven workspace CLI checks passed: successful collection, failed retention, evidence hold, raw-trace guard, recorded cache override, repeat, held release refusal, reviewed failure release, pipeline retention, pipeline release and unmanaged retention rejection.\n'

# Exercise the nested whole-compiler producer through the real release and
# collection entry points. A fresh fixture owner scopes each independent case.
whole_case() (
    set -euo pipefail
    scenario=$1
    root=$cleanup_fixture/whole-$scenario
    run=local-state/validations/test/batch/compiler/run
    owner=local-state/tmp/validations/test/batch/compiler/run/.workspaces
    key=validation
    if [[ $scenario == sibling-key || $scenario == sibling-claims-genuine ]]; then key=sibling; fi
    work=$owner/$key
    mkdir -p "$root"/{src,tools,docs,local-state/storage-cleanup} "$root/$run" "$root/$work"
    cp "$cleanup_fixture/.zigversion" "$root/"
    cp "$cleanup_fixture/src/main.zig" "$root/src/"
    cp "$cleanup_fixture/tools/clean-storage" "$root/tools/"
    cd "$root"
    trap 's=$?; if (( s != 0 )); then printf "Failed whole-compiler fixture %s\n" "$scenario" >&2; for log in before release changed review apply; do if [[ -f $log.log ]]; then tail -8 "$log.log" >&2; fi; done; fi' EXIT
    export ZLLVM_PROJECT_ROOT=$root
    jq=${JQZ:-jqz}
    printf '%s\n' '{"schema":1,"minimum_idle_hours":0}' > docs/storage_cleanup_policy.json
    printf '%s\n' '{"schema":1,"paths":[]}' > local-state/storage-cleanup/holds.json
    printf '%s\n' 'owned scratch' > "$work/payload"
    layout=$run/$key.storage-layout.json
    release=$run/$key.workspace-release.json
    seed=$root/seed
    prefix=$root/$work/install
    cache=$root/$work/local-cache
    case "$scenario" in
        sibling-claims-genuine) prefix=$root/$owner/validation/install; cache=$root/$owner/validation/local-cache ;;
        other-workspace) prefix=$root/$owner/other/install; cache=$root/$owner/other/local-cache ;;
        other-prefix) prefix=$root/$owner/other/install ;;
        other-cache) cache=$root/$owner/other/local-cache ;;
    esac
    build=("$seed" build --cache-dir "$cache" --prefix "$prefix")
    case "$scenario" in
        duplicate-prefix) build+=(--prefix "$root/$owner/other/install") ;;
        duplicate-cache) build+=(--cache-dir "$root/$owner/other/local-cache") ;;
        prefix-alias) build+=(-p "$root/$owner/other/install") ;;
        equal-cache) build+=("--cache-dir=$root/$owner/other/local-cache") ;;
        option-terminator) build=("$seed" build -- --cache-dir "$cache" --prefix "$prefix") ;;
    esac
    if [[ $scenario == warmup ]]; then build+=(--help); fi
    json_args() {
        local word
        for word in "$@"; do "$jq" -n --arg value "$word" '$value'; done | "$jq" --ndjson 'collect'
    }
    json_args "${build[@]}" > "$run/build-command.json"
    actual=1
    reported=1
    completed=true
    status=completed
    schema=whole-compiler-diagnostic-v1
    population=whole-zig-compiler
    stdout=$root/$run/build.stdout
    case "$scenario" in
        incomplete) completed=false ;;
        mismatched-actual) actual=2 ;;
        mismatched-reported) reported=2 ;;
        interrupted) status=timed_out ;;
        schema) schema=another-producer ;;
        population) population=single-module ;;
        wrong-log) stdout=$root/$run/warmup.stdout ;;
    esac
    json_args /usr/bin/time -f $'wall_seconds=%e\nmax_rss_kb=%M\nexit_status=%x' -o "$root/$run/build.time" -- "${build[@]}" > timed-argv.json
    "$jq" -n --slurpfile args timed-argv.json --arg stdout "$stdout" --arg stderr "$root/$run/build.stderr" --arg state "$status" --argjson actual "$actual" --argjson reported "$reported" '[{argv:$args[0],stdout:$stdout,stderr:$stderr,outcome:$state,actual_returncode:$actual,returncode:$reported}]' > "$run/commands.json"
    "$jq" -n --slurpfile commands "$run/commands.json" --arg schema "$schema" --arg seed "$seed" --arg pop "$population" --argjson done "$completed" '{schema:$schema,population:$pop,status:"blocked",build_completed:$done,build_returncode:1,zig_emitter:{path:$seed},commands:$commands[0]}' > "$run/report.json"
    if [[ $scenario == bare ]]; then
        "$jq" '{schema,population,status}' "$run/report.json" > replacement
        mv replacement "$run/report.json"
    fi
    if [[ $scenario == zero ]]; then
        "$jq" 'update(.,.build_returncode,0)' "$run/report.json" > replacement
        mv replacement "$run/report.json"
    fi
    if [[ $scenario == runner-error ]]; then
        "$jq" '{schema,population,status,build_completed,build_returncode,zig_emitter,commands,runner_error:"early failure"}' "$run/report.json" > replacement
        mv replacement "$run/report.json"
    fi
    if [[ $scenario == changed-saved-argv ]]; then
        json_args "${build[@]}" --another-argument > "$run/build-command.json"
    fi
    if [[ $scenario == different-command-record ]]; then printf '[]\n' > "$run/commands.json"; fi
    report_hash=$(sha256sum "$run/report.json" | cut -d' ' -f1)
    commands_hash=$(sha256sum "$run/commands.json" | cut -d' ' -f1)
    "$jq" -n --arg run "$run" --arg work "$work" --arg key "$key" --arg rep "$report_hash" --arg cmd "$commands_hash" --arg reportfile "$run/report.json" --arg commandfile "$run/commands.json" '{schema:"zllvm-storage-workspace-v1",evidence_root:$run,temporary_root:$work,key:$key,state:"retained",lifetime:"pipeline",result:{path:$reportfile,sha256:$rep},diagnostics:[{path:$commandfile,sha256:$cmd}]}' > "$layout"
    if [[ $scenario == sibling-claims-genuine ]]; then
        mkdir -p "$owner/validation"
        printf 'genuine producer scratch\n' > "$owner/validation/payload"
        "$jq" --arg path "$owner/validation" 'update(update(.,.key,"validation"),.temporary_root,$path)' "$layout" > "$run/validation.storage-layout.json"
    fi
    if [[ $scenario == unbound ]]; then
        "$jq" 'update(.,.diagnostics,[])' "$layout" > replacement
        mv replacement "$layout"
    fi
    if [[ $scenario == changed-commands ]]; then printf '\n' >> "$run/commands.json"; fi
    if [[ $scenario == changed-report ]]; then printf '\n' >> "$run/report.json"; fi
    if [[ $scenario == held ]]; then "$jq" -n --arg run "$run" '{schema:1,paths:[$run]}' > local-state/storage-cleanup/holds.json; fi
    if [[ $scenario == pinned ]]; then
        sha256sum "$work/payload" > "$run/maintained.sha256"
        "$jq" -n --arg manifest "$run/maintained.sha256" '{schema:1,minimum_idle_hours:0,current_manifests:[$manifest]}' > docs/storage_cleanup_policy.json
    fi
    if [[ $scenario == reader ]]; then
        exec 8>local-state/storage-cleanup/cleanup.lock
        flock --shared 8
    fi
    if [[ $scenario == complete ]]; then
        "$cleanup_binary" --minimal --apply > before.log 2>&1
        test -e "$work/payload"
        test ! -e "$release"
    fi
    rc=0
    "$cleanup_binary" release-workspace --layout "$layout" --reason 'Terminal selector refusal diagnosed; object and trace consumers closed' > release.log 2>&1 || rc=$?
    printf '%s\n' "$rc" > release.exit
    if [[ $scenario == complete ]]; then
        test "$rc" = 0
        test -e "$release"
        test -e "$work/payload"
        sha256sum "$layout" "$run/report.json" "$run/commands.json" "$run/build-command.json" "$release" > prior.sha256
        cp "$run/commands.json" original-commands.json
        printf '\n' >> "$run/commands.json"
        rc=0
        "$cleanup_binary" --minimal --apply > changed.log 2>&1 || rc=$?
        printf '%s\n' "$rc" > changed.exit
        if [[ $rc == 0 ]]; then
            "$jq" -e '.removed==0' "$(sed -n 's/^Cleanup complete: //p' changed.log)" >/dev/null
        fi
        test -f "$work/payload"
        cp original-commands.json "$run/commands.json"
        "$cleanup_binary" --minimal > review.log 2>&1
        test -e "$work/payload"
        "$jq" -e --arg path "$work" '.mode=="review" and .ready==1 and .removed==0 and .current_integrity_verified and .actions[0].path==$path' "$(sed -n 's/^Review complete: //p' review.log)" >/dev/null
        "$cleanup_binary" --minimal --apply > apply.log 2>&1
        "$jq" -e --arg path "$work" '.mode=="apply" and .removed==1 and .current_integrity_verified and .actions[0].path==$path' "$(sed -n 's/^Cleanup complete: //p' apply.log)" >/dev/null
        test ! -e "$work"
        sha256sum --check --quiet prior.sha256
    else
        test "$rc" != 0
        test -e "$work/payload"
        test ! -e "$release"
        if [[ $scenario == sibling-claims-genuine ]]; then
            test -e "$owner/validation/payload"
            test ! -e "$run/validation.workspace-release.json"
        fi
    fi
    if [[ -n $cleanup_evidence ]]; then
        dest=$cleanup_evidence/$scenario
        mkdir "$dest"
        cp "$layout" "$dest/layout.fixture.json"
        if [[ $scenario == sibling-claims-genuine ]]; then cp "$run/validation.storage-layout.json" "$dest/genuine-owner.fixture.json"; fi
        cp "$run/report.json" "$dest/producer.fixture.json"
        cp "$run/commands.json" "$run/build-command.json" release.log release.exit "$dest/"
        if [[ $scenario == complete ]]; then
            cp "$release" "$dest/release.fixture.json"
            cp before.log changed.log changed.exit review.log apply.log "$dest/"
            for action in before changed review apply; do
                receipt=$(sed -n -e 's/^Review complete: //p' -e 's/^Cleanup complete: //p' "$action.log")
                if [[ -n $receipt ]]; then cp "$receipt" "$dest/$action.receipt.json"; fi
            done
        fi
    fi
    printf 'whole-compiler workspace %s passed\n' "$scenario"
)
for scenario in complete bare incomplete zero warmup mismatched-actual mismatched-reported interrupted runner-error schema population wrong-log changed-saved-argv different-command-record unbound held pinned reader changed-commands changed-report sibling-key sibling-claims-genuine other-workspace other-prefix other-cache duplicate-prefix duplicate-cache prefix-alias equal-cache option-terminator; do
    whole_case "$scenario"
done
