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
GlobalVariable
GlobalVariable::isConstant
Function::getCallingConv
Function::getAttributes
```

Implemented subset:

```text
source_filename = "..."
target datalayout = "..."
target triple = "..."
$name = comdat <kind>
scalar global definitions: @name = [linkage] global iN <int-or-undef>
scalar constant global definitions: @name = [linkage] constant iN <int-or-undef>
thread_local scalar global and constant definitions preserved as raw address
attributes
global suffix attributes preserved as raw text
function linkage: default, internal, private, external
function visibility: default, hidden, protected
function calling conventions preserved: ccc, fastcc, coldcc
function header attributes preserved as raw text
parameter attributes preserved as raw text
void function return type
ret void
explicit parser errors for unsupported globals, declarations, and attribute groups
raw top-level module metadata preservation
raw module flag named metadata preservation
```

Upstream mapping:

```text
LLVM modules carry target identity, datalayout, source file names, globals, aliases, COMDATs, metadata, attributes, and module flags.
This project now parses and prints the first target records and raw top-level module metadata needed before Zig-emitted IR comparison can be honest.
The records are preserved and lightly validated; transforms do not consume most module-level semantics yet.
Function linkage and visibility are preserved for the first definition forms. Function and parameter attributes are parse-preserve-only metadata today.
Calling conventions are preserved in the function signature because they are ABI-relevant in LLVM, but this project does not lower or verify their target ABI effects yet.
Scalar global definitions are preserved at module level. They are not yet visible to load/store analysis, constant folding, or codegen.
COMDAT records are preserved and treated conservatively by GlobalDCE when
referenced from raw global/function attributes.
Thread-local globals are preserved and treated conservatively by GlobalDCE as
concurrency-visible roots.
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
  function visibility and parameter attribute round-trip
  function calling convention round-trip
  scalar global and constant global round-trip
  COMDAT record and module flag metadata round-trip
  raw top-level module metadata round-trip
  unsupported aggregate global diagnostic
  void function and ret void verification
```

Known gaps:

```text
no aggregate, string, ifunc, or declaration globals
no TLS lowering model beyond preservation and conservative GlobalDCE rooting
no semantic use of globals in optimization or codegen
no semantic use of linkage, visibility, or attributes
no interpreted COMDAT selection semantics
no semantic use of calling conventions
attribute groups are preserved after limited sanitizer rejection
no interpreted module flags
no source filename escaping
```
