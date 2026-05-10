# ELF Object Writer Bootstrap

LLVM references:

```text
llvm-project-22/llvm/include/llvm/MC/MCObjectWriter.h
llvm-project-22/llvm/lib/MC/ELFObjectWriter.cpp
llvm-project-22/llvm/lib/MC/MCELFStreamer.cpp
llvm-project-22/llvm/lib/Target/X86/MCTargetDesc/X86MCCodeEmitter.cpp
```

Upstream entry points to check:

```text
MCObjectWriter
MCELFStreamer
ELFObjectWriter
MCCodeEmitter
X86MCCodeEmitter
```

Implemented subset:

```text
ELF64 little-endian relocatable object
x86_64 machine type
one .text section
.rela.text section for direct call relocations
.symtab with one global STT_FUNC symbol per emitted MachineFunction
.symtab undefined global symbols for external direct call targets
.strtab and .shstrtab
directly encoded local text bytes
R_X86_64_PLT32 relocations for direct callq operands with addend -4
```

Upstream mapping:

```text
LLVM routes selected machine instructions through MCInst, MCCodeEmitter,
MCStreamer, and MCObjectWriter. This project currently writes the smallest
ELF64 relocatable wrapper around already-encoded x86_64 bytes plus the first
call fixup subset. External direct calls map to the same relocation kind LLVM's
x86_64 ELF object writer selects for PLT-style direct calls.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; object bytes are local bootstrap output

local-only conservative:
  only direct call relocations are supported

unit-test only:
  ELF magic/class
  .text/.symtab section names
  global function symbol string
  objdump -dr fixtures for R_X86_64_PLT32 direct call relocations
```

Known gaps:

```text
no relocation kinds beyond R_X86_64_PLT32 direct calls
no external data symbols
no section symbols
no COMDAT, TLS, EH frame, unwind, or debug sections
no Mach-O or COFF
no linker integration
```
