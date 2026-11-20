# INBOX-163 — multiply family isolation

Status: complete and stopped for review. This is an evidence-only result.
The temporary M64 production wiring was removed, the accepted dormant
implementation was restored, and the landed direct-materialization ratchet
remains **140**.

## Verdict

The complete M64 family is **retained wholesale**.

The isolated wiring is byte-identical for the complete cohort, object,
owner projection, and every emitted function. Both focused canaries also
pass. The full unit suite, however, fails four accepted production-path
M64 fixtures because those legacy fixtures do not install the source
allocation-plan metadata required by transaction Q1 admission:

```text
cohort=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object=exact
owner=exact
owner_ledger=167 composed / 17 legacy / 101 structural
per_function=285 compared / 0 divergent / 0 missing
focused_canaries=2/2 canaries / 35 executable cases
full_unit=1361 pass / 4 fail / 1365 total
```

INBOX-163 makes full-unit success mandatory and defines M64 as one
indivisible semantic family. Therefore the exact cohort result does not
earn partial or whole-family credit:

```text
landed_ratchet=140
M64_direct_credit=5
accepted_credit=0
resulting_ratchet=140
conditional_135_projection=not_reached
```

No action/model amendment or fixture alignment was attempted during
isolation.

## Frozen baseline

The accepted dormant implementation is commit
`a93b2c82098a73a9d7ca258e97d116b2a32419ce`, tree
`ce06468c6fef90043851c4ff14783535685b8cf4`. Isolation ran from
authorization HEAD `650fd3996597716af3ba4ad57ec3a71ffe4d6f27`, tree
`cb36f6c4a249d9ae05efe4777d054ff17eb7b712`; the intervening tracked
changes are Supervisor documentation only.

Frozen source/input hashes:

| Source or input | SHA-256 |
|---|---|
| `composed_selector_scalar.zig` | `79b11acbad195436c900e2a3a3344e8f816f90d4fbd447a5a2fc367c2b17f965` |
| `value_use/actions/scalar_multiply_divide.zig` | `9a32e275c70a10d9feb09cb98dd7814dc9d6649601e0aa1a226fd6bda50bd1c0` |
| `value_use/model.zig` | `e48c949d0e04a24e7fae8c2e54ae48562b2c38c4a2fb403db8630307fd81bcd7` |
| `source_guard/consumer_policy.zig` | `005b32d50a93fd4dc4a20cb041b87bb82c699bd5a3de9b079612e5e9cbcca928` |
| `source_guard/consumer_policy_tests.zig` | `d292fc93c903b3697a80d67665ff7ee5ac466a2e296c19a1f0f78dabbfe7a881` |
| `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| `tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll` | `7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b` |
| `tmp/inbox142_family_isolation/compare_elf_functions.zig` | `34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f` |

The complete frozen-source list is
`tmp/inbox163_o2_multiply_isolation/baseline_sources.sha256`, SHA-256
`4006ae62d8474395d565fc3b11c1889a483e4a140d7a850061818f9655faba7a`.

## Temporary-build provenance

The temporary source routes the complete `mul i64 <named>, <named>`
family from `lowerBinary` into one `ValueUseTransaction`. It registers
lhs then rhs, attaches the frozen `ScalarMultiplyAction`, seals,
prepares, materializes, executes the closed action, and commits. The
legacy `lowerMul64` body and `lowerMul64SpillLhsThroughRax` fallback are
removed together.

The temporary patch also contains only procedural source-guard handling:
an exact `INBOX-163 temporary complete-family isolation` marker permits
the temporary M64 action, accounts for its two additional named-source
forms and diagnostic-provenance queries, and suppresses only the obsolete
five-site frozen-bypass comparison for this marked build. The complete
guard still runs. The action, model, planning/lifetime authority,
materialization, and tests are unchanged.

```text
temporary_patch=tmp/inbox163_o2_multiply_isolation/patches/m64.patch
temporary_patch_sha256=fb0a6bf32910079c711456e130ad7be99929fd85cf7d337a95868358c63b01f1
temporary_scalar_source_sha256=1c353375ff5a3b81aaac7cd050b8e2311afcda0e131d0a0cf1a9c7b13e597b3f
temporary_guard_core_sha256=2c0fa81804af6b479d2940bcf3495c6f0b34572fa55dc09dde05491bdb91848b
temporary_consumer_guard_sha256=dcb4678cae3d660e5d67cd1a610352a8d8e4326e817aea5682112fe963bf8531
baseline_artifact_sha256=f61a96c784f7486793cbe4136edd0343c833407d275b736041ad020e4ad2e7c4
m64_artifact_sha256=a2977ec121a4cd763524dd3a44d270ea4ccbab9208956584e91cc1c08d5a8853
```

Both compiler artifacts were copied immediately after their respective
builds and frozen mode `0555`. The temporary patch was regenerated after
the final procedural guard edits. After all isolation runs, the three
temporary source files were restored with scoped
`git checkout -- <files>`. The patch then passed `git apply --check`
against the restored accepted tree, and the restored production,
action/model, and guard hashes match the frozen baseline.

The complete sorted 19-file artifact/log manifest is
`tmp/inbox163_o2_multiply_isolation/hashes.sha256`, SHA-256
`5390e82440165622fe9e0fe06d0d6340d6e2ad9fb6e29b40efd6a13c033757e5`.

## Cohort, object, owner, and per-function comparison

Exact commands:

```text
command=LC_ALL=C tmp/inbox163_o2_multiply_isolation/artifacts/baseline/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox163_o2_multiply_isolation/results/baseline/report.log

command=LC_ALL=C tmp/inbox163_o2_multiply_isolation/artifacts/m64/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox163_o2_multiply_isolation/results/m64/report.log

command=LC_ALL=C <artifact> --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/accepted.o 2> <result>/accepted.stderr

command=LC_ALL=C <artifact> --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/owner.tsv 2> <result>/owner.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox163_o2_multiply_isolation/results/baseline/accepted.o tmp/inbox163_o2_multiply_isolation/results/m64/accepted.o > tmp/inbox163_o2_multiply_isolation/results/m64/function_diff.tsv
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report_counts=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=40 composed_block + 127 composed_cfg / 17 legacy / 101 structural
per_function=285/0/0
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
accepted_stderr_bytes=0
owner_stderr_bytes=0
baseline_report_cmp=equal
baseline_object_cmp=equal
baseline_owner_cmp=equal
```

Thus the complete temporary M64 consumer is byte-identical for all
accepted cohort emission. This is necessary but not sufficient because
the unit gate below fails.

## Full-unit failure

Exact command:

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox163_o2_multiply_isolation/logs/m64_full_unit.log
result=1361 pass / 4 fail / 1365 total
log_sha256=32c2e8110ea275039b4f0fa94fa8d04f30cbaac6654054c00f622c686139f4ce
```

The procedural source-guard adjustments pass. The four remaining
failures are production-path M64 fixtures:

| Fixture | Installed plan state | First transaction admission failure |
|---|---|---|
| `generic cfg selector materializes mul64 lhs into planned register` | result and old-value metadata only; lhs/rhs have bindings but no intervals | lhs current-binding interval missing |
| `generic cfg selector reloads spilled mul64 rhs through rax when scratch registers are live` | lhs interval present; spill-backed rhs has no interval | rhs current-binding interval missing |
| `generic cfg selector multiplies by an rax-resident i64 rhs` | no allocation plan | lhs current-binding plan missing |
| `generic cfg selector reloads spilled mul64 lhs through rax when scratch registers are live` | blocker intervals only; spill-backed lhs/rhs have no intervals | lhs current-binding interval missing |

These fixtures expect successful legacy lowering and reach
`expect(diagnostic == null)`. Transaction Q1 instead returns the
request-attributable closed plan/interval admission failure, which the
temporary consumer maps to the existing unknown-lhs/unknown-rhs
diagnostic. The frozen dormant action fixtures pass because they install
production-faithful source intervals. Aligning the four production-path
fixtures or changing admission would be a follow-up semantic/test-policy
decision; INBOX-163 forbids fix-forward.

## Focused canaries

Exact command:

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox163_o2_multiply_isolation/logs/m64_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

The canaries supplement the cohort comparison and do not override the
failed full-unit acceptance condition.

## Closeout

No performance, `distribution-all`, or Tier-3 command was run. No
production wiring is present in this evidence commit. The ratchet stays
140 and the five M64 gateways remain in the frozen bypass inventory.
`stash@{0}` remains `INBOX-93 preserve B2B wiring plus five diagnosis
tests`; all preserved patches remain untouched.
