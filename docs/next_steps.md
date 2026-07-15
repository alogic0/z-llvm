# Currently Authorized Action

This is the sole authoritative current-action entry. Strategy documents,
roadmap checklists, historical contracts, evidence narratives, and external
discussion may rank or describe work, but they do not authorize it. An Active
worker-inbox directive controls until it is acknowledged here or in its commit;
after that, this entry controls until another explicit directive replaces it.

## INBOX-58 documentation compaction

| Field | Authoritative state |
| --- | --- |
| Accepted compiler-rt report | **443 selected / 285 emitting / 158 failing** |
| Architecture decision | The [INBOX-57 selector/value-location/liveness ADR](evidence/inbox57_selector_value_liveness_adr.md) is **accepted with Reviewer amendments**. |
| Proposed selector slices | **O0-O6 and X1 are proposed and unauthorized.** No slice may begin from the ADR or roadmap alone. |
| Historical selector ledger | **165 composed / 17 legacy / 103 fallback** is historical acceptance accounting, pending O0 measurement. It is not the live route topology and must not drive implementation. |
| Only authorized action | **INBOX-58 documentation compaction through this commit.** It permits documentation/tooling edits only; no selector, test, fixture, or gate change and no gate run. |
| Terminal state | Stop after the compaction and request review. No successor becomes authorized automatically. |

The post-compaction sequence remains an agreed sequence, not permission to
start it: retention limits plus disk-headroom controls, then bounded preopt
sharding, then the minimal ABI differential harness. The ABI harness must exist
before O1 can be considered. O0 also remains a proposed prerequisite under the
accepted ADR. Retention, sharding, the ABI harness, O0-O6, X1, and every later
checkpoint step require a new explicit directive.

## Current handoff and evidence

- INBOX-58 is acknowledged by this compaction commit. Review is requested;
  there is no currently authorized successor after the commit.
- Accepted fma closure:
  [focused acceptance](evidence/std_debug_hello_inbox56_fma_acceptance.summary)
  and [cumulative Tier 3](evidence/distribution_all_after_inbox56_fma_acceptance.summary).
- Accepted architecture decision:
  [INBOX-57 ADR](evidence/inbox57_selector_value_liveness_adr.md).
- Durable historical progress and report topology:
  [convergence tracker](roadmap/convergence_progress.md).

Immutable gate-result evidence is historical proof and must remain byte-for-byte
unchanged during this compaction. No gate was run.
