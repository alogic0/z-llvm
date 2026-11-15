# Local storage: retained purposes and release conditions

This records the continued November 14–15 storage review. The working plan is
[resolve remaining storage](../plans/2026-11-14-resolve-remaining-storage.md).
The audit records live under
`local-state/storage-cleanup/resolve-all-20261114/`.

The user requested preservation of results, commands and identities while
retiring superseded generated products. They subsequently clarified that old
ordinary binaries and objects need no new source/configuration archive.
Current accepted inputs, original evidence, source edits and explicitly retained
replay dependencies have separate lifetimes.

## What stays, and why

| File family | Consumer or retention basis | Release condition |
| --- | --- | --- |
| Three accepted AIR exports and adopted LLVM inputs | Six current checksum contracts bind the accepted comparison inputs. The selection contract now lists maintained inputs/results separately from completed generated controls. | A verified accepted successor or retirement of the corresponding comparison. |
| Original captured LLVM inputs | Invocation records identify the bytes compiled. Full event audits and interruption dispositions bind particular inputs by hash; `storage_cleanup/reviewed_records.zig` rechecks them. Other captures preserve the input side of the original comparison results. | Close that reproduction/evidence contract, or provide a verified archive transition supported by its readers. |
| Original reports, profiles, object contracts, command ledgers and diagnostics | These preserve the requested outcomes and failure explanations. Event auditors, object auditing and retirement verification read the bound records. Repeated immutable content is shared; selected expanded diagnostics are archived losslessly. | A reviewed evidence successor or archive transition that preserves any direct reader dependencies. |
| Saved case sources, provider overrides and source worktrees | Saved cases reproduce the recorded comparisons. Thirty of 32 registered worktrees contain changes. The two clean Fibonacci checkouts also contain ignored experiment inputs/results. The crash-investigation draft remains preserved. Ordinary generated outputs were retired separately and Git status was checked before and after. | Preserve or commit unique edits, and migrate any original-path input/result consumers before retiring a source checkout. |
| Seven current throughput workspaces | Three compiler workspaces and four object workspaces retain the current throughput audit/replay contract. `tools/audit_captured_object.zig` checks the recorded backend identity, captured input, profile, ownership, census and actual object. | A verified replacement audit/object contract, followed by explicit workspace release. |
| Small ABI object fixtures in the artifact store | The maintained `project-improvement-abi-20260910` manifest names these fixtures. Two object hashes also occurred in old Fibonacci worktree outputs; their separate canonical store objects were verified and retained while the duplicate worktree products were removed. | Replace or retire the corresponding ABI fixture contract. |
| Seventeen explicit holds | Eight validation symlinks and three worktree symlinks refer to other storage owners. The remaining holds cover two census inputs, an adopted compiler-input root, a captured input root, and the alternate source/emitter pair. | The owning consumer closes or replaces its specific dependency. |
| Small raw-event fixtures | Deliberate verifier fixtures and the bounded diagnostic sample exercise complete, incomplete and invalid event streams. Large production streams have separate complete-audit or interrupted-prefix dispositions. | Replace or remove the corresponding verifier fixture. |
| Per-file retirement proofs and applied plans | `storage_cleanup/retired_compiler.zig` and related verification read exact records, source/build evidence and identity chains. These also preserve the requested deletion audit. Referenced records remain at their original paths. | Replace the reader contract before moving or compacting a directly referenced proof. |
| Canonical artifact-store objects | Maintained manifests and surviving immutable names use these bytes. Store verification checks their complete hashes. Sharing preserves every selected name and byte. | No remaining manifest or maintained-name consumer, with complete alias ownership established. |
| Installed cleanup/audit tools and the managed launcher | These are the current tools used to inspect and maintain storage. Their installed ReleaseFast identities and qualifications are recorded. Idle build caches and obsolete qualification copies were removed. | Replacement of the installed tool; ordinary build caches can be regenerated when needed. |

The remaining source/evidence/replay contracts determine this retained set.
Further reductions can archive additional historical evidence after updating
its readers. A potential reader accepting an arbitrary path does not by itself
make every old generated product permanent.

For example, `worker-frame-export-0-v243-run.log` is a 67 MB allocator-leak
diagnostic named by the original canceled-run receipt (`returncode: -15`). It
stays at that direct diagnostic path; inventory summaries also mention it, but
those summaries alone would not require retaining an expanded copy.

## Resolved retention mistakes

- Closed 498 obsolete run holds and 26 broad legacy directory holds after review.
- Replaced current mixed manifests with verified successors, preserving every
  unselected entry and the original manifests. The final generated-control
  transition removed exactly 42 temporary-output entries and kept 31,698 entries.
- Closed exact historical references instead of changing their original hashes
  or treating the first reported pin as the only pin.
- Completed hardlink ownership reviews, including unreferenced canonical store
  names and the additional Debug compiler alias.
- Retired all 160 reviewed private-cache candidates, including copied caches,
  failed-build caches and older layouts. Original failures remain failures.
- Removed 112 generated assembly files and 21 structurally verified partial
  link controls through the qualified collector. Three additional expanded
  assembly/disassembly views were preserved in verified gzip archives.
- Individually reviewed 49 further partial compiler/link products. Forty-one
  have exact terminal failed-link commands and undefined-symbol diagnostics;
  two prototype fragments have failure diagnostics and timing receipts. Six
  abandoned compiler/census products have compiled bodies and zeroed headers.
  Missing original build receipts for three of those six are recorded honestly.
- Removed 687 ignored Fibonacci worktree products, seven idle cache roots and an
  obsolete qualification tool copy. Source worktree status and independent
  canonical ABI fixture objects were preserved.
- Shared repeated immutable inputs, results, saved case sources and diagnostics.
  Explicit alternate-source and cleanup-evidence holds remain effective.
- Replaced six obsolete full filesystem/reference survey payloads with a current
  compressed per-path metadata index. Original summaries, decisions, selected
  review lists and historical checksum files remain. Separate retirement notices
  explain the missing superseded payloads without rewriting old observations.

## Qualification and evidence handling

The final collector passed 230 unit tests in both Debug and ReleaseFast. Its
qualification records bind unchanged source inventories to the installed binary.
That final installed ReleaseFast binary also passed both complete CLI suites
and documentation checks, with identical source and binary identities before
and after the run.
The event auditor and interrupted-stream diagnosis tool have their own tests and
source/binary identities. Real collections recheck current contracts, original
proofs, holds, live consumers and complete inode ownership before mutation.

An administrative disposition records the exact files, review, hashes, metadata,
consumer/hold checks, retained dependencies and durable removal journal. It does
not make a broad automatic exception for unrecognized binary formats or missing
receipts. In particular, the native partial-link recognizer remains narrow.

Lossless compaction records both the original and compressed SHA-256 and verifies
the complete decompressed contents before removing an expanded name. The
`archives.ndjson` ledgers under the audit root map original paths to archives.
Applied plans, required source identities and referenced per-file proofs retain
their directly readable paths.

Task-owned qualification reports are promoted with byte comparison before their
workspaces and bootstrap caches are collected. The audit's own preparatory
tables and unreferenced aggregate views are compacted after their consumers
finish.

The final small-evidence pass preserved 285,274 paths and reclaimed
3,098,243,072 allocated bytes. It shared 282,199 paths; 3,075 stayed under their
specific source/input or historical audit holds. All selected paths and every
retained byte remain accounted for by the applied plans and archive ledgers.

## Reading the inventory

Native allocation accounting counts each physical inode once and gives current
contracts precedence across aliases. It includes directory allocation and avoids
following external symlinks. Logical lengths, pathname counts and allocated
bytes are different quantities.

The native inventory recognizes current manifests, explicit holds and qualified
collector candidates. Its `unresolved` category also includes historical source
and result evidence described above, and the collector's own audit records.
The final result preserves that raw classification rather than changing it to
claim that every retained byte has a native current-manifest entry. This purpose
ledger records the additional reviewed retention basis and release conditions.
