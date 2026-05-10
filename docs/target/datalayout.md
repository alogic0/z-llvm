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
DataLayout::getABIIntegerTypeAlignment
TargetMachine::createDataLayout
```

Implemented subset:

```text
parse target triples shaped like arch-vendor-os-abi
classify x86_64 and linux triples
parse and preserve LLVM target datalayout strings
query the default pointer size and pointer ABI alignment from p:<size>:<abi>
query integer ABI alignment from iN:<abi> entries
ignore address-space-specific pointer specs such as p270 for default pointer queries
```

Upstream mapping:

```text
This is the first target-aware replacement slice for LLVM Triple and DataLayout behavior.
LLVM's DataLayout is far richer: endian rules, mangling, native integer widths, stack alignment, address spaces, aggregates, vectors, function pointers, and target-specific defaults all matter upstream.
This project currently preserves the full string but only interprets the fields required by early scalar pointer/integer tests.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; this is currently unit-tested parser/query infrastructure

local-only conservative:
  address-space pointer specs are preserved but not used for default pointer queries

unit-test only:
  x86_64-linux triple parsing
  x86_64 datalayout default pointer-size and ABI-alignment queries
  i64 ABI alignment query
```

Known gaps:

```text
no target registry
no TargetMachine construction
no aggregate, vector, or stack alignment queries
no endian or mangling queries
no address-space-specific pointer query API
no LLVM-generated target matrix fixtures yet
```
