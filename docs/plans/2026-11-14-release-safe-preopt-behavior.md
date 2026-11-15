# ReleaseSafe behavior through the local preopt pipeline

Date: 2026-11-14
Updated: 2026-11-15 after revised implementation and storage planning with agent
`01a1c2b0-45c7-7560-9ad0-050e8f6970f8`.
Status: implementing, authorized by the user on 2026-11-15. Baseline admission
and Debug/ReleaseFast runner qualification passed. Progressive capture exposed
and qualified proxy path, extended negative-zero serialization, inline memset
and scalar operand/immediate repairs. The captured runtime census selects
all 921 definitions without losing a previously selected definition. Promoted
source passes full units, readiness, structural smoke and fixed runtime
object/native replay. The fifth complete attempt matches all 2,097 ordered
reference outcomes, delivers both 921-definition runtime and 7,716-definition
test objects, and passes independent inventory, object/ownership/ELF and full
event audits. The real optimizer failure control stops before emission. Separate
stage-E reconciliation accounts for every invocation and both populations.
The floating cancellation repair passes focused/full units, calibrated native
checks, readiness and structural validation. Complete serial Tier 3 passes all
17 gates on the unchanged candidate, including the 230-population native suite.
Preservation, the committed-source bridge and storage closure remain pending;
earlier canceled integration attempts receive no aggregate acceptance. No preopt milestone
acceptance is claimed until the remaining F/G requirements close.
The [implementation checkpoint](../evidence/release_safe_preopt_checkpoint_20261115.md)
records the qualified A/B tooling, first C/D repairs and exact validation limits.

## Objective

Run the unchanged pinned upstream Zig behavior suite in ReleaseSafe through
the existing local preopt optimizer and local object emitter. Match every named
reference outcome, including reference skips, and independently audit every
delivered compiler-runtime/test object. Establish this complete workload without
executing LLVM's optimization or object-emission passes on the accepted route.

Keep the accepted postopt compiler/self-rebuild proof and fixed populations
unchanged. LLVM IR construction, bitcode parsing, target/analysis setup and
declared providers remain dependencies. This milestone does not remove libLLVM
or establish arbitrary LLVM optimizer parity.

## Observed starting point

The pinned frontend already has a preopt object hook. In ziglang/src/zig_llvm.cpp,
zigLLVMResolveZllvmHook accepts preopt for ReleaseFast, ReleaseSafe and ReleaseSmall,
mapping ReleaseSafe to zig-release-safe-accepted. Debug is explicitly unsupported.
The preopt branch in ZigLLVMTargetMachineEmitToFile prints the module before
module_pm.run, then invokes z_llvm optimization and object emission separately.
LLVM target/analysis objects are still constructed earlier in that function.

The existing preopt child commands have a fixed 64 MiB input limit. The accepted
Debug postopt behavior input alone is 67,658,559 bytes, so complete new inputs
need measured, explicit admission rather than assuming those helper defaults fit.
The current run_upstream_behavior runner fixes local captures to postopt; its
capture proxy and object auditor cannot count optimizer text output as an object.
The runner also does not export `ZLLVM_ZIG_MODE` or connect the shared headroom
admission/watchdog. Both are first-batch requirements before a real preopt run.

## Frozen baseline

Use generation 1 from the
[accepted behavior matrix](../evidence/compiler_behavior_follow_up_acceptance_20261113.json).
Its retained root is
`/home/oleg/prog/z_llvm-validation-qualified-behavior-v1461/local-state/isolated-validations-qualified-behavior-v1461`.

- Frontend: `whole-qualified-normal-v1490/install/bin/zig` under that root,
  SHA-256 `972160f222580c039d2e3244983c0aa13b16957ed56548c6153fb46af896bf8b`.
- Normal LLVM reference: `final-generation1-llvm-v1549/ReleaseSafe/report.json`,
  SHA-256 `8725f82704a5df72e40afaccf0c8f39ca20913c5cae7dcddaf877142b7909305`.
  It records the full unchanged suite and exactly 2,097 ordered outcomes.
- Upstream source: `/home/oleg/prog/ziglang`, clean tracked tree at
  `1c08b09d1c847f4f02c8216e3b62df323861a437`; `test/behavior.zig` SHA-256
  `3ef0e65cb6a9bb8a112549d0d8a52ded81cf4b154bd1f059c4dd878e38098af6`.
- Libc configuration:
  `local-state/validations/compiler-object-completion-20261111/batch-01/native-libc-link-v8/native-libc.txt`,
  SHA-256 `76ec8b788d551b0beed8f7359fd5ded95086f4a758b4bf2e07dfe31b2afdd34f`.
  Keep the reference's provider/toolchain identities, `x86_64-linux-gnu`, CPU
  baseline, pinned source library directory and normal resource settings.

Both agents reverified the frontend and reference hashes during planning.
Reverify the current bytes and complete dependency binding at execution admission.
Reuse this retained accepted pair in place; do not clone or rebuild another
baseline for admission. Run another reference only if a relevant dependency changes,
then account explicitly for any difference from the frozen outcome population.
Historical references using a different frontend remain ancestry, not substitutes
for this selected compiler identity.

Execution admission found changed system `libc.so.6` and dynamic-loader bytes;
the frontend, source/suite/libc configuration and the other 23 checked providers
still match. The required fresh normal LLVM ReleaseSafe run with this same
frontend passed all 2,097 ordered outcomes against the original reference.
Its provider-aware successor is
`local-state/validations/release-safe-preopt-20261115/batch-01/reference-current-runtime/run/report.json`,
SHA-256 `eb95b922e6103f495aef5937a0196cad1cef901f3da9036dd286aa39fc99d0c5`.
Use that report/hash for preopt comparisons under the current runtime. It records
11 current native inputs and the original `8725f827` reference as its exact
outcome ancestry. The original reference and existing accepted proofs remain
unchanged; no compiler baseline is cloned or replaced. Runtime identities and
the failed historical-provider admission remain under `baseline/` and
`tooling-debug-r3/`; the refreshed run records providers before and after execution.

The preopt hook selects its optimizer pipeline from the global environment.
Export `ZLLVM_ZIG_MODE=ReleaseSafe` and require `zig-release-safe-accepted` for
every hooked optimization command in this milestone. Compiler-rt's frontend IR
uses the target's Fast default even when the main workload is Safe; record that
source policy and keep runtime modules separate. This does not establish a
second preopt workload or claim that every module's frontend used Safe settings.

## Delivery

1. Admit and bind the frozen baseline above. Validate the reference hash, LLVM
   route, normal resources, frontend, source/suite/libc and target/CPU command
   settings, as well as all ordered names and outcomes. Keep the fixed postopt
   corpora and the selected reference under their current retention contracts.
2. Add explicit local pipeline selection to the maintained behavior runner,
   with postopt as the unchanged default. Reject preopt with the LLVM route or
   unsupported modes. Bind the explicit mode/pipeline and connect shared
   headroom admission, sampling and resource-stop handling. Use distinct optimizer
   and object stages, recording original/effective argv, tool identities,
   input/output sizes and hashes, actual completion/exit/signal statuses and
   diagnostics. Correlate stages by recorded identities/path relationships;
   require optimizer-output hash equal to emitter-input hash. An IR output is
   never `object_complete`; failed optimization cannot start emission or publish
   successful output. Qualify positive, failed, partial-output, incorrect pairing
   and misclassified-stage cases before expensive capture.
3. Capture each complete real preopt module as encountered, before repairing its
   failure. Record its hash, bytes, definitions, declarations, aliases and globals.
   An early runtime/optimizer failure may prevent later hook invocations: mark
   those populations not yet captured, citing the blocking attempt. If their
   identities or number are unknown, record that uncertainty rather than inventing
   module rows or counts. Keep discovery provisional.
   Steps 3 and 4 may interleave to expose the remaining inputs. A failed run,
   historical postopt counts or an assumed module count never closes inventory.
   Keep an append-only attempt ledger with frontend/backend/source identities,
   each observed module's role and its evidence, capture identity, stage statuses
   and blocking diagnostic. Distinguish input capture, optimizer completion,
   object delivery and audit completion, with failure/interruption states recorded
   separately. A partial optimizer output is a failed-stage diagnostic, not a
   complete optimized module.
   Closure requires one complete unchanged local preopt run on the frozen final
   candidate, using clean private frontend caches and reconciling every actual
   optimizer/emitter invocation and delivered object, separate runtime/test
   inventories, independent audits and all 2,097 outcomes. No reference-assisted
   discovery route is required for the first batch.
   Derive each stage's explicit input limit independently from its verified
   captured file size plus one, with checked arithmetic for the EOF probe.
   Record replacement of the hook's 64 MiB argument in effective argv; optimized
   output may be larger than its input. Keep public CLI defaults and existing
   ABI/frame limits unchanged; input admission does not require a frontend rebuild.
4. Diagnose failures in the shared parser, verifier, optimizer or selector that
   owns them. For each adopted repair, retain a minimal real-input reproduction,
   an independent LLVM/native comparison and adjacent rejection/negative controls.
   Preserve the original failed receipt; compare newly observed inputs with prior
   captures and explain identity changes rather than overwriting earlier records.
   Release diagnosed scratch after its reproduction and diagnostic consumers close.
   Keep LLVM verification as a validation reference, separate from the accepted
   compilation route. Do not stub, omit, substitute or silently fall back.
5. Complete the unchanged ReleaseSafe suite through preopt in one run on the
   frozen final candidate, with fresh private frontend local/global caches.
   Do not stitch successful stages from different attempts into an accepted run.
   Verify the complete optimizer inputs/outputs, match every named reference
   outcome and require census, ownership, ELF and ordered-event audits for every
   delivered local object. Reconcile the complete input inventory and account
   for runtime modules as separate populations. Repeat the route failure control
   with the final tools; qualify only actual local optimizer and emitter executions.
   No blocked or unexplained missing population may remain. Declared provider
   inputs remain dependencies and receive no local compilation credit.
6. Prove route ownership with retained commands and a negative control that
   forces the local optimizer to fail before object delivery. Require a failed
   compile and no successful object/fallback credit. Distinguish constructing LLVM
   target/analysis/pass-manager objects from executing LLVM optimizer or object
   passes; only the former remains on the accepted route. Bind any frontend
   ownership instrumentation to a separate source/build identity, preserving
   the pinned reference checkout and binary.
7. Apply docs/validation_tiers.md. Run required focused checks for each changed
   subsystem and cumulative Tier 3 before acceptance. Preserve prior native
   command outcomes/artifacts, fixed original objects and postopt behavior.
   Publish the new source/input identities and exact remaining LLVM dependencies.

An optional later reference-assisted diagnostic route must use a separate root
and explicit classification. LLVM-assisted completion is not capture-only or
accepted local compilation. Its commands/products earn no acceptance credit and
cannot replace the frozen normal reference or any stage of the accepted run.

## Execution and collection boundaries

The primary agent owns the canonical plan and implementation. The reviewing
agent reviews storage admission, retention and closure; it starts no independent
implementation or concurrent collector under this discussion. Assign one writer
per shared file before any later delegation. Use maintained Zig tools and native
helpers, `jqz` for structured records and `zigrep --no-config` for searches.

Evidence starts under
`local-state/validations/release-safe-preopt-20261115/batch-01/`.
`planning/` contains the discussion and agreement; `planning-check/` qualifies
the initial documentation update only; `planning-revision/` records its follow-up.
`baseline/` verifies the selected dependencies in place. Implementation uses fresh named stage roots
such as `baseline`, `tooling-debug`, `tooling-fast`, `tools`, `capture-01`,
`repair-FAMILY-ATTEMPT`, `final-behavior`, `preservation` and `integration`.
Declare each command's concrete producers, consumers and exceptions in its
`retention.md` before execution. Let nested behavior tools create their own
initially absent output directory inside the stage's evidence root.

Temporary products use the corresponding generated layout under
`local-state/tmp/validations/release-safe-preopt-20261115/batch-01/RUN/.workspaces/KEY/`.
Keep frontend, input and provider dependencies under their existing owners.
Execute A/B before real capture, then alternate C/D as dependencies unblock.
Proceed to E/F/G only with their complete final-run and preservation requirements.

| Stage | Required result | Temporary lifetime and collection boundary |
| --- | --- | --- |
| A. Baseline and storage opening | Verified frozen dependencies, exact reference population, consumer ledger and free-space observation | Checking scratch closes immediately; reuse existing accepted dependencies. |
| B. Tooling and route qualification | Mode/stage contracts, reference binding, headroom controls, focused tests and tool identities | Collect private build/test caches after their checks. Publish only required completed executables into a small managed pipeline; keep their paths stable through later audits. |
| C. Initial capture and provisional inventory | Complete encountered inputs, inventories and explicit blocked populations | Keep one active capture attempt. Preserve its real input and required diagnostics, diagnose the failure, then release scratch that has no remaining consumer. |
| D. Focused repair batches | Minimal reproductions, independent comparisons, rejection controls and required checks | C/D may interleave. Keep one current candidate generation and only a predecessor still needed for a comparison; release superseded products after the last consumer. |
| E. Final local preopt behavior and immediate audits | One complete frozen-candidate run with clean private frontend caches; all 2,097 ordered outcomes, every stage chain, reconciled runtime/test inventory, object/event audits and route control | The nested behavior runner uses its own `--retain-products`. Retain objects, backend executable and raw events through their final audit/comparison/fault consumer, then release and collect promptly. |
| F. Preservation and integration | Prior native populations, fixed postopt objects/behavior, faults, Tier 3 and terminal source verification | Run heavy stages serially in separate managed commands. Release each completed subpipeline; the candidate/tool pipeline closes after its last required consumer. |
| G. Closure | Accepted proof, selected maintained-file manifest, remaining LLVM dependencies and storage disposition | Close only this milestone's holds/pipelines, collect, retry deferrals at idle and record remaining roots with specific consumers. |

These are independent `tools/run-validation` launches, including `--command`
for scripts and custom build/test commands. Avoid a milestone-long enclosing
lease. Declare queued consumers before dropping a producer lease. An outer
retention flag does not retain a nested behavior workspace. In particular,
`audit_captured_object` rehashes the backend executable as well as reading its
object: that executable cannot move or disappear after suite execution but
before auditing finishes.

Preservation includes the
[throughput acceptance](../evidence/compiler_throughput_20261114.json) and the
accepted four-mode postopt behavior matrix. Preserve the existing 225 native
populations, 8,204 prior command outcomes and 3,399 backend artifacts per complete
comparison, fixed original compiler/runtime inputs and separate Small-runtime
population; record additions separately. Apply `docs/validation_tiers.md`,
including immediate Tier 3 for its wrong-code/ABI/verifier triggers. Changed
gate/cache infrastructure requires its fresh/cache comparison. Reuse unchanged
valid evidence rather than repeating broad runs without a relevant change.

The completed storage transition already retired ordinary historical native
outputs. Their original accepted checksum manifest remains intact at
`local-state/validations/compiler-throughput-20261114/batch-01/accepted-artifacts.sha256`,
SHA-256 `184a43fc349af600d3beda1c086ee26c1f99c85903da696675835642f987e0de`,
bound by the throughput acceptance. Qualify an explicit historical-hash provider
for that exact manifest while hashing every new candidate artifact live.
Missing historical identities or new bytes must fail. Preserve original command
outcomes, timeout contracts, fixtures, counters and registry entries, and verify
each normalized source path against its original fixture hash. Compare each new
Debug/Fast build directly against its corresponding historical build: the two
historical builds themselves have 33 differing object hashes, so they cannot
supply a transitive artifact-equality bridge. Retain that rejection, positive
historical self comparisons, and changed-manifest/outcome controls. This changes
the availability of old bytes, not the required 8,204 outcomes and 3,399 artifact
identities per comparison. Keep the qualified helper pipelines through these
consumers, then release their ordinary source copies, executables and caches.

## Space admission and maintained evidence

The shared serial policy remains 20,000,000,000 free bytes at admission:
11,410,065,408 reserve plus an 8,589,934,592 working allowance. Stronger caller
floors remain effective. This historical allowance is not a measured peak for
the new preopt workload. The behavior runner must actually connect admission,
sampling and resource-stop handling in B before claiming this protection.

For each stage, list simultaneously live retained tool/baseline bytes, current
input/output bytes, private build/cache forecast, pending trace/audit bytes and
any temporary publication copies. Bound overlap by running one heavy stage at
a time. Record per-root allocation and filesystem free-space minima; concurrent
processes can affect the latter, and before/after deltas are not measured peaks.
Planning observed about 159.9 decimal GB free. `/tmp` shares this filesystem
and provides no extra disk capacity. Check current space before every heavy run;
never reduce the test population or discard unaudited evidence to fit a forecast.

- Collect before each managed stage and after completed ordinary work. Read the
  collection receipt; a busy/deferred pass is not successful reclamation. Retry
  at the next idle boundary and carry any genuine remaining consumer explicitly.
- Release retained pipelines immediately after their final consumers, then run
  guarded minimal collection. Preserve original failed result records and useful
  diagnostics after diagnosing and releasing failed scratch.
- Keep unique required preopt inputs/outputs, input inventories and command/audit
  records outside disposable caches. Share finalized immutable inputs through the
  existing store API; never hardlink mutable scratch into evidence.
- Audit ordered raw events immediately, then use supported audited retirement
  once replay/trace consumers close. Retain traces and private build caches only
  through their named consumers, rather than accumulating them for every attempt.
- Accepted manifests enumerate only selected maintained files. Ordinary binary,
  object and cache hashes record identity without creating retention pins.
- Preserve the six current checksum contracts, independent holds, seven retained
  throughput workspaces, adopted providers, unique source/worktrees and original
  retirement records under their current contracts. Historical seals may describe
  retired products; current successor manifests govern present requirements.
  Existing launcher/collector bootstrap caches keep their existing owners/locks.

The [completed storage cleanup](../evidence/resolved_storage_cleanup_20261115.json)
and [collection cadence qualification](../evidence/frequent_storage_cleanup_20261115.json)
are the operating baseline. Another broad historical cleanup is not a
prerequisite for compiler development. Implementation stages now run under the
ownership and collection boundaries above.

## Acceptance and stop boundary

Apply the [development storage contract](../development_storage.md) before
starting this milestone. The concrete run plan must name evidence and temporary
roots and the consumers of each retained exception. Private caches, compiler
build trees, intermediate objects and test executables use managed workspaces;
keep baseline/candidate products with pipeline lifetime through comparison and
fault checks, then release them. Invoke `run_upstream_behavior` with its own
`--retain-products` until the independent captured-object audits and comparisons
finish; the outer checked command's retention flag does not retain a nested
tool's workspace. Preserve stage inputs/outputs needed by the
accepted preopt proof, command/result records and diagnostics as explicitly
maintained data. Raw compiler event traces stay outside disposable scratch
until audited retirement. Accepted manifests pin only the selected maintained
files. Close the milestone's own queued holds and completed pipelines, and
record the collector receipt and any remaining dependencies at handoff.

- One complete ReleaseSafe behavior result matching all 2,097 frozen ordered
  reference outcomes, including skips, with the exact baseline bindings above,
  clean private frontend caches and one frozen candidate. Its complete stage
  chains and runtime/test inventories reconcile without unexplained omissions.
- Every optimizer and object invocation in the accepted run completes with
  actual exit zero; all newly captured modules have complete inventories and
  object audits.
- No LLVM optimizer/object pass execution or fallback delivery in the accepted
  preopt route; IR construction and provider dependencies stay explicit.
- Required preservation checks, negative controls and cumulative integration pass.

Stop after this single-mode acceptance. Other modes, complete compiler preopt
build/self-rebuild, LLVM IR-builder replacement and provider-library removal are
separate milestones. Update the active handoff from measured results before
selecting the next one.
