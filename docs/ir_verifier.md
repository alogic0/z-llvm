# IR Verifier

The local verifier is the mandatory validity gate for the LLVM-compatible IR
subset accepted by this project. It is intentionally narrower than LLVM's full
verifier, but it follows the same role: reject malformed IR before optimizer
passes can silently reason from invalid SSA or CFG facts.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/IR/Verifier.cpp
  llvm-project-22/llvm/include/llvm/IR/Verifier.h

LLVM entry points/classes:
  llvm::verifyModule
  llvm::verifyFunction
  llvm::VerifierPass
  llvm::VerifierAnalysis
  Verifier::visitFunction
  Verifier::visitBasicBlock
  Verifier::visitPHINode
  Verifier::visitTerminator
  Verifier::visitCallBase

Required analyses:
  Local CFG predecessor matrix
  Local entry reachability
  Local dominator relation for the accepted SSA subset

Required IR invariants:
  Function definitions contain at least one block
  The function entry block has no predecessors
  Every basic block has one terminator
  Branch targets reference existing blocks
  Basic block labels are unique
  Non-phi instructions cannot appear before phi instructions in a block
  Phi incoming blocks are exact CFG predecessors
  Phi incoming blocks are unique
  Named SSA uses match the defining type
  Named SSA definitions dominate ordinary uses
  Same-block named SSA definitions appear before ordinary uses
  Phi incoming values are valid on the corresponding predecessor edge
  Direct calls reference known declarations or function definitions
  Direct call signatures and calling conventions match callee declarations or
  definitions
  Load/store memory attributes are valid for the local subset
  Atomic load/store, `atomicrmw`, `cmpxchg`, and fence orderings follow LLVM's
  verifier legality rules for the accepted IR surface
  Atomic scalar integer/floating-point access sizes are byte-sized powers of two
  `atomicrmw` operation names match the LLVM verifier's operand-type classes:
  `xchg` accepts integer/floating/pointer, FP operations accept FP types, and
  integer RMW operations require integer operands
  `cmpxchg` operands are integer or pointer typed
  Target triples and DataLayout strings are syntactically valid

Core LLVM algorithm data structures:
  Verifier work over Module, Function, BasicBlock, Instruction, PHINode, and
  Value use sites
  CFG predecessor checks for PHI nodes
  Dominance requirements for SSA values
  Type equality checks at use sites
  Declaration/function signature matching for calls

Local target status:
  LLVM-shaped algorithm subset

Implemented subset:
  Integer, ptr, and void types accepted by the parser
  Scalar binary/cast/freeze/icmp/select/phi instructions
  alloca/load/store/getelementptr instructions
  direct call instructions
  ret, ret void, br, conditional br, and unreachable terminators
  scalar globals, declarations, and function definitions

Intentional divergences:
  The local verifier rebuilds simple CFG and dominance matrices instead of
  using LLVM's DominatorTree infrastructure.
  It ignores pass-internal removed instruction tombstones because the local
  printer and pass pipeline treat them as deleted instructions.
  It validates target triple and DataLayout syntax, but does not verify full
  target ABI semantics, address-space-specific layouts, or GEP offset legality.
  It accepts pointer atomics without DataLayout-backed size checking and treats
  vector-pointer atomic access sizes as a current verifier boundary.
  It verifies a small known-DI-node debug metadata graph subset and keeps
  unknown metadata records opaque when references resolve.
  It does not verify full LLVM metadata semantics, debug salvage, attributes,
  poison semantics, or the full LLVM type system.
  It accepts only the parser-supported IR surface and rejects or never parses
  many LLVM constructs that LLVM's verifier can handle.

Analysis preservation/invalidation:
  The verifier does not mutate IR and preserves every analysis.
  The local pass manager currently reruns verification after each pass instead
  of preserving analysis instances across passes.

Fixture coverage:
  The normalized Zig-emitted tiny scalar fixture verifies.
  Unit tests cover accepted direct calls and declaration/function matching.
  Unit tests reject direct call signature mismatches.
  Unit tests reject direct call calling-convention mismatches.
  Unit tests reject use-before-def in one block.
  Unit tests reject SSA values that do not dominate merge-block uses.
  Unit tests reject phi incoming blocks that are not exact predecessors.
  Unit tests reject missing phi incoming predecessors.
  Unit tests reject phi nodes after non-phi instructions.
  Unit tests reject entry-block predecessors.
  Unit tests reject invalid non-power-of-two load/store alignment.
  Existing opt comparison fixtures exercise accepted verified IR before and
  after optimizer passes.

opt-22 comparison command:
  opt-22 -passes=verify <fixture.ll> -S -o /tmp/llvm_verify.ll

Local-only fixture command:
  zig build test
```

## Current Boundary

This verifier is a validity foundation, not a full reproduction of
`Verifier.cpp`. The important compatibility point is that optimizer slices now
start from LLVM-shaped SSA and PHI invariants for the IR this project accepts.
Future work should extend this document before broadening the IR surface or
promoting additional passes to LLVM-equivalent status.
