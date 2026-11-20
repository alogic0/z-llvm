# INBOX-168 — dormant unsigned quotient actions

Status: implementation and required dormant validation complete; stopped for
Supervisor/Reviewer review. No composed-selector production consumer was
wired, the direct-materialization ratchet remains 135, and no performance,
strengthened Tier 2, or Tier 3 command was run.

## Frozen basis

```text
authorization_head=ae18e0035bc90a2292ab2d0c73815f05887e59c1
authorization_tree=aa77288c2202bbb8d780ba532797ba9a413bf1bf
accepted_INBOX_167=f5b6c516
accepted_semantic_ratchet=135 (unchanged)
stash_at_0=INBOX-93 preserve B2B wiring plus five diagnosis tests (untouched)
performance_run=none
tier2=not_run
tier3=not_run
```

The production scalar consumer is byte-identical to the accepted
INBOX-167 tree:

```text
composed_selector_scalar_sha256=ac4ffae4e822d7056b655e11c72096af29ff5b715e61846f3af6e82c4bfeb8fd
accepted_INBOX_167_composed_selector_scalar_sha256=ac4ffae4e822d7056b655e11c72096af29ff5b715e61846f3af6e82c4bfeb8fd
production_unsigned_quotient_markers=0
direct_materialization_ratchet=135
```

`lowerUnsignedDivRem`, its early `.urem` dispatch, and
`lowerUnsignedRem` are untouched. The source guard rejects
`isUnsignedQuotient`, `attachUnsignedQuotientAction`,
`.unsigned_quotient`, or `executeUnsignedQuotient` in every
composed-selector production consumer. Retained remainder and combined-result
paths therefore keep their existing authority and diagnostics.

## Closed surface and ownership

`value_use/actions/scalar_multiply_divide.zig` now has exactly six
technically public declarations: the accepted three-name multiply surface
plus the following three-name quotient surface:

```text
executeUnsignedQuotient
isUnsignedQuotient
validateUnsignedQuotientAction
```

The classifier admits only named/named `udiv i32` and `udiv i64`. The
central semantic payload contains exactly the durable result identity,
integer type, and already-registered RHS request handle. No register, home,
spill slot, displacement, width tag, staging branch, or sequencing hint
crosses the action API.

Core remains the sole exhaustive attachment and execution dispatch.
`scalar_arithmetic.zig` remains a forwarding-only facade and expands from
the accepted 23 aliases to exactly 26 aliases. The action leaf remains below
both size budgets:

```text
scalar_multiply_divide_lines=696
scalar_multiply_divide_tests_lines=663
scalar_arithmetic_facade_lines=31
scalar_multiply_divide_sha256=fd2ce0f67a2983544c139edd1d0188e8b8a3cd1057d3ce3f4382b4137cc7a0db
scalar_multiply_divide_tests_sha256=5fbd64e50a2d5473b290f3d490dcb7d4482cdb8a06994e085bccc2ee047da0ad
scalar_arithmetic_facade_sha256=9feb885916582a603442344645b59a35ee33353b7c8e50f53945dd467afda36e
facade_manifest_sha256=0925a250ac72481edb1b3c06f140d1102b615b920fb0afc98385ea49618ce6be
```

The leaf has no new planning/core dependency and introduces no physical
home, pair authority, copy-cycle scheduling, signed-division authority, or
remainder/result ownership.

## Distinct internal plans and frozen order

`UnsignedQuotientPlan` is private and contains exactly `.uq32` and `.uq64`.
Width derives only from `action.integer_ty`. The RHS-accumulator branch
derives only after canonical transaction admission from the prepared
canonical source (`EAX` for UQ32, `RAX` for UQ64). The consumer cannot choose
either branch.

Both plans preserve the frozen Section-4 lifecycle:

1. validate RHS and then LHS, preserving legacy source-order failure
   provenance;
2. derive whether the canonical RHS occupies the matching accumulator;
3. open one subordinate accumulator session under the outer transaction;
4. if RHS is accumulator-resident, stage it to RCX before accumulator
   preparation, then canonically refresh and materialize LHS;
5. otherwise prepare/materialize LHS first, canonically refresh RHS, and
   stage RHS to RCX;
6. preserve/clobber RDX, emit `xor edx,edx` as incidental `.write`, and emit
   width-specific `div rcx` as `.clobber`;
7. own the result identity durably, define EAX as `.zeroExtending(32)` or
   RAX as `.fullRax()`, and finalize through the sole outer authority.

The accepted displacement table is internal: a named LHS already in the
matching EAX/RAX uses `.reuse_source`; all other admitted LHS homes use
`.spill_live`. Canonical availability and prepared records are revalidated
after mutations. RCX and RDX preservation remain the existing selector
authorities rather than duplicated action-local mechanisms.

All physical candidates participate in seal planning. There is one outer
snapshot and zero subordinate snapshots.

## Focused coverage

Every new fixture installs a real allocation plan with exact
current-inclusive intervals, canonical assignments and bindings, and
canonical dependency state. Coverage proves:

- the exact UQ32 and UQ64 non-accumulator streams;
- the exact UQ32 and UQ64 accumulator-first RHS-to-RCX streams;
- width and RHS-staging selection derived internally from semantic type and
  canonical state;
- frozen RCX and RDX preservation order with live occupants;
- durable EAX/RAX result lookup and use after transaction teardown;
- RHS-before-LHS first-request provenance and width/location precedence;
- rollback at all eleven declared boundaries: RHS classification,
  accumulator-RHS staging, accumulator preparation, LHS materialization,
  non-accumulator RHS staging, RDX preservation, high-dividend zeroing,
  divide, result identity ownership, result definition, and finalization.

Rollback restores instructions, bindings, spills and counters, accumulator
state, EFLAGS semantics, labels, dependency metadata, prepared state, and
owned result identity through the existing outer snapshot.

The guards freeze the six-name leaf, 26-name scalar facade, exact payload,
error, failure-boundary, action-union, attach, import, line-budget, and
dormant-consumer contracts. Negative fixtures reject payload widening and
premature classifier/action use.

## Ratchet disposition

No quotient gateway is removed in this dormant slice:

```text
ratchet_before=135
ratchet_after=135
direct_credit=0
helper_collapse_credit=0
```

The future `131` versus `132` outcome remains deliberately unresolved.
`accumulatorDirectMaterializationDisplacement` earns a last-owner credit
only if the final separately reviewed wired tree proves zero remaining
production owners. Isolation of UQ32, UQ64, and their aggregate is a
separate directive.

## Decisive identities

The fresh full report retains its intentional exit status 1:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll >/dev/null 2>tmp/inbox168_o2_quotient_dormant/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >tmp/inbox168_o2_quotient_dormant/validation/accepted.o 2>tmp/inbox168_o2_quotient_dormant/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0
```

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >tmp/inbox168_o2_quotient_dormant/validation/owner_manifest.tsv 2>tmp/inbox168_o2_quotient_dormant/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

## Required dormant gates

Every retained gate log is paired with its exact command.

### Source guard

```text
command=set -o pipefail; /home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox168_o2_quotient_dormant/validation/source_guard.log
result=57/57_tests
log_sha256=84f662d58a342ca239975fe7d5bae96a47d32ef0f8f99a8bb03090b92cbebad4
```

### Full unit

```text
command=set -o pipefail; /home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox168_o2_quotient_dormant/validation/full_unit.log >/dev/null
result=7/7_steps,1375/1375_tests
log_sha256=c4a6786ed2048b94b8028e53c40c682062c8ac897507f1348278a198e45bd26f
```

### ABI differential

```text
command=set -o pipefail; /home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox168_o2_quotient_dormant/validation/abi_differential.log >/dev/null
result=5/5_steps,60/60_cases,30/30_real_functions
log_sha256=561edaf1101f96cb5730117b6160773153e6b9f7c7af43493dbf39a572cfa70a
```

### Focused codegen canaries

```text
command=set -o pipefail; /home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox168_o2_quotient_dormant/validation/focused_canaries.log >/dev/null
result=2/2_steps,2/2_canaries,35/35_execution_cases,__multi3_green,fma_green,no_host_libc_substitution
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

No performance, strengthened Tier 2, or Tier 3 command was run. UQ32/UQ64
isolation and any production wiring remain separate review decisions.
