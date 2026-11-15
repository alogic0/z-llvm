# Collect completed work throughout development

Status: completed. The user prioritizes frequent cleanup during development.
The [result](../evidence/frequent_storage_cleanup_20261115.json) binds qualification
and storage closure records.

The managed launcher retries guarded minimal collection before starting the
next checked command. Its existing terminal collection remains. A busy or failed
cleanup is reported without replacing the command's result. The collector keeps
its current rules for active/queued readers, accepted inputs, failed work and
unreleased pipelines.

Development stages should use separate managed commands when their lifetimes
allow it. Release pipeline products immediately after their last comparison,
fault test or measurement, then collect. Diagnose failed work and retire audited
raw traces as those investigations finish. Retry deferred collection at the next
idle boundary; cycle closure is the final check rather than the first cleanup.

Evidence root:
`local-state/validations/storage-cadence-20261115/batch-01/`.
Temporary producers: the managed `qualification.storage-layout.json` workspaces
under `qualification/` and `qualification-v2/`.
Consumers: the launcher/worktree CLI regression suite and documentation checker.
Keep the terminal receipt, logs and source/tool identities. Collect the temporary
runner and compiler caches after qualification. The launcher/collector bootstrap
caches remain separately owned reusable tools, with their build locks.

Validation is focused on maintenance-launcher cadence. Compiler gates, cache
keys, code generation and collector eligibility rules are unchanged, so the
prior collector qualification remains applicable. Exercise actual collection
before the next child starts, busy/error deferral with preserved exit status,
queued input survival through its final use, source/storage owner separation,
failed-run retention and pipeline retention. Run documentation and shell/diff
checks, record storage closure, then commit.

The final implementation passed all 15 worktree/launcher CLI checks and the
documentation checker. The first attempt exposed inherited validation-only
output restrictions in the pre-run collector. Its original failure and diagnosis
remain; the corrected subprocess environment passed the regression, including
busy/error handling and queued-input survival through its last use.

Automatic terminal collection removed the successful qualification workspace.
After diagnosis and successor verification, explicit release and collection
removed the failed attempt's workspace. Both temporary roots are absent; their
combined allocated file size was 120,061,952 bytes. Maintained test evidence and
source identities remain, and no cleanup transaction is pending.
