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
initializerless external/extern_weak global declarations for observed pointer constants
aggregate undef global definitions for fixed array types
named aggregate global type prefixes, including quoted names with spaces or `=`
opaque aggregate global initializers for source-backed named aggregate constants
opaque C string constants for fixed i8 array globals
thread_local scalar global and constant definitions preserved as raw address attributes
known TLS model spellings preserved as raw address attributes
global suffix attributes preserved as raw text
function/global linkage: default, internal, private, external, extern_weak, weak
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
Scalar global definitions, source-backed declaration globals, aggregate undef
globals, and C string constants are preserved at module level. They are not yet
visible to load/store analysis, constant folding, linker resolution, or codegen
semantics beyond the documented GlobalDCE roots.
COMDAT records are preserved, references to modeled COMDAT records are verified,
and members are treated conservatively by GlobalDCE when referenced from raw
global/function attributes.
Thread-local globals are preserved and treated conservatively by GlobalDCE as
concurrency-visible roots.
```

Fixture coverage:

```text
opt-22 equivalent:
  globaldce_weak_root

local-only conservative:
  globaldce_comdat_root

unit-test only:
  module record round-trip
  function linkage and header attribute round-trip
  function visibility and parameter attribute round-trip
  function calling convention round-trip
  scalar global and constant global round-trip
  COMDAT record and module flag metadata round-trip
  unknown COMDAT reference rejection
  weak linkage round-trip
  extern_weak declaration global round-trip
  aggregate undef global round-trip
  C string global round-trip
  raw top-level module metadata round-trip
  unsupported aggregate global diagnostic
  void function and ret void verification
```

Known gaps:

```text
no ifunc globals
no general aggregate or string initializer decoding beyond source-backed
declarations, aggregate undef, and C string preservation
no TLS lowering model beyond preservation and conservative GlobalDCE rooting
no target-specific interpretation of TLS model spellings
no semantic use of globals in optimization or codegen
no semantic use of linkage, visibility, or attributes
no interpreted COMDAT selection semantics
no semantic use of calling conventions
attribute groups are preserved after limited sanitizer rejection
no interpreted module flags
no source filename escaping
```
