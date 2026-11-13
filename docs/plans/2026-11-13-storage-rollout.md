# Complete the storage separation rollout

Continue the [separation plan](2026-11-13-storage-separation.md):

1. Move C/native, input-program and integrated validation products into owned
   temporary workspaces. Keep reports, commands, logs, generated inputs, profiles
   and unresolved traces in their maintained evidence directories. Binary stdout
   is a product too; do not retain a second copy with a `.stdout` extension.
2. Keep fresh compiler installations and their private caches in temporary
   storage. Maintain a compatible executable alias and build receipt. A compiler
   installation remains a pipeline dependency after a successful build, until
   its owner explicitly releases it. Existing mixed installations stay readable.
3. Provide a reviewed release command for terminal failed validations and closed
   compiler pipelines. Bind it to the original layout, result and diagnostics.
   Preserve the original outcome. Apply holds, active-reader, pin, raw-trace,
   snapshot and quarantine checks before any deletion.
4. Exercise the actual copied-project launch pattern and provide a launcher that
   compiles the current tools. Do not modify the other agent's running frozen
   checkout or replace its active cached executable. Record explicit cache
   overrides and adoption gaps accurately.
5. Inventory current storage, review stale holds against terminal receipts and
   current consumers, collect only verified obsolete products, and record tests,
   exact reclaimed bytes and remaining limitations here.

## Initial inventory and workflow review

The inventory at
`local-state/retirements/automatic-storage-cleanup/1794599882072584487-156930/inventory.json`
contains 1,776,762 paths. Its current-contract bucket is 52,400,119,808 allocated
bytes; unresolved storage is 91,053,084,672 bytes; eligible storage was zero.
An unresolved classification does not mean the file is required.

The other agent's native validation was using `run_checked` from
`local-state/caches/behavior-tools-v1038` and `run_native_canary.zig` from the
frozen `z_llvm-validation-tail-fixed-v1132` checkout. Its explicit local/global
cache arguments also bypass the new defaults. Those live jobs continue with
their existing paths. `tools/run-validation` is the current-source entry point
for subsequent runs, including copied projects with their own test fixtures.

## Qualification

- All 124 collector tests passed in Debug and ReleaseFast, including alias-pin
  protection and refusal to overwrite unresolved compiler failure diagnostics.
- All 50 validation-policy tests, 23 collector CLI checks, six lifecycle/input
  CLI checks and eight workspace CLI checks passed.
- The native module-dependencies smoke passed, including separate binary stdout,
  maintained object contracts and diagnostics. A copied wide-saturation project
  passed 61,440 local observations, 30,720 reference observations and nine fault
  controls. A separate reader resolved the same temporary executables and matched
  the original fault results. The current-source launcher repeated that run.
- Four native-comparison tests passed, including old/new path normalization with
  a changed-command negative control. `--retain-products` keeps C/native products
  available for later comparisons under the explicit pipeline release protocol.
- The compiler helper built and rebuilt a small real Zig fixture, executed its
  maintained alias and preserved the original receipt byte for byte. Its pipeline
  workspace stayed retained after success.
- An intentional invalid-argument integrated run kept its failed status and
  temporary workspace. Its forwarded stdout/stderr matched the maintained streams
  byte for byte, so existing summary parsers can keep using the command's output.
- The integrated run passed five selected ReleaseFast executable cases,
  behavioral and memory comparisons, 21 execution-breadth function-modes,
  seven unchanged Zig programs across three modes, and the JSON input program.
  The latter matched 138 inputs and passed 552 negative controls.

The integrated run then failed in the C/native population: another agent added
pointer fixtures while the run was using the earlier `proper-wide-vector` v1335
compiler. That compiler rejected `pointer_order_probe_40` with
`UnsupportedCodegenInstruction`. The original failed report, command, stderr
and retained workspace document that outcome; it is not a full-suite pass.

A C/native replay uses frozen fixture revision
`d6055bd692b7559740493653ff5ac629a3648ecb` and the validated
`proper-short-identity-ReleaseFast-v1372` compiler, SHA-256
`73bf41bee174eceee3e68e76ac8b3e97dd673d73958b6b26f0dd347869a18245`.
That replay passed all 223 native populations in ReleaseFast, completing 2,712
commands. The three new populations passed 81,920 pointer-order, 24,576 register
snapshot and 27,648 bounded-local observations. This narrower replay resolves
the original compiler/fixture mismatch; it does not relabel the earlier parent
integrated run as passed. Its evidence is under
`local-state/validations/storage-rollout-20261113/smokes/frozen-c/evidence/native/`.

A manifest of all 15,981 maintained regular files was recorded before releasing
the completed smoke pipelines and resolved failures. The compiler alias is a
symlink to a disposable product and is deliberately excluded from that manifest.
All six explicit releases were published successfully; an intervening hold
update caused one safe publication retry. The original results stayed unchanged.

The installed collector is a Zig 0.17.0 ReleaseFast build with SHA-256
`0b0c77768eb3df667d4ce391417b8c53a1659e21ba6f62b7877baccfb7f0baec`.
The rollout's separate build scratch was removed after its processes finished,
freeing 533,508,096 allocated tree bytes. The installed collector's hash was
checked before and after that removal.

## Historical hold review

Nine older copied unit-test groups have 18 successful terminal receipts and
logs. Their Debug/ReleaseSafe cache directories are private to those completed
tests; current jobs use newer test groups. The reviewed list and hash-bound
evidence are in `local-state/storage-cleanup/rollout-implementation/`.
The failed `behavior-complete-units-v1161` group was excluded from this release.
Live shared caches, current compilers, source trees, test logs and raw traces
remain outside this cleanup request.

The first apply removed 43 groups and reclaimed 5,916,708,864 allocated file
bytes, then stopped with `FileChanged` when the other agent updated
`local-state/storage-cleanup/holds.json`. A checksum check of every recorded
control found only that hold file changed. No pending deletion journal remained.
The seven remaining private caches were collected using a fresh control snapshot
in the final apply. The original review and partial removal records remain in
`local-state/retirements/automatic-storage-cleanup/1794603657993437381-252069/`.

## Final collection and inventory

The final apply completed successfully in
`local-state/retirements/automatic-storage-cleanup/1794606093421052224-305068/`.
Across the two applies:

| Removed products | Groups | Allocated file bytes |
| --- | ---: | ---: |
| Reviewed historical unit-test caches | 36 | 5,387,407,360 |
| Completed or explicitly released test workspaces | 21 | 2,564,431,872 |
| Total collected | 57 | 7,951,839,232 |

Including the separate 533,508,096-byte build scratch, reclamation was about
**7.903 GiB**, of which **5.017 GiB** was historical cache storage. The scratch
measurement includes directory allocation; collector totals count file allocation.
All 15,981 original maintained files, all 36 reviewed historical receipt/log
hashes and the compiler receipt still match. The final apply verified all five
required integrity manifests. There is no pending deletion journal.

The final read-only inventory is
`local-state/retirements/automatic-storage-cleanup/1794606615878187298-313806/inventory.json`.
It observed 1,796,069 paths and 135.444 GiB of file allocation: 49.900 GiB covered
by current holds/contracts, 85.545 GiB unresolved, and zero automatically eligible
bytes. It is an observation, not a second integrity certification; the preceding
successful apply performed that verification. `du` measured 146,085,388,288 bytes
for the whole tree, including directory allocation. Other validation continued
writing throughout this work, so the whole-tree before/after difference is not
the amount reclaimed.

Zero eligible bytes does not establish that all remaining data is needed. The
unresolved inventory still includes 31,785,385,984 bytes of executables and
10,180,812,800 bytes of raw traces. These families need their own consumer and
diagnostic reviews. The held `behavior-tools-v1038` cache alone contains
14,304,333,824 bytes of executables and continued growing under frozen/cached
invocations. Subsequent jobs should use the current-source launcher and omit
legacy shared-cache overrides when they want the workspace defaults. Existing
running jobs were not redirected.

The machine-readable result is
`local-state/storage-cleanup/rollout-implementation/summary.json`.

## Operational limitation

The first collection spent roughly 40 seconds per temporary workspace on this
large tree. The collector refreshes global pins before each action and again
after quarantining a workspace. It retains these checks, including detection of
changed aliases. Batching independent workspace mutations without weakening the
before-deletion checks is a possible later performance improvement; this rollout
does not alter that safety protocol.
