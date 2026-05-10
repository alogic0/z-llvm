# Machine IR Bootstrap

LLVM references:

```text
llvm-project-22/llvm/include/llvm/CodeGen/MachineFunction.h
llvm-project-22/llvm/include/llvm/CodeGen/MachineInstr.h
llvm-project-22/llvm/lib/CodeGen/GlobalISel/IRTranslator.cpp
llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp
```

Upstream entry points to check:

```text
MachineFunction
MachineInstr
IRTranslator
SelectionDAGBuilder
TargetLowering
TargetRegisterInfo
```

Implemented subset:

```text
x86_64-linux SysV only
one straight-line basic block
i32 leaf functions
return i32 constant
return register-passed i32 parameter
return add/sub/and/or/xor i32 of register-passed parameters
simple three-block conditional return with an i1 register-passed condition
void leaf return
machine labels and conditional branch to a local label
machine verifier for branch-label existence and return-register definition
explicit unsupported diagnostics for general branches, unsupported targets, unsupported types, stack-passed parameters, and unsupported instructions
```

Upstream mapping:

```text
This is a tiny analogue of LLVM's IR-to-machine lowering boundary.
LLVM lowers through SelectionDAG or GlobalISel, legalizes operations and types, selects target instructions, schedules, allocates registers, and preserves debug/metadata state.
This project currently uses a deterministic hand-lowered Machine IR only to prove the boundary from verified IR to target-specific assembly.
The local lowering is closer to a tiny SelectionDAG/GlobalISel result after instruction selection than to LLVM's full pre-register-allocation Machine IR.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; this is codegen bootstrap infrastructure

local-only conservative:
  general branches and unsupported register pressure fail explicitly

unit-test only:
  add_args lowering
  return_constant and return_arg lowering
  bitwise_args lowering
  conditional_return lowering
  x86_64 instruction encoding
  ELF relocatable metadata
  unsupported control-flow diagnostic
```

Known gaps:

```text
no calls
no stack-passed parameters
no spills
no general register allocation
no instruction scheduling
no memory operations
no general branch lowering
only simple conditional-return labels
only deterministic physical argument registers, no virtual-register allocator
```
