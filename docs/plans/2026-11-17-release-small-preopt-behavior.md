# ReleaseSmall behavior through the local preopt pipeline

Date: 2026-11-17
The full Small run, audits, cumulative integration and final source verification
passed. All 63 owned workspace roots are closed. Independent milestone review
accepted M1 at `a27b8e86` on 2026-11-17. Starting tracked baseline
`435ba95c`, compiler source `c32ba3cf`. Canonical sequencing and review gates are
in the [coordination plan](2026-11-17-preopt-qualification-performance-self-rebuild.md).

Qualify the unchanged pinned upstream behavior suite through the LOCAL optimizer
and object emitter in one complete unchanged final-candidate run. Match all
2,097 named ordered LLVM ReleaseSmall outcomes, including skips. Select
`ZLLVM_ZIG_MODE=ReleaseSmall` / `zig-release-small-accepted`. Compiler-rt frontend
policy also changes to Small: separately discover, inventory and census runtime
and test populations; never import Fast/Safe module or definition counts.

Use the [Safe plan](2026-11-14-release-safe-preopt-behavior.md) and
[Fast acceptance](../evidence/release_fast_preopt_acceptance_20261117.md) as the
acceptance framework. LLVM construction, bitcode parsing, target/analysis/pass
manager setup and declared providers remain dependencies, with no LLVM optimizer
or emitter execution or fallback credit. M2 measurement, M3 compiler builds,
scheduler work, performance parity and IR-construction removal are outside M1.

## Baseline admission

Generation-1 frontend remains
`/home/oleg/prog/z_llvm-validation-qualified-behavior-v1461/local-state/isolated-validations-qualified-behavior-v1461/whole-qualified-normal-v1490/install/bin/zig`,
SHA-256 `972160f222580c039d2e3244983c0aa13b16957ed56548c6153fb46af896bf8b`.
Upstream `/home/oleg/prog/ziglang` stays at clean pin
`1c08b09d1c847f4f02c8216e3b62df323861a437`; `test/behavior.zig` hashes to
`3ef0e65cb6a9bb8a112549d0d8a52ded81cf4b154bd1f059c4dd878e38098af6`.
Libc configuration remains
`local-state/validations/compiler-object-completion-20261111/batch-01/native-libc-link-v8/native-libc.txt`,
SHA-256 `76ec8b788d551b0beed8f7359fd5ded95086f4a758b4bf2e07dfe31b2afdd34f`.

Original normal LLVM Small reference is
`final-generation1-llvm-v1549/ReleaseSmall/report.json` under the qualified root,
SHA-256 `9fe0c436e40e5edc77bde977d028dd4f22f00209f6eeb8e5a37d60796881dc53`.
Current-provider normal Small reference is
`local-state/validations/release-safe-preopt-20261115/batch-01/preserve-reference-ReleaseSmall/run/report.json`,
SHA-256 `61021ed755222a295ef4d6bbf683e0a7b60bedd08277934261f1cbaf2ec0ad21`.
It records 2,063 OK and 34 SKIP. Revalidate complete ordered outcomes, frontend,
source/suite/library, libc configuration, all providers and target/CPU/link
settings. Refresh that normal LLVM reference if a relevant identity changed,
preserving original ancestry and explaining any outcome difference. Do not
rebuild or clone the accepted frontend for admission.

Use x86_64-linux-gnu, baseline CPU, the pinned upstream library and normal
resources. Build the backend executable in ReleaseFast, with recorded SDK/library,
source, target, strip and frame-pointer identities; its build mode is separate
from the Small hook/workload policy. Freeze all scripts before launch.

## Required execution and evidence

1. A: Verify baseline/reference/providers, storage contracts/holds, resources,
   source membership and byte identities. Close checking scratch immediately.
2. B: Build the candidate and existing runner/inventory/census/auditors through
   managed pipelines. Qualify runner contracts in Debug/Fast, including Small
   mode selection, stage pairing, measured admission and failure handling.
   Close private build/test scratch while keeping declared executable consumers.
3. C/D: Capture each complete actual input, including failed attempts, and
   independently inventory definitions, declarations, globals and aliases.
   Distinguish capture, optimizer success, complete object delivery and audits.
   Unknown later populations remain not yet captured, without invented counts.
   Reduce demonstrated blockers, retain original failed receipts and qualify
   fixes with meaningful focused/native/negative checks and required tiers.
   Release diagnosed failed scratch as soon as its consumers close.
4. E: Run the full unfiltered suite on one unchanged candidate with initially
   absent evidence/run roots and fresh private frontend local/global caches.
   Require all 2,097 ordered outcomes, no stitched success and fresh backend,
   object, linking and execution evidence. Reconcile every actual optimizer and
   emitter directory, separate runtime/test inventories and complete censuses.
   Bind each optimizer output to its emitter input by exact hash, size and path.
   Independently audit every complete object, owner/ELF output and full ordered
   event stream, including producer/report/input identity, all counters, balanced
   scopes, failures and stream termination. Sampling earns no completeness credit.
5. F: Repeat a real optimizer-failure control using the actual final candidate:
   failed compile, no successful optimizer delivery, zero emitter/object/behavior
   execution and no LLVM fallback. Preserve original failure. Separately prove
   LLVM construction versus pass execution from the pinned source and commands.
   Revalidate Safe/Fast/postopt proof contracts and fixed/native preservation.
   Apply validation_tiers.md: reuse unchanged qualified evidence only with exact
   source, executable, SDK/library, target, mode, corpus, arguments and expected
   contract binding. In particular the existing full 17-gate/237-population run
   may be reused if all relevant identities match; otherwise run the affected
   checks and required cumulative Tier 3. Label reuse explicitly, not as fresh.
6. G: Bind final source/reference/provider identities, record fresh versus reused
   results and remaining LLVM dependencies, close all owned consumers, collect,
   publish selected maintained evidence and commit. Freeze source and send the
   review-ready handoff. Stop M2 until the reviewer explicitly authorizes it.

Every optimizer/emitter input uses verified file bytes plus one with checked
arithmetic, replacing the hook's 64 MiB argument in effective argv. Optimized
inputs are measured independently. Keep public defaults and ABI/frame bounds.
LLVM verification may validate retained IR separately, with no delivery credit.
No stubs, test filtering, missing populations, output substitution or fallback.

## Ownership, storage and resource admission

Evidence root: `local-state/validations/release-small-preopt-20261117/batch-01/`.
Primary agent owns M1 plan, scripts, implementation, validation and cleanup.
Write retention.md before each producer. Use tools/run-validation, including
--command for scripts; generated products go under ZLLVM_TEMP_ROOT and selected
evidence under ZLLVM_RUN_ROOT. No milestone-long outer lease.

Execution update: the outer setup session returned 143 while its original SDK
build continued. The monitor receipt remains unfinalized; a separate managed
candidate admission binds the actual completed child build without a duplicate
build or an invented monitor exit. Original receipts and diagnosis remain.
Candidate `995d5d9d` has the same complete compiler source, SDK/library and build
flags as Fast candidate `87ab3a8e`, but different executable bytes. Therefore
the executable-identity reuse condition is not met: run fresh fixed Debug,
60-case ABI, 27-executable preservation and full serial 17-gate/237-population
integration. The planned adoption helper is unused and earns no execution credit.
Drive subsequent managed stages separately and preserve original failures.

The unchanged complete Small run matches all 2,097 ordered reference outcomes
(2,063 OK and 34 SKIP). Independent runtime/test inventories find 903 and 6,684
definitions. Exact stage pairing, measured input admission, complete censuses,
objects/owners/ELF and all 2,943,342 ordered-event records pass. The first copied
fault matcher recognized Fast only; its child actually succeeded and enclosing
checker actually failed. It earns no failure-control credit; both extra objects
were independently audited. A new Small-qualified matcher passes six dispatch
checks and the real final-candidate optimizer failure: one failed optimizer,
zero emitters, objects or behavior execution. Fresh fixed Debug object equality,
60 ABI cases, 27 executable checks, 17 integration gates and 237 native
populations passed. Final verification rechecked the 679 compiler sources,
the complete SDK library, reference and providers before closing their consumers.

The separate [interrupted-workspace recovery work](2026-11-17-interrupted-workspace-recovery.md)
preserves the original unknown producer outcome. The reviewer approved the
exact ten-file recovery patch and its Debug/Fast qualification after four
findings were fixed. The first native dry review removed zero. The successor
plan kept historical snapshots for the live policy, holds and independent
release records. The separately authorized apply returned zero and reclaimed
265,383,936 bytes from one workspace. Its final action record retained the
reviewed 25 paths. The original layout, receipt and job verified after removal.

Temporary producers: candidate/compiler build caches, five auditor/runner/tool
executables, separate private tool-build/test scratch, full-suite caches/objects/
executable, negative-control scratch and any demonstrated repair checks.
Candidate/tools live through capture, audits, controls and final identity checks;
full-run objects live through independent object/census/ELF audits and inventory
reconciliation. Retain only a predecessor with an actual comparison consumer.
Release immediately after the last consumer, collect at every boundary and retry
idle deferrals. Retained binaries/objects are identities, not new acceptance pins.

Maintained exceptions: unique raw/optimized IR, original failed receipts and
reduced reproducers, command/source/provider/reference identities, complete
inventories/censuses/audits, owners/profiles and final compact reports. Raw event
streams stay maintained until strict audits and an explicit supported retirement.
Reuse immutable artifact sharing when appropriate. Never alter an old seal,
accepted object/input, independent hold or separately owned consumer.

Admission preserves a 20,000,000,000-byte start floor, 11,410,065,408 reserve and
8,589,934,592 working allowance, or stronger caller floors. This allowance is a
forecast, not measured Small use. Serial heavy stages record live overlap,
resource limits/affinity, free-space minima and the guard's stop status. Expand
admission from measured complete inputs instead of weakening coverage. Initial
free space is 192,024,567,808 bytes; /tmp shares this filesystem.

Final closure verifies the eight current proof manifests, unchanged holds and
policy, reports every remaining owned temporary root and its consumer, and
retains release/collector receipts. Build the new seal only from an explicit
maintained-file list. If registered, add this owned proof as a ninth policy entry
with exact before/after identities, preserving the original eight paths/bytes,
all other policy fields and independent holds. Do not add ordinary payload pins.

The final storage inventory, collector receipts, selected file list and proof
identity are under `final-storage/` in the evidence root. The selected seal has
468 files. The [qualification result](../evidence/release_small_preopt_acceptance_20261117.md)
records the execution, failures, operational recovery and disposition.
The ninth policy entry preserves the original eight contracts. All nine
verified after publication, with the seventeen independent holds unchanged.
