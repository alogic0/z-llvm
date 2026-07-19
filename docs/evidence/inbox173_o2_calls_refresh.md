# INBOX-173 — O2 calls evidence refresh

Date: 2026-07-19

Scope: evidence only

Accepted source tree: `d27c1613cc9a3b01cba6d9f46c098106bc1161a2`

Accepted O2 bypass ratchet: **131 (unchanged)**

## Result

The inherited “calls = 18” population is not a valid production target from
the accepted ratchet-131 tree. It mixed seven already-migrated unary
intrinsics, eight still-unmigrated non-call semantic intrinsics, and three
gateways that actually participate in machine-call argument lowering.

The accepted tree contains exactly three remaining true-call staging
gateways:

| Semantic owner | Textual gateway | Occurrences | Direct credit if migrated | Reason |
|---|---|---:|---:|---|
| ordinary direct call | `lowerDirectCallArg/resolveValue` | 2 | 0 | both source rows remain owned by `lowerScalarSseCall`, an O3 scalar-SSE residual |
| `zig.target.intByteSize` specialized call | `lowerIntByteSizeCall/emitValueIntoScratch` | 1 | 1 | distinct one-argument call path; no residual owner of this gateway |

There is no proven last-owner collapse in the call scope. Therefore:

```text
accepted ratchet                         131
ordinary direct-call semantic migration  -0
intByteSize direct gateway                -1  (conditional on future isolation/wiring)
helper-collapse credit                    -0
conditional calls target                 130
```

The ratchet remains **131** in INBOX-173. `130` is only a conditional future
target. No dormant action or production wiring is authorized here.

## Evidence provenance

This refresh used read-only inspection of the accepted tree and retained
accepted artifacts. It ran no Zig build, test, gate, cohort regeneration,
performance measurement, or Tier 3 command.

| Evidence | SHA-256 / value |
|---|---|
| accepted source commit | `d27c1613cc9a3b01cba6d9f46c098106bc1161a2` |
| frozen remaining bypass TSV | `2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11` |
| accepted cohort IR, `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| accepted owner manifest | `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d` |
| accepted report | `49a19f04`, `443/285/158`, first failure `compiler_rt.trunc.truncl` |
| accepted object | `061a64e4` |
| accepted owner projection | `5d91960e`, `167/17/101` |
| `composed_selector_calls.zig` | `f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d`, 1,264 lines |
| `value_use/actions/calls.zig` | `d6b6fd404f8eacc462bf2f9da575cacd6877268ff0407346f8a33aec8aa18fe3`, 215 lines |
| `value_use/actions/calls_tests.zig` | `431a6e1ae2a14b9c17d89e17081676360d7cddca7a2dcde65a2024e4489d8251`, 397 lines |
| `value_use/model.zig` | `32f3086a8fc714245ee9a211e16ce8eb90a32496a2d0f87f1f2e3e5ac27ea3ef`, 1,819 lines |
| `value_use/core.zig` | `728a809c5be17842b3249303ed2053b197ec82e678c9a2942eec866d4409a88e`, 1,295 lines |
| `value_use/composition.zig` | `bcecd26f7faef31621695b940db55bcc4060bf12476c1803404d13f3ec95e82c`, 277 lines |
| `composed_selector_state.zig` | `67849603c8355f5c0aa69f7e06da091199043bb2b3d13a51b593e822ae10657f`, 2,754 lines |
| frozen facade manifest | `0925a250ac72481edb1b3c06f140d1102b615b920fb0afc98385ea49618ce6be`, 122 symbols |

Reproduction commands used for the static inventory:

```text
git rev-parse HEAD
sha256sum docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
rg -n 'composed_selector_calls.zig' docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
rg -n 'lowerDirectCallArg|lowerIntByteSizeCall|spillLiveCallerClobbersForCall|accumulatorInputDisplacement' src/codegen/x86_64/generic_cfg/composed_selector_calls.zig
rg -n 'lowerDirectCallArg\\(' src/codegen/x86_64/generic_cfg/composed_selector_calls.zig
sha256sum tmp/inbox63_accepted_cohort.ll tmp/inbox172_o2_quotient_wiring/validation/owner_manifest.tsv
```

## Reconciliation of the stale 18-site population

The old “calls = 18” composition population reconciles exactly:

| Population | Occurrences | Disposition at ratchet 131 |
|---|---:|---|
| fixed-unary accumulator calls | 7 | already migrated by INBOX-102 |
| ordinary direct-call argument gateways | 2 | still textual; shared with scalar-SSE |
| `intByteSize` argument gateway | 1 | still textual; true specialized call |
| `fshl` intrinsic | 1 | not a machine-call family |
| i128 compare intrinsics | 2 | not a machine-call family |
| signed-multiply-overflow intrinsic | 2 | not a machine-call family |
| unsigned-overflow intrinsics | 3 | not a machine-call family |
| **Total** | **18** | reconciled |

The current calls source contributes 17 occurrences across 10 TSV entries to
the global bypass inventory, not the stale population of 18. Besides the 11
unresolved occurrences above, six occurrences are separately retained FP,
pair, alias, or shared-helper ownership:

| Current textual owner | Occurrences | Frozen future owner |
|---|---:|---|
| `accumulatorInputDisplacement` | 1 | `call_intrinsic_accumulator_displacement` |
| `lowerAbsI128` | 1 | `call_intrinsic_pair_result` |
| `lowerFpAbs` | 2 | `call_intrinsic_fp_xmm_o3` |
| `lowerFpBarrier` | 2 | `call_inline_asm_fp_barrier_o3` |

Those six occurrences are not call-action credits. The eight unresolved
intrinsic occurrences are likewise named residuals:

| Current textual owner | Occurrences | Frozen future owner |
|---|---:|---|
| `lowerFshlI32` | 1 | `scalar_intrinsic_fshl` |
| `lowerI128Compare` | 2 | `pair_compare_call_intrinsic` |
| `lowerSmulOverflowI64` | 2 | `full_product_multi_result` |
| `lowerUnsignedOverflowI32` | 3 | `multi_result_overflow` |

Already-migrated `lowerInlineMemcpy` is excluded completely. It has no
remaining bypass row and its closed `inline_memcpy` action is not a general
call capability.

## Actual call-family census

Read-only inspection of the accepted cohort and owner manifest finds the
following non-intrinsic direct-call shapes in selected composed functions:

| Family | Accepted cohort call instructions | Argument uses | Ownership |
|---|---:|---:|---|
| scalar-SSE ABI calls | 30 | mixed GPR/SSE | retained wholesale by `direct_call_scalar_sse_o3` |
| ordinary GPR/pointer direct calls | 2 | 6 (two `i64`, one pointer per call) | candidate ordinary direct-call family |
| i128-result direct calls | 2 | pair/multi-result | retained by `direct_call_i128_pair_result` |
| specialized `zig.target.intByteSize` calls | 12 | 12 named `i16` | candidate specialized family |

The two ordinary candidate calls are the `__udivmoddi4` calls in
`compiler_rt.int.__umoddi3` and `compiler_rt.int.__moddi3`. This census is
not a claim that the complete semantic family has only two forms: unit
coverage also includes zero-argument calls, void results, scalar integer and
pointer results, multiple arguments, aliases, live caller-clobber pressure,
and rejected call envelopes. Those forms remain part of any future complete
family design and isolation.

The six frozen O2 frontier rows remain outside an O2-3 call landing:

| Shape | Rows | Current diagnostic / owner |
|---|---:|---|
| named pointer already in a register | 1 | `composed-block-call-ptr-arg` / `direct_call_pointer_frontier` |
| typed immediate-null pointer | 5 | `composed-block-call-unknown-ptr-arg` / `direct_call_pointer_frontier` |

They must remain byte-identical. Typed null for a use transaction exists as a
general request capability, but these rows are not authorization to move the
call frontier; several also intersect retained i128 result ownership.

## Authority partition

The future call design must keep the following authorities distinct. A
single outer transaction may own rollback without merging their semantics.

| Authority | Accepted owner and required boundary |
|---|---|
| semantic dispatch/envelope | `lowerCall` dispatches intrinsics, inline assembly, indirect calls, unsupported forms, scalar-SSE, envelope, signature, and result-width decisions before an O2 transaction opens |
| callee resolution | ordinary admitted calls copy an existing direct IR symbol; `callee_value` remains `direct_call_indirect_callee_resolution`; no indirect target request or new callee-home authority |
| argument value admission | named operands register in IR source order; ValueUseTransaction is the sole current-binding/forward-Q1, type/class/width, assignment, and dependency authority |
| caller-clobber preservation | existing `spillLiveCallerClobbersForCall` remains authoritative and executes exactly once inside the outer instruction authority; no duplicate scratch move or spill loop |
| ABI destination planning | argument destinations derive internally from semantic types and source order; the consumer supplies no discovered register, home, or staging order |
| argument staging | current homes resolve only after preservation; all requests re-resolve canonically; safe same-source/multiple-destination remains supported; genuine cycles remain `direct_call_parallel_copy_cycle_o4` |
| stack alignment | accepted conditional `sub rsp, 8` / `add rsp, 8` remains inside the complete action sequence; no consumer-side partial commit |
| call emission | append the direct symbol only after every argument is staged; no general-call, indirect-call, tail-call, or stack-argument expansion |
| EFLAGS | accumulator-result ordinary calls and `intByteSize` use the EFLAGS authority with `.clobber`; accepted no-transaction void/i128/FP paths currently append directly and must not be silently normalized by this slice |
| result definition | i32 uses `.zeroExtending(32)`, i64/pointer uses `.fullRax()`, `intByteSize` masks EAX then uses `.zeroExtending(16)`; void has no session; FP/XMM and i128/pair results remain retained |
| rollback/commit | one outer ValueUseTransaction owns instructions, bindings, spills, caller-clobber preservation, EFLAGS, dependencies, counters, labels, and any subordinate accumulator session; one snapshot; subordinate snapshot copies zero |
| post-call liveness | strict future survival remains the existing liveness/caller-clobber authority, named `direct_call_post_call_liveness_preservation`; no call action invents liveness or a function predicate |

## Frozen validation order and request provenance

The current `lowerCall` order is part of the byte/diagnostic contract:

1. Dispatch debug, inline-assembly, intrinsic, memcpy, and special call forms.
2. Reject `callee_value`, unsupported call form, scalar-SSE delegation, call
   envelope, signature, result type, and result width.
3. Start the one result authority when applicable and perform caller-clobber
   preservation before argument staging.
4. Visit arguments in IR source order.
5. For each argument, obtain the ABI target; then preserve the legacy
   per-argument order:
   - pointer: resolve first, classify the accepted stack address, clobber/move
     the base, then validate/emit displacement;
   - non-pointer: validate integer type and width, then resolve; for i128,
     validate the second ABI register and pair home; for scalars, validate
     home and physical width.
6. Only after that argument stages, increment the ABI index from the declared
   type and enforce the total register count.
7. Finish accumulator preparation, align, emit the call, unalign, then define
   and commit the result.

Future registration must occur for all named operands before mutation, but
seal/action execution must preserve the legacy timing above: checks that
historically followed an earlier operand's staging cannot be hoisted across
that boundary merely to simplify validation.

Each operand retains its own handle in source order. A request-specific error
maps to a legacy diagnostic only when `failedRequestIs(handle)` matches that
operand. The first precise request failure is never overwritten by the action
owner or a later operand. Caller-clobber, EFLAGS, phase, capacity, copy-cycle,
alignment, allocation, and call-emission failures remain authority-level and
match no request. There is no retry, fallback, consumer-side home query, or
consumer-side forward resolution.

## Retained owners

The following names are frozen for residual accounting:

| Retained owner | Scope |
|---|---|
| `direct_call_indirect_callee_resolution` | every `callee_value` call |
| `direct_call_scalar_sse_o3` | scalar-SSE arguments/results and the retained `lowerDirectCallArg` owner |
| `direct_call_i128_pair_result` | accepted i128-result direct calls |
| `direct_call_multi_result` | combined/pair result ownership not expressible as an accumulator result |
| `direct_call_pointer_frontier` | the six frozen target rows |
| `direct_call_scalar_immediate_argument` | scalar literal argument materialization, still unsupported |
| `direct_call_parallel_copy_cycle_o4` | genuine ABI argument copy cycles |
| `direct_call_post_call_liveness_preservation` | caller-clobber preservation and strict survival |
| `direct_call_stack_argument_abi` | stack-passed scalar arguments |
| `direct_call_aggregate_abi` | aggregate/byval argument and result forms |
| `direct_call_tail_abi` | tail-kind/call-form expansion outside the accepted envelope |
| `scalar_sse_call_xmm_result_o3` | XMM result binding and FP preservation |
| `scalar_intrinsic_fshl` | non-call intrinsic residual |
| `pair_compare_call_intrinsic` | i128 comparison intrinsic residual |
| `full_product_multi_result` | signed multiply-overflow residual |
| `multi_result_overflow` | unsigned overflow residual |

The named R03/R04 scalar-immediate residual owners remain unchanged and are
not part of the calls population.

## Credit and last-owner proof

### Ordinary direct calls

`lowerDirectCallArg` contains the two textual bypass rows. It has two
production owners:

```text
lowerCall          -> lowerDirectCallArg
lowerScalarSseCall -> lowerDirectCallArg
```

Migrating only the admitted ordinary direct-call family therefore changes
semantic ownership but cannot delete either textual gateway. The two
occurrences
must stay in the TSV under `direct_call_scalar_sse_o3`, so the direct credit
is zero.

The existing O1 call-preparation helpers also retain the scalar-SSE owner.
`spillLiveCallerClobbersForCall` is a shared state authority, not a bypass
helper. `accumulatorInputDisplacement` has four non-call-intrinsic owners
(`lowerCtpop`, `lowerBitPermutation`, `lowerCtlzI16`, and `lowerFshlI32`).
No helper-collapse credit exists.

### Specialized `intByteSize`

`lowerIntByteSizeCall/emitValueIntoScratch` is a single, distinct textual
gateway. A complete byte-identical migration of this family would remove one
row. No other family owns that source occurrence. The conditional direct
credit is one.

## Derived dormant surface and budgets

No new action leaf is justified. The actual call actions belong in the
existing `value_use/actions/calls.zig`; creating an empty general-call leaf
or reusing the closed memcpy action would be speculative.

The future dormant design has exactly two candidate closed semantic action
families:

1. an ordinary direct-call action, including the admitted zero-argument,
   void, scalar-result, and multi-argument forms while preserving all named
   residual dispatches; and
2. a specialized `intByteSize` action with its `i16` result mask and
   definition lifecycle.

The ordinary action must own a fixed-capacity, source-ordered list of already
registered request handles. The current `max_requests = 16` remains the
ceiling. It may carry direct semantic intent (symbol, return type, result
identity, argument declared types), never current homes or physical
destinations. Zero-argument accepted calls prove that an action cannot be
represented by attaching a fake request; a reviewed request-free
instruction-action attachment is required. Its exact API must be frozen in
the dormant slice before implementation.

The derived expansion budgets are:

| Surface | Accepted size | Future hard budget | Derived allowance |
|---|---:|---:|---:|
| `actions/calls.zig` | 215 | 1,200 | 985 lines |
| `actions/calls_tests.zig` | 397 | 1,500 | 1,103 lines |
| `model.zig` | 1,819 | 1,999 | 180 lines |
| `core.zig` | 1,295 | 1,499 | 204 lines |
| `composition.zig` | 277 | 399 | 122 lines |
| production facade manifest | 122 symbols | 126 symbols | exactly 4 budgeted additions |

The four budgeted facade additions are: `DirectCallAction`,
`IntByteSizeCallAction`, `CallRequestError`, and one closed
`attachCallAction` operation that accepts only the two call action tags. The
direct-call payload owns its fixed `[max_requests]RequestHandle` storage and
declared semantic argument data; no public argument descriptor is needed.
Test-failure controls stay internal and consume no facade budget. A fifth
facade symbol, third action tag, new use form, new physical destination, or
model/core size overrun requires a new reviewed refresh.

The existing `PreparedAction` union may gain at most the two candidate tags.
The dormant slice must preserve the current error sets and exact
`PreparedAction` dispatch exhaustiveness.

Import boundary:

```text
composed_selector_calls.zig
    -> composed_selector_value_use_transaction.zig (facade only)
value_use/core.zig
    -> value_use/actions/calls.zig (sole exhaustive dispatch)
value_use/actions/calls.zig
    -> model.zig + materialization.zig + frozen selector support imports
```

The leaf's current passive `stage2_planning.zig` import and selector support
imports are frozen; the new actions may not add a runtime planning dependency
or a new import edge. No action-to-`composed_selector_calls.zig`, reverse
action/core, function-name, or runtime callback edge is permitted. The dormant
design must reuse an acyclic lower authority for frame alignment; importing
`composed_selector_frame.zig` would cycle through
`composed_selector_scalar.zig` and the ValueUse facade, so that import is
explicitly forbidden. If the complete action cannot preserve alignment
without a new reverse edge, it is a structural review stop rather than
permission to widen imports.

## Future isolation and aggregate procedure

This procedure is frozen but not executed:

1. Implement dormant actions and production-faithful fixtures with
   production routing unchanged and ratchet 131.
2. Freeze the dormant tree and baseline artifacts.
3. Build the ordinary direct-call family alone. Keep scalar-SSE, indirect,
   i128/pair, pointer-frontier, stack/aggregate, immediate, cycle, tail, and
   all intrinsic families on legacy paths.
4. Compare the complete cohort report, object, owner projection, all
   per-function bytes/disassembly, full unit suite, and focused canaries.
   Preserve the six target rows exactly. Attribute the first semantic
   instruction divergence separately from downstream offsets. Any failure
   retains the complete ordinary family.
5. Build `intByteSize` alone under the same bars. Any failure retains the
   complete specialized family.
6. Build the aggregate of all individually accepted call families. If it
   diverges, isolate the minimal interacting set; do not infer aggregate
   identity from isolated identity.
7. Only after Reviewer acceptance of the matrix may a production wiring
   slice claim the corresponding semantic transitions and the one possible
   direct credit. Recount owners again in the final wired tree; no
   pre-authorized helper collapse exists.
8. A production slice must use the standing post-final-tree immutable
   counterbalanced performance protocol. That future gate is not run here.

## Stop statement

INBOX-173 changes documentation only. It does not modify production, tests,
guards, tools, manifests, action/model behavior, emitted bytes, or the bypass
TSV. The accepted ratchet remains **131**. Dormant implementation, isolation,
production wiring, performance, and Tier 3 are not authorized.
