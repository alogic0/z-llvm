# Direct Calls and Stack-Frame Codegen

This document tracks the call-codegen epic from the IR surface upward. The first
implemented slice is an LLVM-compatible IR contract only: declarations and direct
calls can be parsed, printed, verified, and carried conservatively through
existing analysis and optimizer passes. Machine call lowering is intentionally
not implemented yet.

## Upstream Mapping

Primary LLVM source references:

```text
llvm-project-22/llvm/include/llvm/IR/Function.h
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Verifier.cpp
llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp
llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td
llvm-project-22/llvm/lib/Target/X86/X86FrameLowering.cpp
```

Implemented classification:

```text
LLVM-aligned subset:
  direct function declarations
  direct call instruction spelling
  scalar integer/pointer call argument and return type verification
  void-call no-result rule

local-only conservative:
  calls are memory-effect unknown barriers for optimization legality
  only direct named callees are accepted
  call attributes beyond the tiny preserved calling-convention subset are rejected

bootstrap-only:
  no Machine IR call representation yet
  no x86_64 argument move lowering yet
  no call relocations or stack-frame emission yet
```

## Accepted IR Contract

Accepted declarations:

```llvm
declare i32 @callee(i32)
declare void @sink(i32)
```

Accepted calls:

```llvm
%r = call i32 @callee(i32 %a)
call void @sink(i32 %r)
```

The verifier requires the callee to be either a direct declaration or a direct
definition in the same module. Argument count and argument types must match the
callee signature. Non-void calls require a result name; void calls must not have
one.

## Rejected Surface

The first slice rejects:

```text
indirect calls
inline assembly calls
varargs
operand bundles
invoke
callbr
tail, musttail, and notail markers
unsupported call attributes
unsupported calling conventions
```

## Optimizer Legality

Calls are classified as unknown memory effects. This deliberately blocks DCE,
GVN, EarlyCSE, LICM, SROA, mem2reg, and SimplifyCFG from treating calls as pure
or movable while the project lacks alias/mod-ref and call-graph infrastructure.

This follows LLVM's shape around `CallBase`/`CallInst` and
`Instruction::mayReadOrWriteMemory`, but the local behavior is more
conservative until call attributes, memory effects, and target lowering are
modeled.

## Fixture Coverage

Current unit tests cover:

```text
function declaration parse/print/verify round trip
direct non-void call parse/print/verify round trip
direct void call parse/print/verify round trip
call signature mismatch rejection
indirect call rejection
tail-call marker rejection
invoke rejection
```

No `llc-22` fixture is required for this slice because it does not lower calls
to Machine IR yet. Later slices must compare accepted x86_64 call assembly and
relocations against LLVM or assembler output.
