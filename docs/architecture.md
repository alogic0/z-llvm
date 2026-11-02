# Current architecture

Source baseline: `230a30ef` (2026-09-26), updated for the completed correctness
checkpoint covering aliases, module references, vector lanes and shift counts.
This page describes the
implementation; the
[refactor plan](roadmap/architecture_refactor_plan.md) records its completed scope.
The bounded refactors, memset capability,
[fixed-program performance baseline](evidence/fixed_program_baseline.md),
[checked memcpy family](evidence/composed_memcpy_family.md),
[scalar byte-loop slice](evidence/composed_byte_loops.md),
[loop-memory repair slice](evidence/loops_memory_repair.md), and
[cyclic byte-vector transfer slice](evidence/cyclic_byte_transfers.md) are complete.
The active integration frontier is the compiler-core real-rows denominator migration to tracked Zig 0.17.0.
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

## What the evidence establishes

| Check | Population and path | Limit of the claim |
| --- | --- | --- |
| Compiler-core real-row gate | Selected AIR functions, direct lowering/object emission and native linking; a fixed execution cohort. | The gate does not run the local module pass manager. Linking 100 functions does not mean executing 100 functions. |
| Standalone behavioral suite | Composed local codegen from unoptimized LLVM IR, paired with independently optimized LLVM references. | Harness/reference release modes do not select local `release-o3`; this is primarily codegen evidence. |
| Optimizer correctness runner | The original 17-function suite, five alias/reference entry points, vector operands, and seven integer/allocation boundary functions; fixture-specific pipelines plus `release-o3`, with transformed IR verified and compiled by LLVM at `-O0`. | This tests optimizer semantics independently of local codegen; these populations do not establish local object-emission coverage. |
| Integrated preopt/postopt/writer gates | The selected route and wrappers declared by each runner. | Different routes exercise different optimization owners and selector paths. |
| `distribution-all` | The tracked 17-subgate inventory and its declared populations. | Success does not cover every development pass, input shape, or separate frontier gate. |

The latest [repair validation](roadmap/optimizer_review_repairs.md) reports
100 compiler-core functions lowered/emitted/linked and four cohort executions
per release mode. The [accepted record](accepted_status.json) still declares
three executions. Development evidence does not automatically migrate it.
Standalone behavioral and compiler-rt counts are separate populations.

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
