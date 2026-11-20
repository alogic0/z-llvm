# INBOX-169 — unsigned quotient isolation

Status: complete and stopped for review. This is an evidence-only result.
All three temporary consumers were removed after measurement, the accepted
dormant tree was restored, and the landed direct-materialization ratchet
remains **135**.

## Verdict

The two widths have different three-bar results:

| Build | Cohort/object/owner/per-function | Full unit | Focused canaries | Verdict |
|---|---|---|---|---|
| UQ32 alone | exact; 285/0/0 | **1373/1375; 2 fail** | 2/2; 35 cases | retained wholesale |
| UQ64 alone | exact; 285/0/0 | 1375/1375 | 2/2; 35 cases | all three bars pass |
| UQ32+UQ64 aggregate | exact; 285/0/0 | **1373/1375; 2 fail** | 2/2; 35 cases | aggregate bar fails |

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

UQ32 fails the mandatory independent unit bar and is therefore retained as
one complete width family. No alignment or fix-forward was attempted. UQ64
passes independently, but this evidence claims no production credit: the
three direct textual gateways are shared with retained UQ32, and the
quotient-only helper remains owned by retained UQ32. The aggregate does not
satisfy the three-bar discipline.

```text
landed_ratchet=135
UQ32_accepted_credit=0
UQ64_textual_credit=0 (shared gateways remain)
helper_collapse_credit=0
direct_credit_target=unresolved
131_or_132_target=not_reached
current_ratchet=135
```

Any UQ64 semantic-only landing, UQ32 fixture alignment/remediation, fresh
re-isolation, direct-credit accounting, and final helper owner recount
require separate review.

## Frozen accepted baseline

The dormant implementation baseline is commit
`d1e6fcbd69194a566f2e4821f647b2d354378f5d`, tree
`0f00fb7e56f15d6fa1c5e872550a25d3fa2e45ef`. Isolation ran from
authorization HEAD `f70b3ed20288d7223c32ba846eb46fe50d58002e`,
tree `21223ef1a60d3d57335bf95516b0393f662241d2`; the intervening tracked
change is Supervisor documentation only.

Frozen source/input hashes:

| Source or input | SHA-256 |
|---|---|
| `composed_selector_scalar.zig` | `ac4ffae4e822d7056b655e11c72096af29ff5b715e61846f3af6e82c4bfeb8fd` |
| `composed_selector_scalar_tests.zig` | `03fa6a5257ab710a8606a66c1feb3cc18eb5f38fb7e16152c2b2ce5df7a3901c` |
| `value_use/actions/scalar_multiply_divide.zig` | `fd2ce0f67a2983544c139edd1d0188e8b8a3cd1057d3ce3f4382b4137cc7a0db` |
| `value_use/model.zig` | `32f3086a8fc714245ee9a211e16ce8eb90a32496a2d0f87f1f2e3e5ac27ea3ef` |
| `source_guard/consumer_policy.zig` | `999714a7f0317e2a0af242441969026bb7c02c4e55b7373f38c8088375a51d8e` |
| `source_guard/core.zig` | `3bae0ccfc36e34273149efde9b6bb778bd2f9468e8e94cf6f7e7da6018710eee` |
| `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| `tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll` | `7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b` |
| `tmp/inbox142_family_isolation/compare_elf_functions.zig` | `34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f` |

The complete nine-row list is retained at
`tmp/inbox169_o2_quotient_isolation/baseline_sources.sha256`, SHA-256
`9add5da519005d5b20e6234d0fffe5685ef507973a2b196b2fc541c7c57b0ea5`.

The immutable baseline artifact was built and frozen before any temporary
consumer was applied:

```text
command=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox169_o2_quotient_isolation/logs/baseline_build.log
result=3/3_steps
log_sha256=c9fb298c10063d3c13d10c66be7de0ccff1155ab9153396c0f651d5c40bf3f91
artifact_sha256=618a9cafe9973846bd6b2acedb7778d5e56556938b4e4daf7e314d2afd201587
artifact_mode=0555
```

## Temporary-build provenance

The three patches differ only in their pure semantic dispatch boundary:

```text
UQ32: bits == 32 and isUnsignedQuotient(binary)
UQ64: bits == 64 and isUnsignedQuotient(binary)
aggregate: isUnsignedQuotient(binary)
```

Each patch:

- leaves the early `.urem` dispatch and all remainder code legacy-owned;
- registers RHS first and LHS second before mutation;
- derives expected register class only from semantic width;
- attaches the frozen `UnsignedQuotientAction`;
- seals, prepares, materializes, executes, and commits exactly once;
- maps request failures only through the matching retained handles;
- preserves the legacy quotient body for every non-admitted width;
- adds only exact marked source-guard accounting for the temporary
  consumer, two named requests, and two provenance queries.

R03/R04 and all other landed or retained scalar families remain unchanged.
No action, model, planning, lifetime, Q1, materialization, inventory,
remainder, or test source is changed by any patch.

| Build | Patch SHA-256 | Temporary scalar SHA-256 | Temporary guard SHA-256 | Artifact SHA-256 |
|---|---|---|---|---|
| UQ32 | `484be156a47c15c1d256446a79ed0b5ac57f1e31114b757f4e5fd0a4198bf9f4` | `ffbf0c174531af7a6a9fa49a6a61c699c35d75861767ebd74761cdffd9ee791e` | `ca371867e51035d3b19917c3a946da2f23ae6f6803551980d0fc4309638f7b11` | `3b7d35f4fb976d5402afd84ce02dcb44c62cd6a30af95461923fad7004f17c59` |
| UQ64 | `4301762521200b43858549491ab48ab4582f45ab7812bd82d2bb9c810ddfe31c` | `cc0214197550c42fcca884898c62153cb8d379df7eb5406c72cf226063fe19c9` | `ca371867e51035d3b19917c3a946da2f23ae6f6803551980d0fc4309638f7b11` | `67270a08db954f932a7c83ff591453d07032cc5a77f750d89db99c05dfebfa1f` |
| aggregate | `a6ddcf389f02383057e906614d93f1326e7ca61cdf6b2dcb1ff8fa57255caad4` | `c32f61e76e9bb7f1d176dfa4d0bdc84341089ed35a1f8554c44119ecc1340bfc` | `ca371867e51035d3b19917c3a946da2f23ae6f6803551980d0fc4309638f7b11` | `58288a7108003c9b9e3bbbb2d125112361e411d32e1361c9c2a1e37aa299eaa9` |

The frozen action and model hashes remain
`fd2ce0f67a2983544c139edd1d0188e8b8a3cd1057d3ce3f4382b4137cc7a0db`
and
`32f3086a8fc714245ee9a211e16ce8eb90a32496a2d0f87f1f2e3e5ac27ea3ef`
in every build.

Exact build commands:

```text
command[UQ32]=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox169_o2_quotient_isolation/logs/uq32_build.log
result[UQ32]=3/3_steps
log_sha256[UQ32]=742e214901f057196dd6609e163507b454df2d2dc0e8887de5ab74f967b955ae

command[UQ64]=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox169_o2_quotient_isolation/logs/uq64_build.log
result[UQ64]=3/3_steps
log_sha256[UQ64]=d59a3b6e76cb0d515fb26709f1f288403b556b22c6157788973738eb2f8daf05

command[aggregate]=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox169_o2_quotient_isolation/logs/aggregate_build.log
result[aggregate]=3/3_steps
log_sha256[aggregate]=d59a3b6e76cb0d515fb26709f1f288403b556b22c6157788973738eb2f8daf05
```

All four artifacts were copied immediately after their source-state build
and frozen mode `0555`. The complete sorted 41-file source/patch/artifact/
result/log manifest is
`tmp/inbox169_o2_quotient_isolation/hashes.sha256`, SHA-256
`c565aa7a26a62b414d7df04fbe292e0bc808d75a6790a3a43a84ed885c0e89a1`.

## Bar 1 — cohort, object, owner, and per-function identity

The exact commands below were run for `baseline`, `uq32`, `uq64`, and
`aggregate`, substituting the corresponding frozen `<artifact>` and
`<result>` directory:

```text
command=LC_ALL=C <artifact>/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll >/dev/null 2><result>/report.log

command=LC_ALL=C <artifact>/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll ><result>/accepted.o 2><result>/accepted.stderr

command=LC_ALL=C <artifact>/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll ><result>/owner.tsv 2><result>/owner.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox169_o2_quotient_isolation/results/baseline/accepted.o <result>/accepted.o ><result>/function_diff.tsv
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
UQ32=5/7_steps; 1373_pass/2_fail/1375_total
UQ32_log=tmp/inbox169_o2_quotient_isolation/logs/uq32_full_unit.log
UQ32_log_sha256=c999c29073ed016197df458047b3b75a680ac6e5ea36f133b7a56ac4ba0fe84d

UQ64=7/7_steps; 1375/1375_tests
UQ64_log=tmp/inbox169_o2_quotient_isolation/logs/uq64_full_unit.log
UQ64_log_sha256=e502762081f19dd7c644cdfab8f4eb0e59b70601c871e8e64b21a25dad9ba061

aggregate=5/7_steps; 1373_pass/2_fail/1375_total
aggregate_log=tmp/inbox169_o2_quotient_isolation/logs/aggregate_full_unit.log
aggregate_log_sha256=92c48f6fcf61ede4adf9db6728326f29b2acec955448a282025cbdba1fb96678
```

UQ32 and aggregate fail the same two accepted production-path fixtures:

| Fixture | Legacy fixture metadata | First transaction admission result |
|---|---|---|
| `generic cfg selector lowers named i32 unsigned division and remainder` | quotient selector has current bindings but no allocation plan | RHS-first request returns the closed missing-plan admission error, mapped to the legacy unknown-RHS diagnostic; the fixture expected successful lowering |
| `accumulator-resident udiv lhs keeps accepted fixed-register stream` | plan contains only `interval_ends["lhs"] = 9`; RHS has a current binding but no interval/assignment metadata | RHS-first request returns the closed missing-interval admission error, mapped to the legacy unknown-RHS diagnostic; the fixture expected successful lowering |

The corresponding remainder branch in the first fixture stays legacy and is
not the failure. These are fixture-plan admission failures; the dormant
UQ32/UQ64 action tests with real plans remain green. INBOX-169 forbids
fixture alignment or action/admission amendment during isolation, so UQ32
is retained wholesale. UQ64 has no failing production-path fixture and
passes Bar 2.

## Bar 3 — focused canaries

Exact command under each temporary source state:

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee <log> >/dev/null
```

UQ32, UQ64, and aggregate each report:

```text
result=2/2_steps,2/2_canaries,35/35_execution_cases
__multi3=object/stream/symbol/execution exact
fma=object/stream/symbol/helper/execution exact
host_libc_substitution=absent
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

Bar 3 passes for both widths independently and for the aggregate. It does
not override the failed UQ32/aggregate full-unit bar.

## Restoration and review boundary

After each temporary build, the two changed source files were restored with
scoped `git checkout -- <files>`. All three retained patches pass
`git apply --check` against the restored accepted tree. Restored production,
guard, action, and model hashes match the frozen baseline exactly.

No production wiring is present in this evidence commit. The bypass
inventory remains unchanged, ratchet 135 remains landed, and remainder plus
R03/R04 paths remain legacy-owned. No performance, `distribution-all`, or
Tier 3 command was run. `stash@{0}` remains `INBOX-93 preserve B2B wiring
plus five diagnosis tests`; all pre-existing preserved patches are
untouched.
