# Assembly Printer Bootstrap

LLVM references:

```text
llvm-project-22/llvm/include/llvm/MC/MCStreamer.h
llvm-project-22/llvm/lib/MC/MCAsmStreamer.cpp
llvm-project-22/llvm/lib/Target/X86/X86AsmPrinter.cpp
```

Upstream entry points to check:

```text
AsmPrinter
X86AsmPrinter
MCStreamer
MCInstPrinter
```

Implemented subset:

```text
print .text
print .globl function symbols
print function labels
print x86_64 AT&T-style movl immediate/register forms
print x86_64 AT&T-style addl register form
print retq
```

Upstream mapping:

```text
LLVM's assembly printer emits MCInst streams, target directives, symbol attributes, alignment, debug/unwind data, and object-streamer events.
This project only prints normalized assembly text for the first tiny Machine IR subset.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  add_args assembly text
```

Known gaps:

```text
no alignment directives
no local labels
no branch labels
no object streamer
no relocations
no debug or unwind directives
```
