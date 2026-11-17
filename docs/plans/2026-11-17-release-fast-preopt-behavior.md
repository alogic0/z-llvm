# ReleaseFast behavior through the local preopt pipeline

Date: 2026-11-17
Status: authorized; baseline admission in progress. Starting backend source:
`c32ba3cf`. The reviewer found no blocking issues in the completed maintenance
sequence. This plan owns only the newly assigned ReleaseFast milestone.

## Objective and acceptance

Run the unchanged pinned upstream behavior suite in ReleaseFast through the
local optimizer and local object emitter. One complete run on an unchanged
final candidate must match all 2,097 named, ordered normal LLVM reference
outcomes, including skips. Use `ZLLVM_ZIG_MODE=ReleaseFast` and require
`zig-release-fast-accepted` on every optimizer invocation. Record compiler-rt's
frontend Fast policy separately from the global hook policy.

Use the [ReleaseSafe plan](2026-11-14-release-safe-preopt-behavior.md) and its
[final acceptance](../evidence/release_safe_preopt_acceptance_20261116.md) as
the acceptance template. This milestone adds no ReleaseSmall, scheduler,
performance-parity, compiler self-rebuild or LLVM IR-construction-removal work.
LLVM construction, bitcode parsing, target/analysis setup and declared providers
remain dependencies. Existing ReleaseSafe/postopt acceptance remains separate.

## Baseline and admission

- Backend source starts at `c32ba3cf`. Bind complete source membership and bytes,
  build settings, SDK/library identity and the actual backend executable.
- Frontend remains generation 1 at
  `/home/oleg/prog/z_llvm-validation-qualified-behavior-v1461/local-state/isolated-validations-qualified-behavior-v1461/whole-qualified-normal-v1490/install/bin/zig`,
  SHA-256 `972160f222580c039d2e3244983c0aa13b16957ed56548c6153fb46af896bf8b`.
- Upstream source remains `/home/oleg/prog/ziglang` at
  `1c08b09d1c847f4f02c8216e3b62df323861a437`, with clean tracked bytes.
  `test/behavior.zig` hashes to
  `3ef0e65cb6a9bb8a112549d0d8a52ded81cf4b154bd1f059c4dd878e38098af6`.
- Libc configuration remains
  `local-state/validations/compiler-object-completion-20261111/batch-01/native-libc-link-v8/native-libc.txt`,
  SHA-256 `76ec8b788d551b0beed8f7359fd5ded95086f4a758b4bf2e07dfe31b2afdd34f`.
- Original matching Fast reference:
  `final-generation1-llvm-v1549/ReleaseFast/report.json` below the retained
  qualified root, SHA-256
  `33ac5970f58e8250448272dbaabd9251ac9cdbdbb8e839cb671b6bd54947c00a`.
- Current-provider Fast reference:
  `local-state/validations/release-safe-preopt-20261115/batch-01/preserve-reference-ReleaseFast/run/report.json`,
  SHA-256 `3974cd8a3f677667d91d568a5ed16d5bd77bf8ea7796ae8747a8aa8b6a8ca273`.
  It uses the same frontend and all 2,097 original ordered outcomes, with normal
  resources and recorded current libc/loader inputs. Verify all reference,
  frontend, source, suite, library and provider bytes at admission and before/
  after execution. Refresh the normal LLVM Fast reference only if a relevant
  identity changed; preserve original ancestry and account for every outcome.
- Use `x86_64-linux-gnu`, CPU baseline and the pinned upstream library directory.
  Do not clone or rebuild the accepted frontend for admission.

The earlier backend passes 2,438 Fast units, 74 structural checks, seventeen
integration gates and 237 native populations. Those receipts remain baseline
evidence, not full ReleaseFast preopt acceptance. Verify seven current integrity
manifests and preserve all seventeen independently owned holds and storage policy.

## Ordered execution

| Stage | Result and boundary |
| --- | --- |
| A. Admission | Verify baseline/reference/providers, full ordered population, clean source, tool identities, resources, storage contracts and free space. Close checking scratch immediately. |
| B. Candidate and tools | Build the requested ReleaseFast backend in a managed compiler pipeline. Qualify existing mode, capture/pairing, input-limit, reference and headroom contracts in Debug/Fast; bind auditor and inventory sources. Collect build/test scratch, retaining only declared tools/candidate consumers. |
| C/D. Progressive capture and repair | Retain every complete input encountered, inventory runtime/test roles separately and preserve failed receipts. Reduce demonstrated parser/optimizer/emitter blockers, qualify repairs and recapture. Later populations stay not-yet-captured until actually observed. Release diagnosed failed scratch after its consumers close. |
| E. Complete local qualification | One complete unchanged candidate run with clean private frontend local/global caches, no test filter, normal resources and all 2,097 ordered outcomes. Reconcile every optimizer/emitter invocation and every runtime/test module, then complete independent census, object/owner/ELF and ordered-event audits. A first complete capture may serve as this run if every final-source and resource requirement holds. |
| F. Route and preservation | Repeat a real optimizer-failure control with the final toolchain: failed compile, no emitter/object/behavior delivery or LLVM fallback. Verify source/setup-versus-execution route ownership. Preserve fixed objects, current native populations and ReleaseSafe/postopt acceptance. Run required focused checks for repairs and final cumulative Tier 3; classify every changed artifact explicitly. |
| G. Close | Publish source/reference/input/provider identities, exact acceptance and remaining LLVM dependencies. Close only this cycle's consumers/pipelines, collect immediately and record the receipt and any specifically justified remaining roots. Commit the completed milestone and stop for review. |

Input capture, optimizer success, object delivery, outcomes and audit completion
are separate facts. An early failure does not establish the later population's
identity or count. Keep an append-only attempt ledger; never replace original
failed/interrupted outcomes or stitch stages from different runs into acceptance.
Independent reconciliation must account for every actual capture directory,
optimizer and emitter, with no unexplained population or invocation remaining.

Require exact optimizer-output/emitter-input size and hash binding plus recorded
delivery-path relationships. Inventory raw and optimized definitions,
declarations, aliases and globals. Census every complete emitted module, audit
every delivered object and owner/ELF output, and strictly audit each complete
ordered hook event stream against its original producer/input/result bindings.
LLVM verification is a separate validation reference with no compilation credit.

The existing proxy must retain its distinct text/object contracts. Derive each
optimizer and emitter input limit independently from the verified file size
plus one, using checked arithmetic. Record effective argv replacing the fixed
64 MiB hook argument. Do not change public defaults, ABI/frame limits, the
frontend or the suite to fit an input. Do not fall back to LLVM optimization or
emission, omit tests, stub functions or substitute objects.

The final run starts with private, empty frontend local/global caches and uses
normal inherited resources. Record limits and affinity, fresh backend/link/
execution commands and any authenticated frontend reuse separately. Retained
inputs and existing accepted captures are dependencies, not evidence of a new
execution. Preserve unchanged-source checks before and after every accepted run.
No reuse of final backend/object/executable results is permitted.

Any demonstrated blocker gets a reduced real-input regression, independent
LLVM/native comparison and appropriate rejection controls. Apply
[validation tiers](../validation_tiers.md), including immediate Tier 3 for
wrong-code, ABI or verifier changes. No repair may silently weaken prior Safe,
postopt, native, fixed-input or integrity contracts. Reuse unchanged qualified
evidence only with explicit source/input/tool binding; repeat affected checks
when a relevant identity changes.

## Ownership, storage and resource admission

The primary agent owns this plan, implementation and milestone evidence at
`local-state/validations/release-fast-preopt-20261117/batch-01/`.
Each independent stage has `retention.md` before admission. Use
`tools/run-validation`, including `--command` for scripts. Ordinary products
go under the stage's generated `ZLLVM_TEMP_ROOT`; maintained commands, receipts,
diagnoses, unique captures and audits go under `ZLLVM_RUN_ROOT`.

Temporary producers are the candidate compiler, auditor/inventory tool builds,
focused checks, behavior private caches/objects/executable and final integration
work. Keep one current candidate and only a predecessor with an actual comparison
consumer. Candidate and audit tools stay at stable paths through final audits,
failure controls and preservation. Nested behavior tools use their own pipeline
retention when later consumers need objects/executables. No milestone-long outer
lease. Release each producer immediately after its final consumer, collect at
that boundary and retry deferred cleanup at the next idle boundary.

Maintained exceptions are unique complete preopt/optimized inputs, selected
reference/provider/source identities, original failures and reduced reproducers,
final reports, census/ELF/owner/event audits and original command bindings.
Declare their exact path, purpose, consumer and release condition in the relevant
retention note. Ordinary compilers, objects, test executables and private caches
are not new acceptance pins. Raw event streams remain maintained until strict
audits and an explicit supported retirement; never discard an unaudited stream.
Keep retained input sharing immutable through the existing artifact store.

Keep the Safe plan's admission floor: at least 20,000,000,000 free bytes, including
11,410,065,408 reserve and an 8,589,934,592 working allowance. Preserve stronger
caller floors. The historical allowance is not a measured Fast peak. Enforce
admission and runtime sampling through the existing guard, record live tool/
input/cache/object/trace overlap and free-space minima, and run heavy stages
serially. Expand the forecast from actual captured sizes; never lower coverage
or delete unaudited evidence to fit space. Initial read-only observation is about
200.1 decimal GB free; `/tmp` is the same filesystem.

Final closure verifies the seven current contracts and unchanged independent
holds/policy, lists every owned temporary root and its disposition, and retains
collector/release receipts. Build an explicit maintained-file acceptance list;
do not seal an entire temporary run. Record all remaining LLVM/provider
dependencies and exact proof limits in the final acceptance and commit.
