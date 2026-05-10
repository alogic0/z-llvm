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

Implemented subset:

```text
must_alias when two pointer values are the same named value
no_alias when two pointer values are distinct alloca results
trace simple getelementptr chains back to their stack-slot root
must_alias for zero-index GEPs from the same stack slot
no_alias for non-overlapping same-root stack locations when offsets and byte sizes are known
may_alias for unknown same-root GEP offsets
may_alias for parameters, unknown values, and non-stack-slot values
mod/ref scaffold for load and store instructions
no_mod_ref for memory instructions proven no_alias to the queried pointer
unknown mod/ref for volatile or atomic memory barriers
```

Upstream mapping:

```text
This reproduces the stack-slot identity, first GEP-root tracing, MemoryLocation-backed byte range checks, and conservative mod/ref scaffolding needed by memory optimizations.
LLVM BasicAA proves much broader no-alias facts using object identity, GEP offsets, sizes, globals, captures, calls, invariant metadata, and recursive queries through AAResults.
LLVM's mod/ref queries combine alias analysis with instruction memory behavior; this subset only distinguishes direct load ref, direct store mod, no_mod_ref for known no-alias stack slots, and unknown barriers.
```

Current users:

```text
src/tests.zig
src/analysis/memory_location.zig
src/analysis/memory_effect.zig
future src/passes/mem2reg.zig
```

Known gaps:

```text
no target DataLayout
no address spaces
no capture analysis
no globals or calls
no partial_alias result
no aggregate, struct, or vector layout
no precise mod_ref result for calls or unknown instructions
no query cache
```
