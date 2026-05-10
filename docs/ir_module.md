# Module-Level IR

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Module.h
llvm-project-22/llvm/lib/IR/AsmWriter.cpp
llvm-project-22/llvm/lib/AsmParser/LLParser.cpp
```

Upstream entry points to check:

```text
Module::getSourceFileName
Module::getTargetTriple
Module::getDataLayout
Module::setTargetTriple
Module::setDataLayout
LLParser::parseTargetDefinition
GlobalValue::getLinkage
Function::getAttributes
```

Implemented subset:

```text
source_filename = "..."
target datalayout = "..."
target triple = "..."
function linkage: default, internal, private, external
function header attributes preserved as raw text
void function return type
ret void
explicit parser errors for unsupported globals, declarations, attribute groups, and module metadata
```

Upstream mapping:

```text
LLVM modules carry target identity, datalayout, source file names, globals, aliases, COMDATs, metadata, attributes, and module flags.
This project now parses and prints the first target records needed before Zig-emitted IR comparison can be honest.
The records are preserved and lightly validated; transforms do not consume most module-level semantics yet.
Function linkage is preserved for the first definition forms. Function header attributes are parse-preserve-only metadata today.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  module record round-trip
  function linkage and header attribute round-trip
  unsupported global diagnostic
  void function and ret void verification
```

Known gaps:

```text
no globals
no visibility parsing
no parameter attributes
no attribute group parsing
no module flags
no metadata
no source filename escaping
```
