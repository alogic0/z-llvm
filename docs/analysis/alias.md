# Alias Analysis

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
llvm-project-22/llvm/include/llvm/Analysis/MemoryLocation.h
llvm-project-22/llvm/lib/Analysis/BasicAliasAnalysis.cpp
```

Upstream entry points to check:

```text
AliasResult
AAResults::alias
AAResultBase::alias
BasicAAResult::alias
BasicAAResult::aliasCheck
BasicAAResult::aliasGEP
MemoryLocation
AAResults::getModRefInfo
ModRefInfo
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
  llvm-project-22/llvm/lib/Analysis/BasicAliasAnalysis.cpp
  llvm-project-22/llvm/include/llvm/Analysis/MemoryLocation.h

LLVM entry points/classes:
  AAResults::alias
  AAResults::getModRefInfo
  BasicAAResult::aliasGEP
  ModRefInfo

Required analyses:
  MemoryLocation for stack roots, offsets, and sizes.

Required IR invariants:
  Verified pointer-producing alloca/GEP instructions and load/store users.

Core LLVM algorithm data structures:
  AliasResult
  ModRefInfo
  MemoryLocation ranges
  Conservative unknown answers for unsupported memory facts

Local target status:
  LLVM-shaped algorithm subset

Implemented subset:
  Stack-slot identity
  Simple GEP-derived stack locations
  Module-aware global and alias roots for accepted scalar globals
  DataLayout-aware access ranges when the module records a target datalayout
  Known disjoint byte ranges
  Load/store mod-ref queries
  Volatile/atomic/call unknown barriers

Intentional divergences:
  No address spaces, captures, recursive AA stack, metadata, or partial-alias
  result.

Analysis preservation/invalidation:
  Alias analysis is rebuilt on demand and has no preserved state.

Fixture coverage:
  unit tests in src/tests.zig

opt-22 comparison command:
  not applicable; currently analysis-only

Local-only fixture command:
  zig build test
```

Implemented subset:

```text
must_alias when two pointer values are the same named value
no_alias when two pointer values are distinct alloca results
trace simple getelementptr chains back to their stack-slot root
trace simple getelementptr chains from pointer parameters to a parameter root
must_alias for zero-index GEPs from the same stack slot
no_alias for non-overlapping same-root stack locations when offsets and byte sizes are known
no_mod_ref for non-overlapping same-parameter access ranges when the queried
access type supplies size
may_alias for unknown same-root GEP offsets
may_alias for distinct parameters, unknown values, and non-stack-slot values
mod/ref scaffold for load and store instructions
no_mod_ref for memory instructions proven no_alias to the queried pointer
unknown mod/ref for volatile or atomic memory barriers
```

Upstream mapping:

```text
This reproduces the stack-slot and pointer-parameter identity, first GEP-root tracing, MemoryLocation-backed byte range checks, and conservative mod/ref scaffolding needed by memory optimizations.
LLVM BasicAA proves much broader no-alias facts using object identity, GEP offsets, sizes, globals, captures, calls, invariant metadata, and recursive queries through AAResults.
LLVM's mod/ref queries combine alias analysis with instruction memory behavior; this subset only distinguishes direct load ref, direct store mod, no_mod_ref for known no-alias stack slots, and unknown barriers.
```

Current users:

```text
src/tests.zig
src/analysis/memory_location.zig
src/analysis/memory_effect.zig
src/passes/dse.zig
src/passes/early_cse.zig
src/passes/gvn.zig
future memory-aware LICM and MemorySSA-backed passes
```

Known gaps:

```text
no address spaces
no capture analysis; distinct pointer parameters remain may_alias
globals are limited to accepted scalar global definitions and aliases
calls are limited to function-attribute memory-effect classification
no partial_alias result
no aggregate, struct, or vector layout
no precise mod_ref result for calls or unknown instructions
no query cache
```
