# TargetLibraryInfo

LLVM reference:

```text
llvm-project-22/llvm/include/llvm/Analysis/TargetLibraryInfo.h
llvm-project-22/llvm/lib/Analysis/TargetLibraryInfo.cpp
```

TargetLibraryInfo records which library calls exist for a target and how
optimizer passes may reason about them.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Analysis/TargetLibraryInfo.h
  llvm-project-22/llvm/lib/Analysis/TargetLibraryInfo.cpp

LLVM entry points/classes:
  TargetLibraryInfo
  TargetLibraryInfoImpl
  LibFunc

Required analyses:
  Target triple and target library policy.

Required IR invariants:
  Libcall transforms must only use functions available for the active target.
  Unknown library names must remain unavailable.

Core LLVM algorithm data structures:
  Per-target LibFunc availability table.
  Libcall name lookup.

Local target status:
  Minimal target library inventory.
```

Implemented subset:

```text
recognize memcpy, memmove, memset, and sqrt
mark memory libcalls available for supported Linux and WASI triples
mark sqrt available for supported Linux triples
return unavailable for unknown names
```

Intentional divergences:

```text
no vector library mappings
no calling convention or errno policy
no libcall simplification or shrink wrapping yet
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  Linux and WASI libcall availability unit test

unit-test only:
  target library inventory lookup
```
