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

Optional-track docs:

```text
docs/semantics/optional_bitcode_debug_lto_tracks.md
docs/debug/metadata_inventory.md
```

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
parse and print opaque instruction !dbg attachments
preserve branch metadata attachments such as !prof as opaque text
preserve declared opaque panic/runtime calls as side-effecting call barriers in
reduced ReleaseSafe safety fixtures
reject llvm.dbg.value, llvm.dbg.declare, and llvm.dbg.assign with
UnsupportedDebugIntrinsic until debug-value salvage is represented
reject sanitizer/TSan/UBSan/trap instrumentation calls until runtime semantics
are modeled
add-discriminators, annotation2metadata, annotation-remarks, sancov,
module-tsan, tsan, alloc-token, and ee-instrument are executable placeholders
```

Intentional divergences:

```text
no interpretation of debug location attachment graphs
no metadata graph interpretation
no sanitizer runtime declarations or inserted callbacks
no panic/runtime lowering semantics beyond opaque declared calls
no TSan memory instrumentation
no entry/exit call insertion
no debug value salvage, assignment tracking, or discriminator updates
no UBSan or trap-call lowering semantics
```

Fixture coverage:

```text
opt-22 equivalent:
  ReleaseSafe dynamic safety branch with an opaque runtime call compared for
  ADCE and SimplifyCFG preservation

local-only conservative:
  raw module metadata round-trip unit test
  reduced Debug metadata round-trip fixture
  reduced ReleaseSafe safety branch fixture with branch-weight metadata
  reduced ReleaseSafe runtime-call boundary corpus fixture

unit-test only:
  instrumentation placeholder pass dispatch
  debug value intrinsic rejection until metadata operands and salvage exist
  sanitizer/trap instrumentation call rejection
```
