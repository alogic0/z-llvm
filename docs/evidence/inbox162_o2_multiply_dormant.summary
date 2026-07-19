# INBOX-162 — dormant scalar i64 multiply action

Status: implementation and required dormant validation complete; stopped for
Supervisor/Reviewer review. No composed-selector production consumer was
wired, the direct-materialization ratchet remains 140, and no performance,
strengthened Tier 2, or Tier 3 command was run.

## Frozen basis

```text
authorization_head=5756e45e9dc8260b1bc8ce81aaeb63dc7d3bda14
accepted_INBOX_161=2006570f
accepted_semantic_ratchet=140 (unchanged)
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
performance_run=none
tier2=not_run
tier3=not_run
```

The production scalar consumer is byte-identical to the accepted ratchet-140
tree:

```text
composed_selector_scalar_sha256=79b11acbad195436c900e2a3a3344e8f816f90d4fbd447a5a2fc367c2b17f965
production_scalar_multiply_markers=0
direct_materialization_ratchet=140
```

`lowerMul64`, `lowerMul64SpillLhsThroughRax`, and their selector dispatch are
untouched. The source guard rejects `isScalarMultiply`,
`attachScalarMultiplyAction`, `.scalar_multiply`, or
`executeScalarMultiply` in every composed-selector production consumer.

## Closed surface and ownership

`value_use/actions/scalar_multiply_divide.zig` has exactly the frozen three
technically public declarations:

```text
executeScalarMultiply
isScalarMultiply
validateScalarMultiplyAction
```

The classifier admits only `mul i64 <named>, <named>` and observes IR
semantics only. The central action payload contains exactly result identity,
integer type, and the already-registered rhs handle. No register, location,
spill slot, destination, displacement, ordering, or fallback choice crosses
the API.

The scalar facade remains forwarding-only and expands from the accepted
twenty aliases to exactly twenty-three aliases:

```text
scalar_multiply_divide_lines=411
scalar_multiply_divide_tests_lines=344
scalar_arithmetic_facade_lines=28
scalar_multiply_divide_sha256=9a32e275c70a10d9feb09cb98dd7814dc9d6649601e0aa1a226fd6bda50bd1c0
scalar_multiply_divide_tests_sha256=a70e535f40db03ae600d70dbf4ba5b1d9eed483a92f3b96e6a2ba5fc71ca5951
scalar_arithmetic_facade_sha256=52d434214d7c21bb017d0d58b4cda3c075acf61ac020e1b5ad9c3af06d564cd9
facade_manifest_sha256=477769d5111199b9d6b9a0f5e16a47a19f5e0bb8cdb9fa45bf7aeb0f463c82d5
```

Core remains the sole exhaustive attachment/execution dispatch. The leaf
imports only the section-6 lower layers and foundational selector types; it
does not import core, planning, materialization, another action leaf, the
scalar facade, or the scalar production consumer. The leaf is below both the
preferred 1,500-line target and 2,000-line hard stop. Quotient/division adds
no action, model tag, error, facade alias, or execution path in this slice.

## Internal plan derivation

M64-D and M64-R are distinct private plans of one semantic action. The
consumer cannot select either plan:

| plan | canonical internal decision | exact lifecycle |
|---|---|---|
| M64-D | scratch lhs reuse, planned result scratch, free scratch, or the accepted spill-and-reuse decision | select destination; preserve/spill if required; canonically refresh; stage lhs; resolve rhs; use rhs register/RAX, second scratch, or accepted RAX reload; `imul`; durably bind scratch64 result |
| M64-R | lhs is spill64 and canonical state supplies no scratch destination | open one subordinate accumulator session; prepare with hardcoded `.spill_live`; canonically refresh; reload lhs to RAX; re-resolve rhs; `imul rax,reg` or `imul rax,[spill]`; durably define full RAX; finalize |

All candidate physical writes participate in seal planning. Every arithmetic
instruction is appended through the EFLAGS authority with incidental
`.write`. Neither plan introduces a physical home, pair authority, copy-cycle
resolver, fixed-register quotient authority, or consumer-side inspection.

## Focused coverage

Every fixture installs a real allocation plan with exact current-inclusive
intervals, canonical selector bindings, and the canonical empty scalar
dependency domain. The tests prove:

- M64-D planned destination selection and exact register-register stream;
- the M64-D spill-rhs path with no second scratch, including the accepted RAX
  reload and instruction order;
- M64-R selection for a spill-backed lhs with all scratch destinations live,
  including exact accumulator preparation/reload and spill-memory multiply;
- accumulator fallback and second-scratch-unavailable topology;
- durable result lookup after transaction teardown for scratch and RAX
  results;
- lhs-before-rhs source-order failure provenance for both destination and
  accumulator fixture shapes;
- width/class diagnostic precedence and rhs attribution for both plan
  branches;
- exact rollback at all twelve declared boundaries: destination selection,
  lhs preservation, canonical refresh, lhs staging, rhs resolution, rhs
  staging, accumulator preparation, lhs accumulator reload, multiply, result
  identity ownership, result definition, and finalization.

Rollback restores instructions, lhs/rhs/result bindings, EFLAGS records, the
outer transaction state, spills/counters, accumulator state, labels, and
dependency metadata through the existing single outer snapshot. Result
identity ownership occurs only at the durable container boundary immediately
before binding/definition.

The guards freeze the three-name leaf, twenty-three-name facade, exact model
payload/error/failure sets, import direction, line ceiling, semantic
classifier, and dormant production boundary. Negative fixtures reject a
physical payload extension and premature classifier/attachment use.

## Decisive identities

The fresh full report retains its intentional exit status 1:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox162_o2_multiply_dormant/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox162_o2_multiply_dormant/validation/accepted.o 2> tmp/inbox162_o2_multiply_dormant/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0
```

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox162_o2_multiply_dormant/validation/owner_manifest.tsv 2> tmp/inbox162_o2_multiply_dormant/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

## Required dormant gates

Every retained gate log is paired with its exact command.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox162_o2_multiply_dormant/validation/source_guard.log
result=55/55_tests
log_sha256=610cf0022a86aaaaebdb9eeb39ce1615ac1e1fb4a3bcf4642e040fa18b1667f6
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox162_o2_multiply_dormant/validation/full_unit.log
result=7/7_steps,1365/1365_tests
log_sha256=901dd2314e9362e0c808f4bb1157b28538c9b4f4b32ecdd1f5bb5396a533b553
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox162_o2_multiply_dormant/validation/abi_differential.log
result=5/5_steps,60/60_cases,30/30_real_functions
log_sha256=004ea804391cd659fa5bce7e4ac10d8812686b887e3684723d4fa519e578797b
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox162_o2_multiply_dormant/validation/focused_canaries.log
result=2/2_steps,2/2_canaries,35/35_execution_cases,__multi3_green,fma_green,no_host_libc_substitution
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

No performance, strengthened Tier 2, or Tier 3 command was run. Whole-family
isolation and any production wiring toward conditional ratchet 135 remain
separate review decisions.
