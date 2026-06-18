# x86_64 SysV ABI Bootstrap

LLVM references:

```text
llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td
llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp
llvm-project-22/llvm/lib/Target/X86/X86RegisterInfo.td
```

Upstream entry points to check:

```text
X86_64_SysV calling convention tables
X86TargetLowering::LowerFormalArguments
X86TargetLowering::LowerCall
X86TargetLowering::LowerReturn
X86FrameLowering::emitPrologue
X86FrameLowering::emitEpilogue
```

Implemented subset:

```text
i32 return value in %eax
i64 and pointer-class return values in %rax for selected rows
f32/f64 return values in %xmm0 for selected rows
first six integer/pointer-class register arguments are recognized as %edi, %esi, %edx, %ecx, %r8d, and %r9d for i32 values
i64/pointer-class arguments use the corresponding 64-bit GPR view for selected rows
f32/f64 arguments use the independent SysV SSE stream (%xmm0, %xmm1 for the current selected rows)
i1 branch conditions use the matching low 8-bit argument registers
i32/i64/pointer direct-call operands use the first-six integer argument register order
f32/f64 direct-call operands use the independent SSE register order
up to three constant i32 stack-passed direct-call arguments are supported
direct calls preserve SysV stack alignment by subtracting 8 from %rsp before callq and adding it back after the call
one live i32 caller argument can be spilled to (%rsp) across one call
the selected two-live-i32 direct-call shape spills %rdi/%rsi into a 24-byte aligned frame and reloads them after the call
one fixed i32 stack slot can be reloaded into %edi before a direct call
small INTEGER/INTEGER aggregates up to the selected 16-byte `{ i64, i64 }` class return in %rax/%rdx
selected small INTEGER/INTEGER aggregate argument field reads use the SysV integer register pair or stack field locations
the reusable aggregate classifier now distinguishes INTEGER, SSE, mixed INTEGER/SSE, and MEMORY classes for <=16-byte aggregates, with packed/unaligned and too-large aggregates classified as MEMORY
selected mixed INTEGER/SSE aggregate argument field reads use the independent SysV GPR/SSE streams
leaf functions only
no stack frame for register-only leaf functions
```

Call stack rule:

```text
On x86_64 SysV function entry, %rsp % 16 == 8 because the return address has already been pushed.
Immediately before a nested callq, the caller must make %rsp % 16 == 0.
The current project uses a local-only conservative sequence for tiny call fixtures:
  subq $8, %rsp
  callq callee
  addq $8, %rsp
For one live caller argument, the 8-byte alignment slot is also used as a deterministic spill slot.
For the `call_stack_slot` handoff proof, the same fixed slot holds an explicit
i32 alloca value and is reloaded into `%edi` before the direct call.
For the first broader ABI closure wave, a selected two-live-i32 call frame uses:
  subq $24, %rsp
  movq %rdi, 8(%rsp)
  movq %rsi, 16(%rsp)
  ... argument setup ...
  callq callee
  movq 8(%rsp), %rdi
  movq 16(%rsp), %rsi
  addq $24, %rsp
```

Register preservation boundary:

```text
Caller-saved set considered clobbered by calls in this slice:
  %rax, %rcx, %rdx, %rsi, %rdi, %r8, %r9, %r10, %r11
Callee-saved registers are not allocated by this project yet.
One live i32 argument register across one direct call is accepted generally.
The first two-live closure wave accepts the `%rdi`/`%rsi` selected shape.
Wider live sets and live values across multiple calls fail closed.
```

Upstream mapping:

```text
LLVM models x86_64 SysV calling conventions with target lowering tables and call-lowering code.
This project models the selected scalar register/stack assignments, the first
small INTEGER/INTEGER aggregate class, and the first selected MEMORY aggregate
sret/by-value forms needed by the release frontier. The aggregate classifier is
now reusable and records mixed INTEGER/SSE class decisions, but backend lowering
only accepts selected field-read/return forms.
LLVM often emits `pushq %rax`/`popq` around tiny calls at `-O0`; the local `subq`/`addq` sequence has the same stack-alignment purpose for the accepted fixtures.
```

First broader ABI closure wave:

```text
frontier_sysv_abi.Pair64 lowers as the selected small INTEGER/INTEGER class
aggregate return `{ i64, i64 }` uses %rax/%rdx
aggregate argument field 0/1 reads use the SysV integer register pair
the selected two-live-i32 direct-call frame spills and reloads %rdi/%rsi
frontier_sysv_sret_byval.Big3 lowers as the selected MEMORY class:
  `{ i64, i64, i64 }` return stores through the hidden sret pointer in %rdi
  user i64 args are shifted to %rsi/%rdx/%rcx
  first by-value stack aggregate field reads use 8(%rsp) and 24(%rsp)
frontier_sysv_aggregate_classes.Mixed proves the first mixed INTEGER/SSE
aggregate argument field reads:
  field `i64` is returned from the aggregate's GPR class register
  field `double` is returned from the aggregate's SSE class register
frontier_sysv_aggregate_classes.NestedPair proves nested INTEGER aggregate
field add chains:
  nested `{ i32, i32 }` fields are flattened by byte offset
  low/high 32-bit lanes are read from the SysV GPR pair without a
  function-name-specific backend path
frontier_sysv_aggregate_classes.ArrayPair proves array-in-struct INTEGER
aggregate sums:
  `[2]i64` pointer-element GEPs are lowered from typed AIR v2
  the two i64 fields are read from the SysV GPR pair
frontier executable probes validate the aggregate return/argument and call frame in ReleaseFast, ReleaseSafe, and ReleaseSmall
```

Known gaps:

```text
no callee-saved register saves
no full caller-saved clobber model beyond the selected one- and two-live i32 spill shapes
no varargs
no vectors
no full lowering for all classified SysV aggregate classes
no arbitrary MEMORY, X87, packed/unaligned, or complex aggregate ABI classes
no arbitrary sret/byval copy lowering
no indirect calls, tail calls, or unsupported non-default call conventions
no high-register-pressure spill/reload-heavy call frames
```
