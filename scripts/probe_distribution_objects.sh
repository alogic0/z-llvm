#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: bash scripts/probe_distribution_objects.sh --input-dir=DIR [options]

Options:
  --target=TRIPLE          Object target [x86_64-unknown-linux-gnu]
  --input-limit=N         z_llvm input limit [67108864]
  --exclude=FILE:REASON   Skip one optimized IR filename with a boundary reason
  --summary=PATH          Also write the stable probe summary to PATH
  --keep-objects=DIR      Keep emitted objects and error logs under DIR
USAGE
}

input_dir=""
target="${TARGET:-x86_64-unknown-linux-gnu}"
input_limit="${INPUT_LIMIT:-67108864}"
summary_path=""
keep_objects=""
declare -a exclude_specs=()

for arg in "$@"; do
    case "$arg" in
        --input-dir=*) input_dir="${arg#*=}" ;;
        --target=*) target="${arg#*=}" ;;
        --input-limit=*) input_limit="${arg#*=}" ;;
        --exclude=*) exclude_specs+=("${arg#*=}") ;;
        --summary=*) summary_path="${arg#*=}" ;;
        --keep-objects=*) keep_objects="${arg#*=}" ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'unknown argument: %s\n' "$arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "$input_dir" ]; then
    printf 'missing required --input-dir\n' >&2
    usage >&2
    exit 2
fi

if [ ! -d "$input_dir" ]; then
    printf 'input directory not found: %s\n' "$input_dir" >&2
    exit 2
fi

if [ -n "$summary_path" ]; then
    mkdir -p "$(dirname "$summary_path")"
    exec > >(tee "$summary_path")
fi

tmp_dir="$(mktemp -d)"
if [ -n "$keep_objects" ]; then
    mkdir -p "$keep_objects"
    work_dir="$keep_objects"
    trap 'rm -rf "$tmp_dir"' EXIT
else
    work_dir="$tmp_dir"
    trap 'rm -rf "$tmp_dir"' EXIT
fi

zig build >/dev/null

exclude_reason() {
    local file="$1"
    local spec name reason
    for spec in "${exclude_specs[@]}"; do
        name="${spec%%:*}"
        if [ "$name" = "$spec" ]; then
            reason="boundary-exclusion"
        else
            reason="${spec#*:}"
        fi
        if [ "$file" = "$name" ]; then
            printf '%s\n' "$reason"
            return 0
        fi
    done
    return 1
}

category_for_error() {
    local log="$1"
    local line
    line="$(sed -n '1p' "$log")"
    case "$line" in
        *UnsupportedCodegenControlFlow*) printf 'unsupported-control-flow\n' ;;
        *UnsupportedCodegenInstruction*) printf 'unsupported-instruction\n' ;;
        *UnsupportedCodegenValue*) printf 'unsupported-value\n' ;;
        *UnsupportedCodegenType*) printf 'unsupported-type\n' ;;
        *UnsupportedCodegenAbi*) printf 'unsupported-abi\n' ;;
        *UnsupportedCodegenTarget*) printf 'unsupported-target\n' ;;
        *InputTooLarge*) printf 'input-too-large\n' ;;
        error:*) printf 'other-error\n' ;;
        *) printf 'unknown-error\n' ;;
    esac
}

safe_stem() {
    printf '%s\n' "$1" | tr -c 'A-Za-z0-9_.-' '_'
}

total=0
ok=0
fail=0
excluded=0
first_failure="-"
first_failure_category="-"
declare -A fail_categories=()
declare -A excluded_categories=()

printf 'object-probe target=%s input_dir=%s input_limit=%s\n' "$target" "$input_dir" "$input_limit"

while IFS= read -r input; do
    file="$(basename "$input")"
    total=$((total + 1))

    if reason="$(exclude_reason "$file")"; then
        excluded=$((excluded + 1))
        excluded_categories["$reason"]=$(( ${excluded_categories["$reason"]:-0} + 1 ))
        printf 'excluded %s reason=%s\n' "$file" "$reason"
        continue
    fi

    stem="$(safe_stem "$file")"
    object="$work_dir/$stem.o"
    log="$work_dir/$stem.err"
    if zig-out/bin/z_llvm --emit=obj --target="$target" --input-limit="$input_limit" "$input" > "$object" 2> "$log"; then
        ok=$((ok + 1))
        printf 'ok %s\n' "$file"
    else
        fail=$((fail + 1))
        category="$(category_for_error "$log")"
        fail_categories["$category"]=$(( ${fail_categories["$category"]:-0} + 1 ))
        if [ "$first_failure" = "-" ]; then
            first_failure="$file"
            first_failure_category="$category"
        fi
        printf 'fail %s category=%s ' "$file" "$category"
        sed -n '1p' "$log"
    fi
done < <(find "$input_dir" -maxdepth 1 -type f -name '*.ll' | sort)

printf 'summary total=%s ok=%s fail=%s excluded=%s first_failure=%s first_failure_category=%s\n' \
    "$total" "$ok" "$fail" "$excluded" "$first_failure" "$first_failure_category"

for category in "${!fail_categories[@]}"; do
    printf 'fail_category %s=%s\n' "$category" "${fail_categories["$category"]}"
done | sort

for category in "${!excluded_categories[@]}"; do
    printf 'excluded_category %s=%s\n' "$category" "${excluded_categories["$category"]}"
done | sort
