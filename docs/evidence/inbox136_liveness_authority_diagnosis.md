# INBOX-136 liveness-authority architectural diagnosis

Status: delivered for Supervisor/Reviewer design review. No implementation
or B3 resume is authorized by this document.

## Frozen basis and scope

```text
accepted_A3_source_commit=137894b5ffa0dff55325e3087753339a0260fbac
accepted_A3_source_tree=672eb40557536331ac96eac3d27c708cc74c00cc
diagnosis_authorization_head=19e90b763ddd06adc35c79ec30e6a787a90bfba3
diagnosis_authorization_tree=7970fe6cba43da47f6bce8c34e3368aaed607aa0
parked_production_ratchet=166
parked_wiring_ratchet=153
```

The authorization tree differs from the accepted A3 source tree only by
Supervisor evidence/mailbox commits. The parked B3 production diff was
removed with scoped `git checkout -- <six carrier files>` before this audit.
No reset was used.

The three lossless wiring carriers remain byte-for-byte unchanged:

```text
39aa6d5331a0d404bc1b8aca6372e3927314e1044c5b56788c01a1bd86c1dba5  tmp/inbox135_immediate_wiring/inbox135_immediate_wiring_hard_stop.patch
8ab26a97f2337790338025fcee0c8f296430abdf7320ae03588ca6fdff60b9ef  tmp/inbox135_immediate_wiring/inbox135_b2_second_hard_stop.patch
3f3e46ff0fd9b92a40287840716853c1dda70a3f90220107d3301598051f035d  tmp/inbox135_immediate_wiring/inbox135_b3_hard_stop.patch
```

`stash@{0}` remains
`7985c6d01040a6e47e4ce5b918866d0e89517ac7`. This slice changes
documentation only. No identity, performance, ABI, canary, Tier-2, or Tier-3
gate was needed or run.

## Finding

One predicate cannot safely answer all three questions:

1. **Q1 — current availability:** is the registered canonical source valid
   and available from registration through its final consumption in this
   instruction?
2. **Q2 — future liveness:** must that source remain available after the
   instruction?
3. **Q3 — destination occupancy:** does a different live logical value
   occupying a physical destination that this instruction will destroy need
   preservation?

The current implementation uses `valueIsLiveAtOrAfterCurrent` as Q1 during
request sealing, uses `valueIsLiveAfterCurrent` as Q2, and scans other
bindings with an after-current predicate for Q3. This works only while an
allocation plan is present and while tests model physical occupancy exactly.
It has two independently reproduced failure modes:

- with no allocation plan and an empty dependency domain, a present canonical
  binding is rejected at seal as `ValueUseExpiredSource`; and
- the A3 dormant `__multi3` test obtains the accepted spill/reload for the
  wrong reason by inventing a live second RAX alias. In production, `%10` is
  already in a spill and `%9` is the sole RAX occupant.

The likely correction is a set of separate, error-bearing authorities for
Q1, Q2, and Q3. That is a design conclusion for review, not an implementation
proposal approved by this slice. In particular, “replace every query with
`valueIsLiveAtOrAfterCurrent`” is rejected by the evidence below.

## Complete liveness/admission call-site inventory

Line numbers below are from the authorization tree. “Mixed” means the current
site combines two questions and should be decomposed rather than renamed.

### Primitive authorities and direct interval consumers

| File:line / symbol | Current rule | Question actually being asked | Finding |
|---|---|---|---|
| `composed_selector_state.zig:2397 valueIsLiveAtOrAfterCurrent` | dependency closure, then `end >= current`; no plan/empty domain returns `false`; missing ordinary interval returns `true` | Q1 only when a plan exists; sometimes Q3 at current-position CFG boundaries | It is a future-interval predicate, not a complete availability authority. |
| `composed_selector_state.zig:2499 valueIsLiveAfterCurrent` | dependency closure, then `end > current`; no plan/empty domain returns `false`; missing ordinary interval returns `true` | Q2 | Correct boundary for “survive this instruction,” provided missing-plan/entry semantics are made explicit. |
| `composed_selector_state.zig:2508 valueIsLiveAtBoundary` | shared implementation of the preceding two predicates | Q2 plus a current-boundary variant | The shared dependency traversal is useful; the Boolean result is not sufficient for Q1. |
| `composed_selector_state.zig:2524 validateAddressDependenciesForUse` | validates a named source's canonical owner/dependency closure | Q1 | Necessary but not sufficient: it does not establish binding availability or interval coverage. |
| `composed_selector_address_dependencies.zig:192 dependencyIsRequired` | recursively asks whether a live owner extends a dependency | Q2, parameterized by boundary | Keep error-bearing; do not convert failures to a conservative Boolean. |
| `composed_selector_state.zig:2259 valueMustSurviveClobber` | PHI always survives; otherwise `after`, except `preserve_current_position_values` selects `at_or_after` | Q3, with a CFG/current-position policy overlay | The name says Q2, but callers ask whether a physical clobber must preserve an occupant. |
| `composed_selector_state.zig:988 regConflictStatus` | a register conflict is expired only when every interval ends before current; a missing interval is live | Q3 | Direct interval consumer. Its missing-entry behavior is deliberately conservative, unlike seal. |
| `composed_selector_state.zig:1004 expireExpiredBindings` | records whether any binding interval ended before current; does not remove the binding | Q1 bookkeeping | A map entry can remain after its interval. Binding presence alone therefore cannot prove Q1. |
| `composed_selector_state.zig:1352 reusableScratch64RegForInPlace` | source end `<= current`, plus no alias ending `>= current` | Q1 plus Q3 | It proves current source presence through `resolveValue`, then asks whether destructive reuse is safe. |
| `composed_selector_state.zig:1361 spillScratch64SourceForInPlace` | requires a source interval entry and no live/current alias | Q1 plus Q3 | Missing plan/entry returns `null` silently; it is a legacy optional optimization, not a general authority. |
| `composed_selector_state.zig:1387 scratch64SourceHasNoLiveAliases` | another alias ending `>= current` blocks in-place reuse; missing entry blocks | Q3 | Uses the at-current boundary because the alias may still be an operand of this instruction. |

### Q1 admission and canonical re-resolution sites

| File:line / site | Current behavior | Classification |
|---|---|---|
| `value_use/planning.zig:249-255 validateRequest(.named)` | binding lookup → canonical `resolveNamedCurrent` → dependency validation → `valueIsLiveAtOrAfterCurrent` → binding/view validation | **Mixed Q1/Q2.** This is the decisive conflation. The last Boolean is being used as current availability. |
| `value_use/materialization.zig:220 buildPreparedRecord` | canonical binding lookup and view construction | Partial Q1; it re-resolves after preparation but relies on seal for interval admission. |
| `value_use/materialization.zig:263 validatePreparedRecord` | binding lookup plus dependency validation | Q1 revalidation. |
| `value_use/materialization.zig:313 resolveNamedCurrent` | raw canonical location lookup | Partial Q1; binding/location presence only. |
| `value_use/materialization.zig:363,541` | named binding lookup at action/materialization boundaries | Partial Q1; errors are `ValueUseUnresolvedSource`. |
| `value_use/core.zig:759-778 validateConsumedSourceState` | binding lookup; if location changed, allow a durable relocation only when the value is live-after; otherwise reject stale state | Mixed Q1/Q2. Q1 is canonical-state equality; Q2 is used to distinguish a legitimate durable relocation. |

The binding lookup precedes liveness in `validateRequest`. Consequently, a
missing binding is `ValueUseUnresolvedSource` even when the dependency domain
also lacks a plan. That diagnostic precedence must be retained.

### Q2 future-survival call sites

| File:line / caller | Predicate | Purpose |
|---|---|---|
| `composed_selector_scalar.zig:167` | `valueIsLiveAfterCurrent(lhs)` | Legacy named-binary source preservation. |
| `composed_selector_scalar.zig:1129 accumulatorArithmeticDisplacement` | `valueIsLiveAfterCurrent(source)` | Reuse a dying EAX/RAX source; spill a source needed later. |
| `composed_selector_calls.zig:368` | `valueIsLiveAfterCurrent(lhs)` | Preserve an arithmetic-call operand needed after the call. |
| `value_use/core.zig:760,772` | `valueIsLiveAfterCurrent(source)` | Post-consumption durable-relocation/stale-state distinction. |
| `value_use/core.zig:1024` | `valueIsLiveAfterCurrent(phi destination)` | Restore only PHI destinations used later. |
| `composed_selector_cfg.zig:863` | `valueIsLiveAfterCurrent(name)` | CFG-boundary live-value spill. |
| `value_use/actions/control_compare.zig:1002` | `valueIsLiveAfterCurrent(source)` | Current-home source preservation/re-resolution. |
| `value_use/actions/scalar_arithmetic.zig:1382 immediateSourceDisplacement` | `valueIsLiveAfterCurrent(source)` | A2 immediate source survives vs dies-at-current choice. |

These are genuine Q2 queries, although the accepted byte policy may still
choose to spill a dying source for Q1 lifecycle/ordering reasons. Q2 must not
silently decide that separate policy.

### Q3 physical-occupant/alias call sites

| File:line / caller | Predicate/helper | Physical-preservation purpose |
|---|---|---|
| `composed_selector_state.zig:1372 xmmRegAvailable` | `valueMustSurviveClobber` | Is an XMM destination occupied by a value that must be kept? |
| `composed_selector_state.zig:1471 spillCurrentAccumulator` | `liveAccumulatorName` | Preserve a current/after accumulator occupant. |
| `composed_selector_state.zig:1770 preserveCurrentEaxIntoScratch` | `liveEaxName` | Preserve a live-after EAX occupant before a destructive write. |
| `composed_selector_state.zig:1781 preserveCurrentRaxIntoScratch` | `liveRaxName` | Preserve a live-after RAX occupant before a destructive write. |
| `composed_selector_state.zig:2225 clobberArgReg` | `valueMustSurviveClobber` | Spill or remove each scalar occupant of a fixed GPR destination. |
| `composed_selector_state.zig:2232 clobberArgReg` | `valueMustSurviveClobber` | Same for pair occupants. |
| `composed_selector_state.zig:2242 clobberXmmReg` | `valueMustSurviveClobber` | Same for XMM occupants. |
| `composed_selector_state.zig:2269 clobberAccumulator` | `liveAccumulatorName` | Preserve current/after accumulator bindings before clobber. |
| `composed_selector_state.zig:2279 spillAccumulatorAliasesExcept` | `liveAccumulatorNameExcept` | Preserve other accumulator aliases while excluding one semantic source. |
| `composed_selector_state.zig:2306 dropExpiredAccumulatorBindings` | `valueMustSurviveClobber` | Remove accumulator occupants that need not survive the impending clobber. |
| `composed_selector_state.zig:2331 dropExpiredAccumulatorBindingsExcept` | `valueMustSurviveClobber` | Same while pinning one reuse-source operand. |
| `composed_selector_state.zig:2354 spillLiveCallerClobbersForCall` | `liveFpNameInReg` | Preserve live-after XMM caller-clobbers. |
| `composed_selector_state.zig:2373 liveAccumulatorName` | `valueIsLiveAtOrAfterCurrent` | Enumerate EAX/RAX occupants at the inclusive boundary. |
| `composed_selector_state.zig:2385 liveAccumulatorNameAfterCurrent` | `valueIsLiveAfterCurrent` | Enumerate EAX/RAX occupants needed after this instruction. |
| `composed_selector_state.zig:2401 liveEaxName` | `valueIsLiveAfterCurrent` | EAX-specific live-after occupant. |
| `composed_selector_state.zig:2413 liveRaxName` | `valueIsLiveAfterCurrent` | RAX-specific live-after occupant. |
| `composed_selector_state.zig:2447 liveScalarNameInRegExcept` | `valueIsLiveAfterCurrent` | Scalar GPR live-after occupant, optionally excluding a source. |
| `composed_selector_state.zig:2484 livePairNameContainingRegExcept` | `valueIsLiveAfterCurrent` | Pair live-after occupant, optionally excluding a source. |
| `composed_selector_state.zig:2633 liveRegisterValueName` | `valueIsLiveAfterCurrent` | Any live-after register occupant at a CFG boundary. |
| `composed_selector_state.zig:314 AccumulatorDefinitionSession.prepare(.scratch_preferred)` | `liveAccumulatorNameAfterCurrent` | Preserve the preexisting live-after accumulator occupant. |
| `composed_selector_scalar.zig:163,259` | `liveAccumulatorNameAfterCurrent` | Legacy binary/immediate accumulator preambles. |
| `composed_selector_conversion.zig:35` | `liveAccumulatorNameAfterCurrent` | Conversion preamble. |
| `composed_selector_icmp.zig:589` | `liveAccumulatorNameAfterCurrent` | Legacy compare preamble. |
| `value_use/actions/control_compare.zig:470,978` | `liveAccumulatorNameAfterCurrent` | Compare-action preambles. |
| `value_use/actions/control_compare.zig:1399` | `valueIsLiveAfterCurrent(entry)` | Other live accumulator alias scan. |
| `value_use/actions/scalar_arithmetic.zig:810` | `valueIsLiveAfterCurrent(entry)` | A3 immediate unrelated-accumulator scan. |

`preserve_current_position_values` changes Q3's boundary. It is set around
prepared materialization (`value_use/materialization.zig:126-128`) and around
PHI/CFG boundary work (`composed_selector_cfg.zig:260-262`, `523-525`,
`725-727`, and `924-926`). It does not make Q1 and Q3 the same question; it
only says that current-position occupants must survive a particular clobber.

### Legacy displacement policy call sites

Two similarly named helpers intentionally answer different questions:

- `accumulatorArithmeticDisplacement` at
  `composed_selector_scalar.zig:1120` is Q2-aware and reuses only a dying
  source.
- `accumulatorPreserveCurrentDisplacement` at
  `composed_selector_scalar.zig:1150` first asks the inclusive Q3-style
  `liveAccumulatorName`; it therefore selects `.spill_source` for a source
  that ends exactly at current.

That second behavior is the accepted ancestor of the `%11` spill/reload.
It cannot be reproduced faithfully by inventing an unrelated alias, and it
must not be silently rewritten as a Q2 rule.

## Truth table

The table describes a named request at seal. `P` is allocation-plan presence,
`D` is address-dependency-domain state, `B` is canonical binding presence, and
`I` is the ordinary interval end relative to `current`. “Current result” is
the behavior of `validateRequest` today. “Required authority result” is the
fail-closed behavior that a reviewed Q1/Q2/Q3 design must represent
explicitly.

| P | D | B | I / dependency state | Current seal result | Q1 availability requirement | Q2 survive-after | Q3 occupant-preservation input |
|---|---|---|---|---|---|---|---|
| absent | empty | missing | none | `ValueUseUnresolvedSource` | `UnresolvedSource` | not queried | not queried |
| absent | empty | present | unknowable | `ValueUseExpiredSource` because at-or-after returns `false` | Must not be a Boolean fallback. Either an explicit active binding-generation proof admits it, or Q1 returns a distinct no-plan error. | Unknown; must not be reported as `false`. | Unknown; a destructive write must not silently discard it. |
| absent | nonempty | missing | none | `ValueUseUnresolvedSource` (binding lookup wins) | `UnresolvedSource` | not queried | not queried |
| absent | nonempty | present | any | `AddressDependencyMissingPlan` | same error | same error | same error |
| present | empty | missing | before/at/after | `ValueUseUnresolvedSource` | `UnresolvedSource` | not queried | not queried |
| present | empty | present | before | `ValueUseExpiredSource` | unavailable/released at this instruction | false | do not preserve as a live occupant |
| present | empty | present | at | accepted | available through this instruction; request must remain pinned until consumed | false | preserve only if it is another current operand required before the destructive write; do not call it live-after |
| present | empty | present | after | accepted | available | true | preserve if its physical home is destroyed |
| present | empty | present | missing entry | accepted because `valueIsLiveAtBoundary` returns `true` | **Fail-open gap:** Q1 needs a distinct missing-entry error unless the binding carries an explicit noninterval lifetime class | error/explicit unbounded class, never implicit `true` | error/explicit unbounded class |
| present | nonempty valid | present | before, no live owner | `ValueUseExpiredSource` | unavailable | false | no |
| present | nonempty valid | present | before, extended by owner ending at current | accepted for at-or-after | available as the owner's dependency at current | false for after-current | current-only preservation if the owner still needs it before consumption |
| present | nonempty valid | present | before, extended by owner ending after current | accepted | available | true transitively | preserve on destructive overlap |
| present | nonempty valid | present | at | accepted | available | false unless another live owner extends it | current-only/other-owner dependent |
| present | nonempty valid | present | after | accepted | available | true | preserve on destructive overlap |

Dependency metadata failures are not Boolean outcomes:

| Failure | Required error |
|---|---|
| nonempty domain, no plan | `AddressDependencyMissingPlan` |
| registered owner has no binding | `AddressDependencyMissingOwnerBinding` |
| owner binding type is incompatible | `AddressDependencyInvalidOwnerBindingType` |
| owner descriptor no longer matches its binding | `AddressDependencyStaleEdge` |
| owner lacks a plan interval | `AddressDependencyMissingOwnerPlanEntry` |
| dependency lacks a binding | `AddressDependencyMissingBinding` |
| dependency lacks a plan interval | `AddressDependencyMissingPlanEntry` |
| dependency binding type is incompatible | `AddressDependencyInvalidBindingType` |
| recursive owner/dependency cycle | `AddressDependencyCycle` |
| malformed role/type/identity metadata | the existing `AddressDependencyInvalidRoleType`, `AddressDependencyIdentityTypeMismatch`, duplicate-role/identity/owner, capacity, or identity errors |

No Q1/Q2/Q3 authority may catch these errors and return `false`. A missing
binding retains `ValueUseUnresolvedSource` precedence because request
validation performs that lookup before dependency traversal.

## Exact production trace: `__multi3` `%9`, `%10`, `%11`

### Frozen IR and allocation plan

The trace source is
`test/zig/integrated/compiler_rt_i128_builtins.ll` SHA-256
`69f3c2821e7c97e5c339ed51223761e525c2fb5e80ec030b297efeed2510d1ea`.
The focused canary contains the same `__multi3` body.

The relevant instructions are:

```llvm
%9  = add nuw i64 %5, %8
%10 = lshr i64 %9, 32
%11 = and i64 %9, 4294967295
```

Selector positions start at one and advance after every nonremoved
instruction. `%9`, `%10`, and `%11` execute at positions 14, 15, and 16.
A temporary Zig-only read of the real `buildSelectorAllocationPlan` returned:

```text
name  interval_end  planned_assignment
%9    16            gpr64:r9
%10   29            spill:9
%11   19            spill:10
```

The planned `%9` register is not available at its definition, so
`plannedResultLoc` retains the actual RAX result. `%10` and `%11` are
committed to frame slots 9 and 10 (`72(%rsp)` and `80(%rsp)`).

### State and queries at `%9` (position 14)

At instruction entry:

- `%5` is `spill64:slot5` (`40(%rsp)`), interval end 14;
- `%8` is `spill64:slot8` (`64(%rsp)`), interval end 14;
- no logical binding occupies EAX/RAX;
- the accumulator domain has no live occupant;
- the address-dependency domain is empty and has no edges.

Queries and mutations:

1. `liveAccumulatorNameAfterCurrent` scans EAX/RAX and returns `null` (Q3).
2. `valueIsLiveAfterCurrent("%5")` returns `false` because `14 > 14` is
   false (Q2).
3. Accumulator preparation/materialization reloads `%5` to RAX.
4. Reloading `%8` to RCX invokes fixed-register clobber preservation; the
   prior RCX argument value is genuinely live and is spilled once to
   `152(%rsp)` (Q3).
5. `addq %rcx,%rax` defines `%9`.

After commit:

```text
EAX/RAX bindings: %9 -> RAX
aliases sharing EAX/RAX: none
accumulator_domain: occupant=%9, logical_bits=64, defined_bits=64
address dependencies: empty
```

### State and queries at `%10` (position 15)

At entry `%9` is the sole RAX binding, its interval end is 16, and
`valueIsLiveAfterCurrent("%9")` would be `true`. The accepted R01
scratch-result path does not destructively redefine RAX:

```asm
movq %rax, %rcx
shrq $32, %rcx
movq %rcx, 72(%rsp)
```

The selected scratch RCX is clobber-checked (Q3), but there is no second
EAX/RAX binding to preserve. After result finalization:

```text
EAX/RAX bindings: %9 -> RAX
%10 binding: spill64:slot9
aliases sharing EAX/RAX: none
accumulator_domain: occupant=%9, logical_bits=64, defined_bits=64
address dependencies: empty
```

The fact that `%10` remains live to position 29 does not make it an RAX
occupant. Its canonical home at `%11` is the spill.

### State and queries at `%11` (position 16)

The complete canonical state before the first `%11` mutation is:

```text
binding %9:  loc=RAX, interval_end=16
binding %10: loc=spill64:slot9, interval_end=29
binding %11: not yet defined, planned spill64:slot10, interval_end=19
all other EAX/RAX bindings: none
accumulator_domain: occupant=%9, logical_bits=64, defined_bits=64
dependency owners/edges: 0/0
```

The accepted O1 path calls
`accumulatorPreserveCurrentDisplacement`. Its inclusive
`liveAccumulatorName` query returns `%9` because `16 >= 16`. The resulting
policy is `.spill_source("%9")`, producing:

```asm
movq %rax, 160(%rsp)
movq 160(%rsp), %rax
andl $-1, %eax
movq %rax, 80(%rsp)
```

The parked O2 wiring instead makes these distinct queries:

| Phase | Query | Exact name/result |
|---|---|---|
| seal/Q1-as-implemented | `validateAddressDependenciesForUse("%9")` | success; empty domain |
| seal/Q1-as-implemented | `valueIsLiveAtOrAfterCurrent("%9")` | `true` (`16 >= 16`) |
| A3 Q3 preamble | scan other EAX/RAX bindings with `valueIsLiveAfterCurrent` | `null`; `%10` is a spill and `%9` is excluded as the semantic source |
| A2 Q2 displacement | `valueIsLiveAfterCurrent("%9")` | `false` (`16 > 16` is false) |

The parked action therefore chooses `.reuse_source("%9")` and emits only:

```asm
andl $-1, %eax
movq %rax, 80(%rsp)
```

This is the first frozen stream divergence. It is not evidence of a missing
unrelated-alias preamble. Q1 says `%9` is available now, Q2 says it need not
survive, and Q3 says no other accumulator occupant needs preservation. The
accepted spill/reload is a source-lifecycle/legacy displacement policy at
the current boundary. The architecture must represent that policy directly,
not manufacture a Q3 alias to trigger it.

## Dormant-test trace and the exact mismatch

The A3 test named
`value-use immediate scalar __multi3 unrelated RAX alias is spilled once
before R05` constructs:

```text
current_position=1
source:       binding=RAX, interval_end=1
prior-result: binding=RAX, interval_end=10
result:       no binding, interval_end=1
allocation_plan=present
address_dependencies=empty
accumulator_domain=default/empty
```

Its queries are:

| Phase | Query | Result |
|---|---|---|
| seal | source at-or-after | `true` (`1 >= 1`) |
| A3 Q3 | other live-after EAX/RAX binding | `"prior-result"` (`10 > 1`) |
| preservation | spill chosen physical RAX once | both logical aliases rebound to `spill64:slot0` |
| canonical refresh | source rebuilt from slot 0 | success |
| A2 Q2 | source is no longer in RAX | fallback policy; reload through RAX |

That produces the desired three-instruction stream, but the state is not the
production state:

- production `%10` is plan-assigned and already bound to spill slot 9;
- production has no `"prior-result"` RAX alias at `%11`;
- production's accumulator domain explicitly owns `%9`, while the test leaves
  the domain empty;
- production's accepted spill is selected for `%9` itself at the inclusive
  current boundary, not for another live-after occupant.

The test therefore validates Q3 mechanics but cannot serve as the
production-faithful `%11` regression.

There is a second dormant discrepancy in the seven direct scalar unit paths
from the B3 stop. They bind a valid source (the first is `spill64`) but leave
`allocation_plan=null` and the dependency domain empty. Seal performs:

```text
binding lookup                 -> present
canonical location             -> present
dependency validation          -> success (empty domain)
valueIsLiveAtOrAfterCurrent     -> false (legacy no-plan result)
transaction result             -> error.ValueUseExpiredSource
phase                          -> seal, before materialization
```

Thus the existing spill materializer is never reached. This proves the
no-plan failure is Q1 admission, independent of the incorrect A3 alias
fixture.

## R00-R06/L01-L03 occurrence enumeration

### Enumeration method and frozen inputs

A temporary Zig program parsed each IR module with `ir.Module.parse`, selected
forms using the production
`ValueUseTransaction.isImmediateRhsScalar/isImmediateLhsScalar`
classifiers, and emitted the tuple:

```text
dataset, function, result, plan, direction, operation, bits, literal, named-source
```

The exact command was:

```text
/home/oleg/bin/zig run .inbox136_plan_trace.zig
```

The temporary program and raw files are not delivered because INBOX-136
permits one documentation artifact only. No Python or other scripting
language was used. The deterministic 4,178-row raw manifest SHA-256 was:

```text
42b3ea2d7cae30c1e7d1c5c90f064faf30d8728acc1fcd0aa87f790e35adcd50
```

The frozen input hashes were:

```text
d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4  tmp/inbox63_accepted_cohort.ll
c43d4e153119adc221c2942a70f3801736a5a2a68ea3a7c0a73f4d4f7fe6278b  src/codegen/x86_64/generic_cfg/testdata/compiler_rt_multi3.ll
69f3c2821e7c97e5c339ed51223761e525c2fb5e80ec030b297efeed2510d1ea  test/zig/integrated/compiler_rt_i128_builtins.ll
5c2b4d16ed8129bfc82ce06cb5d023c16c614f04adb4d1a352b28172fe249122  test/zig/integrated/compiler_rt_fma.ll
d7da6921d9831512e8967496fadbea7d2942de676d451887a9d677e8f358d1c4  test/zig/integrated/compiler_rt_fma_helpers.ll
```

### Accepted cohort: every semantic occurrence

The cohort contains 4,074 admitted semantic occurrences in 314 functions.
The exact `(function,plan,count)` projection has 1,041 keys and SHA-256
`7f434896345b71565ba479d01ddfa92b4713ae8a1632c187323b1feb84218f21`.
This projection preserves every occurrence by multiplicity; the raw manifest
additionally distinguishes every result identity.

| Plan | Occurrences | Functions |
|---|---:|---:|
| R00 | 5 | 5 |
| R01 | 519 | 191 |
| R02 | 247 | 111 |
| R03 | 58 | 36 |
| R04 | 1,432 | 256 |
| R05 | 793 | 144 |
| R06 | 555 | 87 |
| L01 | 438 | 185 |
| L02 | 14 | 14 |
| L03 | 13 | 12 |
| **Total** | **4,074** | **314 distinct overall** |

This is a semantic occurrence count, not the 12 textual gateway count from
the parked wiring. It demonstrates why a Q1/Q2/Q3 rule cannot be validated
only against `__multi3`.

### Unit coverage: every declared plan and production-path occurrence class

The dormant action suite has one closed table row for each of R00-R06 and
L01-L03, and executes all ten rows through the representative loop. Its
additional occurrences are:

| Test | Plans/forms exercised |
|---|---|
| plan table closed/direction specific | all ten; explicit L00 and i128 pair negatives |
| declared type × binding class × home | all plans share the frozen 6 × 10 × 21 admission matrix |
| representative ownership/writes | all ten |
| exact R00 and variable-lhs streams | R00, L01, L02, L03 |
| source-derived result branches | R01, R02, R03 |
| spill source fallback through RAX | R01 |
| live-after vs dies-at-current RAX | R02 |
| `__multi3` unrelated alias | R05; non-production-faithful state diagnosed above |
| no-alias and multiple-alias preambles | R05 |
| preamble rollback | R05 |
| nonaccumulator/literal controls | R02, L03 |
| malformed dependency liveness | R02 |
| malformed alias dependency liveness | R05 |
| provenance diagnostic | R05 |
| literal validation before mutation | R06 |
| generic rollback boundaries | L01 |
| preservation/scratch/multi-instruction rollback | R00, R01, R02, R05, R06 |

The legacy/production-path scalar suite supplies the complementary concrete
coverage:

| Production-path unit family | Plans/forms |
|---|---|
| reload and mask i64 low half; preserve prior RAX mask | R05 |
| four wide immediate siblings on dead RAX | four R05 occurrences |
| lshr64 scratch selection, dead-source reuse, live-source spill, spill-through-RAX | R01 |
| destructive shl64 live-source spill | R02 |
| i64 immediate-left variable lshr | L03 |
| i16/i32 immediate-left variable shl plus executable boundaries | L02 |
| i64 immediate xor | R05 |
| i32 arithmetic-right immediate arm | R03 |
| live accumulator across two immediate adds | two R04 occurrences |
| i7 add/xor executable modulo behavior | two R04 occurrences plus rejected-width negative |
| live accumulator aliases across xor/shift | R04 and R02 |
| signed i32 divide-by-two executable behavior | R00 plus four rejected-form negatives |
| i128 immediate shifts and pair results | explicit legacy/O4 negatives to scalar plans |

The seven no-plan failures in the parked B3 full-unit run span R05, R03,
L02, and L03 production paths and therefore are not a single-plan issue.

### Canary coverage: every occurrence

The canary datasets contain 104 occurrences. The exact
`(dataset,function,plan,count)` projection below has SHA-256
`06015458cd611951a858f0511cd7c5c31a833d54c5783d568fc5aba77772ce9c`.

| Dataset / function | Plan counts |
|---|---|
| focused multi3 / `__multi3` | R01=5, R02=1, R05=4 |
| integrated i128 / `__multi3` | R01=5, R02=1, R05=4 |
| integrated i128 / `__moddi3` | R03=1 |
| integrated i128 / `zllvm_add_i64_large_imm` | R05=1 |
| integrated i128 / `zllvm_and_i8_one` | R04=1 |
| integrated i128 / `zllvm_backward_layout_phi` | R04=1 |
| integrated i128 / `zllvm_four_phi_loop` | R04=4 |
| integrated i128 / `zllvm_i32_ashr_immediate` | R03=1 |
| integrated i128 / `zllvm_neg_i32` | L01=1 |
| integrated i128 / `zllvm_neg_i64` | L01=1 |
| integrated i128 / `zllvm_or_i64_imm` | R05=1 |
| integrated i128 / `zllvm_spilled_cond` | R04=6 |
| integrated i128 / `zllvm_spilled_phi` | R06=2 |
| integrated i128 / `zllvm_stack_index_dependency` | R06=1 |
| integrated i128 / `zllvm_sub_i6` | L01=1 |
| integrated i128 / `zllvm_xor_i32_ones` | R04=1 |
| focused fma / `compiler_rt.fma.fma` | L01=5, R01=5, R04=10, R05=14 |
| fma helpers / `compiler_rt.fma.add_and_denorm` | L01=1, R01=2, R04=1, R05=2, R06=1 |
| fma helpers / `math.ldexp.ldexp__anon_5959` | L01=7, R01=2, R02=4, R04=2, R05=4, R06=1 |

The exact ten focused/integrated `__multi3` occurrences are:

```text
%2  R05 and  i64 %.sroa.01.0.extract.trunc, 4294967295
%3  R05 and  i64 %.sroa.04.0.extract.trunc, 4294967295
%5  R01 lshr i64 %4, 32
%6  R05 and  i64 %4, 4294967295
%7  R01 lshr i64 %.sroa.01.0.extract.trunc, 32
%10 R01 lshr i64 %9, 32
%11 R05 and  i64 %9, 4294967295
%12 R01 lshr i64 %.sroa.04.0.extract.trunc, 32
%15 R02 shl  i64 %14, 32
%17 R01 lshr i64 %14, 32
```

The duplicate focused and integrated counts are intentional: they are
separate canary invocation surfaces over the same compiler-rt body.

## `ValueUseExpiredSource` semantic audit

`ValueUseExpiredSource` has one producer:
`value_use/planning.zig:253`. It is raised only after all of these have
succeeded:

1. named binding lookup;
2. canonical current-location resolution;
3. canonical address-dependency validation; and
4. the at-or-after Boolean returned `false`.

Consumers then provenance-map it beside `ValueUseUnresolvedSource` in the
approved memory, scalar, CFG, and call diagnostic mappers. Its intended
meaning, established by the original O2-2 skeleton, is therefore:

> the named source still has a map entry, but its lifetime does not cover
> this instruction, so the request may not consume it.

It is **not** intended to mean:

- “there is no allocation plan”;
- “the source need not survive after the instruction”;
- “another occupant does not need preservation”; or
- “canonical dependency metadata is malformed.”

The no-plan path currently overloads the error with the first meaning. The
missing ordinary interval path has the opposite problem: it returns `true`
and can admit a source without an interval.

### Non-resurrection proof obligation

Changing no-plan/empty-domain from `false` to unconditional `true` is unsafe.
`expireExpiredBindings` does not remove stale entries; it only sets
`expired_binding_this_position`. A map entry can therefore outlive its
interval. Presence in `selector.values` is insufficient proof of Q1.

Any reviewed Q1 authority must satisfy one of these two closed designs:

1. **Plan-required design:** production and production-path tests always
   provide a plan. No-plan Q1 returns a distinct error. Direct unit fixtures
   that intend a current source install a minimal real plan interval.
2. **Explicit canonical-generation design:** a binding carries an
   authority-owned active generation/availability token, updated atomically
   by bind, durable relocation, removal, invalidation, snapshot, and
   rollback. No-plan Q1 admits only the active generation. A removed binding,
   invalid generation, or pre-current tombstone remains unresolved/expired.

Without one of those proofs, no-plan must fail closed. A test-only function
name, family predicate, or “binding present means live” fallback is not
acceptable. A plan-present source with no interval entry likewise requires
an explicit noninterval lifetime class or a distinct missing-entry error;
the current implicit `true` is not a proof.

Request sealing must also pin a Q1-approved source through final action
consumption. Preparation may relocate it durably, but may not drop it merely
because Q2 is false. After consumption, Q2 controls whether the binding must
remain. This lifecycle pin is separate from both Q2 and Q3.

## Production-faithful test model

The next reviewed semantic slice should first add a common scenario builder
that creates the same bindings, domain, position, physical occupancy, and
action for both plan-backed and no-plan cases. It must not use function names.

### Scenario matrix

| Scenario | Plan-backed form | No-plan form | Required assertions |
|---|---|---|---|
| dies exactly at current, sole RAX source | source interval ends at current | explicit active binding generation, or expected distinct no-plan error under plan-required design | Q1 available/error as designed; Q2 false; Q3 none; source remains usable until action consumption |
| live-after sole RAX source | interval ends after current | explicit active generation plus explicit Q2 evidence, or no-plan Q2 error | Q1 available; Q2 true; preserve once |
| dying source plus unrelated live RAX alias | source ends at current, alias after | same canonical generations | Q3 returns alias, preserves physical value once, canonical refresh updates both aliases |
| source and alias share RAX but both die at current | both end at current | same canonical generations | Q3 live-after result none; current-only operand ordering is represented by Q1/action plan, not Q2 |
| source already spilled, live RAX occupant unrelated | source spill interval covers current, occupant after | same canonical generations | Q1 resolves spill; Q3 preserves occupant; action reload order exact |
| released binding | interval ends before current while stale map entry remains | removed/tombstoned generation | Q1 fails `ValueUseExpiredSource` or a more precise closed variant; never materializes |
| binding missing | any | any | `ValueUseUnresolvedSource` before dependency/liveness errors |
| valid transitive address dependency | live owner extends base/index/addend | no-plan is `AddressDependencyMissingPlan` unless explicit graph lifetime evidence exists | identical dependency closure and error propagation |
| malformed owner/dependency | each existing failure class | same | exact error; zero mutation; no Boolean conversion |

### Exact `%11` regression

The production-faithful `%11` fixture must use:

```text
current=16
%9  -> RAX, end=16, accumulator-domain occupant=%9
%10 -> spill64:slot9, end=29
no other EAX/RAX binding
empty dependency domain
R05 action with planned result spill64:slot10
```

It must independently assert:

```text
Q1(%9)=available-through-consumption
Q2(%9)=false
Q3(destination=RAX, excluding %9)=none
```

Then it must pin the accepted spill/reload/AND/result-spill sequence under
the reviewed source-lifecycle/displacement rule. The current A3 alias test
should remain as a separate Q3 regression but must lose the `__multi3`
production claim.

### No-plan parity

Every scenario should be run:

- with a real `SelectorAllocationPlan`; and
- without a plan only if the selected Q1 design has explicit no-plan
  availability metadata.

The two runs must agree on binding/home/dependency errors and on instruction
rollback. They may differ only in the explicit no-plan authority result
chosen by the reviewed design. No test may obtain parity by omitting the
accumulator domain, inventing aliases, or treating a missing plan as
`false`/`true`.

## Separate-authority hypothesis: evidence for and against

### Evidence for

- Production `%11` has Q1=true, Q2=false, Q3=none. No single Boolean can
  encode that triple.
- The no-plan unit failure is Q1, while A2's source displacement is Q2 and
  A3's alias scan is Q3. They fail in different phases and require different
  evidence.
- Dependency closure is relevant to all three questions but with different
  boundaries. Sharing the traversal is sound; sharing the final Boolean is
  not.
- `preserve_current_position_values` already proves Q3 sometimes needs an
  inclusive boundary even when ordinary Q2 uses after-current.
- Existing accepted code has both liveness-aware arithmetic displacement and
  inclusive/current-preserving displacement. The distinction is historical
  behavior, not a new immediate-family exception.
- A sealed source needs an instruction-local pin even when it dies at
  current. That is Q1 lifecycle, not artificial post-instruction liveness.

### Evidence against / costs

- Three public-looking predicates could drift or be called in the wrong
  order.
- Dependency traversal and plan lookup could be duplicated, increasing
  error-precedence risk.
- Q3 still requires a physical-home scan and alias coalescing; Q1/Q2 alone
  cannot replace it.
- A safe no-plan Q1 answer may require new binding-generation metadata. If
  that state cannot be made snapshot/rollback-complete, the plan-required
  design is safer.
- Accepted byte policy is not derivable from liveness alone. Closed action
  plans must continue to own legacy spill/reuse choices without consumer
  hints.

### Required containment if accepted

The strongest design is not three unrelated helpers. It is one internal,
error-bearing lifetime context that validates canonical binding and
dependency metadata once, then exposes three narrow decisions:

```text
availabilityForConsumption(request) -> available/pinned or explicit error
mustSurviveInstruction(identity)    -> bool or explicit error
occupantNeedsPreservation(dest, excluding request identities)
                                     -> canonical identity/null or explicit error
```

The context may share plan/dependency data, but the result types and
boundaries remain distinct. Q1 runs at seal and revalidates after mutation;
Q2 runs only where post-instruction survival is relevant; Q3 runs immediately
before the first destructive physical write. No consumer supplies a home,
boundary, function name, or family hint.

## Design-review stop

The evidence supports separate Q1/Q2/Q3 authorities and disproves both an
unconditional no-plan Boolean fallback and the current production claim of
the A3 `__multi3` alias test. It does not authorize a concrete error-union
change, action amendment, or B3 resume. The Reviewer must first choose:

1. plan-required Q1 versus explicit canonical-generation Q1;
2. the closed error for a plan-present binding missing an interval;
3. the instruction-local source pin/displacement rule that reproduces the
   accepted `%11` stream while Q2 remains false and Q3 remains empty.

Until then, production remains at ratchet 166 and the three B3 carriers
remain parked.
