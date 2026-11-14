#!/usr/bin/env bash
set -euo pipefail
cache_binary=$(realpath -e -- "${1:?pass the compiled cleanup binary}")
cache_fixture=$(mktemp -d /tmp/zllvm-command-caches-XXXXXXXX)
cache_finish() {
    cache_status=$?
    if (( cache_status != 0 )); then tail -n 12 "$cache_fixture/"*.log >&2 || true; fi
    rm -r -- "$cache_fixture"
}
trap cache_finish EXIT
cache_run=local-state/validations/comparison/batch-01/run
mkdir -p "$cache_fixture/$cache_run/Debug/reference-cache" "$cache_fixture/src"
printf '0.17.0\n' > "$cache_fixture/.zigversion"
printf 'pub fn main() void {}\n' > "$cache_fixture/src/main.zig"
printf '{"schema":1,"current_manifests":[]}\n' > "$cache_fixture/policy.json"
printf '{"status":"passed"}\n' > "$cache_fixture/$cache_run/report.json"
printf 'generated object bytes\n' > "$cache_fixture/$cache_run/Debug/reference-cache/object"
: > "$cache_fixture/$cache_run/compile.stdout"
printf 'expected diagnostic\n' > "$cache_fixture/$cache_run/compile.stderr"
cat > "$cache_fixture/$cache_run/commands.json" <<EOF
[{"argv":["zig","build-obj","--cache-dir","$cache_fixture/$cache_run/Debug/reference-cache"],"outcome":"completed","returncode":1,"actual_returncode":1,"stdout":"$cache_fixture/$cache_run/compile.stdout","stderr":"$cache_fixture/$cache_run/compile.stderr"}]
EOF
printf '%s/report.json\n' "$cache_run" > "$cache_fixture/reports.txt"
export ZLLVM_PROJECT_ROOT=$cache_fixture
for cache_case in missing-reports missing-reason apply; do
    cache_args=(prepare-command-caches --policy policy.json)
    if [[ $cache_case != missing-reports ]]; then cache_args+=(--reports reports.txt); fi
    if [[ $cache_case != missing-reason ]]; then cache_args+=(--reason 'Closed comparison'); fi
    if [[ $cache_case == apply ]]; then cache_args+=(--apply); fi
    if "$cache_binary" "${cache_args[@]}" > "$cache_fixture/$cache_case.log" 2>&1; then
        printf 'Invalid preparation accepted: %s\n' "$cache_case" >&2; exit 1
    fi
    "${ZIGREP:-zigrep}" --no-config -q -e InvalidReleaseArguments -e PreparationIsReadOnly "$cache_fixture/$cache_case.log"
done
mkdir "$cache_fixture/isolated-owner"
if ZLLVM_PROJECT_ROOT="$cache_fixture/isolated-owner" "$cache_binary" --minimal --apply --policy policy.json > "$cache_fixture/wrong-root.log" 2>&1; then
    printf 'Explicit owner silently selected its parent project\n' >&2; exit 1
fi
"${ZIGREP:-zigrep}" --no-config -q -F ExplicitStorageRootMismatch "$cache_fixture/wrong-root.log"
test ! -e "$cache_fixture/local-state/retirements"
test -f "$cache_fixture/$cache_run/Debug/reference-cache/object"
"$cache_binary" prepare-command-caches --policy policy.json --reports reports.txt --reason 'Closed comparison' > "$cache_fixture/prepare.log"
cache_review=$(tail -n 1 "$cache_fixture/prepare.log")
test -f "$cache_fixture/$cache_run/Debug/reference-cache/object"
"$cache_binary" --minimal --apply --policy policy.json --requests "${cache_review%/*}/requests.json" > "$cache_fixture/apply.log"
test ! -e "$cache_fixture/$cache_run/Debug/reference-cache"
for cache_file in report.json commands.json compile.stdout compile.stderr; do test -f "$cache_fixture/$cache_run/$cache_file"; done
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 1;' "$cache_fixture/apply.log"
printf 'Command-cache preparation arguments, explicit owner rejection and guarded collection passed\n'
