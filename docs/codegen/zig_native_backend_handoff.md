# Zig Native Backend Handoff

This document defines how this repository's LLVM-compatible IR, verifier, and
optimizer work can help Zig's native backends without becoming a competing
general backend project.

## Zig Source Anchors

All paths are relative to `prog`.

| Zig source | Boundary |
| --- | --- |
| `ziglang/src/Air.zig` | AIR is produced by Sema and consumed by codegen, one AIR instance per function. |
| `ziglang/src/Air/Liveness.zig` | Liveness records unreferenced instructions, operand deaths, branch deaths, loop live-ins, and block-scope deaths for backend lowering. |
| `ziglang/src/Zcu.zig` | Documents the intended split: AIR to MIR in `codegen.generateFunction`, then MIR to machine code in `codegen.emitFunction`, then linker storage. |
| `ziglang/src/codegen.zig` | Dispatches backend-specific AIR plus Liveness lowering into `AnyMir`, then emits finalized machine code through linkers. |
| `ziglang/src/codegen/llvm/FuncGen.zig` | Current LLVM backend AIR-to-LLVM-IR lowering surface that this repository uses for fixture and semantic inventory work. |
| `ziglang/src/codegen/x86_64/CodeGen.zig` | Native x86_64 AIR-to-MIR lowering, register/spill handling, branch lowering, and call lowering. |
| `ziglang/src/codegen/x86_64/Mir.zig` | Backend-specific MIR representation for x86_64. |
| `ziglang/src/codegen/x86_64/Emit.zig` | Converts x86_64 MIR into finalized machine-code bytes and fixups. |
| `ziglang/src/link/*.zig` | Linker-owned object placement, relocation application, and final binary state. |

## Project Role

The local project owns LLVM-compatible semantics and optimizer reproduction for
Zig-emitted LLVM IR. It does not own Zig's native backend architecture.

Accepted local roles:

```text
validate optimizer semantics against LLVM 22
record which optimizer facts should be available before native backend handoff
compare local optimized IR against equivalent Zig AIR/native-backend behavior
keep tiny codegen/MC/object paths as validation-only fixtures
study object/debug/linker boundaries when optimizer semantics require them
```

## Linker Ownership

Zig already owns linker infrastructure under `ziglang/src/link/*` and may
select its LLD path when configured. This repository should not clone LLD or
implement final executable, shared-library, archive, linker-script, CRT, libc,
or dynamic-loader behavior.

The local object work exists to validate that optimized LLVM-compatible IR can
become relocatable `.o` files whose symbols, relocations, sections, ABI, and
metadata are acceptable inputs to Zig's linker/toolchain. Executable harnesses
compile or link through Zig's linker path; failures are local object
compatibility gaps unless explicitly traced to missing Zig linker behavior.

The current linker boundary is checked directly by
`zig build distribution-boundary`: local `--emit=ir`, `--emit=asm`, and
`--emit=obj` stay in scope, `z_llvm --emit=exe` stays rejected, and executable
validation continues to hand local objects to Zig's toolchain through `zig cc`
or the selected Zig driver path. `zig build distribution-all` composes that
boundary proof with the selected positive no-LLVM-codegen distribution subset,
the selected native-linker execution proof, and the native-linker acceptance
probe.
This is not, by itself, proof that Zig's native linker was used: `zig cc` may
still choose an LLD-backed implementation for a target or configuration. A
native-linker claim requires a separate gate that selects a native-linker path
and records that fact; this repository should validate object compatibility
with that path, not implement the linker.

The selected native-linker proof is `zig build distribution-native-link`. It
emits local `.o` files with `z_llvm`, compiles C harnesses with `zig cc -c`,
then links with `zig build-exe -fno-lld` before executing the result. This
currently covers an ABI-stable subset across ReleaseFast, ReleaseSafe,
ReleaseSmall, and Debug/O0 objects. `zig build probe-native-linker` runs the
same selected object set as a compatibility probe and classifies the first
native-linker acceptance failure by symbol, relocation, section, TLS model,
COMDAT, alignment, ABI, or unknown linker compatibility.

The experimental integrated object-emission proofs are
`zig build distribution-zig-integrated-object` and
`zig build distribution-zig-integrated-preopt`; the external z_llvm textual IR writer
proofs are `zig build distribution-zig-ir-writer-tiny-scalar` and
`zig build distribution-zig-ir-writer`. The postopt/preopt hooks require a
patched local `../ziglang` with `ZIG_USE_ZLLVM_OBJECT=1`,
`ZLLVM_EXE=/path/to/z_llvm`, and `ZLLVM_PIPELINE=postopt|preopt`. Zig still
constructs LLVM IR. In postopt mode, LLVM runs Zig's normal module optimization
pipeline and the hook replaces only LLVM target-machine object emission with
`z_llvm --emit=obj`. In preopt mode, patched Zig writes IR before
`module_pm.run(...)`, `z_llvm` runs the accepted mode pipeline and emits the
object, and LLVM's module optimization pipeline is bypassed for the selected
rows. With `ZIG_USE_ZLLVM_IR_WRITER=1`, patched `Object.emit` validates the
external writer contract (`ZLLVM_IR_WRITER_MODE=external`,
`ZLLVM_CASE_ID`, `ZLLVM_ZIG_MODE`, `ZLLVM_WRAPPER`, `ZLLVM_IR_PATH`) and calls
`z_llvm --emit=ir-writer` to write the selected textual LLVM IR module before
the libLLVM bitcode parse/print path, then uses the same preopt `z_llvm`
optimizer/object path. Runtime writer rows now cover
`scalar-add-ret`, `integer-arithmetic`, `error-switch-select`, `direct-call`,
`global-load`, `i64-arithmetic`, `table-indexed-load`, and
`checked-add-runtime-boundary`, plus `runtime-condbr`,
`runtime-phi-merge`, `runtime-loop-sum`, `runtime-switch`, `global-update`,
`abi-arg-call`, `i64-call-return`, `tls-read`, `tls-bump`, `atomic-add`,
`inline-asm-barrier`, `aggregate-pair-abi`, `float-less`, and `float-mul`; all 24 selected rows are runtime-emitted and the gate
fails on unexpected `minimal-ret0` rows. All modes link through Zig native linking with
`-fno-lld`. Each wrapper row records the existing source-backed fixture it
covers so this gate remains connected to captured evidence rather than
standalone toy programs. The current wrappers expose C ABI `main`; the gate
emits the wrapper object with patched Zig `build-obj`, then links it with
`zig build-exe -fno-lld -fno-compiler-rt -lc`. Zig startup runtime and
compiler_rt sub-compilations are documented boundaries rather than part of this
object-emission slice.

Default non-goals:

```text
do not replace Zig's AIR, Liveness, MIR, codegen, linker, or debug pipelines
do not grow a general register allocator or scheduler here
do not generalize local MC/object writing beyond validation fixtures
do not clone LLD or move linker, archive, Clang, or C frontend replacement into
optimizer epics
```

## Handoff Map

| Local IR fact or optimizer output | Zig native consumer or validation use | Local action |
| --- | --- | --- |
| Verified CFG and terminators | AIR block, branch, switch, return, and unreachable lowering in native codegen | Use as fixture validation for control-flow lowering; do not replace AIR control-flow semantics. |
| SSA dominance and use-before-def checks | AIR value ordering plus Liveness death tracking | Use to prove optimizer rewrites preserve value availability before comparing with native backend behavior. |
| Phi predecessor validity | AIR block result and branch payload lowering | Use as a comparison model for merge values; do not introduce an LLVM-phi requirement into native MIR. |
| Canonical entry-block allocas promoted by mem2reg | AIR temporaries, stack slots, and native register/spill decisions | Use to validate when stack traffic can disappear before codegen; native backends may express this without LLVM allocas. |
| SROA zero-GEP forwarding | AIR aggregate or pointer-field simplification opportunities | Treat as a semantic fixture source; avoid implying Zig native backends need LLVM-style GEP slicing. |
| SimplifyCFG folded branches and merged returns | AIR control-flow simplification and native branch lowering | Compare final behavior and branch shape where practical. |
| InstSimplify/InstCombine scalar folds | Sema/AIR scalar canonicalization or native instruction selection simplification | Use LLVM fixture parity to define expected scalar semantics. |
| SCCP constants | AIR constant propagation and branch pruning opportunities | Use as optimizer-quality guidance, not a required backend input format. |
| DCE/ADCE removed pure instructions | AIR dead-value elimination and Liveness unreferenced-bit behavior | Use to validate that removed operations have no side effects. |
| DSE removed overwritten stores | Native stack-slot and memory-effect safety | Keep memory-effect proof explicit before comparing stack behavior. |
| GVN/EarlyCSE repeated pure-expression elimination | AIR/MIR commoning opportunities | Use as release-mode optimizer behavior, not an assumed backend pass. |
| LICM scalar hoisting | AIR loop lowering, Liveness loop live-ins, native MIR code motion | Compare only for pure scalar code until memory LICM has alias/MemorySSA proof. |
| LoopInfo canonical loop facts | AIR loop bodies and Liveness loop-analysis live sets | Use to document accepted loop shapes and test native behavior on equivalent source fixtures. |
| Target triple, DataLayout, and scalar ABI facts | Native backend ABI lowering and linker object format decisions | Keep as hard preconditions for both LLVM-compatible IR and codegen validation fixtures. |
| Memory-effect classification | Native backend side-effect barriers for calls, volatile, atomic, and stores | Use as a legality contract for optimizer rewrites before backend handoff. |

Detailed validation fixtures live in
`docs/codegen/handoff_validation_matrix.md`. That file is the active checklist
for mapping optimizer outputs to Zig-native handoff questions.

## Backend Experiment Classification

| Local area | Classification | Reason |
| --- | --- | --- |
| `src/air_bridge.zig` and `docs/codegen/air_lowering.md` | handoff study | Synthetic AIR-like builder helps compare optimizer facts with Zig AIR-shaped inputs. |
| `src/codegen/` tiny x86_64 lowering | validation-only | Proves selected optimized IR still reaches assembly/object bytes for tiny fixtures. |
| `src/mc/assembly.zig` | validation-only | Normalized assembly text is useful for regression checks, not a general `AsmPrinter` replacement. |
| `src/mc/encoding.zig` | validation-only | Direct encoding covers only tiny x86_64 instructions used by fixtures. |
| `src/mc/elf.zig` | validation-only | Selected ELF64 relocatable object writing validates relocation and symbol assumptions for tiny x86_64 fixtures; final ELF linking is Zig-owned. |
| debug metadata preservation/emission | debug-info study | Activate only after metadata parsing/preservation exists and a Zig fixture needs it. |
| broad register allocation, scheduling, multi-target MC, linkers | out of scope | Zig native backends and linkers already own this path. |

## Comparison Examples

These are the kinds of examples that should drive future handoff work:

| Local optimized IR change | Equivalent Zig-native question |
| --- | --- |
| mem2reg removes an entry alloca and replaces loads with SSA values | Does equivalent Zig source produce AIR/native code without unnecessary stack traffic in the chosen mode? |
| SimplifyCFG folds a constant conditional branch | Does AIR or native lowering avoid emitting the dead edge for the same source? |
| InstCombine folds a safe scalar identity | Is the same operation simplified by Sema/AIR, or should a Zig-owned optimizer pass learn it? |
| DSE removes an overwritten stack store | Can the native path prove the earlier store is not observable before codegen? |
| LICM hoists a pure scalar expression to a preheader | Can AIR loop lowering or native MIR represent the invariant value without increasing live ranges unsafely? |
| Target DataLayout changes pointer size/alignment | Do AIR lowering, ABI classification, Machine IR, and object metadata agree on the target facts? |

## Activation Rule

A local backend experiment is justified only when at least one condition is met:

```text
it validates an optimizer semantic claim with real assembly/object output
it exposes a target/DataLayout/ABI assumption needed by accepted IR fixtures
it clarifies debug-info, relocation, or object boundaries for future handoff
it provides a tiny regression fixture for a source-backed Zig LLVM dependency
```

Otherwise, add a doc row or inventory row instead of implementing backend code.

## Current Validation Gate

Run the bounded handoff regression set with:

```sh
zig build handoff
```

The supported compatibility gate is `zig build handoff`.
The gate covers representative scalar, memory, loop, and global optimizer
outputs plus tiny x86_64 assembly/object smoke checks, including fixed stack
access feeding a direct call, selected empty-module object emission, and the
selected Debug/O0 checked-add handoff fixture. Local `instcombine,dce` output
for `test/handoff/inputs/scalar_add_zero.ll` is compared against `opt-22`, then
emitted through local x86_64 assembly/object paths and compared with `llc-22`
object disassembly. It does not claim full native backend, linker, or
object/codegen completeness.

For linker and executable-handoff ownership, run:

```sh
zig build distribution-boundary
```

That boundary gate verifies the local linker non-goal separately from the
positive no-LLVM-codegen distribution subset. It proves that final linking is
outside `z_llvm`; it does not prove that Zig avoided LLD internally.

For selected native-linker handoff proof, run:

```sh
zig build distribution-native-link
```

## Out Of Scope

| Area | Disposition |
| --- | --- |
| Full AIR replacement | Zig-owned compiler architecture. |
| Full native backend replacement | Zig-owned backend work. |
| General register allocation | Out of scope until a source-backed validation slice requires a tiny model. |
| Instruction scheduling and target cost modeling | Out of scope; tied to real backend quality work. |
| Full executable/shared-library/archive linking | Zig linker-owned, not `z_llvm` work. |
| General ELF/Mach-O/COFF object writer parity | Out of scope except selected relocatable `.o` validation fixtures. |
| DWARF/CodeView emission | Debug-info study only after metadata surface exists. |
| LLD, archives, `zig cc`, `zig c++`, and `translate-c` | Separate Zig LLVM-removal workstreams; do not clone their ownership into this repository. |

## Maintenance

Refresh this document when Zig's backend split changes:

```sh
rg -n "generateFunction|emitFunction|AnyMir|Liveness|Legalize|separate_thread|llvm_object|failed_codegen" ziglang/src -g '*.zig'
rg -n "air[A-Z]|finishAir|lowerBlock|Emit|Mir|reloc|FrameIndex" ziglang/src/codegen -g '*.zig'
```
