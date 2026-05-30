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
  fixture-equivalent for listed graph fixtures.
```

Implemented subset:

```text
module-level dependency graph for supported functions and globals
externally visible functions, globals, and aliases are live roots
weak functions and globals are externally visible live roots
non-local function definitions are roots
direct calls from live functions mark local function definitions live
exported aliases mark their target functions/globals live
local functions/globals with raw COMDAT attributes are removed when unreachable,
along with dead COMDAT records
thread-local globals are removed when unreachable and preserved when reached
through live functions, aliases, or externally visible roots
unreached internal/private functions are removed
scalar global initializer references are represented in the graph if the parser
accepts them
unreached internal/private globals are removed
unreached internal/private aliases are removed
```

Intentional divergences:

```text
no ifuncs or metadata dependency graph
no available_externally handling yet
the parser still rejects most global-as-value and aggregate initializer forms,
so global initializer edges are limited to the accepted scalar surface
```

Fixture coverage:

```text
opt-22 equivalent:
  globaldce_basic
  globaldce_alias_root
  globaldce_weak_root
  globaldce_comdat_root
  globaldce_tls_root
  globaldce_tls_concurrency_root
  globaldce_tls_model_root
  globaldce_switch_table_root

unit-test only:
  globaldce removes unreferenced local functions and globals
  exported alias keeps a private target function live
  weak linkage is preserved and rooted
  unreferenced local COMDAT members and COMDAT records are removed
  unreferenced local thread-local globals are removed
  known TLS model spellings are preserved and unknown models fail verifier checks
```
