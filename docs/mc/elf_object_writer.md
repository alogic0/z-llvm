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
.symtab with one global STT_FUNC symbol per emitted MachineFunction
.strtab and .shstrtab
directly encoded local text bytes with no relocations
```

Upstream mapping:

```text
LLVM routes selected machine instructions through MCInst, MCCodeEmitter,
MCStreamer, and MCObjectWriter. This project currently writes the smallest
ELF64 relocatable wrapper around already-encoded x86_64 bytes.
```

Fixture coverage:

```text
opt-22 equivalent:
  none; object bytes are local bootstrap output

local-only conservative:
  no relocations or external references

unit-test only:
  ELF magic/class
  .text/.symtab section names
  global function symbol string
```

Known gaps:

```text
no relocations
no external symbols
no section symbols
no COMDAT, TLS, EH frame, unwind, or debug sections
no Mach-O or COFF
no linker integration
```
