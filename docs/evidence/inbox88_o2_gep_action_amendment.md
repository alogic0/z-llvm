# INBOX-88 O2-3B1A2 dormant GEP action amendment

Status: implemented and validated; delivered for Supervisor/Reviewer review.
O2-3B1B remains unauthorized and no production consumer is wired.

## Base and boundary

The accepted B1A production base is commit
`4582a832` with tree `c490891e15949b914d80b3cc4cebecc591819baf`.
The directive arrived at documentation-only descendant `6a00d070`; the
intervening commits change only `docs/next_steps.md`, and
`git diff 4582a832..6a00d070 -- src tools build.zig` is empty. This amendment
therefore preserves the accepted B1A production base while retaining the
tracked hard-stop and dispatch record.

This slice changes only the dormant `ValueUseTransaction`, its white-box
tests, this summary, and the machine-readable complete API-fit audit. It does
not change `composed_selector_memory.zig`, any production lowerer, emitter
route, tool, mandatory runner, bypass inventory, or ratchet count.

## Narrow bounded-descriptor admission

The new `stack_f32_pair_byte_address` use form is action-only. It is accepted
only with a sealed `form_byte_address` action, a typed address-space-zero
pointer expectation, and the existing `stack_pointer` virtual-register class.
It is rejected as a prepared source, fixed-destination request,
`emit_copy_to`, validation action, and generic `.pointer` request. Generic
pointer materialization remains unchanged and still rejects
`.stack_f32_pair_ptr`.

The private prepared representation records only `object_base_disp` and
`disp`; neither representation nor a discovered location crosses the closed
action API. Constant formation:

- preserves `object_base_disp`;
- derives the inclusive upper bound with `aggregate_object.byte_size`;
- accepts displacement in `[object_base_disp, object_base_disp + byte_size]`,
  including the one-past-end pointer;
- fails closed on signed addition overflow, u32 conversion underflow/overflow,
  object-end overflow, below-base displacement, and above-end displacement;
- performs no physical write, while the durable result binding remains owned
  by the transaction snapshot.

Named offsets use the accepted physical path: materialize the bounded base to
R8, materialize the registered offset to RCX, append the add, and bind the
result as ordinary `scratch64(RCX)`. The result deliberately does not retain
bounded-descriptor status. Seal declares exactly R8 and RCX plus their source
mappings for this path. Constant bounded adjustment declares no physical
destination or mapping.

## Complete four-lowerer API-fit audit

`inbox88_o2_gep_api_fit_audit.tsv` records every accepted branch in
`lowerGep`, `lowerBytePointerGep`, `lowerI32ElementPointerGep`, and
`lowerReadOnlyTableGep`, including delegated dispatcher branches. The audit
found no other missing accepted source or result representation after the
bounded f32-pair form was added. It contains 15 rows: 6 `lowerGep`, 5
`lowerBytePointerGep`, 3 `lowerI32ElementPointerGep`, and 1
`lowerReadOnlyTableGep`.

The audit did identify two dormant policy-fit details needed to preserve the
accepted rejection boundary without raw consumer resolution:

- `form_scaled_address` now accepts optional semantic
  `expected_stack_array_len` intent. Stack-array paths validate it internally;
  non-array paths reject a supplied array-length contract. This preserves
  `lowerGep`'s source-array-length check.
- indexed `stack_i32_ptr` addend formation now requires the accepted RCX index
  and one-level descriptor depth, and readonly-table byte adjustment now
  requires exactly offset 8 from prior offset 0 on a shape that permits 8.

These are general action invariants, not function/family predicates. They add
no location to a public descriptor and no production capability. All other
accepted branches already fit: stack-array constant/named derivation,
stack-i32 descriptor chaining, generic byte and scaled pointer formation, and
readonly-table symbol/index formation. The dispatcher-owned readonly
provenance marker is metadata after successful delegated lowering and is not
a missing source/result form.

## Focused coverage

The amendment adds coverage for lower-bound-minus-one, offsets 0/4/8,
inclusive one-past-end, upper-bound-plus-one, object-end overflow, exact
dynamic instruction order, deliberate loss of bounded status on dynamic
formation, result/label rollback, action-only admission, constant no-write
planning, dynamic R8/RCX conflict detection, stack-array length mismatch,
indexed-descriptor register mismatch, and exact readonly-table offset policy.
The pre-existing address-action cycle negative continues to exercise the same
seal-time physical mapping graph and rejects a genuine RCX/R8 copy cycle.

## Validation

The final code state passed the authorized focused and full validation:

```text
focused_bounded_and_api_fit=4/4
focused_source_guard=18/18
full_unit=1133/1133
full_unit_log_sha256=f5e688b37c8403e3c1646a3435b9f0206add35cf4d9132e972051aefa0f15efd
abi_differential_from_full_unit=60/60 cases; 30/30 real functions; result=pass
production_consumer_wiring=none
frozen_bypass_inventory=current-tree-pass; unchanged
tier3=not-run
```

The fresh post-final-code cohort log is
`tmp/inbox88_b1a2_full_report.log`:

```text
capture_sha256=7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The report is byte-identical to the accepted baseline. `git diff --check`
passes, formatting is clean, no temporary focused-test root remains, and a
production-source search finds no `ValueUseTransaction` use outside its
dormant module/export. No Tier 3 was run.

B1B remains on hold. After B1A2 acceptance its five warmed BEFORE performance
samples must be recaptured at the accepted B1A2 tree because this dormant
amendment changes the compiled binary.
