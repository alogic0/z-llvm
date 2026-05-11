# dce

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/DCE.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp
llvm-project-22/llvm/lib/Analysis/ValueTracking.cpp
```

Upstream entry points to check:

```text
DCEPass::run
eliminateDeadCode
isInstructionTriviallyDead
wouldInstructionBeTriviallyDead
ADCEPass::run
Instruction::mayReadOrWriteMemory
```

This pass removes instructions whose results are unused and whose execution has no side effects.

Local target status:

```text
fixture-equivalent for listed fixtures
```

Implemented subset:

```text
mark values used by live instructions and terminators
remove unused pure add/sub/mul, fadd/fsub/fmul/fdiv/frem, icmp/fcmp, phi, alloca, and load instructions
keep store, volatile, atomic, and unknown memory instructions because the shared memory-effect API classifies them as side-effecting
use the shared `isSafeToDelete` helper rather than pass-local side-effect rules
iterate until no newly unused instructions remain
```

Upstream mapping:

```text
This reproduces local trivially-dead pure-instruction removal and the first memory side-effect rule through `analysis/memory_effect.zig`: unused nonvolatile loads can be removed, stores and memory barriers cannot.
LLVM's DCE uses richer side-effect and liveness checks through instruction semantics, memory effects, debug-info salvage, and ADCE for control-flow-sensitive removal.
```

Fixture coverage:

```text
opt-22 equivalent:
  dce
  memory_dce
  dce_scalar_with_memory
  dce_volatile_load_reject
  fp_dce_dead
  fp_extended_dce_preserve

local-only conservative:
  none currently

unit-test only:
  none currently
```

Example:

```text
before:
  %x = add i32 %a, 0
  %dead = mul i32 %x, 4
  ret i32 %x

after dce:
  %x = add i32 %a, 0
  ret i32 %x
```

Known gaps:

```text
no control-flow-sensitive liveness
no MemorySSA or alias-aware memory liveness
no volatile or atomic memory removal
no calls
no debug-info salvage
no aggressive DCE for unreachable control-flow
```
