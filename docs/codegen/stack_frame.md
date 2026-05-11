# Stack Frame Bootstrap

This document tracks the first local x86_64 stack-frame subset. It is a
bootstrap frame model, not general alloca lowering.

## Upstream Mapping

Primary LLVM source references:

```text
llvm-project-22/llvm/lib/Target/X86/X86FrameLowering.cpp
llvm-project-22/llvm/lib/Target/X86/X86RegisterInfo.td
llvm-project-22/llvm/lib/Target/X86/X86InstrInfo.cpp
```

Relevant LLVM concepts:

```text
MachineFrameInfo
TargetFrameLowering
TargetRegisterInfo
frame indexes
emitPrologue
emitEpilogue
```

Implemented classification:

```text
local-only conservative:
  no frame pointer
  no red zone
  one fixed 8-byte %rsp-relative slot
  explicit Machine IR frame-index operand for slot0
  only i32 alloca/store/load/return pattern
  one i32 alloca/store/load feeding the first direct-call argument

bootstrap-only:
  no general frame-index allocator yet
  no dynamic alloca
  no stack realignment
  no callee-saved spills
  no unwind or debug frame records
```

## Accepted Shape

The first accepted frame fixture is:

```llvm
%slot = alloca i32
store i32 %a, ptr %slot
%v = load i32, ptr %slot
ret i32 %v
```

It lowers to:

```asm
subq $8, %rsp
movl %edi, (%rsp)
movl (%rsp), %eax
addq $8, %rsp
retq
```

The slot is intentionally fixed at `(%rsp)` after the prologue adjustment.
The Machine IR carries an explicit `slot0` frame-index operand, but only that one
slot is legal today. Multiple slots, slot coloring, callee-saved areas, and
outgoing call-argument areas are still out of scope.

Cycle 07 adds a handoff proof where the fixed slot feeds a direct call:

```llvm
%slot = alloca i32
store i32 %a, ptr %slot
%v = load i32, ptr %slot
%r = call i32 @callee(i32 %v)
ret i32 %r
```

The same `subq $8, %rsp` adjustment both creates the fixed slot and satisfies
the x86_64 SysV pre-call alignment rule.

## Fixture Coverage

```text
unit-test only:
  stack_slot assembly fixture
  stack_slot objdump fixture
  call_stack_slot assembly fixture
  call_stack_slot objdump/readelf fixture
```
