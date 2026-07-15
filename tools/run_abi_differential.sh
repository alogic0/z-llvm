#!/usr/bin/env bash
set -euo pipefail

# INBOX-60: deliberately non-gating, postopt-only ABI differential evidence.
# This runner never invokes zig build, an AIR exporter, or a distribution gate.

readonly root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

readonly scratch="${1:-tmp/inbox60_abi_diff/run}"
readonly zig="${ZIG_EMITTER:-../ziglang/build/stage4/bin/zig}"
readonly zllvm="${ZLLVM_EXE:-zig-out/bin/z_llvm}"
readonly nm="${LLVM_NM:-/usr/lib/llvm-22/bin/llvm-nm}"
readonly objdump="${LLVM_OBJDUMP:-/usr/lib/llvm-22/bin/llvm-objdump}"
readonly zig_pin="bdee02bc0c7f227c0f11bc9a449df673fe803540"
readonly zig_version="0.17.0-dev.364+bdee02bc0"
readonly zllvm_baseline="0025b18b3339c98018d3e276c7120d73b6ad1682"
readonly zllvm_expected_digest="5653cc7eda5f1a915a4a2c583b37868048c2c345ca9425de53ee3806314401be"
readonly scratch_limit=$((256 * 1024 * 1024))
readonly target="x86_64-linux-gnu"
readonly cpu="baseline"

fail() {
    printf 'INBOX-60 fail-closed: %s\n' "$*" >&2
    exit 1
}

[[ ! -e "$scratch" ]] || fail "scratch path already exists (execution results are never reused): $scratch"
[[ -x "$zig" ]] || fail "missing pinned Zig: $zig"
[[ -x "$zllvm" ]] || fail "missing accepted z_llvm: $zllvm"
[[ -x "$nm" && -x "$objdump" ]] || fail "missing pinned LLVM object inspection tools"
[[ "$(git -C ../ziglang rev-parse HEAD)" == "$zig_pin" ]] || fail "patched Zig source pin mismatch"
[[ "$($zig version)" == "$zig_version" ]] || fail "reference compiler identity mismatch"
[[ "$(sha256sum "$zllvm" | awk '{print $1}')" == "$zllvm_expected_digest" ]] || fail "z_llvm executable identity mismatch"
git merge-base --is-ancestor "$zllvm_baseline" HEAD || fail "z_llvm source baseline is not an ancestor of HEAD"

mkdir -p "$scratch/global-cache" "$scratch/common-cache"

readonly cohort="test/abi_diff/cohort.zig"
readonly harness="test/abi_diff/harness.c"
readonly shim="test/abi_diff/abi_shim.S"
readonly body_digest="$(sha256sum "$cohort" | awk '{print $1}')"
readonly harness_digest="$(sha256sum "$harness" | awk '{print $1}')"
readonly shim_digest="$(sha256sum "$shim" | awk '{print $1}')"
readonly zllvm_digest="$(sha256sum "$zllvm" | awk '{print $1}')"

readonly symbols=(
    abi_neg_u64 abi_select_i32 abi_identity_u8 abi_identity_i16
    abi_pointer_load_store abi_load_u32 abi_identity_ptr abi_neg_u128
    abi_add_f32 abi_mul_f64
)

check_budget() {
    local used
    used="$(du -sb "$scratch" | awk '{print $1}')"
    (( used <= scratch_limit )) || fail "scratch budget exceeded: $used > $scratch_limit"
}

inspect_object() {
    local object="$1" listing="$2" disassembly="$3"
    "$nm" --defined-only "$object" > "$listing"
    "$objdump" -dr "$object" > "$disassembly"
    for symbol in "${symbols[@]}"; do
        [[ "$(awk -v symbol="$symbol" '$3 == symbol { count++ } END { print count + 0 }' "$listing")" == 1 ]] ||
            fail "object does not define exactly one $symbol: $object"
        rg -q "<(cohort\\.)?$symbol>:" "$disassembly" || fail "object disassembly missing $symbol: $object"
    done
}

linked_bodies_match() {
    local object="$1" executable="$2" output_dir="$3"
    local object_bytes executable_bytes
    mkdir -p "$output_dir"
    for symbol in "${symbols[@]}"; do
        "$objdump" -d --disassemble-symbols="$symbol" "$object" |
            awk '/^[[:space:]]*[0-9a-f]+:/ { for (i = 2; i <= NF && $i ~ /^[0-9a-f][0-9a-f]$/; i++) printf "%s", $i } END { print "" }' \
            > "$output_dir/$symbol.object.bytes"
        "$objdump" -d --disassemble-symbols="$symbol" "$executable" |
            awk '/^[[:space:]]*[0-9a-f]+:/ { for (i = 2; i <= NF && $i ~ /^[0-9a-f][0-9a-f]$/; i++) printf "%s", $i } END { print "" }' \
            > "$output_dir/$symbol.executable.bytes"
        [[ -s "$output_dir/$symbol.object.bytes" ]] || return 1
        object_bytes="$(tr -d '\n' < "$output_dir/$symbol.object.bytes")"
        executable_bytes="$(tr -d '\n' < "$output_dir/$symbol.executable.bytes")"
        [[ "$executable_bytes" == "$object_bytes"* ]] || return 1
    done
}

provenance_ok() {
    local reference="$1" candidate="$2" marker="$3" mode="$4" candidate_exe="$5" proof_dir="$6"
    [[ "$(sha256sum "$reference" | awk '{print $1}')" != "$(sha256sum "$candidate" | awk '{print $1}')" ]] || return 1
    rg -q '^pipeline=postopt ' "$marker" || return 1
    rg -q " mode=$mode$" "$marker" || return 1
    rg -q ' target=x86_64-unknown-linux-gnu ' "$marker" || return 1
    linked_bodies_match "$candidate" "$candidate_exe" "$proof_dir" || return 1
}

run_normal() {
    local exe="$1" stdout="$2" stderr="$3"
    local status
    set +e
    /usr/bin/timeout --signal=KILL 5 "$exe" > "$stdout" 2> "$stderr"
    status=$?
    set -e
    [[ $status == 0 ]] || fail "termination class was not normal for $exe (status=$status)"
}

"$zig" cc -c "$harness" -O2 -fno-lto -fno-stack-protector -target "$target" \
    -o "$scratch/harness.o"
"$zig" cc -c "$shim" -target "$target" -o "$scratch/abi_shim.o"

{
    printf 'directive=INBOX-60 status=provisional-non-gating\n'
    printf 'zig_source_commit=%s reference_compiler=%s\n' "$zig_pin" "$zig_version"
    printf 'zllvm_commit=%s zllvm_sha256=%s\n' "$zllvm_baseline" "$zllvm_digest"
    printf 'target=%s cpu=%s features=baseline\n' "$target" "$cpu"
    printf 'cohort_body_sha256=%s harness_sha256=%s shim_sha256=%s\n' "$body_digest" "$harness_digest" "$shim_digest"
    printf 'harness_object_sha256=%s shim_object_sha256=%s\n' \
        "$(sha256sum "$scratch/harness.o" | awk '{print $1}')" \
        "$(sha256sum "$scratch/abi_shim.o" | awk '{print $1}')"
} > "$scratch/report.txt"

real_execution_attempted=0
real_execution_matches=0

for mode in ReleaseFast ReleaseSafe ReleaseSmall; do
    mode_dir="$scratch/$mode"
    mkdir -p "$mode_dir/ref-cache" "$mode_dir/candidate-cache"
    reference="$mode_dir/reference.o"
    candidate="$mode_dir/candidate.o"
    marker="$mode_dir/candidate.marker"

    "$zig" build-obj "$cohort" "-O$mode" -target "$target" -mcpu="$cpu" \
        -fllvm -flibllvm -fno-lto -fno-stack-protector -fno-unwind-tables \
        --cache-dir "$mode_dir/ref-cache" --global-cache-dir "$scratch/global-cache" \
        -femit-bin="$reference"

    env ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE="$(realpath "$zllvm")" \
        ZLLVM_MARKER_PATH="$(realpath -m "$marker")" ZLLVM_ZIG_MODE="$mode" \
        "$zig" build-obj "$cohort" "-O$mode" -target "$target" -mcpu="$cpu" \
        -fllvm -flibllvm -fno-lto -fno-stack-protector -fno-unwind-tables \
        --cache-dir "$mode_dir/candidate-cache" --global-cache-dir "$scratch/global-cache" \
        -femit-bin="$candidate"

    inspect_object "$reference" "$mode_dir/reference.nm" "$mode_dir/reference.objdump"
    inspect_object "$candidate" "$mode_dir/candidate.nm" "$mode_dir/candidate.objdump"

    reference_exe="$mode_dir/reference.exe"
    candidate_exe="$mode_dir/candidate.exe"
    "$zig" cc "$scratch/harness.o" "$scratch/abi_shim.o" "$reference" -target "$target" \
        -o "$reference_exe"
    "$zig" cc "$scratch/harness.o" "$scratch/abi_shim.o" "$candidate" -target "$target" \
        -o "$candidate_exe"

    linked_bodies_match "$reference" "$reference_exe" "$mode_dir/reference-link-proof" ||
        fail "reference linked-body provenance rejected for $mode"
    provenance_ok "$reference" "$candidate" "$marker" "$mode" "$candidate_exe" \
        "$mode_dir/candidate-link-proof" ||
        fail "candidate provenance rejected for $mode"

    run_normal "$reference_exe" "$mode_dir/reference.stdout" "$mode_dir/reference.stderr"
    run_normal "$candidate_exe" "$mode_dir/candidate.stdout" "$mode_dir/candidate.stderr"
    cmp -s "$mode_dir/reference.stdout" "$mode_dir/candidate.stdout" ||
        fail "declared return/memory/termination mismatch for $mode"
    [[ "$(rg -c '^case=' "$mode_dir/reference.stdout")" == 15 ]] || fail "incomplete reference cohort for $mode"
    [[ "$(rg -c '^case=' "$mode_dir/candidate.stdout")" == 15 ]] || fail "incomplete candidate cohort for $mode"
    [[ "$(rg -c '^diag=identity_(u8|i16) upper_rax=' "$mode_dir/reference.stderr")" == 2 ]] ||
        fail "missing narrow-return diagnostics for reference $mode"
    [[ "$(rg -c '^diag=identity_(u8|i16) upper_rax=' "$mode_dir/candidate.stderr")" == 2 ]] ||
        fail "missing narrow-return diagnostics for candidate $mode"

    real_execution_attempted=$((real_execution_attempted + 15))
    real_execution_matches=$((real_execution_matches + 15))
    {
        printf 'mode=%s reference_object_sha256=%s candidate_object_sha256=%s cases=15 termination=normal result=match\n' \
            "$mode" "$(sha256sum "$reference" | awk '{print $1}')" \
            "$(sha256sum "$candidate" | awk '{print $1}')"
    } >> "$scratch/report.txt"
    check_budget
done

# Negative self-tests.  Success means the deliberately bad condition was rejected.
cp "$scratch/ReleaseFast/candidate.stdout" "$scratch/negative-value.stdout"
sed -i '1s/lo=/lo=1/' "$scratch/negative-value.stdout"
cmp -s "$scratch/ReleaseFast/reference.stdout" "$scratch/negative-value.stdout" &&
    fail "value-mismatch negative was accepted"

if provenance_ok "$scratch/ReleaseFast/reference.o" "$scratch/ReleaseFast/reference.o" \
    "$scratch/ReleaseFast/candidate.marker" ReleaseFast "$scratch/ReleaseFast/candidate.exe" \
    "$scratch/negative-substitution-proof"; then
    fail "reference-substitution negative was accepted"
fi

"$scratch/ReleaseFast/reference.exe" --negative-clobber || fail "callee-saved clobber was not detected"
"$scratch/ReleaseFast/reference.exe" --negative-write || fail "unauthorized memory write was not detected"
set +e
/usr/bin/timeout --signal=TERM 1 "$scratch/ReleaseFast/reference.exe" --negative-timeout \
    > "$scratch/negative-timeout.stdout" 2> "$scratch/negative-timeout.stderr"
timeout_status=$?
set -e
[[ $timeout_status == 124 ]] || fail "timeout negative was not canonicalized as timeout (status=$timeout_status)"

{
    printf 'negative=value-mismatch result=rejected\n'
    printf 'negative=reference-substitution result=rejected\n'
    printf 'negative=callee-saved-clobber result=rejected abi_bit=RBX\n'
    printf 'negative=timeout result=rejected termination=timeout\n'
    printf 'negative=unauthorized-memory-write result=rejected\n'
    printf 'real_execution_attempted=%u real_execution_matches=%u real_programs_ok=reserved\n' \
        "$real_execution_attempted" "$real_execution_matches"
    printf 'scratch_bytes=%s scratch_limit_bytes=%s status=pass\n' \
        "$(du -sb "$scratch" | awk '{print $1}')" "$scratch_limit"
} >> "$scratch/report.txt"

check_budget
cat "$scratch/report.txt"
