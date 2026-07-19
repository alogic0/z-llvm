# INBOX-187 — compiler-rt v1 baseline-validation execution contract

Status: **contract and patch freeze complete; execution not performed**.

This document closes the future ratchet-131 baseline-validation procedure.
It deliberately separates canonical identity creation from temporary call
coverage. No command in the future procedure was executed in INBOX-187.
Production remains dormant and the bypass ratchet remains **131**.

INBOX-187A closed the previously withheld section-9 command contract from
operating-document commit
`e4a8952633c101949093130b935db8503e921b68`. The accepted INBOX-187 document
commit is `a041487eee50f86b594beeeedb2071479842c093`. The correction changes only
this document: it does not change or execute the accepted patch bundle,
validation protocol, compiler, or any retained artifact.

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

Coverage uses two distinct immutable inputs for two distinct purposes:

```text
raw report input:
  /home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll

successful-subset input:
  /home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/canonical/repetition-1/accepted.ll
```

The raw input is used only by each phase's `--report-all-codegen-failures`
command. The single canonical `accepted.ll` is referenced by every coverage
object/owner command and by all downstream object inspection. Neither
coverage phase runs `llvm-extract`, creates an `accepted.ll`, copies one,
normalizes one, or chooses another successful subset.

### 9.1 Exact paths, shell state, and command recorder

The following blocks are one ordered command stream supplied to one
`/bin/bash --noprofile --norc` process. Launch that process exactly from the
coverage source root with an otherwise empty environment:

```bash
/usr/bin/mkdir -p \
  /home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/driver/home \
  /home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/driver/tmp
(
  cd /home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/source
  exec /usr/bin/env -i \
    HOME=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/driver/home \
    TMPDIR=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/driver/tmp \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /bin/bash --noprofile --norc
)
```

The driver environment deliberately contains no coverage variable. Before
any coverage command, set exactly:

```bash
set -euo pipefail
umask 022

readonly ROOT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1
readonly RAW_INPUT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
readonly COVERAGE_ARTIFACT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/artifact/z_llvm
readonly CANONICAL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/canonical/repetition-1
readonly CANONICAL_ACCEPTED=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/canonical/repetition-1/accepted.ll
readonly CANONICAL_IDENTITIES=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/canonical/o2_calls_crt_v1_r131.identities.tsv
readonly OFF=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/observation-off
readonly ON=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/observation-on
readonly REPORT_CHANNEL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/observation-on/report.coverage.tsv
readonly OBJECT_CHANNEL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/observation-on/object.coverage.tsv
readonly OWNER_CHANNEL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1/coverage/observation-on/owner.coverage.tsv
```

Section 7 must have written `CANONICAL_IDENTITIES` as two-column TSV
`name<TAB>value`, with exactly one row for each frozen
`o2_calls_crt_v1_r131_*` name. Section 6.5 command retention must place the
canonical repetition-1 statuses at these exact paths:

```text
$CANONICAL/report.status                     = 1
$CANONICAL/report-summary.status             = 0
$CANONICAL/failures-in-order.status           = 0
$CANONICAL/failures-sorted.status             = 0
$CANONICAL/frontier.status                    = 0
$CANONICAL/frontier-grouped.status            = 0
$CANONICAL/object.status                     = 0
$CANONICAL/owner.status                      = 0
$CANONICAL/objdump.status                    = 0
$CANONICAL/readelf-sections.status           = 0
$CANONICAL/readelf-symbols.status            = 0
$CANONICAL/objcopy-text.status               = 0
$CANONICAL/functions-sorted.status           = 0
$CANONICAL/per-function.status               = 0
$CANONICAL/owner-ledger.status               = 0
```

Every coverage command below is recorded through this one exact,
non-transforming Bash function:

```bash
run_recorded() {
  local record_prefix="$1"
  local expected_status="$2"
  local stdout_path="$3"
  local stderr_path="$4"
  shift 4

  printf '%q ' "$@" >"${record_prefix}.command.txt"
  printf '\n' >>"${record_prefix}.command.txt"
  pwd -P >"${record_prefix}.cwd.txt"
  /usr/bin/env | LC_ALL=C /usr/bin/sort \
    >"${record_prefix}.environment.txt"
  printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"${record_prefix}.start.utc"
  set +e
  "$@" >"$stdout_path" 2>"$stderr_path"
  local status="$?"
  set -e
  printf '%s\n' "$status" >"${record_prefix}.status"
  printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"${record_prefix}.end.utc"
  test "$status" -eq "$expected_status"
}

require_identity_sha() {
  local identity_name="$1"
  local input_path="$2"
  local record_prefix="$3"
  local expected_path="${record_prefix}.expected.sha256"
  local actual_path="${record_prefix}.actual.sha256"

  /usr/bin/awk -F '\t' -v name="$identity_name" \
    '$1 == name { print $2; found += 1 }
     END { if (found != 1) exit 96 }' \
    "$CANONICAL_IDENTITIES" >"$expected_path"
  /usr/bin/sha256sum "$input_path" |
    /usr/bin/awk '{print $1}' >"$actual_path"
  run_recorded "${record_prefix}.cmp" 0 \
    "${record_prefix}.cmp.stdout" \
    "${record_prefix}.cmp.stderr" \
    /usr/bin/cmp "$expected_path" "$actual_path"
}
```

Thus each invocation retains exact argv, start/end UTC, status, raw stdout,
and raw stderr. No command output is piped through `tee` or normalized.

Create only the declared phase directories:

```bash
test ! -e "$OFF"
test ! -e "$ON"
/usr/bin/mkdir -p \
  "$OFF/home" "$OFF/tmp" "$OFF/records" "$OFF/functions" \
  "$ON/home" "$ON/tmp" "$ON/records" "$ON/functions" \
  "$ROOT/coverage/reference"
printf '0\n' >"$ROOT/coverage/records-directory-creation.status"
```

The three prospective channel paths must all be absent before observation
off:

```bash
test ! -e "$REPORT_CHANNEL"
test ! -e "$OBJECT_CHANNEL"
test ! -e "$OWNER_CHANNEL"
printf 'all-three-absent\n' \
  >"$ROOT/coverage/reference/channels.before-observation-off.txt"
```

### 9.2 Freeze and verify the sole canonical successful subset

The accepted-input identity is captured before either coverage phase:

```bash
test -f "$CANONICAL_ACCEPTED"
test "$(/usr/bin/stat -c '%a' "$CANONICAL_ACCEPTED")" = 444
accepted_bytes=$(/usr/bin/stat -c '%s' "$CANONICAL_ACCEPTED")
accepted_sha=$(/usr/bin/sha256sum "$CANONICAL_ACCEPTED" |
  /usr/bin/awk '{print $1}')
expected_sha=$(/usr/bin/awk -F '\t' \
  '$1 == "o2_calls_crt_v1_r131_accepted_input_sha256" {
     print $2; found += 1
   }
   END { if (found != 1) exit 94 }' \
  "$CANONICAL_IDENTITIES")
test "$accepted_sha" = "$expected_sha"
printf 'path\tbytes\tmode\tsha256\n%s\t%s\t0444\t%s\n' \
  "$CANONICAL_ACCEPTED" "$accepted_bytes" "$accepted_sha" \
  >"$ROOT/coverage/reference/canonical-accepted.before.tsv"
```

`canonical-accepted.before.tsv` freezes the required absolute path, byte
count, mode, and SHA-256. The same four fields are re-read and raw-compared
after observation off and after observation on.

### 9.3 Observation-off raw report: adopted raw input only

The observation-off report command is first and consumes `RAW_INPUT`:

```bash
run_recorded \
  "$OFF/records/report" 1 \
  "$OFF/report.stdout.raw" \
  "$OFF/report.stderr.raw" \
  /usr/bin/env -i \
    HOME="$OFF/home" \
    TMPDIR="$OFF/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    "$COVERAGE_ARTIFACT" \
    --emit=obj \
    --generic-cfg-selector \
    --report-all-codegen-failures \
    --target=x86_64-linux \
    --input-limit=67108864 \
    "$RAW_INPUT"
```

The `env -i` list contains no `ZLLVM_CALL_COVERAGE_PATH`. Require empty
stdout, status `1`, and exactly one summary:

```bash
test ! -s "$OFF/report.stdout.raw"

run_recorded \
  "$OFF/records/report-summary" 0 \
  "$OFF/report.summary.txt" \
  "$OFF/report-summary.stderr.raw" \
  /bin/bash -c '
    /usr/bin/awk '\''
      $1 == "summary" && $2 == "zllvm-codegen-report-all" {
        print; found += 1
      }
      END { if (found != 1) exit 95 }
    '\'' "$1"
  ' _ "$OFF/report.stderr.raw"

run_recorded \
  "$OFF/records/failures-in-order" 0 \
  "$OFF/failed-functions.in-report-order.txt" \
  "$OFF/failures-in-order.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk '\''
      $1 == "zllvm-codegen-failure" {
        if ($2 !~ /^function=/) exit 91;
        sub(/^function=/, "", $2);
        print $2
      }
    '\'' "$1"
  ' _ "$OFF/report.stderr.raw"

run_recorded \
  "$OFF/records/failures-sorted" 0 \
  "$OFF/failed-functions.sorted.txt" \
  "$OFF/failures-sorted.stderr.raw" \
  /usr/bin/sort -u "$OFF/failed-functions.in-report-order.txt"

run_recorded \
  "$OFF/records/frontier" 0 \
  "$OFF/frontier.tsv" \
  "$OFF/frontier.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk '\''
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
      }
    '\'' "$1" | LC_ALL=C /usr/bin/sort -t "$(printf "\t")" -k1,1
  ' _ "$OFF/report.stderr.raw"

run_recorded \
  "$OFF/records/frontier-grouped" 0 \
  "$OFF/frontier-grouped.tsv" \
  "$OFF/frontier-grouped.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk -F "\t" '\''
      { key = $3 "\t" $4 "\t" $2; count[key] += 1 }
      END { for (key in count) print key "\t" count[key] }
    '\'' "$1" | LC_ALL=C /usr/bin/sort
  ' _ "$OFF/frontier.tsv"
```

No extraction command occurs. Require:

```bash
test ! -e "$OFF/accepted.ll"
run_recorded "$OFF/records/cmp-report-stdout" 0 \
  "$OFF/cmp-report-stdout.stdout" "$OFF/cmp-report-stdout.stderr" \
  /usr/bin/cmp "$CANONICAL/report.stdout.raw" "$OFF/report.stdout.raw"
run_recorded "$OFF/records/cmp-report-stderr" 0 \
  "$OFF/cmp-report-stderr.stdout" "$OFF/cmp-report-stderr.stderr" \
  /usr/bin/cmp "$CANONICAL/report.stderr.raw" "$OFF/report.stderr.raw"
run_recorded "$OFF/records/cmp-report-status" 0 \
  "$OFF/cmp-report-status.stdout" "$OFF/cmp-report-status.stderr" \
  /usr/bin/cmp "$CANONICAL/report.status" "$OFF/records/report.status"
run_recorded "$OFF/records/cmp-report-summary" 0 \
  "$OFF/cmp-report-summary.stdout" "$OFF/cmp-report-summary.stderr" \
  /usr/bin/cmp "$CANONICAL/report.summary.txt" "$OFF/report.summary.txt"
run_recorded "$OFF/records/cmp-failures-in-order" 0 \
  "$OFF/cmp-failures-in-order.stdout" "$OFF/cmp-failures-in-order.stderr" \
  /usr/bin/cmp "$CANONICAL/failed-functions.in-report-order.txt" \
  "$OFF/failed-functions.in-report-order.txt"
run_recorded "$OFF/records/cmp-failures-sorted" 0 \
  "$OFF/cmp-failures-sorted.stdout" "$OFF/cmp-failures-sorted.stderr" \
  /usr/bin/cmp "$CANONICAL/failed-functions.sorted.txt" \
  "$OFF/failed-functions.sorted.txt"
run_recorded "$OFF/records/cmp-frontier" 0 \
  "$OFF/cmp-frontier.stdout" "$OFF/cmp-frontier.stderr" \
  /usr/bin/cmp "$CANONICAL/frontier.tsv" "$OFF/frontier.tsv"
run_recorded "$OFF/records/cmp-frontier-grouped" 0 \
  "$OFF/cmp-frontier-grouped.stdout" "$OFF/cmp-frontier-grouped.stderr" \
  /usr/bin/cmp "$CANONICAL/frontier-grouped.tsv" \
  "$OFF/frontier-grouped.tsv"

for status_name in \
  report-summary failures-in-order failures-sorted frontier frontier-grouped
do
  run_recorded "$OFF/records/cmp-canonical-$status_name-status" 0 \
    "$OFF/cmp-canonical-$status_name-status.stdout" \
    "$OFF/cmp-canonical-$status_name-status.stderr" \
    /usr/bin/cmp "$CANONICAL/$status_name.status" \
    "$OFF/records/$status_name.status"
done

require_identity_sha o2_calls_crt_v1_r131_object_sha256 \
  "$OFF/accepted.o" "$OFF/records/object-identity"
require_identity_sha o2_calls_crt_v1_r131_owner_sha256 \
  "$OFF/owner.tsv" "$OFF/records/owner-identity"
require_identity_sha o2_calls_crt_v1_r131_objdump_sha256 \
  "$OFF/accepted.objdump" "$OFF/records/objdump-identity"
require_identity_sha o2_calls_crt_v1_r131_per_function_manifest_sha256 \
  "$OFF/per-function-identities.tsv" \
  "$OFF/records/per-function-identity"
require_identity_sha o2_calls_crt_v1_r131_frontier_manifest_sha256 \
  "$OFF/frontier.tsv" "$OFF/records/frontier-identity"
```

These are raw-report invariants. They do not use `accepted.ll` and do not
assert successful-transaction counter equality.

Freeze the raw report hash against the newly named canonical identity:

```bash
require_identity_sha \
  o2_calls_crt_v1_r131_report_sha256 \
  "$OFF/report.stderr.raw" \
  "$OFF/records/report-identity"
```

### 9.4 Observation-off successful-subset outputs

The object and owner commands reference the one absolute
`CANONICAL_ACCEPTED` path:

```bash
run_recorded \
  "$OFF/records/object" 0 \
  "$OFF/accepted.o" \
  "$OFF/object.stderr.raw" \
  /usr/bin/env -i \
    HOME="$OFF/home" \
    TMPDIR="$OFF/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    "$COVERAGE_ARTIFACT" \
    --emit=obj \
    --generic-cfg-selector \
    --target=x86_64-linux \
    --input-limit=67108864 \
    "$CANONICAL_ACCEPTED"

run_recorded \
  "$OFF/records/owner" 0 \
  "$OFF/owner.tsv" \
  "$OFF/owner.stderr.raw" \
  /usr/bin/env -i \
    HOME="$OFF/home" \
    TMPDIR="$OFF/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    "$COVERAGE_ARTIFACT" \
    --emit=selection-owner-manifest \
    --generic-cfg-selector \
    --target=x86_64-linux \
    --input-limit=67108864 \
    "$CANONICAL_ACCEPTED"
```

Again, neither environment contains the coverage variable. Require both
stderr files empty. Derive only from `OFF/accepted.o`:

```bash
run_recorded "$OFF/records/objdump" 0 \
  "$OFF/accepted.objdump" "$OFF/objdump.stderr.raw" \
  /bin/bash -c 'cd "$1" && exec /usr/bin/objdump -d accepted.o' _ "$OFF"

run_recorded "$OFF/records/readelf-sections" 0 \
  "$OFF/sections.readelf" "$OFF/sections.stderr.raw" \
  /usr/bin/readelf -SW "$OFF/accepted.o"

run_recorded "$OFF/records/readelf-symbols" 0 \
  "$OFF/symbols.readelf" "$OFF/symbols.stderr.raw" \
  /usr/bin/readelf -sW "$OFF/accepted.o"

run_recorded "$OFF/records/objcopy-text" 0 \
  "$OFF/objcopy.stdout.raw" "$OFF/objcopy.stderr.raw" \
  /usr/bin/objcopy --dump-section ".text=$OFF/text.bin" "$OFF/accepted.o"

run_recorded "$OFF/records/functions-sorted" 0 \
  "$OFF/functions.sorted.tsv" "$OFF/functions-sorted.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk '\''
      $4 == "FUNC" && $7 == "1" && ($3 + 0) > 0 {
        print $8 "\t" $2 "\t" $3
      }
    '\'' "$1" | LC_ALL=C /usr/bin/sort -t "$(printf "\t")" -k1,1
  ' _ "$OFF/symbols.readelf"

run_recorded "$OFF/records/per-function" 0 \
  "$OFF/per-function-identities.tsv" "$OFF/per-function.stderr.raw" \
  /bin/bash -c '
    set -euo pipefail
    phase="$1"
    row=0
    while IFS=$'\''\t'\'' read -r function_name value_hex size_dec; do
      row=$((row + 1))
      id=$(printf "%06d" "$row")
      offset=$((16#$value_hex))
      /usr/bin/dd if="$phase/text.bin" \
        of="$phase/functions/$id.code.bin" \
        bs=1 skip="$offset" count="$size_dec" status=none
      (
        cd "$phase"
        LC_ALL=C /usr/bin/objdump -dr \
          --disassemble="$function_name" accepted.o \
          >"functions/$id.objdump" \
          2>"functions/$id.objdump.stderr"
      )
      test ! -s "$phase/functions/$id.objdump.stderr"
      test "$(/usr/bin/stat -c "%s" "$phase/functions/$id.code.bin")" \
        -eq "$size_dec"
      code_sha=$(/usr/bin/sha256sum "$phase/functions/$id.code.bin" |
        /usr/bin/awk "{print \\$1}")
      dis_sha=$(/usr/bin/sha256sum "$phase/functions/$id.objdump" |
        /usr/bin/awk "{print \\$1}")
      printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$id" "$function_name" "$size_dec" "$value_hex" \
        "$code_sha" "$dis_sha"
    done <"$phase/functions.sorted.tsv"
  ' _ "$OFF"

run_recorded "$OFF/records/owner-ledger" 0 \
  "$OFF/owner-ledger.txt" "$OFF/owner-ledger.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk -F "\t" '\''
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
      }
    '\'' "$1"
  ' _ "$OFF/owner.tsv"
```

Raw-compare the fixed outputs:

```bash
for relative in \
  accepted.o object.stderr.raw owner.tsv owner.stderr.raw \
  accepted.objdump objdump.stderr.raw sections.readelf sections.stderr.raw \
  symbols.readelf symbols.stderr.raw text.bin objcopy.stdout.raw \
  objcopy.stderr.raw functions.sorted.tsv per-function-identities.tsv \
  owner-ledger.txt
do
  label=${relative//[^A-Za-z0-9]/-}
  run_recorded "$OFF/records/cmp-canonical-$label" 0 \
    "$OFF/cmp-canonical-$label.stdout" \
    "$OFF/cmp-canonical-$label.stderr" \
    /usr/bin/cmp "$CANONICAL/$relative" "$OFF/$relative"
done

while IFS=$'\t' read -r id function_name size_dec value_hex code_sha dis_sha
do
  run_recorded "$OFF/records/cmp-canonical-$id-code" 0 \
    "$OFF/cmp-canonical-$id-code.stdout" \
    "$OFF/cmp-canonical-$id-code.stderr" \
    /usr/bin/cmp "$CANONICAL/functions/$id.code.bin" \
    "$OFF/functions/$id.code.bin"
  run_recorded "$OFF/records/cmp-canonical-$id-objdump" 0 \
    "$OFF/cmp-canonical-$id-objdump.stdout" \
    "$OFF/cmp-canonical-$id-objdump.stderr" \
    /usr/bin/cmp "$CANONICAL/functions/$id.objdump" \
    "$OFF/functions/$id.objdump"
done <"$CANONICAL/per-function-identities.tsv"

for status_name in \
  object owner objdump readelf-sections readelf-symbols objcopy-text \
  functions-sorted per-function owner-ledger
do
  run_recorded "$OFF/records/cmp-canonical-$status_name-status" 0 \
    "$OFF/cmp-canonical-$status_name-status.stdout" \
    "$OFF/cmp-canonical-$status_name-status.stderr" \
    /usr/bin/cmp "$CANONICAL/$status_name.status" \
    "$OFF/records/$status_name.status"
done
```

The comparison loop is driven only by the immutable canonical manifest. It
must compare the canonical function count exactly once with no missing or
extra `OFF/functions` file.

Observation off must still have no channel and no local accepted subset:

```bash
test ! -e "$REPORT_CHANNEL"
test ! -e "$OBJECT_CHANNEL"
test ! -e "$OWNER_CHANNEL"
test ! -e "$OFF/accepted.ll"
printf 'all-three-absent\n' \
  >"$ROOT/coverage/reference/channels.after-observation-off.txt"

test "$(/usr/bin/stat -c '%a' "$CANONICAL_ACCEPTED")" = 444
printf 'path\tbytes\tmode\tsha256\n%s\t%s\t0444\t%s\n' \
  "$CANONICAL_ACCEPTED" \
  "$(/usr/bin/stat -c '%s' "$CANONICAL_ACCEPTED")" \
  "$(/usr/bin/sha256sum "$CANONICAL_ACCEPTED" |
    /usr/bin/awk '{print $1}')" \
  >"$ROOT/coverage/reference/canonical-accepted.after-off.tsv"
/usr/bin/cmp "$ROOT/coverage/reference/canonical-accepted.before.tsv" \
  "$ROOT/coverage/reference/canonical-accepted.after-off.tsv"
printf '0\n' \
  >"$ROOT/coverage/reference/canonical-accepted.after-off.cmp.status"
```

### 9.5 Observation-on raw report: one exclusive report channel

Before the raw report:

```bash
test ! -e "$REPORT_CHANNEL"
test ! -e "$OBJECT_CHANNEL"
test ! -e "$OWNER_CHANNEL"
test ! -e "$ON/accepted.ll"
```

Run exactly one report producer, against `RAW_INPUT`:

```bash
run_recorded \
  "$ON/records/report" 1 \
  "$ON/report.stdout.raw" \
  "$ON/report.stderr.raw" \
  /usr/bin/env -i \
    HOME="$ON/home" \
    TMPDIR="$ON/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    ZLLVM_CALL_COVERAGE_PATH="$REPORT_CHANNEL" \
    "$COVERAGE_ARTIFACT" \
    --emit=obj \
    --generic-cfg-selector \
    --report-all-codegen-failures \
    --target=x86_64-linux \
    --input-limit=67108864 \
    "$RAW_INPUT"

test -f "$REPORT_CHANNEL"
test ! -e "$OBJECT_CHANNEL"
test ! -e "$OWNER_CHANNEL"
printf 'report-created-once\n' \
  >"$ON/records/report-channel.presence.txt"
```

Parse the raw report with these five commands, in order:

```bash
test ! -s "$ON/report.stdout.raw"

run_recorded \
  "$ON/records/report-summary" 0 \
  "$ON/report.summary.txt" \
  "$ON/report-summary.stderr.raw" \
  /bin/bash -c '
    /usr/bin/awk '\''
      $1 == "summary" && $2 == "zllvm-codegen-report-all" {
        print; found += 1
      }
      END { if (found != 1) exit 95 }
    '\'' "$1"
  ' _ "$ON/report.stderr.raw"

run_recorded \
  "$ON/records/failures-in-order" 0 \
  "$ON/failed-functions.in-report-order.txt" \
  "$ON/failures-in-order.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk '\''
      $1 == "zllvm-codegen-failure" {
        if ($2 !~ /^function=/) exit 91;
        sub(/^function=/, "", $2);
        print $2
      }
    '\'' "$1"
  ' _ "$ON/report.stderr.raw"

run_recorded \
  "$ON/records/failures-sorted" 0 \
  "$ON/failed-functions.sorted.txt" \
  "$ON/failures-sorted.stderr.raw" \
  /usr/bin/sort -u "$ON/failed-functions.in-report-order.txt"

run_recorded \
  "$ON/records/frontier" 0 \
  "$ON/frontier.tsv" \
  "$ON/frontier.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk '\''
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
      }
    '\'' "$1" | LC_ALL=C /usr/bin/sort -t "$(printf "\t")" -k1,1
  ' _ "$ON/report.stderr.raw"

run_recorded \
  "$ON/records/frontier-grouped" 0 \
  "$ON/frontier-grouped.tsv" \
  "$ON/frontier-grouped.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk -F "\t" '\''
      { key = $3 "\t" $4 "\t" $2; count[key] += 1 }
      END { for (key in count) print key "\t" count[key] }
    '\'' "$1" | LC_ALL=C /usr/bin/sort
  ' _ "$ON/frontier.tsv"
```

These five commands consume only `$ON/report.stderr.raw`; they receive no
coverage environment variable and invoke neither `z_llvm` nor
`llvm-extract`.

Raw-compare all seven report artifacts and status to canonical repetition 1
and observation off:

```bash
for relative in \
  report.stdout.raw report.stderr.raw report.summary.txt \
  failed-functions.in-report-order.txt failed-functions.sorted.txt \
  frontier.tsv frontier-grouped.tsv
do
  label=${relative//[^A-Za-z0-9]/-}
  run_recorded "$ON/records/cmp-canonical-$label" 0 \
    "$ON/cmp-canonical-$label.stdout" \
    "$ON/cmp-canonical-$label.stderr" \
    /usr/bin/cmp "$CANONICAL/$relative" "$ON/$relative"
  run_recorded "$ON/records/cmp-off-$label" 0 \
    "$ON/cmp-off-$label.stdout" \
    "$ON/cmp-off-$label.stderr" \
    /usr/bin/cmp "$OFF/$relative" "$ON/$relative"
done

run_recorded "$ON/records/cmp-canonical-report-status" 0 \
  "$ON/cmp-canonical-report-status.stdout" \
  "$ON/cmp-canonical-report-status.stderr" \
  /usr/bin/cmp "$CANONICAL/report.status" "$ON/records/report.status"
run_recorded "$ON/records/cmp-off-report-status" 0 \
  "$ON/cmp-off-report-status.stdout" \
  "$ON/cmp-off-report-status.stderr" \
  /usr/bin/cmp "$OFF/records/report.status" "$ON/records/report.status"

for status_name in \
  report-summary failures-in-order failures-sorted frontier frontier-grouped
do
  run_recorded "$ON/records/cmp-canonical-$status_name-status" 0 \
    "$ON/cmp-canonical-$status_name-status.stdout" \
    "$ON/cmp-canonical-$status_name-status.stderr" \
    /usr/bin/cmp "$CANONICAL/$status_name.status" \
    "$ON/records/$status_name.status"
  run_recorded "$ON/records/cmp-off-$status_name-status" 0 \
    "$ON/cmp-off-$status_name-status.stdout" \
    "$ON/cmp-off-$status_name-status.stderr" \
    /usr/bin/cmp "$OFF/records/$status_name.status" \
    "$ON/records/$status_name.status"
done

require_identity_sha o2_calls_crt_v1_r131_object_sha256 \
  "$ON/accepted.o" "$ON/records/object-identity"
require_identity_sha o2_calls_crt_v1_r131_owner_sha256 \
  "$ON/owner.tsv" "$ON/records/owner-identity"
require_identity_sha o2_calls_crt_v1_r131_objdump_sha256 \
  "$ON/accepted.objdump" "$ON/records/objdump-identity"
require_identity_sha o2_calls_crt_v1_r131_per_function_manifest_sha256 \
  "$ON/per-function-identities.tsv" \
  "$ON/records/per-function-identity"
require_identity_sha o2_calls_crt_v1_r131_frontier_manifest_sha256 \
  "$ON/frontier.tsv" "$ON/records/frontier-identity"
```

`accepted.ll` is neither produced nor referenced by the report command.

Freeze the observation-on raw report hash against the same canonical
identity:

```bash
require_identity_sha \
  o2_calls_crt_v1_r131_report_sha256 \
  "$ON/report.stderr.raw" \
  "$ON/records/report-identity"
```

### 9.6 Observation-on successful-subset outputs: two exclusive channels

The object command is the sole producer of `OBJECT_CHANNEL`:

```bash
test ! -e "$OBJECT_CHANNEL"
run_recorded \
  "$ON/records/object" 0 \
  "$ON/accepted.o" \
  "$ON/object.stderr.raw" \
  /usr/bin/env -i \
    HOME="$ON/home" \
    TMPDIR="$ON/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    ZLLVM_CALL_COVERAGE_PATH="$OBJECT_CHANNEL" \
    "$COVERAGE_ARTIFACT" \
    --emit=obj \
    --generic-cfg-selector \
    --target=x86_64-linux \
    --input-limit=67108864 \
    "$CANONICAL_ACCEPTED"
test -f "$OBJECT_CHANNEL"
test ! -e "$OWNER_CHANNEL"
printf 'object-created-once\n' \
  >"$ON/records/object-channel.presence.txt"
```

The owner command is the sole producer of `OWNER_CHANNEL`:

```bash
test ! -e "$OWNER_CHANNEL"
run_recorded \
  "$ON/records/owner" 0 \
  "$ON/owner.tsv" \
  "$ON/owner.stderr.raw" \
  /usr/bin/env -i \
    HOME="$ON/home" \
    TMPDIR="$ON/tmp" \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    ZLLVM_CALL_COVERAGE_PATH="$OWNER_CHANNEL" \
    "$COVERAGE_ARTIFACT" \
    --emit=selection-owner-manifest \
    --generic-cfg-selector \
    --target=x86_64-linux \
    --input-limit=67108864 \
    "$CANONICAL_ACCEPTED"
test -f "$OWNER_CHANNEL"
printf 'owner-created-once\n' \
  >"$ON/records/owner-channel.presence.txt"
```

The downstream commands are exactly:

```bash
run_recorded "$ON/records/objdump" 0 \
  "$ON/accepted.objdump" "$ON/objdump.stderr.raw" \
  /bin/bash -c 'cd "$1" && exec /usr/bin/objdump -d accepted.o' _ "$ON"

run_recorded "$ON/records/readelf-sections" 0 \
  "$ON/sections.readelf" "$ON/sections.stderr.raw" \
  /usr/bin/readelf -SW "$ON/accepted.o"

run_recorded "$ON/records/readelf-symbols" 0 \
  "$ON/symbols.readelf" "$ON/symbols.stderr.raw" \
  /usr/bin/readelf -sW "$ON/accepted.o"

run_recorded "$ON/records/objcopy-text" 0 \
  "$ON/objcopy.stdout.raw" "$ON/objcopy.stderr.raw" \
  /usr/bin/objcopy --dump-section ".text=$ON/text.bin" "$ON/accepted.o"

run_recorded "$ON/records/functions-sorted" 0 \
  "$ON/functions.sorted.tsv" "$ON/functions-sorted.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk '\''
      $4 == "FUNC" && $7 == "1" && ($3 + 0) > 0 {
        print $8 "\t" $2 "\t" $3
      }
    '\'' "$1" | LC_ALL=C /usr/bin/sort -t "$(printf "\t")" -k1,1
  ' _ "$ON/symbols.readelf"

run_recorded "$ON/records/per-function" 0 \
  "$ON/per-function-identities.tsv" "$ON/per-function.stderr.raw" \
  /bin/bash -c '
    set -euo pipefail
    phase="$1"
    row=0
    while IFS=$'\''\t'\'' read -r function_name value_hex size_dec; do
      row=$((row + 1))
      id=$(printf "%06d" "$row")
      offset=$((16#$value_hex))
      /usr/bin/dd if="$phase/text.bin" \
        of="$phase/functions/$id.code.bin" \
        bs=1 skip="$offset" count="$size_dec" status=none
      (
        cd "$phase"
        LC_ALL=C /usr/bin/objdump -dr \
          --disassemble="$function_name" accepted.o \
          >"functions/$id.objdump" \
          2>"functions/$id.objdump.stderr"
      )
      test ! -s "$phase/functions/$id.objdump.stderr"
      test "$(/usr/bin/stat -c "%s" "$phase/functions/$id.code.bin")" \
        -eq "$size_dec"
      code_sha=$(/usr/bin/sha256sum "$phase/functions/$id.code.bin" |
        /usr/bin/awk "{print \\$1}")
      dis_sha=$(/usr/bin/sha256sum "$phase/functions/$id.objdump" |
        /usr/bin/awk "{print \\$1}")
      printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$id" "$function_name" "$size_dec" "$value_hex" \
        "$code_sha" "$dis_sha"
    done <"$phase/functions.sorted.tsv"
  ' _ "$ON"

run_recorded "$ON/records/owner-ledger" 0 \
  "$ON/owner-ledger.txt" "$ON/owner-ledger.stderr.raw" \
  /bin/bash -c '
    LC_ALL=C /usr/bin/awk -F "\t" '\''
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
      }
    '\'' "$1"
  ' _ "$ON/owner.tsv"
```

These commands consume only `$ON/accepted.o` or `$ON/owner.tsv`; pass no
coverage variable; and invoke neither `z_llvm` nor `llvm-extract`.

Compare every fixed successful-subset artifact to both references:

```bash
for relative in \
  accepted.o object.stderr.raw owner.tsv owner.stderr.raw \
  accepted.objdump objdump.stderr.raw sections.readelf sections.stderr.raw \
  symbols.readelf symbols.stderr.raw text.bin objcopy.stdout.raw \
  objcopy.stderr.raw functions.sorted.tsv per-function-identities.tsv \
  owner-ledger.txt
do
  label=${relative//[^A-Za-z0-9]/-}
  run_recorded "$ON/records/cmp-canonical-$label" 0 \
    "$ON/cmp-canonical-$label.stdout" \
    "$ON/cmp-canonical-$label.stderr" \
    /usr/bin/cmp "$CANONICAL/$relative" "$ON/$relative"
  run_recorded "$ON/records/cmp-off-$label" 0 \
    "$ON/cmp-off-$label.stdout" \
    "$ON/cmp-off-$label.stderr" \
    /usr/bin/cmp "$OFF/$relative" "$ON/$relative"
done

while IFS=$'\t' read -r id function_name size_dec value_hex code_sha dis_sha
do
  run_recorded "$ON/records/cmp-canonical-$id-code" 0 \
    "$ON/cmp-canonical-$id-code.stdout" \
    "$ON/cmp-canonical-$id-code.stderr" \
    /usr/bin/cmp "$CANONICAL/functions/$id.code.bin" \
    "$ON/functions/$id.code.bin"
  run_recorded "$ON/records/cmp-off-$id-code" 0 \
    "$ON/cmp-off-$id-code.stdout" \
    "$ON/cmp-off-$id-code.stderr" \
    /usr/bin/cmp "$OFF/functions/$id.code.bin" \
    "$ON/functions/$id.code.bin"
  run_recorded "$ON/records/cmp-canonical-$id-objdump" 0 \
    "$ON/cmp-canonical-$id-objdump.stdout" \
    "$ON/cmp-canonical-$id-objdump.stderr" \
    /usr/bin/cmp "$CANONICAL/functions/$id.objdump" \
    "$ON/functions/$id.objdump"
  run_recorded "$ON/records/cmp-off-$id-objdump" 0 \
    "$ON/cmp-off-$id-objdump.stdout" \
    "$ON/cmp-off-$id-objdump.stderr" \
    /usr/bin/cmp "$OFF/functions/$id.objdump" \
    "$ON/functions/$id.objdump"
done <"$CANONICAL/per-function-identities.tsv"

for status_name in \
  object owner objdump readelf-sections readelf-symbols objcopy-text \
  functions-sorted per-function owner-ledger
do
  run_recorded "$ON/records/cmp-canonical-$status_name-status" 0 \
    "$ON/cmp-canonical-$status_name-status.stdout" \
    "$ON/cmp-canonical-$status_name-status.stderr" \
    /usr/bin/cmp "$CANONICAL/$status_name.status" \
    "$ON/records/$status_name.status"
  run_recorded "$ON/records/cmp-off-$status_name-status" 0 \
    "$ON/cmp-off-$status_name-status.stdout" \
    "$ON/cmp-off-$status_name-status.stderr" \
    /usr/bin/cmp "$OFF/records/$status_name.status" \
    "$ON/records/$status_name.status"
done
```

The loop must consume every canonical manifest row exactly once. The only
per-function filenames are the six-digit IDs generated from those rows,
each with `.code.bin`, `.objdump`, and empty `.objdump.stderr` companions.
There must be no missing, extra, or duplicate per-function output.

Finally recheck the sole canonical accepted input:

```bash
test ! -e "$ON/accepted.ll"
test "$(/usr/bin/stat -c '%a' "$CANONICAL_ACCEPTED")" = 444
printf 'path\tbytes\tmode\tsha256\n%s\t%s\t0444\t%s\n' \
  "$CANONICAL_ACCEPTED" \
  "$(/usr/bin/stat -c '%s' "$CANONICAL_ACCEPTED")" \
  "$(/usr/bin/sha256sum "$CANONICAL_ACCEPTED" |
    /usr/bin/awk '{print $1}')" \
  >"$ROOT/coverage/reference/canonical-accepted.after-on.tsv"
/usr/bin/cmp "$ROOT/coverage/reference/canonical-accepted.before.tsv" \
  "$ROOT/coverage/reference/canonical-accepted.after-on.tsv"
printf '0\n' \
  >"$ROOT/coverage/reference/canonical-accepted.after-on.cmp.status"
```

### 9.7 Exact counter checks

The report counter is a raw-report observation. Validate it with:

```bash
run_recorded "$ON/records/validate-report-counters" 0 \
  "$ON/validate-report-counters.stdout" \
  "$ON/validate-report-counters.stderr" \
  /bin/bash -c '
    /usr/bin/awk -F "\t" '\''
      $1 == "schema" {
        if ($2 != "o2_calls_crt_v1_coverage_v1") exit 101;
        schema += 1
      }
      NF == 8 && ($1 == "direct_call" ||
                  $1 == "int_byte_size_call") {
        family[$1] += 1;
        for (i = 2; i <= 8; i++) if (($i + 0) <= 0) exit 102;
      }
      $1 == "unexpected_family_events" {
        if (($2 + 0) != 0) exit 103; unexpected += 1
      }
      $1 == "argument_index_overflow_events" {
        if (($2 + 0) != 0) exit 104; overflow += 1
      }
      END {
        if (schema != 1 || family["direct_call"] != 1 ||
            family["int_byte_size_call"] != 1 ||
            unexpected != 1 || overflow != 1) exit 105
      }
    '\'' "$1"
  ' _ "$REPORT_CHANNEL"
```

This requires every family lifecycle boundary nonzero, but deliberately
does not require transaction/success equality because report-all continues
after failing functions.

Object and owner consume only canonical successful functions. Validate each
with the same exact successful-subset checker:

```bash
for channel in "$OBJECT_CHANNEL" "$OWNER_CHANNEL"; do
  channel_label=${channel##*/}
  channel_label=${channel_label%.coverage.tsv}
  run_recorded "$ON/records/validate-$channel_label-counters" 0 \
    "$ON/validate-$channel_label-counters.stdout" \
    "$ON/validate-$channel_label-counters.stderr" \
    /bin/bash -c '
      /usr/bin/awk -F "\t" '\''
        $1 == "schema" {
          if ($2 != "o2_calls_crt_v1_coverage_v1") exit 111;
          schema += 1
        }
        NF == 8 && ($1 == "direct_call" ||
                    $1 == "int_byte_size_call") {
          name = $1;
          family[name] += 1;
          transactions[name] = $2 + 0;
          requests[name] = $3 + 0;
          attachments[name] = $4 + 0;
          stages[name] = $5 + 0;
          materializations[name] = $6 + 0;
          actions[name] = $7 + 0;
          commits[name] = $8 + 0;
        }
        NF == 4 && ($1 == "direct_call" ||
                    $1 == "int_byte_size_call") {
          name = $1; position = $2 + 0;
          if (position < 0 || position > 5) exit 112;
          position_rows[name, position] += 1;
          position_requests[name, position] = $3 + 0;
          position_stages[name, position] = $4 + 0;
        }
        $1 == "unexpected_family_events" {
          if (($2 + 0) != 0) exit 113; unexpected += 1
        }
        $1 == "argument_index_overflow_events" {
          if (($2 + 0) != 0) exit 114; overflow += 1
        }
        END {
          if (schema != 1 || unexpected != 1 || overflow != 1) exit 115;
          for (f = 1; f <= 2; f++) {
            name = (f == 1 ? "direct_call" : "int_byte_size_call");
            if (family[name] != 1 || transactions[name] <= 0) exit 116;
            if (transactions[name] != attachments[name] ||
                transactions[name] != materializations[name] ||
                transactions[name] != actions[name] ||
                transactions[name] != commits[name]) exit 117;
            if (requests[name] != stages[name]) exit 118;
            for (p = 0; p <= 5; p++) {
              if (position_rows[name, p] != 1) exit 119;
              if (position_requests[name, p] !=
                  position_stages[name, p]) exit 120;
            }
          }
          if (requests["direct_call"] <= 0 ||
              stages["direct_call"] <= 0) exit 121;
          if (requests["int_byte_size_call"] !=
              transactions["int_byte_size_call"]) exit 122;
          if (position_requests["int_byte_size_call", 0] !=
              transactions["int_byte_size_call"]) exit 123;
          for (p = 1; p <= 5; p++) {
            if (position_requests["int_byte_size_call", p] != 0)
              exit 124;
          }
        }
      '\'' "$1"
    ' _ "$channel"
done

run_recorded "$ON/records/cmp-object-owner-counters" 0 \
  "$ON/cmp-object-owner-counters.stdout" \
  "$ON/cmp-object-owner-counters.stderr" \
  /usr/bin/cmp "$OBJECT_CHANNEL" "$OWNER_CHANNEL"
```

The counter TSVs are evidence only; they are never compared to or included
in canonical semantic identity hashes.

### 9.8 Produced-versus-referenced closure and final records

Observation off references:

```text
RAW_INPUT for report
CANONICAL_ACCEPTED for object and owner
CANONICAL report/object/owner/objdump/readelf/per-function/frontier outputs
COVERAGE_ARTIFACT
```

It newly produces only its command records, raw report and parsings,
object/owner outputs, object inspections, per-function files, ledgers,
comparisons, and final manifest under `OFF`. It produces no channel file and
no successful-subset input.

Observation on references the same four sets. It additionally produces
exactly the three exclusive channel files and nothing else outside `ON`.
`REPORT_CHANNEL` is produced only by the raw-input report command;
`OBJECT_CHANNEL` only by the canonical-subset object command; and
`OWNER_CHANNEL` only by the canonical-subset owner command.

After all comparisons:

```bash
test -f "$REPORT_CHANNEL"
test -f "$OBJECT_CHANNEL"
test -f "$OWNER_CHANNEL"
test ! -e "$OFF/accepted.ll"
test ! -e "$ON/accepted.ll"

shopt -s globstar nullglob
off_paths=("$OFF"/**)
for path in "${off_paths[@]}"; do
  test -f "$path" && test ! -L "$path" || continue
  /usr/bin/sha256sum "$path"
done |
  LC_ALL=C /usr/bin/sort \
  >"$ROOT/coverage/observation-off.files.sha256"
on_paths=("$ON"/**)
for path in "${on_paths[@]}"; do
  test -f "$path" && test ! -L "$path" || continue
  /usr/bin/sha256sum "$path"
done |
  LC_ALL=C /usr/bin/sort \
  >"$ROOT/coverage/observation-on.files.sha256"

for path in "${off_paths[@]}"; do
  test -f "$path" && test ! -L "$path" || continue
  /usr/bin/chmod 0444 "$path"
done
for path in "${on_paths[@]}"; do
  test -f "$path" && test ! -L "$path" || continue
  /usr/bin/chmod 0444 "$path"
done

reference_paths=("$ROOT/coverage/reference"/**)
for path in "${reference_paths[@]}"; do
  test -f "$path" && test ! -L "$path" || continue
  /usr/bin/chmod 0444 "$path"
done
/usr/bin/chmod 0444 \
  "$ROOT/coverage/observation-off.files.sha256" \
  "$ROOT/coverage/observation-on.files.sha256"

{
  printf 'path\tbytes\tmode\tsha256\n'
  {
    for path in "${off_paths[@]}"; do
      test -f "$path" && test ! -L "$path" || continue
      printf '%s\t%s\t%s\t%s\n' \
        "$path" \
        "$(/usr/bin/stat -c '%s' "$path")" \
        "$(/usr/bin/stat -c '%a' "$path")" \
        "$(/usr/bin/sha256sum "$path" | /usr/bin/awk '{print $1}')"
    done
  } | LC_ALL=C /usr/bin/sort -t "$(printf '\t')" -k1,1
} >"$ROOT/coverage/observation-off.final.tsv"

{
  printf 'path\tbytes\tmode\tsha256\n'
  {
    for path in "${on_paths[@]}"; do
      test -f "$path" && test ! -L "$path" || continue
      printf '%s\t%s\t%s\t%s\n' \
        "$path" \
        "$(/usr/bin/stat -c '%s' "$path")" \
        "$(/usr/bin/stat -c '%a' "$path")" \
        "$(/usr/bin/sha256sum "$path" | /usr/bin/awk '{print $1}')"
    done
  } | LC_ALL=C /usr/bin/sort -t "$(printf '\t')" -k1,1
} >"$ROOT/coverage/observation-on.final.tsv"

/usr/bin/chmod 0444 \
  "$ROOT/coverage/observation-off.final.tsv" \
  "$ROOT/coverage/observation-on.final.tsv"
/usr/bin/sha256sum \
  "$ROOT/coverage/observation-off.final.tsv" \
  "$ROOT/coverage/observation-on.final.tsv" \
  >"$ROOT/coverage/final-manifests.sha256"
/usr/bin/chmod 0444 "$ROOT/coverage/final-manifests.sha256"
```

The two final TSVs record path, bytes, mode, and SHA-256 for every phase
file after its final mode change. They are outside the enumerated phase
roots and are then made `0444`; their hashes are frozen in the separately
mode-frozen `final-manifests.sha256`. Any extra output, channel reuse,
missing status record, changed canonical accepted input, semantic mismatch,
zero/invalid counter, or mode/hash movement is an immediate stop.

Static classifier matches, patch content, and INBOX-181 isolation remain
supporting provenance only; they cannot replace any dynamic count.

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

## 14. INBOX-187A command-closure correction record

INBOX-187A started from clean operating-document commit
`e4a8952633c101949093130b935db8503e921b68` above accepted INBOX-187
document commit `a041487eee50f86b594beeeedb2071479842c093`. The only tracked
change is this document.

The final read-only recheck observed:

```text
bundle_manifest_sha256=0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
combined_patch_sha256=7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
combined_patch_apply_check_status=0
adopted_input_sha256=9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_sha256=500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
reproduction_manifest_sha256=885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
watcher_head_index_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
source_surface_diff_from_43de59b0=empty
ratchet=131
```

All bundle payloads remain mode `0444` and the bundle root remains mode
`0555`. The correction ran no project code, build, Zig command, `z_llvm`,
report/object generation, guard/test/gate, validation, coverage,
performance, wiring, pin edit, cleanup, or credit.

```text
section_9=EXACT_COMMAND_CLOSURE_CORRECTED_PENDING_REVIEW
patch_bundle=UNCHANGED_ACCEPTED
validation=NOT_RUN
coverage=NOT_RUN
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_BEFORE_VALIDATION_EXECUTION
```
