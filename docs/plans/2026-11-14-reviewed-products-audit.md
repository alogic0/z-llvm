# Audit unproven storage retention and retire reviewed generated files

Status: completed, 2026-11-14. Removed **605 compiled-file paths**, reclaiming
**7.720 GiB**. Final observed `local-state`: **78.286 GiB**.

The user requested a code audit and deletion of files without evidence for
keeping them. The starting inventory is 85.978 GiB, including 64.053 GiB whose
retention or disposal is unresolved. This is not an authorization to mistake
unique source, input, diagnostic or audit data for generated scratch.

1. Audit inventory classification, producer requirements, current consumers,
   retention scanning, hardlink accounting and mutation guards.
2. Audit completed validation families against their generators and present
   consumers. Prepare an exact file/hash list of ordinary compiled products
   without an identified continuing use. Preserve existing records; do not
   fabricate original build receipts when those receipts are missing.
3. Add an explicit reviewed-product mode using the existing guarded collector.
   Permit only named ELF/archive products in validation storage. The review
   must record ownership, closure and the disposal reason. Retain holds, current
   and historical pins, active-consumer and full-alias checks. Test scope,
   changed-review/changed-file rejection, pins, holds and guarded collection.
4. Apply only the reviewed set, record per-file decisions and actual reclaimed
   bytes, verify all current contracts, inventory again, close task scratch,
   update this plan and commit.

Evidence root: `local-state/storage-cleanup/reviewed-products-20261114/`.
Qualification uses managed pipelines under an isolated owner at
`local-state/tmp/reviewed-products-build/owner/`. Its caches and executables
are temporary until installation and evidence promotion. The isolated owner
has project markers and a collector, so its completion hook cannot collect
the main project's data. Remove this task-owned bootstrap after closure.
Current compiler work and adopted baselines retain their existing contracts.

## Initial audit findings

- Inventory's unresolved category is the fallback when no configured current
  manifest, hold, or qualified retirement action classifies a path. It does
  not scan all program consumers or prove a file unused; file kinds are based
  on names and modes. It is unsuitable as an automatic deletion predicate.
- Private-cache and command-output adapters deliberately recognize specific
  producer schemas. Missing or custom historical receipts can leave ordinary
  generated executables unresolved even after their use ends.
- Current manifest verification, historical pin scanning, recorded retained
  dependencies, active consumers and complete hardlink checks already protect
  mutation. The reviewed-product mode reuses these checks, without manufacturing
  a passed producer or using an unrelated receipt as a substitute.
- A new regression exposed an existing pin-scan bug: the blanket exclusion of
  this collector's output directory also skipped an explicitly configured
  current manifest there. Current manifests now take precedence over that
  exclusion. The first qualification retains this failed regression; the
  separate changed-review test also distinguishes the metadata rejection
  (`FileChanged`) for a parsed plan from the content-hash rejection for notes.

## Reviewed payload scope

The six completed compiler-selection, compiler-object, compiler-behavior,
compiler-throughput, Fibonacci and validation-performance families contained
1,905 regular compiled files larger than 1 MiB. Actual file-type inspection
selected executables, objects and archives, rather than trusting executable bits.
A candidate-path search in current implementation and documentation found 28
files referenced by thirteen historical acceptance records; these are excluded
from this pass. Another 308 binary stdout captures and one `.missing` output
have special recorded roles and are excluded. The exact plan contains 1,568
compiled-file paths; native hold, pin, alias and consumer checks may retain more.

## Qualification and completed collection

The implementation passed **188 storage tests in Debug and ReleaseFast**. The
general CLI suite passed, including its generated-output and command-output
checks. A real dry run caught an argument-validation omission for the new
mode's explicit artifact-alias flag; the final parser fix passes reviewed-product
and root/cache CLI checks in both modes. Mutation modules remain identical to
their 188-test qualification. The installed and applied ReleaseFast collector is
`f177969d05c93ef9790083370468496be758fd805aa3815aa21c450b0792c6ab`.

Failed initial tests remain failures in the retained qualification records.
The successful full checked command and hook returned zero; its parent launcher
subsequently reported a shell parse error after being edited while blocked.
`qualification-wrapper-disposition.txt` explains this separately from the
successful checks. Final startup qualification completed normally. Qualification
records are promoted under this pass's `qualification-storage/` directory.

| Completed family | Removed paths | Allocated file bytes reclaimed |
| --- | ---: | ---: |
| Compiler throughput | 98 | 2,358,566,912 |
| Compiler selection | 51 | 1,776,488,448 |
| Compiler object/self-rebuild | 28 | 1,966,841,856 |
| Compiler behavior | 428 | 2,187,452,416 |
| Total | **605** | **8,289,349,632** |

Collection completed in
`local-state/retirements/automatic-storage-cleanup/1794687918866455299-2302228/report.json`.
The [tracked result](../evidence/reviewed_products_cleanup_20261114.json) binds the
review, receipt, final inventory and verification. No policy, hold or historical
pin exception was added. The 963 retained candidates have per-path reasons in
the receipt and `retained-decisions.ndjson`; these include current manifests,
historical retirement evidence, manual holds and incomplete hardlink groups.

All six current manifests and four accepted external artifacts passed final
verification. All 605 removed paths are absent, all 963 retained candidate
hashes match, and all 517 manual holds and the policy are unchanged. Original
throughput acceptance and seals are unchanged. No pending transaction remains.

The task's four qualification workspaces were collected (440,168,448 bytes).
After verified evidence promotion, its remaining bootstrap files were removed
(117,841,920 bytes). These 558,010,368 task-created bytes are excluded from
existing-payload savings. `local-state/tmp/reviewed-products-build` is absent.

The final inventory is
`local-state/retirements/automatic-storage-cleanup/1794688188340970878-2306664/inventory.json`:
84,059,295,744 allocated bytes, 1,758,934 paths and 1,749,735 unique inodes.
The footprint decreased 8,259,178,496 bytes (7.692 GiB) from the starting
inventory; new audit records account for 30,171,136 bytes of the difference
from gross reclamation. It classifies 21.925 GiB under current contracts and
56.361 GiB unresolved. Its inventory-only integrity flag is false because no
deletion candidates required checking in that command; the independent final
verification and completed collection both verified the current contracts.

This audit does not establish that the remaining unresolved inputs, records,
logs, sources or smaller products are unnecessary. Their purposes and any
historical retention transitions remain separate review work; the explicit
reviewed-file mode does not turn missing evidence into automatic deletion.
