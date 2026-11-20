# Zig backend and linker handoff

This repository implements an experimental local optimizer and x86_64 Linux
object backend for selected Zig inputs. Its codegen is used by integration
hooks and executable validation; describing the whole backend as a tiny,
validation-only bootstrap understates the current implementation.

The [architecture map](../architecture.md) describes the current owners and
routes. It distinguishes implemented behavior from the
[proposed refactors](../roadmap/architecture_refactor_plan.md). This document
does not establish a complete replacement for Zig's native backends or LLVM.

## Ownership

| Component | Owner and boundary |
| --- | --- |
| Zig source semantics, AIR production, and compiler source checkout | Zig; selected descriptors are exported by the pinned patched emitter. |
| Exported AIR descriptor parsing and local lowering | z_llvm's AIR adapter; supported types, instructions, and shapes are bounded. |
| LLVM-compatible IR parsing, verification, and selected passes | z_llvm; opaque or unsupported semantics must retain conservative boundaries. |
| Selected x86_64 instruction selection, allocation/spill planning, ABI handling, and machine verification | z_llvm's local backend. |
| Selected assembly, encoding, symbols/relocations, and ELF relocatable output | z_llvm's MC/object modules. |
| Final executable/shared-library layout, linker runtime integration, CRT/libc, and dynamic loader responsibilities | Zig's selected toolchain/linker path and external runtime components. |

Zig source anchors include `src/Air.zig`, `src/Air/Liveness.zig`,
`src/codegen.zig`, `src/codegen/llvm/FuncGen.zig`, the native x86_64 backend, and
`src/link/*` in the pinned source checkout. Local code does not replace those
representations globally or require Zig to adopt LLVM PHIs, GEPs, or MemorySSA.

## Integration paths

| Path | What it does | What it does not establish |
| --- | --- | --- |
| Postopt object hook | Patched Zig constructs and optimizes LLVM IR, then z_llvm emits the selected object. | Independence from LLVM IR construction or LLVM optimization. |
| Preopt textual hook | Patched Zig writes pre-optimization IR; z_llvm applies an accepted mode pipeline and emits an object. | General `release-o3` coverage or independence from LLVM IR construction. |
| External/structured writer and semantic descriptors | Selected adapters construct IR from their declared inputs, then use the configured local optimization/emission path. | A general Zig frontend or universal AIR semantics. |
| Real AIR descriptor lowering | The pinned emitter exports AIR; local code lowers selected functions into project IR and objects. | Every gate runs the same optimizer pipeline or selects the same backend owner. |

The hook contracts include `ZIG_USE_ZLLVM_OBJECT`, `ZLLVM_EXE`,
`ZLLVM_PIPELINE=postopt|preopt`, and the separate IR-writer contract. Source and
emitter selection is documented in [environment](../environment.md).
[Pipeline documentation](../passes/pipelines.md) records local pass-manager invocation.
Gate populations and counters belong to their individual runners; older fixed
wrapper totals are not a current support inventory.

## Final linking

`z_llvm` emits IR, assembly, and relocatable objects, not final executables.
Native-link evidence explicitly selects `zig build-exe -fno-lld` and executes
the result. Merely invoking `zig cc` does not prove use of Zig's native linker.

The project should keep final linker ownership separate from object compatibility.
An object rejection needs classification by ABI, symbol, relocation, section,
TLS, COMDAT, alignment, or an actual external linker limitation. It does not
by itself justify implementing a linker in this repository.

## Selector and machine boundaries

The local backend has structural paths and a composed selector with bounded
liveness/allocation/spill planning. The composed selector is opt-in and an
unsupported attempt can reach structural fallback. Its ownership tags allow a
runner to reject that fallback where composed lowering is required. See
[machine representation](machine_ir.md) and the [behavioral suite](../../test/behavioral/README.md).

General multi-target support, arbitrary instruction/ABI/pressure combinations,
complete debug/unwind emission, and LLVM-level optimization quality remain
unproven. Existing register/spill planning should not be described as absent;
its limits should be stated by the relevant source and negative tests.

## Validation and scope

- `zig build handoff` compares selected optimizer and assembly/object facts.
- `zig build distribution-native-link` and `zig build probe-native-linker`
  exercise selected objects through explicit native linking.
- Integrated postopt, preopt, IR-writer, and release-source gates cover their
  declared wrappers and ownership contracts.
- `zig build distribution-all` composes the tracked 17 gates. Separate frontier
  gates remain outside that inventory where documented in [build steps](../build_steps.md).
- The public linker boundary is checked by
  `zig build distribution-linker-boundary`.

These checks are complementary. Compiler-core link counts, its fixed execution
cohort, compiler-rt ABI comparisons, and standalone behavioral observations are
separate populations. [Current state](../current_state.md) distinguishes the
accepted record from newly validated development evidence.

Future work should close a named source-backed family through shared lowering,
with executable and nearby rejection cases. The [active direction](../next_steps.md)
selects that family; this ownership document does not authorize a broad backend
rewrite or expansion into final linking.
