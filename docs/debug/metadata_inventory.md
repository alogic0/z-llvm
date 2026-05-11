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
instruction `!dbg` attachments can round-trip as opaque metadata
metadata node graphs are not interpreted
debug-info updater behavior in passes is not implemented
broken-debug-info diagnostics are not implemented locally
```

## Metadata Surface To Inventory

| Metadata area | Zig/LLVM source shape | Local status |
| --- | --- | --- |
| Compile units | `llvm.dbg.cu`, `DICompileUnit`, producer, language, optimized flag | opaque raw metadata |
| Files | `DIFile` for root source and imported scopes | opaque raw metadata |
| Subprograms | `DISubprogram` attached to function definitions | preserved as function attrs plus opaque raw metadata |
| Lexical scopes | `DILexicalBlock`, inline scopes, namespace scopes | missing |
| Locations | `DILocation` attached to instructions | opaque `!dbg` attachment preservation |
| Local variables | `DILocalVariable`, `dbg.declare`, `dbg.value`, `dbg.assign` | missing |
| Global variables | `DIGlobalVariableExpression` and global metadata attachments | missing |
| Types | base, pointer, array, vector, struct, union, enum, optional/error union representations | missing |
| Module flags | `Debug Info Version`, DWARF version, CodeView mode, PIC/PIE flags where relevant | raw records only |
| Discriminators | `AddDiscriminatorsPass` updates line-table discrimination | placeholder only |
| Profile metadata | branch weights, call profile, function entry counts | missing |

## Optimizer Preservation Rules

Before a pass can claim debug-aware behavior, it needs an explicit policy:

```text
instruction deletion: current local policy drops attached `!dbg` with the
deleted instruction; debug value salvage is unsupported
instruction replacement: current local policy drops the removed instruction's
location unless the instruction is mutated in place; explicit transfer is
unsupported
CFG rewrite: preserve branch/debug locations or record unsupported behavior
code motion: keep a valid debug location or explicitly clear it
inlining: create inline scopes only after inline debug metadata is represented
loop transforms: preserve locations through hoist/rotate/unroll only after tests
```

Current passes are debug-location-aware only at the preservation boundary:
unchanged instructions keep their opaque `!dbg` attachments, removed or replaced
instructions drop them, and no pass attempts LLVM's debug value salvage,
assignment tracking, discriminator update, or inline-scope construction.

## First Implementation Slice Criteria

The first debug-info implementation slice should be preservation, not emission:

```text
parse a small Zig-emitted Debug LLVM IR fixture
preserve module flags and llvm.dbg.cu named metadata
preserve function subprogram attachments without interpreting the full graph
preserve instruction-level `!dbg` attachments as opaque records
document which passes are allowed to run on the fixture
```

Implemented Cycle 8 slice:

```text
test/zig/expected/debug_metadata.reduced.ll
src/ir/parser.zig preserves instruction !dbg attachments
src/ir/printer.zig prints preserved instruction !dbg attachments
debug value intrinsics remain rejected because metadata operands and salvage are
not represented
```

## Deferred Behavior

```text
DWARF emission
CodeView emission
debug value intrinsic operands and salvage
debug value intrinsics
debug-info salvage/update behavior in transforms
inline debug scopes
broken-debug-info diagnostic parity
```
