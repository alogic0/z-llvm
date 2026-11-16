# Current architecture

Accepted backend source: `dbf7ade0` (2026-11-13), validated with tooling Zig
0.17.0 and upstream Zig source `1c08b09d`. This page describes implementation
and ownership; [current state](current_state.md) owns acceptance counts and the
[refactor plan](roadmap/architecture_refactor_plan.md) records the completed
bounded consolidation.

The project implements a bounded LLVM-compatible IR, optimizer, and x86_64 Linux
backend. Through the patched postopt hook, z_llvm emits the complete compiler
and runtime objects used to build the unchanged pinned Zig compiler and rebuild
itself under inherited stack and CPU settings. Both resulting compiler
generations pass the complete four-mode upstream behavior matrix through both
normal LLVM and local-hook routes. See the
[final acceptance](evidence/compiler_behavior_follow_up_acceptance_20261113.json).

LLVM still performs frontend optimization and supplies declared external
providers; Zig owns final executable linking. The accepted build and self-rebuild
prove this configuration. General LLVM replacement, arbitrary LLVM inputs and
other targets remain outside that acceptance. The text and AIR adapters retain
the distinct routes described below.

## Components and ownership

| Layer | Current owner | Responsibility |
| --- | --- | --- |
| LLVM-compatible text input | [IR parser](../src/ir/parser.zig) | Parse the supported textual surface into project IR. |
| Exported Zig AIR input | [AIR export](../src/zig_air_export.zig), [AIR lowering](../src/zig_air_lowering_impl.zig) | Consume the patched emitter's descriptor contract and lower supported functions; report unsupported shapes and fallback ownership. |
| Synthetic test construction | [AIR-like bridge](../src/air_bridge.zig) | Build small test modules without invoking Zig Sema. This is separate from real AIR export/lowering. |
| Shared IR | [IR core](../src/ir/core.zig), [verifier](../src/ir/verifier.zig) | Represent modules, values, instructions, CFGs, globals, and aliases; verify the supported invariants. |
| Optimization | [analyses](../src/analysis), [passes](../src/passes), [pass manager](../src/pass_manager.zig) | Apply explicitly selected transformations with local analyses. |
| x86_64 lowering | [lowering dispatch](../src/codegen/x86_64/air_patterns_impl.zig), [composed selector](../src/codegen/x86_64/generic_cfg_selector.zig) | Lower supported IR through structural or composed paths, including bounded allocation/spill planning and ABI handling. |
| Machine representation and objects | [MachineFunction](../src/codegen/x86_64/machine.zig), [MC](../src/mc) | Verify machine instructions and emit assembly, encoded instructions, and ELF relocatable objects. |
| Final linking | Zig toolchain, invoked by integration runners | Own executable layout, final relocation/linking, and runtime integration. `z_llvm` does not emit final executables. |

Both text and AIR adapters can construct project IR. They do **not** currently
follow one identical optimize-and-emit route. Case/semantic-descriptor writers
also remain separate integration adapters; they are not general Zig frontends.

The [AIR export cache](../src/air_export_cache.zig) publishes schema-4 metadata
atomically after transferring a verified run-owned payload into an immutable
generation-and-content-named file. Same-filesystem publication renames the
original file; cross-filesystem publication removes the raw copy after commit.
Failed metadata commits restore run ownership and leave the previous committed
payload intact. Readers retain schema-3 compatibility and authenticate payload
hashes. Cache identity still binds the emitter, source authority, mode, target,
arguments and closed environment; publication does not cache executions or
change the frozen candidate selection. This is validation infrastructure rather
than a change to LLVM instruction semantics.

The historical selector-v3 membership audit now consumes checked
[semantic facts](evidence/real_candidates_release_v3_facts_manifest.json).
These preserve signatures, effects, definedness and typed-body hashes from every
unambiguous function in the old exports. The offline builder verifies the original
audit identity and reproduces the entire candidate table and selected mode facts.
The [retention proof](evidence/candidate_facts_retention_20261103.json) permits
retirement of the old raw audit generation. Production lowering continues to
consume the current authenticated AIR cache.

## Actual execution routes

The dispatch is in [main_flow.zig](../src/main_flow.zig).

| Input and operation | Optimization behavior | Output |
| --- | --- | --- |
| LLVM IR, default/`--emit=ir` | Run the selected pass list; default `instcombine,dce`. | Transformed LLVM-compatible text. |
| LLVM IR, `--emit=obj`, `--emit=asm`, or selection-owner manifest | Shared preparation verifies the module and runs explicit `--passes`/`--pipeline` requests before selection. No optimization by default. | Object, assembly, or ownership report. |
| Exported AIR, `--emit=ir` | Lower, verify, run any explicit optimization request, then print. No optimization by default. | Project IR text. |
| Exported AIR, object/assembly/selection-owner manifest | Lower and use the same explicit preparation contract before selection. | Object, assembly, or ownership report. |
| Structured descriptors/writer cases, `--emit=ir` | Preserve the adapter envelope and append validated explicit optimization requests as a deferred recipe. | Adapter artifact with its preparation recipe. |
| Structured descriptors/writer cases, codegen | Build the typed module, run the surface- and environment-gated helper when applicable, replay deferred preparation, then apply explicit CLI optimization and generic selection. | Object, assembly, or ownership report. |
| Patched Zig postopt hook | LLVM optimizes the module; z_llvm replaces target-machine object emission. | Object handed to Zig. |
| Patched Zig preopt textual hook | The hook invokes z_llvm's accepted mode pipeline, then emits the transformed IR. | Object handed to Zig. |

See [pipelines](pipelines.md) for the distinction between accepted aliases and
development pipelines. The structured helper explicitly disables per-pass
verification; callers and tests must not assume the pass manager's default
verification setting applies to every route.

The [ReleaseSafe preopt acceptance](evidence/release_safe_preopt_acceptance_20261116.md)
proves one complete unchanged behavior suite through the local optimizer and
object emitter, with all 2,097 ordered reference outcomes and independent audits.
The global hook mode is Safe; compiler-runtime frontend mode remains Fast.
LLVM construction, bitcode parsing and target/analysis/pass-manager setup still
occur, and declared providers remain. The selected route executes no LLVM
optimizer or object-emission pass; a real optimizer-failure control proves that
failed local optimization cannot fall back to object delivery.

The shared contract is implemented by [compilation.zig](../src/compilation.zig)
and [compilation_artifact.zig](../src/compilation_artifact.zig). Codegen pass
traces and timing go to stderr so they cannot corrupt object bytes. For an
explicit optimizer-plus-local-backend experiment:

```sh
zig build run -- --passes=release-o3 --target=x86_64-unknown-linux-gnu --generic-cfg-selector --emit=obj input.ll > output.o
```

## Selector ownership

`CodegenOptions.generic_cfg_selector` defaults to false. The CLI flag
`--generic-cfg-selector` or `ZLLVM_GENERIC_CFG_SELECTOR` enables the selector
attempt. Within that attempt, mandatory semantic normalization precedes
selection. Recognized legacy envelopes retain their own lowering; other forms
pass checked normalization invariants before optional legalization and composed
block or CFG selection. Optional legalizers use an ordered bounded driver with
explicit original-form retry policy. Each rewrite returns through checked
semantic normalization; generated switch labels are retained in unwind order.
An unsupported result can still lead to structural
fallback in the outer lowering dispatcher. Prepared typed adapters explicitly
enable generic selection; ordinary CLI inputs retain the flag/environment choice.

The recorded owners are `legacy_envelope`, `composed_block`, `composed_cfg`, and
`structural_fallback`. Merely enabling the flag does not prove composed lowering.
The [behavioral runner](../tools/run_behavioral_diff.zig) checks the ownership
manifest and rejects every owner except `composed_block` and `composed_cfg`.
An aggregate `generic_codegen` counter is not a substitute for that assertion.

Register pressure is admitted through the shared allocation plan and concrete
frame layout. The six-register/32-spill summary describes the minimum reservation;
it is not a 38-value selection limit. Planned and emergency homes are sized
dynamically, with checked frame indices, page probing and the existing 8 MiB frame
ceiling. The independent 65,536-block boundary remains. Rejected frame construction rolls
back machine state and can report its pressure context through the observer.

After lowering, [frame compaction](../src/codegen/x86_64/generic_cfg/frame_compaction.zig)
can remove an unused trailing spill-reserve gap. Spill homes and lifetimes stay
unchanged. The pass rebases object and incoming-stack offsets, accounts for
temporary pushes, retains 16-byte alignment and page touching, and verifies a
private candidate before publication. Opaque stack uses keep their original
machine function. The 64 KiB stack-object limit is unchanged.

Scalar bit intrinsics use the existing integer legalizer and shared native-width
operations. Logical widths, funnel counts and advisory facts are validated before
private widening; source IR retains its types and attributes. General-dynamic
TLS addresses use an explicit resolver-call instruction with caller-saved register
and flags effects. Shared call-preservation transactions protect live GPR/SSE
values, and ELF emission checks TLS symbol types, section alignment and aliases.
Relocated TLS initializers remain outside this address contract.

The closed Linux x86-64 syscall matcher validates typed facts and optional tail
hints through the shared call contract. Exact assembly constraints, i64 carriers,
memory/register effects and the zero-through-six-argument boundary remain
authoritative. Mandatory tail calls and arbitrary assembly reject. Existing
simultaneous transfers and call-preservation transactions implement the operation.
Named `samesign ult i64` comparisons use the same full-width scratch action as
ordinary unsigned comparisons; the flag restricts defined inputs without
changing the predicate or register effects.

The diagnostic census copies final private assembly, comparison operands and
rejected value/allocation definitions before candidate rollback. It retains
unattributed cases explicitly. Its complete-input comparisons check selected
identities and failure tuples against production replay; adding observations
does not confer code-generation or execution credit.

`--selection-owner-output=PATH` writes the same sorted ownership manifest from
the successful object-emission selection run. It sorts references to machine
functions, preserving object order and bytes. The standalone manifest route
remains available for independent replay. `--profile=PATH` records exclusive
phase timings, per-legalizer attempts/rewrites, original-form retries, selection
iterations and emitted spill instructions. Profiling state is explicit and local
to a compilation; the JSON report is separate from binary stdout. `other` includes
uninstrumented setup and cleanup. Timings describe compiler work, not runtime
performance of emitted code.

Optional `--profile-events=PATH` writes `compilation-events-v1` JSONL records,
flushing each record with its sequence, elapsed time, function and phase. The
stream records begin/end pairs for functions, normalization activities,
legalizers and retries, so interruption leaves useful progress without claiming
completion. Event output is independent of the unchanged final
`compilation-profile-v2` summary. A rejected but complete diagnostic census has
balanced function outcomes and `succeeded: false`; the bounded tail retained by
the diagnostic runner is explicitly not a whole-stream audit. Timings with events
enabled include their output overhead.

## Correctness contracts at the AIR/backend boundary

Aggregate AIR loads capture scalar field values at the load instruction. A later
store consumes that snapshot rather than rereading an aliased source pointer.
Tagged optional loads likewise capture their null tag; pointer forms load the
stored pointer or tag before testing it. Non-null zero payloads stay non-null.
Tagged optional parameter/return ABIs and tagged stores without a complete
representation reject instead of silently dropping the tag.

[Shared constant address resolution](../src/codegen/x86_64/generic_cfg/cabi_memory_address.zig)
uses the target data layout to scale typed GEP indices. It checks offset arithmetic
and chooses signed disp8 only through 127, otherwise disp32 for supported 64-bit
loads. Narrow forms without a suitable encoder reject. Return reconstruction
cannot discard side effects or move barrier reads; the sret field loader declines
when a delayed load could cross an intervening store. Scalar load snapshots that
survive stores receive frame preservation space.

The shared [target layout](../src/target/datalayout.zig) now advances struct
fields by allocation size, including each scalar field's ABI tail padding. The
field after `i24` starts at byte 4 and the field after `x86_fp80` at byte 16;
nested structs and arrays preserve those strides. Arithmetic overflow rejects
instead of wrapping. The [accepted repair](evidence/allocation_padding_acceptance_20261103.json)
includes executable LLVM comparisons in all three modes.

Upstream mapping for these repairs, inspected in the local pinned sources:

- Zig `src/codegen/llvm/FuncGen.zig`: `airLoad`, `airIsNonNull` and `optCmpNull`;
  optional layout version 3 puts the tag after the payload's ABI size and retains
  volatile access semantics.
- LLVM `llvm/lib/IR/Operator.cpp`: `GEPOperator::accumulateConstantOffset` scales
  sequential indices by allocation size and handles struct layout offsets.
- LLVM `llvm/lib/Target/X86/X86ISelLowering.cpp` and
  `llvm/lib/Target/X86/X86InstrInfo.td`: target addressing and signed displacement
  forms. Local support remains the bounded, checked subset covered by native tests.

These contracts do not advance accepted counters. Current native regressions,
the behavioral comparisons and the integration gates establish different scopes.

The [pointer/length memory slice](evidence/startup_word_pair_memory_20261102.json)
admits an exact 16-byte `{ ptr, i64 }` object and transparent named wrappers.
A private codegen view decomposes defined constructors and aggregate stores into
scalar fields and reuses the existing 128-bit frame object. Bounded byte addresses
and memcpy use the existing value-use authority. The caller's IR, including
nested call arguments, remains unchanged. Other layouts, volatile/atomic aggregate
stores, unsupported address spaces, excessive alignment and escaping aggregate
SSA values retain explicit boundaries. Direct and release routes pass 384 local
observations against 192 LLVM-reference observations reused across the two routes,
plus independent expected fields and output guards.

The [scalar frame-store slice](evidence/scalar_frame_acceptance_20261103.json)
extends the existing value-use store action to runtime pointer and i64 values in
typed 64-bit integer frame slots. Register, spill and returned RAX values remain
distinct from frame-object addresses. Planning and execution retain width, kind,
alignment and frame-bound checks; the new frame forms reject non-default address
spaces and pointer stores require a 64-bit default pointer layout.
Immediate intent retains all 64 bits: `store i64 4294967295` now writes
`00000000ffffffff`, correcting the prior sign extension to all ones.
New direct/release canaries pass 768 local pointer observations against 384
reference observations and 486 local scalar observations against 243 references;
each reference population is reused across the two routes.

The [scalar startup slice](evidence/scalar_startup_acceptance_20261103.json)
lowers named `inttoptr i64 to ptr` through the existing sealed accumulator cast
action. It preserves all bits, live flags and aliases without a width mask;
other widths, immediates, flags and non-64-bit pointer layouts reject. Nondefault
pointer targets remain a parser boundary. LLVM's owner is
`SelectionDAGBuilder.cpp::visitIntToPtr`, whose equal-width integral conversion
preserves the representation. The frozen legacy cast body is unchanged.

Signed `icmp sge i32/i64 <named>, 0` complements the existing sign-bit action's
logical shift result with XOR 1 and defines a zero-extended i1. It reuses the
current-home, preservation, EFLAGS and rollback authority; `samesign`, other
widths and unproved operand forms remain outside that action. LLVM's owner is
`SelectionDAGBuilder.cpp::visitICmp`. Each new standalone canary passes 1,536
local observations against 768 LLVM references reused across direct/release
routes in three modes.

The unchanged Fibonacci retry passes these operations and stops in `start.main`
at `unsupported_value:composed-block-memcpy-dst`, on a constant-offset global
destination. Its LLVM reference executes; local execution remains zero. Symbolic
global address formation, initializer layout/bytes and relocations form the next
memory boundary.

The current-pin SysV legalization keeps `{ i64, i64 }` returns in RAX/RDX across
composed control flow and preserves both live operands of i128 subtraction.
The half-float carrier adapter admits only a nonescaping, nonvolatile aligned
slot with the audited scalar loads/stores; its unspecified padding is zeroed.
Exhaustive native tests check all 65,536 half payloads and seeded pair arithmetic.
Upstream owners are LLVM `X86ISelLoweringCall.cpp` (`LowerReturn` and call
argument assignment) and Zig `src/codegen/llvm.zig` (float ABI representation).

Unsigned 32-bit returns retain every immediate bit, and unsigned i64 comparisons
handle the signed-immediate boundaries through the existing compare authority.
LLVM's X86 instruction definitions and the `icmp` contract in `docs/LangRef.rst`
define the corresponding register and comparison semantics. Unreachable CFG
blocks retain earlier side effects and emit a trap when no existing trap or
exhaustive-switch proof terminates them; the upstream owner is
`CodeGen/SelectionDAG/SelectionDAGBuilder.cpp::visitUnreachable`.

The [FMA canary migration](evidence/current_pin_fma_canary_20261102.json)
audits the resulting register/spill changes against the unchanged frozen IR.
The original 29 exact-result checks and 8,192 seeded LLVM-paired observations
pass. Two FMA stream/byte identities move together; the helper and `__multi3`
identities stay fixed, and the production mismatch negative still rejects.

Direct C variadic calls admit one or two fixed pointer arguments, an i32
result, and at most one unnamed i32 after C's default integer promotions.
The composed caller preserves live values and overlapping outgoing argument
sources, materializes ordinary global addresses and integer constants, and sets AL to zero immediately
before the call, matching LLVM `X86ISelLoweringCall.cpp`'s vector-register count.
Floating, indirect, aggregate and stack variadic forms cannot enter legacy or
structural callers. Pointer-return `noalias` and argument `noundef` remain
advisory representation attributes, matching LLVM `IR/Attributes.td`; extension
and memory-return ABI attributes retain their separate admission checks.

All-zero scalar GEPs fold to their base pointer following
`Analysis/InstructionSimplify.cpp::simplifyGEPInst`; vector indices and nondefault
address spaces retain their boundaries. An i32 store through a returned RAX
pointer stages its address before scalar materialization, under the existing
value-use plan. Ordinary global pointer loads use the state authority's
accumulator definition and the existing ELF load instruction; atomic, TLS and
nondefault-address-space global loads remain outside this added form.

The [unchanged C compiler fixture](evidence/upstream_c_program_20261102.json)
comes from the pinned Zig repository. The pinned `zig cc` command constructs
sanitizer-free, unoptimized IR; local `memory-foundation` and the accepted release
pipeline optimize it before local object emission. LLVM 22 compiles the same
input for the reference. Both command-line paths execute in each mode, and an
independent native driver checks integer varargs, AL, argument permutations,
live-value preservation and heap accesses. The C mode labels select local
pipelines and do not claim Zig safety semantics for C.

`instcombine` folds direct `strlen` of complete private constant byte strings,
following LLVM `Transforms/Utils/SimplifyLibCalls.cpp::optimizeStrLen` and
`optimizeStringLength`. Mutable/interposable data, unknown pointers, missing
terminators and `nobuiltin` retain calls. Constant flagged truncations fold only
when each unsigned/signed promise holds, matching LLVM constant-folding rules.
The accepted release pipeline runs CFG and instruction cleanup again after
these folds so newly constant safety branches disappear before codegen.

## What the evidence establishes

| Check | Population and path | Limit of the claim |
| --- | --- | --- |
| Compiler-core real-row gate | Selected AIR functions, direct lowering/object emission and native linking; a fixed execution cohort. | The gate does not run the local module pass manager. Linking 100 functions does not mean executing 100 functions. |
| Standalone behavioral suite | Composed local codegen from unoptimized LLVM IR, paired with independently optimized LLVM references. | Harness/reference release modes do not select local `release-o3`; this is primarily codegen evidence. |
| Optimizer correctness runner | The original 17-function suite, five alias/reference entry points, vector operands, and seven integer/allocation boundary functions; fixture-specific pipelines plus `release-o3`, with transformed IR verified and compiled by LLVM at `-O0`. | This tests optimizer semantics independently of local codegen; these populations do not establish local object-emission coverage. |
| Integrated preopt/postopt/writer gates | The selected route and wrappers declared by each runner. | Different routes exercise different optimization owners and selector paths. |
| `distribution-all` | The tracked 17-subgate inventory and its declared populations. | Success does not cover every development pass, input shape, or separate frontier gate. |

The [memory and width acceptance](evidence/compiler_core_memory_width_acceptance_20261107.json)
records 100 compiler-core functions lowered, emitted and linked, with twelve
cohort executions in every release mode. The cohort checks 7,856 observations per mode:
four constant methods, ASCII, index boundaries, guarded atomic state transitions
and exhaustive packed-byte predicates, guarded event resets and packed 64-bit
conversions. The event checks are single-threaded. The 17-subgate run, unchanged
programs, 45 native populations and compiler-rt comparisons retain separate denominators.
Fresh AIR generation and cached execution replay authenticate the expanded source
identity. The fixed 100-row candidate prefix remains unchanged.

The shared transfer planner snapshots cyclic sources and later call arguments
before their registers are overwritten. Scalar integer register PHIs use the
same transaction. Proven free scratch registers or existing spill authority
preserve live aliases and widths; storage and unsupported-forward-reference
failures roll back. Pair/vector PHIs and spill destinations retain existing paths.
The [execution evidence](evidence/execution_breadth.md) records native cycle,
fan-out, pressure, memory-guard and rollback checks.

The earlier [infrastructure pair](evidence/startup_headroom_acceptance_20261103.json)
established the calibrated 8 GiB forecast and unchanged execution reserve.
Nested row workers inherit the original serial admission and enforce its reserve;
their transient minimum enters the serial report. Schema-3 row telemetry measures
allocated bytes across all seven owned roots, including retained exports.
Two-second samples and filesystem activity limit the measurement; these results
do not establish a runtime speedup.

## Current design constraints

- Alloca element counts are typed operands and participate in traversal,
  replacement, verification, and loop-use checks. Local frame codegen accepts
  only a single object; dynamic and multi-element counts are explicit rejections.
- Values use string names; integer literals use `i128` with width held in the
  surrounding instruction/type. Some values and attributes remain opaque text.
- [Integer semantics](../src/analysis/integer_semantics.zig) validates scalar
  widths 1–128, normalizes literal bit patterns, and provides comparisons and
  signed division/remainder with explicit failure reasons. The simplifier also
  uses width-aware signed min/max and unsigned div/rem interpretation while
  retaining its existing flags, poison/undef, and unsupported-case
  policies. Other integer families still have pass-local rules.
  Vector lane verification and folding share unsigned index normalization;
  scalar constant shifts normalize their counts before poison checks.
- [Operand traversal](../src/ir/operands.zig) provides typed const/mutable walks
  and function-wide replacement. `Instruction.mapOperands`, use counting,
  GlobalOpt replacement, and ADCE liveness share those walks. CFG-update helpers
  handle labels separately. Other passes still have independent replacement/reference scans.
  Shared queries distinguish operand occurrences from distinct users and carry
  type and coverage results. Vector-combine preflights coverage and dominance,
  including PHI edges, before replacement; its insert index reads current
  instruction operands. Cyclic byte-vector memory admission uses the same
  queries. Their [qualification](evidence/compiler_generalization_stage1_20261116.md)
  distinguishes consolidation, opaque-reference refusal and the stale-insert repair.
- [Constant tables](../src/codegen/x86_64/constant_table.zig) use validated typed
  descriptions for element family, count, stride, alignment, extent, access
  widths and index bits. The four original layouts retain their boundaries;
  literal i16 arrays additionally admit power-of-two counts 2 through 65,536.
  Checked access arithmetic and read-only/alias proofs precede emission.
  Index masks prove allowed bits and paired-access parity, not arbitrary ranges.
  Floating layouts and unsupported initializer syntax retain explicit limits.
  The [table qualification](evidence/compiler_generalization_stage2_20261116.md)
  records preservation separately from the bounded capability extension.
- Operand traversal reports opaque values, attributes, metadata, and call text
  as an incomplete reference boundary. It does not parse or rewrite that text
  or enumerate direct call symbols. Existing use-count and mapping wrappers
  retain their structured-value scope. ADCE skips a function before CFG or
  instruction deletion if active operands/raw fields have incomplete coverage;
  removed instructions do not block the pass.
- [Module reference discovery](../src/analysis/module_references.zig) combines
  structured operands, direct callees, aliases, and global initializers. It
  distinguishes global `@name` from local `%name` and reports opaque regions
  explicitly; absence requires both zero direct uses and complete coverage.
  Assembly, raw call fields, metadata, and unrecognized attributes conservatively
  remain unknown. GlobalOpt uses this API for eligibility and deletion checks.
  Allocation-capable consumers build one module context to resolve the bounded
  [reference-free attribute grammar](../src/analysis/reference_attributes.zig).
  Missing/duplicate group IDs and arbitrary string attributes, including helper
  names in `probe-stack`, remain unknown. Standalone walks cannot resolve group
  IDs without that context. The [attribute slice](evidence/reference_attributes_focused_20261103.json)
  has focused proof; cumulative dependency-reference integration is pending.
  GlobalDCE uses definition-scoped walks to build function/global/alias edges:
  an unknown in a live definition or module scope blocks deletion, while an
  unreachable definition containing unknown text can still be removed. Other
  reference consumers remain separate.
  ConstMerge now preflights shared reference coverage, rewrites structured
  operands through the shared traversal, and rechecks references before deletion.
  InstCombine resolves aliases over the complete live function after folding,
  including earlier PHIs and non-topologically ordered blocks. See the
  [correctness checkpoint](roadmap/correctness_checkpoint.md) for validation.
- `Instruction.clone` copies instruction-owned PHI, GEP, and call lists plus
  the synthesized `cmpxchg` result-type string. Other strings remain borrowed
  from the module/source. SCCP uses a temporary clone with explicit cleanup;
  both inlining passes share the same clone API and transfer ownership only
  after reserving caller storage. Plain struct copies still share storage and
  are appropriate only for reads or deliberate ownership transfers.
- Verifier context initialization registers each allocation for cleanup before
  the next allocation can fail; its accepted IR invariants are unchanged.
- The pass manager has no shared analysis cache/preservation contract. Passes
  construct their own analyses and must keep them valid across local mutation.
- The backend supports multiple blocks, memory, calls, and bounded spill
  planning. Older descriptions of an i32-only, memory-free bootstrap no longer
  describe the whole backend. General target/ABI/pressure coverage is still
  limited and must be established by specific evidence. Composed lowering now
  includes pointer returns, `i8 zeroext` entry parameters, and nonvolatile
  `llvm.memset.p0.i64` through a transaction-owned byte-fill action; see the
  [bounded family evidence](evidence/composed_memset_family.md).

These constraints motivate the refactor plan; they are not claims that shared
IR or shared lowering is absent. Linker ownership and accepted support boundaries
remain as documented in [current state](current_state.md).
