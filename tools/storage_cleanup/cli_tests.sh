#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -e -- "${1:?pass the compiled cleanup binary}")
cleanup_fixture=$(mktemp -d /tmp/zllvm-storage-cli-XXXXXXXX)
trap 'rm -r -- "$cleanup_fixture"' EXIT
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
printf 'Three isolated CLI checks passed: interruption, shared reader lease, empty apply.\n'
