#!/usr/bin/env bash
set -euo pipefail

usage='usage: scripts/capture_zig_ir.sh <zig-source> <Debug|ReleaseSafe|ReleaseFast|ReleaseSmall> [target] [output.ll]'

source_path="${1:-}"
optimize_mode="${2:-}"
target_arg="${3:-x86_64-linux-gnu}"
output_path="${4:-}"

if [[ -z "$source_path" || -z "$optimize_mode" ]]; then
  printf '%s\n' "$usage" >&2
  exit 2
fi

case "$optimize_mode" in
  Debug|ReleaseSafe|ReleaseFast|ReleaseSmall) ;;
  *)
    printf 'unsupported optimize mode: %s\n%s\n' "$optimize_mode" "$usage" >&2
    exit 2
    ;;
esac

if [[ ! -f "$source_path" ]]; then
  printf 'missing Zig source: %s\n' "$source_path" >&2
  exit 1
fi

zig_source_dir="${ZIG_SOURCE_DIR:-../ziglang}"
zig_emitter="${ZIG_EMITTER:-$zig_source_dir/build/stage4/bin/zig}"
bash scripts/check_zig_stage4_emitter.sh >/dev/null

source_name="$(basename "$source_path" .zig)"
target_tag="${target_arg%%-*}"
if [[ -z "$output_path" ]]; then
  case "$optimize_mode" in
    Debug|ReleaseSafe)
      output_path="tmp/zig_ir/raw/$source_name.$optimize_mode.$target_tag.ll"
      ;;
    ReleaseFast|ReleaseSmall)
      output_path="test/zig/captured/$source_name.$optimize_mode.$target_tag.ll"
      ;;
  esac
fi

mkdir -p "$(dirname "$output_path")"

strip_flag=()
if [[ "$optimize_mode" == ReleaseFast || "$optimize_mode" == ReleaseSmall ]]; then
  strip_flag=(-fstrip)
fi

"$zig_emitter" build-obj \
  -fllvm \
  -flibllvm \
  "${strip_flag[@]}" \
  -fno-emit-bin \
  "-femit-llvm-ir=$output_path" \
  -O "$optimize_mode" \
  -target "$target_arg" \
  "$source_path"

printf 'wrote %s\n' "$output_path"
