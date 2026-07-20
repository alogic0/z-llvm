# INBOX-187 — compiler-rt v1 baseline-validation execution contract

Status: **v3 source-commit identity/namespace correction pending
Watcher/Reviewer acceptance; v3 execution not authorized or performed**.

This document defines the proposed future ratchet-131 baseline-validation
procedure.
It deliberately separates canonical identity creation from temporary call
coverage. No command in the future procedure was executed in INBOX-187.
Production remains dormant and the bypass ratchet remains **131**.

INBOX-187A corrected section 9, but closed-contract acceptance was withheld
because successful-subset checks preceded their producers and canonical
status production remained implicit. INBOX-187B, authorized from operating
commit `1d996a1abddfc584bcad2b747705fca7f6a3642d`, corrects only this
document. Closed-contract acceptance of INBOX-187B commit
`22da533a8b7ee5596671beb91dd4f5575e5708b9` was withheld because its
canonical owner-ledger left the report-summary argument unbound inside
AWK. INBOX-187C, authorized from clean operating commit
`d34fd6dee198f5f8e823b2d8b842d4d142b221a8`, closes only that
argument-binding class and records the complete static invocation audit. It
does not change or execute the accepted patch bundle, validation protocol,
compiler, or any retained artifact.

INBOX-188 then executed the v1 contract once. Its first C01 assertion
failed closed because the sanitized environment exposed a preexisting
untracked tooling path, and static inspection found the unreached
double-evaluation defect that corrupts the AWK `$1` programs. INBOX-189,
authorized from clean operating commit
`b7eaafa7230bc4d2b6305f99fbbcac757258a067`, preserves that exhausted v1
attempt byte for byte and defines a wholly disjoint v2 namespace. No v1
command, record, root, or external record prefix may be rerun, repaired,
renamed, normalized, or reused.

INBOX-190 executed the accepted v2 contract once. Its external preflight
passed and it created one clean detached source worktree, then the first
canonical source-preflight assertion failed because the command compared a
full 40-character `git rev-parse HEAD` result with the short literal
`43de59b0`. The entire v2 namespace and its registered detached worktree are
now immutable exhausted evidence. INBOX-191 defines a fresh v3 namespace
and binds the full source commit once in each complete future executable
stream. Neither v1 nor v2 may be a future command input, output, restoration
target, or generated-ledger path.

## 1. Accepted basis and current preflight

The tracked authorization and source basis are:

```text
original_INBOX_187_operating_head=d7b11c97f43ccb5566f56a396501169f1334a15d
original_INBOX_187_operating_tree=b065779d17e5726dd81bc6b3c19bedf61a74b942
INBOX_187_document_commit=a041487eee50f86b594beeeedb2071479842c093
INBOX_187A_document_commit=527340b6
INBOX_187B_operating_commit=1d996a1abddfc584bcad2b747705fca7f6a3642d
INBOX_187B_document_commit=22da533a8b7ee5596671beb91dd4f5575e5708b9
INBOX_187C_operating_commit=d34fd6dee198f5f8e823b2d8b842d4d142b221a8
INBOX_187C_document_commit=8411478a
INBOX_188_operating_commit=d0c1d262
INBOX_188_compliant_stop_commit=59d9cb335f37fdb1df07bb25769a551760c4207a
INBOX_188_summary_sha256=802990e44f4a283a0d2bc95568b1602dfa108d97e1c13c36d792fca0d6002c24
INBOX_189_operating_commit=b7eaafa7230bc4d2b6305f99fbbcac757258a067
INBOX_190_operating_commit=a4c9d020ec869d808cb12213c1229c159f9bd374
INBOX_190_compliant_stop_commit=49bbb9d0bb7d0fb70e0654eddbacae0fd58ddd0c
INBOX_190_summary_sha256=5cf4b9bb2ba4d4ada1f00aca07e083e5ca7624a7e803addbc0e560f7b1bd2e57
INBOX_191_operating_commit=85386b77acfc915f7de4b3efd8f19dab89907a77
exact_dormant_ratchet_131_source_commit=43de59b06ca3a687368bfaf0595c5759c8ab3a57
INBOX_184_contract_commit=1c343ec8
INBOX_185_reproduction_commit=b1567ace
INBOX_186_adoption_commit=43de59b0
ratchet=131
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
```

`git diff 43de59b06ca3a687368bfaf0595c5759c8ab3a57 d7b11c97 -- src build.zig build.zig.zon tools scripts
docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
docs/evidence/inbox128_o2_r1_facade_manifest.tsv` is empty. Thus
`43de59b06ca3a687368bfaf0595c5759c8ab3a57` is the exact code/build/tool
baseline and the later commits are operating documentation only.

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
`43de59b06ca3a687368bfaf0595c5759c8ab3a57`, with no aggregate consumer
patch, observer patch, guard patch, or other temporary source. Exactly three
non-timing repetitions from that one immutable artifact define all
`o2_calls_crt_v1_r131_*` identities.

Only these three repetitions may define the canonical identities. Historical
`49a19f04...`, `061a64e4...`, and `5d91960e...` are reference-only even if a
new byte hash happens to equal one of them.

### 2.2 Coverage-only artifact

The coverage artifact is built separately from
`43de59b06ca3a687368bfaf0595c5759c8ab3a57` plus the frozen
aggregate-consumer/observer/guard bundle in section 3. It exists only to
prove dynamic execution of:

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
| 1 | aggregate consumer | `patches/01-aggregate-consumer.patch` | `8b5750fa6aa0f8811da3585614fd3386739d11d8f65896fa6eaf6a8a89b47a66` | 8,681 | clean `43de59b06ca3a687368bfaf0595c5759c8ab3a57` |
| 2 | fixed observer | `patches/02-fixed-observer.patch` | `db05812e28dee0ed3f30f56df82e5fde8f531b1dd2ae8bf0ca66521ae78e6a67` | 14,274 | result of order 1 |
| 3 | exact aggregate guard | `patches/03-exact-combined-guard.patch` | `9263f132b7bc30d6c17c26c58f61c8cfe9874ee0abdc453d730951130f089e3e` | 21,068 | result of order 2 |

The independently applicable combined patch is:

```text
patches/aggregate-consumer-observer-guard.patch
sha256=7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
bytes=41140
apply_base=clean 43de59b06ca3a687368bfaf0595c5759c8ab3a57
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
ROOT=$REPO/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
SOURCE_COMMIT=<bound and validated once per complete stream>
TARGET=x86_64-linux
INPUT_LIMIT=67108864
```

`$ROOT`, `$PARENT/baseline_validation_v3.preflight.*`, and
`$PARENT/baseline_validation_v3.driver.*` must all be absent. The exact
adopted input and all section-1 surfaces must pass again before `$ROOT` is
created. The future tool hashes must equal
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

### 4.1 V3 namespace and exhausted-v1/v2 separation

The future generated namespace is closed to these two prefixes:

```text
/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3.{preflight,driver}
```

Every future canonical root, coverage root, status, manifest, comparison,
record, and generated-ledger path in sections 5–12 is beneath one of those
prefixes. The root/prefix absence checks execute before any producer. No
future executable command or generated-ledger entry names
`baseline_validation_v1` or `baseline_validation_v2`, follows a symlink into
either exhausted namespace, or accepts a generated-path parameter outside
the closed v3 variables. Outside this separation statement, v1 and v2 paths
occur only in the immutable historical ledgers in sections 15.1 and 17;
they are review inputs, never command inputs, outputs, restoration targets,
or provenance sources.

The tracked-cleanliness portion of C01 uses only the exact expected tracked
`HEAD`, the worktree diff, the cached diff,
`status --porcelain --untracked-files=no`, and the frozen tracked-source
manifest. It does not enumerate, whitelist, read, hash, consume, modify, or
grant an exception for `.claude` or any other untracked workspace path.
The separately named adopted input and read-only bundle remain immutable
contract inputs, not cleanliness exceptions.

## 5. One exact canonical Bash driver

Sections 5–7 are one ordered `/bin/bash --noprofile --norc` driver. The
code block below is the complete driver; no line may be omitted, reordered,
or run interactively. Its working directory is `/home/oleg/prog/z_llvm`.
The invoking shell has no inherited environment beyond the seven entries
shown here:

```bash
(
  cd /home/oleg/prog/z_llvm
  exec /usr/bin/env -i \
    HOME=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1 \
    TMPDIR=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1 \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /bin/bash --noprofile --norc -s -- \
    __BASELINE_VALIDATION_V3_AUTHORIZED_HEAD__
)
```

The driver block is supplied exactly once on that shell's standard input.
The final launcher argument is the single closed future-authorization
binding. A later v3 execution authorization must replace that token with
its exact 40-lowercase-hex tracked operating `HEAD`; no command is
authorized while the token remains. The driver accepts exactly that one
argument and C01 compares it to `git rev-parse HEAD`.
The already pinned parent is used only for the driver shell's `HOME` and
`TMPDIR`; every build and workload command still receives its separately
empty phase directories. The driver begins in strict mode and never uses
`|| true`.

The driver uses one status writer. `write_status_once` requires the status
path to be absent, enables `noclobber`, and issues one Bash-builtin `printf`
write. Thus no command can overwrite, append to, or partially reuse a
status. `run_step` disables immediate exit only around its one producer,
captures `$?` in the immediately following statement, restores strict mode,
atomically creates the sole status, and validates the exact expected value
before returning. Every pipeline executes with `pipefail` already active;
no expected-nonzero producer is placed in a pipeline.

```bash
set -euo pipefail
umask 022

test "$#" -eq 1
readonly EXPECTED_MAIN_HEAD="$1"
shift
test "$#" -eq 0
test "${#EXPECTED_MAIN_HEAD}" -eq 40
test -z "${EXPECTED_MAIN_HEAD//[0-9a-f]/}"

readonly REPO=/home/oleg/prog/z_llvm
readonly PARENT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1
readonly INPUT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
readonly BUNDLE=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/inbox187_baseline_validation_contract_bundle
readonly ROOT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
readonly CANONICAL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/canonical
readonly ARTIFACT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/canonical/artifact/z_llvm
readonly ACCEPTED=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/canonical/repetition-1/accepted.ll
readonly DRIVER_RECORD=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3.driver
readonly SOURCE_COMMIT=43de59b06ca3a687368bfaf0595c5759c8ab3a57
readonly TRACKED_SOURCE_MANIFEST="$BUNDLE/manifests/baseline-source.sha256"
readonly PATH_VALUE=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin
test "${#SOURCE_COMMIT}" -eq 40
test -z "${SOURCE_COMMIT//[0-9a-f]/}"

write_status_once() {
  local status_path="$1"
  local status_value="$2"
  local status_text
  test ! -e "$status_path"
  printf -v status_text '%s\n' "$status_value"
  (
    set -o noclobber
    printf '%s' "$status_text" >"$status_path"
  )
}

run_step() {
  local record_prefix="$1"
  local status_path="$2"
  local expected_status="$3"
  local stdout_path="$4"
  local stderr_path="$5"
  local command_status
  shift 5

  test ! -e "${record_prefix}.command.txt"
  test ! -e "${record_prefix}.environment.txt"
  test ! -e "${record_prefix}.cwd.txt"
  test ! -e "${record_prefix}.start.utc"
  test ! -e "${record_prefix}.end.utc"
  test ! -e "${record_prefix}.records.tsv"
  test ! -e "$status_path"
  test ! -e "$stdout_path"
  test ! -e "$stderr_path"

  printf '%q ' "$@" >"${record_prefix}.command.txt"
  printf '\n' >>"${record_prefix}.command.txt"
  /usr/bin/env | LC_ALL=C /usr/bin/sort \
    >"${record_prefix}.environment.txt"
  pwd -P >"${record_prefix}.cwd.txt"
  printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"${record_prefix}.start.utc"

  set +e
  "$@" >"$stdout_path" 2>"$stderr_path"
  command_status=$?
  set -e

  write_status_once "$status_path" "$command_status"
  printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"${record_prefix}.end.utc"
  test "$command_status" -eq "$expected_status"

  /usr/bin/chmod 0444 \
    "${record_prefix}.command.txt" \
    "${record_prefix}.environment.txt" \
    "${record_prefix}.cwd.txt" \
    "${record_prefix}.start.utc" \
    "${record_prefix}.end.utc" \
    "$status_path" "$stdout_path" "$stderr_path"
  {
    printf 'path\tbytes\tmode\tsha256\n'
    for record_path in \
      "${record_prefix}.command.txt" \
      "${record_prefix}.environment.txt" \
      "${record_prefix}.cwd.txt" \
      "${record_prefix}.start.utc" \
      "${record_prefix}.end.utc" \
      "$status_path" "$stdout_path" "$stderr_path"
    do
      printf '%s\t%s\t%s\t%s\n' \
        "$record_path" \
        "$(/usr/bin/stat -c '%s' "$record_path")" \
        "$(/usr/bin/stat -c '%a' "$record_path")" \
        "$(/usr/bin/sha256sum "$record_path" |
          /usr/bin/awk '{print $1}')"
    done
  } >"${record_prefix}.records.tsv"
  /usr/bin/chmod 0444 "${record_prefix}.records.tsv"
}

test "$PWD" = "$REPO"
test ! -e "$ROOT"
readonly PREFLIGHT_RECORD="$PARENT/baseline_validation_v3.preflight"
for suffix in \
  command.txt environment.txt cwd.txt start.utc end.utc \
  stdout.raw stderr.raw status records.tsv
do
  test ! -e "$PREFLIGHT_RECORD.$suffix"
done

/usr/bin/env | LC_ALL=C /usr/bin/sort \
  >"$PREFLIGHT_RECORD.environment.txt"
pwd -P >"$PREFLIGHT_RECORD.cwd.txt"
printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 \
  >"$PREFLIGHT_RECORD.start.utc"
preflight_command=(
  /bin/bash -c '
  set -euo pipefail
  repo="$1"
  input="$2"
  bundle="$3"
  expected_main_head="$4"
  tracked_source_manifest="$5"
  source_commit="$6"

  test "$(/usr/bin/git -C "$repo" rev-parse HEAD)" = \
    "$expected_main_head"
  /usr/bin/git -C "$repo" diff --quiet --exit-code
  /usr/bin/git -C "$repo" diff --cached --quiet --exit-code
  test -z "$(/usr/bin/git -C "$repo" status --porcelain \
    --untracked-files=no)"
  test -f "$tracked_source_manifest"
  test ! -L "$tracked_source_manifest"
  (
    cd "$repo"
    /usr/bin/sha256sum -c "$tracked_source_manifest"
  )
  test -f "$input"
  test ! -L "$input"
  test "$(/usr/bin/stat -c "%a" "$input")" = 444
  test "$(/usr/bin/stat -c "%s" "$input")" = 1897410
  test "$(/usr/bin/sha256sum "$input" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
  test "$(/usr/bin/stat -c "%a" \
    "$repo/tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv")" = 444
  test "$(/usr/bin/stat -c "%s" \
    "$repo/tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv")" = 4394
  test "$(/usr/bin/sha256sum \
    "$repo/tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
  test -d "$bundle"
  test ! -L "$bundle"
  test "$(/usr/bin/stat -c "%a" "$bundle")" = 555
  test "$(/usr/bin/stat -c "%a" \
    "$bundle/manifests/bundle-files.sha256")" = 444
  test "$(/usr/bin/stat -c "%s" \
    "$bundle/manifests/bundle-files.sha256")" = 2519
  test "$(/usr/bin/sha256sum \
    "$bundle/manifests/bundle-files.sha256" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
  test "$(/usr/bin/stat -c "%a" \
    "$bundle/patches/aggregate-consumer-observer-guard.patch")" = 444
  test "$(/usr/bin/stat -c "%s" \
    "$bundle/patches/aggregate-consumer-observer-guard.patch")" = 41140
  test "$(/usr/bin/sha256sum \
    "$bundle/patches/aggregate-consumer-observer-guard.patch" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
  (
    cd "$repo"
    /usr/bin/sha256sum -c \
      "$bundle/manifests/bundle-files.sha256"
  )
  while IFS="$(printf "\t")" read -r payload_path \
    payload_bytes payload_mode
  do
    test "$(/usr/bin/stat -c "%s" "$repo/$payload_path")" = \
      "$payload_bytes"
    test "$(/usr/bin/stat -c "%a" "$repo/$payload_path")" = \
      "${payload_mode#0}"
  done <"$bundle/manifests/payload-final-modes.tsv"
  test "$(/usr/bin/stat -c "%a" \
    "$repo/tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/retained-files-final.tsv")" = 664
  test "$(/usr/bin/stat -c "%s" \
    "$repo/tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/retained-files-final.tsv")" = 458294
  test "$(/usr/bin/sha256sum \
    "$repo/tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/retained-files-final.tsv" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
  test "$(/usr/bin/stat -c "%a" \
    "$repo/docs/evidence/tmp_retention_pins.tsv")" = 664
  test "$(/usr/bin/stat -c "%s" \
    "$repo/docs/evidence/tmp_retention_pins.tsv")" = 3051
  test "$(/usr/bin/sha256sum \
    "$repo/docs/evidence/tmp_retention_pins.tsv" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
  test "$(/usr/bin/stat -c "%a" \
    "$repo/docs/retention_headroom_policy.md")" = 664
  test "$(/usr/bin/stat -c "%s" \
    "$repo/docs/retention_headroom_policy.md")" = 10622
  test "$(/usr/bin/sha256sum \
    "$repo/docs/retention_headroom_policy.md" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd
  test "$(/usr/bin/stat -c "%a" "$repo/tools/clean_tmp.zig")" = 664
  test "$(/usr/bin/stat -c "%s" "$repo/tools/clean_tmp.zig")" = 50100
  test "$(/usr/bin/sha256sum "$repo/tools/clean_tmp.zig" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e
  test "$(/usr/bin/stat -c "%a" \
    "$repo/scripts/z_llvm_watcher_loop.sh")" = 775
  test "$(/usr/bin/stat -c "%s" \
    "$repo/scripts/z_llvm_watcher_loop.sh")" = 10850
  test "$(/usr/bin/git -C "$repo" hash-object \
    scripts/z_llvm_watcher_loop.sh)" = \
    b64131cf60dd0ef638e815cd33db9ae8595a72cf
  test "$(/usr/bin/git -C "$repo" rev-parse \
    :scripts/z_llvm_watcher_loop.sh)" = \
    b64131cf60dd0ef638e815cd33db9ae8595a72cf
  test "$(/usr/bin/git -C "$repo" rev-parse \
    HEAD:scripts/z_llvm_watcher_loop.sh)" = \
    b64131cf60dd0ef638e815cd33db9ae8595a72cf
  test "$(/usr/bin/git -C "$repo" stash list \
    --format="%H" |
    /usr/bin/awk '\''NR == 1 { print; exit }'\'')" = \
    7985c6d01040a6e47e4ce5b918866d0e89517ac7
  test "$(/usr/bin/stat -c "%a" \
    "$repo/docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv")" = 664
  test "$(/usr/bin/stat -c "%s" \
    "$repo/docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv")" = 5188
  test "$(/usr/bin/sha256sum \
    "$repo/docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
  test "$(/usr/bin/stat -c "%a" \
    "$repo/docs/evidence/inbox128_o2_r1_facade_manifest.tsv")" = 664
  test "$(/usr/bin/stat -c "%s" \
    "$repo/docs/evidence/inbox128_o2_r1_facade_manifest.tsv")" = 2686
  test "$(/usr/bin/sha256sum \
    "$repo/docs/evidence/inbox128_o2_r1_facade_manifest.tsv" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26
  test "$(/usr/bin/stat -c "%a" \
    "$repo/src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig")" = 664
  test "$(/usr/bin/stat -c "%s" \
    "$repo/src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig")" = 103
  test "$(/usr/bin/sha256sum \
    "$repo/src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig" |
    /usr/bin/awk '\''{print $1}'\'')" = \
    4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a
  test "$(/usr/bin/git -C /home/oleg/prog/ziglang rev-parse HEAD)" = \
    bdee02bc0c7f227c0f11bc9a449df673fe803540
  test "$(/usr/bin/git -C /home/oleg/prog/ziglang rev-parse HEAD^{tree})" = \
    aa032b2b82a48a4684657f909e6e270a6c925e33
  test "$(/usr/bin/stat -c "%a" \
    /home/oleg/prog/ziglang/build/stage4/bin/zig)" = 775
  test "$(/usr/bin/stat -c "%s" \
    /home/oleg/prog/ziglang/build/stage4/bin/zig)" = 530327885
  test "$(/usr/bin/sha256sum \
    /home/oleg/prog/ziglang/build/stage4/bin/zig |
    /usr/bin/awk '\''{print $1}'\'')" = \
    dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7
  while IFS="  " read -r expected tool_path; do
    test -n "$expected"
    test -n "$tool_path"
    test "$(/usr/bin/sha256sum "$tool_path" |
      /usr/bin/awk '\''{print $1}'\'')" = "$expected"
  done <"$bundle/manifests/future-tool-identities.sha256"
  /usr/bin/git -C "$repo" diff --quiet "$source_commit" -- \
    src build.zig build.zig.zon tools scripts \
    docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv \
    docs/evidence/inbox128_o2_r1_facade_manifest.tsv
  /usr/bin/git -C "$repo" apply --check \
    "$bundle/patches/aggregate-consumer-observer-guard.patch"
  available_blocks=$(/usr/bin/stat -f -c "%a" "$repo")
  block_size=$(/usr/bin/stat -f -c "%S" "$repo")
  test "$((available_blocks * block_size))" -ge 17179869184
  printf "preflight=pass\nroot_absent=1\n"
  ' _ "$REPO" "$INPUT" "$BUNDLE" "$EXPECTED_MAIN_HEAD" \
  "$TRACKED_SOURCE_MANIFEST" "$SOURCE_COMMIT"
)
printf '%q ' "${preflight_command[@]}" \
  >"$PREFLIGHT_RECORD.command.txt"
printf '\n' >>"$PREFLIGHT_RECORD.command.txt"
set +e
"${preflight_command[@]}" \
  >"$PREFLIGHT_RECORD.stdout.raw" \
  2>"$PREFLIGHT_RECORD.stderr.raw"
preflight_status=$?
set -e
write_status_once "$PREFLIGHT_RECORD.status" "$preflight_status"
printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 \
  >"$PREFLIGHT_RECORD.end.utc"
test "$preflight_status" -eq 0
/usr/bin/chmod 0444 \
  "$PREFLIGHT_RECORD.command.txt" \
  "$PREFLIGHT_RECORD.environment.txt" \
  "$PREFLIGHT_RECORD.cwd.txt" \
  "$PREFLIGHT_RECORD.start.utc" \
  "$PREFLIGHT_RECORD.end.utc" \
  "$PREFLIGHT_RECORD.status" \
  "$PREFLIGHT_RECORD.stdout.raw" \
  "$PREFLIGHT_RECORD.stderr.raw"
{
  printf 'path\tbytes\tmode\tsha256\n'
  for record_path in \
    "$PREFLIGHT_RECORD.command.txt" \
    "$PREFLIGHT_RECORD.environment.txt" \
    "$PREFLIGHT_RECORD.cwd.txt" \
    "$PREFLIGHT_RECORD.start.utc" \
    "$PREFLIGHT_RECORD.end.utc" \
    "$PREFLIGHT_RECORD.status" \
    "$PREFLIGHT_RECORD.stdout.raw" \
    "$PREFLIGHT_RECORD.stderr.raw"
  do
    printf '%s\t%s\t%s\t%s\n' \
      "$record_path" \
      "$(/usr/bin/stat -c '%s' "$record_path")" \
      "$(/usr/bin/stat -c '%a' "$record_path")" \
      "$(/usr/bin/sha256sum "$record_path" |
        /usr/bin/awk '{print $1}')"
  done
} >"$PREFLIGHT_RECORD.records.tsv"
/usr/bin/chmod 0444 "$PREFLIGHT_RECORD.records.tsv"

for suffix in \
  command.txt environment.txt cwd.txt start.utc end.utc \
  stdout.raw stderr.raw status records.tsv
do
  test ! -e "$DRIVER_RECORD.$suffix"
done

/usr/bin/env | LC_ALL=C /usr/bin/sort \
  >"$DRIVER_RECORD.environment.txt"
pwd -P >"$DRIVER_RECORD.cwd.txt"
printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"$DRIVER_RECORD.start.utc"
mkdir_command=(/usr/bin/mkdir -p \
  "$CANONICAL/records" \
  "$CANONICAL/manifests" \
  "$CANONICAL/comparisons" \
  "$CANONICAL/build/home" \
  "$CANONICAL/build/tmp" \
  "$CANONICAL/build/cache/local" \
  "$CANONICAL/build/cache/global" \
  "$CANONICAL/build/prefix" \
  "$CANONICAL/artifact" \
  "$CANONICAL/repetition-1/home" \
  "$CANONICAL/repetition-1/tmp" \
  "$CANONICAL/repetition-1/records" \
  "$CANONICAL/repetition-1/functions" \
  "$CANONICAL/repetition-2/home" \
  "$CANONICAL/repetition-2/tmp" \
  "$CANONICAL/repetition-2/records" \
  "$CANONICAL/repetition-2/functions" \
  "$CANONICAL/repetition-3/home" \
  "$CANONICAL/repetition-3/tmp" \
  "$CANONICAL/repetition-3/records" \
  "$CANONICAL/repetition-3/functions")
printf '%q ' "${mkdir_command[@]}" >"$DRIVER_RECORD.command.txt"
printf '\n' >>"$DRIVER_RECORD.command.txt"
set +e
"${mkdir_command[@]}" \
  >"$DRIVER_RECORD.stdout.raw" \
  2>"$DRIVER_RECORD.stderr.raw"
driver_mkdir_status=$?
set -e
write_status_once "$DRIVER_RECORD.status" "$driver_mkdir_status"
printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"$DRIVER_RECORD.end.utc"
test "$driver_mkdir_status" -eq 0
/usr/bin/chmod 0444 \
  "$DRIVER_RECORD.command.txt" \
  "$DRIVER_RECORD.environment.txt" \
  "$DRIVER_RECORD.cwd.txt" \
  "$DRIVER_RECORD.start.utc" \
  "$DRIVER_RECORD.end.utc" \
  "$DRIVER_RECORD.status" \
  "$DRIVER_RECORD.stdout.raw" \
  "$DRIVER_RECORD.stderr.raw"
{
  printf 'path\tbytes\tmode\tsha256\n'
  for record_path in \
    "$DRIVER_RECORD.command.txt" \
    "$DRIVER_RECORD.environment.txt" \
    "$DRIVER_RECORD.cwd.txt" \
    "$DRIVER_RECORD.start.utc" \
    "$DRIVER_RECORD.end.utc" \
    "$DRIVER_RECORD.status" \
    "$DRIVER_RECORD.stdout.raw" \
    "$DRIVER_RECORD.stderr.raw"
  do
    printf '%s\t%s\t%s\t%s\n' \
      "$record_path" \
      "$(/usr/bin/stat -c '%s' "$record_path")" \
      "$(/usr/bin/stat -c '%a' "$record_path")" \
      "$(/usr/bin/sha256sum "$record_path" |
        /usr/bin/awk '{print $1}')"
  done
} >"$DRIVER_RECORD.records.tsv"
/usr/bin/chmod 0444 "$DRIVER_RECORD.records.tsv"

run_step \
  "$CANONICAL/records/worktree-add" \
  "$CANONICAL/worktree-add.status" 0 \
  "$CANONICAL/records/worktree-add.stdout" \
  "$CANONICAL/records/worktree-add.stderr" \
  /usr/bin/git -C "$REPO" worktree add --detach \
  "$CANONICAL/source" "$SOURCE_COMMIT"

run_step \
  "$CANONICAL/records/source-preflight" \
  "$CANONICAL/source-preflight.status" 0 \
  "$CANONICAL/records/source-preflight.stdout" \
  "$CANONICAL/records/source-preflight.stderr" \
  /bin/bash -c '
    set -euo pipefail
    source_root="$1"
    source_commit="$2"
    test "$(/usr/bin/git -C "$source_root" rev-parse HEAD)" = \
      "$source_commit"
    test -z "$(/usr/bin/git -C "$source_root" status --porcelain)"
    /usr/bin/git -C "$source_root" rev-parse HEAD
    /usr/bin/git -C "$source_root" rev-parse HEAD^{tree}
  ' _ "$CANONICAL/source" "$SOURCE_COMMIT"

run_step \
  "$CANONICAL/records/build" \
  "$CANONICAL/build/build.status" 0 \
  "$CANONICAL/build/stdout.raw" \
  "$CANONICAL/build/stderr.raw" \
  /usr/bin/env -i \
  HOME="$CANONICAL/build/home" \
  TMPDIR="$CANONICAL/build/tmp" \
  PATH="$PATH_VALUE" \
  LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
  /bin/bash -c '
    set -euo pipefail
    cd "$1"
    exec /home/oleg/bin/zig build \
      --prefix "$2" \
      --cache-dir "$3" \
      --global-cache-dir "$4" \
      --summary all
  ' _ \
  "$CANONICAL/source" \
  "$CANONICAL/build/prefix" \
  "$CANONICAL/build/cache/local" \
  "$CANONICAL/build/cache/global"

run_step \
  "$CANONICAL/records/artifact-install" \
  "$CANONICAL/artifact-install.status" 0 \
  "$CANONICAL/records/artifact-install.stdout" \
  "$CANONICAL/records/artifact-install.stderr" \
  /usr/bin/install -D -m 0555 \
  "$CANONICAL/build/prefix/bin/z_llvm" "$ARTIFACT"

run_step \
  "$CANONICAL/records/artifact-identity" \
  "$CANONICAL/artifact-identity.status" 0 \
  "$CANONICAL/records/artifact-identity.stdout" \
  "$CANONICAL/records/artifact-identity.stderr" \
  /bin/bash -c '
    set -euo pipefail
    artifact="$1"
    output="$2"
    test -f "$artifact"
    test ! -L "$artifact"
    test "$(/usr/bin/stat -c "%a" "$artifact")" = 555
    printf "path\tbytes\tmode\tsha256\n%s\t%s\t0555\t%s\n" \
      "$artifact" \
      "$(/usr/bin/stat -c "%s" "$artifact")" \
      "$(/usr/bin/sha256sum "$artifact" |
        /usr/bin/awk "{print \\$1}")" >"$output"
  ' _ "$ARTIFACT" "$CANONICAL/artifact.identity.tsv"

for repetition in 1 2 3; do
  REP="$CANONICAL/repetition-$repetition"
  REC="$REP/records"

  run_step \
    "$REC/report" "$REP/report.status" 1 \
    "$REC/report.stdout" "$REC/report.stderr" \
    /usr/bin/env -i \
    HOME="$REP/home" TMPDIR="$REP/tmp" PATH="$PATH_VALUE" \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /bin/bash -c '
      set -euo pipefail
      artifact="$1"
      input="$2"
      semantic_stdout="$3"
      semantic_stderr="$4"
      exec "$artifact" \
        --emit=obj \
        --generic-cfg-selector \
        --report-all-codegen-failures \
        --target=x86_64-linux \
        --input-limit=67108864 \
        "$input" \
        >"$semantic_stdout" 2>"$semantic_stderr"
    ' _ "$ARTIFACT" "$INPUT" \
    "$REP/report.stdout.raw" "$REP/report.stderr.raw"

  run_step \
    "$REC/report-summary" "$REP/report-summary.status" 0 \
    "$REC/report-summary.stdout" "$REC/report-summary.stderr" \
    /bin/bash -c '
      set -euo pipefail
      /usr/bin/awk '\''
        $1 == "summary" && $2 == "zllvm-codegen-report-all" {
          print; found += 1
        }
        END { if (found != 1) exit 95 }
      '\'' "$1" >"$2"
    ' _ "$REP/report.stderr.raw" "$REP/report.summary.txt"

  run_step \
    "$REC/report-validate" "$REP/report-validate.status" 0 \
    "$REC/report-validate.stdout" "$REC/report-validate.stderr" \
    /bin/bash -c '
      set -euo pipefail
      test ! -s "$1"
      /usr/bin/awk '\''
        {
          for (i = 1; i <= NF; i++) {
            split($i, part, "=")
            value[part[1]] = part[2]
          }
        }
        END {
          selected = value["selected_functions"] + 0
          emitted = value["emitted_functions"] + 0
          failed = value["failed_functions"] + 0
          if (selected <= 0 || emitted <= 0 || failed <= 0) exit 97
          if (selected != emitted + failed) exit 98
          if (value["local_fail"] != "1") exit 99
          if (value["first_failure"] == "" ||
              value["first_failure"] == "-") exit 100
          if (value["first_diagnostic"] == "" ||
              value["first_diagnostic"] == "-") exit 101
        }
      '\'' "$2"
    ' _ "$REP/report.stdout.raw" "$REP/report.summary.txt"

  run_step \
    "$REC/failures-in-order" "$REP/failures-in-order.status" 0 \
    "$REC/failures-in-order.stdout" "$REC/failures-in-order.stderr" \
    /bin/bash -c '
      set -euo pipefail
      LC_ALL=C /usr/bin/awk '\''
        $1 == "zllvm-codegen-failure" {
          if ($2 !~ /^function=/) exit 91
          sub(/^function=/, "", $2)
          print $2
        }
      '\'' "$1" >"$2"
    ' _ "$REP/report.stderr.raw" \
    "$REP/failed-functions.in-report-order.txt"

  run_step \
    "$REC/failures-sorted" "$REP/failures-sorted.status" 0 \
    "$REC/failures-sorted.stdout" "$REC/failures-sorted.stderr" \
    /usr/bin/sort -u \
    -o "$REP/failed-functions.sorted.txt" \
    "$REP/failed-functions.in-report-order.txt"

  run_step \
    "$REC/frontier" "$REP/frontier.status" 0 \
    "$REC/frontier.stdout" "$REC/frontier.stderr" \
    /bin/bash -c '
      set -euo pipefail
      temporary="$3"
      LC_ALL=C /usr/bin/awk '\''
        $1 == "zllvm-codegen-failure" {
          function = diagnostic = selector_tag = selector_detail = ""
          for (i = 2; i <= NF; i++) {
            if ($i ~ /^function=/) {
              function = $i
              sub(/^function=/, "", function)
            } else if ($i ~ /^diagnostic=/) {
              diagnostic = $i
              sub(/^diagnostic=/, "", diagnostic)
            } else if ($i ~ /^selector_tag=/) {
              selector_tag = $i
              sub(/^selector_tag=/, "", selector_tag)
            } else if ($i ~ /^selector_detail=/) {
              selector_detail = $i
              sub(/^selector_detail=/, "", selector_detail)
            }
          }
          if (function == "" || diagnostic == "" ||
              selector_tag == "" || selector_detail == "") exit 93
          print function "\t" diagnostic "\t" selector_tag "\t" \
            selector_detail
        }
      '\'' "$1" >"$temporary"
      LC_ALL=C /usr/bin/sort -t "$(printf "\t")" -k1,1 \
        -o "$2" "$temporary"
      /usr/bin/chmod 0444 "$temporary"
    ' _ "$REP/report.stderr.raw" "$REP/frontier.tsv" \
    "$REP/frontier.unsorted.tsv"

  run_step \
    "$REC/frontier-grouped" "$REP/frontier-grouped.status" 0 \
    "$REC/frontier-grouped.stdout" "$REC/frontier-grouped.stderr" \
    /bin/bash -c '
      set -euo pipefail
      temporary="$3"
      LC_ALL=C /usr/bin/awk -F "\t" '\''
        { key = $3 "\t" $4 "\t" $2; count[key] += 1 }
        END { for (key in count) print key "\t" count[key] }
      '\'' "$1" >"$temporary"
      LC_ALL=C /usr/bin/sort -o "$2" "$temporary"
      /usr/bin/chmod 0444 "$temporary"
    ' _ "$REP/frontier.tsv" "$REP/frontier-grouped.tsv" \
    "$REP/frontier-grouped.unsorted.tsv"

  run_step \
    "$REC/report-counts-validate" \
    "$REP/report-counts-validate.status" 0 \
    "$REC/report-counts-validate.stdout" \
    "$REC/report-counts-validate.stderr" \
    /bin/bash -c '
      set -euo pipefail
      expected=$(/usr/bin/awk '\''
        {
          for (i = 1; i <= NF; i++) {
            split($i, part, "=")
            if (part[1] == "failed_functions") print part[2]
          }
        }
      '\'' "$1")
      ordered=$(/usr/bin/awk '\''END { print NR }'\'' "$2")
      unique=$(/usr/bin/awk '\''END { print NR }'\'' "$3")
      frontier=$(/usr/bin/awk '\''END { print NR }'\'' "$4")
      test "$ordered" -eq "$expected"
      test "$unique" -eq "$expected"
      test "$frontier" -eq "$expected"
      /usr/bin/awk '\''
        $0 == "" || $0 !~ /^[A-Za-z0-9_.$]+$/ { exit 102 }
      '\'' "$3"
    ' _ "$REP/report.summary.txt" \
    "$REP/failed-functions.in-report-order.txt" \
    "$REP/failed-functions.sorted.txt" "$REP/frontier.tsv"

  if test "$repetition" -eq 1; then
    run_step \
      "$REC/extract" "$REP/extract.status" 0 \
      "$REC/extract.stdout" "$REC/extract.stderr" \
      /usr/bin/env -i \
      HOME="$REP/home" TMPDIR="$REP/tmp" PATH="$PATH_VALUE" \
      LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
      /bin/bash -c '
        set -euo pipefail
        failure_file="$1"
        input="$2"
        accepted="$3"
        semantic_stdout="$4"
        semantic_stderr="$5"
        extract_args=(--delete -S -o "$accepted")
        while IFS= read -r function_name; do
          extract_args+=(--func "$function_name")
        done <"$failure_file"
        extract_args+=("$input")
        exec /usr/lib/llvm-22/bin/llvm-extract \
          "${extract_args[@]}" \
          >"$semantic_stdout" 2>"$semantic_stderr"
      ' _ "$REP/failed-functions.sorted.txt" "$INPUT" "$ACCEPTED" \
      "$REP/extract.stdout.raw" "$REP/extract.stderr.raw"

    run_step \
      "$REC/accepted-freeze" "$REP/accepted-freeze.status" 0 \
      "$REC/accepted-freeze.stdout" "$REC/accepted-freeze.stderr" \
      /bin/bash -c '
        set -euo pipefail
        accepted="$1"
        identity="$2"
        test -f "$accepted"
        test ! -L "$accepted"
        test ! -s "$3"
        test ! -s "$4"
        /usr/bin/chmod 0444 "$accepted"
        printf "path\tbytes\tmode\tsha256\n%s\t%s\t0444\t%s\n" \
          "$accepted" \
          "$(/usr/bin/stat -c "%s" "$accepted")" \
          "$(/usr/bin/sha256sum "$accepted" |
            /usr/bin/awk "{print \\$1}")" >"$identity"
      ' _ "$ACCEPTED" "$REP/accepted.identity.tsv" \
      "$REP/extract.stdout.raw" "$REP/extract.stderr.raw"
  fi

  test -f "$ACCEPTED"
  test "$(/usr/bin/stat -c '%a' "$ACCEPTED")" = 444

  run_step \
    "$REC/object" "$REP/object.status" 0 \
    "$REC/object.stdout" "$REC/object.stderr" \
    /usr/bin/env -i \
    HOME="$REP/home" TMPDIR="$REP/tmp" PATH="$PATH_VALUE" \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /bin/bash -c '
      set -euo pipefail
      exec "$1" \
        --emit=obj \
        --generic-cfg-selector \
        --target=x86_64-linux \
        --input-limit=67108864 \
        "$2" >"$3" 2>"$4"
    ' _ "$ARTIFACT" "$ACCEPTED" "$REP/accepted.o" \
    "$REP/object.stderr.raw"

  run_step \
    "$REC/owner" "$REP/owner.status" 0 \
    "$REC/owner.stdout" "$REC/owner.stderr" \
    /usr/bin/env -i \
    HOME="$REP/home" TMPDIR="$REP/tmp" PATH="$PATH_VALUE" \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /bin/bash -c '
      set -euo pipefail
      exec "$1" \
        --emit=selection-owner-manifest \
        --generic-cfg-selector \
        --target=x86_64-linux \
        --input-limit=67108864 \
        "$2" >"$3" 2>"$4"
    ' _ "$ARTIFACT" "$ACCEPTED" "$REP/owner.tsv" \
    "$REP/owner.stderr.raw"

  run_step \
    "$REC/objdump" "$REP/objdump.status" 0 \
    "$REC/objdump.stdout" "$REC/objdump.stderr" \
    /bin/bash -c '
      set -euo pipefail
      cd "$1"
      exec /usr/bin/objdump -d accepted.o >accepted.objdump \
        2>objdump.stderr.raw
    ' _ "$REP"

  run_step \
    "$REC/readelf-sections" "$REP/readelf-sections.status" 0 \
    "$REC/readelf-sections.stdout" "$REC/readelf-sections.stderr" \
    /bin/bash -c '
      set -euo pipefail
      exec /usr/bin/readelf -SW "$1" >"$2" 2>"$3"
    ' _ "$REP/accepted.o" "$REP/sections.readelf" \
    "$REP/sections.stderr.raw"

  run_step \
    "$REC/readelf-symbols" "$REP/readelf-symbols.status" 0 \
    "$REC/readelf-symbols.stdout" "$REC/readelf-symbols.stderr" \
    /bin/bash -c '
      set -euo pipefail
      exec /usr/bin/readelf -sW "$1" >"$2" 2>"$3"
    ' _ "$REP/accepted.o" "$REP/symbols.readelf" \
    "$REP/symbols.stderr.raw"

  run_step \
    "$REC/objcopy-text" "$REP/objcopy-text.status" 0 \
    "$REC/objcopy-text.stdout" "$REC/objcopy-text.stderr" \
    /bin/bash -c '
      set -euo pipefail
      exec /usr/bin/objcopy --dump-section ".text=$2" "$1" \
        >"$3" 2>"$4"
    ' _ "$REP/accepted.o" "$REP/text.bin" \
    "$REP/objcopy.stdout.raw" "$REP/objcopy.stderr.raw"

  run_step \
    "$REC/functions-sorted" "$REP/functions-sorted.status" 0 \
    "$REC/functions-sorted.stdout" "$REC/functions-sorted.stderr" \
    /bin/bash -c '
      set -euo pipefail
      temporary="$3"
      LC_ALL=C /usr/bin/awk '\''
        $4 == "FUNC" && $7 == "1" && ($3 + 0) > 0 {
          print $8 "\t" $2 "\t" $3
        }
      '\'' "$1" >"$temporary"
      LC_ALL=C /usr/bin/sort -t "$(printf "\t")" -k1,1 \
        -o "$2" "$temporary"
      /usr/bin/chmod 0444 "$temporary"
    ' _ "$REP/symbols.readelf" "$REP/functions.sorted.tsv" \
    "$REP/functions.unsorted.tsv"

  row=0
  while IFS=$'\t' read -r function_name value_hex size_dec; do
    row=$((row + 1))
    id=$(printf '%06d' "$row")
    offset=$((16#$value_hex))

    run_step \
      "$REC/function-$id-dd" "$REP/functions/$id.dd.status" 0 \
      "$REC/function-$id-dd.stdout" "$REC/function-$id-dd.stderr" \
      /usr/bin/dd if="$REP/text.bin" \
      of="$REP/functions/$id.code.bin" \
      bs=1 skip="$offset" count="$size_dec" status=none

    run_step \
      "$REC/function-$id-objdump" \
      "$REP/functions/$id.objdump.status" 0 \
      "$REC/function-$id-objdump.stdout" \
      "$REC/function-$id-objdump.stderr" \
      /bin/bash -c '
        set -euo pipefail
        cd "$1"
        exec /usr/bin/objdump -dr \
          --disassemble="$2" accepted.o \
          >"functions/$3.objdump" \
          2>"functions/$3.objdump.stderr"
      ' _ "$REP" "$function_name" "$id"

    run_step \
      "$REC/function-$id-identity" \
      "$REP/functions/$id.identity.status" 0 \
      "$REC/function-$id-identity.stdout" \
      "$REC/function-$id-identity.stderr" \
      /bin/bash -c '
        set -euo pipefail
        test ! -s "$2"
        test "$(/usr/bin/stat -c "%s" "$1")" -eq "$3"
        printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
          "$4" "$5" "$3" "$6" \
          "$(/usr/bin/sha256sum "$1" |
            /usr/bin/awk "{print \\$1}")" \
          "$(/usr/bin/sha256sum "$7" |
            /usr/bin/awk "{print \\$1}")" >"$8"
      ' _ "$REP/functions/$id.code.bin" \
      "$REP/functions/$id.objdump.stderr" "$size_dec" "$id" \
      "$function_name" "$value_hex" "$REP/functions/$id.objdump" \
      "$REP/functions/$id.identity.tsv"
  done <"$REP/functions.sorted.tsv"

  run_step \
    "$REC/per-function" "$REP/per-function.status" 0 \
    "$REC/per-function.stdout" "$REC/per-function.stderr" \
    /bin/bash -c '
      set -euo pipefail
      functions="$1"
      output="$2"
      source_manifest="$3"
      : >"$output"
      shopt -s nullglob
      rows=("$functions"/*.identity.tsv)
      expected_rows=$(/usr/bin/awk '\''END { print NR }'\'' \
        "$source_manifest")
      test "${#rows[@]}" -eq "$expected_rows"
      for row_path in "${rows[@]}"; do
        while IFS= read -r row_text; do
          printf "%s\n" "$row_text" >>"$output"
        done <"$row_path"
      done
    ' _ "$REP/functions" "$REP/per-function-identities.tsv" \
    "$REP/functions.sorted.tsv"

  run_step \
    "$REC/owner-ledger" "$REP/owner-ledger.status" 0 \
    "$REC/owner-ledger.stdout" "$REC/owner-ledger.stderr" \
    /bin/bash -c '
      set -euo pipefail
      summary="$3"
      LC_ALL=C /usr/bin/awk -F "\t" -v summary="$summary" '\''
        NR == 1 {
          if ($1 != "row_identity" ||
              $2 != "selection_owner") exit 92
          next
        }
        {
          if ($2 != "composed_block" &&
              $2 != "composed_cfg" &&
              $2 != "legacy_envelope" &&
              $2 != "structural_fallback") exit 93
          if (seen[$1] != 0) exit 94
          seen[$1] = 1
          count[$2] += 1
          total += 1
        }
        END {
          expected = 0
          while ((getline line < summary) > 0) {
            fields = split(line, values, " ")
            for (i = 1; i <= fields; i++) {
              split(values[i], part, "=")
              if (part[1] == "emitted_functions") expected = part[2] + 0
            }
          }
          if (total != expected) exit 95
          printf("composed_block=%d\n", count["composed_block"])
          printf("composed_cfg=%d\n", count["composed_cfg"])
          printf("legacy_envelope=%d\n", count["legacy_envelope"])
          printf("structural_fallback=%d\n",
            count["structural_fallback"])
          printf("ledger=%d/%d/%d\n",
            count["composed_block"] + count["composed_cfg"],
            count["legacy_envelope"],
            count["structural_fallback"])
          printf("total=%d\n", total)
        }
      '\'' "$1" >"$2"
    ' _ "$REP/owner.tsv" "$REP/owner-ledger.txt" \
    "$REP/report.summary.txt"
done
```

There is exactly one extraction invocation: repetition 1 produces
`$ACCEPTED`, freezes it mode `0444`, and records its identity before any
object consumer. Repetitions 2 and 3 never create an `accepted.ll`; all
three object and owner commands consume the same absolute `$ACCEPTED`.

## 6. Exact equality, statuses, and canonical identities

Continue the same driver, without resetting shell state:

```bash
readonly BASE="$CANONICAL/repetition-1"

for repetition in 2 3; do
  REP="$CANONICAL/repetition-$repetition"
  for relative in \
    report.stdout.raw report.stderr.raw report.status \
    report.summary.txt report-summary.status report-validate.status \
    report-counts-validate.status \
    failed-functions.in-report-order.txt failures-in-order.status \
    failed-functions.sorted.txt failures-sorted.status \
    frontier.unsorted.tsv frontier.tsv frontier.status \
    frontier-grouped.unsorted.tsv frontier-grouped.tsv \
    frontier-grouped.status \
    accepted.o object.stderr.raw object.status \
    owner.tsv owner.stderr.raw owner.status \
    accepted.objdump objdump.stderr.raw objdump.status \
    sections.readelf sections.stderr.raw readelf-sections.status \
    symbols.readelf symbols.stderr.raw readelf-symbols.status \
    text.bin objcopy.stdout.raw objcopy.stderr.raw objcopy-text.status \
    functions.unsorted.tsv functions.sorted.tsv functions-sorted.status \
    per-function-identities.tsv per-function.status \
    owner-ledger.txt owner-ledger.status
  do
    label=${relative//[^A-Za-z0-9]/-}
    run_step \
      "$CANONICAL/comparisons/repetition-$repetition-$label" \
      "$CANONICAL/comparisons/repetition-$repetition-$label.status" 0 \
      "$CANONICAL/comparisons/repetition-$repetition-$label.stdout" \
      "$CANONICAL/comparisons/repetition-$repetition-$label.stderr" \
      /usr/bin/cmp "$BASE/$relative" "$REP/$relative"
  done

  while IFS=$'\t' read -r id function_name size_dec value_hex \
    code_sha dis_sha
  do
    for suffix in \
      code.bin objdump objdump.stderr \
      dd.status objdump.status identity.status identity.tsv
    do
      label=${suffix//[^A-Za-z0-9]/-}
      run_step \
        "$CANONICAL/comparisons/repetition-$repetition-$id-$label" \
        "$CANONICAL/comparisons/repetition-$repetition-$id-$label.status" \
        0 \
        "$CANONICAL/comparisons/repetition-$repetition-$id-$label.stdout" \
        "$CANONICAL/comparisons/repetition-$repetition-$id-$label.stderr" \
        /usr/bin/cmp "$BASE/functions/$id.$suffix" \
        "$REP/functions/$id.$suffix"
    done
  done <"$BASE/per-function-identities.tsv"
done

run_step \
  "$CANONICAL/records/identity-manifest" \
  "$CANONICAL/identity-manifest.status" 0 \
  "$CANONICAL/records/identity-manifest.stdout" \
  "$CANONICAL/records/identity-manifest.stderr" \
  /bin/bash -c '
    set -euo pipefail
    input="$1"
    artifact="$2"
    base="$3"
    output="$4"
    accepted="$5"
    summary="$base/report.summary.txt"
    population=$(/usr/bin/awk '\''
      {
        for (i = 1; i <= NF; i++) {
          split($i, part, "=")
          if (part[1] == "selected_functions") print part[2]
        }
      }
    '\'' "$summary")
    first_failure=$(/usr/bin/awk '\''
      {
        for (i = 1; i <= NF; i++) {
          split($i, part, "=")
          if (part[1] == "first_failure") print part[2]
        }
      }
    '\'' "$summary")
    frontier_population=$(/usr/bin/awk '\''END { print NR }'\'' \
      "$base/frontier.tsv")
    function_count=$(/usr/bin/awk '\''END { print NR }'\'' \
      "$base/per-function-identities.tsv")
    printf "%s\t%s\n" \
      o2_calls_crt_v1_r131_input_sha256 \
      "$(/usr/bin/sha256sum "$input" | /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_artifact_sha256 \
      "$(/usr/bin/sha256sum "$artifact" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_report_sha256 \
      "$(/usr/bin/sha256sum "$base/report.stderr.raw" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_report_population "$population" \
      o2_calls_crt_v1_r131_report_first_failure "$first_failure" \
      o2_calls_crt_v1_r131_report_status \
      "$(/usr/bin/awk "{print \\$1}" "$base/report.status")" \
      o2_calls_crt_v1_r131_accepted_input_sha256 \
      "$(/usr/bin/sha256sum "$accepted" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_object_sha256 \
      "$(/usr/bin/sha256sum "$base/accepted.o" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_object_status \
      "$(/usr/bin/awk "{print \\$1}" "$base/object.status")" \
      o2_calls_crt_v1_r131_owner_sha256 \
      "$(/usr/bin/sha256sum "$base/owner.tsv" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_owner_ledger \
      "$(/usr/bin/awk -F= '\''$1 == "ledger" { print $2 }'\'' \
        "$base/owner-ledger.txt")" \
      o2_calls_crt_v1_r131_owner_status \
      "$(/usr/bin/awk "{print \\$1}" "$base/owner.status")" \
      o2_calls_crt_v1_r131_objdump_sha256 \
      "$(/usr/bin/sha256sum "$base/accepted.objdump" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_per_function_manifest_sha256 \
      "$(/usr/bin/sha256sum "$base/per-function-identities.tsv" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_per_function_count "$function_count" \
      o2_calls_crt_v1_r131_frontier_manifest_sha256 \
      "$(/usr/bin/sha256sum "$base/frontier.tsv" |
        /usr/bin/awk "{print \\$1}")" \
      o2_calls_crt_v1_r131_frontier_population "$frontier_population" \
      >"$output"
  ' _ "$INPUT" "$ARTIFACT" "$BASE" \
  "$CANONICAL/o2_calls_crt_v1_r131.identities.tsv" "$ACCEPTED"

for repetition in 1 2 3; do
  REP="$CANONICAL/repetition-$repetition"
  run_step \
    "$CANONICAL/records/repetition-$repetition-finalize" \
    "$CANONICAL/repetition-$repetition-finalize.status" 0 \
    "$CANONICAL/records/repetition-$repetition-finalize.stdout" \
    "$CANONICAL/records/repetition-$repetition-finalize.stderr" \
    /bin/bash -c '
      set -euo pipefail
      rep="$1"
      manifest="$2"
      shopt -s globstar nullglob
      paths=("$rep"/**)
      for path in "${paths[@]}"; do
        test -f "$path" && test ! -L "$path" || continue
        /usr/bin/chmod 0444 "$path"
      done
      {
        printf "path\tbytes\tmode\tsha256\n"
        {
          for path in "${paths[@]}"; do
            test -f "$path" && test ! -L "$path" || continue
            printf "%s\t%s\t%s\t%s\n" \
              "$path" \
              "$(/usr/bin/stat -c "%s" "$path")" \
              "$(/usr/bin/stat -c "%a" "$path")" \
              "$(/usr/bin/sha256sum "$path" |
                /usr/bin/awk "{print \\$1}")"
          done
        } | LC_ALL=C /usr/bin/sort -t "$(printf "\t")" -k1,1
      } >"$manifest"
      /usr/bin/chmod 0444 "$manifest"
    ' _ "$REP" \
    "$CANONICAL/manifests/repetition-$repetition.final.tsv"
done

run_step \
  "$CANONICAL/records/canonical-finalize" \
  "$CANONICAL/canonical-finalize.status" 0 \
  "$CANONICAL/records/canonical-finalize.stdout" \
  "$CANONICAL/records/canonical-finalize.stderr" \
  /bin/bash -c '
    set -euo pipefail
    canonical="$1"
    identities="$2"
    artifact="$3"
    /usr/bin/chmod 0444 "$identities"
    test "$(/usr/bin/stat -c "%a" "$artifact")" = 555
    test "$(/usr/bin/stat -c "%a" "$4")" = 444
    printf "path\tbytes\tmode\tsha256\n%s\t%s\t0444\t%s\n" \
      "$identities" \
      "$(/usr/bin/stat -c "%s" "$identities")" \
      "$(/usr/bin/sha256sum "$identities" |
        /usr/bin/awk "{print \\$1}")" \
      >"$canonical/manifests/identities.final.tsv"
    /usr/bin/chmod 0444 \
      "$canonical/manifests/identities.final.tsv"
  ' _ "$CANONICAL" \
  "$CANONICAL/o2_calls_crt_v1_r131.identities.tsv" \
  "$ARTIFACT" "$ACCEPTED"
```

All three reports consume the adopted raw input. Only repetition 1 produces
the successful subset. Every later canonical and coverage object/owner
consumer uses that one read-only file. No comparison normalizes semantic
output. Any mismatch stops the driver before section 8.

## 7. Complete producer-before-consumer ledger

This ledger is part of the executable contract. A pattern denotes the
finite set driven by the already-produced manifest named in its consumer
column; it is not an open-ended path choice.

### 7.1 Immutable inputs

| Input | Absolute path | Required type/mode/bytes | Required identity check | Consumers |
|---|---|---|---|---|
| baseline source commit | Git object in `/home/oleg/prog/z_llvm` | commit object | full `43de59b06ca3a687368bfaf0595c5759c8ab3a57`; each complete stream binds this literal once and validates exactly 40 lowercase hexadecimal characters | source-surface provenance, canonical and coverage worktree creation, source preflight, coverage restoration |
| adopted raw input | `/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll` | regular, `0444`, 1,897,410 | SHA-256 `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` | all canonical/off/on report commands |
| adoption manifest | `/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv` | regular, `0444`, 4,394 | SHA-256 `500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf` | preflight only |
| bundle manifest | `/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/inbox187_baseline_validation_contract_bundle/manifests/bundle-files.sha256` | regular, `0444`, 2,519 | SHA-256 `0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0` | bundle preflight |
| combined patch | `/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/inbox187_baseline_validation_contract_bundle/patches/aggregate-consumer-observer-guard.patch` | regular, `0444`, 41,140 | SHA-256 `7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f` | apply-check only |
| reproduction manifest | `/home/oleg/prog/z_llvm/tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/retained-files-final.tsv` | regular, `0664`, 458,294 | SHA-256 `885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e` | preflight only |
| live pins | `/home/oleg/prog/z_llvm/docs/evidence/tmp_retention_pins.tsv` | regular, `0664`, 3,051 | SHA-256 `1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3` | preflight only |
| retention policy | `/home/oleg/prog/z_llvm/docs/retention_headroom_policy.md` | regular, `0664`, 10,622 | SHA-256 `a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd` | preflight only |
| cleanup source | `/home/oleg/prog/z_llvm/tools/clean_tmp.zig` | regular, `0664`, 50,100 | SHA-256 `8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e` | preflight only; never executed |
| watcher | `/home/oleg/prog/z_llvm/scripts/z_llvm_watcher_loop.sh` | regular, `0775`, 10,850 | Git blob `b64131cf60dd0ef638e815cd33db9ae8595a72cf` for HEAD/index/worktree | preflight only; never executed |
| bypass inventory | `/home/oleg/prog/z_llvm/docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv` | regular, `0664`, 5,188 | SHA-256 `2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11`; recount 131 | preflight/restoration |
| facade manifest | `/home/oleg/prog/z_llvm/docs/evidence/inbox128_o2_r1_facade_manifest.tsv` | regular, `0664`, 2,686 | SHA-256 `2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26` | preflight/restoration |
| facade source | `/home/oleg/prog/z_llvm/src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig` | regular, `0664`, 103 | SHA-256 `4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a` | preflight/restoration |
| pinned Zig source | `/home/oleg/prog/ziglang` | Git worktree | commit `bdee02bc0c7f227c0f11bc9a449df673fe803540`, tree `aa032b2b82a48a4684657f909e6e270a6c925e33` | provenance preflight only |
| pinned stage4 | `/home/oleg/prog/ziglang/build/stage4/bin/zig` | regular, `0775`, 530,327,885 | SHA-256 `dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7` | provenance preflight only; never executed here |
| frozen tool set | paths in `$BUNDLE/manifests/future-tool-identities.sha256` | modes unchanged | every path SHA-256 equals its manifest row | all future commands |

Every row is checked before `$ROOT` is created and again after restoration.
Mode, size, and identity movement is a stop.

### 7.2 Canonical directories and files

| Generated path or finite pattern | Sole producer | First consumer |
|---|---|---|
| `$PARENT/baseline_validation_v3.preflight.{command.txt,environment.txt,cwd.txt,start.utc,end.utc,stdout.raw,stderr.raw,status,records.tsv}` | immutable-input preflight record/write | review |
| `$PARENT/baseline_validation_v3.driver.{command.txt,environment.txt,cwd.txt,start.utc,end.utc,stdout.raw,stderr.raw,status,records.tsv}` | driver bootstrap record/write | review |
| `$ROOT/canonical/{records,manifests,comparisons,build/*,artifact,repetition-{1,2,3}/{home,tmp,records,functions}}` | driver bootstrap `mkdir` | subsequent named step |
| `$ROOT/canonical/source` | `worktree-add` | `source-preflight`, then build |
| `$ROOT/canonical/{worktree-add,source-preflight,artifact-install,artifact-identity,identity-manifest,repetition-{1,2,3}-finalize,canonical-finalize}.status` | corresponding named `run_step` | final evidence |
| `$ROOT/canonical/records/*.{command.txt,environment.txt,cwd.txt,start.utc,end.utc,stdout,stderr}` | corresponding named canonical step | final evidence |
| `$ROOT/canonical/build/{cache/**,prefix/**,stdout.raw,stderr.raw,build.status}` | `build` | artifact install/final evidence |
| `$ROOT/canonical/artifact/z_llvm` | `artifact-install` | all three report/object/owner producers |
| `$ROOT/canonical/artifact.identity.tsv` | `artifact-identity` | identity manifest/final evidence |
| `repetition-N/report.{stdout.raw,stderr.raw,status}` | `repetition-N/report` | report parsers/comparisons |
| `repetition-N/report.summary.txt` and parser status | `report-summary` | report validation/identity/comparison |
| `repetition-N/failed-functions.in-report-order.txt` and status | `failures-in-order` | unique sort/comparison |
| `repetition-N/failed-functions.sorted.txt` and status | `failures-sorted` | repetition-1 extraction/comparison |
| `repetition-N/frontier{,-grouped}{,.unsorted}.tsv` and statuses | `frontier`, then `frontier-grouped` | identity/comparison |
| `repetition-1/accepted.ll` | repetition-1 `extract` only | freeze, all canonical object/owner, section 9 |
| `repetition-1/{extract.stdout.raw,extract.stderr.raw,extract.status,accepted.identity.tsv,accepted-freeze.status}` | `extract`, then `accepted-freeze` | immutable-input checks |
| `repetition-N/accepted.o` and object records/status | `object` | objdump/readelf/objcopy/comparisons |
| `repetition-N/owner.tsv` and owner records/status | `owner` | ledger/comparisons |
| `repetition-N/accepted.objdump`, stderr, status | `objdump` | comparison/identity |
| `repetition-N/{sections,symbols}.readelf`, stderr, statuses | two readelf steps | function sorting/comparison |
| `repetition-N/text.bin`, objcopy channels/status | `objcopy-text` | per-function `dd` |
| `repetition-N/functions.{unsorted,sorted}.tsv` and status | `functions-sorted` | finite per-function loop |
| `repetition-N/functions/NNNNNN.{code.bin,dd.status,objdump,objdump.stderr,objdump.status,identity.tsv,identity.status}` | manifest-driven `dd`, objdump, identity steps | per-function aggregate/comparison |
| `repetition-N/per-function-identities.tsv` and status | `per-function` | comparison/identity |
| `repetition-N/owner-ledger.txt` and status | `owner-ledger` | comparison/identity |
| `$CANONICAL/comparisons/*.{stdout,stderr,status,command.txt,environment.txt,cwd.txt,start.utc,end.utc}` | one named `run_step` comparison | final evidence only |
| `$CANONICAL/o2_calls_crt_v1_r131.identities.tsv` | `identity-manifest` | section 9 identity checks |
| `$CANONICAL/manifests/repetition-N.final.tsv` | repetition-N finalize | review |
| `$CANONICAL/manifests/identities.final.tsv` | canonical finalize | review |

Each `run_step` additionally and solely produces its unique
`command.txt`, `environment.txt`, `cwd.txt`, `start.utc`, `end.utc`,
stdout, stderr, status, and `records.tsv` paths. Its `records.tsv` freezes
the path, bytes, final mode, and SHA-256 of the other eight records after
they become `0444`. The table's `N` is exactly `1`, `2`, or `3`;
`NNNNNN` is exactly one row ID from that repetition's
`functions.sorted.tsv`.

### 7.3 Coverage roots

Canonical, observation-off, and observation-on generated roots are
pairwise disjoint:

```text
$ROOT/canonical
$ROOT/coverage/observation-off
$ROOT/coverage/observation-on
```

The coverage producers are closed as follows:

| Generated path or finite pattern | Sole producer | First consumer |
|---|---|---|
| `$ROOT/coverage/reference` and `$ROOT/coverage/directory-creation.{command.txt,environment.txt,cwd.txt,start.utc,end.utc,stdout.raw,stderr.raw,status,records.tsv}` | section 9 directory-creation command/record | reference records |
| `$OFF/{home,tmp,records,functions}` and `$ON/{home,tmp,records,functions}` | section 9 directory-creation command | phase commands |
| `$OFF/report.{stdout,stderr}.raw`, report status/records | off report | off raw parsers/comparisons |
| `$OFF/{report.summary.txt,failed-functions.*,frontier.tsv,frontier-grouped.tsv}` and parser records/statuses | corresponding off parser | off raw comparisons |
| `$OFF/{accepted.o,object.stderr.raw,owner.tsv,owner.stderr.raw}` and records/statuses | off object/owner | off inspection/ledger |
| `$OFF/{accepted.objdump,sections.readelf,symbols.readelf,text.bin,functions.sorted.tsv,per-function-identities.tsv,owner-ledger.txt}` plus finite function files and records | corresponding off inspection/manifest step | off comparisons/identity checks |
| `$ROOT/coverage/reference/{channels.before-observation-off.txt,channels.after-observation-off.txt,canonical-accepted.before.tsv,canonical-accepted.after-off.tsv,canonical-accepted.after-off.cmp.status,canonical-accepted.after-on.tsv,canonical-accepted.after-on.cmp.status}` | corresponding exact absence/identity check | next named comparison/review |
| `$ON/report.coverage.tsv` | on report only | report counter validator |
| `$ON/object.coverage.tsv` | on object only | object counter validator |
| `$ON/owner.coverage.tsv` | on owner only | owner counter validator |
| `$ON/report.{stdout,stderr}.raw`, parsed raw-report outputs and records | on report/parsers | on raw comparisons |
| `$ON/{accepted.o,owner.tsv,accepted.objdump,sections.readelf,symbols.readelf,text.bin,functions.sorted.tsv,per-function-identities.tsv,owner-ledger.txt}` plus finite function files and records | corresponding on successful-subset producer | on comparisons/identity checks |
| `$ON/records/{report,object,owner}-channel.presence.txt` | corresponding sole channel producer postcheck | review |
| `$ON/{validate-report-counters,validate-object-counters,validate-owner-counters,cmp-object-owner-counters}.{stdout,stderr}` and record/status sets | corresponding counter validator/comparison | review |
| `$ROOT/coverage/{observation-off,observation-on}.{files.sha256,final.tsv}` and `final-manifests.sha256` | section 9 finalizers | review |

Neither coverage root has a producer for `accepted.ll`. Every coverage
object/owner command references the immutable absolute `$ACCEPTED`.
Every report command references the immutable absolute `$INPUT`. Any
duplicate producer, read-before-produce, unlisted output, root overlap, or
implicit path is a contract failure.

### 7.4 Complete `/bin/bash -c` argument-binding audit

This is the closed invocation ledger for all **45** `/bin/bash -c`
templates in sections 5–9: 27 canonical templates and 18 coverage
templates. Every invocation supplies the literal `_` as `$0`; no script
body receives a path through `$0`. “AWK input” names an explicit file
argument or pipeline standard input. “No `-v`” means the AWK program uses
only its records and AWK-local variables. The sole shell-to-AWK binding in
these templates is C24’s `-v summary="$summary"`.

`run_step` is the unique status producer for C02–C27. Its status argument
is the path shown below; loop expansion makes every repetition and
six-digit function ID a disjoint invocation. C01 is the pre-root preflight
and writes its status exactly once through `write_status_once`.
`run_recorded` is the unique status producer for F01–F18; F18 expands once
for `object` and once for `owner`, with disjoint record prefixes. These
recorder-owned status files are never command stdout or semantic output.

The canonical complete stream binds the literal full `SOURCE_COMMIT` once,
validates its 40-lowercase-hex shape, and passes it as C01 `$6`, C02 `$2`,
and the worktree-add revision argument. The complete coverage stream binds
the same literal once before worktree creation, validates it, uses it for
that creation and both restoration comparisons, and passes it as the sole
argument to the section-9 shell. That shell revalidates the passed value
without repeating the literal. These two stream-level bindings are outside
the 45 `/bin/bash -c` child templates and add no hidden positional input.

#### Canonical templates

| ID | Command and explicit binding (`$0` is `_`) | Shell-variable bindings | AWK binding and consumed path | Producer-before-consumer and sole status |
|---|---|---|---|---|
| C01 | immutable preflight: direct `/bin/bash -c '<literal body>' _ "$REPO" "$INPUT" "$BUNDLE" "$EXPECTED_MAIN_HEAD" "$TRACKED_SOURCE_MANIFEST" "$SOURCE_COMMIT"`; `$0=_`, `$1=$REPO`, `$2=$INPUT`, `$3=$BUNDLE`, `$4=$EXPECTED_MAIN_HEAD`, `$5=$TRACKED_SOURCE_MANIFEST`, `$6=$SOURCE_COMMIT` | `repo=$1`; `input=$2`; `bundle=$3`; `expected_main_head=$4`; `tracked_source_manifest=$5`; `source_commit=$6`; manifest loops bind `payload_path`, `payload_bytes`, `payload_mode`, `expected`, and `tool_path`; capacity checks bind `available_blocks` and `block_size` | no `-v`; every AWK program is a literal single-quoted field program inside the direct child body; SHA readers consume pipeline stdin; stash reader consumes `git stash list` stdin; mode/tool manifests are consumed through their explicit redirections | verifies exact main `HEAD`, empty worktree/index/tracked-only status, frozen tracked-source manifest, and source-surface provenance against the bound full source commit before `$ROOT` creation; produces only v3 preflight records; `$PREFLIGHT_RECORD.status` |
| C02 | source preflight: `$1=$CANONICAL/source`, `$2=$SOURCE_COMMIT` | `source_root=$1`; `source_commit=$2` | none | consumes the worktree-add result and compares full `rev-parse HEAD` with the bound source identity before build; `$CANONICAL/source-preflight.status` |
| C03 | canonical build: `$1=$CANONICAL/source`, `$2=$CANONICAL/build/prefix`, `$3=$CANONICAL/build/cache/local`, `$4=$CANONICAL/build/cache/global` | no aliases; all four positions are consumed directly | none | consumes C02’s verified source, produces the build prefix; `$CANONICAL/build/build.status` |
| C04 | artifact identity: `$1=$ARTIFACT`, `$2=$CANONICAL/artifact.identity.tsv` | `artifact=$1`; `output=$2` | no `-v`; SHA field reader consumes `sha256sum` stdin | consumes artifact-install, produces artifact identity before reports; `$CANONICAL/artifact-identity.status` |
| C05 | repetition report: `$1=$ARTIFACT`, `$2=$INPUT`, `$3=$REP/report.stdout.raw`, `$4=$REP/report.stderr.raw` | `artifact=$1`; `input=$2`; `semantic_stdout=$3`; `semantic_stderr=$4` | none | consumes C04 artifact and adopted raw input; produces one raw report per repetition; `$REP/report.status` |
| C06 | report summary: `$1=$REP/report.stderr.raw`, `$2=$REP/report.summary.txt` | none | no `-v`; AWK consumes `$1`; shell redirects AWK stdout to `$2` | consumes C05, produces the sole summary; `$REP/report-summary.status` |
| C07 | report validation: `$1=$REP/report.stdout.raw`, `$2=$REP/report.summary.txt` | none | no `-v`; AWK consumes `$2`; shell separately requires `$1` empty | consumes C05/C06; no semantic output; `$REP/report-validate.status` |
| C08 | failures in report order: `$1=$REP/report.stderr.raw`, `$2=$REP/failed-functions.in-report-order.txt` | none | no `-v`; AWK consumes `$1`; shell redirects to `$2` | consumes C05 before unique sort/extract; `$REP/failures-in-order.status` |
| C09 | frontier: `$1=$REP/report.stderr.raw`, `$2=$REP/frontier.tsv`, `$3=$REP/frontier.unsorted.tsv` | `temporary=$3` | no `-v`; AWK consumes `$1` and writes `$temporary`; sort consumes `$temporary` and produces `$2` | consumes C05 before grouping/identity; `$REP/frontier.status` |
| C10 | grouped frontier: `$1=$REP/frontier.tsv`, `$2=$REP/frontier-grouped.tsv`, `$3=$REP/frontier-grouped.unsorted.tsv` | `temporary=$3` | no `-v`; AWK consumes `$1` and writes `$temporary`; sort consumes `$temporary` and produces `$2` | consumes C09; `$REP/frontier-grouped.status` |
| C11 | report-count validation: `$1=$REP/report.summary.txt`, `$2=$REP/failed-functions.in-report-order.txt`, `$3=$REP/failed-functions.sorted.txt`, `$4=$REP/frontier.tsv` | `expected`, `ordered`, `unique`, and `frontier` are derived from the corresponding positions | no `-v`; four count AWKs consume `$1`–`$4`; the syntax AWK consumes `$3` | consumes C06, C08, failures-sorted, and C09; `$REP/report-counts-validate.status` |
| C12 | repetition-1 extraction: `$1=$REP/failed-functions.sorted.txt`, `$2=$INPUT`, `$3=$ACCEPTED`, `$4=$REP/extract.stdout.raw`, `$5=$REP/extract.stderr.raw` | `failure_file=$1`; `input=$2`; `accepted=$3`; `semantic_stdout=$4`; `semantic_stderr=$5`; array `extract_args` and loop variable `function_name` are built only from `$failure_file` | none | consumes sorted failures and raw input; sole producer of `$ACCEPTED`; `$REP/extract.status` |
| C13 | accepted-input freeze: `$1=$ACCEPTED`, `$2=$REP/accepted.identity.tsv`, `$3=$REP/extract.stdout.raw`, `$4=$REP/extract.stderr.raw` | `accepted=$1`; `identity=$2`; `$3`/`$4` are consumed directly as empty channels | no `-v`; SHA field reader consumes `sha256sum` stdin | consumes C12, freezes `$ACCEPTED` before every object/owner consumer; `$REP/accepted-freeze.status` |
| C14 | canonical object: `$1=$ARTIFACT`, `$2=$ACCEPTED`, `$3=$REP/accepted.o`, `$4=$REP/object.stderr.raw` | no aliases; all positions consumed directly | none | consumes frozen C13 input and C04 artifact; produces object; `$REP/object.status` |
| C15 | canonical owner: `$1=$ARTIFACT`, `$2=$ACCEPTED`, `$3=$REP/owner.tsv`, `$4=$REP/owner.stderr.raw` | no aliases; all positions consumed directly | none | consumes frozen C13 input and C04 artifact; produces owner manifest; `$REP/owner.status` |
| C16 | canonical objdump: `$1=$REP` | no alias; `$1` becomes working directory | none | consumes C14 object; produces objdump files; `$REP/objdump.status` |
| C17 | section readelf: `$1=$REP/accepted.o`, `$2=$REP/sections.readelf`, `$3=$REP/sections.stderr.raw` | no aliases; all positions consumed directly | none | consumes C14 object; `$REP/readelf-sections.status` |
| C18 | symbol readelf: `$1=$REP/accepted.o`, `$2=$REP/symbols.readelf`, `$3=$REP/symbols.stderr.raw` | no aliases; all positions consumed directly | none | consumes C14 object; `$REP/readelf-symbols.status` |
| C19 | text extraction: `$1=$REP/accepted.o`, `$2=$REP/text.bin`, `$3=$REP/objcopy.stdout.raw`, `$4=$REP/objcopy.stderr.raw` | no aliases; all positions consumed directly | none | consumes C14 object; produces text for function extraction; `$REP/objcopy-text.status` |
| C20 | function sorting: `$1=$REP/symbols.readelf`, `$2=$REP/functions.sorted.tsv`, `$3=$REP/functions.unsorted.tsv` | `temporary=$3` | no `-v`; AWK consumes `$1` and writes `$temporary`; sort produces `$2` | consumes C18 before the finite per-function loop; `$REP/functions-sorted.status` |
| C21 | per-function objdump: `$1=$REP`, `$2=$function_name`, `$3=$id` | no aliases; all positions consumed directly | none | consumes C14/C20; produces `functions/$id.objdump`; `$REP/functions/$id.objdump.status` |
| C22 | per-function identity: `$1=$REP/functions/$id.code.bin`, `$2=$REP/functions/$id.objdump.stderr`, `$3=$size_dec`, `$4=$id`, `$5=$function_name`, `$6=$value_hex`, `$7=$REP/functions/$id.objdump`, `$8=$REP/functions/$id.identity.tsv` | no aliases; all positions consumed directly | no `-v`; two SHA field readers consume `sha256sum` stdin for `$1` and `$7` | consumes function `dd` and C21; produces one identity row; `$REP/functions/$id.identity.status` |
| C23 | per-function aggregate: `$1=$REP/functions`, `$2=$REP/per-function-identities.tsv`, `$3=$REP/functions.sorted.tsv` | `functions=$1`; `output=$2`; `source_manifest=$3`; array `rows`, `expected_rows`, and loop variables `row_path` and `row_text` derive from those paths | no `-v`; row-count AWK consumes `$source_manifest` | consumes every C22 row and C20 manifest; `$REP/per-function.status` |
| C24 | owner ledger: `$1=$REP/owner.tsv`, `$2=$REP/owner-ledger.txt`, `$3=$REP/report.summary.txt` | `summary=$3` before AWK | `-v summary="$summary"` binds the exact report-summary path; AWK records consume `$1`; `getline` consumes `summary`; shell redirects to `$2` | consumes C15 and C06; produces checked ledger before identity/comparison; `$REP/owner-ledger.status` |
| C25 | canonical identity manifest: `$1=$INPUT`, `$2=$ARTIFACT`, `$3=$BASE`, `$4=$CANONICAL/o2_calls_crt_v1_r131.identities.tsv`, `$5=$ACCEPTED` | `input=$1`; `artifact=$2`; `base=$3`; `output=$4`; `accepted=$5`; `summary`, `population`, `first_failure`, `frontier_population`, and `function_count` derive only from those bindings | no `-v`; AWKs consume `$base/report.summary.txt`, `$base/frontier.tsv`, `$base/per-function-identities.tsv`, status/ledger files, or SHA pipeline stdin | consumes all three exact repetitions and comparisons; produces canonical identities; `$CANONICAL/identity-manifest.status` |
| C26 | repetition finalizer: `$1=$REP`, `$2=$CANONICAL/manifests/repetition-$repetition.final.tsv` | `rep=$1`; `manifest=$2`; array `paths` is the closed glob rooted at `$rep`; both loops bind `path` | no `-v`; SHA field readers consume pipeline stdin | consumes the completed repetition; produces its final manifest; `$CANONICAL/repetition-$repetition-finalize.status` |
| C27 | canonical finalizer: `$1=$CANONICAL`, `$2=$CANONICAL/o2_calls_crt_v1_r131.identities.tsv`, `$3=$ARTIFACT`, `$4=$ACCEPTED` | `canonical=$1`; `identities=$2`; `artifact=$3`; `$4` is consumed directly for the accepted-input mode check | no `-v`; SHA field reader consumes `sha256sum` stdin | consumes C25, C04, and C13; produces `identities.final.tsv`; `$CANONICAL/canonical-finalize.status` |

#### Coverage templates

| ID | Command and explicit binding (`$0` is `_`) | Shell-variable bindings | AWK binding and consumed path | Producer-before-consumer and sole status |
|---|---|---|---|---|
| F01 | off report summary: `$1=$OFF/report.stderr.raw` | none | no `-v`; AWK consumes `$1`; recorder stdout is `$OFF/report.summary.txt` | consumes off raw report before comparisons; `$OFF/records/report-summary.status` |
| F02 | off failures in order: `$1=$OFF/report.stderr.raw` | none | no `-v`; AWK consumes `$1`; recorder stdout is the ordered-failures file | consumes off raw report before unique sort; `$OFF/records/failures-in-order.status` |
| F03 | off frontier: `$1=$OFF/report.stderr.raw` | none | no `-v`; AWK consumes `$1` and pipes to sort; recorder stdout is `$OFF/frontier.tsv` | consumes off raw report before grouping/comparison; `$OFF/records/frontier.status` |
| F04 | off grouped frontier: `$1=$OFF/frontier.tsv` | none | no `-v`; AWK consumes `$1` and pipes to sort; recorder stdout is `$OFF/frontier-grouped.tsv` | consumes F03; `$OFF/records/frontier-grouped.status` |
| F05 | off objdump: `$1=$OFF` | no alias; `$1` becomes working directory | none | consumes off object before fixed comparisons; `$OFF/records/objdump.status` |
| F06 | off function sorting: `$1=$OFF/symbols.readelf` | none | no `-v`; AWK consumes `$1` and pipes to sort; recorder stdout is `$OFF/functions.sorted.tsv` | consumes off readelf-symbols before F07; `$OFF/records/functions-sorted.status` |
| F07 | off per-function manifest: `$1=$OFF` | `phase=$1`; `row`, read-loop variables `function_name`, `value_hex`, and `size_dec`, plus `id`, `offset`, `code_sha`, and `dis_sha`, derive only from `$phase/functions.sorted.tsv` and its object/text outputs | no `-v`; the manifest read is `$phase/functions.sorted.tsv`; SHA field readers consume pipeline stdin | consumes off object/text/F06 and produces all finite function files plus recorder stdout; `$OFF/records/per-function.status` |
| F08 | off owner ledger: `$1=$OFF/owner.tsv` | none | no `-v`; AWK consumes `$1`; recorder stdout is `$OFF/owner-ledger.txt` | consumes off owner before comparisons; `$OFF/records/owner-ledger.status` |
| F09 | on report summary: `$1=$ON/report.stderr.raw` | none | no `-v`; AWK consumes `$1`; recorder stdout is `$ON/report.summary.txt` | consumes on raw report before comparisons; `$ON/records/report-summary.status` |
| F10 | on failures in order: `$1=$ON/report.stderr.raw` | none | no `-v`; AWK consumes `$1`; recorder stdout is the ordered-failures file | consumes on raw report before unique sort; `$ON/records/failures-in-order.status` |
| F11 | on frontier: `$1=$ON/report.stderr.raw` | none | no `-v`; AWK consumes `$1` and pipes to sort; recorder stdout is `$ON/frontier.tsv` | consumes on raw report before grouping/comparison; `$ON/records/frontier.status` |
| F12 | on grouped frontier: `$1=$ON/frontier.tsv` | none | no `-v`; AWK consumes `$1` and pipes to sort; recorder stdout is `$ON/frontier-grouped.tsv` | consumes F11; `$ON/records/frontier-grouped.status` |
| F13 | on objdump: `$1=$ON` | no alias; `$1` becomes working directory | none | consumes on object before fixed comparisons; `$ON/records/objdump.status` |
| F14 | on function sorting: `$1=$ON/symbols.readelf` | none | no `-v`; AWK consumes `$1` and pipes to sort; recorder stdout is `$ON/functions.sorted.tsv` | consumes on readelf-symbols before F15; `$ON/records/functions-sorted.status` |
| F15 | on per-function manifest: `$1=$ON` | `phase=$1`; `row`, read-loop variables `function_name`, `value_hex`, and `size_dec`, plus `id`, `offset`, `code_sha`, and `dis_sha`, derive only from `$phase/functions.sorted.tsv` and its object/text outputs | no `-v`; the manifest read is `$phase/functions.sorted.tsv`; SHA field readers consume pipeline stdin | consumes on object/text/F14 and produces all finite function files plus recorder stdout; `$ON/records/per-function.status` |
| F16 | on owner ledger: `$1=$ON/owner.tsv` | none | no `-v`; AWK consumes `$1`; recorder stdout is `$ON/owner-ledger.txt` | consumes on owner before comparisons; `$ON/records/owner-ledger.status` |
| F17 | report-counter validator: `$1=$REPORT_CHANNEL` | none | no `-v`; AWK consumes `$1`; recorder owns the validation channels | consumes the sole on-report channel after its producer; `$ON/records/validate-report-counters.status` |
| F18 | successful-subset counter validator: `$1=$channel`, where the loop binds `$channel` first to `$OBJECT_CHANNEL` and then `$OWNER_CHANNEL` | no alias inside the child; parent `channel_label` selects the disjoint record prefix only | no `-v`; AWK consumes `$1`; recorder owns each validation channel | each invocation follows its sole object/owner channel producer; `$ON/records/validate-object-counters.status` and `$ON/records/validate-owner-counters.status` |

The INBOX-187C audit had two and only two same-class corrections:

1. C24 now binds its third Bash argument to shell variable `summary` and
   passes that exact path to AWK with `-v summary="$summary"` before
   `getline line < summary`.
2. C10 no longer passes its unrelated temporary-output argument as an
   unused AWK variable named `summary`; the grouped-frontier AWK consumes
   only `$1`, exactly as its body requires.

Every other template already supplies `_`, supplies at least its highest
referenced positional argument, consumes only the paths mapped above, and
has a producer before its first generated-path consumer. There is no
unbound positional parameter, AWK path variable, duplicate generated
status, or coverage producer for `accepted.ll`.

INBOX-189 re-audited all 45 rows against the v2 driver. C02–C27 and
F01–F18 retain their accepted bindings and producer/status order. C01 now
has this exact argv:

```text
argv[0]=/bin/bash
argv[1]=-c
argv[2]=the single literal C01 body in section 5
argv[3]=_
argv[4]=$REPO
argv[5]=$INPUT
argv[6]=$BUNDLE
argv[7]=$EXPECTED_MAIN_HEAD
argv[8]=$TRACKED_SOURCE_MANIFEST
```

The child receives `_` as `$0` and the five paths or bindings as `$1`
through `$5`. There is no `preflight_program`, `eval`, serialized-program
re-evaluation, or other intermediate parser. Every C01 AWK field program
is a literal single-quoted child-script token and reaches AWK as
`{print $1}` or `NR == 1 { print; exit }`, with no parent-shell expansion.

## 8. Coverage-only artifact and guard

Coverage begins only after the canonical three-repetition block passes.
The complete coverage stream binds the full source identity exactly once,
validates it before any generated-path producer, and passes that bound value
to every child source-identity consumer:

```bash
set -euo pipefail
readonly SOURCE_COMMIT=43de59b06ca3a687368bfaf0595c5759c8ab3a57
test "${#SOURCE_COMMIT}" -eq 40
test -z "${SOURCE_COMMIT//[0-9a-f]/}"

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
  "$ROOT/coverage/source" "$SOURCE_COMMIT"
test "$(/usr/bin/git -C "$ROOT/coverage/source" rev-parse HEAD)" = \
  "$SOURCE_COMMIT"
test -z "$(/usr/bin/git -C "$ROOT/coverage/source" status --porcelain)"
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
  /home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/canonical/repetition-1/accepted.ll
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
(
  cd /home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage/source
  exec /usr/bin/env -i \
    HOME=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage \
    TMPDIR=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage \
    PATH=/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin \
    LC_ALL=C LANG=C TZ=UTC SOURCE_DATE_EPOCH=0 \
    /bin/bash --noprofile --norc -s -- "$SOURCE_COMMIT"
)
```

The driver environment deliberately contains no coverage variable. Before
any coverage command, set exactly:

```bash
set -euo pipefail
umask 022

test "$#" -eq 1
readonly SOURCE_COMMIT="$1"
shift
test "$#" -eq 0
test "${#SOURCE_COMMIT}" -eq 40
test -z "${SOURCE_COMMIT//[0-9a-f]/}"

readonly ROOT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
readonly RAW_INPUT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
readonly COVERAGE_ARTIFACT=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage/artifact/z_llvm
readonly CANONICAL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/canonical/repetition-1
readonly CANONICAL_ACCEPTED=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/canonical/repetition-1/accepted.ll
readonly CANONICAL_IDENTITIES=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/canonical/o2_calls_crt_v1_r131.identities.tsv
readonly OFF=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage/observation-off
readonly ON=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage/observation-on
readonly REPORT_CHANNEL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage/observation-on/report.coverage.tsv
readonly OBJECT_CHANNEL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage/observation-on/object.coverage.tsv
readonly OWNER_CHANNEL=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3/coverage/observation-on/owner.coverage.tsv
```

Section 6 must have written `CANONICAL_IDENTITIES` as two-column TSV
`name<TAB>value`, with exactly one row for each frozen
`o2_calls_crt_v1_r131_*` name. The section-6 driver places the
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
write_coverage_status_once() {
  local status_path="$1"
  local status_value="$2"
  local status_text
  test ! -e "$status_path"
  printf -v status_text '%s\n' "$status_value"
  (
    set -o noclobber
    printf '%s' "$status_text" >"$status_path"
  )
}

run_recorded() {
  local record_prefix="$1"
  local expected_status="$2"
  local stdout_path="$3"
  local stderr_path="$4"
  local status
  shift 4

  test ! -e "${record_prefix}.command.txt"
  test ! -e "${record_prefix}.cwd.txt"
  test ! -e "${record_prefix}.environment.txt"
  test ! -e "${record_prefix}.start.utc"
  test ! -e "${record_prefix}.end.utc"
  test ! -e "${record_prefix}.status"
  test ! -e "$stdout_path"
  test ! -e "$stderr_path"

  printf '%q ' "$@" >"${record_prefix}.command.txt"
  printf '\n' >>"${record_prefix}.command.txt"
  pwd -P >"${record_prefix}.cwd.txt"
  /usr/bin/env | LC_ALL=C /usr/bin/sort \
    >"${record_prefix}.environment.txt"
  printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"${record_prefix}.start.utc"
  set +e
  "$@" >"$stdout_path" 2>"$stderr_path"
  status=$?
  set -e
  write_coverage_status_once "${record_prefix}.status" "$status"
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
readonly COVERAGE_BOOT="$ROOT/coverage/directory-creation"
for suffix in \
  command.txt environment.txt cwd.txt start.utc end.utc \
  stdout.raw stderr.raw status records.tsv
do
  test ! -e "$COVERAGE_BOOT.$suffix"
done
/usr/bin/env | LC_ALL=C /usr/bin/sort \
  >"$COVERAGE_BOOT.environment.txt"
pwd -P >"$COVERAGE_BOOT.cwd.txt"
printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"$COVERAGE_BOOT.start.utc"
coverage_mkdir_command=(/usr/bin/mkdir -p \
  "$OFF/home" "$OFF/tmp" "$OFF/records" "$OFF/functions" \
  "$ON/home" "$ON/tmp" "$ON/records" "$ON/functions" \
  "$ROOT/coverage/reference")
printf '%q ' "${coverage_mkdir_command[@]}" \
  >"$COVERAGE_BOOT.command.txt"
printf '\n' >>"$COVERAGE_BOOT.command.txt"
set +e
"${coverage_mkdir_command[@]}" \
  >"$COVERAGE_BOOT.stdout.raw" \
  2>"$COVERAGE_BOOT.stderr.raw"
coverage_mkdir_status=$?
set -e
write_coverage_status_once "$COVERAGE_BOOT.status" \
  "$coverage_mkdir_status"
printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >"$COVERAGE_BOOT.end.utc"
test "$coverage_mkdir_status" -eq 0
/usr/bin/chmod 0444 \
  "$COVERAGE_BOOT.command.txt" \
  "$COVERAGE_BOOT.environment.txt" \
  "$COVERAGE_BOOT.cwd.txt" \
  "$COVERAGE_BOOT.start.utc" \
  "$COVERAGE_BOOT.end.utc" \
  "$COVERAGE_BOOT.status" \
  "$COVERAGE_BOOT.stdout.raw" \
  "$COVERAGE_BOOT.stderr.raw"
{
  printf 'path\tbytes\tmode\tsha256\n'
  for record_path in \
    "$COVERAGE_BOOT.command.txt" \
    "$COVERAGE_BOOT.environment.txt" \
    "$COVERAGE_BOOT.cwd.txt" \
    "$COVERAGE_BOOT.start.utc" \
    "$COVERAGE_BOOT.end.utc" \
    "$COVERAGE_BOOT.status" \
    "$COVERAGE_BOOT.stdout.raw" \
    "$COVERAGE_BOOT.stderr.raw"
  do
    printf '%s\t%s\t%s\t%s\n' \
      "$record_path" \
      "$(/usr/bin/stat -c '%s' "$record_path")" \
      "$(/usr/bin/stat -c '%a' "$record_path")" \
      "$(/usr/bin/sha256sum "$record_path" |
        /usr/bin/awk '{print $1}')"
  done
} >"$COVERAGE_BOOT.records.tsv"
/usr/bin/chmod 0444 "$COVERAGE_BOOT.records.tsv"
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

require_identity_sha o2_calls_crt_v1_r131_object_sha256 \
  "$OFF/accepted.o" "$OFF/records/object-identity"
require_identity_sha o2_calls_crt_v1_r131_owner_sha256 \
  "$OFF/owner.tsv" "$OFF/records/owner-identity"
require_identity_sha o2_calls_crt_v1_r131_objdump_sha256 \
  "$OFF/accepted.objdump" "$OFF/records/objdump-identity"
require_identity_sha o2_calls_crt_v1_r131_per_function_manifest_sha256 \
  "$OFF/per-function-identities.tsv" \
  "$OFF/records/per-function-identity"
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

require_identity_sha o2_calls_crt_v1_r131_object_sha256 \
  "$ON/accepted.o" "$ON/records/object-identity"
require_identity_sha o2_calls_crt_v1_r131_owner_sha256 \
  "$ON/owner.tsv" "$ON/records/owner-identity"
require_identity_sha o2_calls_crt_v1_r131_objdump_sha256 \
  "$ON/accepted.objdump" "$ON/records/objdump-identity"
require_identity_sha o2_calls_crt_v1_r131_per_function_manifest_sha256 \
  "$ON/per-function-identities.tsv" \
  "$ON/records/per-function-identity"
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
test "$(/usr/bin/git -C "$ROOT/coverage/source" rev-parse HEAD)" = \
  "$SOURCE_COMMIT"
git -C "$ROOT/coverage/source" apply -R \
  "$BUNDLE/patches/03-exact-combined-guard.patch"
git -C "$ROOT/coverage/source" apply -R \
  "$BUNDLE/patches/02-fixed-observer.patch"
git -C "$ROOT/coverage/source" apply -R \
  "$BUNDLE/patches/01-aggregate-consumer.patch"
test "$(/usr/bin/git -C "$ROOT/coverage/source" rev-parse HEAD)" = \
  "$SOURCE_COMMIT"
```

Require:

```text
coverage worktree HEAD == $SOURCE_COMMIT
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

1. separately authorize and execute this corrected validation contract;
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
contract=CORRECTED_PENDING_REVIEW
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

## 15. INBOX-187B execution-order correction record

INBOX-187B started from clean operating-document commit
`1d996a1abddfc584bcad2b747705fca7f6a3642d` above the withheld
INBOX-187A document commit `527340b6`. The only tracked change is this
document.

The correction:

- moves raw report/frontier identity checks and successful-subset identity
  checks into their respective producer phases;
- defines one exact strict-mode canonical driver, including every status
  later consumed by coverage;
- produces the canonical `accepted.ll` exactly once in repetition 1;
- gives every command unique command, environment, working-directory,
  timing, stdout, stderr, status, and record-manifest paths; and
- freezes the complete immutable-input and producer-before-consumer ledger.

The final read-only recheck observed:

```text
bundle_manifest_sha256=0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
combined_patch_sha256=7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
combined_patch_apply_check_status=0
canonical_driver_bash_syntax_status=0
coverage_referenced_canonical_status_producers=15_paths_each_exactly_once
bundle_root_mode=0555
bundle_payload_modes=0444
adopted_input_mode_bytes_sha256=0444/1897410/9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_mode_bytes_sha256=0444/4394/500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
reproduction_manifest_sha256=885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
source_surface_diff_from_43de59b0=empty
watcher_head_index_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
ratchet=131
```

INBOX-187B ran no project code, build, Zig command, `z_llvm`,
selector/report, object generation, guard/test/gate, validation, coverage,
performance, protocol adoption, production wiring, pin edit, cleanup, or
credit.

```text
contract=CORRECTED_PENDING_WATCHER_REVIEWER_ACCEPTANCE
patch_bundle=UNCHANGED_ACCEPTED
canonical_identity=NOT_YET_DEFINED
coverage=NOT_RUN
validation=NOT_RUN
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_BEFORE_VALIDATION_EXECUTION
```

## 17. INBOX-190 exhausted-v2 compliant-stop record

INBOX-190 started from exact clean tracked operating commit
`a4c9d020ec869d808cb12213c1229c159f9bd374`, immediately above accepted
INBOX-189A commit `2f1a880e096a95b9cea0fdd3b2f3294ae0f61465`.
The sole v2 attempt is recorded by compliant-stop commit
`49bbb9d0bb7d0fb70e0654eddbacae0fd58ddd0c`; its summary SHA-256 is
`5cf4b9bb2ba4d4ada1f00aca07e083e5ca7624a7e803addbc0e560f7b1bd2e57`.

The exact token-substituted launcher-plus-driver stream had SHA-256
`fa87620599a147327db58e4ec6a1246858fccac89221f0fe5422a6512e95dc0c`;
the canonical stdin driver had SHA-256
`30b4a934d2996eed4fea8039e279104f2d527e95526b5eddf81b8c34b9ee7fc8`.
It was supplied once. The external preflight and driver setup returned
status zero, and the worktree-add step created one clean detached source.
The source-preflight then returned status one because its first assertion
compared the full `rev-parse HEAD` result
`43de59b06ca3a687368bfaf0595c5759c8ab3a57` with short literal
`43de59b0`. It produced no stdout or stderr and stopped before build,
repetition, identity, coverage, restoration, or read-only finalization.

All retained v2 regular files outside the detached source are:

| Exact historical path | Bytes | Mode | SHA-256 |
|---|---:|---:|---|
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.command.txt` | 2,235 | `0444` | `b8b27dd1842a960698de8b9fc2f66fb29cf863aa8cfb3faa283e1cfe8ed4ca40` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.cwd.txt` | 23 | `0444` | `0e1ea70040234514d54c24539ae63de2b78042567c3ca45697f85dbac7dab734` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.end.utc` | 21 | `0444` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.environment.txt` | 272 | `0444` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.records.tsv` | 1,370 | `0444` | `a00bc09f13770adbb46e3843301d2848e854c8ac533ac34200e6bcb9cf35d16b` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.start.utc` | 21 | `0444` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.status` | 2 | `0444` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.stderr.raw` | 0 | `0444` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.driver.stdout.raw` | 0 | `0444` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.command.txt` | 8,191 | `0444` | `a27b2dfc823b0fff653d7c57ba73912d3810f7ace6d7f76694567b9df3825815` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.cwd.txt` | 23 | `0444` | `0e1ea70040234514d54c24539ae63de2b78042567c3ca45697f85dbac7dab734` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.end.utc` | 21 | `0444` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.environment.txt` | 272 | `0444` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.records.tsv` | 1,397 | `0444` | `db603583b4c885bae86d562e96bb4ecca69a48127daeb9f9cfb23749034b1d4f` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.start.utc` | 21 | `0444` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.status` | 2 | `0444` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.stderr.raw` | 0 | `0444` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2.preflight.stdout.raw` | 2,134 | `0444` | `1caf5c5b235793cfcc8bd0dd407a1d30f7e5a56caffde066096cf9879653c0d6` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.command.txt` | 167 | `0444` | `8218cfa2d77f6a2df537d90d16b35fd25c6fb680768801a317997596476a7ce0` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.cwd.txt` | 23 | `0444` | `0e1ea70040234514d54c24539ae63de2b78042567c3ca45697f85dbac7dab734` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.end.utc` | 21 | `0444` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.environment.txt` | 272 | `0444` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.records.tsv` | 1,547 | `0444` | `11ccd4472fee45d4bd1021218f9fe6eed4d20460ec9f9ba3af6de391a6112754` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.start.utc` | 21 | `0444` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.stderr` | 44 | `0444` | `ad1a8bf0b621f34815d1a15ad0dd583b9f78c213dd86a47daa15502ede75aeeb` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/worktree-add.stdout` | 70 | `0444` | `d16e7f9d63cc1f47a125f3de3776d87e902173e5529037bc18834cdf8616aff9` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/worktree-add.status` | 2 | `0444` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.command.txt` | 424 | `0644` | `1bcdc0771c77407bc6e793ecd76d2925c90e62f694aa58e1243e68824c68f44d` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.cwd.txt` | 23 | `0644` | `0e1ea70040234514d54c24539ae63de2b78042567c3ca45697f85dbac7dab734` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.end.utc` | 21 | `0644` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.environment.txt` | 272 | `0644` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.start.utc` | 21 | `0644` | `afd078a16b495be7efd2f5ac239e9e55e1b757a98e8f4ebde94108f93b7efe67` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.stderr` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.stdout` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/source-preflight.status` | 2 | `0644` | `4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865` |

The registered detached source remains clean and exact:

```text
path=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/source
head=43de59b06ca3a687368bfaf0595c5759c8ab3a57
tree=d56a8d1aad6c8c80b9106fa3ee9bf8b10630fc2f
detached=true
porcelain_bytes=0
```

The root, canonical, records, manifests, comparisons, build, artifact, and
three repetition directory skeletons exist at mode `0755`. Outside the
registered detached source and the exact files above, every build,
artifact, comparison, manifest, repetition, identity, and coverage output
is absent. In particular:

```text
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/records/source-preflight.records.tsv=absent
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/build/build.status=absent
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/artifact/z_llvm=absent
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/repetition-1/accepted.ll=absent
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/canonical/o2_calls_crt_v1_r131.identities.tsv=absent
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2/coverage=absent
restoration_outputs=absent
read_only_retention_outputs=absent
```

No v2 byte or mode was repaired, normalized, chmodded, removed, renamed,
copied, or reused. The registered worktree was not unregistered. V2 is
immutable historical evidence only and is prohibited as a future
validation, restoration, provenance, or generated-path input.

```text
v2_attempt=EXHAUSTED_IMMUTABLE
v2_canonical=FAIL_CLOSED_AT_SOURCE_PREFLIGHT
v2_coverage=NOT_ENTERED
v2_validation=INCOMPLETE
v3_execution=NOT_AUTHORIZED_OR_RUN
production=UNCHANGED_DORMANT
ratchet=131
```

## 15.1 INBOX-188 exhausted-v1 compliant-stop record

INBOX-188 started from clean tracked operating commit `d0c1d262` above
accepted INBOX-187C document commit `8411478a`. Its sole v1 execution
attempt stopped at C01 before any validation root, detached worktree,
build, repetition, identity, coverage, or restoration path was created.
The committed compliant-stop evidence is
`59d9cb335f37fdb1df07bb25769a551760c4207a`; its summary SHA-256 is
`802990e44f4a283a0d2bc95568b1602dfa108d97e1c13c36d792fca0d6002c24`.

The eight retained v1 files are immutable historical evidence:

| Exact path | Bytes | Mode | SHA-256 |
|---|---:|---:|---|
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.command.txt` | 7,590 | `0644` | `6e0b79fe54a666343a35159c76ee9a535d0725fa33d7c7a6cd722beb3b3b6500` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.environment.txt` | 272 | `0644` | `2eb1eedb2c1d2c52fe21e6540ca227bdff057c23a62c531a057ddc3ed7783202` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.cwd.txt` | 23 | `0644` | `0e1ea70040234514d54c24539ae63de2b78042567c3ca45697f85dbac7dab734` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.start.utc` | 21 | `0644` | `8c706bdca3eb50fa2ce3c51d1d6ad236323995ca6e48f351c9d029af7bafea8d` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.end.utc` | 21 | `0644` | `8c706bdca3eb50fa2ce3c51d1d6ad236323995ca6e48f351c9d029af7bafea8d` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.stdout.raw` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.stderr.raw` | 0 | `0644` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.status` | 2 | `0644` | `4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865` |

The following v1 outputs were and remain absent:

```text
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.preflight.records.tsv
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.command.txt
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.environment.txt
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.cwd.txt
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.start.utc
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.end.utc
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.stdout.raw
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.stderr.raw
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.status
tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v1.driver.records.tsv
```

The attempted C01 failed its first tracked-tree assertion because the
sanitized `HOME` exposed the preexisting untracked `.claude/` tooling
path. It produced no semantic output. Static inspection then established
that its separately assigned `preflight_program` passed AWK field programs
through an extra shell evaluation and corrupted literal `$1` before the
unreached immutable-input checks. The v1 namespace is therefore exhausted:
none of the eight files or absent paths may be rerun, repaired, chmodded,
copied, renamed, rewritten, normalized, deleted, or reused as a v2
input/output.

## 15.2 INBOX-189 v2 portability and serialization closure record

INBOX-189 started from clean tracked operating commit
`b7eaafa7230bc4d2b6305f99fbbcac757258a067`, whose parent is the accepted
INBOX-188 compliant-stop commit
`59d9cb335f37fdb1df07bb25769a551760c4207a`. The only tracked INBOX-189
change is this contract.

The v2 correction is closed as follows:

1. every future generated path and both external record prefixes use
   `baseline_validation_v2`;
2. C01 binds the exact future-authorized tracked `HEAD` through the single
   launcher token and checks worktree, cached/index, and tracked-only
   porcelain cleanliness plus the frozen tracked-source manifest;
3. C01 is one direct `/bin/bash -c` vector with `_` as `$0`, the complete
   `$1`–`$5` ledger in section 7.4, and literal protected AWK programs;
4. no `preflight_program`, `eval`, or equivalent re-evaluation layer
   remains;
5. all 45 templates retain one explicit `_`, closed positional/variable/
   AWK bindings, producer-before-consumer order, and one status producer;
   and
6. the executable blocks and generated-ledger entries in sections 4–12
   contain no `baseline_validation_v1` reference, while section 15.1 is the
   sole historical-v1 path ledger.

The static/read-only audit observed:

```text
starting_head=b7eaafa7230bc4d2b6305f99fbbcac757258a067
starting_parent=59d9cb335f37fdb1df07bb25769a551760c4207a
retained_v1_files=8_exact
v1_records_manifest=absent
v1_root=absent
v1_driver_records=absent
v2_root=absent
v2_preflight_records=absent
v2_driver_records=absent
canonical_bash_c_templates=27
coverage_bash_c_templates=18
explicit_bash_c_sentinels=45
canonical_bash_syntax_status=0
coverage_bash_syntax_status=0
c01_serialized_argv_count=9
c01_child_body_sha256=bdd8af559a93383a6d0cafde2931bc4e6a2083095a819ca0bf8e28bd2ce54f12
c01_child_bash_syntax_status=0
c01_literal_awk_print_field_programs=13
c01_literal_awk_stash_programs=1
c01_total_awk_programs=14
future_executable_v1_path_references=0
preflight_program_references_in_future_driver=0
eval_references_in_future_driver=0
bundle_manifest_mode_bytes_sha256=0444/2519/0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
combined_patch_mode_bytes_sha256=0444/41140/7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
combined_patch_apply_check_status=0
adopted_input_mode_bytes_sha256=0444/1897410/9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_mode_bytes_sha256=0444/4394/500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
reproduction_manifest_mode_bytes_sha256=0664/458294/885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_mode_bytes_sha256=0664/3051/1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
watcher_head_index_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
source_surface_diff_from_43de59b0=empty
ratchet=131
```

INBOX-189 ran only static/read-only inspection. It ran no project code,
build, Zig command, `z_llvm`, validation, coverage, guard/test/gate,
performance, production wiring, retention reporter, cleanup, deletion, or
credit.

```text
contract=V2_PREFLIGHT_CORRECTED_PENDING_WATCHER_REVIEWER_ACCEPTANCE
v1_attempt=EXHAUSTED_IMMUTABLE
v2_execution=NOT_AUTHORIZED_OR_RUN
canonical_identity=NOT_YET_DEFINED
coverage=NOT_RUN
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_BEFORE_V2_EXECUTION
```

## 16. INBOX-187C argument-binding closure record

INBOX-187C started from clean tracked operating commit
`d34fd6dee198f5f8e823b2d8b842d4d142b221a8`, whose parent is the
withheld INBOX-187B document commit
`22da533a8b7ee5596671beb91dd4f5575e5708b9`. The operating delta from
that parent is only `docs/next_steps.md`; the INBOX-187B contract blob had
SHA-256
`26ef0df76e087487331318dd99d87e99e3907c42aa044ca9428be9624a262512`.
The only tracked INBOX-187C change is this contract.

The static audit found and corrected exactly two defects in the same
argument-binding class:

1. the canonical owner-ledger now binds Bash `$3` as `summary` and passes
   the exact `$REP/report.summary.txt` path to AWK with
   `-v summary="$summary"` before `getline`; and
2. the canonical grouped-frontier parser no longer binds its unrelated
   temporary-output argument as an unused AWK variable named `summary`.

Section 7.4 maps all 45 `/bin/bash -c` templates: 27 canonical and 18
coverage templates. Each row records the literal `_` `$0` sentinel, every
positional argument, every shell alias, every AWK binding and input,
producer-before-consumer placement, and its sole status producer. The
static closure check found 45 command templates, 45 explicit sentinels, 27
canonical ledger rows, and 18 coverage ledger rows. Both the concatenated
sections 5–6 canonical Bash stream and the concatenated sections 8–9
coverage Bash stream pass `/bin/bash -n`.

The final read-only recheck observed:

```text
starting_head=d34fd6dee198f5f8e823b2d8b842d4d142b221a8
starting_parent=22da533a8b7ee5596671beb91dd4f5575e5708b9
bundle_manifest_mode_bytes_sha256=0444/2519/0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
bundle_manifest_check_status=0
combined_patch_mode_bytes_sha256=0444/41140/7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
combined_patch_apply_check_status=0
bundle_root_mode=0555
bundle_payload_modes=0444
adopted_input_mode_bytes_sha256=0444/1897410/9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_mode_bytes_sha256=0444/4394/500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
reproduction_manifest_mode_bytes_sha256=0664/458294/885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_mode_bytes_sha256=0664/3051/1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
retention_policy_mode_bytes_sha256=0664/10622/a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd
cleanup_source_mode_bytes_sha256=0664/50100/8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e
watcher_head_index_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
pinned_zig_head=bdee02bc0c7f227c0f11bc9a449df673fe803540
pinned_zig_tree=aa032b2b82a48a4684657f909e6e270a6c925e33
pinned_stage4_mode_bytes_sha256=0775/530327885/dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7
source_surface_diff_from_43de59b0=empty
bypass_inventory_sha256=2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
facade_manifest_sha256=2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26
canonical_bash_c_templates=27
coverage_bash_c_templates=18
explicit_bash_c_sentinels=45
canonical_bash_syntax_status=0
coverage_bash_syntax_status=0
ratchet=131
```

INBOX-187C ran no project code, build, Zig command, `z_llvm`,
selector/report, object generation, guard/test/gate, validation, coverage,
performance, protocol adoption, production wiring, pin edit, cleanup, or
credit. The future post-calls checkpoint changes no authority in this
slice.

```text
contract=ARGUMENT_BINDINGS_CORRECTED_PENDING_WATCHER_REVIEWER_ACCEPTANCE
patch_bundle=UNCHANGED_ACCEPTED
canonical_identity=NOT_YET_DEFINED
coverage=NOT_RUN
validation=NOT_RUN
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_BEFORE_VALIDATION_EXECUTION
```

## 18. INBOX-191 v3 source-commit and namespace closure record

INBOX-191 started from exact clean tracked operating commit
`85386b77acfc915f7de4b3efd8f19dab89907a77`, immediately above accepted
INBOX-190 compliant-stop commit
`49bbb9d0bb7d0fb70e0654eddbacae0fd58ddd0c`. It changes only this
contract. No v1/v2 byte, mode, absence, registered worktree, or retained
path changed.

The future contract correction is closed as follows:

1. every future generated root, detached worktree, external prefix,
   record, output, status, manifest, comparison, and generated-ledger path
   uses the fresh `baseline_validation_v3` namespace;
2. the canonical complete stream binds literal full commit
   `43de59b06ca3a687368bfaf0595c5759c8ab3a57` once, validates its exact
   40-lowercase-hex form, passes it to C01 and C02, and uses it for the
   canonical worktree revision;
3. the coverage complete stream independently binds that same literal
   once, validates it, uses it for worktree creation and restoration, and
   passes it as the sole section-9 launcher argument; the child revalidates
   the passed value without repeating the literal;
4. C01 uses the bound source identity for the main-tree provenance diff,
   C02 compares full `rev-parse HEAD` to its passed `$2`, and both coverage
   creation and restoration compare full `rev-parse HEAD` to the bound
   value;
5. future executable blocks contain no short source equality and no v1/v2
   generated-path reference; and
6. sections 15.1 and 17 retain the immutable exhausted-v1/v2 ledgers for
   review only, never as executable inputs, outputs, restoration targets,
   or provenance sources.

The explicit binding changes are:

```text
canonical_source_literal_bindings=1
coverage_source_literal_bindings=1
C01_serialized_argv_count_before=9
C01_serialized_argv_count_after=10
C01_new_position=$6_SOURCE_COMMIT
C02_source_positions_before=1
C02_source_positions_after=2
C02_new_position=$2_SOURCE_COMMIT
coverage_section9_launcher_source_args_before=0
coverage_section9_launcher_source_args_after=1
canonical_bash_c_template_count_change=0
coverage_bash_c_template_count_change=0
```

The static/read-only audit observed:

```text
starting_head=85386b77acfc915f7de4b3efd8f19dab89907a77
starting_parent=49bbb9d0bb7d0fb70e0654eddbacae0fd58ddd0c
INBOX_190_summary_sha256=5cf4b9bb2ba4d4ada1f00aca07e083e5ca7624a7e803addbc0e560f7b1bd2e57
retained_v2_regular_file_rows=35_exact
retained_v2_source_head=43de59b06ca3a687368bfaf0595c5759c8ab3a57
retained_v2_source_tree=d56a8d1aad6c8c80b9106fa3ee9bf8b10630fc2f
retained_v2_source_porcelain_bytes=0
retained_v2_source_preflight_records_manifest=absent
retained_v2_build_artifact_repetition_identity_coverage_outputs=absent
v3_root=absent
v3_external_prefix_files=0
source_commit_object_type=commit
future_authorization_token_count=1
future_old_authorization_token_count=0
canonical_source_literal_bindings=1
coverage_source_literal_bindings=1
future_short_source_equalities=0
future_executable_v1_v2_path_references=0
canonical_bash_c_templates=27
coverage_bash_c_templates=18
canonical_ledger_rows=27
coverage_ledger_rows=18
explicit_bash_c_sentinels=45
canonical_bash_syntax_status=0
coverage_bash_syntax_status=0
canonical_stream_sha256=9fecf6990636f2bf4b7a325e951260a4ce7ee34964aedd739d2f6aa3a7e53a18
coverage_stream_sha256=e8a1871bf46f50ef0533062a9af068724a56dddc71d433b5c4514fb8c2d70b2e
future_sections_4_through_12_sha256=19aa3977192974d1e34964a7de345c5a5fb5f98fb3dda86495c4b168e55d4dbd
C01_direct_block_sha256=f5548043edeaa575a8398d144ec8a576bd91a2726294eff3489a15f39ddbbf5b
C01_literal_awk_print_field_programs=13
C01_literal_awk_stash_programs=1
C01_total_awk_programs=14
bundle_manifest_check_status=0
combined_patch_apply_check_status=0
bundle_manifest_mode_bytes_sha256=0444/2519/0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0
combined_patch_mode_bytes_sha256=0444/41140/7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f
adopted_input_mode_bytes_sha256=0444/1897410/9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_mode_bytes_sha256=0444/4394/500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
reproduction_manifest_mode_bytes_sha256=0664/458294/885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_mode_bytes_sha256=0664/3051/1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
watcher_head_index_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
production_surface_diff_from_full_source_commit=empty
ratchet=131
```

INBOX-191 ran only static/read-only inspection, Bash syntax checks,
identity and absence checks, and the accepted bundle apply check. It ran
no project code, build, Zig command, `z_llvm`, validation, coverage,
guard/test/gate, performance, protocol adoption, production wiring,
retention reporter, cleanup, deletion, or credit.

```text
contract=V3_SOURCE_IDENTITY_AND_NAMESPACE_CORRECTED_PENDING_REVIEW
v1_attempt=EXHAUSTED_IMMUTABLE
v2_attempt=EXHAUSTED_IMMUTABLE
v3_execution=NOT_AUTHORIZED_OR_RUN
canonical_identity=NOT_YET_DEFINED
coverage=NOT_RUN
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_BEFORE_V3_EXECUTION
```

## 19. INBOX-196 durability-authority amendment

### 19.1 Disposition and immutable authority

This amendment started from exact operating commit
`bd8c67029041921f26dc4d92b504862e6d203c96`, whose exact parent is
`a22f027081cf491969c7448ad80dae4d6e54c67e`. INBOX-195C and the calls-input
publication are accepted. The following bytes are immutable:

```text
tracked_live_manifest=docs/evidence/artifact_manifest_v1.tsv
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
generation_manifest=/home/oleg/prog/z_llvm-artifacts/manifests/generation-00000001.tsv
generation_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
real_store_inventory_sha256=3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
real_store_file_ledger_sha256=a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65
INBOX_195C_record_count=75
INBOX_195C_record_ledger_sha256=e80b6a5f540451529bbed0612b60d53cae822ccf3d08a92159a522c9239293ae
frozen_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
accepted_durability_audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
pre_amendment_contract_sha256=448482a91a47f00cfd0c0e89d73c5c7332a49beb21906e529914913491f383ba
ratchet=131
```

The byte-identical tracked live manifest and authoritative generation manifest
are jointly the sole artifact authority. Both must exist, be regular immutable
files, have the frozen hash above, and compare byte-for-byte before any later
resolution. A disagreement or missing side is a hard stop. An object path,
snapshot path, compatibility path, `tmp/` path, retained record, source
specification, or proposed manifest is never authority by itself.

The mapping columns below have these closed meanings:

- **Logical ID** is the only caller-visible durable name. A family ending in
  `<...>` is a finite future-required definition, not a wildcard accepted by
  the authority.
- **Authority** is either an accepted active manifest row, protected Git
  control state, or `future-required / absent`. No fourth authority exists.
- **Class** is one of the four accepted retention classes:
  `canonical-input`, `irreplaceable-acceptance-evidence`,
  `reproducible-cache`, or `ephemeral-scratch`; protected control state is
  explicitly outside all four.
- **Access** is read-only resolution, atomic no-overwrite compatibility
  materialization, producer-only creation, or protected-control access.
- **Producer** is the sole producer. A generated group never includes its own
  publisher, receipt, publication log, or publication verification.
- **Consumers** is exhaustive at the family grain.
- **Compatibility** describes a non-authoritative local path. Equality never
  promotes that path to authority.
- **WT intersection** is the registered-worktree result. `protected` means
  excluded from every artifact operation; `none required` must be re-proved
  against a frozen registration set before every later write.
- **Later permission** states the minimum separate authorization. This
  amendment grants none.

### 19.2 Accepted active inputs: all 19 logical references

Every authority cell below means the matching active logical-ref row in both
accepted manifests and its exact `target_id` object row. Each object must be
verified by key, SHA-256, bytes, immutable object mode `0444`, and media
identity before use. The source-mode value in the source specification is not
an object-mode exception.

| Logical ID | Authority | Class | Access | Producer | Consumers | Compatibility | WT intersection | Later permission |
|---|---|---|---|---|---|---|---|---|
| `calls/input/accepted-cohort-ac285/v1` | active row -> object `d8da86ca…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | retained cohort identity checks only; not the v3 raw input | existing `tmp/inbox63_accepted_cohort.ll` may be read only after resolution and exact byte/mode verification | none required; re-freeze | later resolver/materializer directive |
| `calls/input/compiler-rt-v1/raw/adoption-final/v1` | active row -> object `00cee290…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | immutable-input provenance preflight and final review | existing `tmp/o2_calls_perf/compiler_rt_v1/adoption_final.sha256` is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/compiler-rt-v1/raw/adoption-manifest/v1` | active row -> object `500e73c8…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | immutable-input provenance preflight and final review | existing `tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv` is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/compiler-rt-v1/raw/module/v1` | active row -> object `9b8d6993…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | `$INPUT`; all three canonical raw-report producers and both coverage raw-report producers | existing `tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll` may be reused only after exact resolve/verify | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/baseline-source.sha256/v1` | active row -> object `c918f0f4…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage source creation, restoration, and identity checks | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer and protected-path directives |
| `calls/input/validation-v3/coverage-bundle/manifests/bundle-files.sha256/v1` | active row -> object `0576d580…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | bundle completeness preflight and coverage source preparation | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/bundled-source.sha256/v1` | active row -> object `0b216fc8…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage source apply proof | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/combined-apply-source.sha256/v1` | active row -> object `0b216fc8…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | combined-patch source proof | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/future-tool-identities.sha256/v1` | active row -> object `05ea0083…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | future tool identity preflight | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/patch-manifest.tsv/v1` | active row -> object `7717db66…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | ordered coverage patch validation | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/payload-final-modes.tsv/v1` | active row -> object `0ece5ced…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage payload mode validation | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/preflight-and-apply-proof.txt/v1` | active row -> object `d03c18a2…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage patch preflight proof | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/restored-source.sha256/v1` | active row -> object `c918f0f4…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage restoration proof | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer and protected-path directives |
| `calls/input/validation-v3/coverage-bundle/manifests/sequential-apply-source.sha256/v1` | active row -> object `0b216fc8…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | sequential-patch source proof | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer directive |
| `calls/input/validation-v3/coverage-bundle/manifests/touched-paths.txt/v1` | active row -> object `9f755c67…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage source touched-path fence | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer and protected-path directives |
| `calls/input/validation-v3/coverage-bundle/patches/01-aggregate-consumer.patch/v1` | active row -> object `8b5750fa…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage source sequential apply and combined-patch equivalence | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer and protected-path directives |
| `calls/input/validation-v3/coverage-bundle/patches/02-fixed-observer.patch/v1` | active row -> object `db05812e…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage source sequential apply and combined-patch equivalence | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer and protected-path directives |
| `calls/input/validation-v3/coverage-bundle/patches/03-exact-combined-guard.patch/v1` | active row -> object `9263f132…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | coverage source sequential apply and combined-patch equivalence | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer and protected-path directives |
| `calls/input/validation-v3/coverage-bundle/patches/aggregate-consumer-observer-guard.patch/v1` | active row -> object `7508d1d8…` | canonical-input | read-only resolve/verify | accepted INBOX-195 publication | `$BUNDLE`; coverage source sole accepted combined apply | matching bundle path is non-authoritative | none required; re-freeze | later resolver/materializer and protected-path directives |

### 19.3 Accepted snapshots

The snapshot rows are alternative integrity/retention proofs for the same
accepted objects, not a second authority and not permission to extract.

| Logical ID | Authority | Class | Access | Producer | Consumers | Compatibility | WT intersection | Later permission |
|---|---|---|---|---|---|---|---|---|
| `snapshot/calls-inputs/v1` | active snapshot row `a545221b…`, exact constituent `1d5aa3cc…`, four exact members | canonical-input | read-only whole-snapshot verification | accepted INBOX-195 publication | future durability preflight for AC285 and compiler-rt core inputs | no extraction or compatibility destination authorized | none required; re-freeze | later standalone-verifier directive |
| `snapshot/calls-validation-inputs/v1` | active snapshot row `69593839…`, exact constituent `e7e26c87…`, twelve exact members | canonical-input | read-only whole-snapshot verification | accepted INBOX-195 publication | future durability preflight for the coverage bundle | no extraction or compatibility destination authorized | none required; re-freeze | later standalone-verifier directive |

### 19.4 Protected control paths and namespace containers

`$PARENT` remains
`/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1` and `$ROOT` remains
`$PARENT/baseline_validation_v3`. These names are protocol namespaces, not
artifact identities. The following mapping is exhaustive for parents, roots,
and protected source paths:

| Logical ID | Authority | Class | Access | Producer | Consumers | Compatibility | WT intersection | Later permission |
|---|---|---|---|---|---|---|---|---|
| none: `$PARENT` | main-tree filesystem namespace only | ephemeral-scratch container | later no-follow parent validation only | pre-existing main tree | external preflight/driver and `$ROOT` containment | not resolvable from artifact authority | main worktree; never an artifact row | later path-specific directive |
| none: `$ROOT` | future v3 namespace, currently absent | ephemeral-scratch container | later atomic namespace creation only | future authorized bootstrap | canonical and coverage containers | not resolvable from artifact authority | main worktree untracked area; re-freeze | later path-specific directive |
| none: `$ROOT/canonical` | future canonical container | mixed children; container has no class | producer-only directory creation | future canonical bootstrap | canonical groups only | no artifact row | none required before source registration; re-freeze | later path-specific directive |
| none: `$ROOT/coverage` | future coverage container | mixed children; container has no class | producer-only directory creation | future coverage bootstrap after canonical success | coverage groups only | no artifact row | none required before source registration; re-freeze | later path-specific directive |
| none: `$ROOT/canonical/source` | Git commit `43de59b06ca3a687368bfaf0595c5759c8ab3a57` only | protected control; outside four classes | Git worktree control access only | separately authorized `git worktree add` | source preflight, canonical build, restoration proof | **never** an object, snapshot, resolver input, or compatibility destination | protected registered worktree | separate explicit user permission naming this exact path for creation; separate permission again for modification or removal |
| none: `$ROOT/coverage/source` | same Git commit plus accepted bundle transformation proof | protected control; outside four classes | Git worktree control access only | separately authorized worktree creation and bundle application | coverage build and restoration proof | **never** an object, snapshot, resolver input, or compatibility destination | protected registered worktree | separate explicit user permission naming this exact path for creation; separate permission again for modification or removal |

No durability pre-wrapper, post-wrapper, resolver, verifier, publisher, or
finalizer may create, enter, inspect recursively, hash, classify, copy,
materialize, publish, repair, remove, or prune either protected `source` path.
Registration topology must be frozen outside those paths. Any intersection
between a proposed artifact/compatibility path and any registered worktree is a
hard stop.

### 19.5 Complete finite future-v3 output mapping

The following rows close every path family in accepted contract sections 7.2
and 7.3 and accepted audit section 12. Each logical-ID family is
`future-required / absent`: it creates no live row, object, snapshot, or
authority in this amendment. Angle-bracket domains are finite:

- `<external-kind>` is exactly `preflight` or `driver`;
- `<external-name>` is exactly `command.txt`, `environment.txt`, `cwd.txt`,
  `start.utc`, `end.utc`, `stdout.raw`, `stderr.raw`, `status`, or
  `records.tsv`;
- `<N>` is exactly `1`, `2`, or `3`;
- `<step>` is one of the exact 27 canonical or 18 coverage ledger step names
  frozen in sections 7.2 and 7.3;
- `<record-part>` is exactly `command`, `environment`, `cwd`, `start`, `end`,
  `stdout`, or `stderr`;
- `<function-id>` is drawn only from the corresponding bytewise-sorted
  generated function manifest;
- `<channel>` is exactly `report`, `object`, or `owner`.

| Logical ID / contract path family | Authority | Class | Access | Producer | Consumers | Compatibility | WT intersection | Later permission |
|---|---|---|---|---|---|---|---|---|
| `calls/validation-v3/<external-kind>/<external-name>/v1`; `$PARENT/baseline_validation_v3.<external-kind>.<external-name>` | future-required / absent | irreplaceable-acceptance-evidence | producer writes once; post-wrapper may publish only after group closure | sole external preflight or driver launcher | bootstrap review and terminal evidence | external prefix is eventual atomic no-overwrite compatibility path | none required; re-freeze | future-output publisher plus path-specific directive |
| none; `$ROOT/{canonical,coverage}/{records,manifests,comparisons,build,artifact,reference,observation-off,observation-on}` parents | namespace only | mixed container | producer-only directory creation | exact phase bootstrap | contained finite groups | no artifact row for directory alone | none required; re-freeze | later path-specific directive |
| `calls/validation-v3/canonical/cache/<tree-path>/v1`; `$ROOT/canonical/build/{cache,prefix}/**` | future-required / absent | reproducible-cache | producer writes; optional later publish | sole canonical build | canonical artifact build only | local build path; never acceptance authority | none required; re-freeze | later build and optional publisher directive |
| `calls/validation-v3/canonical/repetition-<N>/{home,tmp}/<tree-path>/v1`; repetition working trees | future-required / absent | ephemeral-scratch unless a fail-stop separately promotes exact records | producer working access | corresponding report producer | that producer only | no durable compatibility promise | none required; re-freeze | later validation directive |
| `calls/validation-v3/canonical/artifact/z_llvm/v1`; `$ROOT/canonical/artifact/z_llvm` | future-required / absent | canonical-input | producer writes; later consumers resolve exact immutable object | sole canonical build/install | all canonical and coverage report/object/owner producers | path becomes compatibility copy only after publication | none required; re-freeze | later build, publisher, and compatibility directives |
| `calls/validation-v3/canonical/artifact/identity/v1`; `artifact.identity.tsv` | future-required / absent | irreplaceable-acceptance-evidence | producer writes once | canonical artifact identity step | canonical/coverage preflight and final review | atomic no-overwrite copy after publication | none required; re-freeze | later publisher directive |
| `calls/validation-v3/canonical/step/<step>/status/v1` and `/record/<record-part>/v1`; exact canonical status and record paths | future-required / absent | irreplaceable-acceptance-evidence | each exact path has one producer | corresponding `run_step` | step validator, canonical finalizer, review | no synthesized missing member; group copy after close | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/canonical/build/{stdout,stderr,status}/v1`; exact build records | future-required / absent | irreplaceable-acceptance-evidence | sole build launcher | canonical build | artifact identity and review | group copy after close | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/canonical/repetition-<N>/raw-report/<name>/v1`; `report.{stdout,stderr,status,summary}`, failure and frontier files | future-required / absent | irreplaceable-acceptance-evidence | exact report/parser producer writes once | repetition `<N>` raw report and parsers | report comparison, accepted subset, finalizer | sealed repetition report-proof group | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/canonical/accepted-ll/object/v1`; `repetition-1/accepted.ll` | future-required / absent | canonical-input | produced exactly once, then read-only | repetition-1 accepted-subset extraction | all canonical object/owner and both coverage phases | atomic no-overwrite compatibility copy after publication | none required; re-freeze | later validation, publisher, and compatibility directives |
| `calls/validation-v3/canonical/accepted-ll/proof/<name>/v1`; extract/freeze/identity records | future-required / absent | irreplaceable-acceptance-evidence | each proof has one producer | repetition-1 accepted-subset finalizer | canonical and coverage preflight, review | sealed with accepted-ll proof group | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/canonical/repetition-<N>/successful-subset/{accepted.o,owner.tsv,objdump,readelf,text,functions-manifest,owner-ledger}/v1` | future-required / absent | irreplaceable-acceptance-evidence | exact sole producers | repetition object/owner/inspection steps | identity and comparison finalizers | sealed repetition successful-subset group | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/canonical/repetition-<N>/function/<function-id>/{bytes,disassembly,identity}/v1` | future-required / absent, finite manifest-derived IDs | irreplaceable-acceptance-evidence | sole per-function extractor | repetition per-function step | 285/0/0 comparisons and finalizer | membership must equal frozen sorted function manifest | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/canonical/comparison/<name>/v1`; `$CANONICAL/comparisons/*` | future-required / absent | irreplaceable-acceptance-evidence | sole comparison step | exact canonical comparator | canonical finalizer and review | publish only after all inputs exist | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/canonical/identities/v1`; canonical identity TSV | future-required / absent | canonical-input and irreplaceable-acceptance-evidence | sole identity finalizer | canonical three-repetition equality step | coverage reference/off/on comparisons and review | atomic no-overwrite compatibility copy after publication | none required; re-freeze | later validation, publisher, and compatibility directives |
| `calls/validation-v3/canonical/repetition-<N>/final-manifest/v1` and `canonical/final-manifest/v1` | future-required / absent | irreplaceable-acceptance-evidence | sole repetition or canonical finalizer | corresponding finalizer | review and coverage preflight | publication only after semantic group closes | none required; re-freeze | later validation and publisher directives |
| `calls/validation-v3/coverage/cache/<tree-path>/v1`; `$ROOT/coverage/build/{cache,prefix}/**` | future-required / absent | reproducible-cache | producer writes; optional later publish | sole coverage build | coverage artifact build only | local build path; excluded from performance | none required excluding protected source; re-freeze | later build and optional publisher directive |
| `calls/validation-v3/coverage/artifact/{z_llvm,identity}/v1`; coverage artifact paths | future-required / absent | canonical-input for coverage only; identity proof is evidence | producer writes; read-only by off/on | sole coverage build/install | observation-off and observation-on producers | compatibility only after publication; excluded from performance | none required excluding protected source; re-freeze | later build, publisher, compatibility directives |
| `calls/validation-v3/coverage/reference/<name>/v1`; reference identity/channel/accepted checks | future-required / absent | irreplaceable-acceptance-evidence | sole reference producer | coverage bootstrap from canonical identities | off/on validators and finalizer | sealed reference group | none required; re-freeze | later coverage and publisher directives |
| `calls/validation-v3/coverage/off/step/<step>/{status,record-<record-part>}/v1` and `/semantic/<name>/v1`; all `$OFF` outputs | future-required / absent | irreplaceable-acceptance-evidence | sole off producer per path | observation-off stream | on comparator and coverage finalizer | channels must be absent before and after off | none required; re-freeze | later coverage and publisher directives |
| `calls/validation-v3/coverage/on/channel/<channel>/v1`; exact three `*.coverage.tsv` paths | future-required / absent | irreplaceable-acceptance-evidence | each path has exactly one producer | corresponding observation-on report/object/owner producer | counter validators only | absent before sole producer; no fallback/cross-channel reuse | none required; re-freeze | later coverage and publisher directives |
| `calls/validation-v3/coverage/on/step/<step>/{status,record-<record-part>}/v1` and `/semantic/<name>/v1`; remaining `$ON` outputs | future-required / absent | irreplaceable-acceptance-evidence | sole on producer per path | observation-on stream | equality/counter checks and finalizer | sealed on group after exact semantic equality | none required; re-freeze | later coverage and publisher directives |
| `calls/validation-v3/coverage/{off,on}/function/<function-id>/{bytes,disassembly,identity}/v1` | future-required / absent, finite manifest-derived IDs | irreplaceable-acceptance-evidence | sole phase extractor | off or on per-function step | canonical/off/on equality and finalizer | membership must equal the canonical sorted manifest | none required; re-freeze | later coverage and publisher directives |
| `calls/validation-v3/coverage/comparison/<name>/v1`; off/on/canonical comparisons and counter validations | future-required / absent | irreplaceable-acceptance-evidence | sole comparison producer | coverage comparator | coverage finalizer and review | publish only after all compared inputs exist | none required; re-freeze | later coverage and publisher directives |
| `calls/validation-v3/coverage/{off,on}/final/v1` and `coverage/final/v1`; `*.files.sha256`, `*.final.tsv`, `final-manifests.sha256` | future-required / absent | irreplaceable-acceptance-evidence | sole phase/final finalizer | exact off, on, or coverage finalizer | terminal review | final coverage semantic group, excluding publication evidence | none required; re-freeze | later coverage and publisher directives |
| `calls/validation-v3/publication/<group-id>/{command,environment,stdout,stderr,status,receipt,verification}/v1` | future-required / absent | irreplaceable-acceptance-evidence | post-wrapper only | separately authorized publisher/verifier after group closure | terminal durability ledger | never included in `<group-id>` itself | none required; re-freeze | later publisher/verifier directive |
| `calls/validation-v3/durability-terminal/v1` | future-required definition only; deliberately not publishable | irreplaceable-acceptance-evidence | terminal review only | finite ledger over all expected publication groups | human/Reviewer acceptance | no compatibility copy and no self-publication | none required; re-freeze | later terminal-evidence directive |

Any future-v3 path not matched by the exact finite domains above has no logical
ID, no authority, no producer, and no compatibility permission. It fails
closed. A function-ID family cannot be instantiated until its one sorted
function manifest exists; the manifest closes the set and is itself outside
that member family.

### 19.6 Compatibility-copy contract

An existing regular `tmp/` file is usable only through this ordered
pre-wrapper contract:

1. freeze the exact 43-registration topology without entering any non-main
   registered worktree;
2. establish the sole manifest pair and exact equality from section 19.1;
3. resolve exactly one active logical ID; reject zero rows, duplicates,
   non-active status, unexpected kind, ambiguous targets, a missing target
   object/snapshot/member, or any field mismatch;
4. no-follow every authority and destination ancestor; reject symlinks,
   non-directories, unsafe or non-canonical traversal, registered-worktree
   intersection, and changed registration;
5. verify the authoritative object/snapshot by key, SHA-256, bytes, immutable
   mode, media, constituent recipe, and complete member relationships as
   applicable;
6. if the compatibility destination is an existing regular file, require its
   exact bytes and reviewed compatibility mode and allocate/write nothing;
7. if absent, require fresh capacity and path-specific authorization, create
   an authority-verified incoming file in the same destination directory,
   set and verify its final mode, sync it, publish with atomic no-replace,
   sync the directory ancestry, and re-read/verify the final;
8. if the destination exists as stale/mismatched bytes or mode, a symlink,
   directory, other node, or appears during publication, retain it unchanged
   and fail closed; never replace, normalize, chmod, repair, retry, or fall
   back to another path.

This contract is intentionally not executable today. Resolution,
compatibility creation, and verification require the missing frozen-tool
surfaces in section 19.9. No shell implementation or invented CLI is accepted
as a substitute.

Every later store mutation or compatibility write additionally requires a
fresh capacity observation, the frozen registration proof, all no-follow and
path-safety proofs, explicit authorization naming the destination, and a
separate directive. Read-only equality of a historical path waives none of
those requirements.

### 19.7 Pre/post wrapper boundary and semantic-body freeze

Durability may wrap, but never enter, the accepted semantic streams:

```text
durability_preflight
  -> accepted semantic producer body, byte-for-byte unchanged
  -> accepted semantic validation/comparison, byte-for-byte unchanged
  -> durability_postpublish_for_closed_group
  -> next accepted semantic producer
```

The pre-wrapper may only resolve/verify immutable inputs and, with later
authority, establish exact compatibility copies. The post-wrapper may only
publish a fully closed finite group and verify its receipt. Neither wrapper may
change a producer environment, command, cwd, stdout, stderr, status, timing,
counter, channel presence/exclusivity, output, comparison, or equality rule.
Wrapper failure stops before the next semantic producer. Publication failure
does not rerun the producer.

No executable wrapper can be emitted with the frozen CLI. Therefore no
composed stream exists and no composed hash may be invented:

```text
canonical_semantic_body_sha256=9fecf6990636f2bf4b7a325e951260a4ce7ee34964aedd739d2f6aa3a7e53a18
coverage_semantic_body_sha256=e8a1871bf46f50ef0533062a9af068724a56dddc71d433b5c4514fb8c2d70b2e
canonical_semantic_body_change=none
coverage_semantic_body_change=none
canonical_durability_wrapper_sha256=WITHHELD_MISSING_CLI_SURFACE
coverage_durability_wrapper_sha256=WITHHELD_MISSING_CLI_SURFACE
canonical_composed_stream_sha256=WITHHELD_MISSING_CLI_SURFACE
coverage_composed_stream_sha256=WITHHELD_MISSING_CLI_SURFACE
```

This is the required hash-change record: semantic-body hashes remain frozen;
wrapper and composed hashes are not defined because defining an executable
wrapper would require invented syntax. A later contract amendment must record
exact wrapper and composed hashes after, and only after, the missing
capabilities are implemented and accepted.

The only Bash text newly specified by INBOX-196 is the fail-closed placeholder
below. It is not a validation command and cannot authorize execution:

```bash
printf '%s\n' \
  'BLOCKED: frozen artifact CLI lacks v3 resolver/materializer/publisher/verifier surfaces' >&2
exit 125
```

### 19.8 Acyclic producer/publication DAG and terminal closure

The finite DAG is:

```text
A0 accepted-manifest-pair + frozen-registration + capacity
  -> A1 resolve-and-verify accepted inputs
  -> A2 optional authorized compatibility establishment
  -> C0 external preflight group
  -> C1 protected canonical/source creation [separate explicit permission]
  -> C2 canonical build/cache
  -> C3 canonical artifact group
  -> C4 canonical repetitions 1..3
  -> C5 canonical accepted.ll and successful-subset groups
  -> C6 canonical comparisons/identities/final groups
  -> V0 resolve-and-verify coverage bundle and canonical accepted.ll
  -> V1 protected coverage/source creation [separate explicit permission]
  -> V2 coverage build/artifact/reference
  -> V3 observation-off
  -> V4 observation-on
  -> V5 coverage comparisons/counters/final groups
  -> T0 durability-terminal ledger
```

For every closed semantic group `G`, an optional post-wrapper publication node
`P(G)` depends on `G`; its verification node `Q(G)` depends on `P(G)`.
Downstream semantic consumers depend on `Q(G)` when they require durable
resolution. Neither `P(G)` nor `Q(G)` is a member of `G`. The publication
command, environment, stdout, stderr, status, receipt, and verification result
are members of the distinct finite `publication/<group-id>` evidence group.
That evidence group is listed once in `T0`; it is never published. `T0` has no
publisher, receipt, verifier, or successor and therefore terminates without
recursion.

Edges always move from a lower numbered canonical/coverage node to a higher
numbered node. `P(G)` and `Q(G)` point only forward to a consumer or `T0`.
Protected source nodes are Git control dependencies, never children of an
artifact publication node. No publication group contains itself, its own
publication evidence, or `T0`. This closes the DAG finitely.

### 19.9 Frozen-tool CLI surface audit and structural blocker

Static inspection of frozen tool
`94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859`
found exactly these command forms:

```text
zllvm-artifact-store resolve-authority
zllvm-artifact-store materialize-spec plan docs/evidence/inbox194_calls_canonical_source_spec_v1.tsv
zllvm-artifact-store materialize-spec publish docs/evidence/inbox194_calls_canonical_source_spec_v1.tsv
```

`resolve-authority` returns only the authority root. `materialize-spec` rejects
any specification path other than the frozen canonical source specification;
`plan` only renders its proposed generation; `publish` only performs the
accepted generation-1 canonical-source publication. Internal `Store` methods
are not a contract-visible command or API and cannot be called by a future
shell stream.

The following required surfaces are absent:

| Required capability | Exact missing command/API surface | Consequence |
|---|---|---|
| logical-ID resolver | no CLI accepting an accepted manifest plus one logical ID and returning/verifying its unique active object or snapshot identity | accepted inputs cannot be resolved under the sole-authority rule |
| compatibility materializer | no CLI accepting a resolved identity and separately authorized destination with atomic no-overwrite/no-follow verification | historical `tmp/` paths cannot be established or accepted by durability wrappers |
| future-output publisher | no CLI accepting a finite closed future-output group, publishing objects/snapshot, and atomically creating a later generation without rewriting generation 1 | no canonical or coverage output group can become authoritative |
| standalone verifier | no CLI verifying an existing generation manifest, object, snapshot, constituent, complete member set, registration boundary, and final compatibility result without publication | preflight, postpublication, and later-consumer verification cannot be expressed |

The existing `materialize-spec publish` command is not any of these surfaces
and must not be repurposed. Invented flags, subcommands, shell access to store
internals, direct object-path reads, and ad hoc manifest parsers are prohibited.

Therefore:

```text
mapping=COMPLETE
accepted_logical_refs=19
accepted_snapshots=2
protected_source_paths=2_EXCLUDED
future_output_families=FINITE_FUTURE_REQUIRED_ONLY
producer_publication_DAG=FINITE_ACYCLIC
terminal_evidence=FINITE_NONRECURSIVE
artifact_authority=TRACKED_LIVE_PLUS_GENERATION_MANIFEST_ONLY
frozen_cli_surface=INSUFFICIENT
structural_blockers=4
durability_wrappers=NOT_DEFINED
contract_acceptance=WITHHELD_STRUCTURAL_BLOCKER
validation_v3=NOT_AUTHORIZED_OR_RUN
```

### 19.10 Static/read-only closure record

INBOX-196 permits only static/read-only contract checks. The check set is:

1. the pre-amendment contract is a byte-exact prefix of this file;
2. this amendment names all 19 active logical references and both accepted
   snapshots;
3. every path family in contract sections 7.2 and 7.3 and accepted audit
   section 12 maps to exactly one finite row above, or is an explicitly invalid
   unlisted path;
4. no exhausted-attempt path occurs in any executable amendment block;
5. both protected source paths occur only as protected Git control rows and
   never as logical IDs, objects, snapshots, resolver inputs, publishers, or
   compatibility destinations;
6. the tracked/live and generation manifests are the sole authority;
7. every DAG edge is forward, publication evidence is disjoint from the group
   it describes, and terminal evidence is not published;
8. the frozen CLI audit is limited to source inspection and records all
   missing surfaces without invented syntax;
9. the sole new Bash block parses successfully and exits closed before any
   semantic body; and
10. only this contract differs from the operating commit.

The performed static checks recorded:

```text
operating_head=bd8c67029041921f26dc4d92b504862e6d203c96
operating_parent=a22f027081cf491969c7448ad80dae4d6e54c67e
pre_amendment_contract_bytes=168785
pre_amendment_contract_sha256=448482a91a47f00cfd0c0e89d73c5c7332a49beb21906e529914913491f383ba
pre_amendment_prefix_cmp_status=0
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
frozen_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
active_manifest_vs_mapping_diff=empty
snapshot_manifest_vs_mapping_diff=empty
active_logical_reference_rows=19
accepted_snapshot_rows=2
namespace_and_protected_control_rows=6
future_output_family_rows=27
mapping_rows_with_wrong_column_count=0
protected_source_rows=2
missing_CLI_surface_rows=4
amendment_executable_v1_v2_path_references=0
amendment_bash_syntax_status=0
diff_check_status=0
changed_tracked_paths=1
changed_tracked_path=docs/evidence/inbox187_o2_compiler_rt_v1_baseline_validation_execution_contract.md
```

No project code, artifact tool, resolver, publisher, compatibility writer,
validation, registered-worktree command, gate, performance, cleanup, wiring,
store/manifest/path/pin/source/tool/namespace mutation, ratchet action,
checkpoint action, or credit action ran in INBOX-196.

```text
INBOX_196=STATIC_DURABILITY_AUTHORITY_AMENDMENT_COMPLETE
contract_acceptance=WITHHELD_STRUCTURAL_BLOCKER
v1_v2_evidence=UNCHANGED_EXHAUSTED
v3_execution=UNAUTHORIZED
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_CONTRACT_REVIEW
```
