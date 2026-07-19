# INBOX-187 — compiler-rt v1 baseline-validation execution contract

Status: **contract and patch freeze complete; execution not performed**.

This document closes the future ratchet-131 baseline-validation procedure.
It deliberately separates canonical identity creation from temporary call
coverage. No command in the future procedure was executed in INBOX-187.
Production remains dormant and the bypass ratchet remains **131**.

## 1. Accepted basis and current preflight

The tracked authorization and source basis are:

```text
operating_head=d7b11c97f43ccb5566f56a396501169f1334a15d
operating_tree=b065779d17e5726dd81bc6b3c19bedf61a74b942
exact_dormant_ratchet_131_source_commit=43de59b0
INBOX_184_contract_commit=1c343ec8
INBOX_185_reproduction_commit=b1567ace
INBOX_186_adoption_commit=43de59b0
ratchet=131
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
```

`git diff 43de59b0 d7b11c97 -- src build.zig build.zig.zon tools scripts
docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
docs/evidence/inbox128_o2_r1_facade_manifest.tsv` is empty. Thus
`43de59b0` is the exact code/build/tool baseline and the later commits are
operating documentation only.

The accepted immutable inputs and infrastructure were rechecked before the
bundle root was created:

| Surface | Required and observed identity |
|---|---|
| adopted input | `tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll`, regular `0444`, 1,897,410 bytes, SHA-256 `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |
| adoption manifest | `tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv`, regular `0444`, 4,394 bytes, SHA-256 `500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf` |
| generation outputs | all three are 1,897,410 bytes, SHA-256 `9b8d6993...`, and raw-`cmp` equal to the adopted input |
| reproduction manifest | `tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/retained-files-final.tsv`, SHA-256 `885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e` |
| retention pins | `docs/evidence/tmp_retention_pins.tsv`, SHA-256 `1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3` |
| retention policy | `docs/retention_headroom_policy.md`, SHA-256 `a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd` |
| cleanup source | `tools/clean_tmp.zig`, SHA-256 `8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e` |
| watcher | HEAD/index/worktree Git blob `b64131cf60dd0ef638e815cd33db9ae8595a72cf` |
| pinned Zig source | commit `bdee02bc0c7f227c0f11bc9a449df673fe803540`, tree `aa032b2b82a48a4684657f909e6e270a6c925e33` |
| facade | 126 names plus header, manifest SHA-256 `2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26` |
| facade source | SHA-256 `4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a` |
| bypass TSV | SHA-256 `2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11`; direct occurrence recount `131` |
| initial available bytes | `97,833,832,448` |

The new bundle root was absent before creation. The future validation
preflight requires at least 17,179,869,184 available bytes. Any mismatch in
this section is a stop; no repair, replacement, cleanup, pin edit, or
alternate input is permitted.

## 2. Non-negotiable phase separation

There are two separate artifacts and two separate evidentiary purposes.

### 2.1 Canonical identity artifact

The canonical artifact is built exactly once from clean detached commit
`43de59b0`, with no aggregate consumer patch, observer patch, guard patch, or
other temporary source. Exactly three non-timing repetitions from that one
immutable artifact define all `o2_calls_crt_v1_r131_*` identities.

Only these three repetitions may define the canonical identities. Historical
`49a19f04...`, `061a64e4...`, and `5d91960e...` are reference-only even if a
new byte hash happens to equal one of them.

### 2.2 Coverage-only artifact

The coverage artifact is built separately from `43de59b0` plus the frozen
aggregate-consumer/observer/guard bundle in section 3. It exists only to prove
dynamic execution of:

```text
ordinary GPR/pointer DirectCallAction
zig.target.intByteSize IntByteSizeCallAction
```

It cannot define a canonical identity, cannot be a performance artifact, and
cannot claim production wiring or ratchet credit. Its observation-disabled
and observation-enabled semantic outputs must both equal the canonical
identities byte for byte.

No result from one phase may fill a missing result in the other.

## 3. Frozen read-only patch bundle

The bundle root is:

```text
tmp/o2_calls_perf/compiler_rt_v1/inbox187_baseline_validation_contract_bundle
```

The component application order is exact:

| Order | Role | File | SHA-256 | Bytes | Applies to |
|---:|---|---|---|---:|---|
| 1 | aggregate consumer | `patches/01-aggregate-consumer.patch` | `8b5750fa6aa0f8811da3585614fd3386739d11d8f65896fa6eaf6a8a89b47a66` | 8,681 | clean `43de59b0` |
| 2 | fixed observer | `patches/02-fixed-observer.patch` | `db05812e28dee0ed3f30f56df82e5fde8f531b1dd2ae8bf0ca66521ae78e6a67` | 14,274 | result of order 1 |
| 3 | exact aggregate guard | `patches/03-exact-combined-guard.patch` | `9263f132b7bc30d6c17c26c58f61c8cfe9874ee0abdc453d730951130f089e3e` | 21,068 | result of order 2 |

The independently applicable combined patch is:

```text
patches/aggregate-consumer-observer-guard.patch
sha256=7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
bytes=41140
apply_base=clean 43de59b0
```

Accepted INBOX-181 provenance remains:

```text
aggregate_patch_sha256=b00536c214fcd2ba2c3e6dceabcce5851124d706c890f63edb843e67f298676c
guard_patch_sha256=9263f132b7bc30d6c17c26c58f61c8cfe9874ee0abdc453d730951130f089e3e
```

The bundle manifest identities are:

```text
manifests/patch-manifest.tsv
  sha256=7717db66248bdb3268c186efaa22660a3d0e2d06f1086719d0224be156f46723
manifests/future-tool-identities.sha256
  sha256=05ea0083c843923adad63e3d8f897bb83405c915552f393fac4483096809f670
manifests/payload-final-modes.tsv
  sha256=0ece5ced2c472a2c25c9ca0660ae61c8312a463ad59346e739dd8f0ad596e7c7
manifests/bundle-files.sha256
  sha256=0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
```

All bundle files finish mode `0444`; the bundle directories finish mode
`0555`. The existing top-level `tmp/o2_calls_perf` pin protects the bundle;
no pin or retention-policy edit is made.

### 3.1 Apply and restoration proof completed in this slice

Both allowed application forms were checked without executing project code:

```text
sequential:
  git apply --check 01 = 0
  git apply 01
  git apply --check 02 = 0
  git apply 02
  git apply --check 03 = 0
  git apply 03
  sequential source manifest == bundled source manifest

combined:
  git apply --check combined = 0
  git apply combined
  combined source manifest == bundled source manifest

restoration:
  tracked files restored with scoped git checkout
  new observer source removed
  baseline source manifest == restored source manifest
  index clean
  worktree clean
```

The exact records are retained in `manifests/preflight-and-apply-proof.txt`,
`baseline-source.sha256`, `bundled-source.sha256`,
`sequential-apply-source.sha256`, `combined-apply-source.sha256`, and
`restored-source.sha256`.

### 3.2 Observer contract

The observer is private and fixed:

- one fixed global struct; no allocator, slice ownership, callback, vtable,
  dynamic collection, or selector-state access;
- only the two closed families are representable by its `Family` enum;
- counters are `u64` scalars plus fixed six-position arrays;
- the output file is created with `exclusive=true`;
- the only enabling input is the private
  `ZLLVM_CALL_COVERAGE_PATH` validation channel;
- no output goes to semantic stdout or stderr;
- no classifier, request, action, staging, instruction, diagnostic,
  ownership, or fallback decision reads a counter or the channel;
- the observer adds no public facade symbol, action tag, request form,
  destination, planning edge, or production authority.

For each family it records:

```text
transactions
requests_registered
actions_attached
arguments_staged
materializations_completed
actions_completed
commits
requests_registered[position 0..5]
arguments_staged[position 0..5]
```

It also records `unexpected_family_events` and
`argument_index_overflow_events`. Both must be zero.

The accepted aggregate guard remains exact and fail-closed. It requires both
complete consumer lifecycles, permits only the reviewed
`lowerIntByteSizeCall/emitValueIntoScratch` 1-to-0 temporary transition, and
rejects partial activation, legacy coexistence, cross-family markers,
unrelated inventory movement, and use outside the approved functions.

## 4. Frozen future root, tools, and environment

Future execution may use only:

```text
REPO=/home/oleg/prog/z_llvm
INPUT=$REPO/tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
BUNDLE=$REPO/tmp/o2_calls_perf/compiler_rt_v1/inbox187_baseline_validation_contract_bundle
ROOT=$REPO/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1
SOURCE_COMMIT=43de59b0
TARGET=x86_64-linux
INPUT_LIMIT=67108864
```

`$ROOT` must be absent. The exact adopted input and all section-1 surfaces
must pass again before `$ROOT` is created. The future tool hashes must equal
`$BUNDLE/manifests/future-tool-identities.sha256`; in particular:

```text
/home/oleg/bin/zig
  2317bbb91798556d9d0f38aabdac23db83f0979b25f767259ae474546724087c
/usr/bin/git
  2a8c18fbf43da9f692d75474c72bea9dfd796c260b0f3dfe456376abc3bbd668
/usr/lib/llvm-22/bin/llvm-extract
  fcb8715a8e3a5b3581d7112357df5ea250eb011e4aec79401f6780ae71e0652c
/usr/bin/objcopy
  9276e918e3c26d3aa7ef9dd2232cd8ac692f03d3c1f270bfa5144a2b5492b713
/usr/bin/objdump
  325c4205a4c658a9d1e1ebc469ae55975a2b897a3d3c1e79d9b158612d37f745
/usr/bin/readelf
  64c58e15274bbbb5153f31078e455e9e77ee5f51489e709bba5bb788ce9df2b0
/usr/bin/dd
  dd07a1b0f236f221f71fac70103765286d1ccf29b747cbb24345d0c57a0311b6
/bin/bash
  bc5945feb8bd26203ebfafea5ce1878bb2e32cb8fb50ab7ae395cfb1e1aaaef1
```

Every build and `z_llvm` invocation uses `env -i` with exactly:

```text
HOME=<phase-specific empty home>
TMPDIR=<phase-specific empty tmp>
PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin
LC_ALL=C
LANG=C
TZ=UTC
SOURCE_DATE_EPOCH=0
```

No inherited environment variable is allowed. Build commands additionally
use explicit, initially empty local/global cache directories. A command,
environment, tool, or output path not named here is prohibited.

## 5. Canonical artifact build

After all preflights, create the root once and execute exactly:

```bash
/usr/bin/mkdir -p \
  "$ROOT/canonical/build/home" \
  "$ROOT/canonical/build/tmp" \
  "$ROOT/canonical/build/cache/local" \
  "$ROOT/canonical/build/cache/global" \
  "$ROOT/canonical/build/prefix" \
  "$ROOT/canonical/artifact"

/usr/bin/git -C "$REPO" worktree add --detach "$ROOT/canonical/source" \
  43de59b0

(
  cd "$ROOT/canonical/source"
  /usr/bin/env -i \
    HOME="$ROOT/canonical/build/home" \
    TMPDIR="$ROOT/canonical/build/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /home/oleg/bin/zig build \
    --prefix "$ROOT/canonical/build/prefix" \
    --cache-dir "$ROOT/canonical/build/cache/local" \
    --global-cache-dir "$ROOT/canonical/build/cache/global" \
    --summary all \
    >"$ROOT/canonical/build/stdout.raw" \
    2>"$ROOT/canonical/build/stderr.raw"
)

/usr/bin/install -D -m 0555 \
  "$ROOT/canonical/build/prefix/bin/z_llvm" \
  "$ROOT/canonical/artifact/z_llvm"
```

The build runs exactly once. Its status must be zero. Record command bytes,
start/end UTC, stdout, stderr, status, byte counts, modes, SHA-256 values,
the detached HEAD/tree/status, and a sorted SHA-256 manifest of all tracked
production/build/tool files. Make every retained build log and manifest
`0444`. The artifact stays `0555`. Any dirty source, changed hash, existing
path, build failure, or post-mode movement stops without retry.

The canonical artifact is now immutable and is the only artifact used in
section 6.

## 6. Exactly three canonical non-timing repetitions

Create exactly:

```text
$ROOT/canonical/repetition-1
$ROOT/canonical/repetition-2
$ROOT/canonical/repetition-3
```

Each repetition receives independently empty `home` and `tmp` directories.
There is no warmup, timing, CPU pin, cache sharing, retry, or fourth
repetition.

### 6.1 Report and accepted-subset derivation

For each `N` in the fixed order `1 2 3`, define `REP` as the corresponding
directory and execute the same block:

```bash
/usr/bin/env -i \
  HOME="$REP/home" TMPDIR="$REP/tmp" \
  PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
  LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
  "$ROOT/canonical/artifact/z_llvm" \
  --emit=obj \
  --generic-cfg-selector \
  --report-all-codegen-failures \
  --target=x86_64-linux \
  --input-limit=67108864 \
  "$INPUT" \
  >"$REP/report.stdout.raw" \
  2>"$REP/report.stderr.raw"
```

Capture the status without transforming either channel. The required status
is exactly `1`, `report.stdout.raw` is exactly empty, and
`report.stderr.raw` contains exactly one final
`summary zllvm-codegen-report-all` row. The summary must report:

- `selected_functions > 0`;
- `emitted_functions > 0`;
- `failed_functions > 0`;
- `selected_functions = emitted_functions + failed_functions`;
- `local_fail=1`;
- a non-`-` first failure and diagnostic.

Extract the complete ordered failures with this exact command:

```bash
LC_ALL=C /usr/bin/awk \
  '$1 == "zllvm-codegen-failure" {
     if ($2 !~ /^function=/) exit 91;
     sub(/^function=/, "", $2);
     print $2
   }' \
  "$REP/report.stderr.raw" \
  >"$REP/failed-functions.in-report-order.txt"

LC_ALL=C /usr/bin/sort -u \
  "$REP/failed-functions.in-report-order.txt" \
  >"$REP/failed-functions.sorted.txt"
```

The ordered and unique counts must both equal `failed_functions`; duplicate,
empty, or non-`[A-Za-z0-9_.$]+` identities are a stop.

Create the candidate-specific accepted input only with:

```bash
extract_args=(--delete -S -o "$REP/accepted.ll")
while IFS= read -r function_name; do
  extract_args+=(--func "$function_name")
done <"$REP/failed-functions.sorted.txt"
extract_args+=("$INPUT")

/usr/bin/env -i \
  HOME="$REP/home" TMPDIR="$REP/tmp" \
  PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
  LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
  /usr/lib/llvm-22/bin/llvm-extract \
  "${extract_args[@]}" \
  >"$REP/extract.stdout.raw" \
  2>"$REP/extract.stderr.raw"
```

This command must return zero with empty stdout/stderr. `accepted.ll` is a
derived output, not a substitute input. It is retained and hashed in every
repetition.

### 6.2 Object and owner outputs

Run in this fixed order:

```bash
/usr/bin/env -i \
  HOME="$REP/home" TMPDIR="$REP/tmp" \
  PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
  LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
  "$ROOT/canonical/artifact/z_llvm" \
  --emit=obj \
  --generic-cfg-selector \
  --target=x86_64-linux \
  --input-limit=67108864 \
  "$REP/accepted.ll" \
  >"$REP/accepted.o" \
  2>"$REP/object.stderr.raw"

/usr/bin/env -i \
  HOME="$REP/home" TMPDIR="$REP/tmp" \
  PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
  LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
  "$ROOT/canonical/artifact/z_llvm" \
  --emit=selection-owner-manifest \
  --generic-cfg-selector \
  --target=x86_64-linux \
  --input-limit=67108864 \
  "$REP/accepted.ll" \
  >"$REP/owner.tsv" \
  2>"$REP/owner.stderr.raw"

(cd "$REP" && LC_ALL=C /usr/bin/objdump -d accepted.o \
  >accepted.objdump 2>objdump.stderr.raw)
```

All three statuses must be zero; both `z_llvm` stderr files and objdump
stderr must be empty. The owner header must be exactly
`row_identity<TAB>selection_owner`. Owner row count must equal
`emitted_functions`.

Create `owner-ledger.txt` with exactly:

```bash
LC_ALL=C /usr/bin/awk -F '\t' '
  NR == 1 {
    if ($1 != "row_identity" || $2 != "selection_owner") exit 92;
    next
  }
  { count[$2] += 1; total += 1 }
  END {
    printf("composed_block=%d\n", count["composed_block"]);
    printf("composed_cfg=%d\n", count["composed_cfg"]);
    printf("legacy_envelope=%d\n", count["legacy_envelope"]);
    printf("structural_fallback=%d\n", count["structural_fallback"]);
    printf("ledger=%d/%d/%d\n",
      count["composed_block"] + count["composed_cfg"],
      count["legacy_envelope"],
      count["structural_fallback"]);
    printf("total=%d\n", total);
  }' "$REP/owner.tsv" >"$REP/owner-ledger.txt"
```

Any other owner tag, missing row, duplicate row identity, or count mismatch
is a stop.

### 6.3 Per-function bytes and disassembly

Run:

```bash
(cd "$REP" && LC_ALL=C /usr/bin/readelf -SW accepted.o \
  >sections.readelf 2>sections.stderr.raw)
(cd "$REP" && LC_ALL=C /usr/bin/readelf -sW accepted.o \
  >symbols.readelf 2>symbols.stderr.raw)
(cd "$REP" && LC_ALL=C /usr/bin/objcopy \
  --dump-section .text=text.bin accepted.o \
  >objcopy.stdout.raw 2>objcopy.stderr.raw)

LC_ALL=C /usr/bin/awk '
  $4 == "FUNC" && $7 == "1" && ($3 + 0) > 0 {
    print $8 "\t" $2 "\t" $3
  }' "$REP/symbols.readelf" |
  LC_ALL=C /usr/bin/sort -t "$(printf '\t')" -k1,1 \
  >"$REP/functions.sorted.tsv"
```

The three tool statuses must be zero and all tool stderr/stdout channels
that are expected empty must be empty. The function count and unique-name
count must equal `emitted_functions`.

Then execute this exact fixed loop:

```bash
/usr/bin/mkdir -p "$REP/functions"
row=0
while IFS=$'\t' read -r function_name value_hex size_dec; do
  row=$((row + 1))
  id=$(printf '%06d' "$row")
  offset=$((16#$value_hex))
  /usr/bin/dd \
    if="$REP/text.bin" \
    of="$REP/functions/$id.code.bin" \
    bs=1 skip="$offset" count="$size_dec" status=none
  (
    cd "$REP"
    LC_ALL=C /usr/bin/objdump -dr \
      --disassemble="$function_name" accepted.o \
      >"functions/$id.objdump" \
      2>"functions/$id.objdump.stderr"
  )
  test ! -s "$REP/functions/$id.objdump.stderr"
  code_sha=$(/usr/bin/sha256sum "$REP/functions/$id.code.bin" |
    /usr/bin/awk '{print $1}')
  dis_sha=$(/usr/bin/sha256sum "$REP/functions/$id.objdump" |
    /usr/bin/awk '{print $1}')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$function_name" "$size_dec" "$value_hex" "$code_sha" "$dis_sha"
done <"$REP/functions.sorted.tsv" >"$REP/per-function-identities.tsv"
```

Every extracted code file must contain exactly `size_dec` bytes. The loop
row count must equal `emitted_functions`. Empty, duplicate, overlapping, or
out-of-range symbols are a stop. The sorted TSV is the canonical
per-function manifest.

### 6.4 Complete candidate-specific frontier

The frontier is the complete failure set, not a selected historical subset:

```bash
LC_ALL=C /usr/bin/awk '
  $1 == "zllvm-codegen-failure" {
    function = diagnostic = selector_tag = selector_detail = "";
    for (i = 2; i <= NF; i++) {
      if ($i ~ /^function=/) {
        function = $i; sub(/^function=/, "", function)
      } else if ($i ~ /^diagnostic=/) {
        diagnostic = $i; sub(/^diagnostic=/, "", diagnostic)
      } else if ($i ~ /^selector_tag=/) {
        selector_tag = $i; sub(/^selector_tag=/, "", selector_tag)
      } else if ($i ~ /^selector_detail=/) {
        selector_detail = $i; sub(/^selector_detail=/, "", selector_detail)
      }
    }
    if (function == "" || diagnostic == "" ||
        selector_tag == "" || selector_detail == "") exit 93;
    print function "\t" diagnostic "\t" selector_tag "\t" selector_detail
  }' "$REP/report.stderr.raw" |
  LC_ALL=C /usr/bin/sort -t "$(printf '\t')" -k1,1 \
  >"$REP/frontier.tsv"
```

Its row count must equal `failed_functions`; every row must map one-to-one
to an original report failure. Record a second sorted proof grouped by exact
`selector_tag`, `selector_detail`, and `diagnostic`, with counts. These two
files define the candidate-specific frontier identity. Historical six-row
pointer evidence is reference-only and cannot fill a missing v1 row.

### 6.5 Per-command and repetition manifests

For every command retain, before mode changes:

```text
exact command text
exact environment text
start UTC
end UTC
exit status
stdout path/bytes/SHA-256/mode
stderr path/bytes/SHA-256/mode
all declared output paths/bytes/SHA-256/mode
input SHA-256
artifact SHA-256
source commit/tree/status
```

Create a sorted repetition manifest covering every file in `REP` except the
manifest itself, then make every output and manifest `0444` and re-hash after
the final modes. No output is normalized or rewritten after its producing
command.

## 7. Three-repetition equality and canonical names

After all three repetitions finish, compare repetition 1 to repetitions 2
and 3 with raw `cmp` for every corresponding semantic and provenance output,
including:

```text
report stdout/stderr/status and parsed summary
failed-function lists
accepted.ll
accepted.o and object stderr/status
owner.tsv, owner stderr/status, owner ledger
accepted.objdump and stderr/status
sections.readelf and symbols.readelf
text.bin
functions.sorted.tsv
every per-function code file and disassembly
per-function-identities.tsv
frontier.tsv and grouped frontier proof
all command/environment records
```

Path fields in command/provenance records are compared after replacing only
the exact repetition directory token with literal `<REP>` at record creation
time; semantic output files are never normalized. Any byte movement, even
with stable counts, is failure.

Only after every comparison passes, write the following names to the
validation result manifest using the exact observed values:

```text
o2_calls_crt_v1_r131_input_sha256
o2_calls_crt_v1_r131_artifact_sha256
o2_calls_crt_v1_r131_report_sha256
o2_calls_crt_v1_r131_report_population
o2_calls_crt_v1_r131_report_first_failure
o2_calls_crt_v1_r131_report_status
o2_calls_crt_v1_r131_accepted_input_sha256
o2_calls_crt_v1_r131_object_sha256
o2_calls_crt_v1_r131_object_status
o2_calls_crt_v1_r131_owner_sha256
o2_calls_crt_v1_r131_owner_ledger
o2_calls_crt_v1_r131_owner_status
o2_calls_crt_v1_r131_objdump_sha256
o2_calls_crt_v1_r131_per_function_manifest_sha256
o2_calls_crt_v1_r131_per_function_count
o2_calls_crt_v1_r131_frontier_manifest_sha256
o2_calls_crt_v1_r131_frontier_population
```

The result manifest is new evidence requiring separate Reviewer/user
acceptance. It does not modify historical identity files.

## 8. Coverage-only artifact and guard

Coverage begins only after the canonical three-repetition block passes.
Create a second detached worktree with exactly:

```bash
/usr/bin/mkdir -p \
  "$ROOT/coverage/build/home" \
  "$ROOT/coverage/build/tmp" \
  "$ROOT/coverage/build/cache/local" \
  "$ROOT/coverage/build/cache/global" \
  "$ROOT/coverage/build/prefix" \
  "$ROOT/coverage/artifact" \
  "$ROOT/coverage/guard/home" \
  "$ROOT/coverage/guard/tmp"

/usr/bin/git -C "$REPO" worktree add --detach \
  "$ROOT/coverage/source" 43de59b0
```

Verify every bundle hash, then apply exactly:

```bash
git -C "$ROOT/coverage/source" apply --check \
  "$BUNDLE/patches/01-aggregate-consumer.patch"
git -C "$ROOT/coverage/source" apply \
  "$BUNDLE/patches/01-aggregate-consumer.patch"
git -C "$ROOT/coverage/source" apply --check \
  "$BUNDLE/patches/02-fixed-observer.patch"
git -C "$ROOT/coverage/source" apply \
  "$BUNDLE/patches/02-fixed-observer.patch"
git -C "$ROOT/coverage/source" apply --check \
  "$BUNDLE/patches/03-exact-combined-guard.patch"
git -C "$ROOT/coverage/source" apply \
  "$BUNDLE/patches/03-exact-combined-guard.patch"
```

The resulting nine-path manifest must equal
`$BUNDLE/manifests/bundled-source.sha256`. No other path may differ. The
combined patch is check-only corroboration here; it is not additionally
applied.

Run the exact temporary guard once:

```bash
/usr/bin/env -i \
  HOME="$ROOT/coverage/guard/home" \
  TMPDIR="$ROOT/coverage/guard/tmp" \
  PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
  LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
  /home/oleg/bin/zig test \
  src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig \
  >"$ROOT/coverage/guard/stdout.raw" \
  2>"$ROOT/coverage/guard/stderr.raw"
```

The working directory is `$ROOT/coverage/source`; status must be zero.
This is the only correctness guard in the future coverage phase and is not a
canonical identity command.

Build the coverage artifact once with:

```bash
(
  cd "$ROOT/coverage/source"
  /usr/bin/env -i \
    HOME="$ROOT/coverage/build/home" \
    TMPDIR="$ROOT/coverage/build/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /home/oleg/bin/zig build \
    --prefix "$ROOT/coverage/build/prefix" \
    --cache-dir "$ROOT/coverage/build/cache/local" \
    --global-cache-dir "$ROOT/coverage/build/cache/global" \
    --summary all \
    >"$ROOT/coverage/build/stdout.raw" \
    2>"$ROOT/coverage/build/stderr.raw"
)

/usr/bin/install -D -m 0555 \
  "$ROOT/coverage/build/prefix/bin/z_llvm" \
  "$ROOT/coverage/artifact/z_llvm"
```

It must return zero on its only attempt. Freeze the artifact mode `0555`; do
not use it for timing.

## 9. Observation-off and observation-on executions

Use canonical repetition 1's `accepted.ll` as the already derived,
candidate-specific successful subset.

### 9.1 Observation disabled

Run the complete section-6 report/object/owner/objdump/per-function/frontier
procedure with the coverage artifact and with
`ZLLVM_CALL_COVERAGE_PATH` absent. Store it under:

```text
$ROOT/coverage/observation-off
```

Require no coverage-channel file exists.

### 9.2 Observation enabled

Repeat the same semantic commands under:

```text
$ROOT/coverage/observation-on
```

Add exactly one unique environment entry to each `z_llvm` invocation:

```text
ZLLVM_CALL_COVERAGE_PATH=<command-specific exclusive .tsv path>
```

The exact paths are:

```text
report.coverage.tsv
object.coverage.tsv
owner.coverage.tsv
```

Each path must be absent before its command and must be created exactly once.
No coverage variable is passed to `llvm-extract`, `objdump`, `readelf`,
`objcopy`, `dd`, hashing, parsing, or comparison commands.

### 9.3 Semantic comparisons

Raw-compare every semantic output from observation-off and observation-on to
canonical repetition 1:

```text
report bytes/status/population/first failure
failed-function lists and accepted.ll
object bytes/status/stderr
owner bytes/status/stderr/ledger
whole objdump
all per-function bytes and disassemblies
per-function manifest
complete frontier and grouped proof
```

All three sets must be exactly equal. The coverage artifact cannot establish
or replace a canonical value.

### 9.4 Counter invariants

Every coverage TSV must have the exact schema and two family rows emitted by
the frozen observer. `unexpected_family_events` and
`argument_index_overflow_events` must be zero in all three files.

For `object.coverage.tsv` and `owner.coverage.tsv`, independently require:

```text
direct_call.transactions > 0
int_byte_size_call.transactions > 0

for each family:
  transactions
    == actions_attached
    == materializations_completed
    == actions_completed
    == commits
  requests_registered == arguments_staged
  requests_registered[position N] == arguments_staged[position N]
    for every N in 0..5

int_byte_size_call.requests_registered
  == int_byte_size_call.transactions
int_byte_size_call.position_0
  == int_byte_size_call.transactions
int_byte_size_call.position_1..5 == 0

direct_call.requests_registered > 0
direct_call.arguments_staged > 0
```

The complete object and owner counter files must be byte-identical. For the
raw-input report counter file, require every listed lifecycle count for both
families to be nonzero and both unexpected/overflow counts zero. It is not
used to assert success-count equality because report-all deliberately
continues after failed functions.

Static classifier matches, patch content, and INBOX-181 isolation are
supporting provenance only; they cannot replace any nonzero dynamic count.

## 10. Exact restoration proof

After coverage evidence is complete, reverse only the three component
patches in exact order `3, 2, 1`:

```bash
git -C "$ROOT/coverage/source" apply -R \
  "$BUNDLE/patches/03-exact-combined-guard.patch"
git -C "$ROOT/coverage/source" apply -R \
  "$BUNDLE/patches/02-fixed-observer.patch"
git -C "$ROOT/coverage/source" apply -R \
  "$BUNDLE/patches/01-aggregate-consumer.patch"
```

Require:

```text
coverage worktree HEAD == 43de59b0
git status --porcelain == empty
tracked source manifest == pre-patch manifest
observer source absent
facade manifest unchanged
bypass TSV unchanged at ratchet 131
retention/watcher/stash surfaces unchanged
```

Retain the detached worktree and all validation evidence pending review.
Do not remove a worktree, delete caches, clean temporary roots, or execute
retention cleanup without later authority.

## 11. Immutable retention and future acceptance boundary

Before reporting validation success, make all retained inputs, artifacts,
patches, commands, logs, outputs, status files, manifests, comparisons, and
restoration proofs read-only. Re-run the existing retention reporter only if
a later directive explicitly authorizes it; INBOX-187 does not.

Validation execution stops after producing the complete bundle. It does not
adopt the protocol. The ordered later boundaries are:

1. execute this closed validation contract;
2. Watcher/Reviewer/user accept or reject the new identities and coverage;
3. separately authorize combined production wiring;
4. run full wiring correctness gates and final owner recount;
5. allow only the conditional direct ratchet credit `131 -> 130`;
6. assume no helper-collapse credit;
7. build the final post-commit production artifact;
8. only then run separately authorized amended performance.

The coverage artifact is excluded from steps 3 through 8.

## 12. Fail-closed stops

Stop immediately, retain all evidence, and perform no later step on:

- wrong/missing/dirty source commit, tree, index, worktree, watcher, stash,
  adopted input, adoption manifest, reproduction manifest, pin, policy,
  cleanup tool, facade, bypass TSV, Zig source, or tool hash;
- insufficient capacity or a preexisting future output path;
- bundle hash, mode, apply-check, touched-path, source-manifest, or
  restoration mismatch;
- any need for a public helper, fifth call facade addition, new action tag,
  request form, destination, import/planning edge, callback, allocator,
  scheduler, home/liveness hint, classifier change, fallback, or API
  widening;
- build failure, command failure, unexpected status, missing output,
  unexpected stdout/stderr, or mode/hash movement;
- extraction ambiguity, duplicate failure identity, unsupported identity
  spelling, report arithmetic mismatch, owner mismatch, or per-function
  extraction mismatch;
- any byte difference among the three canonical repetitions;
- any semantic difference between canonical, observation-off, and
  observation-on results;
- any zero required call-family/lifecycle counter, unexpected-family event,
  position overflow, lifecycle equality failure, or guard failure;
- any attempt to use the coverage artifact for canonical identity or
  performance;
- any attempt to substitute historical `49a19f04`, `061a64e4`,
  `5d91960e`, `accepted_cohort.ll`, an INBOX-178 regeneration, or another
  candidate;
- contamination, normalization, retry, alternate command, repair,
  fix-forward, cleanup, deletion, pin edit, production wiring, or credit.

There is no automatic retry, alternate candidate, protocol amendment,
threshold change, or local semantic fix.

## 13. INBOX-187 execution record

INBOX-187 performed only:

- repository and retained-artifact identity inspection;
- patch derivation from accepted INBOX-181 provenance;
- fixed observer authoring;
- `git apply --check`, temporary patch application, manifest comparison, and
  exact source restoration;
- read-only bundle creation;
- this evidence document.

It ran no project code, build, Zig command, `z_llvm`, selector/report, object
generation, guard/test/gate, baseline validation, dynamic coverage,
performance, production wiring, pin edit, cleanup, or ratchet credit.

Disposition:

```text
contract=CLOSED_NON_EXECUTING
patch_bundle=FROZEN_READ_ONLY
canonical_identity=NOT_YET_DEFINED
coverage=NOT_RUN
validation=NOT_RUN
protocol=NOT_ADOPTED
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_BEFORE_VALIDATION_EXECUTION
```
