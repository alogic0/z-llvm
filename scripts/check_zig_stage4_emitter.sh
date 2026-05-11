#!/usr/bin/env bash
set -euo pipefail

zig_source_dir="${ZIG_SOURCE_DIR:-../ziglang}"
zig_emitter="${ZIG_EMITTER:-$zig_source_dir/build/stage4/bin/zig}"

if [[ ! -x "$zig_emitter" ]]; then
  printf 'missing executable Zig emitter: %s\n' "$zig_emitter" >&2
  exit 1
fi

head_rev="$(git -C "$zig_source_dir" rev-parse --short=9 HEAD)"
version="$("$zig_emitter" version)"

if [[ "$version" != *"$head_rev"* ]]; then
  printf 'stage4 Zig version does not match %s HEAD\n' "$zig_source_dir" >&2
  printf '  HEAD:    %s\n' "$head_rev" >&2
  printf '  version: %s\n' "$version" >&2
  exit 1
fi

printf 'ok stage4 emitter %s matches %s HEAD %s\n' "$version" "$zig_source_dir" "$head_rev"
