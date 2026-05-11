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
  fixture-equivalent for listed fixtures.
```

Implemented subset:

```text
function-local sparse lattice propagation
unknown, undef, constant, and overdefined lattice states
executable-block and executable-edge tracking
edge-sensitive PHI visitation that ignores unreachable incoming values
undef plus constant PHI resolution for covered scalar cases
supported scalar instruction visitor using the InstSimplify helper
select simplification where an overdefined condition still permits folding
identical constant arms
conditional branch edge marking and branch folding when the condition is constant
direct call folding when the callee is a known local function that always returns the same constant
FP instructions are treated as unknown/overdefined and preserved because the
local lattice has no FP constants or NaN/signed-zero model
```

Intentional divergences:

```text
no interprocedural propagation yet
no general call semantics yet
no poison/freeze-sensitive SCCP model beyond current scalar fixtures
no solver worklist partitioning matching LLVM's exact internal queues
IPSCCP is an explicit placeholder until call graph support exists
```

Fixture coverage:

```text
opt-22 equivalent:
  sccp_branch
  sccp_phi_edge
  sccp_undef_phi
  sccp_select_same_arms
  fp_sccp_preserve
  fp_extended_sccp_preserve

local-only conservative:
  none currently

unit-test only:
  pipeline inclusion and pass dispatch
  direct call to a constant-return function
```

Comparison command:

```bash
bash scripts/compare_opt.sh
```

Known gaps:

```text
no complete undef/poison lattice distinction
no constant range lattice
no FP constant lattice
no IPSCCP argument/return lattice summaries
no branch unreachable removal beyond what SimplifyCFG removes after SCCP
no IPSCCP
```
