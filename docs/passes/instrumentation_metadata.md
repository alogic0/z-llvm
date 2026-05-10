# Instrumentation, Sanitizers, And Metadata

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Utils/AddDiscriminators.cpp
llvm-project-22/llvm/lib/Transforms/IPO/Annotation2Metadata.cpp
llvm-project-22/llvm/lib/Transforms/Instrumentation/SanitizerCoverage.cpp
llvm-project-22/llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp
llvm-project-22/llvm/lib/Transforms/Utils/EntryExitInstrumenter.cpp
```

These passes attach, preserve, or consume optimizer-visible debug/profile and
instrumentation metadata. They are separate from scalar optimization because
they have runtime, debug-info, and sanitizer ABI consequences.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Utils/AddDiscriminators.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/Annotation2Metadata.cpp
  llvm-project-22/llvm/lib/Transforms/Instrumentation/SanitizerCoverage.cpp
  llvm-project-22/llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/EntryExitInstrumenter.cpp

LLVM entry points/classes:
  AddDiscriminatorsPass::run
  Annotation2MetadataPass::run
  SanitizerCoveragePass::run
  ModuleThreadSanitizerPass::run
  ThreadSanitizerPass::run
  EntryExitInstrumenterPass::run

Required analyses:
  Debug metadata and module flags.
  Sanitizer runtime ABI configuration.
  Target and object-format lowering facts.

Required IR invariants:
  Instrumentation must preserve verifier-clean IR.
  Debug/profile metadata must be preserved or deliberately dropped with a
  documented diagnostic.
  Sanitizer passes must not run unless their runtime hooks are represented.

Core LLVM algorithm data structures:
  Module metadata records.
  Debug locations and discriminators.
  Sanitizer coverage options and inserted callback calls.
  ThreadSanitizer memory-access instrumentation.

Local target status:
  Raw module metadata preservation plus executable placeholders.
```

Implemented subset:

```text
parse and print raw top-level module metadata records beginning with !
add-discriminators, annotation2metadata, annotation-remarks, sancov,
module-tsan, tsan, alloc-token, and ee-instrument are executable placeholders
```

Intentional divergences:

```text
no debug location attachment to instructions
no metadata graph interpretation
no sanitizer runtime declarations or inserted callbacks
no TSan memory instrumentation
no entry/exit call insertion
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  raw module metadata round-trip unit test

unit-test only:
  instrumentation placeholder pass dispatch
```
