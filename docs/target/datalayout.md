# Target Triple and DataLayout

LLVM references:

```text
llvm-project-22/llvm/include/llvm/TargetParser/Triple.h
llvm-project-22/llvm/lib/TargetParser/Triple.cpp
llvm-project-22/llvm/include/llvm/IR/DataLayout.h
llvm-project-22/llvm/lib/IR/DataLayout.cpp
llvm-project-22/llvm/include/llvm/Target/TargetMachine.h
```

Upstream entry points to check:

```text
llvm::Triple
DataLayout
DataLayout::getPointerSizeInBits
DataLayout::getPointerABIAlignment
DataLayout::getPointerPrefAlignment
DataLayout::getABIIntegerTypeAlignment
DataLayout::getPrefTypeAlign
DataLayout::getTypeAllocSize
DataLayout::getStructLayout
TargetMachine::createDataLayout
```

Implemented subset:

```text
parse target triples shaped like arch-vendor-os-abi
parse compact arch-os triples for Zig-style wasm32-wasi input
classify supported targets: x86_64-linux-gnu, x86_64-linux-musl, aarch64-linux-gnu, wasm32-wasi
parse and preserve LLVM target datalayout strings
query the default pointer size plus pointer ABI/preferred alignment from
p:<size>:<abi>[:preferred]
use LLVM's 64-bit default pointer layout when no default p: entry is present
query integer ABI/preferred alignment from iN:<abi>[:preferred] entries
fall back to LLVM-like primitive integer defaults for i1/i8/i16/i32/i64 when a
layout omits an explicit entry
compute scalar, pointer, array, and simple literal-struct store sizes
compute ABI/preferred alignments and field offsets for simple aggregate types
ignore address-space-specific pointer specs such as p270 for default pointer queries
```

Upstream mapping:

```text
This is the first target-aware replacement slice for LLVM Triple and DataLayout behavior.
LLVM's DataLayout is far richer: endian rules, mangling, native integer widths, stack alignment, address spaces, aggregates, vectors, function pointers, and target-specific defaults all matter upstream.
This project currently preserves the full string but only interprets the fields
required by scalar pointer/integer tests and simple aggregate offset decisions.
The target matrix expectations are copied from `clang-22 -target <triple> -S -emit-llvm -xc /dev/null -o -`, which exercises LLVM's target datalayout creation path without relying on object emission.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; this is currently unit-tested parser/query infrastructure

local-only conservative:
  address-space pointer specs are preserved but not used for default pointer queries

unit-test only:
  x86_64-linux triple parsing
  x86_64-linux-gnu and x86_64-linux-musl datalayout default pointer-size, pointer ABI-alignment, and i128 ABI-alignment queries
  aarch64-linux-gnu datalayout default pointer-size, pointer ABI-alignment, and i16 ABI-alignment queries
  wasm32-wasi datalayout p:32 pointer-size, pointer ABI-alignment, and i64 ABI-alignment queries
  aarch64 aggregate padding for `{ i8, i32 }` and `[2 x { i8, i32 }]`
  memory-location GEP offset calculation using parsed aarch64 DataLayout
  compact wasm32-wasi triple parsing
```

Known gaps:

```text
no target registry
no TargetMachine construction
no vector or stack alignment queries
no endian or mangling queries
no address-space-specific pointer query API
no scalable vector, packed struct, or non-integral pointer layout semantics
no automatic LLVM-generated target matrix fixture regeneration yet
```
