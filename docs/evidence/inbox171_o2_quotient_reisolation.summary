# INBOX-171 — unsigned quotient re-isolation

Status: complete and stopped for review. This is an evidence-only result.
All three temporary consumers were removed after measurement, the aligned
tree was restored, and the landed direct-materialization ratchet remains
**135**. No performance command and no Tier 3 command was run.

## Verdict

UQ32, UQ64, and their aggregate each pass all three mandatory bars from the
aligned tree:

| Build | Cohort/object/owner/per-function | Full unit | Focused canaries | Verdict |
|---|---|---|---|---|
| UQ32 alone | exact; 285/0/0 | 1375/1375 | 2/2; 35 cases | pass |
| UQ64 alone | exact; 285/0/0 | 1375/1375 | 2/2; 35 cases | pass |
| UQ32+UQ64 aggregate | exact; 285/0/0 | 1375/1375 | 2/2; 35 cases | pass |

Every build reproduced:

```text
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167 composed / 17 legacy / 101 structural
per_function=285 compared / 0 divergent / 0 missing
```

The aligned UQ32 production-path fixtures remove the only failures seen in
INBOX-169. Both widths now pass independently, and their aggregate is
byte-identical. This evidence lands no production credit:

```text
ratchet_before=135
UQ32_isolation=pass
UQ64_isolation=pass
aggregate_isolation=pass
direct_credit_landed=0
helper_collapse_credit_landed=0
current_ratchet=135
conditional_direct_credit_target=132
conditional_last_owner_target=131
```

The three direct textual credits and the possible one last-owner helper
credit remain conditional on a separately reviewed wiring slice and its
final owner recount. This evidence does not choose between 132 and 131.

## Frozen aligned baseline

The aligned source baseline is commit
`390945be29e81e8fb904b66935486e69ab06a282`, tree
`15a242782b3d0fb421e3efbf9a8d8b9614aac253`. Isolation ran from
authorization HEAD `d3605dabd67ac8610570504d00b772dfdd4b048b`, tree
`90a706b5b6c140b6f779e631af3859b750f60e50`; the sole intervening tracked
change is Supervisor documentation (`docs/next_steps.md`).

Frozen source/input hashes:

| Source or input | SHA-256 |
|---|---|
| `composed_selector_scalar.zig` | `ac4ffae4e822d7056b655e11c72096af29ff5b715e61846f3af6e82c4bfeb8fd` |
| `composed_selector_scalar_tests.zig` | `e03086370f49ebe459b3dc4661d393132b7cc5cad9d82026b4049c71eb68ff26` |
| `value_use/actions/scalar_multiply_divide.zig` | `fd2ce0f67a2983544c139edd1d0188e8b8a3cd1057d3ce3f4382b4137cc7a0db` |
| `value_use/model.zig` | `32f3086a8fc714245ee9a211e16ce8eb90a32496a2d0f87f1f2e3e5ac27ea3ef` |
| `source_guard/consumer_policy.zig` | `999714a7f0317e2a0af242441969026bb7c02c4e55b7373f38c8088375a51d8e` |
| `source_guard/core.zig` | `3bae0ccfc36e34273149efde9b6bb778bd2f9468e8e94cf6f7e7da6018710eee` |
| `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| `tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll` | `7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b` |
| `tmp/inbox142_family_isolation/compare_elf_functions.zig` | `34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f` |

The complete nine-row list is retained at
`tmp/inbox171_o2_quotient_reisolation/baseline_sources.sha256`, SHA-256
`37c210619b77149f2dbfda5109bd7232d7cc7455c8cbf33c98a725a2b6493887`.

The immutable baseline artifact was built and frozen before any temporary
consumer was applied:

```text
command=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox171_o2_quotient_reisolation/logs/baseline_build.log
result=3/3 steps
log_sha256=1f67977ce5e27ce62b752ef0dbddf817921b3f31d95e78fb928a799528ca58db
artifact_sha256=4dd31f7b1e90a6142b4da6db756acf11c0a533be86a590b9e18d1bc8524b0b14
artifact_mode=0555
```

Its identities are:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
accepted_stderr_bytes=0
owner_stderr_bytes=0
```

## Temporary-build provenance

The re-isolation reused the exact reviewed INBOX-169 temporary patches.
All three passed `git apply --check` against the clean aligned tree before
use:

| Build | Pure semantic dispatch | Patch SHA-256 |
|---|---|---|
| UQ32 | `bits == 32 and isUnsignedQuotient(binary)` | `484be156a47c15c1d256446a79ed0b5ac57f1e31114b757f4e5fd0a4198bf9f4` |
| UQ64 | `bits == 64 and isUnsignedQuotient(binary)` | `4301762521200b43858549491ab48ab4582f45ab7812bd82d2bb9c810ddfe31c` |
| aggregate | `isUnsignedQuotient(binary)` | `a6ddcf389f02383057e906614d93f1326e7ca61cdf6b2dcb1ff8fa57255caad4` |

Each patch:

- leaves the early `.urem` dispatch and all remainder lowering legacy-owned;
- leaves R03/R04 and every other retained scalar family unchanged;
- registers RHS first and LHS second before mutation;
- derives expected class only from semantic width;
- attaches the frozen `UnsignedQuotientAction`;
- seals, prepares, materializes, executes, and commits exactly once;
- maps failures only through the matching request handles; and
- changes only `composed_selector_scalar.zig` and the temporary
  function-scoped source-guard accounting.

No action, model, planning, lifetime, Q1, materialization, inventory,
remainder, or test source changed in any temporary build.

| Build | Temporary scalar SHA-256 | Temporary guard SHA-256 | Artifact SHA-256 |
|---|---|---|---|
| UQ32 | `7e72810dbcd78fbc782bc09d09cb0117c55172e549de7691429437781c3ac145` | `ca371867e51035d3b19917c3a946da2f23ae6f6803551980d0fc4309638f7b11` | `3a7bb68da3ec90d224b760a589cd021ddfbafaf75a886ed63dcbf421fd4a0d1f` |
| UQ64 | `cc0214197550c42fcca884898c62153cb8d379df7eb5406c72cf226063fe19c9` | `ca371867e51035d3b19917c3a946da2f23ae6f6803551980d0fc4309638f7b11` | `38e46b21f75cd492bc3223808403f81091bf7b1f9874a073a3edca95854f00a3` |
| aggregate | `c32f61e76e9bb7f1d176dfa4d0bdc84341089ed35a1f8554c44119ecc1340bfc` | `ca371867e51035d3b19917c3a946da2f23ae6f6803551980d0fc4309638f7b11` | `53c794297c89e93c5d1bd562c73b02cb8fa0ebf90c972918d64ac97d7faee48c` |

The frozen action and model hashes remain
`fd2ce0f67a2983544c139edd1d0188e8b8a3cd1057d3ce3f4382b4137cc7a0db`
and
`32f3086a8fc714245ee9a211e16ce8eb90a32496a2d0f87f1f2e3e5ac27ea3ef`
in all three builds.

Exact build commands and retained logs:

```text
command[UQ32]=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox171_o2_quotient_reisolation/logs/uq32_build.log
result[UQ32]=3/3 steps
log_sha256[UQ32]=0a7fd2ad664536b2ccec222b2e7e138a9b17eff97d8250af9ea8a7b366c7a576

command[UQ64]=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox171_o2_quotient_reisolation/logs/uq64_build.log
result[UQ64]=3/3 steps
log_sha256[UQ64]=d59a3b6e76cb0d515fb26709f1f288403b556b22c6157788973738eb2f8daf05

command[aggregate]=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox171_o2_quotient_reisolation/logs/aggregate_build.log
result[aggregate]=3/3 steps
log_sha256[aggregate]=603c3e959b162849085cd01bae20c4fab67a8f3bc7e73a772ff7f1fa8bce5ebb
```

All four artifacts were copied immediately from their corresponding source
state and frozen mode `0555`. The complete sorted 45-file
source/patch/artifact/result/log manifest is
`tmp/inbox171_o2_quotient_reisolation/hashes.sha256`, SHA-256
`2a1956f6e29b03a442402edcdb779761313ad60a4a3713fa2e6307ac520a90cb`.

## Bar 1 — cohort, object, owner, and per-function identity

The exact commands below were run for `baseline`, `uq32`, `uq64`, and
`aggregate`, substituting the corresponding frozen `<artifact>` and
`<result>` directory:

```text
command=LC_ALL=C <artifact>/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll >/dev/null 2><result>/report.log

command=LC_ALL=C <artifact>/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll ><result>/accepted.o 2><result>/accepted.stderr

command=LC_ALL=C <artifact>/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll ><result>/owner.tsv 2><result>/owner.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox171_o2_quotient_reisolation/results/baseline/accepted.o <result>/accepted.o ><result>/function_diff.tsv
```

For UQ32, UQ64, and aggregate:

```text
report_cmp=equal
object_cmp=equal
owner_cmp=equal
report_counts=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
per_function=285/0/0
function_diff_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
accepted_stderr_bytes=0
owner_stderr_bytes=0
```

Bar 1 passes for both widths independently and for the aggregate.

## Bar 2 — full unit

Exact command under each temporary source state:

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee <log> >/dev/null
```

Results:

```text
UQ32=7/7 steps; 1375/1375 tests
UQ32_log=tmp/inbox171_o2_quotient_reisolation/logs/uq32_full_unit.log
UQ32_log_sha256=f3623efc1bd0bf5dd92c99023f383951fd5d4482fc3c6cb941ecf624c22d4560

UQ64=7/7 steps; 1375/1375 tests
UQ64_log=tmp/inbox171_o2_quotient_reisolation/logs/uq64_full_unit.log
UQ64_log_sha256=f030dddbc698a9d5ace1ddf0bb86449ef8d8e7cfc3e0cfdf362a30c29f090145

aggregate=7/7 steps; 1375/1375 tests
aggregate_log=tmp/inbox171_o2_quotient_reisolation/logs/aggregate_full_unit.log
aggregate_log_sha256=b9b099cbb404611ded6ccaac78a41df78393683414f082117d98883aa502586d
```

Bar 2 passes for both widths independently and for the aggregate. In
particular, UQ32 now passes both aligned production-path fixtures:

```text
generic cfg selector lowers named i32 unsigned division and remainder
accumulator-resident udiv lhs keeps accepted fixed-register stream
```

The remainder half of the first fixture stays on the unchanged legacy path.

## Bar 3 — focused canaries

Exact command under each temporary source state:

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee <log> >/dev/null
```

UQ32, UQ64, and aggregate each report:

```text
result=2/2 steps, 2/2 canaries, 35/35 execution cases
__multi3=object/stream/symbol/execution exact
fma=object/stream/symbol/helper/execution exact
host_libc_substitution=absent
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

Bar 3 passes for both widths independently and for the aggregate.

## Restoration and review boundary

After each temporary build, only these two files were restored with scoped
`git checkout -- <files>`:

```text
src/codegen/x86_64/generic_cfg/composed_selector_scalar.zig
src/codegen/x86_64/generic_cfg/source_guard/consumer_policy.zig
```

All three retained patches pass `git apply --check` against the restored
aligned tree. Restored production, test, guard, action, and model hashes
match the frozen baseline exactly. No production wiring is present in this
evidence commit; the bypass inventory remains unchanged; remainder plus
R03/R04 remain legacy-owned; and ratchet 135 remains landed.

No performance, `distribution-all`, or Tier 3 command was run. `stash@{0}`
remains `INBOX-93 preserve B2B wiring plus five diagnosis tests`; all
pre-existing preserved patches are untouched. INBOX-171 stops here before
any production wiring or final helper-owner recount.
