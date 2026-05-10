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
print x86_64 AT&T-style addl/subl/andl/orl/xorl register forms
print local labels for the simple conditional-return subset
print testb and je for the simple conditional-return subset
print retq
```

Upstream mapping:

```text
LLVM's assembly printer emits MCInst streams, target directives, symbol attributes, alignment, debug/unwind data, and object-streamer events.
This project only prints normalized assembly text for the first tiny Machine IR subset.
The local printer is intentionally a text backend over the local Machine IR; the binary path uses a separate minimal encoder instead of an LLVM-like MCStreamer graph.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  add_args assembly text
  return_constant and return_arg assembly text
  bitwise_args assembly text
  conditional_return assembly text
```

Known gaps:

```text
no alignment directives
local labels only for simple function-local branch targets
no object streamer abstraction
no relocation printing
no debug or unwind directives
```
