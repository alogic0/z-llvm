# INBOX-111 — O2-3I-A1 dormant fixed-scratch ICMP actions

Status: complete and validated; delivered for Supervisor/Reviewer review.
The action family is dormant. No ICMP production consumer is wired by this
slice.

## Frozen source and scope

The accepted I-0 code commit is `4e759d0302d33abbfb2e5246cb49eb5be62902e4`
(tree `e9ec10017e6bb3ecf2ed99498268f4c3ffeed1ed`). Work began at the
Supervisor documentation descendant
`aad2b25f41ef2b592d6571284af76adb6c6f49ef` (tree
`082bc18b7ef2849ab1dc04935290d7b3d1f388ba`), without branch movement,
rebase, or reset.

This slice implements only the I-0 fixed-scratch subgroup: 20 audited branch
rows and the future 29-gateway population. It does not implement a
current-home, exact-EI, in-place, or i128 pair action.

Production changes are confined to the dormant
`ValueUseTransaction` authority. The other code changes are focused tests and
source-guard tests. In particular:

```text
composed_selector_icmp.zig_sha256=8d96a4c345f47ebf3393cf04a02df7f80d048f3d06287448c04bf247472cff4c
production_icmp_changed=0
bypass_inventory_sha256=c5cf3caa4f4edfc715d8e139d736b399a4fb0b70a82b82f17af182ec88aace3e
textual_bypass_ratchet_before=216
textual_bypass_ratchet_after=216
tools_changed=0
mandatory_runner_changed=0
```

`stash@{0}` remains the untouched INBOX-93 preservation stash.

## Closed semantic action

One `ScratchCompareAction` family covers the 20 fixed-scratch matrix rows
through an internal tagged plan. Its public intent contains only:

- result identity;
- operand IR type;
- predicate and `samesign`;
- typed immediate or typed pointer null; or
- a previously registered named-RHS request handle.

It exposes no physical register, `ValueLoc`, spill slot, staging order, or
prepared-location representation. Typed null creates no request or binding.
Named operands are registered LHS then RHS; attaching a named action rejects
a reversed order, a non-prepared secondary operand, or an unregistered or
foreign handle.

The internal classifier derives the accepted RCX/R8 roles. Seal-time planning
declares RCX, R8 when used, and EAX for every action. A focused conflict proof
independently collides each of those three nodes and observes
`ValueUseConflictingDestination` before mutation.

The action-specific request form accepts only the scalar/pointer homes already
recorded by I-0: the matching GPR views, accumulator views, spill64 low views,
and the read-only low limb of an existing arg/scratch pair. It does not admit
spill128, allocate or choose a pair, expose current-home classification, or
grant a generic copy/materialization capability.

## Validation timing and lifecycle

Classification preserves the I-0 precedence:

- pointer/RHS-form, generic-width, and u16 range checks that historically
  precede staging are performed while constructing the sealed plan;
- named requests validate in legacy LHS-then-RHS order and retain distinct
  `failedRequestIs` provenance;
- ugt immediate conversion remains after LHS staging and R8 clobber;
- signed/ult i64 immediate conversion remains at the compare-definition point
  after LHS staging and accumulator preparation; and
- preparation/EFLAGS failures remain authority-level rather than being
  attributed to a request.

Execution uses one outer `ValueUseTransaction`, one outer snapshot, and one
snapshot-free subordinate accumulator session. The action stages all operands
in the accepted order, prepares the accumulator at the accepted point, emits
normalization and compare/setcc through the EFLAGS authority, defines the
result as `.zeroExtending(1)`, finalizes the subordinate session, and leaves
the sole commit to the outer authority.

The result identity used by the subordinate session is borrowed from the
transaction-owned stored action record, not an execution-local action copy.
This keeps the binding key lifetime stable through finalization and commit.

No standalone `AccumulatorDefinitionTransaction`, logical label, switch
action, pair helper, or consumer/family predicate is present.

## Focused proofs

The focused suite covers:

- all 20 internal semantic forms corresponding to the 20 I-0 fixed-scratch
  rows;
- representative exact instruction streams for named i16 normalization,
  pointer-null, immediate staging, and reversed-register unsigned compare;
- exact `.write` x4 -> `.definition` -> `.use` semantics for normalized i16,
  and `.definition` -> `.use` for ordinary forms;
- typed-null request count one, and named-RHS request count two;
- LHS-before-RHS unresolved-source precedence and distinct RHS provenance;
- early u16 range rejection without mutation;
- accepted wide-class spill low views and existing read-only pair low views;
- mandatory subordinate-session ownership; and
- exact automatic rollback after LHS staging, RHS staging, immediate staging,
  each of four normalization instructions, accumulator preparation, flags
  definition, setcc, and result finalization.

The rollback assertions restore instructions, all operand and live
accumulator bindings, result absence, virtual/spill counters, address
dependencies, EFLAGS state, and semantic-record length. The transaction is
closed exactly once after automatic rollback.

The source guard:

- rejects physical-location types in the public compare intent;
- rejects any scratch-compare action/request marker in a production consumer
  while the action is dormant; and
- continues to enforce the existing one-outer-snapshot/no-nested-accumulator
  composition contract and frozen bypass inventory.

## Validation and frozen identities

```text
full_unit=1221/1221
abi_differential=60/60 cases; 30/30 real functions; result=pass
full_unit_log=tmp/inbox111_icmp_scratch/full_unit.log
full_unit_log_sha256=d9e89b437271d9ad0ecdfe880b163dff87902da69a22a26f55e6ef24759b96cc
source_guard=current-tree-pass

fresh_report=tmp/inbox111_icmp_scratch/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type

accepted_object=tmp/inbox111_icmp_scratch/accepted.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox111_icmp_scratch/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

All six `.spill128` O2 target rows remain exactly at
`no_emitter/composed-block-icmp-lhs-loc`; target advancement is zero.

No performance run and no Tier 3 were run. INBOX-111 stops here before any
fixed-scratch ICMP production wiring.
