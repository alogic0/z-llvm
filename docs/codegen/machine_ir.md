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
return first or second i32 parameter
return add i32 of the first two parameter registers
void leaf return
explicit unsupported diagnostics for branches, unsupported targets, unsupported types, and unsupported instructions
```

Upstream mapping:

```text
This is a tiny analogue of LLVM's IR-to-machine lowering boundary.
LLVM lowers through SelectionDAG or GlobalISel, legalizes operations and types, selects target instructions, schedules, allocates registers, and preserves debug/metadata state.
This project currently uses a deterministic hand-lowered Machine IR only to prove the boundary from verified IR to target-specific assembly.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; this is codegen bootstrap infrastructure

local-only conservative:
  branches and unsupported register pressure fail explicitly

unit-test only:
  add_args lowering
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
no branches
no object emission
```
