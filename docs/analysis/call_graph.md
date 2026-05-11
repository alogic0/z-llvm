# Call Graph

LLVM references:

```text
llvm-project-22/llvm/lib/Analysis/CallGraph.cpp
llvm-project-22/llvm/include/llvm/Analysis/CallGraph.h
llvm-project-22/llvm/include/llvm/Analysis/LazyCallGraph.h
```

The call graph records direct call edges between functions. It is the local
foundation for later IPSCCP, inlining, argument promotion, dead argument
elimination, and attribute propagation.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Analysis/CallGraph.cpp
  llvm-project-22/llvm/include/llvm/Analysis/LazyCallGraph.h

LLVM entry points/classes:
  CallGraphWrapperPass
  CallGraph
  LazyCallGraph
  CGSCCAnalysisManager

Required analyses:
  Verified call IR.
  Function and declaration symbol lookup.

Required IR invariants:
  Direct calls must reference known declarations or definitions.
  Indirect calls remain unsupported in the local IR surface.

Core LLVM algorithm data structures:
  Per-function nodes.
  Caller-to-callee edges.
  CGSCC traversal for IPO passes.

Local target status:
  Direct-call graph foundation.
```

Implemented subset:

```text
one node per defined function
one node per declaration with no outgoing body edges
unique direct-call callee list per function
queries for calleesOf and hasDirectEdge
queries for definition/declaration/known-callee status
definition reachability from explicit root functions while ignoring declaration
leaves
```

Intentional divergences:

```text
no indirect-call nodes
declarations are represented as leaves, not as LLVM's external calling node
no SCC construction yet
no CGSCC pass manager
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  direct call graph unit test with duplicate direct calls
  root-reachability unit test that keeps definitions and excludes declarations

unit-test only:
  call graph construction and edge query
  declaration/definition classification
```
