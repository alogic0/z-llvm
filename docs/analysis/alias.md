# Alias Analysis

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
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
```

Implemented subset:

```text
must_alias when two pointer values are the same named value
no_alias when two pointer values are distinct alloca results
trace simple getelementptr chains back to their stack-slot root
must_alias for zero-index GEPs from the same stack slot
may_alias for nonzero or unknown same-root GEP offsets
may_alias for parameters, unknown values, and non-stack-slot values
```

Upstream mapping:

```text
This reproduces the stack-slot identity and first GEP-root tracing needed by memory optimizations.
LLVM BasicAA proves much broader no-alias facts using object identity, GEP offsets, sizes, globals, captures, calls, invariant metadata, and recursive queries through AAResults.
```

Current users:

```text
src/tests.zig
future src/passes/mem2reg.zig
```

Known gaps:

```text
no MemoryLocation size modeling
only zero-vs-unknown GEP offset reasoning
no address spaces
no capture analysis
no globals or calls
no partial_alias result
no query cache
```
