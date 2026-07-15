# Currently Authorized Action

This is the sole authoritative current-action entry. Strategy documents,
roadmap checklists, historical contracts, evidence narratives, and external
discussion may rank or describe work, but they do not authorize it. An Active
worker-inbox directive controls until it is acknowledged here or in its commit;
after that, this entry controls until another explicit directive replaces it.

## INBOX-59 retention and headroom controls

| Field | Authoritative state |
| --- | --- |
| Accepted compiler-rt report | **443 selected / 285 emitting / 158 failing** |
| Architecture decision | The [INBOX-57 selector/value-location/liveness ADR](evidence/inbox57_selector_value_liveness_adr.md) is **accepted with Reviewer amendments**. |
| Proposed selector slices | **O0-O6 and X1 are proposed and unauthorized.** No slice may begin from the ADR or roadmap alone. |
| Historical selector ledger | **165 composed / 17 legacy / 103 fallback** is historical acceptance accounting, pending O0 measurement. It is not the live route topology and must not drive implementation. |
| Only authorized action | **INBOX-59 non-destructive retention inventory, policy, reporter, and report-only fixture through this commit.** No deletion, rename, rotation, pruning, sharding, or Tier 2/Tier 3/distribution gate is authorized. |
| Cleanup state | **Unauthorized.** The would-remove manifest is a proposal only and requires explicit user authorization before any cleanup. |
| Headroom state | **Not ready for sharding.** Current and projected post-cleanup free space do not satisfy the ten-percent floor plus the conservative 16 GiB peak. |
| Terminal state | Stop after the report-only deliverables and request review plus explicit user authorization before cleanup. No successor becomes authorized automatically. |

The post-compaction sequence remains an agreed sequence, not permission to
start it: retention limits plus disk-headroom controls, then bounded preopt
sharding, then the minimal ABI differential harness. The ABI harness must exist
before O1 can be considered. O0 also remains a proposed prerequisite under the
accepted ADR. Retention, sharding, the ABI harness, O0-O6, X1, and every later
checkpoint step require a new explicit directive.

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
