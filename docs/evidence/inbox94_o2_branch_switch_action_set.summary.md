# INBOX-94 — O2-3B3A dormant branch/switch action sets

Status: delivered for review; B3B/B3C production wiring is not included.

## Frozen source state

The accepted production parent is `ffce32aba918602b4b5808a547bc176ad45c93a2`
(tree `5e90585c867f8a388e641f85de1b666509c8b20f`). The working branch already
contained two Supervisor documentation-only descendants; immediately before
B3A its HEAD was `fede3c2f20acff3605fcf7e4095d20e9cddc7710` and the only difference
from `ffce32ab` was `docs/next_steps.md`. No branch movement or destructive
worktree operation was used. `stash@{0}` was not inspected, applied, or
dropped.

## Separate complete matrices

The branch-condition matrix is:

```text
docs/evidence/inbox94_o2_branch_condition_api_fit_audit.tsv
sha256=387e63f94b0491ab8cd64ef2f9816fbdd8b5c70107f03ebc68159e1196aac848
```

It starts from the accepted physical-home/type/binding cross product. The
closed branch action accepts only the legacy EAX, arg32/scratch32, and spill64
test forms. A spill may carry a canonical gpr32 or wider gpr64 binding whose
defined width covers i1; wide register and RAX homes remain rejected even
though the generic narrow-view relation could otherwise interpret them. The
action emits the exact accepted test and leaves its EFLAGS definition
committed for the outer conditional branch.

The ordinary non-PHI switch matrix is:

```text
docs/evidence/inbox94_o2_switch_api_fit_audit.tsv
sha256=9855a2474181e54e063e3e23a809c9b3c5f264897e444e1cedf37d5f32f9fc34
```

It separately enumerates every accepted condition home, IR width, canonical
class, and defined-bit requirement, including the legitimate low32 views of
gpr64 registers/spills and existing gpr128 low limbs. Unsupported FP, vector,
aggregate, stack/address, and pair-spill homes remain fail-closed. Immediate
conditions are action-owned semantic intent and do not create a value binding.
The exact frexp and EI PHI-switch paths, every other PHI-edge switch, and
conditional-PHI lowering remain outside O2 under O4 ownership.

## Dormant implementation

`ValueUseTransaction` now has two closed actions:

- `branch_condition`, which owns the complete accepted test and EFLAGS
  definition;
- `switch_compare_chain`, whose maximum-eight case values, target identities,
  default identity, and optional exhaustive-case index use fixed inline-owned
  storage.

The switch source is deliberately deferred at seal. `applySwitchBoundary`
runs inside the transaction after seal and before prepare: it performs the
accepted framed CFG spill or unframed displaced-PHI restoration, then resolves
and validates the condition from canonical current state. The snapshot now
includes `phi_destinations`, so boundary restoration rolls back atomically
with instructions, bindings, spills, counters, EFLAGS, labels, and dependency
metadata.

The switch action owns the optional mask, ordered compare/conditional-branch
chain, and final jump. Target names are the already consumer-validated semantic
block identities. Their inline action copies are retained durably when emitted;
no `.label` instruction is emitted, no new logical target is generated, and
`edge_label_count` is not advanced. Rollback frees durable after-snapshot
copies exactly once. This is storage ownership, not speculative CFG-label
creation.

No production consumer contains either action tag. The source guard rejects
`.branch_condition`, `.switch_condition`, or `.switch_compare_chain` in every
composed-selector consumer file, while the frozen O2-0 bypass inventory is
unchanged.

## Frozen later ratchets

```text
docs/evidence/inbox94_o2_branch_switch_ratchets.tsv
sha256=7966618ceb7f765cffadce7b5e708ad52270fcf5d864ad8b929dd54781c84ae8
```

- B3B removes exactly the single `resolveValue` occurrence owned by
  `emitBranchCondition`.
- B3C removes exactly the single `emitValueIntoEax` occurrence in the ordinary
  non-PHI `lowerSwitch` path. The parent-owned exact PHI helpers are not
  absorbed.

## Focused and full validation

The focused transaction coverage exercises:

- exact branch EAX, argument, scratch, narrow-spill, and wide-binding spill
  streams, plus action-specific rejection of wide register homes;
- a committed branch EFLAGS definition and rollback when a live definition
  rejects the new test after spill staging;
- every accepted named switch home (EAX/RAX, 32/64-bit argument and scratch,
  both existing pair low-limb forms, and spill64), plus immediate intent;
- fixed target ownership, duplicate/capacity rejection, narrow masking,
  compare/branch order, and unsupported-home rejection;
- post-boundary resolution after a framed spill; unframed displaced-PHI
  restoration; and exact rollback of instructions, bindings, spill state,
  PHI destinations, EFLAGS records, and durable target storage.

The final unit run is `1167/1167` green
(`tmp/inbox94_b3a/full_unit.log`, SHA-256
`501595c579ee44c070920ac805959ca0022d616c119eade93d123cdb9e6729eb`). It includes the focused source-guard
negative proving that the dormant actions cannot appear in production
consumers. The build's mandatory ABI differential also remained `60/60` cases
and `30/30` real functions.

## Fresh byte identities

The post-final-code whole-cohort run used frozen input SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`:

```text
full_report=tmp/inbox94_b3a/full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted 285-row projection is unchanged:

```text
accepted_object=tmp/inbox94_b3a/accepted_cohort.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox94_b3a/selection_owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

`composed_selector_cfg.zig`, `composed_selector_memory.zig`, and the mandatory
integrated-exe runner have no B3A diff. The report proves the action set remains
dormant and baseline-byte-identical. No Tier 3 was run. Stop here for B3A
review; B3B must recapture its performance baseline at the accepted B3A tree.
