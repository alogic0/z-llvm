# Verify the remaining sibling traces

The user requested verification of the 32 streams left by the sibling storage
cleanup. Prior cleanup authorization still applies to evidence-qualified
retirement. Preserve accepted frontends, reference outcomes, unique inputs,
original diagnostics and the other agent's preopt work.

Evidence root: `local-state/validations/sibling-trace-verification-20261115/batch-01`.
Administrative review: `local-state/storage-cleanup/sibling-trace-verification-20261115`.

1. Reconcile the exact remaining paths with terminal producer receipts and
   original backend reports. Missing reports remain missing.
2. Run the existing strict `event_audit_core.zig` state machine through a
   read-only file driver. It must read/hash every byte, check metadata before
   and after, and preserve failed and interrupted outcomes. Qualify successful,
   failed, incomplete, corrupt and unterminated streams before the real audit.
3. Bind full-stream results to input bytes, producer argv/status, original tail
   counters and failure names. Verify compiler build/source evidence, including
   completed guarded retirement records for absent compilers.
4. Resolve missing bindings from retained original evidence. Keep incomplete
   or invalid streams distinct from complete audits. Any interrupted-trace
   retirement must separately satisfy the documented closed-attempt protocol.
5. Retire qualified raw data under the exclusive cleanup lock, with native
   metadata/hash guards, unchanged controls, a durable journal and explicit pin
   transitions if needed. Collect at each completed consumer boundary.

Use separate managed commands for tool qualification and full-stream auditing.
Private caches, fixture traces and auditor executables live in managed temporary
workspaces and are released when their last consumer finishes. Retain compact
audit results, source identities, original failure details and retirement
receipts. No new compiler build or performance/behavior suite is required.

## Verification and retirement result

All 32 streams were read and hashed. Twenty-nine passed the complete ordered
event audit: ten successful compilations and nineteen completed failures.
The other three are valid, newline-complete prefixes from canceled attempts,
with `profile_end` absent. Their original nonzero terminal receipts, canceled
backend commands, empty objects and diagnostics were retained. Their exact
input bytes match the accepted successor object closed by the cumulative
checkpoint and final follow-up; they receive no completed-compilation credit.

Producer and input bindings passed for all 32. Eighteen retired compiler
identities were resolved through original build receipts and guarded retirement
records; six live compiler identities were verified directly. No obsolete
compiler was rebuilt. The standalone driver reports stream validity only and
always sets `retirement_ready` to false; the separate binding and retention
review establishes eligibility.

The guarded retirement removed all 32 raw streams, recovering 20,362,543,104
allocated bytes (18.96 GiB). Native before/after snapshots verified every other
capture file unchanged. All current manifest files, holds, accepted frontend
generations and the normal ReleaseSafe reference remained unchanged. No pin
transition was needed for this batch. No raw event trace remains in the eleven
reviewed sibling roots, whose combined allocated size is now 43,988,930,560
bytes, including shared immutable input inodes.

`retirement-result.json`, `removal-journal.ndjson`, `binding-results.ndjson` and
the per-trace native audits are retained under the roots above. The two bulky
manifest lookup tables are losslessly compressed, with original and compressed
hashes in `compressed-evidence.ndjson`; decode them to their original paths
before repeating an old identity-file check. Compact audit reports and native
snapshots stay directly readable.

## Tool validation and use

Validation is focused Tier 1 for a read-only inspection tool. The unchanged
strict parser passed all nine tests in ReleaseFast. Eight CLI cases passed:
complete success, complete failure, missing end, unterminated record, corrupt
event, event after the end, symlink refusal and existing-output refusal. The
final fixture run also verified removal of its deliberate symlink so managed
collection can close normally. Formatting, project documentation and whitespace
checks passed. This changes no compiler, public compiler CLI, acceptance gate
or collector path boundary and claims no compiler capability advancement.

The reusable driver is `tools/audit_trace_stream.zig`. Build it in a managed
workspace, then invoke the retained executable with
`--input ABSOLUTE_TRACE_PATH --output FRESH_JSON_PATH`. A successful command
means a report was written: callers must inspect its `status`, completeness,
error and outcome fields. Bind producer/input provenance and review retention
separately before deleting any trace. `tools/audit_trace_stream_test.sh` accepts
the executable as its first argument and requires `ZLLVM_TEMP_ROOT`.

## Cycle closure

The qualification pipeline was explicitly released after its final CLI consumer.
All three task-owned workspaces (qualification, audit and final checks) are gone.
The final minimal collector receipt is
`local-state/retirements/automatic-storage-cleanup/1794739057153452509-3628591/report.json`.
It verified all six current integrity manifests and removed the 59,506,688-byte
qualification workspace plus one independently eligible completed peer workspace.
The separate peer removal is not included in the 18.96 GiB trace total.

Ten other workspaces were preserved: seven earlier throughput workspaces and
three ongoing preopt workspaces. The collector records their pipeline, aliased
cache or unresolved failure guards individually. They are not artifacts of this
trace review and no guard was weakened to collect them. Reusable launcher and
collector bootstrap caches retain their existing shared owners.
