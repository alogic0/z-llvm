#!/usr/bin/env bash
set -euo pipefail
review_binary=$(realpath -e -- "${1:?pass compiled collector}")
review_fixture=$(mktemp -d /tmp/zllvm-reviewed-products-XXXXXXXX)
trap 'rm -r -- "$review_fixture"' EXIT
review_run=local-state/validations/reviewed/batch/run
mkdir -p "$review_fixture/$review_run" "$review_fixture/src"
printf '0.17.0\n' > "$review_fixture/.zigversion"
printf 'pub fn main() void {}\n' > "$review_fixture/src/main.zig"
printf '{"schema":1,"current_manifests":[]}\n' > "$review_fixture/policy.json"
printf '\177ELFtemporary reviewed binary\n' > "$review_fixture/$review_run/helper"
printf 'unique input remains\n' > "$review_fixture/$review_run/input.ll"
printf 'Closed generated helper; no continuing consumer identified.\n' > "$review_fixture/review.md"
review_hash=$(sha256sum "$review_fixture/$review_run/helper")
review_hash=${review_hash%% *}
review_notes_hash=$(sha256sum "$review_fixture/review.md")
review_notes_hash=${review_notes_hash%% *}
cat > "$review_fixture/plan.json" <<EOF
{"schema":"zllvm-reviewed-products-v1","reason":"Explicit disposal review","review":{"path":"review.md","sha256":"$review_notes_hash"},"products":[{"path":"$review_run/helper","sha256":"$review_hash","run_root":"$review_run","reason":"Closed generated helper","consumers_closed":true}]}
EOF
export ZLLVM_PROJECT_ROOT=$review_fixture
if "$review_binary" retire-reviewed-products --policy policy.json > "$review_fixture/invalid.log" 2>&1; then
    printf 'Missing review was accepted\n' >&2; exit 1
fi
"${ZIGREP:-zigrep}" --no-config -q -F InvalidReviewedProducts "$review_fixture/invalid.log"
"$review_binary" retire-reviewed-products --minimal --complete-artifact-aliases --policy policy.json --review plan.json > "$review_fixture/review.log"
test -f "$review_fixture/$review_run/helper"
"$review_binary" retire-reviewed-products --minimal --complete-artifact-aliases --apply --policy policy.json --review plan.json > "$review_fixture/apply.log"
test ! -e "$review_fixture/$review_run/helper"
test -f "$review_fixture/$review_run/input.ll"
test -f "$review_fixture/review.md"
test -f "$review_fixture/plan.json"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 1;' "$review_fixture/apply.log"
"$review_binary" retire-reviewed-products --minimal --complete-artifact-aliases --apply --policy policy.json --review plan.json > "$review_fixture/repeat.log"
"${ZIGREP:-zigrep}" --no-config -q -F 'removed: 0;' "$review_fixture/repeat.log"
printf 'Reviewed-product arguments, dry run, guarded removal and repeat passed\n'
