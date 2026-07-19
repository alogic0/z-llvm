# INBOX-165 — M64 re-isolation

Status: complete and stopped for review. This is an evidence-only result.
The temporary complete-family M64 wiring was removed after measurement,
the accepted aligned tree was restored, and the landed
direct-materialization ratchet remains **140**.

## Verdict

The complete M64 family passes all three mandatory isolation bars
simultaneously:

```text
cohort=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object=exact
owner=exact
owner_ledger=167 composed / 17 legacy / 101 structural
per_function=285 compared / 0 divergent / 0 missing
full_unit=1365/1365
focused_canaries=2/2 canaries / 35 execution cases
```

M64 remained one indivisible semantic family throughout the run. No
partial family was tested or credited. This evidence makes the five
direct M64 gateways conditionally eligible for a separately reviewed
production wiring slice:

```text
landed_ratchet=140
conditional_M64_direct_credit=5
conditional_projection=135
current_ratchet=140
```

No production credit is claimed by INBOX-165.

## Frozen aligned baseline

The aligned code baseline is commit
`b301456d7450360fa310f3c9abaaabe02a225603`, tree
`f6ca6f2a27ad307add0cba08e91526a8fc09da14`. Isolation ran from
authorization HEAD `7228f6fecc31cb357a8f1f2c236c9f510352e351`,
tree `9a9d16753010c742f181b0cc427b1a73ed9e5e92`; the tracked delta from
`b301456d` is Supervisor documentation only.

Frozen source/input hashes:

| Source or input | SHA-256 |
|---|---|
| `composed_selector_scalar.zig` | `79b11acbad195436c900e2a3a3344e8f816f90d4fbd447a5a2fc367c2b17f965` |
| `composed_selector_scalar_tests.zig` | `03fa6a5257ab710a8606a66c1feb3cc18eb5f38fb7e16152c2b2ce5df7a3901c` |
| `value_use/actions/scalar_multiply_divide.zig` | `9a32e275c70a10d9feb09cb98dd7814dc9d6649601e0aa1a226fd6bda50bd1c0` |
| `value_use/model.zig` | `e48c949d0e04a24e7fae8c2e54ae48562b2c38c4a2fb403db8630307fd81bcd7` |
| `source_guard/consumer_policy.zig` | `005b32d50a93fd4dc4a20cb041b87bb82c699bd5a3de9b079612e5e9cbcca928` |
| `source_guard/consumer_policy_tests.zig` | `d292fc93c903b3697a80d67665ff7ee5ac466a2e296c19a1f0f78dabbfe7a881` |
| `source_guard/core.zig` | `3bae0ccfc36e34273149efde9b6bb778bd2f9468e8e94cf6f7e7da6018710eee` |
| `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| `tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll` | `7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b` |
| `tmp/inbox142_family_isolation/compare_elf_functions.zig` | `34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f` |

The complete ten-row source/input list is retained at
`tmp/inbox165_o2_m64_reisolation/baseline_sources.sha256`, SHA-256
`d1cc013e8e51fa4d1eb798b462af7808fe01bb15678110bacd86103f76e753f8`.

## Temporary-build provenance

The temporary patch is byte-identical to the complete-family patch used
for INBOX-163:

```text
temporary_patch=tmp/inbox165_o2_m64_reisolation/patches/m64.patch
temporary_patch_sha256=fb0a6bf32910079c711456e130ad7be99929fd85cf7d337a95868358c63b01f1
```

It routes the complete `mul i64 <named>, <named>` family from
`lowerBinary` into exactly one `ValueUseTransaction`: lhs registration,
rhs registration, frozen `ScalarMultiplyAction` attachment, seal,
prepare, materialize, execute, and commit. It removes the legacy
`lowerMul64` body and its spill-through-RAX fallback together.
Everything else remains as landed, including the R03/R04 legacy routes.

The only other patch changes are procedural temporary source-guard
accounting for that exact marked isolation build. The action, model,
planning/lifetime authority, materialization, and tests are unchanged.
No amendment or fix-forward occurred:

```text
temporary_scalar_source_sha256=1c353375ff5a3b81aaac7cd050b8e2311afcda0e131d0a0cf1a9c7b13e597b3f
temporary_consumer_guard_sha256=dcb4678cae3d660e5d67cd1a610352a8d8e4326e817aea5682112fe963bf8531
temporary_guard_core_sha256=2c0fa81804af6b479d2940bcf3495c6f0b34572fa55dc09dde05491bdb91848b
frozen_action_sha256=9a32e275c70a10d9feb09cb98dd7814dc9d6649601e0aa1a226fd6bda50bd1c0
frozen_model_sha256=e48c949d0e04a24e7fae8c2e54ae48562b2c38c4a2fb403db8630307fd81bcd7
```

Fresh immutable artifacts were built before cohort comparison:

```text
command=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox165_o2_m64_reisolation/logs/baseline_build.log
baseline_build=3/3 steps
baseline_build_log_sha256=1f67977ce5e27ce62b752ef0dbddf817921b3f31d95e78fb928a799528ca58db
baseline_artifact_sha256=d27327bfb60f364b01f207025687c5b0c8e573a47069f0969935519690eb7efe
baseline_artifact_mode=0555

command=/home/oleg/bin/zig build --summary all 2>&1 | tee tmp/inbox165_o2_m64_reisolation/logs/m64_build.log
m64_build=3/3 steps
m64_build_log_sha256=a8fc9856b43da9fccd9c467e912124a62ad657a21dc90b637898b56aeecfbf83
m64_artifact_sha256=031a816c50aec99c4697dd5378b5d3ebaf3acd7ae74308afa7dd556c8d113dcb
m64_artifact_mode=0555
```

After all runs, the three temporary source files were restored with
scoped `git checkout -- <files>`. The retained patch again passes
`git apply --check`; restored production/action/model/guard hashes match
the frozen baseline. The complete sorted 19-file artifact/log manifest
is `tmp/inbox165_o2_m64_reisolation/hashes.sha256`, SHA-256
`4812dd47be1a76c8bd5ae6dcbe2c6bb448a04df36bb949befd7eee8e1f22d3ad`.

## Bar 1 — cohort, object, owner, and per-function identity

Exact commands:

```text
command=LC_ALL=C tmp/inbox165_o2_m64_reisolation/artifacts/baseline/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox165_o2_m64_reisolation/results/baseline/report.log

command=LC_ALL=C tmp/inbox165_o2_m64_reisolation/artifacts/m64/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox165_o2_m64_reisolation/results/m64/report.log

command=LC_ALL=C <artifact> --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/accepted.o 2> <result>/accepted.stderr

command=LC_ALL=C <artifact> --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/owner.tsv 2> <result>/owner.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox165_o2_m64_reisolation/results/baseline/accepted.o tmp/inbox165_o2_m64_reisolation/results/m64/accepted.o > tmp/inbox165_o2_m64_reisolation/results/m64/function_diff.tsv
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report_counts=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=40 composed_block + 127 composed_cfg / 17 legacy / 101 structural
per_function=285 compared / 0 divergent / 0 missing
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
baseline_report_cmp=equal
baseline_object_cmp=equal
baseline_owner_cmp=equal
baseline_accepted_stderr_bytes=0
m64_accepted_stderr_bytes=0
baseline_owner_stderr_bytes=0
m64_owner_stderr_bytes=0
```

Bar 1 passes.

## Bar 2 — full unit

Exact command:

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox165_o2_m64_reisolation/logs/m64_full_unit.log
result=7/7 steps; 1365/1365 tests passed
log_sha256=377e474d7b5ae18e0b96f5c47ae8bca57c710e27141eb5252c195bf1ad682009
```

All four aligned production-path M64 fixtures pass through the temporary
transaction consumer. This is the bar that failed 1361/1365 in
INBOX-163. Bar 2 now passes without an action/model/admission change.

## Bar 3 — focused canaries

Exact command:

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox165_o2_m64_reisolation/logs/m64_canaries.log
result=2/2 canaries; 35 execution cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

Bar 3 passes.

## Review boundary

All three bars pass for the same complete-family temporary source state.
INBOX-165 does not land that source state: the ratchet remains 140 and
the five M64 gateways remain in the frozen bypass inventory. A move to
135 requires separate production-wiring authorization and acceptance.

No performance, `distribution-all`, or Tier 3 command was run.
`stash@{0}` remains `INBOX-93 preserve B2B wiring plus five diagnosis
tests`; all preserved patches are untouched.
