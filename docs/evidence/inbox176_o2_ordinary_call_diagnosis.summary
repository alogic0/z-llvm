# INBOX-176 — ordinary-call isolation failure diagnosis

Status: **diagnosis complete; no remedy implemented.** The ordinary call
family remains retained wholesale, `zig.target.intByteSize` and aggregate
isolation remain unauthorized, and the O2 bypass ratchet remains **131**.

This slice changed no production, action, model, planning, lifetime/Q1,
materialization, facade, capability, classifier, fixture, or guard policy.
Only this evidence file is tracked. All temporary consumer, guard, lifetime,
action, and project-root test instrumentation was removed before this commit.

## Frozen basis and retained artifacts

```text
dispatch_operating_commit=982929dcc996abac1ce145083726ec2787b19766
composite_provenance_head=dc8609a4cbcd4b84f3733eeac87d4fee4b05e6dc
exact_codegen_source_baseline=c1ffd1cc0940b8dd1354c14f3bb7ca53c4709532
accepted_INBOX_174a_source=c1ffd1cc0940b8dd1354c14f3bb7ca53c4709532
accepted_INBOX_175_stop_evidence=fd48a962
ratchet_before=131
ratchet_after=131
direct_credit=0
helper_collapse_credit=0
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
stash_subject=INBOX-93 preserve B2B wiring plus five diagnosis tests
```

The retained INBOX-175 ordinary patch was copied without modification:

```text
source=tmp/inbox175_o2_call_isolation/patches/ordinary.patch
diagnostic_copy=tmp/inbox176_o2_call_diagnosis/patches/ordinary.patch
sha256=b337761f6944b689b631a13dc60c8ba58e5226ee623a655329aff1d9205b3834
git_apply_check_before_diagnosis=pass
git_apply_check_after_restoration=pass
```

Temporary diagnostic sources were frozen before execution:

```text
ordinary_plus_instrumentation.patch=e126578fbe14b5bba55e50e8651f533e8dbdefadaafbac1d8be1bc56d96252e6
legacy_instrumentation.patch=242b04d7e6114bda77df561dc06e74cd9862dc67afd8fc79534790576dc3c76f
project_root_focus_aggregator=e6844b99d2d5689324c459fe37cfa86d87ded108a6d6e977d813100e390a5e74
```

The project-root focus aggregator imported only
`composed_selector_calls_tests.zig`,
`source_guard/consumer_policy_tests.zig`, and
`source_guard/split_policy_tests.zig`. It was removed from `src/` after the
focused runs; an exact retained copy is at
`tmp/inbox176_o2_call_diagnosis/patches/inbox176_focus_tests.zig`.

## Authorized focused commands

No broad gate was run. The four decisive commands were:

```text
command=/home/oleg/bin/zig test src/inbox176_focus_tests.zig --test-filter "composed selector stages a dead accumulator argument before dropping its binding"
tree=ordinary retained patch plus temporary phase/state instrumentation
expected_result=FAIL at the retained ordinary-path defect
log=tmp/inbox176_o2_call_diagnosis/logs/ordinary_dies_at_current.log
log_sha256=359000551c83adec7ec6f97504d1826c9ed220a573b373bdb394a3b0be6a507e
```

```text
command=/home/oleg/bin/zig test src/inbox176_focus_tests.zig --test-filter "composed selector source guard confines failure provenance to the memcpy mapper"
tree=ordinary retained patch plus temporary guard trace
expected_result=FAIL at the retained temporary guard accounting
log=tmp/inbox176_o2_call_diagnosis/logs/guard_failure_provenance.log
log_sha256=2385ea3daeeca7919c04a0880a76e5b13fd03805dcef19011809ceb2647303e3
```

```text
command=/home/oleg/bin/zig test src/inbox176_focus_tests.zig --test-filter "composed selector source guard accepts the fully classified current tree"
tree=ordinary retained patch plus temporary guard trace
expected_result=FAIL at the retained temporary guard accounting
log=tmp/inbox176_o2_call_diagnosis/logs/guard_current_tree.log
log_sha256=70f2991201e8e372c69432e5857f3da630f5bd4341b3b0ceb2b0d7e2ca9f9129
```

```text
command=/home/oleg/bin/zig test src/inbox176_focus_tests.zig --test-filter "composed selector stages a dead accumulator argument before dropping its binding"
tree=unwired c1ffd1cc codegen source plus temporary read-only legacy state trace
result=1/1 PASS
log=tmp/inbox176_o2_call_diagnosis/logs/legacy_dies_at_current_exact.log
log_sha256=d9bc618f75e0096d9cbd3d26d12f3d161ec7fded59ee3a09f7ec2b18c7582b64
```

Early focus-discovery probes that exercised only lazy root aggregators, or
used a nested module root that Zig rejected as importing outside its module
path, are retained under the same temporary directory but are explicitly
excluded from the findings. They are not gate evidence.

## Finding 1 — exact transaction failure

The failure is at **seal/Q1**. It is not a request-construction, prepare,
materialization, or action-execution failure.

The precise path is:

```text
lowerOrdinaryDirectCallValueUse
  -> transaction.register(request 0)                         succeeds
  -> transaction.seal()
  -> planning/physical_mapping.seal request loop
  -> lifetime_admission.validateRequestAt(request 0)
  -> lifetime_admission.validateRequest
  -> core_availabilityForConsumption
  -> valueIsLiveAtOrAfterCurrent("argument")                 false
  -> error.ValueUseExpiredSource
```

`validateRequestAt` records request boundary provenance before returning the
error. The focused trace proves:

```text
phase=request-construction index=0 request_failed=false
phase=seal error=ValueUseExpiredSource request0_failed=true
```

The retained consumer catches that error at `seal()` and invokes
`directCallValueUseDiagnostic`. Because `failedRequestIs(argument_handle)` is
true and the request is scalar, the exhaustive fallback maps:

```text
transaction_error=ValueUseExpiredSource
provenance=request 0 / scalar argument
legacy_diagnostic_kind=unsupported_value
legacy_diagnostic_detail=composed-block-call-unknown-arg
```

The action attaches only after a successful seal in the retained patch.
Therefore `attachCallAction`, `prepare`, `materializeAll`, and
`executeAttachedCallAction` are never reached. No later layer is masking the
failure.

## Finding 2 — exact lifetime and selector state

The unchanged production-path fixture installs:

```text
source_identity=argument
semantic_type=i32
current_position=1
allocation_plan=present
stored_interval_end=0
stored_interval_start=no separately installed start field
dependency_domain=empty (0 owners/edges)
canonical_binding=vreg 0 / gpr32 / 32 defined binding bits / EAX
accumulator_domain_occupant=vreg 0 / gpr32 / 32 / EAX
accumulator_domain_logical_bits=32
accumulator_domain_defined_bits=64
```

The fixture models the value's final use by this instruction. Its accepted
legacy behavior is current-consumption followed by removal, not survival
beyond the instruction. The three authority questions are:

| Question | Result | Evidence |
|---|---:|---|
| Q1: available for transaction consumption now | `false` under current transaction Q1 | `valueIsLiveAtOrAfterCurrent`: `0 >= 1` is false, producing `ValueUseExpiredSource` |
| Q2: must survive the instruction | `false` | strict-after test: `0 > 1` is false |
| Q3: another live alias in the destructive accumulator needs preservation | `false` | the canonical value map has only `argument`; no other EAX/RAX binding survives after current |

The physical accumulator is occupied, but only by the semantic source. That
occupancy must not be confused with a Q3 unrelated-alias obligation.

### Transaction before/after

Before registration:

```text
values=1
instructions=0
spill_slots=0
next_virtual_reg=1
next_spill_slot=0
address_dependencies=0
accumulator_occupied=true
argument=vreg 0 / gpr32 / 32 / EAX
```

At the seal error, and again after automatic rollback/deinit, every field is
identical:

```text
values=1
instructions=0
spill_slots=0
next_virtual_reg=1
next_spill_slot=0
address_dependencies=0
accumulator_occupied=true
argument=vreg 0 / gpr32 / 32 / EAX
result=unbound
```

Thus the transaction fails before mutation and rollback is exact.

### Accepted legacy displacement and staging

The unwired legacy control passes 1/1 from the same fixture. Its accepted
order is:

1. `prepareCallBeforeArguments(.clobber)` asks
   `spillLiveCallerClobbersForCall`.
2. `spillCurrentAccumulator` uses `liveAccumulatorName`; the stored end `0`
   at selector position `1` does not qualify, so it emits no preservation
   spill.
3. `lowerDirectCallArg` resolves the still-canonical EAX binding and stages
   it directly with `mov_eax_to_arg rdi`.
4. Only after argument staging,
   `finishCallPreparationAfterArguments` drops the expired source binding.
5. The call appends and the i32 result becomes the new EAX occupant.

The exact committed state is:

```text
instructions[0]=mov_eax_to_arg rdi
instructions[1]=direct_call { symbol="callee", ret_ty=i32 }
spill_slots=0
next_spill_slot=0
argument_binding=removed
result_binding=vreg 1 / gpr32 / 32 / EAX
values=1
next_virtual_reg=2
address_dependencies=0
```

This is a truthful planned legacy-success fixture. Its interval and expected
stream must not be weakened, relabeled, or moved merely to admit the current
transaction path.

## Finding 3 — remedy classification

The minimal semantic remedy is an **action displacement/admission-plan
amendment**, not a narrower classifier envelope.

The ordinary classifier sees only the semantic call envelope. It cannot
distinguish this current EAX final-use topology from the same admitted i32
named-argument form without inspecting selector state, source homes, or
liveness. Narrowing it enough to avoid this case would therefore retain a
complete semantic call envelope rather than address the isolated lifecycle
ordering. A state-sensitive classifier would violate the established pure
classifier boundary.

The missing closed-plan behavior is the accepted call-specific sequence:
consume/stage a canonical current accumulator source before caller-clobber
preparation drops it, while still preserving Q2-surviving sources and
unrelated Q3 occupants under their existing authorities. Because the current
attachment occurs after seal, a reviewed dormant amendment would also have
to define how this closed action plan participates in admission without
public hints, consumer home inspection, generic Q1 weakening, or a retained
`ValueLoc`. This evidence does not choose or implement that API shape.

Consequences frozen for review:

- do not change generic current-binding Q1;
- do not turn `ValueUseExpiredSource` into success globally;
- do not add attempt-then-fallback;
- do not inspect home/liveness in the consumer classifier;
- do not change the truthful fixture;
- do not partially wire the ordinary family.

## Finding 4 — guard failure: generic opcode marker

The complete-tree guard failure is:

```text
validator=validateDormantCallActionProductionSites
source=composed_selector_eflags.zig
function=instructionEffect
matched_marker=.direct_call
error=ValueUseCallActionPrematureProductionUse
```

`instructionEffect` legitimately classifies the machine instruction
`.direct_call` as an EFLAGS clobber. The temporary INBOX-175 guard treats
`.direct_call` as a generic forbidden action marker in every source except
`composed_selector_calls.zig`, so it rejects an unrelated, pre-existing
machine-opcode authority. If that first rejection were bypassed, the same
text also legitimately appears in the closed calls action implementation.

The required future accounting is function/API-scoped:

- consumer routing is counted only in the exact
  `composed_selector_calls.zig` dispatcher/classifier/transaction-helper
  bodies;
- action attachment/validation/execution tags are counted only in the
  frozen `value_use/actions/calls.zig` API bodies;
- machine opcode classification in
  `composed_selector_eflags.instructionEffect` remains under the EFLAGS
  authority;
- a raw `.direct_call` textual ban is not an action-use policy.

This is a derived policy requirement only. The guard was restored unchanged.

## Finding 5 — guard failure: provenance mapper coupling

The focused provenance guard failure is:

```text
test_source_name=composed_selector_calls.zig
fixture_function_present=inlineMemcpyValueUseDiagnostic
fixture_failedRequestIs_count=3
fixture_function_absent=directCallValueUseDiagnostic
validator=validateFailureProvenanceProductionSites
error=ValueUseFailureProvenanceOutsideAllowlist
```

The accepted focused fixture intentionally models only the existing memcpy
mapper. The temporary INBOX-175 accounting sees any provenance query in the
calls source and then unconditionally requires both the memcpy mapper and the
new ordinary-call mapper. It therefore requires a call-specific API inside
an unrelated memcpy-only fixture.

The required future accounting is per present function/API:

- `inlineMemcpyValueUseDiagnostic`, when present, owns exactly its three
  destination/source/length queries;
- `directCallValueUseDiagnostic`, when present, owns exactly its one
  per-handle-loop query site;
- the real production calls source may require both and a total of four;
- a focused memcpy-only fixture requires only the memcpy mapper and three;
- any query outside the corresponding exact mapper body remains rejected.

Again, this is diagnosis, not a guard amendment. The production and test
guard sources were restored byte-for-byte.

## Restoration and prohibited-work record

The exact codegen source hashes after removing every temporary change are:

```text
composed_selector_calls.zig=f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d
source_guard/consumer_policy.zig=3085a1963faccc6e3d3453fffc6369e6f3936e38738d2a70a8685946f098683e
value_use/actions/calls.zig=90990dd80a6f31c085a7b09e286e8b52674fcf03f29be492c661239a8483cb4c
value_use/planning/lifetime_admission.zig=3974dcfea69d3880e47d61ad40e1caf3c4da3938ef0c595b649568cb45b49f6c
git_diff_c1ffd1cc_for_these_sources=empty
```

Retention tooling and policy remain byte-identical to the composite
provenance head:

```text
build.zig=051381dcd4811460c39c19a0b902deedd69b5722bac15698c8146f5b32b122ff
tools/clean_tmp.zig=8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e
docs/retention_headroom_policy.md=a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd
docs/evidence/tmp_retention_pins.tsv=f4374187d77ec6b7c42ee1b64538ead1a2d599697595a7f59c28b23dae5c6614
docs/evidence/inbox59_would_remove.tsv=bbe785cc4c41686178086ef08c7d28966628043110493ab591dbd440ed512da8
```

`clean-tmp` was not executed and no retained artifact was deleted. No full
unit, isolation, `intByteSize`, aggregate, standalone source guard, ABI,
canary, performance, integrated-exe, strengthened Tier 2, distribution-all,
or Tier 3 command was run. Accepted identities remain the governing frozen
values but were deliberately not regenerated in this diagnostic-only slice:

```text
report=49a19f04 / 443 selected / 285 emitted / 158 failed
object=061a64e4
owner=5d91960e / 167-17-101
```

STOP for Watcher/Reviewer review. No amendment, re-isolation, or production
wiring is authorized by this evidence.
