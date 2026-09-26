# Architecture corrections and refactor plan

Initial baseline: `629e2ee7`, 2026-09-26. Documentation and planning were committed
as `56e66794`. The first four bounded refactor slices are implemented below.
Selector defaults, public CLI behavior, and acceptance counters remain unchanged.

## Corrected assessment

The project already has a shared IR, analyses, operand mapping, CFG helpers,
typed AIR adapters, and composed selection with allocation/spill planning.
The problem is uneven use of shared mechanisms and multiple execution routes,
not their absence. The [architecture map](../architecture.md) records those
routes and their source owners.

Older backend-bootstrap documents understated the implemented backend. Equally,
a diagram showing every input passing through the optimizer overstated route
consistency. The ordinary object route bypasses the module pass manager; the
composed selector is opt-in and does not alone prohibit structural fallback.

The three repaired bugs justify targeted work on integer semantics, speculative
operand ownership, and complete reference discovery. They do not establish a
need to replace the entire IR or add an analysis-cache framework immediately.

## Documentation work

- [x] Publish a source-grounded component and execution-route map.
- [x] Correct backend, synthetic AIR bridge, and pipeline scope descriptions.
- [x] Separate optimizer evidence, local codegen evidence, real-row execution,
  and accepted-status declarations.
- [x] Link current guidance from the setup and documentation entrypoints.
- [x] Validate current-document and touched-document links; record the result.

## Proposed implementation sequence

Slices 1–4 have bounded implementations recorded below; slice 5 remains
pending.
These steps do not claim new compiler capability. Keep the named real-function
failure family in [next steps](../next_steps.md) as the capability objective; introduce helpers
in bounded slices where they support that work or reproduced correctness gaps.

### 1. Shared operand traversal and replacement

Owners: `src/ir/core.zig`, `src/ir/operands.zig`, `src/analysis/def_use.zig`,
and `src/passes/globalopt.zig`.

- Inventory existing `mapOperands`, use-count, and pass-local replacement
  implementations before choosing an API.
- Provide typed traversal of instruction and terminator value operands. Cover
  call callees/arguments, PHI values, GEP indices, aggregates, and vectors.
- Keep PHI predecessor labels and block targets distinct from value operands.
  Opaque textual expressions must return an explicit unknown/reference boundary.
- Introduce function-wide replace-all-uses on that traversal. Preserve each
  pass's replacement-chain and removed-instruction behavior during migration.
- Migrate one pass first, retaining behavior and existing APIs where practical;
  migrate others only after the helper is proven.

Exit criteria: all supported operand kinds have traversal/replacement coverage;
CFG/SSA verification and the migrated pass's fixtures remain unchanged; native
regressions agree with the pre-refactor behavior. No wholesale value-ID migration
is required for this step.

Implementation (2026-09-26, focused refactor):

- Inventoried `Instruction.mapOperands`, the three UseCounts walks, and
  GlobalOpt's instruction/terminator replacement switches. They enumerated the
  same structured values. Other pass-local walkers, including vector-combine,
  SCCP terminators, and GlobalOpt's escape scans, remain for later migrations.
- Added `ir.operands.instruction` and `terminator`. Visitors receive a value
  pointer and its IR type. Const input guarantees const value pointers even
  through list storage; mutable input borrows the actual operand storage.
- Added `replaceAllUses`, returning the replacement count and coverage. It
  performs exact name substitution, skips removed instructions, and leaves
  definitions, replacement bookkeeping, PHI labels, and branch targets intact.
  Mapping still does one alias lookup per operand; it does not chase chains.
- `Coverage.has_opaque_references` marks opaque values and unparsed syntax;
  clients cannot infer complete absence of references from an empty walk.
  Direct call symbols are outside this value API. GlobalOpt's eligibility and
  opaque escape policy are unchanged; its replacement walk alone is migrated.
- Added six tests covering all 20 instruction and six terminator kinds, typed
  const access, mutable list operands, CFG/SSA verification after replacement,
  one-step/cyclic alias maps, removed instructions, opaque boundaries, use-count
  balance, and allocation-failure cleanup.

Validation is recorded at the end of this page. This is an intermediate shared
IR refactor, with no capability/ratchet closure or Tier-3 milestone claim.

### 2. Explicit ownership for speculative instructions

Owners: IR instruction storage, SCCP, and inlining/clone consumers.

- Document which strings are borrowed/module-owned and which operand buffers an
  instruction owns; audit plain instruction copies followed by mutation.
- Design a mapped read-only operand view or an owning clone with explicit
  cleanup. Choose based on actual consumers, not a second IR hierarchy.
- Migrate SCCP's local argument copy and one additional real consumer only where
  the API improves ownership clarity.

Exit criteria: mutating speculative operands cannot change the source IR; call,
PHI, and GEP list storage is covered; allocation failure/leak checks pass; the
changing-loop-argument regression and positive constant-call folds still pass.

Implementation (2026-09-26, based on `b44ace9e`):

- Chose an owning `Instruction.clone` because SCCP and the inliner both consume
  mutable instructions. A mapped view would require changing the simplifier's
  interface while leaving the inliner in need of a separate clone mechanism.
- The ownership inventory found three allocated operand lists (PHI incoming
  values, GEP indices, call arguments) and one owned text allocation
  (`cmpxchg.result_ty.aggregate`). The clone copies those resources and preserves
  all other fields, including removed/replacement bookkeeping. Other strings
  remain borrowed; cloning does not extend their module/source lifetime.
- Migrated SCCP's speculative instruction and the common inliner used by both
  `always-inline` and `inline`. SCCP retains its selective lattice mapping rules;
  the inliner explicitly clears clone bookkeeping as before.
- The inliner reserves caller capacity before rewriting uses and transferring
  the staged clones. Name creation delegates cleanup to `Module.ownString`,
  avoiding duplicate frees when ownership registration fails.
- Allocation-failure testing exposed a missing `errdefer` in CFG reachability
  allocation, reached during SCCP cleanup. Added it without changing CFG or
  verifier semantics.
- Reviewed GVN scalar instruction copies (limited to binary operations) and CFG
  block-merging copies (ownership transfers). They are outside this bounded
  migration; this slice does not claim a repository-wide ownership conversion.
- Added six tests covering clone mutation isolation, both destruction orders,
  borrowed call fields and bookkeeping, inlining GEP storage, and exhaustive
  allocation-failure injection through clone and consumer cleanup. Borrowed
  strings deliberately remain valid only while their original owner lives.

This is an intermediate ownership refactor. It does not advance a compiler
capability, acceptance counter, or Tier-3 milestone.

### 3. Shared integer constant semantics

Owners: `inst_simplify`, other constant-folding consumers, and a small semantic
helper module located with the existing IR/analysis helpers.

- Centralize width validation, low-bit normalization, signed interpretation,
  comparisons, wrapping operations, and overflow/exactness checks.
- Keep poison/undef and unsupported widths explicit. Do not silently extend
  beyond the current representation or turn unsupported folds into guesses.
- Migrate a narrow family first, such as comparisons and signed div/rem, with
  differential tests before moving additional folds.

Exit criteria: paired signed/unsigned spellings agree at i1, narrow widths,
i64, i127, and i128; overflow, exactness, and shift boundaries preserve the
supported semantics; LLVM execution comparisons pass. A new arbitrary-precision
integer implementation is not a prerequisite.

Implementation (2026-09-26, based on `307a3688`):

- Added `analysis/integer_semantics.zig` with a checked scalar width descriptor,
  modulo-width normalization, signed/unsigned interpretation, all ten integer
  comparison predicates, and signed division/remainder. Division reports zero,
  signed overflow, and inexactness separately. Unsupported widths/types return
  no descriptor; poison, undef, and symbolic operands stay with the caller.
- Migrated constant comparisons and signed div/rem in `inst_simplify`, which is
  also consumed by SCCP and other optimizer passes. Existing arithmetic result
  normalization and shift input/output normalization use the same helper.
- Kept the migration narrow: `samesign`, algebraic identities, poison/undef
  policies, arithmetic flags, casts, unsigned div/rem, and i128 shift-folding
  limits retain their previous behavior. Other integer-family migrations and
  their operation-specific overflow/flag policies remain follow-up work.
- Added five tests, including all operand pairs for widths i1 through i8, an
  independent i256 mathematical oracle, and signed/unsigned spellings through
  i127. i128 exercises the full bit pattern through signed i128 storage; positive
  decimal literals above maxInt(i128) remain outside the parser's representation.
- Boundary tests cover min/-1, normalized zero divisors, exact/inexact results,
  wrapping normalization, shift limits, unsupported widths, poison/undef, and
  `samesign`. Undefined/poison-producing cases are structural tests and are not
  executed as native correctness probes.

The operation contract follows LLVM's
[integer comparisons](https://llvm.org/docs/LangRef.html#icmp-instruction),
[signed division](https://llvm.org/docs/LangRef.html#sdiv-instruction), and
[signed remainder](https://llvm.org/docs/LangRef.html#srem-instruction).
This extraction preserves existing optimizer behavior; it does not claim a
complete migration of integer folding or a Tier-3 capability milestone.

### 4. Module reference discovery

Owners: GlobalOpt, GlobalDCE, alias/constant handling, and a shared reference API.

- Enumerate references in instructions, terminators, global initializers,
  aliases, and supported constant expressions.
- Distinguish a known direct reference, known absence, and opaque/unknown uses.
  Module/inline assembly and raw attributes/bundles need an explicit policy.
- Migrate GlobalOpt first while preserving its conservative escape handling;
  audit the same categories before migrating deletion or merging passes.
- Parse opaque references only as justified by a named capability. Do not use
  partial textual matching to assert that a global is unreferenced.

Exit criteria: escaping references survive folding/deletion; unescaped globals
still optimize; arrays, aggregates, aliases, and nested expressions are covered;
native indirect-write tests and nearby rejection cases pass.

Implementation (2026-09-26, based on `8dad9cd6`):

- Added `analysis/module_references.zig`, a read-only, allocation-free visitor
  over module symbol uses. Events distinguish direct symbols from unknown
  regions and identify their containing site. A summary can contain both known
  uses and unknown coverage; only zero uses with no unknowns proves absence.
- Structured operands reuse the shared IR walker. Direct callees and alias
  targets follow their symbol-field contracts; definition names, block labels,
  removed instructions, and replacement bookkeeping are not uses. Alias edges
  are enumerated directly without claiming transitive alias resolution.
- Scalar and structured array initializers are inspected. Opaque initializers,
  constant expressions, vector text, metadata, assembly, raw arguments, and
  operand bundles remain unknown even when their text contains no `@`. A small
  explicit grammar accepts reference-free attributes; all other attributes
  remain unknown. Parsed byte strings are literal data. Pointer arrays that
  the parser retains as opaque stay unknown; this slice does not expand parsing.
- Migrated GlobalOpt's eligibility and remaining-use checks, removing its
  duplicate instruction/terminator/module scans. Unknown regions block folding;
  directly loaded local scalar globals still optimize. GlobalDCE and other
  deletion/merging consumers remain follow-up migrations requiring their own
  reference-policy audit.
- Found and repaired a namespace collision: the old GlobalOpt matched local
  `%g` against global `@g`, folding both loads to the global initializer. The
  new API matches only explicit global values. A native probe with global 1
  and local pointee 9 returned 2 before the fix and 10 after, matching LLVM 22.
  The permanent optimizer native harness now contains 17 functions.
- Added six tests for namespace separation, positive folding, alias chains,
  arrays, call/terminator references, nested opaque expressions, raw fields,
  assembly, metadata, attribute coverage, volatile/atomic loads, removed
  instructions, and visitor error propagation.

GlobalDCE follow-up (2026-09-26, based on `f635ac44`):

- Exposed shared module-scope and per-definition reference walks. GlobalOpt's
  whole-module scan composes the same walks; its reference policy is unchanged.
- Replaced GlobalDCE's call-graph dependency and duplicate operand switches with
  scanner-backed edges for functions, globals, and aliases. Alias targets and
  initializer references now resolve through all three definition kinds; local
  SSA names never create global edges. Removed instructions and replacement
  bookkeeping are ignored by the shared scanner.
- Kept reachability and reference coverage distinct. Unknown references in a
  live definition or module scope conservatively prevent all deletion, including
  COMDAT cleanup. Unknowns inside unreachable definitions do not make those
  definitions roots. Dead function/global cycles and unused aliases still go.
- Reproduced deletion of live alias dependencies on the saved baseline: a valid
  native fixture fails post-GlobalDCE verification with `UnknownGlobalAliasTarget`.
  The migrated pass preserves the dependencies and LLVM verifies the output.
- Added eight tests covering alias chains, initializers, terminators, vector
  operands, local/global collisions, dead cycles, live/dead opaque regions,
  assembly, raw call bundles, metadata, removed instructions, and allocation
  failures. Failure injection targets the graph/worklist allocator and verifies
  that failures leave the module intact.
- Added a five-entry-point native fixture to the mandatory optimizer correctness
  runner. It covers an exported alias, an alias pointer, an indirect callback,
  a pointer array, and a constant-expression load against LLVM 22 execution.
- The stricter unknown policy intentionally changes one of 243 existing fixture
  outputs: `globaldce_tls_concurrency_root` now retains definitions because its
  module metadata and attribute groups remain opaque. Its expectation is marked
  `local-conservative`; the remaining 242 outputs are byte-identical. This
  trades some dead-definition removal for soundness until structured parsing
  justifies narrower reference coverage.

### 5. Shared lowering and validation scope

Owners: AIR lowering, composed selector, relevant runners, and capability docs.

- Reproduce the named pointer-return/memory-intrinsic failure family before
  selecting its implementation slice. Implement reusable operations and require
  composed ownership for the new executable cases.
- Keep direct lowering, accepted optimization, and development optimization as
  explicit routes. Any later unified optimize-and-emit API must preserve route
  behavior until a separately reviewed CLI change is intended.
- Add generated compositions with defined semantics and minimized failure
  retention. Cover optimizer-only, codegen-only, and composed execution paths
  separately; report their pipeline and selector ownership.
- Establish fixed-program measurements for compile time, runtime, and object
  size before making optimization-quality or performance claims.

Exit criteria: unseen combinations of the newly supported operations execute
correctly, the named family closes through shared lowering, unsupported neighbors
fail explicitly, and results identify which route and population they prove.

## Validation and sequencing

Apply [validation tiers](../validation_tiers.md) to each implementation slice.
Optimizer changes require pass fixtures, compare-opt, and readiness. Changes to
shared lowering require the relevant AIR/codegen tests and real rows. Confirmed
wrong-code repairs, ABI/verifier changes, and milestone closure require Tier 3.
Any CLI behavior change also requires the linker-boundary gate. Record the exact
source/input state before a full run and reuse only matching evidence.

The original documentation-only change needed documentation validation only.

Documentation baseline validation (Zig 0.16.0): `zig build check-docs` passed for
its 14 current documents, 59 internal links, and two accepted-status blocks. A separate link
check covered all 11 changed/new Markdown files and verified 108 local links,
including the new architecture and plan pages outside the checker's fixed list.
`git diff --check` passed. That commit changed only Markdown documentation.

Slice 1 validation (Zig 0.16.0): focused operand tests passed. Saved the clean
`56e66794` compiler before editing and compared all 243 optimizer fixture rows;
raw printed IR is byte-identical before and after. The 16-function native
regression program agrees between the old compiler, new compiler, and LLVM 22
for both the focused pass list and `release-o3`. The migrated GlobalOpt's
positive direct-load fixture also executes identically (`read_h() == 7`).
Evidence and the comparison script are in
`local-state/validations/operand-refactor-20260926/` (ignored local artifacts).

`zig build readiness` passed, including unit tests, pass fixtures/compare-opt,
optimizer native checks, parser corpus, handoff, generated differential tests,
and release pipeline policy. Its behavioral suite passed 24 case/mode runs and
6,528 observations. `zig build check-docs`, a separate check of 24 local links
in both touched Markdown files, formatting, and `git diff --check` passed.

Additional ReleaseFast validation: `zig test src/tests.zig -O ReleaseFast`
passed 1,427 of 1,428 tests, including all six new operand tests. The existing
`generic cfg selector executes bit-exact widened half addition` test failed
with NaN bits `0x7e00` expected, `0xfe00` observed. Running the identical command
in a clean archive of `56e66794` reproduced that failure (1,421 passed, one
failed). This is a pre-existing ReleaseFast limitation; the suite is not
reported as green and no backend/test expectation was changed in this slice.
Both full logs are retained alongside the readiness and equivalence logs.

This follows the optimizer/shared-IR focused validation route. No ABI, verifier
invariant, CLI, acceptance counter, or gate infrastructure is changed. Full
Tier 3 remains required for a subsequent milestone or capability closure under
the validation policy; previous full-run evidence is not claimed for these
changed sources.

Slice 2 validation (Zig 0.16.0): all six ownership tests and both existing SCCP
changing-loop-argument/positive-call-fold regressions passed in Debug and
ReleaseFast. The full ReleaseFast half-add NaN-bit failure recorded for slice 1
remains tracked separately; this slice does not change that backend or test.
Evidence is retained under
`local-state/validations/instruction-ownership-20260926/`.

The saved clean `b44ace9e` compiler and the updated compiler produce identical
raw IR for all 243 optimizer fixtures. The 16-function optimizer regression
program agrees before/after and with LLVM 22 for the focused pipeline and
`release-o3`. A native inliner check also agrees before/after and with LLVM 22
when copying eight GEP instructions into a caller; LLVM verifies the resulting
IR. The local comparison script and outputs are retained with the evidence.
Documentation checks passed (14 current documents, 59 links, two status blocks),
as did the separate check of 24 links in both touched pages and formatting.

`zig build readiness` passed for slice 2, including the full Debug unit suite,
compare-opt, native optimizer regressions, corpus/handoff checks, generated
behavioral comparisons, and release pipeline policy. Validation follows the
focused optimizer/shared-IR route; the allocation-cleanup repairs do not alter
successful-program semantics or verifier invariants. No Tier-3 milestone is
claimed. The source hashes in the evidence directory identify the tested files.

Slice 3 validation (Zig 0.16.0): five new integer-semantics tests and the existing
comparison/division regressions passed in Debug and ReleaseFast. Exhaustive
narrow-width checks use an independent i256 model. All 243 optimizer fixture
outputs are byte-identical to the saved clean `307a3688` compiler, and the
16-function native regression program agrees before/after and with LLVM 22
under the focused pipeline and `release-o3`.

A separate deterministic native matrix covers 1,037 defined probes across i1,
i2, i7, i8, i16, i64, i127, and i128: 830 comparisons, 87 divisions, 87 remainders,
and 33 exact divisions. Both InstCombine and SCCP agree with the LLVM 22
reference execution and retain identical before/after IR. LLVM verifies the
source and every transformed module. The generator, harness, binaries, logs,
and source hashes are retained under
`local-state/validations/integer-semantics-20260926/`.

The previously recorded ReleaseFast half-add NaN-bit failure remains tracked
separately; this slice does not modify its backend or test. Additional integer
families and the remaining architecture slices remain pending.

`zig build readiness` passed for slice 3, including the full Debug unit suite,
compare-opt, native optimizer checks, corpus/handoff checks, generated behavioral
comparisons, and release pipeline policy. Documentation validation passed for
14 current documents, 59 links, and two status blocks; the separate touched-page
check covered 25 local links. Formatting and `git diff --check` passed. This is
a focused optimizer refactor with no ABI, verifier, CLI, capability, or ratchet
change; it does not claim Tier-3 milestone validation.

Slice 4 focused validation (Zig 0.16.0): six new reference-discovery tests and
existing GlobalOpt regressions passed in Debug and ReleaseFast. All 243
optimizer fixtures produce byte-identical output to the saved clean `8dad9cd6`
compiler. The expanded 17-function native optimizer harness agrees with LLVM 22
under both the focused pass list and `release-o3`. The separately retained
namespace-collision probe records old/new/reference outputs of 2/10/10.

Evidence, source hashes, and the immediate Tier-3 wrong-code trigger are under
`local-state/validations/module-references-20260926/`. Immutable AIR input caches
are reused with runner identity checks; earlier full-run results are not reused
for the changed optimizer sources. The previously recorded full ReleaseFast
half-add NaN-bit limitation remains separate and unchanged.

`zig build readiness` passed for slice 4, including the full Debug unit suite,
compare-opt, native optimizer checks, corpus/handoff checks, and release
pipeline policy. Generated behavioral checks passed 24 case/mode runs and
6,528 observations. Documentation validation passed for 14 current documents,
59 links, and two status blocks; the separate touched-page check covered 26
local links. Formatting and `git diff --check` passed.

Slice 4 Tier 3 passed: `zig build distribution-all -- --serial` completed all
17 subgates with `local_fail=0` in 2,190,811 ms (36m31s). The exact pinned-Zig
command, emitter selection, cache/evidence roots, trigger, and source hashes
are retained in the evidence directory above. Compiler, test, tool, and build
sources still match the recorded starting snapshot. The gate checked the
release object bundle and all three consuming link/inspection checks, native
executable canaries, and distribution boundaries.

Each release mode lowered/emitted/linked 100 compiler-core rows and executed
four cohort cases. These remain distinct from the integrated fixture and
standalone optimizer populations. No accepted-status counter, selector default,
public CLI, or capability ratchet changes in that slice. GlobalDCE migration is
recorded below; additional opaque-syntax parsing and slice 5 remain follow-ups.

GlobalDCE follow-up validation and limitations:

Eight new GlobalDCE tests, three existing GlobalDCE tests, and shared-reference
tests passed in Debug/ReleaseFast as applicable. The existing 17-function native
optimizer checks pass under both their focused pipeline and `release-o3`; the
new five-entry-point native reference fixture passes under GlobalDCE alone.
A separate alias-only native probe has no opaque regions: the old compiler
fails after GlobalDCE, while the new compiler and LLVM both return 19 through
an exported alias and an indirect callback. Its unrelated dead global is removed.
Evidence and the saved baseline are under
`local-state/validations/globaldce-references-20260926/`.

Two unrelated issues surfaced during test development and remain follow-up work:
ADCE drops a live indirect-callee dependency (`UnknownValue`), reproduced on the
saved clean `f635ac44` compiler under both `adce` and `release-o3`; and the unchanged
`VerifyContext.init` leaks an earlier allocation when a later initialization
allocation fails. The latter was observed when injecting failures across the
verifier as well as the pass; the permanent GlobalDCE failure test isolates the
pass allocator. No ADCE or verifier semantics are changed. The earlier full
ReleaseFast half-add NaN-bit limitation also remains separate.

`zig build readiness` passed for the GlobalDCE migration, including the full
Debug unit suite, all optimizer fixtures, both native optimizer programs,
corpus/handoff checks, generated behavioral checks, and release-pipeline policy.
Documentation checks passed for 14 current documents, 59 links, and two status
blocks; a separate check verified 33 links across the four touched pages.
Formatting and `git diff --check` passed.

GlobalDCE Tier 3 passed: the pinned Zig 0.16.0 `distribution-all -- --serial`
run completed all 17 subgates with `local_fail=0` in 2,193,991 ms (36m34s).
The evidence directory records the exact command, emitter/cache selections,
correctness trigger, and source/input hashes. Compiler, test, tool, and build
files still match the starting snapshot. Each release mode lowered, emitted,
and linked 100 compiler-core rows and executed four cohort cases. Release
object consumers, executable canaries, and distribution boundaries passed.
Readiness's generated behavioral suite passed 24 case/mode runs and 6,528
observations. These populations remain separate; accepted counters, selector
defaults, CLI behavior, and capability ratchets are unchanged.
