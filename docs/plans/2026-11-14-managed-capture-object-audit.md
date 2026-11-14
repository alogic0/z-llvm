# Restore object audits for managed behavior captures

Status: complete; fixes the review finding in `95700e10`.

Managed behavior runs now keep `local.o` in their temporary workspace, while
the independent object auditor still reconstructs the legacy evidence path.
The review reproduced a successful real capture followed by `FileNotFound`;
identical bytes at the old path made the audit pass.

1. Resolve objects through the existing validated workspace layout, preserving
   legacy captures without a layout. Hold the storage reader lease throughout
   the audit. Preserve capture binding, command, input, ownership, census and ELF
   checks; never fall back to an evidence copy when a managed object is missing.
2. Extend the isolated behavior CLI coverage with a successful real capture-to-
   audit path, a legacy local capture, and the missing-managed-object/stale-copy
   rejection. Run the existing auditor units and these CLI checks in Debug and
   ReleaseFast. Compiler code, gate/cache producers and acceptance populations
   are unchanged; validation is focused on this read-only audit consumer.
3. Document path selection, record results and storage closure, then commit only
   this fix. Preserve the concurrent storage-minimization changes.

## Qualification

Focused Tier 1 covers the independent audit consumer and its storage contract;
compiler behavior, production gate/cache producers and accepted populations do
not change. All commands used `tools/run-validation --command` with the pinned
Zig 0.17.0 compiler and a frozen parent checkout plus this patch.

- With the original auditor, the new real capture-to-audit regression fails
  with `FileNotFound` after a successful managed capture.
- `test-behavior-storage` passes in Debug and ReleaseFast: 11 CLI checks and
  4 filtered object-audit unit tests per mode. The cases include successful
  managed and legacy captures, missing managed objects despite a valid evidence
  copy, and the existing retention/release checks. The frontend and source pin
  are protocol fixtures; this is not full upstream behavior-suite acceptance.
- Zig formatting, shell syntax, whitespace and documentation checks pass. The
  documentation checker validates 24 documents, 514 links and 2 status blocks.

The evidence root's `results/` directory preserves command receipts and logs;
`source.patch` records the tested code. `qualification-evidence.tar.gz` archives
the isolated owner's layouts, jobs and collection receipts without introducing
foreign layouts into the main collector's live evidence tree.

All four checked-command workspaces were collected, reclaiming 1,133,031,424
allocated file bytes. The isolated storage owner and task-specific bootstrap
caches were removed after archiving. `storage-collection.log` records the final
empty collection; `bootstrap-accounting.txt` and `storage-disposition.txt` record
the remaining task-owned storage closure. The detached checkout is retained
only through this fix's commit, with removal recorded in the disposition note.

## Storage

Evidence and run notes live under
`local-state/validations/managed-capture-audit-fix-20261114/batch-01/`.
Managed checked commands own private caches and test binaries in the isolated
storage owner `/tmp/zllvm-capture-audit-fix-YPuokR5M`. This avoids contention
with the concurrent main-storage collector. Archive compact receipts and logs
back into the evidence root, then remove this task-owned storage owner and its
bootstrap caches after qualification. The first main-storage admission was
cancelled while waiting for its lease; no test or workspace began there. A detached
task-owned checkout at `local-state/worktrees/managed-capture-audit-fix-20261114`
freezes the parent revision plus this patch for testing while other files change
in the shared checkout. Remove it after the tested patch is committed.
CLI fixtures are isolated `/tmp/zllvm-behavior-storage-cli-*` projects; their
collector releases the test capture pipeline after all audit consumers finish,
then the harness removes the fixture. Maintain only commands, terminal logs,
patch/provenance and a compact result summary. No temporary binary/object is an
adopted baseline or retention pin. Close this cycle's pipelines and collect its
scratch at completion; existing accepted files and independent holds stay intact.
