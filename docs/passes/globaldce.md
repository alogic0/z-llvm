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
module-level dependency graph for supported functions, globals, and aliases
shared module-reference scanner supplies definition-scoped symbol edges
externally visible functions, globals, and aliases are live roots
weak functions and globals are externally visible live roots
non-local function definitions are roots
direct calls from live functions mark local function definitions live
exported aliases mark their target functions/globals/aliases live
alias chains and recursive dependencies use the same live-node worklist
local SSA names do not create global dependency edges
local functions/globals with raw COMDAT attributes are removed when unreachable,
along with dead COMDAT records
thread-local globals are removed when unreachable and preserved when reached
through live functions, aliases, or externally visible roots
unreached internal/private functions are removed
scalar and structured array initializer references are represented in the graph
opaque references in live definitions or module scope prevent all deletion
unreachable definitions containing opaque references may still be removed
unreached internal/private globals are removed
unreached internal/private aliases are removed
```

Intentional divergences:

```text
no ifuncs or metadata dependency graph
no available_externally handling yet
opaque initializers, constant expressions, assembly, metadata, raw call fields,
and unrecognized attributes remain unknown rather than being parsed for symbols
module-wide unknowns, including attribute-group records, conservatively retain
all definitions; this can inhibit otherwise legal dead-definition removal
structured COMDAT group dependencies are not modeled; reachable raw COMDAT
attributes block deletion, while wholly unreachable groups can be removed
```

Fixture coverage:

```text
opt-22 equivalent:
  globaldce_basic
  globaldce_alias_root
  globaldce_weak_root
  globaldce_comdat_root
  globaldce_tls_root
  globaldce_tls_model_root
  globaldce_switch_table_root

local-conservative:
  globaldce_tls_concurrency_root (opaque module metadata/attribute groups)

native execution compared with LLVM 22:
  globaldce_references: alias export, alias pointer, indirect callback,
  pointer array, and constant-expression load, under GlobalDCE alone

unit-test only:
  globaldce removes unreferenced local functions and globals
  exported alias keeps a private target function live
  weak linkage is preserved and rooted
  unreferenced local COMDAT members and COMDAT records are removed
  unreferenced local thread-local globals are removed
  known TLS model spellings are preserved and unknown models fail verifier checks
  live alias chains and initializer/terminator/vector edges
  local/global name separation and removal of dead function/global cycles
  live versus dead opaque initializers and function bodies
  module assembly, metadata, attributes, and removed-instruction handling
  allocation-failure cleanup with no partial deletion
```

The new callback fixture exposes an existing ADCE `UnknownValue` failure under
`release-o3`, also reproduced with the saved pre-migration compiler. Its native
check therefore exercises GlobalDCE alone; the existing 17-function optimizer
harness still checks `release-o3`. Direct calls to aliases also remain outside
the verifier's accepted call surface; the native fixture calls through pointers
and an exported alias from C. Neither limitation is changed by this migration.
