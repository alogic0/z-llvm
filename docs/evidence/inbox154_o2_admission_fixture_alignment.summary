# INBOX-154 — admission fixture alignment and characterization

Status: complete for review. This is a test/evidence-only slice. Production,
actions, model, admission, guards, tools, build roots, and the bypass
inventory are unchanged. The direct-resolution ratchet remains **152**.
No performance command and no Tier 3 command was run.

## Scope and baseline

The accepted ratchet-152 production baseline is
`e048ff5cb7818f0b1e99d6971b9542562ffcf086`, tree
`5c5bfa8cc202ec6403799b56df2e613275bdeb22`. Work began from authorization
HEAD `5284cea9`, tree
`806f9531319cc8012096963580a642c8f5af427e`. The preserved hard-stop patch
was verified before reuse:

```text
path=tmp/inbox154_o2_admission_fixture_alignment/inbox154_fixture_alignment_hard_stop.patch
sha256=6aeea7ebc704141d9aa4009173cc114c962c8cb6e5eb90da0623e9bac7ac2506
```

Only these test sources changed:

```text
src/codegen/x86_64/generic_cfg/composed_selector_scalar_tests.zig
src/codegen/x86_64/generic_cfg/value_use/planning_lifetime_admission_tests.zig
```

The first source aligns the legacy production-path fixtures. The second
adds closed characterization coverage for current and forward identities.
No test-only admission bypass exists.

## Production-path fixture manifest

Every named source below uses `allocateSelectorIntervals`, so the plan is
the real allocator-produced `SelectorAllocationPlan`: interval ends and
assignments are canonical, and no blanket `maxInt` endpoint is used. Each
fixture has the canonical empty address-dependency domain; therefore the
exact dependency owner/edge set is `0/0`. “Assignment” is the allocator
assignment, while “binding” is the deliberately installed current home.

| Family / fixture subcase | Current position | Exact intervals | Exact assignments | Current bindings | Intended lifetime | Result |
|---|---:|---|---|---|---|---|
| B07 `reload-spill32-rhs` | 1 | lhs `[0,1]`; rhs `[0,1]` | lhs gpr32/RDI; rhs gpr32/RSI | lhs scratch32/RDI; rhs spill64/slot4 | both operands consumed at current | old reload/stage/result stream and bindings exact |
| B06 exact-EI `or i55` | 1 | source `[0,1]`; amount `[0,1]` | amount gpr64/RDI; source gpr64/RSI | source RAX; amount arg64/RSI | both operands consumed at current | reviewed current-inclusive spill/reload movement |
| B05 exact-EI `shl i56` | 1 | source `[0,1]`; amount `[0,1]` | amount gpr64/RDI; source gpr64/RSI | source RAX; amount arg64/RSI | both operands consumed at current | reviewed current-inclusive spill/reload movement |
| B05 `current-rhs-exact-ei` | 4 | lhs `[0,4]`; amount `[1,4]` | lhs gpr64/RDI; amount gpr64/RSI | lhs spill64/slot6; amount RAX | both operands consumed at current | old spill/reload/shift stream exact |
| B04 `shift-i32-accumulator-lhs` | 4 | lhs `[0,9]`; amount `[1,4]` | lhs gpr32/RDI; amount gpr32/RSI | lhs EAX; amount arg32/RSI | lhs survives; amount ends at current | old direct stage/shift stream and bindings exact |
| B03 `mul-i32-preserve-order` | 4 | live `[0,9]`; lhs `[1,4]`; rhs `[2,4]` | live gpr32/RDI; lhs gpr32/RSI; rhs gpr32/RDX | live EAX; lhs spill64/slot2; rhs spill64/slot3 | live survives; operands end at current | old preserve/reload/multiply stream exact |
| B04 `variable-i16-shift` / shl | 1 | value `[0,1]`; amount `[0,1]` | amount gpr32/RDI; value gpr32/RSI | value arg32/RDI; amount arg32/RSI | both operands consumed at current | old rhs/lhs/shift stream exact |
| B04 `variable-i16-shift` / lshr | 1 | value `[0,1]`; amount `[0,1]` | amount gpr32/RDI; value gpr32/RSI | value arg32/RDI; amount arg32/RSI | both operands consumed at current | old rhs/lhs/shift stream exact |
| B04 `i32-ashr` / immediate rhs | 0 | value `[0,0]`; amount `[0,0]` | amount gpr32/RDI; value gpr32/RSI | value arg32/RDI; amount arg32/RSI | value consumed at current; named amount is the sibling plan identity | old immediate stream exact |
| B04 `i32-ashr` / named rhs | 0 | value `[0,0]`; amount `[0,0]` | amount gpr32/RDI; value gpr32/RSI | value arg32/RDI; amount arg32/RSI | both operands consumed at current | old variable stream exact |

The existing instruction, result-binding, source-binding, and diagnostic
assertions remain unchanged for every row except the two explicitly
reviewed B05/B06 rows sharing the exact-EI fixture.

## Option-A current-inclusive movement proof

The renamed test
`generic cfg selector exact ei binary and shift preserve a current accumulator lhs`
covers B06 `or i55` and B05 `shl i56` under one production-shaped loop.
Both meet all five reviewed criteria:

1. The old fixture installed no allocation plan.
2. The truthful source and amount intervals are `[0,1]` at
   `current_position=1`.
3. Both accepted legacy paths call
   `accumulatorPreserveCurrentDisplacement`, whose current-inclusive
   `liveAccumulatorName` result selects `.spill_source`.
4. The accepted no-plan source and compiled test artifact reproduce the
   old stream.
5. The only changed instructions and binding are the deterministic spill
   and canonical reload selected by that authority.

Before, for each inline case:

```text
plan=absent
instructions=[
  mov_arg64_arg rcx,rsi,
  <or_rax_rcx | shl_rax_cl>,
]
source_binding=RAX
result_binding=RAX
```

After:

```text
plan=real; source=[0,1]; amount=[0,1]; current_position=1
instructions=[
  mov_arg64_arg rcx,rsi,
  spill_rax_rsp slot0,
  reload_rsp_rax slot0,
  <or_rax_rcx | shl_rax_cl>,
]
source_binding=spill64/slot0
result_binding=RAX
```

The detached no-plan source came from HEAD `5284cea9`, tree
`806f9531319cc8012096963580a642c8f5af427e`. It was copied to ignored
evidence storage and the detached worktree was removed. No permanent
plan-blind test was added.

```text
plan_blind_source_sha256=7cedc1451e8c4ab9c71114120ad97e25e90bbfbbb8f4a093205de151b839cf2e
plan_blind_unit_artifact_sha256=ad68fcd96ee990a0415cd7b572a6a2d99ac24f751aa609b668ce869f09ca70b7
plan_blind_unit_artifact_bytes=132720546
command=tmp/inbox154_o2_admission_fixture_alignment/plan_blind_proof/unit_test_binary > tmp/inbox154_o2_admission_fixture_alignment/validation/plan_blind_unit_binary.log 2>&1
result=1339/1339 tests passed
log_sha256=4f7799d04beaa47beb7faaa957a6d9f066f7e4144c026d23c515f86b8b8d0fd5
```

This evidence is historical attribution only. Production correctness is
covered by the truthful plan-visible fixture and the frozen whole-cohort
identities.

## Admission characterization

`value-use current binding characterizes missing plan and missing interval`
uses a real current arg64/RDI binding at position 2 and proves:

```text
missing plan     -> ValueUseSourcePlanMissing
missing interval -> ValueUseSourceIntervalMissing
failedRequestIs(source)=true
instructions/dependencies/binding unchanged
```

`value-use forward metadata characterizes legacy resolution before Q1 admission`
freezes the present behavior without inventing future-Q1 errors:

| Case | Legacy/shared resolution | Current transaction admission |
|---|---|---|
| valid forward identity, def=5/current=2/end=7, gpr64/64, assignment R9 | scratch64/R9 | `ValueUseUnresolvedSource`, source provenance |
| stale definition, def=current=5 | null | `ValueUseUnresolvedSource`, source provenance |
| expired interval, current=3/end=2 | scratch64/R9 (legacy does not consult interval) | `ValueUseUnresolvedSource`, source provenance |
| class mismatch, forward gpr32 vs assignment gpr64 | null | `ValueUseUnresolvedSource`, source provenance |
| defined-width mismatch, forward gpr64/32 vs 64-bit request | scratch64/R9 (legacy does not validate width) | `ValueUseUnresolvedSource`, source provenance |
| missing assignment | null | `ValueUseUnresolvedSource`, source provenance |

Every characterization begins a real transaction, registers the semantic
request, and reaches `seal()`. No mutation occurs and the first-request
provenance is retained.

## Immutable B07 forward inputs

The six accepted cohort traces are encoded as exact future regression
inputs. Each uses the current transaction behavior
`ValueUseUnresolvedSource` and source-handle provenance:

| Function | Source | Current / interval end / definition | Metadata | Assignment | Legacy resolution |
|---|---|---|---|---|---|
| `compiler_rt.floatuneidf.__floatuneidf` | `%20` | 25 / 42 / 37 | gpr64/64 | R9 | scratch64/R9 |
| `compiler_rt.floatuneisf.__floatuneisf` | `%20` | 25 / 42 / 37 | gpr64/64 | R9 | scratch64/R9 |
| `compiler_rt.floatuneihf.__floatuneihf` | `%20` | 25 / 42 / 37 | gpr64/64 | R9 | scratch64/R9 |
| `compiler_rt.floateidf.__floateidf` | `%26` | 29 / 47 / 42 | gpr64/64 | spill 0 | spill64/slot0 |
| `compiler_rt.floateisf.__floateisf` | `%26` | 29 / 47 / 42 | gpr64/64 | spill 0 | spill64/slot0 |
| `compiler_rt.floateihf.__floateihf` | `%26` | 29 / 47 / 42 | gpr64/64 | spill 0 | spill64/slot0 |

The dependency domain is canonically empty for all six. These tests
characterize the future forward-Q1 design boundary; they do not relax it.

## Production hash identity and performance omission

Performance is omitted because the complete production contract is
byte-identical to accepted commit `e048ff5c`. The full 423-row proof is
tracked in
`docs/evidence/inbox154_o2_performance_omission_hash_contract.tsv`.

```text
command=/home/oleg/bin/zig run tmp/inbox148_o2_checkpoint_slice4/hash_contract.zig -- e048ff5c docs/evidence/inbox154_o2_performance_omission_hash_contract.tsv 2>&1 | tee tmp/inbox154_o2_admission_fixture_alignment/validation/performance_omission_hash_contract.log
result=423/423 identical
production=310
tools=72
build_configuration=1
build_roots=37
facades=3
table_sha256=93f3dad2b82cc731db27f4145430cacaa941822b05c1b66a435dd294a486299a
log_sha256=9b4235b0126f8e0409e969aaafdc5c7633f264455b109ced36d76bd5238f2b86
```

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox154_o2_admission_fixture_alignment/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox154_o2_admission_fixture_alignment/validation/accepted.o 2> tmp/inbox154_o2_admission_fixture_alignment/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox154_o2_admission_fixture_alignment/validation/owner_manifest.tsv 2> tmp/inbox154_o2_admission_fixture_alignment/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox151_o2_family_isolation/results/baseline/accepted.o tmp/inbox154_o2_admission_fixture_alignment/validation/accepted.o > tmp/inbox154_o2_admission_fixture_alignment/validation/function_diff.tsv
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167 composed / 17 legacy / 101 structural
accepted_stderr_bytes=0
owner_stderr_bytes=0
per_function=285 compared / 0 divergent / 0 missing
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
```

## Correctness gates

All commands ran against the final test source state. Logs are retained
under `tmp/inbox154_o2_admission_fixture_alignment/validation/`.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox154_o2_admission_fixture_alignment/validation/source_guard.log
result=50/50 passed
log_sha256=973bd4f8ee08f195dff21cc112d9191b5d5e57a17de52c87f96aaf093ed208c3
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox154_o2_admission_fixture_alignment/validation/full_unit.log
result=7/7 steps; 1342/1342 tests
log_sha256=f1759049622159b00316849dc786f225450ac8516b5b976d8f1683398a562cdc
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox154_o2_admission_fixture_alignment/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=d77021c53f46775c373ba812653e4fddceccf4b3b3e22081476bc19ebca1769b
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox154_o2_admission_fixture_alignment/validation/focused_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 object/stream/symbol/helper checks exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox154_o2_admission_fixture_alignment/validation/integrated_exe.log
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=1bde3882401aa625fcc9975f3c0868ee04b729f5cb6e2df42b2522643562d791
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox154_o2_admission_fixture_alignment/validation/strengthened_tier2.log
result=29/29 steps; 1350/1350 tests
log_sha256=70822ccf5e5d5e6dbd02079b95e34db8cc735fdd89aa41da46dbb84a71173416
```

No `distribution-all` command was run. No Tier 3 command was run.
`stash@{0}` and every preserved carrier/patch remain untouched.
