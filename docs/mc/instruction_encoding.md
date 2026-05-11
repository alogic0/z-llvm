# x86_64 Instruction Encoding Bootstrap

LLVM references:

```text
llvm-project-22/llvm/include/llvm/MC/MCCodeEmitter.h
llvm-project-22/llvm/lib/Target/X86/MCTargetDesc/X86MCCodeEmitter.cpp
llvm-project-22/llvm/lib/Target/X86/X86InstrCompiler.td
```

Upstream entry points to check:

```text
MCCodeEmitter
X86MCCodeEmitter
X86InstrInfo
```

Implemented subset:

```text
mov imm32, %eax
mov r32, %eax for register-passed integer arguments
add/sub/and/or/xor r32, %eax
test r8, r8 for register-passed i1 conditions
near je rel32 to a local Machine IR label
retq
subq/addq 8-byte %rsp adjustment
movl r32, (%rsp) and movl (%rsp), r32 for one deterministic spill slot
movl (%rsp), %eax for one fixed local stack slot
callq rel32 placeholder bytes for ELF relocation
```

Upstream mapping:

```text
LLVM lowers MachineInstr to MCInst, then X86MCCodeEmitter encodes the selected
instruction using target tables and fixups. This project encodes only the tiny
selected Machine IR instruction set directly and resolves local labels before
ELF writing.
```

Native backend handoff classification:

```text
validation-only: direct encoding checks ABI, branch, call, and stack assumptions for tiny fixtures
out of scope: target-table-driven encoding, relaxation, scheduling, and broad instruction coverage
handoff doc: docs/codegen/zig_native_backend_handoff.md
```

Fixture coverage:

```text
opt-22 equivalent:
  none; instruction bytes are checked through local unit tests and objdump

local-only conservative:
  no relocations or fixups

unit-test only:
  add_args byte sequence
```

Known gaps:

```text
no ModRM/SIB memory forms
no general immediates beyond mov imm32 to eax
no short-branch relaxation
only callq fixups are modeled, through ELF .rela.text records
no VEX/EVEX, floating-point, vector, general call, general stack, or memory encodings
```
