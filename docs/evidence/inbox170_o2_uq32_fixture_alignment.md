# INBOX-170 — UQ32 fixture alignment

Status: complete for review. This is a test/evidence-only slice. Production,
Q1, actions, model, admission, guard policy, tools, build roots, the legacy
remainder path, and the bypass inventory are unchanged. The direct-resolution
ratchet remains **135**. No performance command and no Tier 3 command was run.
The required UQ32/UQ64/aggregate re-isolation was not started.

## Scope and baseline

The accepted dormant quotient code baseline is `d1e6fcbd`; work began from
authorization HEAD `74dbb793732b0b23387e22939b60783833c685a0`, tree
`69372efe1f54af4c63cae0ea315ab6d8a4fb3cba`.

The only test source changed is:

```text
src/codegen/x86_64/generic_cfg/composed_selector_scalar_tests.zig
```

Tracked evidence also adds this summary and the complete performance-omission
hash table. No production `.zig`, action, model, admission, guard, tool, build,
inventory, or manifest file changed.

Both fixtures now use `allocateSelectorIntervals`, the real
`SelectorAllocationPlan` construction path. The plans install bounded
allocation intervals, canonical assignments, and the canonical empty
address-dependency domain. No interval uses `maxInt`. “Assignment” below is
the planned physical storage; “binding” is the canonical current home
installed in selector state.

## Per-fixture manifest

### 1. `generic cfg selector lowers named i32 unsigned division and remainder`

This test contains two independent selector runs. Each receives its own plan;
the legacy quotient and remainder paths do not share mutable plan state.

#### Quotient run

```text
source identities=lhs,rhs
current_position=1
lhs: IR=i32 class=gpr32 bits=32 interval=[0,1] assignment=gpr32/RDI binding=arg32/RDI
rhs: IR=i32 class=gpr32 bits=32 interval=[0,1] assignment=gpr32/RSI binding=arg32/RSI
dependencies=owners:0 edges:0
result=quotient binding=EAX
```

Both operands are defined before and consumed at instruction position 1. Their
truthful intervals therefore end inclusively at the current instruction. The
accepted instruction stream is unchanged:

```text
mov_arg_eax RDI
mov_arg_arg RCX,RSI
xor_edx_edx
div_arg32 RCX
```

#### Remainder run

```text
source identities=lhs,rhs
current_position=1
lhs: IR=i32 class=gpr32 bits=32 interval=[0,1] assignment=gpr32/RDI binding=arg32/RDI
rhs: IR=i32 class=gpr32 bits=32 interval=[0,1] assignment=gpr32/RSI binding=arg32/RSI
dependencies=owners:0 edges:0
result=remainder binding=scratch32/RDX
```

The same current-inclusive operand lifetime is truthful for the legacy
remainder consumer. Its dispatch, fixed-register discipline, result ownership,
and instruction stream remain unchanged:

```text
mov_arg_eax RDI
mov_arg_arg RCX,RSI
xor_edx_edx
div_arg32 RCX
```

### 2. `accumulator-resident udiv lhs keeps accepted fixed-register stream`

```text
source identities=lhs,rhs
current_position=4
lhs: IR=i32 class=gpr32 bits=32 interval=[0,9] assignment=gpr32/RDI binding=EAX
rhs: IR=i32 class=gpr32 bits=32 interval=[1,4] assignment=gpr32/RSI binding=arg32/RSI
dependencies=owners:0 edges:0
result=result binding=EAX
```

`lhs` is already resident in the accumulator and survives the instruction;
`rhs` is consumed at and ends at the current instruction. The accepted
fixed-register stream and both source/result bindings remain unchanged:

```text
mov_arg_arg RCX,RSI
xor_edx_edx
div_arg32 RCX
lhs=EAX
result=EAX
```

## No Option-A exception

No fixture moved. All pre-alignment instruction streams, result bindings,
source bindings, diagnostics, and the legacy remainder path remain exact after
installing truthful plans. Therefore none of the fixtures needs the reviewed
Option-A plan-visible-stream exception, and no fixture-minus-plan artifact was
created.

## Production hash identity and performance omission

Performance is omitted because every production source, tool, build
configuration/root, and facade is byte-identical to the accepted dormant
quotient tree `d1e6fcbd`. The complete 424-row proof is tracked in
`docs/evidence/inbox170_o2_performance_omission_hash_contract.tsv`.

```text
command=set -o pipefail; /home/oleg/bin/zig run tmp/inbox148_o2_checkpoint_slice4/hash_contract.zig -- d1e6fcbd docs/evidence/inbox170_o2_performance_omission_hash_contract.tsv 2>&1 | tee tmp/inbox170_o2_uq32_fixture_alignment/validation/performance_omission_hash_contract.log
result=424/424 identical
production=311
tools=72
build_configuration=1
build_roots=37
facades=3
table_sha256=e932e61d3b658343afa1698297a0f80e1bdb83f2029aee96e94a7a6c955c12f2
log_sha256=cd53864fbf18d416f92b987030ad434a8c3729a8ea5b7defde138bc323ec0921
```

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll >/dev/null 2>tmp/inbox170_o2_uq32_fixture_alignment/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >tmp/inbox170_o2_uq32_fixture_alignment/validation/accepted.o 2>tmp/inbox170_o2_uq32_fixture_alignment/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >tmp/inbox170_o2_uq32_fixture_alignment/validation/owner_manifest.tsv 2>tmp/inbox170_o2_uq32_fixture_alignment/validation/owner_manifest.stderr
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=40 composed_block + 127 composed_cfg / 17 legacy / 101 structural
accepted_stderr_bytes=0
owner_stderr_bytes=0
```

## Correctness gates

All commands ran against the final test source state. Logs are retained under
`tmp/inbox170_o2_uq32_fixture_alignment/validation/`.

### Full unit

```text
command=set -o pipefail; /home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox170_o2_uq32_fixture_alignment/validation/full_unit.log >/dev/null
result=7/7 steps; 1375/1375 tests passed
log_sha256=3c439b6f701e5427f69c12bd8275e4c13c755667b19da697a7605f96c7f716b9
```

### Source guard

```text
command=set -o pipefail; /home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox170_o2_uq32_fixture_alignment/validation/source_guard.log >/dev/null
result=57/57 tests passed
log_sha256=84f662d58a342ca239975fe7d5bae96a47d32ef0f8f99a8bb03090b92cbebad4
```

### ABI differential

```text
command=set -o pipefail; /home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox170_o2_uq32_fixture_alignment/validation/abi_differential.log >/dev/null
result=5/5 steps; 60/60 cases and 30/30 real functions matched
log_sha256=7dc2d5b2c992d0c942d6fdd621a25c06c27b7fac7e27c778fe7d4a8a6d7579f1
```

### Focused canaries

```text
command=set -o pipefail; /home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox170_o2_uq32_fixture_alignment/validation/focused_canaries.log >/dev/null
result=2/2 canaries; 35/35 execution cases
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=set -o pipefail; /home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox170_o2_uq32_fixture_alignment/validation/integrated_exe.log >/dev/null
result=2/2 steps; 7/7 builds and runs
log_sha256=f8c34c34a40b819df8ae2be09bac5760e018b05cf211a3db261acb848632fd1d
```

### Strengthened Tier 2

```text
command=set -o pipefail; /home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox170_o2_uq32_fixture_alignment/validation/strengthened_tier2.log >/dev/null
result=29/29 steps; 1383/1383 tests passed; structural 8/8; integrated executable 7/7; ABI 60/60+30/30
log_sha256=5f15209baf0b7d6e8b3e398134e6c1d0863b4f39140a4e5fd12f0dcaa521a222
```

No `distribution-all` command was run. No authorized or acceptance-grade
Tier 3 evidence was produced.

## Scope audit

```text
test_sources_changed=1
production_sources_changed=0
action_or_model_changed=0
admission_changed=0
guard_policy_changed=0
legacy_remainder_changed=0
bypass_inventory_changed=0
ratchet=135
performance_run=none
tier3_run=none
stash0=untouched
```

INBOX-170 stops here. The three-build UQ32/UQ64/aggregate re-isolation remains
a separately reviewed and separately authorized slice.
