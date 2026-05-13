# jump-threading

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/JumpThreading.cpp
```

Upstream entry points to check:

```text
JumpThreadingPass::run
JumpThreadingPass::runImpl
JumpThreadingPass::processBlock
JumpThreadingPass::processBranchOnPHI
JumpThreadingPass::processThreadableEdges
JumpThreadingPass::tryThreadEdge
JumpThreadingPass::threadEdge
JumpThreadingPass::duplicateCondBranchOnPHIIntoPred
addPHINodeEntriesForMappedBlock
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/JumpThreading.cpp

LLVM entry points/classes:
  JumpThreadingPass
  processBlock
  processBranchOnPHI
  processThreadableEdges
  tryThreadEdge
  threadEdge
  duplicateCondBranchOnPHIIntoPred
  addPHINodeEntriesForMappedBlock

Required analyses:
  DominatorTree for loop-header/backedge rejection.
  Local CFG predecessor/successor graph.
  PHI translation for values flowing through the threaded block.

Required IR invariants:
  Verified branch targets, PHI incoming predecessor validity, and SSA
  dominance for the accepted IR subset.

Core LLVM algorithm data structures:
  predecessor-known condition values
  predecessor-to-destination list
  CFG edge rewrite/update helper
  PHI value mapping for the new predecessor edge
```

Local target status:

```text
LLVM-shaped subset for branch-on-PHI predecessor constants
```

Implemented subset:

```text
br i1 %p, label %then, label %else
%p = phi i1 [ 1, %pred_true ], [ 0, %pred_false ]

When a predecessor reaches the branch block through an unconditional branch and
the PHI incoming value from that predecessor is an integer constant, the local
pass retargets that predecessor to the known successor.
```

The pass updates destination PHIs by adding an incoming value for the new
predecessor edge. If the successor PHI uses a value defined by a PHI in the old
branch block, the incoming value is translated through the predecessor-specific
PHI entry, mirroring the category of work LLVM performs in
`addPHINodeEntriesForMappedBlock`.

Intentional missing behavior:

```text
No block duplication.
No LazyValueInfo, AssumptionCache, ConstantFold, or generic PHI translation.
No switch or indirectbr threading.
No profile metadata or branch probability updates.
No loop-header threading.
No debug-location salvage for duplicated instructions.
```

Fixture coverage:

```text
jump_threading_phi_const
jump_threading_non_phi_reject
```

opt-22 comparison command:

```bash
bash scripts/compare_opt.sh test/opt/fixtures.tsv
```
