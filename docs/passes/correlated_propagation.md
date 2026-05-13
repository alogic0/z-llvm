# correlated-propagation

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp
llvm-project-22/llvm/lib/Analysis/LazyValueInfo.cpp
```

Upstream entry points to check:

```text
CorrelatedValuePropagationPass::run
runImpl
processCmp
constantFoldCmp
LazyValueInfo::getPredicateAt
LazyValueInfo::getPredicateOnEdge
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp
  llvm-project-22/llvm/lib/Analysis/LazyValueInfo.cpp

LLVM entry points/classes:
  CorrelatedValuePropagationPass
  processCmp
  LazyValueInfo
  ValueLatticeElement
  ConstantRange

Required analyses:
  LazyValueInfo-shaped predicate facts.
  DominatorTree-backed edge fact scope.

Required IR invariants:
  Verified SSA, branch targets, and integer `icmp` operand types.
```

Local target status:

```text
LLVM-shaped subset for dominating branch-implied icmp facts
```

Implemented subset:

```text
If a dominating branch proves `icmp <pred> %x, C` true on the only incoming
edge to a block, repeated matching `icmp` instructions in that block or blocks
dominated by it are replaced with `true`. Repeated inverse predicates are
replaced with `false`.
```

Known missing behavior:

```text
No select, PHI, switch, assume, guard, overflow intrinsic, min/max intrinsic,
division, shift, sext/zext/trunc, or range tightening.
No ConstantRange/ValueLatticeElement implementation.
No multi-predecessor edge-sensitive fact joins.
No metadata or debug salvage beyond removing the folded instruction.
```

Fixture coverage:

```text
correlated_propagation_icmp_eq
correlated_propagation_multipred_reject
```

opt-22 comparison command:

```bash
bash scripts/compare_opt.sh test/opt/fixtures.tsv
```
