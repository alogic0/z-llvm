# Zig LLVM API Inventory

This inventory anchors the replacement project to the LLVM surface that Zig
actually uses today. Paths are relative to `prog`.

## Zig Entry Points

| Zig source | Role | Replacement owner |
| --- | --- | --- |
| `ziglang/src/codegen/llvm.zig` | LLVM backend object, module setup, target triple/data layout, type/value lowering, debug metadata, bitcode handoff, final emission | `src/codegen/`, `src/target/`, `src/debug/`, `src/bitcode/` |
| `ziglang/src/codegen/llvm/FuncGen.zig` | AIR-to-LLVM instruction lowering for functions | `src/air_bridge.zig`, `src/codegen/air_lowering.zig`, `src/ir/` |
| `ziglang/src/codegen/llvm/bindings.zig` | C ABI surface to libLLVM, ZigLLVM helpers, target initialization, LLD/archive helpers | component-specific bindings inventory below |
| `ziglang/src/zig_llvm.cpp` and `ziglang/src/zig_llvm.h` | Zig-specific wrappers around LLVM pass/codegen/linker APIs | upstream mapping for wrapper behavior |
| `ziglang/src/Compilation/Config.zig` | Decides when the LLVM backend and libLLVM are required | frontend/backend selection policy |
| `ziglang/src/link/Lld.zig` | Calls LLD through Zig LLVM bindings for link jobs | out of compiler-backend scope except dependency accounting |

## Binding Inventory

| Zig binding/API | LLVM or ZigLLVM entry point | Category | Owner | Current coverage |
| --- | --- | --- | --- | --- |
| `MemoryBuffer.createMemoryBufferWithMemoryRange` | `LLVMCreateMemoryBufferWithMemoryRange` | bitcode input | `src/bitcode/` | missing |
| `Context.create`, `Context.dispose` | `LLVMContextCreate`, `LLVMContextDispose` | IR context/lifetime | `src/ir/` | missing |
| `Context.parseBitcodeInContext2` | `LLVMParseBitcodeInContext2` | bitcode input | `src/bitcode/` | missing |
| `Context.setOptBisectLimit` | `ZigLLVMSetOptBisectLimit` | pass instrumentation | `src/pass_manager.zig`, `src/pipelines.zig` | pass-limit foundation |
| `Context.enableBrokenDebugInfoCheck`, `Context.getBrokenDebugInfo` | Zig LLVM debug-info wrappers | debug validation | `src/debug/` | missing |
| `Context.intType` | `LLVMIntTypeInContext` | LLVM type construction | `src/ir/` | partial integer IR only |
| `Module.dispose` | `LLVMDisposeModule` | module lifetime | `src/ir/` | partial text IR module with scalar globals |
| `Target.getFromTriple` | `LLVMGetTargetFromTriple` | target discovery | `src/target/` | initial target matrix recognition |
| `TargetMachine.create` | `ZigLLVMCreateTargetMachine` | target machine setup | `src/target/`, `src/codegen/` | missing |
| `TargetMachine.emitToFile` | `ZigLLVMTargetMachineEmitToFile` | optimization, codegen, object/asm/IR/bitcode emission | `src/pipeline.zig`, `src/codegen/`, `src/mc/`, `src/bitcode/` | asm bootstrap for tiny x86_64 leaf subset |
| `TargetMachine.createTargetDataLayout` | `LLVMCreateTargetDataLayout` | data layout | `src/target/` | parse/query foundation tested against clang-22 emitted datalayouts |
| `TargetData.abiAlignmentOfType` | `LLVMABIAlignmentOfType` | ABI query | `src/target/abi.zig` | partial integer ABI alignment query |
| `LLVMInitialize*TargetInfo` | LLVM target registration | target registry | `src/target/` | missing |
| `LLVMInitialize*Target` | LLVM target lowering registration | target registry/codegen | `src/target/`, `src/codegen/` | missing |
| `LLVMInitialize*TargetMC` | LLVM MC registration | assembler/object layer | `src/mc/` | local x86_64 assembly printer only |
| `LLVMInitialize*AsmPrinter` | LLVM assembly/object printers | asm/object emission | `src/mc/` | local x86_64 assembly printer only |
| `LLVMInitialize*AsmParser` | LLVM assembly parsers | tooling | `src/mc/` | missing |
| `LinkCOFF`, `LinkELF`, `LinkWasm` | `ZigLLDLink*` wrappers | linker | separate Zig linker effort; inventory only here | out of scope for backend replacement |
| `WriteArchive` | `ZigLLVMWriteArchive` | archive writer | `src/mc/archive.zig` or linker support | missing |
| `ParseCommandLineOptions` | `ZigLLVMParseCommandLineOptions` | LLVM diagnostics/options | tooling/pipeline instrumentation | missing |
| `GetHostCPUName`, `GetHostCPUFeatures` | `LLVMGetHostCPUName`, `LLVMGetHostCPUFeatures` | host CPU feature detection | `src/target/host.zig` | missing |

## AIR-To-IR Lowering Surface

`ziglang/src/codegen/llvm/FuncGen.zig` is the largest direct dependency on LLVM
semantics. It lowers Zig AIR to LLVM builder operations and is the main source
for deciding which IR instructions, attributes, intrinsics, and ABI rules the
replacement needs.

| AIR/lowering area | Representative Zig functions | Replacement owner | Current coverage |
| --- | --- | --- | --- |
| Calls and returns | `airCall`, `airRet`, `airRetLoad`, `lowerFnRetTy`, `ParamTypeIterator` | `src/codegen/abi.zig`, `src/target/abi.zig` | scalar return/parameter ABI classification only; full ABI lowering missing |
| Control flow | `lowerBlock`, `airBr`, `airCondBr`, `airSwitchBr`, `airLoop`, `airUnreach` | `src/ir/`, `src/codegen/control_flow.zig` | partial `br`, `condbr`, `unreachable` text IR |
| Arithmetic and comparisons | `airAdd`, `airSub`, `airMul`, `airCmp`, `airOverflow`, `airShl`, `airShr` | `src/air_bridge.zig`, `src/ir/`, `src/passes/` | AIR-like scalar binary/cast builder plus partial integer arithmetic, div/rem, casts, flags, freeze, and icmp |
| Memory operations | `airAlloc`, `airLoad`, `airStore`, `airMemset`, `airMemcpy`, `airMemmove` | `src/ir/`, `src/codegen/memory.zig` | partial alloca/load/store/GEP and mem2reg |
| Atomics | `airCmpxchg`, `airAtomicRmw`, `airAtomicLoad`, `airAtomicStore` | `src/ir/atomics.zig`, `src/codegen/atomics.zig` | missing |
| Aggregates and pointers | `airAggregateInit`, `airUnionInit`, `airStructFieldVal`, `airPtrElemPtr`, `ptraddConst` | `src/ir/aggregate.zig`, `src/codegen/layout.zig` | minimal GEP and scalar global preservation only |
| Optionals and error unions | `airOptionalPayload`, `airErrUnionPayload`, `airWrapErrUnionErr` | `src/codegen/zig_abi.zig` | missing |
| Debug info | `airDbgStmt`, `airDbgVarPtr`, `airDbgVarVal`, `getDebugFile`, `getDebugType` | `src/debug/` | missing |
| Inline assembly | `airAssembly`, constraint helpers | `src/codegen/inline_asm.zig`, `src/target/` | missing |
| Intrinsics and target hooks | `airTrap`, `airBreakpoint`, `airPrefetch`, `airWorkItemId` | `src/codegen/intrinsics.zig`, `src/target/` | missing |
| Address spaces | `airAddrSpaceCast`, `llvmAllocaAddressSpace`, `toLlvmAddressSpace` | `src/target/address_space.zig` | missing except opaque `ptr` |

## Current `z_llvm` Coverage

The current project covers phase-zero optimizer infrastructure:

- LLVM-compatible text IR parser/printer/verifier subset, including module-level source filename, target triple, target datalayout, scalar globals, function linkage/visibility, calling convention preservation, raw function and parameter attribute preservation, and void returns.
- AIR-like helper bridge for lowering tiny scalar binary/cast arithmetic function specs into project IR.
- CFG, def-use, dominators, dominance frontiers, LoopInfo, memory-effect classification, stack-slot MemoryLocation and alias/mod-ref scaffolding, and pass-manager instrumentation.
- `instcombine`, InstSimplify-style local scalar helper, `dce`, `adce`, `simplifycfg`, `early-cse`, `mem2reg`, `sroa`, `gvn`, and `licm` subsets.
- IR support for `void` returns, `select`, `unreachable`, bitwise operations, shifts, division/remainder spelling, integer `trunc`/`zext`/`sext`, scalar `freeze`, `nsw`/`nuw`/`exact` flag preservation, relational integer `icmp`, `undef`, simple `getelementptr`, and load/store `align`/`volatile` plus narrow atomic barrier spelling.
- Target support for initial target matrix recognition, default pointer/integer DataLayout queries, and scalar ABI classification.
- Codegen bootstrap support for `--emit=asm` over tiny x86_64 SysV straight-line i32 leaf functions.
- Named `scalar-foundation` and `memory-foundation` pipeline aliases, plus `opt-22` comparison fixtures for the implemented middle-end subset and unit tests for analysis-only behavior.

This is useful groundwork, but it does not yet cover the largest Zig LLVM
dependencies: AIR lowering, target lowering, ABI rules, instruction selection,
register allocation, object emission, debug info, bitcode, sanitizer/coverage
hooks, LTO, target features, or host CPU detection.

## Required Next Architecture

Only create implementation directories when inventory entries are ready to land
there. The current owner map is:

```text
src/ir/        LLVM-compatible IR semantics, parser, printer, verifier
src/passes/    middle-end pass subsets and future pipeline passes
src/analysis/  CFG, dominators, alias, dataflow, call graph
src/target/    triples, data layout, ABI, address spaces, CPU features
src/codegen/   AIR lowering, machine IR, instruction selection, register allocation
src/mc/        assembly, fixups, relocations, object/archive writing
src/debug/     DWARF, CodeView, debug metadata validation/emission
src/bitcode/   LLVM bitcode compatibility for migration and comparison
```

## Immediate Consequence

Future cycles should start from this inventory. Adding another optimizer pass is
valid only when it is tied to either:

1. a Zig LLVM API dependency listed here;
2. a required LLVM default pipeline stage that Zig invokes through
   `TargetMachine.emitToFile`; or
3. a comparison fixture needed to validate existing replacement behavior.
