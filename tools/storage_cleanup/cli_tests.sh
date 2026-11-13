#!/usr/bin/env bash
set -euo pipefail
cleanup_binary=$(realpath -e -- "${1:?pass the compiled cleanup binary}")
cleanup_launcher=$(realpath -e -- "$(dirname -- "${BASH_SOURCE[0]}")/../clean-storage")
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
cleanup_run="$cleanup_fixture/local-state/validations/cli/build"
cleanup_source="$cleanup_fixture/local-state/validations/cli/source"
mkdir -p "$cleanup_run/zig-local-cache/o" "$cleanup_source" "$cleanup_fixture/toolchain"
printf 'private generated object\n' > "$cleanup_run/zig-local-cache/o/test.o"
printf 'retained compiler\n' > "$cleanup_run/z_llvm"
printf 'successful build log\n' > "$cleanup_run/build.stdout"
: > "$cleanup_run/build.stderr"
printf 'pub fn main() void {}\n' > "$cleanup_source/main.zig"
printf 'toolchain\n' > "$cleanup_fixture/toolchain/zig"
cleanup_compiler_sha=$(sha256sum "$cleanup_run/z_llvm"); cleanup_compiler_sha=${cleanup_compiler_sha%% *}
cleanup_source_sha=$(sha256sum "$cleanup_source/main.zig"); cleanup_source_sha=${cleanup_source_sha%% *}
cleanup_zig_sha=$(sha256sum "$cleanup_fixture/toolchain/zig"); cleanup_zig_sha=${cleanup_zig_sha%% *}
cat > "$cleanup_run/report.json" <<EOF
{"status":"passed","source_root":"$cleanup_source","source_sha256":{"main.zig":"$cleanup_source_sha"},"compiler":"$cleanup_run/z_llvm","compiler_sha256":"$cleanup_compiler_sha","zig":"$cleanup_fixture/toolchain/zig","zig_sha256":"$cleanup_zig_sha","commands":[{"outcome":"completed","actual_returncode":0,"argv":["zig","build-exe","--cache-dir","$cleanup_run/zig-local-cache","-Mroot=$cleanup_source/main.zig","-femit-bin=$cleanup_run/z_llvm"],"stdout":"$cleanup_run/build.stdout","stderr":"$cleanup_run/build.stderr"}]}
EOF
# The ordinary 24-hour policy holds this newly completed cache.
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --apply --policy policy.json > "$cleanup_fixture/recent.log"
test -f "$cleanup_run/zig-local-cache/o/test.o"
"${ZIGREP:-zigrep}" --no-config -q -F 'TooRecent' "$cleanup_fixture/local-state/retirements"
printf '%064d  %s\n' 0 "$cleanup_source/main.zig" > "$cleanup_fixture/current.sha256"
printf '{"schema":1,"current_manifests":["current.sha256"]}\n' > "$cleanup_fixture/bad-current-policy.json"
if ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy bad-current-policy.json > "$cleanup_fixture/bad-current.log" 2>&1; then
    printf 'FAIL: bad current integrity manifest permitted collection\n' >&2; exit 1
fi
test -f "$cleanup_run/zig-local-cache/o/test.o"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy policy.json > "$cleanup_fixture/minimal.log"
test ! -e "$cleanup_run/zig-local-cache"
test -f "$cleanup_run/z_llvm"
test -f "$cleanup_source/main.zig"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 1;' "$cleanup_fixture/minimal.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_binary" --minimal --apply --policy policy.json > "$cleanup_fixture/repeat.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 0;' "$cleanup_fixture/repeat.log"
mkdir -p "$cleanup_fixture/docs"
cp -- "$cleanup_fixture/policy.json" "$cleanup_fixture/docs/storage_cleanup_policy.json"
cleanup_job_status=0
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_launcher" maintain -- bash -c '
    if flock --nonblock --exclusive "$1" true; then exit 91; fi
    exit 7
' _ "$cleanup_fixture/local-state/storage-cleanup/cleanup.lock" > "$cleanup_fixture/maintain-failure.log" 2>&1 || cleanup_job_status=$?
test "$cleanup_job_status" -eq 7
"${ZIGREP:-zigrep}" --no-config -q -F 'Cleanup complete:' "$cleanup_fixture/maintain-failure.log"
ZLLVM_PROJECT_ROOT="$cleanup_fixture" "$cleanup_launcher" maintain -- true > "$cleanup_fixture/maintain-success.log" 2>&1
"${ZIGREP:-zigrep}" --no-config -q -F 'Cleanup complete:' "$cleanup_fixture/maintain-success.log"
printf 'Nine isolated CLI checks passed: interruption, shared lease, empty apply, fresh-cache hold, current-manifest failure, minimal collection, idempotence, failed-job maintenance, successful-job maintenance.\n'
