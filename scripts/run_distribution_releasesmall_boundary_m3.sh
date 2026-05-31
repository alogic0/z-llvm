#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

zig build >/dev/null

expect_control_flow_boundary() {
    local name="$1"
    local function_name="$2"
    local fixture="$3"
    local err="$tmp_dir/$name.err"

    if zig-out/bin/z_llvm --emit=obj --target="$target" --input-limit=67108864 "$fixture" > "$err" 2>&1; then
        printf 'error: expected ReleaseSmall boundary fixture to fail: %s\n' "$name" >&2
        return 1
    fi

    rg -q 'UnsupportedCodegenControlFlow' "$err"
    rg -q "codegen failed for function $function_name:" "$err"
    printf 'ok distribution releasesmall boundary %s [unsupported-control-flow]\n' "$name"
}

expect_control_flow_boundary \
    "standalone_emit_llvm_no_bin_str_from_float_help" \
    "main.strFromFloatHelp" \
    "test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll"

expect_control_flow_boundary \
    "standalone_mix_o_files_base64_decode_base_64" \
    "base64.decode_base_64" \
    "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll"
