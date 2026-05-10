# SCCP

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/SCCP.cpp
llvm-project-22/llvm/lib/Transforms/IPO/SCCP.cpp
```

SCCP propagates constants through SSA values while using control-flow
reachability to avoid treating unreachable incoming values as constraints.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/SCCP.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/SCCP.cpp

LLVM entry points/classes:
  SCCPPass::run
  IPSCCPPass::run
  SCCPSolver
  ValueLatticeElement

Required analyses:
  Function-local SCCP does not require a heavy analysis input for the current
  local subset. IPSCCP requires call-graph and argument/use information.

Required IR invariants:
  Verified scalar SSA and CFG.
  Replacement values must dominate their uses.

Core LLVM algorithm data structures:
  Lattice values for unknown, constant, and overdefined states.
  Executable-block worklist.
  SSA edge propagation.
  Branch condition simplification.

Local target status:
  LLVM-shaped algorithm subset.
```

Implemented subset:

```text
function-local scalar constant propagation using the InstSimplify helper
phi simplification when all incoming values are the same integer or undef
conditional branch condition replacement when the condition folds to a constant
```

Intentional divergences:

```text
no full lattice yet
no executable-edge pruning yet
no overdefined tracking yet
no interprocedural propagation yet
no call semantics yet
IPSCCP is an explicit placeholder until call graph support exists
```

Fixture coverage:

```text
opt-22 equivalent:
  sccp_branch

local-only conservative:
  none currently

unit-test only:
  pipeline inclusion and pass dispatch
```

Comparison command:

```bash
bash scripts/compare_opt.sh
```

Known gaps:

```text
no edge-sensitive phi filtering
no executable block worklist
no undef/poison lattice distinction
no branch unreachable marking beyond what SimplifyCFG removes after SCCP
no IPSCCP
```
