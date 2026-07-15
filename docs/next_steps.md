# Currently Authorized Action

This is the sole authoritative current-action entry. Strategy documents,
roadmap checklists, historical contracts, evidence narratives, and external
discussion may rank or describe work, but they do not authorize it. An Active
worker-inbox directive controls until it is acknowledged here or in its commit;
after that, this entry controls until another explicit directive replaces it.

## INBOX-63 fail-closed selection atomicity repair

| Field | Authoritative state |
| --- | --- |
| Accepted compiler-rt report | **443 selected / 285 emitting / 158 failing** |
| Architecture decision | The [INBOX-57 selector/value-location/liveness ADR](evidence/inbox57_selector_value_liveness_adr.md) is **accepted with Reviewer amendments**; the [x87/fp128 ABI contract](evidence/inbox61_x87_fp128_abi_contract.md) is **accepted with Reviewer amendments**. |
| Correctness finding | The INBOX-62 O0 atomicity snapshot exposed a **fail-closed selection leak**: on unsupported composed speculation the wrappers restore only `instructions.items.len`, leaking `owned_labels` and `entry_xmm_defined_bits`. Evidence: [atomicity stop](evidence/inbox62_selection_atomicity_stop.md). |
| Only authorized action | **INBOX-63 fail-closed selection atomicity repair.** One transaction authority snapshots/restores instructions, `owned_labels` (speculative-only free), `entry_xmm_defined_bits`, `codegen_path`, and future owner state; rolls back on unsupported results and mapped errors; commits only on success. No `selection_owner`, owner manifest, capability admission, or row movement. |
| Headroom / gate policy | **Serial Tier 3 is available** at current headroom under the revised [two-class retention/headroom policy](retention_headroom_policy.md) (serial required ~57.7 GB vs ~90 GB free). **Parallel sharding remains deferred** (needs ~115.4 GB). |
| Acceptance | Exact 443/285/158, byte-identical accepted objects, strengthened Tier 2, and **one serial Tier 3** (repairs a confirmed shared selector correctness invariant). |
| Terminal state | Stop after the repair is accepted and request review. O0 restarts only after this repair is accepted; O1, other O-slices, X1 implementation stages, and sharding remain unauthorized. |

Agreed sequence after this repair (each still needs its own directive): O0
route observability, then O1 accumulator-definition transaction, then O2
ordinary GPR/pointer materialization; the ABI differential harness promotion
(a separate gate-infrastructure change) and the x87/fp128 X1 stages proceed
under serial Tier 3; preopt sharding stays deferred under the higher parallel
readiness bar until non-z_llvm disk is freed or a further reviewed revision.

## Current handoff and evidence

- INBOX-59 is acknowledged by this retention/reporting commit. Review and
  explicit user authorization are required before cleanup; there is no
  currently authorized successor after the commit.
- Retention deliverables: [policy](retention_headroom_policy.md),
  [cache inventory](evidence/inbox59_cache_inventory.md),
  [live pins](evidence/tmp_retention_pins.tsv), and
  [deterministic would-remove manifest](evidence/inbox59_would_remove.tsv),
  with the [report-only fixture proof](evidence/inbox59_report_only_fixture.summary).
- Accepted fma closure:
  [focused acceptance](evidence/std_debug_hello_inbox56_fma_acceptance.summary)
  and [cumulative Tier 3](evidence/distribution_all_after_inbox56_fma_acceptance.summary).
- Accepted architecture decision:
  [INBOX-57 ADR](evidence/inbox57_selector_value_liveness_adr.md).
- Durable historical progress and report topology:
  [convergence tracker](roadmap/convergence_progress.md).

Immutable gate-result evidence is historical proof and must remain byte-for-byte
unchanged during this retention/reporting cycle. No gate was run.
