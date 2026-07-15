# Currently Authorized Action

This is the sole authoritative current-action entry. Strategy documents,
roadmap checklists, historical contracts, evidence narratives, and external
discussion may rank or describe work, but they do not authorize it. An Active
worker-inbox directive controls until it is acknowledged here or in its commit;
after that, this entry controls until another explicit directive replaces it.

## INBOX-66 ABI differential harness promotion (O1 prerequisite)

| Field | Authoritative state |
| --- | --- |
| Accepted compiler-rt report | **443 selected / 285 emitting / 158 failing** (first failing `compiler_rt.trunc.truncl`, `UnsupportedLongDoubleAbi`) |
| Architecture decision | The [INBOX-57 selector/value-location/liveness ADR](evidence/inbox57_selector_value_liveness_adr.md) is **accepted with Reviewer amendments**; the [x87/fp128 ABI contract](evidence/inbox61_x87_fp128_abi_contract.md) is **accepted with Reviewer amendments**. |
| Accepted correctness repair | **INBOX-63 is accepted** (`02d375a2`): one `SelectionTransaction` authority with a comptime field-coverage guard restores instructions, `owned_labels` (speculative-only free), `entry_xmm_defined_bits`, `codegen_path`, `name`, `ret_ty` and a future owner; rolls back on unsupported and mapped-error paths; commits only on `.selected`. Byte-identical accepted objects `061a64e4`; strengthened Tier 2 24/24 + 1034/1034; one serial Tier 3 17/17. Evidence: [repair](evidence/inbox63_selection_atomicity_repair.summary), [serial Tier 3](evidence/distribution_all_after_inbox63_selection_atomicity_repair.summary). |
| Delivered O0 evidence | A distinct `SelectionOwner` enum (`unassigned`/`composed_block`/`composed_cfg`/`legacy_envelope`/`structural_fallback`), `codegen_path` unchanged, composed ownership committed through the repaired transaction only after `.selected`, legacy/fallback assigned after final lowerer success, and both atomicity negatives extended with non-default owner restoration. The separate sorted 285-row manifest is byte-identical across two runs (`5d91960e...`). |
| Superseded historical ledger | 165 / 17 / 103 (composed / legacy / fallback) was historical net-acceptance accounting, not a live route trace. It is superseded by the accepted canonical live ledger below. |
| Live topology | `composed_block=40`, `composed_cfg=127`, `legacy_envelope=17`, `structural_fallback=101`, `unassigned=0`; the four successful tags sum to 285. The aggregate live split is **167 / 17 / 101**. This fired the earlier INBOX-64 stop and was subsequently reviewed as benign. |
| Movement evidence | Seven rows from the older 120-row cohort are now composed while five of the later 165 net acceptances are structural fallback, explaining the `+2 / 0 / -2` movement without an O0 precedence change. Full row evidence: [INBOX-64 stop record](evidence/inbox64_selection_owner_stop.md). |
| Movement reviewed | The Supervisor and Reviewer reviewed the `+2/0/-2` movement and found it **benign** — a historical ledger-estimation correction, not a routing change: no precedence change, owner metadata is not emitted, manifest sorting occurs only in the manifest path (which returns before object emission), and the report stream is byte-identical to the accepted INBOX-63 report (`49a19f04`). No further row investigation is required before Tier 2. |
| Validation result | **INBOX-65 passed** at docs-only HEAD `a72ca77d` over O0 code state `6ee8bd4e`: strengthened Tier 2 24/24 steps and 1034/1034 tests; exact byte-identical 443/285/158 report with unchanged first failure; full accepted cohort 285/285/0; accepted object byte-identical at SHA-256 `061a64e4…`; manifest byte-identical at SHA-256 `5d91960e…`. Evidence: [INBOX-65 acceptance](evidence/inbox65_o0_validation_acceptance.summary). |
| Acceptance | O0 is **accepted**. **167 composed / 17 legacy / 101 fallback is the corrected canonical live owner ledger**, superseding the historical 165 / 17 / 103 estimate. |
| Only authorized action | **INBOX-66 ABI differential harness promotion** — the agreed prerequisite for O1. Promote the provisional non-gating INBOX-60 harness to a mandatory Tier-2 gate: exactly 10 audited real compiler-rt rows (2 each integer/narrow-return/pointer-memory/i128/finite-FP, both owners, stop-not-substitute); a hook-produced provenance manifest with linker-map symbol resolution (reference-substitution fails via provenance, not digest equality); a separate `abi_diff_cases_attempted/matched` + `abi_diff_real_functions_matched` schema with a versioned counter migration; the `distribution_real_rows_gate.zig:678` candidate-only success claim removed (keep 100/100/100 ratchets, `real_programs_ok=0`); a controlled ReleaseSafe panic case with termination-class matching. Keep the compiler-rt 285 and distribution 100-row populations distinct. |
| Acceptance | Exact 443/285/158 first-failure unchanged; accepted objects byte-identical (`061a64e4`); promoted harness + all negatives green in mandatory Tier 2; counter-schema migration versioned; distribution ratchets preserved; **one serial Tier 3** after a fresh headroom preflight. Any object/owner/report/route movement → stop and diagnose before Tier 3. |
| Terminal state | Stop after acceptance and request review. **O1** (scoped: 7 ordered commits, XMM query-migration, bypass closure at `scalar:561/587`+`vector:661`+`cfg:821` with a source-level guard, explicit EFLAGS def/use/preserve/clobber APIs, one serial Tier 3) **remains unauthorized until this promotion is accepted.** O2-O6, X1, and sharding remain unauthorized. |

Agreed sequence (each still needs its own directive): **INBOX-66 harness
promotion first** (this is the O1 prerequisite), then O1 accumulator-definition
transaction, then O2 ordinary GPR/pointer materialization; the x87/fp128 X1
stages proceed under serial Tier 3; preopt sharding stays deferred under the
higher parallel readiness bar and is not auto-authorized until its own fresh
preflight (and, if the ~119.9 GB observation regresses, freeing non-z_llvm disk
or a further reviewed revision).

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
