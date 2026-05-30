# BDCE

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/BDCE.cpp
```

BDCE removes instructions whose computed bits are not demanded by any live use.

## LLVM Algorithm Contract

```text
LLVM source file:
  llvm-project-22/llvm/lib/Transforms/Scalar/BDCE.cpp

LLVM entry points/classes:
  BDCEPass::run
  DemandedBits
  KnownBits

Required analyses:
  DemandedBits and AssumptionCache in LLVM's implementation.

Required IR invariants:
  Verified scalar SSA.
  Bit-level liveness must preserve every externally observed value bit.

Core LLVM algorithm data structures:
  Per-instruction demanded-bit masks.
  KnownBits facts used to prove that some computations do not affect demanded
  output bits.

Local target status:
  fixture-equivalent for listed demanded-bit fixtures.
```

Implemented subset:

```text
Demanded low-bit cleanup for a narrow integer `and` mask chain:
  %wide = and iN %x, C1
  %narrow = and iN %wide, C2

When C2 demands only bits already preserved by C1 and `%wide` has one use, the
local pass rewrites `%narrow` to use `%x` directly and removes `%wide`.

Unused non-effecting instructions are removed to a fixed point because no bits
of their result are demanded.
```

Intentional divergences:

```text
No general demanded-bits lattice yet.
No KnownBits analysis, AssumptionCache, vector handling, poison-sensitive
reasoning, or multi-user propagation.
Only integer widths up to 64 bits are accepted in the current fixture-backed
rule.
No partial demanded-bits propagation beyond the accepted mask-chain rule and
whole-result unused cleanup.
```

Fixture coverage:

```text
opt-22 equivalent:
  bdce_and_mask
  bdce_unused_chain

local-only conservative:
  none currently

unit-test only:
  none currently
```
