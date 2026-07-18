# INBOX-153 — B03–B07 admission diagnosis

Status: evidence only. This document is anchored to the accepted
ratchet-152 production tree. It does not authorize or contain an action,
model, consumer, test, guard, tool, or build change. The direct-resolution
ratchet remains **152**. No performance or Tier-3 command was run.

## Conclusion

The retained families do not share one root cause.

| Family | First failing request(s) | Root classification | Scope proved by isolation |
|---|---|---|---|
| B03 | fixture lhs | interval bookkeeping | fixture-only |
| B04 | fixture lhs or rhs, depending on row | plan construction and interval bookkeeping | fixture-only |
| B05 | fixture lhs | plan construction and interval bookkeeping | fixture-only |
| B06 | fixture lhs | plan construction | fixture-only |
| B07 | fixture lhs; cohort rhs | fixture plan construction; production request-identity/RHS-resolution-channel mismatch | shared family, two distinct causes |

B03–B06 have no production-cohort admission failure. Their isolated
cohort reports, objects, owners, and all 285 emitted functions were exact.
Their dormant action fixtures also pass because those fixtures install a
real `SelectorAllocationPlan` with current-inclusive entries for every
named request. The failing wired-path unit fixtures predate the Q1
lifetime contract and either install no plan or install a partial plan
without all registered operands.

B07 has both that fixture-construction problem and a separate production
problem. In six accepted compiler-rt rows the rhs is a planned loop-forward
identity. It intentionally has no current `selector.values` binding, but
the allocation plan contains a `ForwardValuePlan`, an assignment, and a
current-inclusive interval. Legacy `resolveValue` resolves that identity
through `resolveForwardValue`; transaction Q1 rejects it at the earlier
`selector.values.get` step as `ValueUseUnresolvedSource`. This is not a
physical-home capability gap.

No family is ready to move from its accepted INBOX-152 residual owner on
the basis of this diagnosis alone.

## Frozen baseline and evidence provenance

The accepted production commit is
`e048ff5cb7818f0b1e99d6971b9542562ffcf086`, with tree
`5c5bfa8cc202ec6403799b56df2e613275bdeb22`. Its immutable performance
evidence is `cf07e35b`; the authorization HEAD used for this diagnosis was
`ba2e3671`. The latter adds Supervisor documentation only.

The accepted identities remain:

```text
ratchet=152
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
```

The INBOX-151 isolated source/artifact pairs reused here are:

| Family | Isolated consumer SHA-256 | Isolated artifact SHA-256 | Original full-unit log SHA-256 |
|---|---|---|---|
| B03 | `48c64e143431f50c6862d867bd503843e8c6eb82db6501d44c0f55feb6a50c02` | `31f9fcf6d7509e04e96c9e94f005193915a01f7173f461c6be5beea6961e9e93` | `d91407f00a5f0f32b659b87f655065bb8b8625dfe12f4000379dbc97a0c36538` |
| B04 | `bc35f972e0d73526b35576e806079decbcf027c5d2828f9c3a3bc4117affbdf4` | `17f84264a27b12ac87b73039574676095d6c751b97676d63d07efa6088862adb` | `8c613e402c0bff65d92b0aea5f8d2b9d6628405e91a36f81c0bcb8898b8b297e` |
| B05 | `341095b31d23a71faa54f90cc3e6cf10fa01f1a8eeac934b87baabe275c3361b` | `855c87081c6c8b7cc7d7f1958372d700b98f8cf473d9ac6029dbb495a85053b1` | `26a867cbd710fddb44903068fcbdf89b6da7e998731e9be2f12ded76e73626e4` |
| B06 | `10c33fc563bfa09e10092cfd8c4393bced78cb2dcfcb1d004dce820e7731713d` | `d23c3eca92333c3c761e9216207e56637dd1ed16eaead749db43a5bd4172f8e6` | `25aac2e201c63228d1a6d4e4ec3dac5f62e3559985b46a0e1d6f4de9389bac59` |
| B07 | `83f8bd6638f34a8b467e9a686f5cea00a0ea8ccc12ee9a4bc418301071ffb475` | `5797b1d19fc5730a6f31a6e2e224082eef1e6be92d47d4f4d2564bbf5f227281` | `edbce587fbc04c8bd1d6b52d54c44fa63e1b48ad0fafdcb88b27d5671c8ea873` |

Read-only trace instrumentation was applied only in a detached temporary
worktree to the retained isolated consumer. The last instrumented source
had SHA-256
`8d86f70d0b75b8c27e613cc733a1fa89f66af5e6433423ab5ad709cced433c91`.
It recorded the caught error and phase, request handles and provenance,
bindings, plan entries, forward metadata, assignments, legacy resolution,
and dependency edges. The worktree and instrumentation were removed before
this document was added. The retained trace logs are ignored procedural
artifacts under `tmp/inbox153_o2_admission_diagnosis/`:

| Trace | SHA-256 |
|---|---|
| B03 fixture | `011dad244ebc7aceb422c70b97a5b66e2973c3398bb191d898d7dbb29cb38ef1` |
| B04 fixtures | `99413659b8f3b7080fea457cc499d1e6484187f11091744f0ca58efebb752474` |
| B05 fixtures | `6bb33b6668d7d7eb76b3da9b61d18552459ee02e39aef104fc51ef93b3782113` |
| B06 fixture | `abf0f825ce63d7b017a1b3efb9d1184849572fb46378987c704497c39d32dee5` |
| B07 fixture | `c48be540ce9f61c9d33350bbd8b98df1b33c89444ea208368210f63e5af6e4ac` |
| B07 six-row detailed cohort trace | `5319166b0644fda66f9499402cf76fdfa5783e6cd1aeff0d537a1f6fa565ac0a` |

The fixture traces came from direct full-unit execution of each retained
isolated family source. The six-row trace came from the frozen compiler-rt
report command using the isolated B07 artifact. Instrumentation changed no
admission decision.

## Shared request and admission route

Every isolated named-binary lowering registers requests in legacy source
order:

| Stable handle | Semantic role | Source | Destination |
|---|---|---|---|
| `{ index = 0, generation = 1 }` | lhs/action owner | `binary.lhs` | `.prepared_view` |
| `{ index = 1, generation = 1 }` | rhs/secondary operand | `binary.rhs` | `.prepared_source` |

The raw handle owner token is transaction-instance-specific and has no
source semantics; the stable index/generation and retained local handle
establish provenance. `seal()` validates index 0 before index 1. The first
request-specific error is recorded once and survives rollback, so the
`failedRequestIs(lhs_request)` and `failedRequestIs(rhs_request)` results
below identify the actual first failure rather than a later action-owner
rewrite.

For a named request, current Q1
`core_availabilityForConsumption` performs this sequence:

```text
selector.values.get(identity)       else ValueUseUnresolvedSource
selector.allocation_plan            else ValueUseSourcePlanMissing
plan.intervalEnd(identity)           else ValueUseSourceIntervalMissing
validateAddressDependenciesForUse
valueIsLiveAtOrAfterCurrent          else ValueUseExpiredSource
pin identity + binding generation
```

By contrast, the legacy scalar path calls `resolveValue`. For a named
value, that is:

```text
valueLoc(selector, name)
    orelse resolveForwardValue(selector, name)
```

`resolveForwardValue` accepts a plan-backed value only before its
`definition_position`, and only when its planned assignment agrees with
its recorded virtual class. This legacy second channel is the material
difference for the six B07 cohort rows.

`SelectorAllocationPlan` persists interval ends, not interval starts.
Accordingly, the fixture tables below record the exact persisted
`interval_end`; “none” means no interval exists. For the six production
forward uses, the start is recoverable exactly from the planner's
earliest-use rewrite and the `ForwardValuePlan`, so the full reconstructed
range is also recorded.

## Why dormant fixtures pass and wired-path fixtures fail

The dormant `scalar_named_tests.zig` setup is production-faithful with
respect to the transaction lifetime contract:

```text
current_position=1
lhs interval_end=1
rhs interval_end=1
result interval_end=2 where a result is consumed later
address_dependency_domain=empty and valid
```

Every named source is bound, every request has a real plan entry, and the
dependency domain is canonical. Family-specific tests add exact longer
intervals only when they are testing survival or preservation.

The older wired-path selector fixtures were built to test legacy
`resolveValue`, accumulator displacement, and instruction order. Legacy
resolution requires a binding or a forward assignment but does not require
an allocation plan entry for each current binding. Consequently those
fixtures either have no allocation plan or have a partial plan containing
only the one value whose liveness mattered to the old test. Wiring the
complete consumer correctly makes Q1 validate both requests during
`seal()`, exposing the missing fixture metadata before any mutation.

This difference is not evidence that Q1 should silently accept a missing
plan or interval. INBOX-137 intentionally made both conditions distinct,
request-attributable, fail-closed errors. The production cohort result is
the discriminator: B03–B06 are exact under the real planner, while B07 is
not.

## B03 — narrow named multiply

### Exact failing row and trace

```text
fixture=named i32 multiply preserves the accepted accumulator-before-rhs order
machine=mul-i32-preserve-order
current_position=4
phase=seal
error=ValueUseSourceIntervalMissing
first_failed_request=lhs { index=0, generation=1 }
rhs_failed=false
dependency_owner_count=0
```

| Role | Identity | Expected type/class | Canonical binding | Home | Plan and exact interval | Legacy route | Dependency edge |
|---|---|---|---|---|---|---|---|
| lhs | `lhs` | i32 / gpr32 | vreg 1, gpr64, 64 defined bits | spill64 slot 2 | plan present; `interval_end=none`; no forward entry or assignment | resolves spill64 slot 2 | none |
| rhs | `rhs` | i32 / gpr32 | vreg 2, gpr64, 64 defined bits | spill64 slot 3 | plan present; `interval_end=none`; no forward entry or assignment | resolves spill64 slot 3 | none |

The partial plan contains only the unrelated live value used by the
fixture's preservation setup. Q1 rejects lhs first. The legacy B03 route
prepares the accumulator before staging rhs and can resolve both spill
bindings without plan entries.

Classification: **interval bookkeeping**, fixture-only. The isolated B03
cohort has the exact report/object/owner identities and a 285/0/0
per-function comparison, proving the real planner supplies adequate
metadata for every production occurrence. The dormant B03 action fixture
passes with explicit current-inclusive lhs/rhs entries.

Bounded remediation proposal: align this exact legacy unit fixture with a
real plan containing the two semantic source intervals and the existing
unrelated-live interval. Endpoints must encode the fixture's stated
current-use and future-liveness intent; they must not use a blanket
`maxInt`. Keep the instruction and binding expectations unchanged. This
requires no action/model change, consumer home inspection, or
function-name predicate.

## B04 — narrow named shifts

### Exact failing rows and traces

| Fixture / machine | Position | Error | First failed request |
|---|---:|---|---|
| `accumulator-resident named i32 shift keeps accepted direct materialization stream` / `shift-i32-accumulator-lhs` | 4 | `ValueUseSourceIntervalMissing` | rhs `{1,1}` |
| `generic cfg selector lowers variable i16 shifts` / `variable-i16-shift` | 1 | `ValueUseSourcePlanMissing` | lhs `{0,1}` |
| `generic cfg selector lowers i32 arithmetic-right shifts` / `i32-ashr` | 0 | `ValueUseSourceIntervalMissing` | rhs `{1,1}` |

All failures occur during `seal()` before mutation; dependency-owner count
is zero in all three.

| Row | Role | Identity | Type/class; binding width | Home | Plan and exact interval | Legacy route |
|---|---|---|---|---|---|---|
| direct i32 | lhs | `lhs` | i32/gpr32; vreg 0 gpr32/32 | EAX | present; `interval_end=9` | EAX |
| direct i32 | rhs | `amount` | i32/gpr32; vreg 1 gpr32/32 | arg32 RSI | present; `interval_end=none` | arg32 RSI |
| variable i16 | lhs | `value` | i16/gpr32; vreg 0 gpr32/32 | arg32 RDI | plan absent; no interval | arg32 RDI |
| variable i16 | rhs | `amount` | i16/gpr32; vreg 1 gpr32/32 | arg32 RSI | plan absent; no interval | arg32 RSI |
| i32 ashr | lhs | `value` | i32/gpr32; vreg 0 gpr32/32 | arg32 RDI | present; `interval_end=0` | arg32 RDI |
| i32 ashr | rhs | `amount` | i32/gpr32; vreg 1 gpr32/32 | arg32 RSI | present; `interval_end=none` | arg32 RSI |

No row has an address-dependency owner or edge. The accepted legacy route
stages rhs into RCX before accumulator preparation; its direct
`emitValueIntoScratch` and later lhs materialization use the installed
bindings and do not demand a complete plan.

Classification: the variable-i16 row is **plan construction**; the two
other rows are **interval bookkeeping**. All are fixture-only. B04's
isolated production cohort is exact down to all function bytes, while the
dormant B04 action fixture gives both named operands current-inclusive
entries and passes.

Bounded remediation proposal: give each of these three fixtures a complete
real plan for both registered operands. Preserve the existing long-lived
lhs endpoint 9 in the direct-i32 case; add only the rhs interval its
current-use semantics require. For the other rows, derive current-inclusive
endpoints from their tiny fixture instruction positions. Do not alter
B04's rhs-before-prepare action order or admission rules.

## B05 — wide named shifts

### Exact failing rows and traces

| Fixture / machine | Position | Error | First failed request |
|---|---:|---|---|
| `generic cfg selector exact ei binary and shift reuse a dead accumulator lhs` / `dead-rax-exact-ei` | 1 | `ValueUseSourcePlanMissing` | lhs `{0,1}` |
| `exact ei shift preserves accepted current-use accumulator rhs spill` / `current-rhs-exact-ei` | 4 | `ValueUseSourceIntervalMissing` | lhs `{0,1}` |

| Row | Role | Identity | Type/class; binding width | Home | Plan and exact interval | Legacy route |
|---|---|---|---|---|---|---|
| dead-RAX exact-EI | lhs | `source` | i56/gpr64; vreg 0 gpr64/64 | RAX | plan absent; no interval | RAX |
| dead-RAX exact-EI | rhs | `amount` | i56/gpr64; vreg 1 gpr64/64 | arg64 RSI | plan absent; no interval | arg64 RSI |
| current-rhs exact-EI | lhs | `lhs` | i56/gpr64; vreg 0 gpr64/64 | spill64 slot 6 | present; `interval_end=none` | spill64 slot 6 |
| current-rhs exact-EI | rhs | `amount` | i56/gpr64; vreg 1 gpr64/64 | RAX | present; `interval_end=4` | RAX |

The address-dependency domain is empty in both rows. The first row's
failure is plan construction. The second has a deliberately modeled
current-use rhs but omits the equally consumed lhs; it is interval
bookkeeping. Q1 therefore fails lhs before reaching rhs. Legacy B05 stages
rhs first and then uses the accepted accumulator-preserve-current
displacement for lhs without demanding complete request intervals.

Classification: **plan construction plus interval bookkeeping**,
fixture-only. The isolated B05 cohort and every emitted function are
exact; dormant B05 passes with both requests represented.

Bounded remediation proposal: install exact lhs and rhs entries in both
fixtures, retaining rhs `interval_end=4` in the current-rhs case and
encoding the dead-at/current boundary intended by the other case. Preserve
the accepted source-liveness policy and staging order; do not weaken Q1.

## B06 — wide exact-EI named binary

### Exact failing row and trace

```text
fixture=generic cfg selector exact ei binary and shift reuse a dead accumulator lhs
active_subcase=wide exact-EI OR
machine=dead-rax-exact-ei
current_position=1
phase=seal
error=ValueUseSourcePlanMissing
first_failed_request=lhs { index=0, generation=1 }
dependency_owner_count=0
```

| Role | Identity | Expected type/class | Canonical binding | Home | Plan and exact interval | Legacy route |
|---|---|---|---|---|---|---|
| lhs | `source` | i55 / gpr64 | vreg 0, gpr64, 64 defined bits | RAX | plan absent; no interval | RAX |
| rhs | `amount` | i55 / gpr64 | vreg 1, gpr64, 64 defined bits | arg64 RSI | plan absent; no interval | arg64 RSI |

Classification: **plan construction**, fixture-only. The dormant B06 test
installs both entries and passes. The isolated B06 production cohort is
exact for report/object/owner and all emitted functions, so this is not a
production admission gap.

Bounded remediation proposal: add the exact current-use intervals for both
named operands to the shared exact-EI fixture. Keep B06's accepted rhs
staging, accumulator preparation, and diagnostics untouched.

## B07 — general named binary

### Fixture: valid bindings rejected because the plan is absent

```text
fixture=generic cfg selector reloads 32-bit spill rhs for binary accumulator op
machine=reload-spill32-rhs
current_position=1
phase=seal
error=ValueUseSourcePlanMissing
first_failed_request=lhs { index=0, generation=1 }
dependency_owner_count=0
```

| Role | Identity | Expected type/class | Canonical binding | Home | Plan and exact interval | Legacy route |
|---|---|---|---|---|---|---|
| lhs | `lhs` | i32/gpr32 | vreg 0, gpr32, 32 defined bits | scratch32 RDI | plan absent; no interval | scratch32 RDI |
| rhs | `rhs` | i32/gpr32 | vreg 1, gpr64, 64 defined bits | spill64 slot 4 | plan absent; no interval | spill64 slot 4, accepted low-32 reload |

This is the required **valid binding rejected by admission** case. Both
bindings and their homes are valid for the audited B07 action. Q1 rejects
the first request because the fixture has no plan. Classification:
**plan construction**, fixture-only.

The bounded fixture remedy is the same production-faithful alignment as
B03–B06: install exact current-inclusive entries for both operands while
retaining the gpr64/64 spill binding that exercises the accepted low-32
semantic view. No compatibility or home-admission expansion is indicated.

### Production: all six forward-RHS regressions

All six production failures occur at `seal()` with
`ValueUseUnresolvedSource`. Registration is lhs index 0 followed by rhs
index 1. Lhs passes; provenance records rhs `{ index=1, generation=1 }`.
The address-dependency domain has zero owners and neither request has an
edge.

The detailed trace corrects the coarse INBOX-151 attribution for the three
unsigned rows: the first rejected B07 producer is `%13 = sub`, not the
later masked/combined value observed after report-level comparison.

| Function | Position and exact producer | Lhs binding/home/interval | RHS plan-backed identity | Legacy rhs resolution |
|---|---|---|---|---|
| `compiler_rt.floatuneidf.__floatuneidf` | 25: `%13 = sub nuw i64 %12, %20` | `%12`: vreg 22, gpr64/64, RAX; reconstructed interval `[24,25]`, persisted end 25; planned assignment RCX | `%20`: no current binding; gpr64/64 forward definition 37, assignment R9, reconstructed interval `[25,42]`, persisted end 42 | scratch64 R9 |
| `compiler_rt.floatuneisf.__floatuneisf` | 25: `%13 = sub nuw i64 %12, %20` | `%12`: vreg 23, gpr64/64, RAX; `[24,25]`, end 25; assignment RCX | `%20`: no current binding; gpr64/64 forward definition 37, assignment R9, `[25,42]`, end 42 | scratch64 R9 |
| `compiler_rt.floatuneihf.__floatuneihf` | 25: `%13 = sub nuw i64 %12, %20` | `%12`: vreg 22, gpr64/64, RAX; `[24,25]`, end 25; assignment RCX | `%20`: no current binding; gpr64/64 forward definition 37, assignment R9, `[25,42]`, end 42 | scratch64 R9 |
| `compiler_rt.floateidf.__floateidf` | 29: `%17 = sub i64 %.neg, %26` | `%.neg`: vreg 26, gpr64/64, RAX; reconstructed interval `[28,29]`, persisted end 29; assignment R9 | `%26`: no current binding; gpr64/64 forward definition 42, spill assignment 0, reconstructed interval `[29,47]`, persisted end 47 | spill64 slot 0 |
| `compiler_rt.floateisf.__floateisf` | 29: `%17 = sub i64 %.neg, %26` | `%.neg`: vreg 27, gpr64/64, RAX; `[28,29]`, end 29; assignment R9 | `%26`: no current binding; gpr64/64 forward definition 42, spill assignment 0, `[29,47]`, end 47 | spill64 slot 0 |
| `compiler_rt.floateihf.__floateihf` | 29: `%17 = sub i64 %.neg, %26` | `%.neg`: vreg 26, gpr64/64, RAX; `[28,29]`, end 29; assignment R9 | `%26`: no current binding; gpr64/64 forward definition 42, spill assignment 0, `[29,47]`, end 47 | spill64 slot 0 |

For every row:

- both semantic requests are i64/gpr64;
- lhs is an ordinary current binding and passes Q1;
- rhs has a valid allocation-plan interval, `ForwardValuePlan`, virtual
  metadata, and physical assignment;
- rhs has no current `selector.values` binding because its IR definition is
  later in the loop order;
- legacy `resolveForwardValue` checks `current_position <
  definition_position`, validates assignment/class compatibility, and
  returns the recorded R9 or spill home;
- Q1 stops before consulting any of that forward metadata;
- dependency validation is not the cause: there are no domain owners or
  edges.

This is the required **unresolved identity** distinction. The identity is
not unresolved to the IR planner or legacy selector; it is unresolved only
under Q1's current-binding-only request model. Conversely, none of these
six rows is a current binding rejected because of its home. The valid
binding/admission case is the separate B07 unit fixture above.

The production proof is the isolated B07 cohort movement:

```text
report_sha256=9e283eade6790443768b41e112c7c8f28993564d3df83fc5c5e5d1737a27ae72
report=443 selected / 279 emitted / 164 failed
new_diagnostic=unsupported_value/composed-block-unknown-rhs
new_failures=the six functions listed above
```

Stubbing exactly those six functions in both baseline and B07 inputs
restored an exact object and a 285/0/0 comparison for all surviving
definitions in INBOX-151. Therefore this gap is production-only for those
six rows and is the first semantic divergence; it is not downstream
branch-offset movement.

Classification: **request identity plus RHS resolution-channel failure**.
`ValueUseUnresolvedSource` is the observed Q1 error, but broadening ordinary
Q1 availability to ignore missing bindings would be incorrect.

Bounded remediation proposal for design review:

1. Add a private, transaction-owned admission branch for a named request
   that lacks a current binding but has a canonical `ForwardValuePlan`.
2. Require all of the same structural facts used by legacy forward
   resolution: current position strictly before definition, matching
   virtual class/defined width, a planned assignment, and an interval
   covering the current instruction.
3. Validate address dependencies and any forward-plan generation/identity
   metadata before pinning the request.
4. Pin only durable identity and plan-generation/definition/assignment
   metadata, never a pre-mutation `ValueLoc`.
5. Re-resolve canonically at materialization time through one shared
   selector-owned forward resolver, so relocation or plan staleness fails
   closed.
6. Use distinct closed errors for a missing binding with no valid forward
   plan versus malformed or stale forward metadata; retain first-request
   provenance.

The branch is structural for every plan-backed forward named use. It
contains no function/family/name predicate, consumer-selected home, or
consumer-side location inspection. It does not grant a new physical home:
only assignments already accepted by the canonical planner and legacy
resolver qualify. The exact error surface and ownership would require a
separately reviewed dormant amendment; none is authorized here.

## Remediation ordering proposed for review

1. Align the listed B03–B07 legacy unit fixtures with production-faithful
   plans, preserving all existing instruction and diagnostic expectations.
   This is fixture work, not an admission relaxation.
2. Add focused transaction tests that distinguish:
   current binding + missing plan, current binding + missing interval,
   valid forward identity, malformed forward metadata, expired forward
   interval, class/defined-width mismatch, and missing assignment.
3. Only after those tests are reviewed, consider the private forward-Q1
   admission amendment described above.
4. Re-run complete family isolation. B03–B06 cannot be inferred ready from
   fixture alignment alone; B07 must restore all six rows and exact object/
   owner/per-function identity before any wiring is considered.

No transactional attempt-then-legacy fallback is proposed. The accepted
residual owners remain:

```text
B03 scalar_named_b03_interval_admission
B04 scalar_named_b04_interval_admission
B05 scalar_named_b05_interval_admission
B06 scalar_named_b06_interval_admission
B07 scalar_named_b07_rhs_admission
```

## Closeout

The tracked change for INBOX-153 is this document only. Temporary
instrumentation has been removed. The accepted ratchet remains 152; no
production identity was regenerated because no production input changed.
No performance, Tier-2, or Tier-3 command was run. `stash@{0}` and all
preserved patches remain untouched.
