# GlobalDCE

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/IPO/GlobalDCE.cpp
```

GlobalDCE removes internal globals and functions that cannot be reached from
externally visible roots.

## LLVM Algorithm Contract

```text
LLVM source file:
  llvm-project-22/llvm/lib/Transforms/IPO/GlobalDCE.cpp

LLVM entry points/classes:
  GlobalDCEPass::run
  GlobalDCEPass::ComputeDependencies
  GlobalDCEPass::MarkLive

Required analyses:
  Module global/function symbol graph.
  Conservative handling of aliases, ifuncs, comdats, initializers, and
  externally visible roots in LLVM's full implementation.

Required IR invariants:
  Local definitions may be removed only when unreachable from visible roots.
  Definitions with externally visible linkage are live roots.

Core LLVM algorithm data structures:
  Global value dependency graph.
  Live global set and worklist.

Local target status:
  LLVM-shaped algorithm subset.
```

Implemented subset:

```text
non-local function definitions are roots
direct calls from live functions mark local function definitions live
unreached internal/private functions are removed
internal/private globals are removed because accepted IR cannot reference
globals as values yet
```

Intentional divergences:

```text
no aliases, ifuncs, comdats, metadata, or global initializer dependency graph
no available_externally handling yet
no global variable reference scanning until @global values are represented
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  internal function kept through direct call and dead internal function/global removal

unit-test only:
  globaldce removes unreferenced local functions and globals
```
