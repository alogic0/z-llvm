# Currently Authorized Action

This is the sole authoritative current-action entry. Strategy documents,
roadmap checklists, historical contracts, evidence narratives, and external
discussion may rank or describe work, but they do not authorize it. An Active
worker-inbox directive controls until it is acknowledged here or in its commit;
after that, this entry controls until another explicit directive replaces it.

## INBOX-64 O0 route-observability restart

| Field | Authoritative state |
| --- | --- |
| Accepted compiler-rt report | **443 selected / 285 emitting / 158 failing** (first failing `compiler_rt.trunc.truncl`, `UnsupportedLongDoubleAbi`) |
| Architecture decision | The [INBOX-57 selector/value-location/liveness ADR](evidence/inbox57_selector_value_liveness_adr.md) is **accepted with Reviewer amendments**; the [x87/fp128 ABI contract](evidence/inbox61_x87_fp128_abi_contract.md) is **accepted with Reviewer amendments**. |
| Accepted correctness repair | **INBOX-63 is accepted** (`02d375a2`): one `SelectionTransaction` authority with a comptime field-coverage guard restores instructions, `owned_labels` (speculative-only free), `entry_xmm_defined_bits`, `codegen_path`, `name`, `ret_ty` and a future owner; rolls back on unsupported and mapped-error paths; commits only on `.selected`. Byte-identical accepted objects `061a64e4`; strengthened Tier 2 24/24 + 1034/1034; one serial Tier 3 17/17. Evidence: [repair](evidence/inbox63_selection_atomicity_repair.summary), [serial Tier 3](evidence/distribution_all_after_inbox63_selection_atomicity_repair.summary). |
| Only authorized action | **INBOX-64 O0 route-observability restart.** A distinct `SelectionOwner` enum (`unassigned`/`composed_block`/`composed_cfg`/`legacy_envelope`/`structural_fallback`), `codegen_path` unchanged, committed through the repaired transaction only after `.selected`; a separate deterministic per-row owner manifest (twice, byte-identical) summing to 285; the two atomicity negatives extended to seed and restore a non-default owner. Strictly non-semantic: no object-byte, precedence, mandatory-summary, or ratchet change. |
| Historical ledger | 165 / 17 / 103 (composed / legacy / fallback) is **historical accounting, not an acceptance target**. If live owner counts disagree, stop and explain the movement; do not reorder precedence to force the split. |
| Headroom / gate policy | O0's accepted minimum is **strengthened Tier 2** (non-gating); a serial Tier 3 is required only if O0 changes mandatory reporting/gate behavior or shows unexpected route movement. Serial Tier 3 remains available under the [two-class policy](retention_headroom_policy.md) (serial required refined by INBOX-63 to ~53.5 GB; ~119.9 GB observed free). **Parallel sharding remains deferred and is NOT auto-authorized** (needs ~115.4 GB and its own fresh df + retention preflight). |
| Acceptance | Exact 443/285/158 with first failure unchanged, accepted-object SHA-256 still `061a64e4`, the owner manifest byte-identical across two runs summing to 285, the extended atomicity negatives, full captured cohort, permanent canaries, and the real-program boundary. |
| Terminal state | Stop after O0 delivery (or ownership-movement evidence + stop) and request review. O1, other O-slices, X1 implementation stages, harness promotion, and sharding remain unauthorized. |

Agreed sequence after O0 (each still needs its own directive): O1
accumulator-definition transaction, then O2 ordinary GPR/pointer
materialization; the ABI differential harness promotion (a separate
gate-infrastructure change) and the x87/fp128 X1 stages proceed under serial
Tier 3; preopt sharding stays deferred under the higher parallel readiness bar
and is not auto-authorized until its own fresh preflight (and, if the ~119.9 GB
observation regresses, freeing non-z_llvm disk or a further reviewed revision).

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
