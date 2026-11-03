# Current architecture

Source baseline: `1f92385e` (2026-11-03), including the current-pin
correctness, ABI, export publication, execution, scalar frame stores and startup
scalar conversions/comparisons.
This page describes the
implementation; the
[refactor plan](roadmap/architecture_refactor_plan.md) records its completed scope.
The bounded refactors, memset capability,
[fixed-program performance baseline](evidence/fixed_program_baseline.md),
[checked memcpy family](evidence/composed_memcpy_family.md),
[scalar byte-loop slice](evidence/composed_byte_loops.md),
[loop-memory repair slice](evidence/loops_memory_repair.md), and
[cyclic byte-vector transfer slice](evidence/cyclic_byte_transfers.md) are complete.
The accepted checkpoint uses tracked Zig 0.17.0, executes all byte inputs for
the selected ASCII function, and runs unchanged upstream Zig and C programs.
Production export publication transfers the original payload into the cache;
an earlier infrastructure checkpoint passed fresh and cached full integration
runs against one source snapshot. The current scalar checkpoint reuses verified
exports and reruns executions.
The project implements a bounded LLVM-compatible IR, optimizer, and x86_64 Linux
backend for selected Zig inputs. It does not yet provide a complete LLVM
replacement or a self-hosting Zig backend.

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
| LLVM IR, `--emit=obj`, `--emit=asm`, or selection-owner manifest | Verify and emit directly; return before the CLI pass manager. Supplying `--passes` does not turn this route into optimize-and-emit. | Object, assembly, or ownership report. |
| Exported AIR, `--emit=ir` | Lower and print; return before the CLI pass manager. | Project IR text. |
| Exported AIR, object/assembly | Lower and emit directly. | Object or assembly. |
| Selected structured descriptors/writer cases | A surface- and environment-gated helper may run `sccp,simplifycfg,instcombine,dce` before emission. | Selected integration objects. |
| Patched Zig postopt hook | LLVM optimizes the module; z_llvm replaces target-machine object emission. | Object handed to Zig. |
| Patched Zig preopt textual hook | The hook invokes z_llvm's accepted mode pipeline, then emits the transformed IR. | Object handed to Zig. |

See [pipelines](pipelines.md) for the distinction between accepted aliases and
development pipelines. The structured helper explicitly disables per-pass
verification; callers and tests must not assume the pass manager's default
verification setting applies to every route.

For an explicit optimizer-plus-local-backend experiment, use two steps:

```sh
zig build run -- --passes=release-o3 input.ll > optimized.ll
zig build run -- --target=x86_64-unknown-linux-gnu --generic-cfg-selector --emit=obj optimized.ll > output.o
```

## Selector ownership

`CodegenOptions.generic_cfg_selector` defaults to false. The CLI flag
`--generic-cfg-selector` or `ZLLVM_GENERIC_CFG_SELECTOR` enables the selector
attempt. Within that attempt, a legacy envelope is tried before composed block
or CFG selection. An unsupported result can still lead to structural fallback
in the outer lowering dispatcher.

The recorded owners are `legacy_envelope`, `composed_block`, `composed_cfg`, and
`structural_fallback`. Merely enabling the flag does not prove composed lowering.
The [behavioral runner](../tools/run_behavioral_diff.zig) checks the ownership
manifest and rejects every owner except `composed_block` and `composed_cfg`.
An aggregate `generic_codegen` counter is not a substitute for that assertion.

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

The [current acceptance](evidence/scalar_frame_acceptance_20261103.json)
records 100 compiler-core functions lowered, emitted and linked, with five cohort
executions in every release mode. ASCII contributes 256 input observations per
mode; the retained constant methods contribute one each. The current serial run
passes all 17 subgates against a frozen 2,580-file source snapshot, reusing three
authenticated AIR exports while rerunning execution. Standalone programs,
behavioral observations and compiler-rt counts retain their own populations.
The earlier [infrastructure pair](evidence/startup_headroom_acceptance_20261103.json)
passed both 17-subgate runs with 1,396 matching canonical records. Its calibrated
8 GiB forecast and unchanged reserve are reused; the current serial report
observes a 1.63 GB free-space decrease.
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
