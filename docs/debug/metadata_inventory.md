# Debug-Info Metadata Inventory

This inventory separates debug-info preservation from optimizer and codegen
work. Debug metadata is important for Zig, but it should not be silently mixed
into scalar pass implementation.

## Zig Source Anchors

```text
ziglang/src/Compilation/Config.zig:
  debug_format selection and strip behavior

ziglang/src/codegen/llvm.zig:
  debug_compile_unit
  debugFile
  debugCompileUnit
  addNamedMetadata("llvm.dbg.cu")
  debugSubprogram
  debugGlobalVarExpression
  lowerDebugType
  debug location and source-scope plumbing around AIR lowering

ziglang/src/codegen/llvm/bindings.zig:
  Context.enableBrokenDebugInfoCheck
  Context.getBrokenDebugInfo

ziglang/src/zig_llvm.cpp:
  ZigLLVMEnableBrokenDebugInfoCheck
  ZigLLVMGetBrokenDebugInfo
  DiagnosticInfoDebugMetadataVersion handling

llvm-project-22/llvm/lib/IR/Verifier.cpp
llvm-project-22/llvm/lib/Transforms/Utils/AddDiscriminators.cpp
```

## Current Local Status

```text
raw top-level metadata records beginning with ! can round-trip
debug locations are not attached to instructions
metadata node graphs are not interpreted
debug-info updater behavior in passes is not implemented
broken-debug-info diagnostics are not implemented locally
```

## Metadata Surface To Inventory

| Metadata area | Zig/LLVM source shape | Local status |
| --- | --- | --- |
| Compile units | `llvm.dbg.cu`, `DICompileUnit`, producer, language, optimized flag | raw named metadata only |
| Files | `DIFile` for root source and imported scopes | missing |
| Subprograms | `DISubprogram` attached to function definitions | missing |
| Lexical scopes | `DILexicalBlock`, inline scopes, namespace scopes | missing |
| Locations | `DILocation` attached to instructions | missing |
| Local variables | `DILocalVariable`, `dbg.declare`, `dbg.value`, `dbg.assign` | missing |
| Global variables | `DIGlobalVariableExpression` and global metadata attachments | missing |
| Types | base, pointer, array, vector, struct, union, enum, optional/error union representations | missing |
| Module flags | `Debug Info Version`, DWARF version, CodeView mode, PIC/PIE flags where relevant | raw records only |
| Discriminators | `AddDiscriminatorsPass` updates line-table discrimination | placeholder only |
| Profile metadata | branch weights, call profile, function entry counts | missing |

## Optimizer Preservation Rules

Before a pass can claim debug-aware behavior, it needs an explicit policy:

```text
instruction deletion: drop or salvage debug value uses
instruction replacement: transfer debug location when LLVM does
CFG rewrite: preserve branch/debug locations or record unsupported behavior
code motion: keep a valid debug location or explicitly clear it
inlining: create inline scopes only after inline debug metadata is represented
loop transforms: preserve locations through hoist/rotate/unroll only after tests
```

Current passes are debug-unaware because accepted instructions do not carry
debug locations locally. That is honest only while the parser rejects or
preserves unsupported metadata without pretending to update it.

## First Implementation Slice Criteria

The first debug-info implementation slice should be preservation, not emission:

```text
parse a small Zig-emitted Debug LLVM IR fixture
preserve module flags and llvm.dbg.cu named metadata
preserve function subprogram attachments without interpreting the full graph
reject instruction-level debug locations until operand metadata attachments exist
document which passes are allowed to run on the fixture
```

## Deferred Behavior

```text
DWARF emission
CodeView emission
instruction debug locations
debug value intrinsics
debug-info salvage/update behavior in transforms
inline debug scopes
broken-debug-info diagnostic parity
```
