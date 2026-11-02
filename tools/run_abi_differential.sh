#!/usr/bin/env bash
set -euo pipefail

# INBOX-66 mandatory Tier-2 audited-real-row ABI differential gate.

readonly root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

readonly scratch="${1:-tmp/inbox66_abi_diff/run-$$}"
readonly zig_source="${ZIG_SOURCE_DIR:-../ziglang}"
readonly zig="${ZIG_EMITTER:-$zig_source/build/stage4/bin/zig}"
readonly zllvm="${ZLLVM_EXE:-zig-out/bin/z_llvm}"
readonly nm="${LLVM_NM:-/usr/lib/llvm-22/bin/llvm-nm}"
readonly objdump="${LLVM_OBJDUMP:-/usr/lib/llvm-22/bin/llvm-objdump}"
readonly readelf="${LLVM_READELF:-/usr/lib/llvm-22/bin/llvm-readelf}"
readonly linker="${ABI_DIFF_LINKER:-cc}"
readonly timeout_bin="${TIMEOUT:-/usr/bin/timeout}"
source test/abi_diff/reference_identity.env
readonly zig_pin="$ABI_DIFF_SOURCE_REVISION"
readonly zig_version="$ABI_DIFF_REFERENCE_VERSION"
readonly accepted_source_head="3deafe0f"
readonly target="x86_64-linux-gnu"
readonly cpu="baseline"
readonly counter_schema="abi-diff-v2"
readonly historical_accepted_air_sha256="d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4"
readonly cohort_source_sha256="$ABI_DIFF_COHORT_SHA256"
readonly scratch_limit=$((512 * 1024 * 1024))
readonly cohort="test/abi_diff/compiler_rt.zig"
readonly cohort_manifest="test/abi_diff/cohort_manifest.tsv"
readonly panic_source="test/abi_diff/panic.zig"
readonly harness="test/abi_diff/harness.c"
readonly shim="test/abi_diff/abi_shim.S"

readonly rows=(
    compiler_rt.__negsi2
    compiler_rt.shift.__ashlsi3
    compiler_rt.fabs.__fabsh
    compiler_rt.__neghf2
    compiler_rt.mulo.__mulosi4
    compiler_rt.mulo.__mulodi4
    compiler_rt.__negti2
    compiler_rt.shift.__ashlti3
    compiler_rt.fabs.fabs
    compiler_rt.fmin.fmin
)
readonly aliases=(__negsi2 __ashlsi3 __fabsh __neghf2 __mulosi4 __mulodi4 __negti2 __ashlti3 fabs fmin)
readonly owners=(composed_block composed_cfg composed_block composed_block composed_block composed_cfg composed_block composed_cfg composed_block composed_cfg)

fail() {
    printf 'INBOX-66 fail-closed: %s\n' "$*" >&2
    exit 1
}

digest() {
    sha256sum "$1" | awk '{print $1}'
}

check_budget() {
    local used
    used="$(du -sb "$scratch" | awk '{print $1}')"
    (( used <= scratch_limit )) || fail "scratch budget exceeded: $used > $scratch_limit"
}

require_identity() {
    [[ ! -e "$scratch" ]] || fail "scratch already exists; execution results are never reused: $scratch"
    [[ -x "$zig" ]] || fail "missing pinned Zig: $zig"
    [[ -x "$zllvm" ]] || fail "missing current z_llvm: $zllvm"
    [[ -x "$nm" && -x "$objdump" && -x "$readelf" && -x "$timeout_bin" ]] ||
        fail "missing pinned object-inspection or timeout tool"
    command -v "$linker" >/dev/null || fail "missing native linker driver: $linker"
    [[ "$(<docs/evidence/ziglang_pin.txt)" == "$zig_pin" ]] ||
        fail "ABI reference contract differs from docs/evidence/ziglang_pin.txt; migrate and audit the cohort before running"
    [[ "$(git -C "$zig_source" rev-parse HEAD 2>/dev/null || true)" == "$zig_pin" ]] ||
        fail "patched Zig source pin mismatch: expected $zig_pin (select the pinned source via ZIG_SOURCE_DIR; run 'zig build test-unit' for isolated compiler tests)"
    [[ "$($zig version 2>/dev/null || true)" == "$zig_version" ]] ||
        fail "reference compiler identity mismatch: expected $zig_version (select the audited emitter via ZIG_EMITTER)"
    git merge-base --is-ancestor "$accepted_source_head" HEAD || fail "accepted O0 head is not an ancestor"
    [[ "$(digest "$cohort")" == "$cohort_source_sha256" ]] || fail "frozen compiler-rt cohort body source changed"
    [[ "$(wc -l < "$cohort_manifest")" == 11 ]] || fail "audited cohort is not exactly ten rows"
    for category in integer narrow-return pointer-memory i128 finite-fp; do
        [[ "$(awk -F '\t' -v category="$category" '$1 == category { count++ } END { print count + 0 }' "$cohort_manifest")" == 2 ]] ||
            fail "cohort category is not exactly two rows: $category"
    done
    rg -q $'^integer\t.*composed_block' "$cohort_manifest" || fail "cohort lacks composed_block"
    rg -q $'^integer\t.*composed_cfg' "$cohort_manifest" || fail "cohort lacks composed_cfg"
    while IFS=$'\t' read -r _ _ _ _ _ _ source source_sha _; do
        [[ "$source" == pinned_source ]] && continue
        [[ "$(digest "$zig_source/$source")" == "$source_sha" ]] || fail "pinned compiler-rt source changed: $source"
    done < "$cohort_manifest"
    mkdir -p "$scratch/global-cache" "$scratch/common"
}

validate_owner_manifest() {
    local manifest="$1" mode="$2"
    [[ "$(wc -l < "$manifest")" == 11 ]] || fail "$mode owner manifest does not contain ten rows"
    for index in "${!rows[@]}"; do
        [[ "$(awk -F '\t' -v row="${rows[$index]}" '$1 == row { print $2 }' "$manifest")" == "${owners[$index]}" ]] ||
            fail "$mode owner mismatch for ${rows[$index]}"
    done
    [[ "$(awk -F '\t' 'NR > 1 && $2 == "unassigned" { count++ } END { print count + 0 }' "$manifest")" == 0 ]] ||
        fail "$mode owner manifest contains unassigned"
}

symbol_line() {
    local object="$1" symbol="$2"
    "$readelf" -Ws "$object" | awk -v symbol="$symbol" '$NF == symbol { print; count++ } END { if (count != 1) exit 1 }'
}

symbol_body_digest() {
    local object="$1" symbol="$2" output="$3"
    "$objdump" -d --disassemble-symbols="$symbol" "$object" |
        awk '/^[[:space:]]*[0-9a-f]+:/ { for (i = 2; i <= NF && $i ~ /^[0-9a-f][0-9a-f]$/; i++) printf "%s", $i } END { print "" }' > "$output"
    [[ -s "$output" ]] || return 1
    digest "$output"
}

body_relocations() {
    local object="$1" start_hex="$2" size="$3"
    local start=$((16#$start_hex)) end=$((16#$start_hex + size)) in_text=0
    local offset info type value symbol rest off result=""
    while read -r offset info type value symbol rest; do
        if [[ "$offset $info $type $value $symbol $rest" == "Relocation section '.rela.text'"* ]]; then
            in_text=1
            continue
        fi
        if [[ "$offset" == Relocation && "$info" == section && "$type" != "'.rela.text'"* ]]; then
            in_text=0
            continue
        fi
        (( in_text == 1 )) || continue
        [[ "$offset" =~ ^[0-9a-fA-F]+$ ]] || continue
        off=$((16#$offset))
        (( off >= start && off < end )) || continue
        [[ "$symbol" == .LCPI* ]] || return 1
        result+="${offset}:${type}:${symbol},"
    done < <("$readelf" -r "$object")
    body_relocs="${result%,}"
    [[ -n "$body_relocs" ]] || body_relocs=none
}

inspect_object() {
    local object="$1" kind="$2" mode="$3" out_dir="$4"
    mkdir -p "$out_dir/bodies"
    "$nm" -S --defined-only "$object" > "$out_dir/$kind.nm"
    "$objdump" -dr "$object" > "$out_dir/$kind.objdump"
    "$readelf" -SW "$object" > "$out_dir/$kind.sections"
    "$readelf" -Ws "$object" > "$out_dir/$kind.symbols"
    "$readelf" -r "$object" > "$out_dir/$kind.relocations"
    rg -q '^ *\[ *[0-9]+\] \.text +PROGBITS .* AX ' "$out_dir/$kind.sections" ||
        fail "$mode $kind object lacks executable allocatable .text"
    for index in "${!rows[@]}"; do
        local row="${rows[$index]}" alias="${aliases[$index]}" row_line alias_line body_sha body_relocs
        row_line="$(symbol_line "$object" "$row")" || fail "$mode $kind object does not define exactly one $row"
        alias_line="$(symbol_line "$object" "$alias")" || fail "$mode $kind object does not define exactly one $alias"
        [[ "$(awk '{print $4}' <<< "$row_line")" == FUNC ]] || fail "$mode $row is not an ELF function"
        [[ "$(awk '{print $4}' <<< "$alias_line")" == FUNC ]] || fail "$mode $alias is not an ELF function"
        [[ "$(awk '{print $7}' <<< "$row_line")" == "$(awk '{print $7}' <<< "$alias_line")" ]] || fail "$mode alias section mismatch: $alias"
        [[ "$(awk '{print $2":"$3}' <<< "$row_line")" == "$(awk '{print $2":"$3}' <<< "$alias_line")" ]] || fail "$mode alias body mismatch: $alias"
        body_sha="$(symbol_body_digest "$object" "$row" "$out_dir/bodies/$kind.$index.bytes")" || fail "$mode missing body bytes: $row"
        if "$objdump" -d --disassemble-symbols="$row" "$object" | rg -q '[[:space:]]callq?[[:space:]]'; then
            fail "$mode $kind row is not call-free: $row"
        fi
        body_relocations "$object" "$(awk '{print $2}' <<< "$row_line")" "$(awk '{print $3}' <<< "$row_line")" ||
            fail "$mode $kind row has a non-local relocation and is not a proven leaf: $row"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$mode" "$kind" "$row" "$alias" "$(awk '{print $4":"$5":"$6}' <<< "$alias_line")" \
            "$(awk '{print $7":"$2":"$3}' <<< "$row_line")" '.text:SHF_ALLOC|SHF_EXECINSTR' "$body_sha" "$body_relocs" >> "$scratch/provenance.tsv"
    done
}

map_provenance_ok() {
    local expected_object="$1" supplied_object="$2" map="$3"
    [[ "$(realpath "$supplied_object")" == "$(realpath "$expected_object")" ]] || return 1
    rg -Fq "LOAD $supplied_object" "$map" || return 1
    local section_line start size end address alias
    section_line="$(awk -v object="$supplied_object" '$1 == ".text" && $NF == object { print; count++ } END { if (count != 1) exit 1 }' "$map")" || return 1
    start=$(( $(awk '{print $2}' <<< "$section_line") ))
    size=$(( $(awk '{print $3}' <<< "$section_line") ))
    end=$(( start + size ))
    (( size > 0 )) || return 1
    for alias in "${aliases[@]}"; do
        address="$(awk -v symbol="$alias" '$NF == symbol { print $1; count++ } END { if (count != 1) exit 1 }' "$map")" || return 1
        address=$(( address ))
        (( address >= start && address < end )) || return 1
    done
}

run_pair_case() {
    local mode="$1" index="$2" reference_exe="$3" candidate_exe="$4"
    local pair_dir="$scratch/$mode/cases/$index" ref_status cand_status
    mkdir -p "$pair_dir"
    abi_diff_cases_attempted=$((abi_diff_cases_attempted + 1))
    set +e
    "$timeout_bin" --signal=TERM --kill-after=1 5 "$reference_exe" --case "$index" > "$pair_dir/reference.stdout" 2> "$pair_dir/reference.stderr"
    ref_status=$?
    "$timeout_bin" --signal=TERM --kill-after=1 5 "$candidate_exe" --case "$index" > "$pair_dir/candidate.stdout" 2> "$pair_dir/candidate.stderr"
    cand_status=$?
    set -e
    [[ $ref_status == 0 && $cand_status == 0 ]] || fail "$mode case $index did not terminate normally (reference=$ref_status candidate=$cand_status)"
    [[ ! -s "$pair_dir/reference.stderr" && ! -s "$pair_dir/candidate.stderr" ]] || fail "$mode case $index emitted unexpected diagnostics"
    cmp -s "$pair_dir/reference.stdout" "$pair_dir/candidate.stdout" || fail "$mode case $index return/memory/ABI/termination mismatch"
    [[ "$(rg -c '^case=.* abi=0000000000000000 term=normal$' "$pair_dir/reference.stdout")" == 1 ]] || fail "$mode case $index lacks exact ABI result"
    abi_diff_cases_matched=$((abi_diff_cases_matched + 1))
}

termination_status() {
    local exe="$1" option="$2" out="$3" err="$4" seconds="$5"
    local status
    set +e
    "$timeout_bin" --signal=TERM --kill-after=1 "$seconds" "$exe" "$option" > "$out" 2> "$err"
    status=$?
    set -e
    printf '%s' "$status"
}

classify_panic() {
    local status="$1" panic_object="$2" executable="$3" map="$4"
    [[ "$status" == 132 ]] || return 1
    symbol_line "$panic_object" abi_diff_controlled_panic >/dev/null || return 1
    rg -Fq "LOAD $panic_object" "$map" || return 1
    "$nm" --defined-only "$executable" | awk '$3 == "abi_diff_controlled_panic" { count++ } END { exit count == 1 ? 0 : 1 }'
}

require_identity

# Keep all C-compiler manifests and outputs in the same owned generation as the
# other reference artifacts, so unrelated project-cache cleanup cannot split them.
export ZIG_LOCAL_CACHE_DIR="$scratch/common/cc-cache"
export ZIG_GLOBAL_CACHE_DIR="$scratch/global-cache"
"$zig" cc -c "$shim" -target "$target" -o "$scratch/common/abi_shim.o"

printf 'mode\tkind\trow_identity\texport_symbol\ttype_binding_visibility\tsection_offset_size\tsection_flags\tbody_sha256\trelocations\n' > "$scratch/provenance.tsv"
{
    printf 'directive=INBOX-66 status=mandatory-tier2 counter_schema=%s\n' "$counter_schema"
    printf 'population=compiler-rt-accepted-285 cohort_functions=10 compiler_core_distribution_rows=separate-not-executed-here\n'
    printf 'zig_source_commit=%s zig_version=%s target=%s cpu=%s features=baseline\n' "$zig_pin" "$zig_version" "$target" "$cpu"
    printf 'zllvm_commit=%s zllvm_sha256=%s historical_accepted_air_sha256=%s\n' "$(git rev-parse HEAD)" "$(digest "$zllvm")" "$historical_accepted_air_sha256"
    printf 'cohort_source_sha256=%s cohort_manifest_sha256=%s harness_sha256=%s shim_sha256=%s panic_source_sha256=%s\n' \
        "$(digest "$cohort")" "$(digest "$cohort_manifest")" "$(digest "$harness")" "$(digest "$shim")" "$(digest "$panic_source")"
    printf 'compiler_rt_body_optimization=ReleaseFast reason=canonical-accepted-cohort harness_modes=ReleaseFast,ReleaseSafe,ReleaseSmall\n'
    printf 'abi_shim_object_sha256=%s linker=%s\n' \
        "$(digest "$scratch/common/abi_shim.o")" "$($linker --version | head -n 1)"
} > "$scratch/report.txt"

abi_diff_cases_attempted=0
abi_diff_cases_matched=0
abi_diff_real_functions_matched=0

for mode in ReleaseFast ReleaseSafe ReleaseSmall; do
    mode_dir="$scratch/$mode"
    mkdir -p "$mode_dir/reference-cache" "$mode_dir/candidate-cache" "$mode_dir/panic-reference-cache" "$mode_dir/panic-candidate-cache"
    reference="$mode_dir/reference.o"
    candidate="$mode_dir/candidate.o"
    marker="$mode_dir/candidate.marker"
    case "$mode" in
        ReleaseFast) harness_opt=-O3 ;;
        ReleaseSafe) harness_opt=-O2 ;;
        ReleaseSmall) harness_opt=-Oz ;;
    esac
    "$zig" cc -c "$harness" "$harness_opt" -fno-lto -fno-stack-protector -fno-builtin -target "$target" -o "$mode_dir/harness.o"

    # Compiler-rt itself is bound to the canonical accepted ReleaseFast body
    # population. The surrounding harness mode and z_llvm accepted pipeline vary.
    "$zig" build-obj "$cohort" -OReleaseFast -target "$target" -mcpu="$cpu" \
        -fllvm -flibllvm -fno-lto -fno-stack-protector -fno-unwind-tables \
        --cache-dir "$mode_dir/reference-cache" --global-cache-dir "$scratch/global-cache" \
        -femit-llvm-ir="$mode_dir/reference.ll" -femit-bin="$reference"

    env ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE="$(realpath "$zllvm")" \
        ZLLVM_MARKER_PATH="$(realpath -m "$marker")" ZLLVM_ZIG_MODE="$mode" ZLLVM_GENERIC_CFG_SELECTOR=1 \
        "$zig" build-obj "$cohort" -OReleaseFast -target "$target" -mcpu="$cpu" \
        -fllvm -flibllvm -fno-lto -fno-stack-protector -fno-unwind-tables \
        --cache-dir "$mode_dir/candidate-cache" --global-cache-dir "$scratch/global-cache" \
        -femit-llvm-ir="$mode_dir/candidate.ll" -femit-bin="$candidate"

    rg -q '^pipeline=postopt ' "$marker" || fail "$mode hook marker lacks postopt identity"
    rg -q " mode=$mode$" "$marker" || fail "$mode hook marker mode mismatch"
    hook_ir="$(awk '{for (i=1;i<=NF;i++) if ($i ~ /^ir=/) {sub(/^ir=/,"",$i); print $i}}' "$marker")"
    hook_object="$(awk '{for (i=1;i<=NF;i++) if ($i ~ /^object=/) {sub(/^object=/,"",$i); print $i}}' "$marker")"
    [[ -n "$hook_ir" && -n "$hook_object" ]] || fail "$mode hook marker lacks artifact identities"
    "$zllvm" --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 "$mode_dir/candidate.ll" > "$mode_dir/replayed-candidate.o"
    "$objdump" -dr "$candidate" | tail -n +3 > "$mode_dir/candidate.normalized-objdump"
    "$objdump" -dr "$mode_dir/replayed-candidate.o" | tail -n +3 > "$mode_dir/replayed.normalized-objdump"
    cmp -s "$mode_dir/candidate.normalized-objdump" "$mode_dir/replayed.normalized-objdump" ||
        fail "$mode hook object bodies are not a deterministic replay of captured IR"
    "$zllvm" --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 "$mode_dir/candidate.ll" > "$mode_dir/owners.tsv"
    validate_owner_manifest "$mode_dir/owners.tsv" "$mode"
    inspect_object "$reference" reference "$mode" "$mode_dir"
    inspect_object "$candidate" candidate "$mode" "$mode_dir"

    reference_exe="$mode_dir/reference.exe"
    candidate_exe="$mode_dir/candidate.exe"
    "$linker" -no-pie -Wl,-Map="$mode_dir/reference.map" -o "$reference_exe" "$mode_dir/harness.o" "$scratch/common/abi_shim.o" "$reference"
    "$linker" -no-pie -Wl,-Map="$mode_dir/candidate.map" -o "$candidate_exe" "$mode_dir/harness.o" "$scratch/common/abi_shim.o" "$candidate"
    map_provenance_ok "$candidate" "$candidate" "$mode_dir/candidate.map" || fail "$mode linker-map candidate provenance failed"
    map_provenance_ok "$reference" "$reference" "$mode_dir/reference.map" || fail "$mode linker-map reference provenance failed"

    mode_start_attempted=$abi_diff_cases_attempted
    mode_start_matched=$abi_diff_cases_matched
    mode_start_functions=$abi_diff_real_functions_matched
    for function_index in "${!rows[@]}"; do
        run_pair_case "$mode" "$((function_index * 2))" "$reference_exe" "$candidate_exe"
        run_pair_case "$mode" "$((function_index * 2 + 1))" "$reference_exe" "$candidate_exe"
        abi_diff_real_functions_matched=$((abi_diff_real_functions_matched + 1))
    done
    printf 'summary abi-differential counter_schema=%s population=compiler-rt-accepted-285 mode=%s abi_diff_cases_attempted=%u abi_diff_cases_matched=%u abi_diff_real_functions_matched=%u harness_object_sha256=%s reference_object_sha256=%s candidate_object_sha256=%s hook_ir_sha256=%s owner_manifest_sha256=%s result=match\n' \
        "$counter_schema" "$mode" "$((abi_diff_cases_attempted - mode_start_attempted))" "$((abi_diff_cases_matched - mode_start_matched))" \
        "$((abi_diff_real_functions_matched - mode_start_functions))" "$(digest "$mode_dir/harness.o")" "$(digest "$reference")" "$(digest "$candidate")" "$(digest "$mode_dir/candidate.ll")" "$(digest "$mode_dir/owners.tsv")" >> "$scratch/report.txt"
    printf 'hook_provenance mode=%s marker_ir=%s marker_object=%s captured_ir=%s replay_object_sha256=%s\n' \
        "$mode" "$hook_ir" "$hook_object" "$mode_dir/candidate.ll" "$(digest "$mode_dir/replayed-candidate.o")" >> "$scratch/report.txt"

    if [[ "$mode" == ReleaseSafe ]]; then
        panic_reference="$mode_dir/panic-reference.o"
        panic_candidate="$mode_dir/panic-candidate.o"
        panic_marker="$mode_dir/panic-candidate.marker"
        "$zig" build-obj "$panic_source" -OReleaseSafe -target "$target" -mcpu="$cpu" -fno-lto -fno-stack-protector -fno-unwind-tables \
            --cache-dir "$mode_dir/panic-reference-cache" --global-cache-dir "$scratch/global-cache" -femit-bin="$panic_reference"
        env ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE="$(realpath "$zllvm")" \
            ZLLVM_MARKER_PATH="$(realpath -m "$panic_marker")" ZLLVM_ZIG_MODE=ReleaseSafe ZLLVM_GENERIC_CFG_SELECTOR=1 \
            "$zig" build-obj "$panic_source" -OReleaseSafe -target "$target" -mcpu="$cpu" -fno-lto -fno-stack-protector -fno-unwind-tables \
            --cache-dir "$mode_dir/panic-candidate-cache" --global-cache-dir "$scratch/global-cache" -femit-bin="$panic_candidate"
        panic_reference_exe="$mode_dir/panic-reference.exe"
        panic_candidate_exe="$mode_dir/panic-candidate.exe"
        "$linker" -no-pie -Wl,-Map="$mode_dir/panic-reference.map" -o "$panic_reference_exe" "$mode_dir/harness.o" "$scratch/common/abi_shim.o" "$reference" "$panic_reference"
        "$linker" -no-pie -Wl,-Map="$mode_dir/panic-candidate.map" -o "$panic_candidate_exe" "$mode_dir/harness.o" "$scratch/common/abi_shim.o" "$candidate" "$panic_candidate"
        ref_panic_status="$(termination_status "$panic_reference_exe" --controlled-panic "$mode_dir/panic-reference.stdout" "$mode_dir/panic-reference.stderr" 5)"
        cand_panic_status="$(termination_status "$panic_candidate_exe" --controlled-panic "$mode_dir/panic-candidate.stdout" "$mode_dir/panic-candidate.stderr" 5)"
        [[ "$ref_panic_status" != 124 && "$cand_panic_status" != 124 ]] || fail "controlled panic timed out"
        classify_panic "$ref_panic_status" "$panic_reference" "$panic_reference_exe" "$mode_dir/panic-reference.map" || fail "reference controlled panic did not classify as panic"
        classify_panic "$cand_panic_status" "$panic_candidate" "$panic_candidate_exe" "$mode_dir/panic-candidate.map" || fail "candidate controlled panic did not classify as panic"
        printf 'termination_case=controlled-panic mode=ReleaseSafe reference=panic candidate=panic canonical_signal=4 result=match\n' >> "$scratch/report.txt"
    fi
    check_budget
done

# Negative controls. Passing means every deliberately invalid comparison failed closed.
cp "$scratch/ReleaseFast/cases/0/candidate.stdout" "$scratch/negative-value.stdout"
sed -i 's/lo=[0-9a-f]*/lo=ffffffffffffffff/' "$scratch/negative-value.stdout"
cmp -s "$scratch/ReleaseFast/cases/0/reference.stdout" "$scratch/negative-value.stdout" && fail "value mismatch negative was accepted"

if map_provenance_ok "$scratch/ReleaseFast/candidate.o" "$scratch/ReleaseFast/reference.o" "$scratch/ReleaseFast/reference.map"; then
    fail "reference substitution negative was accepted"
fi

"$scratch/ReleaseFast/reference.exe" --negative-clobber || fail "callee-saved register clobber was not detected"
"$scratch/ReleaseFast/reference.exe" --negative-write || fail "out-of-bounds write was not detected"
timeout_status="$(termination_status "$scratch/ReleaseFast/reference.exe" --negative-timeout "$scratch/negative-timeout.stdout" "$scratch/negative-timeout.stderr" 1)"
[[ "$timeout_status" == 124 ]] || fail "timeout negative did not classify as timeout (status=$timeout_status)"

# The already proven case-0 status is canonical normal and must not equal panic.
[[ 0 != "$ref_panic_status" ]] || fail "normal-versus-panic negative was accepted"
signal_status="$(termination_status "$scratch/ReleaseFast/reference.exe" --negative-signal "$scratch/negative-signal.stdout" "$scratch/negative-signal.stderr" 5)"
[[ "$signal_status" == 139 ]] || fail "signal negative did not retain SIGSEGV number (status=$signal_status)"
[[ "$signal_status" != "$ref_panic_status" ]] || fail "panic-versus-signal negative was accepted"

{
    printf 'negative=value-mismatch result=rejected\n'
    printf 'negative=reference-substitution result=rejected authority=object-path-and-linker-map\n'
    printf 'negative=callee-saved-clobber result=rejected abi_bit=RBX\n'
    printf 'negative=timeout result=rejected termination=timeout\n'
    printf 'negative=out-of-bounds-write result=rejected\n'
    printf 'negative=normal-versus-panic result=rejected normal=normal panic=panic\n'
    printf 'negative=panic-versus-signal result=rejected panic=panic signal=11\n'
    printf 'summary abi-differential counter_schema=%s population=compiler-rt-accepted-285 abi_diff_cases_attempted=%u abi_diff_cases_matched=%u abi_diff_real_functions_matched=%u compiler_core_rows_executed=not-applicable real_programs_ok=reserved-zero result=pass\n' \
        "$counter_schema" "$abi_diff_cases_attempted" "$abi_diff_cases_matched" "$abi_diff_real_functions_matched"
    printf 'scratch_bytes=%s scratch_limit_bytes=%s status=pass\n' "$(du -sb "$scratch" | awk '{print $1}')" "$scratch_limit"
} >> "$scratch/report.txt"

[[ "$abi_diff_cases_attempted" == 60 && "$abi_diff_cases_matched" == 60 && "$abi_diff_real_functions_matched" == 30 ]] ||
    fail "ABI counter ratchet mismatch"
check_budget
cat "$scratch/report.txt"
