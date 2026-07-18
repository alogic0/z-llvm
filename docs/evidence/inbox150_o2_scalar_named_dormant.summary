# INBOX-150 — dormant scalar named actions

Status: implementation and required validation complete; stopped for
Supervisor/Reviewer review. The slice is dormant: no composed-selector
production consumer, bypass inventory, diagnostic mapping, or ratchet entry
changed. No performance, strengthened Tier 2, or Tier 3 command was run.

## Frozen basis and boundaries

```text
authorization_head=a3cb05e34fbecf951a884bf5d394f76aa92dd65a
accepted_INBOX_149=5bc839ee
accepted_semantic_ratchet=154 (unchanged)
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
performance_run=none
tier2=not_run
tier3=not_run
```

The accepted scalar production consumer is byte-identical:

```text
composed_selector_scalar_sha256=1546fe4c600b4649ecd0aab8ee9c556e11feb70818e9d4b4ef49b0ad0e2d4c2c
frozen_bypass_inventory_sha256=155f7be0d933df9516731265d4442c3ebbc1fb9ca4d5d6f3bacc2776aa936eb6
```

R03 remains wholly owned by
`scalar_immediate_live_shared_source_preservation`; R04 remains wholly owned
by `scalar_immediate_multi_alias_preservation`. Their production dispatch,
helpers, guard anchors, and accepted streams are unchanged. The dormant named
classifiers/actions are rejected from production consumers, so neither
residual is reachable through this new action surface.

## Exact model, leaf, and facade surfaces

The central model additions match INBOX-149 section 8:

- one `named_scalar_operand` use form;
- `NamedScalarBinaryAction` and `ExactI52BinaryAction` with exactly their
  frozen semantic fields;
- the exact six-entry `NamedScalarRequestError`;
- the exact ten-boundary `NamedScalarTestFailure`;
- `named_scalar_binary` followed by `exact_i52_binary` in `PreparedAction`;
- exactly two attachment methods, one for each action.

No literal, physical register, home, displacement, preservation, sequencing,
or prepared-location field crosses the public action boundary.

`actions/scalar_named.zig` has exactly the frozen six technically public
declarations. `actions/scalar_arithmetic.zig` remains forwarding-only and has
exactly twenty aliases. Core still imports only that facade. The named leaf
imports model/composition/materialization and foundational selector types; it
does not import core, planning, a planning leaf, or another action leaf.

```text
scalar_named_lines=751
scalar_named_tests_lines=462
scalar_arithmetic_facade_lines=24
scalar_named_sha256=6de4086bb1285db52ebac352acb743e49a6778b2407def137ab71d56b9464416
scalar_named_tests_sha256=2a3ccbf1292675ea853c35184862c71d6f5a94f8dcddf9089498c9513f8c611b
scalar_arithmetic_facade_sha256=5044d3110298721028ea6565429bef5caecacef96a18e93407e906a4d0ad287c
facade_manifest_sha256=9c38e682ff462204ba63a0ab30a9e7f56927ed51ba577dffd710c4222e01a0f8
```

Both production and test leaves remain below the preferred 1,500-line target
and the 2,000-line review ceiling.

## Closed plan families

The named action derives one of six distinct private plans; the i52 action has
its own closed plan. These policies are not generalized:

| plan | admitted form | displacement authority | accepted staging boundary |
|---|---|---|---|
| B01 | named i1 `and`/`or` | direct-materialization table | rhs to RCX, then prepare/materialize lhs |
| B03 | named narrow multiply only | strict-after liveness arithmetic, `scratch_preferred` fallback | prepare lhs before rhs staging |
| B04 | named narrow variable shift | direct-materialization table | rhs to RCX, then prepare/materialize lhs |
| B05 | named wide/exact-EI variable shift | inclusive preserve-current table | rhs to RCX64, then prepare/materialize lhs |
| B06 | named exact-EI wide non-shift | inclusive preserve-current table | rhs to RCX64, then prepare/materialize lhs |
| B07 | general named scalar binary | strict-after liveness arithmetic, branch `spill_live` fallback | legacy four-way accumulator/current-home topology |
| I52B0 | structural exact-i52 guarded shift | inclusive preserve-current table | prepare lhs, rhs to RCX64, SHL, mask, AND |

B03 explicitly rejects i64 multiply; that result remains owned by the future
multiply slice. B07 preserves the accepted four branches: both operands in the
accumulator, commutative rhs in the accumulator, ordered rhs in the
accumulator with RCX/RDX avoidance, and neither operand in the accumulator.
The established live-accumulator/lhs preamble runs only for B07, followed by
canonical re-resolution.

`isExactI52Binary` follows the complete `llvm.ctlz.i52 -> trunc i6 -> nuw add
1 -> zext i52 -> shl i52` IR structure. It does not inspect a function
identity or name. The source guard has a negative that injects a
function-name admission and rejects it.

All arithmetic writes use the EFLAGS authority as incidental `.write`
records. I52B0 records two writes (SHL and AND); every other family records
one. Result identities are owned immediately before subordinate definition,
survive transaction teardown, and remain usable by a following instruction.

## Focused proof and rollback

Every fixture installs a real `SelectorAllocationPlan`, uses canonical
selector bindings and an empty canonical dependency domain appropriate to
scalar values, and models the production physical alias topology for its
family. The focused tests prove:

- the complete instruction stream and exact EFLAGS record count/effect for
  B01, B03, B04, B05, B06, B07, and I52B0;
- B03 preservation before rhs staging with live EAX plus spill-backed lhs/rhs;
- B07's both-accumulator, commutative-rhs-accumulator,
  ordered-rhs-accumulator, and ordinary current-home branches;
- structural exact-i52 admission and neighboring operation/RHS rejection;
- B03 i64-multiply rejection;
- durable result lookup and use after outer transaction teardown;
- matching-request provenance for an unresolved rhs;
- exact rollback at all ten declared boundaries: preamble, canonical refresh,
  first staging, preparation, second staging, first write, second write,
  identity ownership, definition, and finalization.

Rollback checks instructions, bindings/result absence, and EFLAGS records
against the outer snapshot. The existing transaction suite supplies the
shared spill maps/counters, accumulator-domain, labels, and dependency-domain
snapshot proofs exercised by the same outer authority.

The source guard additionally freezes the exact semantic descriptor fields,
six-name leaf budget, twenty-name facade budget, facade-only import direction,
2,000-line ceiling, exact attachment/dispatch surfaces, function-name
classifier prohibition, and complete dormancy. Negative fixtures reject
physical action intent, incomplete descriptors, leaf-public widening,
function-name admission, classifier use, and attachment use in a production
consumer.

## Validation

Every retained gate log is paired with its exact command.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox150_o2_scalar_named_dormant/validation/source_guard.log
result=50/50_tests
log_sha256=884584c325fae90cbc8f7e4626e8569782d755a084eb6f707fc5bf0eff924cdb
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox150_o2_scalar_named_dormant/validation/full_unit.log
result=7/7_steps,1339/1339_tests
log_sha256=f0be57d254d473324809c1aeff32dd7b072098b86c17f521b14c7fccfc42e38a
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox150_o2_scalar_named_dormant/validation/abi_differential.log
result=5/5_steps,60/60_cases,30/30_real_functions
log_sha256=3b6ad9bab08ba283aa7e0f730e6b4c6843a0d43b7e275afe39850afd5264fcd3
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox150_o2_scalar_named_dormant/validation/focused_canaries.log
result=2/2_steps,2/2_canaries,35/35_execution_cases,__multi3_green,fma_green,no_host_libc_substitution
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Frozen report identity

The accepted report command exits `1` because it intentionally reports the
158 frozen failures.

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox150_o2_scalar_named_dormant/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox150_o2_scalar_named_dormant/validation/accepted.o 2> tmp/inbox150_o2_scalar_named_dormant/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox150_o2_scalar_named_dormant/validation/owner_manifest.tsv 2> tmp/inbox150_o2_scalar_named_dormant/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

The ratchet remains exactly 154. No production wiring, performance command,
strengthened Tier 2, or Tier 3 command was run.
