# INBOX-177 — closed call final-use plan design

Status: **design frozen; no implementation or re-isolation authorized.**
INBOX-176 proved that the retained ordinary-call wiring registers its request
successfully and then fails at seal/Q1 with `ValueUseExpiredSource` for a
truthful planned final-use EAX argument. This document freezes the bounded
dormant amendment that can address that failure without changing generic Q1,
the pure consumer classifier, or the public transaction surface.

The O2 bypass ratchet remains **131**. Ordinary direct calls remain retained
wholesale. `zig.target.intByteSize` and aggregate isolation remain
unauthorized.

## 1. Decision and structural-fit ruling

The selected direction is the Reviewer-mandated reuse of the existing
`attachCallAction` operation in the registering/pre-seal phase:

```text
begin
  -> register every argument request in semantic source order
  -> attach exactly one existing call action
  -> seal
  -> prepare
  -> materializeAll / internally execute the attached action
  -> commit
```

A zero-argument direct call performs:

```text
begin -> attach zero-handle DirectCallAction -> seal -> prepare
      -> materializeAll / execute -> commit
```

There is no second declaration or attachment API. There is no new action
tag, request form, destination, facade symbol, callback, consumer hint, or
planning import edge.

### Structural-fit conclusion

This direction fits the frozen boundaries and therefore does **not** require
a structural stop:

| File/surface | Frozen baseline | Frozen ceiling or budget | Designed effect |
|---|---:|---:|---|
| `value_use/model.zig` | 1,889 lines | 1,999 | no public declaration; only a private inline final-use proof inside the existing lifetime pin |
| `value_use/core.zig` | 1,328 lines | 1,499 | change the existing attachment phase check; close registration through existing action storage |
| `planning/lifetime_admission.zig` | 533 lines | 2,000 | one private call-and-handle-scoped predicate; imports remain unchanged |
| `actions/calls.zig` | 607 lines | 1,200 | reuse existing validation/execution; no public payload change |
| `actions/calls_tests.zig` | 975 lines | 1,500 | focused dormant proofs must remain under the existing ceiling |
| facade | 3 lines / 126 symbols | exactly 126 | unchanged |
| call facade additions | 4 | exactly 4 | unchanged |
| call action tags | 2 | exactly 2 | unchanged |

If implementation cannot remain within those exact ceilings and the frozen
imports below, it must stop for architectural review. It may not compensate
with a fifth facade name, another attach method, a public helper, or an action
to planning import.

## 2. Frozen public and semantic surfaces

The following remain byte-for-byte or manifest-identical in the future
dormant amendment:

- `PreparedAction.direct_call`;
- `PreparedAction.int_byte_size_call`;
- `DirectCallAction` fields: copied symbol, optional copied result, return
  type, fixed request-handle array, fixed declared-type array, and count;
- `IntByteSizeCallAction` fields: copied symbol, copied result, and one
  request handle;
- the six-member `CallRequestError` set;
- the single public `attachCallAction(transaction, action)` signature;
- the four reviewed facade additions:
  `CallRequestError`, `DirectCallAction`, `IntByteSizeCallAction`, and
  `attachCallAction`;
- the complete 126-symbol facade manifest;
- request forms `gpr32`, `gpr64`, and `stack_object_address`;
- destination `prepared_source`;
- fixed `max_requests` action-owned handle/type storage;
- the pure semantic call classifier and all pre-transaction call-form,
  signature, tail-kind, volatility, and operand-envelope dispatch;
- the current action/model/core/materialization/facade import DAG.

No public payload may gain a `ValueLoc`, register, spill, home, liveness
result, displacement choice, ABI destination, ordering flag, plan pointer,
function name, or callback. No consumer may query selector state to choose
this plan.

## 3. Import and ownership boundary

The final-use decision is private to the existing transaction authority:

```text
consumer
  -> facade only

core
  -> model
  -> planning facade
  -> actions/calls

planning/lifetime_admission
  -> model
  -> compatibility
  -> selector state

actions/calls
  -> model
  -> materialization
  -> composition
```

`planning/lifetime_admission.zig` already imports the central model and
selector state. Its private predicate may inspect the transaction-owned
`call_action` union and registered request array directly. It must not import
`actions/calls.zig`, and `actions/calls.zig` must not import planning.

The action leaf remains the owner of call attachment validation and complete
call execution. Lifetime admission owns only the scoped proof that one
otherwise-expired current binding is still the final-use operand of the
attached call. Generic Q1 remains the authority for every other request.

## 4. Registering/pre-seal attachment contract

The existing action storage is the registration-closing sentinel. No new
request phase or transaction field is required for attachment state.

### 4.1 Successful attachment

`attachCallAction` succeeds only when all of the following hold:

1. transaction lifecycle is `active`;
2. request phase is `registering`;
3. `call_action == null`;
4. action tag is exactly `direct_call` or `int_byte_size_call`;
5. every referenced handle belongs to this transaction and current handle
   generation;
6. every referenced handle indexes an already-registered
   `prepared_source` request;
7. direct-call handles occur in nondecreasing registered source order;
8. every registered request is claimed by the action;
9. no registered request carries an independent per-request prepared action;
10. zero requests are accepted only by a structurally valid zero-handle
    `direct_call`;
11. existing action identity, result, return-type, argument-count, and
    specialized-action validation succeeds.

Validation completes before `transaction.call_action` is assigned. An
attachment failure therefore changes neither action storage nor request
phase and emits no selector mutation.

### 4.2 Registration closes at attachment

After successful attachment:

```text
request_phase=registering
call_action=<the copied closed action>
call_action_executed=false
registration_closed=true by the non-null call_action invariant
```

Any later `register` attempt fails with existing
`ValueUseLateRegistration`. Any per-request action attachment after a call
action is also rejected before mutation. The only valid next phase-changing
operation is `seal`.

This sentinel rule enforces the intended order without adding an
`action_attached` phase, a boolean field, or a second API.

### 4.3 Exact attachment errors

No new public error type is introduced:

| Condition | Frozen outcome | Provenance |
|---|---|---|
| inactive/committed/rolled-back transaction | `ValueUseTransactionClosed` | authority-level |
| attach after seal/prepare/materialization | `ValueUseLateRegistration` | authority-level |
| second call action | `ValueUseCallActionAlreadyAttached` | authority-level |
| non-call action tag | `ValueUseCallActionUnsupported` | authority-level |
| foreign, stale, or out-of-range handle | `ValueUseActionOperandNotRegistered` | no matching request |
| referenced request is not `prepared_source` | `ValueUseActionOperandNotPreparedSource` | matching request |
| direct-call handle order decreases | `ValueUseCallArgumentSourceOrder` | first offending handle |
| registered request is unclaimed | `ValueUseCallRequestUnclaimed` | first unclaimed request |
| too many or mismatched handle/type entries | `ValueUseCallArgumentCountUnsupported` | authority-level unless a unique handle caused it |
| invalid symbol/result identity | existing identity error | authority-level |
| unsupported result/return relation | `ValueUseCallResultUnsupported` | authority-level |
| registering another request after attachment | `ValueUseLateRegistration` | authority-level |

The former sealed-only attachment outcome
`ValueUseCallActionRequiresSealedPlan` is not repurposed into a second
mechanism. The single method's legal phase moves to registering; post-seal
use follows the same `ValueUseLateRegistration` rule as other registering
attachments.

Request-specific attachment errors call the existing request-boundary
provenance authority exactly once. Global phase, action-tag, identity, count,
and no-matching-handle errors remain unattributed.

## 5. Seal contract with an attached call

`seal` remains the sole plan sealer and retains its existing statement order.
The pre-attached action makes the registered set immutable before seal; it
does not execute and does not mutate selector state.

Seal performs:

1. active/registering checks;
2. existing semantic-order validation;
3. existing request loop in registered order;
4. existing type/form/destination and binding compatibility validation;
5. generic Q1, except for the one separately scoped final-use admission
   described below;
6. existing physical mapping, destination conflict, and cycle planning;
7. transition to `sealed`.

The action leaf is not imported by planning. Action structural validation
does not move into planning. The stored action and handles are immutable
because attachment has already closed registration.

An attached zero-handle direct call has an empty request loop. Seal succeeds
without inventing a fake request, fake literal, fake binding, or global
zero-request capability. The already validated `direct_call` tag is the
closed authority for that zero-request transaction.

## 6. Closed final-use admission predicate

### 6.1 Position convention

The accepted legacy fixture has:

```text
selector.current_position=1
allocation interval end=0
```

The selector cursor is one past the current call's allocation-plan position.
The exact final-use boundary is therefore:

```text
current_position > 0
and interval_end == current_position - 1
```

The subtraction must be guarded by `current_position > 0`; no wrapping or
saturating comparison is allowed. An interval older than
`current_position - 1` is not a final use. An interval ending at or beyond
the raw cursor remains ordinary generic-Q1 input.

### 6.2 Predicate domain

The predicate is private and receives only the transaction and request
index already being validated. It returns no location and creates no public
capability.

It is applicable only when:

- `transaction.call_action` is present;
- its tag is `direct_call` or `int_byte_size_call`;
- the action's fixed handle storage claims this exact request index;
- the handle authority, transaction generation, and index remain valid;
- the claimed request is a named `prepared_source`;
- the request has no independent prepared action;
- a current selector binding exists for the request's inline-owned identity.

Every other prepared-action tag, transaction without a call action,
unclaimed request, foreign handle, literal/null/unsupported source, and
non-call request is outside the predicate. It receives generic Q1 unchanged.

### 6.3 Exact positive requirements

The final-use exception succeeds only when all facts below are true:

1. **Identity:** the current canonical binding is keyed by the exact inline
   request identity.
2. **Handle ownership:** the attached action claims the registered handle
   belonging to this authority/index/transaction generation.
3. **Binding generation:** the binding virtual-register generation equals
   the transaction's existing lifetime pin.
4. **Real plan:** `selector.allocation_plan` is non-null.
5. **Real interval:** the plan has an interval entry for this identity.
6. **Exact boundary:** the interval end equals
   `current_position - 1`, with `current_position > 0`.
7. **Plan identity:** the plan object is the same plan admitted at seal.
8. **Dependencies:** canonical address-dependency validation succeeds even
   though the scalar call shape normally has an empty domain.
9. **Request compatibility:** existing semantic type, class, defined-width,
   form, destination, and binding compatibility checks succeed.
10. **Action-admitted accumulator home:**
    - direct-call `i32` final use is canonical EAX;
    - direct-call `i64` final use is canonical RAX;
    - specialized `i16` final use is canonical EAX;
    - pointer, pair, XMM, aggregate, stack-object, argument-register,
      scratch-register, spill, and every other home are ineligible.
11. **No forward substitution:** the current binding itself exists; a
    forward-plan entry cannot substitute for it.

The internal check may inspect the current `ValueLoc` to prove the closed
home, but it never stores, returns, or exposes that location. Consumers and
action payloads never observe it.

### 6.4 Private structural pin

The existing private `LifetimePin` remains the single per-request identity
and binding-generation pin. Its private representation may be extended,
within `model.zig`'s existing budget, with an optional final-use proof:

```text
plan identity as an integer
admission position
exact interval end
call-final-use marker
```

The identity remains existing inline-owned `Identity`; no borrowed slice,
`ValueLoc`, register, spill, action pointer, plan-entry pointer, or mutable
metadata pointer is retained.

Normal requests leave this optional proof empty. Exact final-use admission
sets it once at seal. Repeated validation compares the current facts
structurally; it never refreshes the proof to make changed metadata pass.
Rollback clears it through the existing complete `lifetime_context = .{}`
reset.

This is private transaction state, not a fifth facade symbol or hidden
consumer API.

### 6.5 Relation to generic Q1

Generic Q1 is unchanged:

- current bindings with intervals covering the raw selector cursor continue
  through existing availability logic;
- forward bindings continue through the existing exact forward snapshot
  authority;
- typed immediates and typed null retain their exemptions;
- all non-call requests retain current behavior and errors.

The call final-use branch is considered only after the existing current
binding, plan, interval, dependency, type/class/width, and handle facts are
available, and only where ordinary Q1 would otherwise return
`ValueUseExpiredSource` for the exact one-position final-use boundary.

It does not redefine `valueIsLiveAtOrAfterCurrent`, make
`ValueUseExpiredSource` globally recoverable, or grant artificial
post-instruction liveness.

## 7. Final-use rejection and error table

No fallback is permitted. A rejected final-use candidate returns an existing
closed error and retains first-request provenance:

| Rejection | Exact outcome |
|---|---|
| no allocation plan | `ValueUseSourcePlanMissing` |
| plan lacks interval | `ValueUseSourceIntervalMissing` |
| interval older than `current_position - 1` | `ValueUseExpiredSource` |
| `current_position == 0` with no exact predecessor position | `ValueUseExpiredSource` |
| interval changed after final-use admission | `ValueUseSourceGenerationChanged` |
| allocation-plan identity changed after admission | `ValueUseSourceGenerationChanged` |
| current binding removed after admission | `ValueUseSourceGenerationChanged` |
| binding identity or vreg generation changed | `ValueUseSourceGenerationChanged` |
| final-use proof unexpectedly missing on revalidation | `ValueUseSourceGenerationChanged` |
| exact final-use source is no longer in the admitted accumulator home | `ValueUseCallArgumentLocationUnsupported` |
| type/class/defined width no longer compatible | existing compatibility error |
| malformed dependency owner/edge | existing address-dependency error |
| foreign/stale/unregistered action handle | `ValueUseActionOperandNotRegistered` |
| handle not claimed by the attached action | `ValueUseCallRequestUnclaimed` |
| attached tag is not one of the two call tags | `ValueUseCallActionUnsupported` |
| request is literal, null, unsupported, or independently action-owned | existing request/form error; no final-use admission |

A source with no current binding never receives the final-use exception.
Existing forward admission returns its existing `ValueUseForward*` outcome;
no forward snapshot can be reinterpreted as a current final-use binding.

Every error tied to a valid request index is passed once through
`noteRequestBoundaryError`. The first attributable request remains stable
through nested validation and automatic rollback. Authority errors—phase,
capacity, identity, EFLAGS conflict, copy cycle, action diagnostic, or an
unmatchable foreign handle—match no request.

The future consumer maps an error only after catching it and only when
`failedRequestIs(its_local_handle)` is true. Otherwise the authority error
propagates unchanged. There is no retry, source inspection, or legacy
fallback.

## 8. Prepare/materialize/action lifecycle

After a successful seal:

### 8.1 Prepare

`prepare` retains:

```text
required phase=sealed
automatic rollback owner=outer ValueUseTransaction
early-plan behavior=unchanged
physical clobber planning=unchanged
next phase=prepared
```

The call final-use proof is read-only during prepare. It does not expose a
prepared view or physical home.

### 8.2 Materialization

`materializeAll` remains the sole outer rollback invocation for action
execution:

1. require `prepared`;
2. enter `materializing`;
3. complete existing fixed materializations;
4. internally build private prepared records from canonical current state;
5. revalidate every exact final-use proof structurally;
6. enter `materialized`;
7. if a call action is attached, enter `views_exposed`;
8. execute it internally;
9. set `call_action_executed=true` only after successful complete action
   execution.

No prepared call location crosses into the consumer.

### 8.3 Action execution

The existing closed action sequence remains:

1. validate EFLAGS clobber;
2. validate the complete copy schedule before caller-clobber mutation;
3. begin the subordinate accumulator session for an admitted result, or use
   the existing void-call caller-clobber authority;
4. preserve Q2-surviving caller-clobbered values and unrelated Q3
   occupants;
5. canonically refresh all argument records after preservation;
6. structurally revalidate every final-use pin before its stage;
7. stage arguments in semantic source order;
8. finish accumulator call preparation after all argument stages;
9. align if required;
10. own the call symbol durably;
11. append the exact EFLAGS-clobbering direct call;
12. unalign if required;
13. own and define the result where applicable;
14. finalize the subordinate result.

The final-use EAX/RAX source is staged directly only when the exact predicate
still holds immediately before staging. No pre-preservation `ValueLoc`
survives the mutation boundary.

### 8.4 Commit

`commit` still requires:

- active transaction;
- phase `materialized` or `views_exposed`;
- subordinate accumulator result finalized when present;
- attached call action executed completely.

Otherwise it returns existing
`ValueUseCommitBeforeMaterialization`,
`ValueUseAccumulatorResultNotFinalized`, or
`ValueUseCallActionNotExecuted`. There is one outer commit and no action-local
commit.

## 9. Q2 and Q3 preservation

The final-use exception answers only current consumption. It is not a
survival or alias-preservation decision.

### Q2 source survives instruction

If the source survives after the call, its interval is not the exact
final-use boundary. Generic Q1 and Q2 remain authoritative. Existing
caller-clobber preservation spills or relocates it exactly as before, and
the action re-resolves it canonically before staging.

The final-use exception cannot be used to suppress that preservation.

### Q3 unrelated accumulator occupant

An unrelated EAX/RAX alias that survives after the call is preserved by the
existing caller-clobber/accumulator authority exactly once. The final-use
source is excluded only as the semantic source; no other live alias is
excluded merely because it shares the same physical EAX/RAX contents.

After preserving the unrelated alias, the source and all other arguments are
canonically rederived. The physical preservation move does not authorize a
stale source record.

### Final-use source

An exact final-use source has Q2=false. When no unrelated Q3 occupant exists,
the accepted stream contains no spill:

```text
EAX i32: mov_eax_to_arg <ABI destination>
RAX i64: mov_rax_to_arg <ABI destination>
```

It is removed only at the accepted post-argument call-preparation point. The
call result may then become the new accumulator occupant.

## 10. Same-source and cycle behavior

Fully identical requests continue to coalesce. A direct-call action may hold
the same valid request handle in multiple semantic argument positions. The
final-use proof is per registered request, not per argument occurrence.
Canonical validation occurs for every stage, while preservation occurs once
per physical source.

Same-source/multiple-destination staging remains valid when the existing
copy schedule is nonconflicting.

A genuine source/destination cycle remains
`ValueUseCopyCycleRequiresO4`. It is detected before caller-clobber
preservation or emission. The final-use plan adds no parallel-copy,
fixed-register, allocator, or O4 scheduling capability.

## 11. Rollback ownership and state

The outer transaction remains the only rollback owner. The call action must
contain no `rollbackInternal` invocation.

Rollback/deinit after any failure restores:

- instructions, including alignment and partially appended calls;
- selector bindings and durable owned keys;
- spill slots, owned spill keys, and counters;
- accumulator domain and subordinate session state;
- EFLAGS physical state and semantic-record length;
- address dependencies;
- labels and counters;
- request array/count and request phase;
- call action storage and `call_action_executed`;
- ordinary and final-use lifetime pins;
- prepared records, early homes, and view generation.

After rollback:

```text
request_phase=registering
request_count=0
call_action=null
call_action_executed=false
lifecycle=rolled_back
```

The first failed-request diagnostic capability remains queryable as already
specified by the provenance authority; it does not become routing or retry
state.

New rollback proofs are required at:

1. after all requests but before attachment;
2. attachment validation failure;
3. immediately after successful pre-seal attachment;
4. seal failure on the first final-use request;
5. seal failure on a later final-use request;
6. immediately after seal;
7. prepare failure;
8. initial prepared-record construction;
9. plan/binding mutation detected by canonical revalidation;
10. Q2/Q3 preservation;
11. each argument stage;
12. call append;
13. result ownership/definition;
14. subordinate finalization.

Every proof compares complete selector and transaction state and verifies
exactly-once durable free behavior.

## 12. Validation and diagnostic precedence

Pre-transaction consumer validation remains first:

```text
call form
signature
tail kind
volatility
callee/operand semantic envelope
pure classifier dispatch
```

Inside the transaction:

1. requests register in legacy source order;
2. attachment validates structural handle ownership/order/claiming only;
3. seal validates Q1 and the scoped final-use proof in request order;
4. action execution retains the existing post-preservation, source-order
   type/home/staging diagnostics;
5. the first request failure remains authoritative.

Attachment must not hoist declared-type or physical-location diagnostics
that historically occur after an earlier argument stage. The final-use
predicate proves only eligibility for the one current accumulator source;
it does not replace the existing action's `validateCallRequest` or staging
diagnostics.

The dies-at-current positive recovers the exact accepted stream, not a new
diagnostic. Negative missing/stale/older metadata remains request-attributable
and maps through the existing guarded call mapper. Authority errors propagate
unchanged.

## 13. Mandatory dormant proof matrix

All fixtures use real allocation plans, exact cursor positions, canonical
bindings, real dependency metadata, and production alias topology. No
blanket lifetime or test-only admission bypass is permitted.

### Positive final-use streams

1. i32 final-use EAX source in argument position 0: exact no-spill
   `mov_eax_to_arg rdi` stream from INBOX-176.
2. i32 final-use EAX source in a middle argument position after earlier
   staging.
3. i32 final-use EAX source in the last argument position.
4. i64 final-use RAX source in argument position 0.
5. i64 final-use RAX source in a later position.
6. specialized i16 EAX final use, if its unchanged semantic action envelope
   reaches the same exact boundary.
7. same source handle used for multiple nonconflicting destinations.
8. zero-argument aligned and framed direct calls with attachment before seal.
9. durable result lookup/use after transaction teardown.

Each pins exact instructions, binding movement, EFLAGS records, spill count,
request phase, action execution state, and durable identity ownership.

### Preservation controls

10. Q2-surviving EAX source preserves exactly once and re-resolves before
    staging.
11. Q2-surviving RAX source preserves exactly once.
12. unrelated live Q3 accumulator alias preserves exactly once while the
    final-use source still stages correctly.
13. multiple aliases of the unrelated live occupant do not duplicate the
    physical preservation.
14. no unrelated alias produces no preservation.
15. preservation moves leave EFLAGS unchanged before the call clobber.

### Admission negatives

16. missing allocation plan;
17. missing interval entry;
18. interval older than the exact final-use boundary;
19. `current_position==0`;
20. plan identity changed after seal;
21. interval changed after seal;
22. binding removed after seal;
23. binding rebound to a new generation;
24. same generation but no longer an admitted accumulator home;
25. malformed dependency owner/edge;
26. valid forward-plan identity with no current binding receives no
    final-use admission;
27. stale/malformed forward metadata receives its existing forward error;
28. non-accumulator argument-register, scratch, spill, pointer, pair, XMM,
    aggregate, and stack homes receive no final-use admission;
29. non-call prepared-action tag;
30. request not claimed by the action;
31. foreign/stale handle;
32. request with an independent prepared action.

Every negative proves no emission and exact rollback.

### Phase and structure negatives

33. attach before required nonzero requests are registered;
34. duplicate attachment;
35. registration after attachment;
36. attach after seal;
37. prepare before seal;
38. materialize before prepare;
39. commit before action execution;
40. zero-request `int_byte_size_call` rejected;
41. wrong action tag rejected;
42. source-order inversion attributed to the first offending handle;
43. unclaimed registered request attributed exactly once;
44. genuine copy cycle rejected before preservation.

### Canonical revalidation and rollback

45. unchanged final-use metadata succeeds at seal, prepared-record creation,
    post-preservation refresh, and per-stage revalidation.
46. mutation of each private proof fact fails before the next emission.
47. rollback immediately after attachment clears action state.
48. rollback after seal clears final-use pins.
49. rollback after Q3 preservation restores bindings/spills/counters.
50. rollback after each argument stage removes all partial staging.
51. rollback after call append frees owned symbol once.
52. rollback after result definition/finalization frees result ownership once.
53. multi-request failure preserves the first precise request provenance.

### Legacy boundary proofs

54. the INBOX-176 EAX final-use fixture remains truthful and byte-identical;
    its plan is not weakened.
55. all currently accepted non-final-use ordinary streams and diagnostics
    remain exact.
56. pointer-frontier, scalar-SSE, indirect, i128/pair, stack/aggregate,
    immediate, cycle, tail, intrinsic, R03/R04, and all other retained
    envelopes remain pre-transaction.
57. `zig.target.intByteSize` production routing remains unchanged during the
    dormant amendment.

## 14. Function/API-scoped guard design

The guard must account for semantic APIs, not raw opcode text.

### Consumer sites

Future production wiring may use call transaction APIs only in exact balanced
function bodies:

- `lowerCall` — pure semantic dispatch only;
- `isAdmittedOrdinaryDirectCall` — predicate/type/RHS-form semantics only;
- `lowerOrdinaryDirectCallValueUse` — begin, register-all, attach, seal,
  prepare, materialize, commit, and diagnostic mapping;
- the separately reviewed specialized helper only when
  `zig.target.intByteSize` wiring is actually authorized.

The guard proves lexical operation order:

```text
all transaction.register calls
  before exactly one transaction.attachCallAction
  before transaction.seal
  before transaction.prepare
  before transaction.materializeAll
  before transaction.commit
```

It also proves no attempt-then-fallback and no second transaction authority.

### Action and authority sites

The following are separately accounted as implementation APIs:

- `core_attachCallAction`;
- `validateCallActionAttachment`;
- `executeAttachedCallAction`;
- the private final-use predicate in
  `planning/lifetime_admission.zig`;
- `materializeAll` as the single outer rollback caller.

The guard freezes one public `attachCallAction` declaration and one direct
forwarding wrapper. It rejects any alternate declaration, wrapper, caller,
callback, or facade alias.

### Opcode rule

There is **no** generic `.direct_call` ban. That token is legitimate in:

- `composed_selector_eflags.instructionEffect`;
- the closed call action tag switch;
- the call action's machine-instruction append;
- retained legacy call paths.

The guard counts action APIs and function bodies, never the raw opcode across
the source tree.

### Provenance mappers

Mapper accounting is conditional on the function being present:

- `inlineMemcpyValueUseDiagnostic`, when present, owns exactly its three
  destination/source/length queries;
- `directCallValueUseDiagnostic`, when present, owns exactly its one
  per-handle-loop query site;
- a future specialized mapper is counted only if its separately reviewed
  consumer exists;
- all `.failedRequestIs` calls outside the corresponding exact mapper body
  are rejected.

A memcpy-only fixture therefore needs only the memcpy mapper. It must not
invent `directCallValueUseDiagnostic`.

### Required guard negatives

Negative fixtures reject:

- action attachment outside the exact consumer helper;
- attach after seal;
- register after attach;
- duplicate attach;
- action use in another calls-file function;
- selector/home/liveness inspection in the pure classifier;
- a second attachment API or facade export;
- a fifth facade addition or 127th facade symbol;
- action-to-planning or planning-to-action import;
- final-use predicate use for a non-call tag/request;
- raw location returned or stored by the predicate;
- provenance query outside a present mapper;
- forcing a call mapper into a memcpy-only fixture;
- any function/family-name predicate.

A positive fixture explicitly accepts `.direct_call` in
`composed_selector_eflags.instructionEffect` without treating it as
production action wiring.

## 15. Frozen implementation sequence for a future dormant slice

A separately authorized dormant implementation must proceed in this order:

1. move the existing `attachCallAction` phase check from sealed to
   registering;
2. close registration after successful attachment using existing
   `call_action` storage;
3. preserve the same public wrapper and action payloads;
4. add only the private structural final-use proof to the existing lifetime
   pin;
5. add the private action/handle-scoped predicate in lifetime admission
   without a new import;
6. revalidate the proof at every current canonical resolution before stage;
7. add the complete dormant proof matrix;
8. replace the temporary INBOX-175 guard accounting with the scoped policy
   above;
9. keep production routing dormant and ratchet 131;
10. stop for review before any isolation.

Any need for a public helper, new action tag, new request form/destination,
consumer-side home/liveness query, new planning edge, callback, second
attachment mechanism, general Q1 change, cycle scheduler, or budget
exception is a structural stop.

## 16. Scope and stop record

This slice adds only this document. It runs no compiler, Zig/project command,
test, guard, identity, isolation, performance, integrated-executable,
strengthened Tier 2, distribution-all, or Tier 3 gate.

No production, test, guard, tool, facade, manifest, bypass inventory,
retention policy, or retained artifact is modified. `clean-tmp` is not run
and no cleanup authority is inferred.

Frozen accepted identities remain documentary context only and are not
regenerated:

```text
report=49a19f04 / 443 selected / 285 emitted / 158 failed
object=061a64e4
owner=5d91960e / 167-17-101
ratchet=131
```

STOP for Watcher/Reviewer architectural review. Dormant implementation,
ordinary-call re-isolation, `zig.target.intByteSize`, aggregate isolation,
and production wiring remain unauthorized.
