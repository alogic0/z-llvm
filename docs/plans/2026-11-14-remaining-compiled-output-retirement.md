# Review and retire remaining compiled outputs

1. Inventory executable, object and archive paths with inode/link accounting.
   Start with the three unresolved readiness-cache groups, then validation
   compilers and test programs. Identify closed owners, current consumers,
   queued work, retained dependencies and all aliases before proposing removal.
2. Use existing native retirement adapters where possible. Extend the collector
   for demonstrated legacy layouts, with explicit evidence bindings and tests;
   preserve current contracts, independent holds, source, commands and results.
3. Qualify Debug and ReleaseFast, install the checked collector, review and
   collect eligible products through guarded transactions. Explain unresolved
   groups rather than treating missing evidence as permission to delete.
4. Remove task-owned build scratch, verify retained integrity, record the new
   inventory and exact reclamation, and commit implementation and results.

Starting inventory:
`local-state/retirements/automatic-storage-cleanup/1794649658752532842-1379413/inventory.json`.
The main checkout contains 85.085 GiB. Unresolved compiled outputs account for
21.251 GiB of executables and 3.655 GiB of objects/archives. These are review
sizes, not guaranteed savings. The preceding pass's 32.510 GiB net reduction is
not part of this task's totals.

Evidence: `local-state/storage-cleanup/compiled-products-20261114/`.

Current acceptance remains
`docs/evidence/compiler_behavior_follow_up_acceptance_20261113.json`.
The compiler agent is idle, with its compiler/self-rebuild work complete; its
accepted generations in the qualified-behavior sibling checkout remain outside
this cleanup. No new source/configuration archives are required for ordinary
closed build products; preserve existing provenance and results.
