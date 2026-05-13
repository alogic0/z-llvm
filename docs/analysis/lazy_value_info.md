# Lazy Value Info

LLVM reference:

```text
llvm-project-22/llvm/lib/Analysis/LazyValueInfo.cpp
llvm-project-22/llvm/include/llvm/Analysis/LazyValueInfo.h
```

Upstream entry points to check:

```text
LazyValueInfo::getPredicateAt
LazyValueInfo::getPredicateOnEdge
LazyValueInfo::getConstantOnEdge
LazyValueInfoImpl::getValueFromCondition
LazyValueInfoImpl::getValueFromICmpCondition
LazyValueInfoImpl::getEdgeValueLocal
```

Local target status:

```text
LLVM-shaped fact-table subset for CorrelatedValuePropagation
```

Implemented subset:

```text
br i1 %cmp, label %then, label %else
%cmp = icmp <pred> iN %x, C
```

For a conditional branch whose condition is a same-block integer `icmp` between
a named value and an integer constant, the local fact table records:

```text
then edge: <pred>(%x, C)
else edge: inverse(<pred>)(%x, C)
```

The fact is propagated only into the edge target and blocks dominated by that
target when the target has exactly one predecessor. This avoids pretending that
edge-specific facts are valid at joins reached from other predecessors.

Known missing behavior:

```text
No ValueLatticeElement range lattice.
No PHI, select, assume, guard, switch, cast, binary-op, intrinsic, or
ConstantRange reasoning.
No edge facts for multi-predecessor targets.
No cache invalidation beyond rebuilding the table per pass run.
```

Fixture coverage:

```text
correlated_propagation_icmp_eq
correlated_propagation_multipred_reject
```
