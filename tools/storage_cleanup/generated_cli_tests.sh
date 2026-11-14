#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -- "$1")
cleanup_fixture=$(mktemp -d /tmp/zllvm-generated-cli-XXXXXXXX)
cleanup_generated_finish() {
    cleanup_status=$?
    if (( cleanup_status != 0 )); then tail -n 12 "$cleanup_fixture/"*.log >&2 || true; fi
    chmod -R u+w -- "$cleanup_fixture"
    rm -rf -- "$cleanup_fixture"
}
trap cleanup_generated_finish EXIT
cleanup_jqz=${JQZ:-jqz}
cleanup_zigrep=${ZIGREP:-zigrep}
mkdir -p "$cleanup_fixture/src" "$cleanup_fixture/docs" "$cleanup_fixture/local-state/storage-cleanup"
printf '0.17.0\n' > "$cleanup_fixture/.zigversion"
printf 'pub fn main() void {}\n' > "$cleanup_fixture/src/main.zig"
printf '{"schema":1,"minimum_idle_hours":0}\n' > "$cleanup_fixture/docs/storage_cleanup_policy.json"
cleanup_run=local-state/validations/test/batch/integrated-generated
for cleanup_case in first second; do
    cleanup_owner="$cleanup_run/$cleanup_case"
    mkdir -p "$cleanup_fixture/$cleanup_owner"
    printf '\177ELFtemporary copied validation runner\n' > "$cleanup_fixture/$cleanup_owner/capture-zllvm"
    printf 'original input remains\n' > "$cleanup_fixture/$cleanup_owner/input.ll"
    printf '[]\n' > "$cleanup_fixture/$cleanup_owner/commands.json"
    cleanup_sha=$(sha256sum -- "$cleanup_fixture/$cleanup_owner/capture-zllvm")
    cleanup_sha=${cleanup_sha%% *}
    "$cleanup_jqz" -n --arg sha "$cleanup_sha" '{schema:"real-program-v1",status:"passed",tool_provenance:{binary_sha256:$sha},rows:[{mode:"ReleaseFast",status:"matched"}]}' > "$cleanup_fixture/$cleanup_owner/report.json"
    printf '%s/capture-zllvm\n' "$cleanup_owner" >> "$cleanup_fixture/paths.txt"
done
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" prepare-generated --paths paths.txt --reason 'Completed fixture outputs' > "$cleanup_fixture/prepare.log"
mapfile -t cleanup_reviews < <("$cleanup_zigrep" --no-config --files --hidden --no-ignore "$cleanup_fixture/local-state/retirements" -g generated-review.json)
test "${#cleanup_reviews[@]}" = 1
"$cleanup_jqz" -e '.prepared == 2 and length(.rejected) == 0' "${cleanup_reviews[0]}" > /dev/null
cleanup_requests=${cleanup_reviews[0]%/*}/requests.json
cleanup_requests=${cleanup_requests#"$cleanup_fixture/"}
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --requests "$cleanup_requests" > "$cleanup_fixture/apply.log"
"$cleanup_zigrep" -q -F 'Removed 2 verified files' "$cleanup_fixture/apply.log"
for cleanup_case in first second; do
    test ! -e "$cleanup_fixture/$cleanup_run/$cleanup_case/capture-zllvm"
    test -f "$cleanup_fixture/$cleanup_run/$cleanup_case/input.ll"
    test -f "$cleanup_fixture/$cleanup_run/$cleanup_case/report.json"
    test -f "$cleanup_fixture/$cleanup_run/$cleanup_case/commands.json"
done
test ! -e "$cleanup_fixture/local-state/storage-cleanup/pending.json"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --requests "$cleanup_requests" > "$cleanup_fixture/repeat.log"
"$cleanup_zigrep" -q -F 'removed: 0;' "$cleanup_fixture/repeat.log"
cleanup_run=local-state/validations/test/batch/integrated-aliases
for cleanup_case in first second third; do
    cleanup_owner="$cleanup_run/$cleanup_case"
    mkdir -p "$cleanup_fixture/$cleanup_owner"
    if [[ $cleanup_case == first ]]; then
        printf '\177ELFshared temporary validation runner\n' > "$cleanup_fixture/$cleanup_owner/capture-zllvm"
    else
        ln -- "$cleanup_fixture/$cleanup_run/first/capture-zllvm" "$cleanup_fixture/$cleanup_owner/capture-zllvm"
    fi
    printf '[]\n' > "$cleanup_fixture/$cleanup_owner/commands.json"
    cleanup_sha=$(sha256sum -- "$cleanup_fixture/$cleanup_owner/capture-zllvm"); cleanup_sha=${cleanup_sha%% *}
    "$cleanup_jqz" -n --arg sha "$cleanup_sha" '{schema:"real-program-v1",status:"passed",tool_provenance:{binary_sha256:$sha},rows:[{mode:"ReleaseFast",status:"matched"}]}' > "$cleanup_fixture/$cleanup_owner/report.json"
    printf '%s/capture-zllvm\n' "$cleanup_owner" >> "$cleanup_fixture/aliases.txt"
done
sed -n '1,2p' "$cleanup_fixture/aliases.txt" > "$cleanup_fixture/incomplete.txt"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" prepare-generated --paths incomplete.txt --reason 'Incomplete alias fixture' > "$cleanup_fixture/incomplete-prepare.log"
cleanup_review=$(tail -n 1 "$cleanup_fixture/incomplete-prepare.log")
cleanup_requests=${cleanup_review%/generated-review.json}/requests.json
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --complete-capture-aliases --requests "$cleanup_requests" > "$cleanup_fixture/incomplete-apply.log"
test -f "$cleanup_fixture/$cleanup_run/first/capture-zllvm"
test -f "$cleanup_fixture/$cleanup_run/second/capture-zllvm"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" prepare-generated --paths aliases.txt --reason 'Complete alias fixture' > "$cleanup_fixture/alias-prepare.log"
cleanup_review=$(tail -n 1 "$cleanup_fixture/alias-prepare.log")
cleanup_requests=${cleanup_review%/generated-review.json}/requests.json
printf '%s  %s\n' "$cleanup_sha" "$cleanup_run/third/capture-zllvm" > "$cleanup_fixture/current.sha256"
printf '{"schema":1,"minimum_idle_hours":0,"current_manifests":["current.sha256"]}\n' > "$cleanup_fixture/docs/storage_cleanup_policy.json"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --complete-capture-aliases --requests "$cleanup_requests" > "$cleanup_fixture/alias-held.log"
test -f "$cleanup_fixture/$cleanup_run/first/capture-zllvm"
test -f "$cleanup_fixture/$cleanup_run/second/capture-zllvm"
test -f "$cleanup_fixture/$cleanup_run/third/capture-zllvm"
printf '{"schema":1,"minimum_idle_hours":0}\n' > "$cleanup_fixture/docs/storage_cleanup_policy.json"
cleanup_blocks=$(stat -c %b "$cleanup_fixture/$cleanup_run/first/capture-zllvm")
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --complete-capture-aliases --requests "$cleanup_requests" > "$cleanup_fixture/alias-apply.log"
cleanup_report=$(tail -n 1 "$cleanup_fixture/alias-apply.log"); cleanup_report=${cleanup_report#Cleanup complete: }
"$cleanup_jqz" -e --argjson bytes "$((cleanup_blocks * 512))" '.removed == 3 and .reclaimed_allocated_file_bytes == $bytes' "$cleanup_fixture/$cleanup_report" > /dev/null
for cleanup_case in first second third; do test ! -e "$cleanup_fixture/$cleanup_run/$cleanup_case/capture-zllvm"; done
printf 'Five generated-output CLI checks passed: single-link and complete-alias batches, incomplete groups, current pins and repeated collection.\n'

cleanup_run=local-state/validations/test/batch/completed-products
for cleanup_case in first second; do
    cleanup_owner="$cleanup_run/$cleanup_case"
    mkdir -p "$cleanup_fixture/$cleanup_owner"
    if [[ $cleanup_case == first ]]; then
        printf '\177ELFshared completed test executable\n' > "$cleanup_fixture/$cleanup_owner/local"
    else
        ln -- "$cleanup_fixture/$cleanup_run/first/local" "$cleanup_fixture/$cleanup_owner/local"
    fi
    printf 'retained test input\n' > "$cleanup_fixture/$cleanup_owner/input.ll"
    printf 'retained compiler diagnostic\n' > "$cleanup_fixture/$cleanup_owner/compile.stderr"
    : > "$cleanup_fixture/$cleanup_owner/compile.stdout"
    printf '{"schema":"input-program-v1","status":"passed"}\n' > "$cleanup_fixture/$cleanup_owner/report.json"
    "$cleanup_jqz" -n --arg input "$cleanup_fixture/$cleanup_owner/input.ll" --arg output "$cleanup_fixture/$cleanup_owner/local" \
        --arg stdout "$cleanup_fixture/$cleanup_owner/compile.stdout" --arg stderr "$cleanup_fixture/$cleanup_owner/compile.stderr" \
        '[{argv:["cc",$input,"-o",$output],outcome:"completed",actual_returncode:0,returncode:0,stdout:$stdout,stderr:$stderr}]' > "$cleanup_fixture/$cleanup_owner/commands.json"
    printf '%s/report.json\n' "$cleanup_owner" >> "$cleanup_fixture/reports.txt"
done
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" prepare-outputs --reports reports.txt --reason 'Completed test products' > "$cleanup_fixture/products-prepare.log"
cleanup_review=$(tail -n 1 "$cleanup_fixture/products-prepare.log")
cleanup_requests=${cleanup_review%/generated-review.json}/requests.json
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --requests "$cleanup_requests" > "$cleanup_fixture/products-single.log"
test -f "$cleanup_fixture/$cleanup_run/first/local"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --complete-artifact-aliases --requests "$cleanup_requests" > "$cleanup_fixture/products-apply.log"
for cleanup_case in first second; do
    test ! -e "$cleanup_fixture/$cleanup_run/$cleanup_case/local"
    for cleanup_evidence in input.ll report.json commands.json compile.stderr; do
        test -f "$cleanup_fixture/$cleanup_run/$cleanup_case/$cleanup_evidence"
    done
done
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --complete-artifact-aliases --requests "$cleanup_requests" > "$cleanup_fixture/products-repeat.log"
"$cleanup_zigrep" -q -F 'removed: 0;' "$cleanup_fixture/products-repeat.log"
printf 'Three command-output CLI checks passed: explicit alias opt-in, completed owner bindings and repeat collection.\n'
