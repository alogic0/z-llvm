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
"$cleanup_zigrep" -q -F 'Removed 2 generated outputs' "$cleanup_fixture/apply.log"
for cleanup_case in first second; do
    test ! -e "$cleanup_fixture/$cleanup_run/$cleanup_case/capture-zllvm"
    test -f "$cleanup_fixture/$cleanup_run/$cleanup_case/input.ll"
    test -f "$cleanup_fixture/$cleanup_run/$cleanup_case/report.json"
    test -f "$cleanup_fixture/$cleanup_run/$cleanup_case/commands.json"
done
test ! -e "$cleanup_fixture/local-state/storage-cleanup/pending.json"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --requests "$cleanup_requests" > "$cleanup_fixture/repeat.log"
"$cleanup_zigrep" -q -F 'removed: 0;' "$cleanup_fixture/repeat.log"
printf 'Two generated-output CLI checks passed: preparation, grouped removal and repeated collection.\n'
