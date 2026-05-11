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
branch/profile metadata attachments such as `!prof` can round-trip as opaque
terminator metadata
branch `!dbg` attachments and lexical-block metadata can round-trip opaquely in
reduced Debug fixtures
metadata node graphs are not interpreted
`llvm.dbg.value` and `llvm.dbg.declare` are accepted only as preserved
variable-location intrinsics with raw metadata operands
debug-info updater behavior in passes is not implemented
broken-debug-info diagnostics are not implemented locally
```

## Metadata Surface To Inventory

| Metadata area | Zig/LLVM source shape | Local status |
| --- | --- | --- |
| Compile units | `llvm.dbg.cu`, `DICompileUnit`, producer, language, optimized flag | opaque raw metadata |
| Files | `DIFile` for root source and imported scopes | opaque raw metadata |
| Subprograms | `DISubprogram` attached to function definitions | preserved as function attrs plus opaque raw metadata |
| Lexical scopes | `DILexicalBlock`, inline scopes, namespace scopes | `DILexicalBlock` preserved opaquely; inline and namespace scopes missing |
| Locations | `DILocation` attached to instructions and simple branch terminators | opaque `!dbg` attachment preservation |
| Local variables | `DILocalVariable`, `dbg.declare`, `dbg.value`, `dbg.assign` | `dbg.value` and `dbg.declare` preserve raw operands; `dbg.assign` remains unsupported |
| Global variables | `DIGlobalVariableExpression` and global metadata attachments | missing |
| Types | base, pointer, array, vector, struct, union, enum, optional/error union representations | missing |
| Module flags | `Debug Info Version`, DWARF version, CodeView mode, PIC/PIE flags where relevant | raw records only |
| Discriminators | `AddDiscriminatorsPass` updates line-table discrimination | placeholder only |
| Profile metadata | branch weights, call profile, function entry counts | opaque branch metadata preservation for reduced safety branches; call profile and function entry counts missing |

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
test/zig/expected/debug_scope_branch.reduced.ll
test/zig/expected/debug_call_chain.reduced.ll
test/zig/expected/debug_loop_sum.reduced.ll
src/ir/parser.zig preserves instruction !dbg attachments
src/ir/printer.zig prints preserved instruction !dbg attachments
src/ir/parser.zig and src/ir/printer.zig preserve branch !dbg attachments and
opaque DILexicalBlock records in reduced Debug fixtures
debug call-site and loop PHI locations are preserved opaquely through the
verifier-only Debug corpus pipeline
debug value and declare intrinsics are accepted as preservation-only calls with
raw metadata operands; transform passes are skipped for modules containing
them because variable-location salvage is not represented
test/zig/expected/debug_value_intrinsic.reduced.ll
test/zig/expected/debug_declare_intrinsic.reduced.ll
```

## Debug Intrinsic Policy

```text
llvm.dbg.value: preserve raw operands; no debug value salvage
llvm.dbg.declare: preserve raw operands; no variable-location salvage
llvm.dbg.assign: reject with UnsupportedDebugIntrinsic
DIExpression: preserved inside opaque metadata records and raw debug intrinsic
operands; not interpreted
DILocalVariable: preserved as opaque metadata and referenced by raw debug
intrinsic operands; no local variable tracking is represented
```

The pass manager treats modules containing accepted debug variable-location
intrinsics as verifier-only unless a pass has explicit salvage support. This is
the local equivalent of LLVM's debug-info updater boundary: preserved
`llvm.dbg.value` and `llvm.dbg.declare` calls are valid IR surface, but they do
not license scalar transformations that could leave stale variable locations.

Implemented Cycle 12 slice:

```text
test/zig/expected/release_safe_safety.reduced.ll
test/zig/expected/release_safe_call_boundary.reduced.ll
src/ir/parser.zig preserves branch `!prof` attachments as opaque metadata
declared opaque panic/runtime calls are preserved as call barriers in reduced
ReleaseSafe safety fixtures
sanitizer and trap instrumentation calls remain rejected until runtime
semantics are represented
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
