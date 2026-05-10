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
  Placeholder.
```

Implemented subset:

```text
none
```

Intentional divergences:

```text
The local pipeline exposes a BDCE placeholder only. A real implementation waits
for known-bits or demanded-bits analysis.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  placeholder pass dispatch through named pipelines
```
