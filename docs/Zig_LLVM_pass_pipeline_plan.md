# Zig LLVM Replacement Plan

Goal: reproduce in Zig all LLVM functionality that the Zig compiler currently uses, so Zig can eventually remove this LLVM dependency while preserving behavior, target support, debug information, optimization quality where required, and emitted binary correctness.

This is not an educational subset and not a line-for-line C++ port. LLVM remains the reference implementation. The replacement should be implemented as Zig compiler infrastructure, with tests proving equivalence against the current LLVM-backed Zig behavior.

## Scope

The initial scope is the LLVM functionality used by Zig's LLVM backend path:

```text
Zig AIR
  -> Zig LLVM backend lowering
  -> LLVM IR / bitcode
  -> LLVM optimization pipeline
  -> LLVM target code generation
  -> assembly / object / bitcode / LLVM IR output
  -> linker input
```

Concrete Zig source references:

*   `ziglang/src/codegen/llvm.zig`
*   `ziglang/src/codegen/llvm/FuncGen.zig`
*   `ziglang/src/codegen/llvm/bindings.zig`
*   `ziglang/src/zig_llvm.cpp`
*   `ziglang/src/zig_llvm.h`

Concrete LLVM source references:

*   `llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp`
*   `llvm-project-22/llvm/include/llvm/Passes/PassBuilder.h`
*   `llvm-project-22/llvm/lib/CodeGen/`
*   `llvm-project-22/llvm/lib/Target/`
*   `llvm-project-22/llvm/lib/MC/`

Out of initial scope unless explicitly added later:

*   Clang frontend replacement for `zig cc` / `zig c++`.
*   LLD replacement. Zig already has self-hosted linker work; this plan focuses on the LLVM compiler backend functionality.
*   libc++, libunwind, compiler-rt, sanitizer runtime implementation. The compiler hooks for sanitizer instrumentation are in scope.

## 1. Inventory Every LLVM API Zig Uses

Start by building a complete API inventory from:

```text
src/codegen/llvm/bindings.zig
src/zig_llvm.cpp
src/zig_llvm.h
```

Classify every dependency into one of these buckets:

```text
IR construction
target triple / data layout / ABI queries
target machine creation
CPU feature handling
optimization pipeline
analysis pipeline
LTO pipeline
sanitizer / coverage instrumentation
debug info validation and emission
bitcode parsing and writing
LLVM IR printing
assembly emission
object emission
archive support
host CPU detection
```

Deliverable:

```text
docs/inventory/zig_llvm_api_inventory.md
```

This document must list each Zig binding, the C++/LLVM function it reaches, the replacement component that will own it, and whether it is required for Debug, ReleaseFast, ReleaseSmall, LTO, tests, or tooling.

## 2. Define the Replacement Architecture

The replacement should be split into explicit compiler layers:

```text
src/ir/
  core IR used by optimization and codegen

src/passes/
  module, function, loop, and machine passes

src/analysis/
  dominators, loops, alias analysis, dataflow, call graph

src/target/
  target descriptions, ABI lowering, instruction selection, register info

src/codegen/
  machine IR, register allocation, scheduling, lowering, emission

src/mc/
  assembler, fixups, relocations, object writing

src/debug/
  DWARF / CodeView generation

src/bitcode/
  optional LLVM IR/bitcode compatibility layer for comparison and migration

src/tools/
  optimizer driver, IR dumper, pipeline explorer
```

The implementation should not depend on LLVM libraries.

## 3. Build an IR That Can Replace LLVM IR for Zig

The replacement IR must cover every construct Zig currently emits to LLVM:

```text
integers and arbitrary integer widths
floats and target-specific float support
pointers and address spaces
arrays, vectors, structs, packed structs
function types and calling conventions
globals and linkage
aliases
thread-local storage
atomics
volatile memory operations
inline assembly constraints
debug metadata
panic/error support data
comptime-generated constants
large aggregate constants
undefined/poison-like semantics where Zig needs them
```

The replacement IR must be LLVM-compatible at the semantic level. Internally it may use Zig-native data structures, but every construct needed by Zig's LLVM backend must have a precise mapping to LLVM IR semantics.

For debugging and equivalence testing, the IR must be able to import and print an LLVM-compatible form. This lets us compare pass-by-pass behavior against LLVM:

```text
Zig-produced pre.ll
  -> import into replacement IR
  -> run one replacement pass
  -> print LLVM-compatible IR
  -> compare with opt -passes=<same-pass>
```

Exact text does not need to match byte-for-byte, but normalized IR should match semantically: same CFG, same def-use graph, same types, same memory semantics, same attributes, and same observable behavior.

Deliverables:

```text
src/ir.zig
src/ir/print.zig
src/ir/verify.zig
src/ir/parser.zig
docs/ir.md
```

## 4. Reproduce LLVM's Pass Manager Functionality

LLVM reference:

```text
PassBuilder::buildO0DefaultPipeline
PassBuilder::buildPerModuleDefaultPipeline
PassBuilder::buildLTOPreLinkDefaultPipeline
PassBuilder::buildModuleSimplificationPipeline
PassBuilder::buildModuleOptimizationPipeline
PassBuilder::buildDefaultAAPipeline
```

Replacement requirements:

```text
ModulePassManager
FunctionPassManager
LoopPassManager
MachineFunctionPassManager
AnalysisManager
analysis invalidation
pipeline configuration
pass instrumentation
before/after IR dumps
pass timing
opt-bisect-style pass limiting
pipeline aliases: O0, O2/O3, Oz, LTO pre-link
```

Deliverables:

```text
src/pass_manager.zig
src/pipeline.zig
src/analysis/manager.zig
docs/pass_manager.md
```

## 5. Reproduce the Optimization Pipeline

The replacement must eventually cover the transformations Zig relies on in LLVM release builds. Start from LLVM's actual pipeline order, not from an invented order.

Core early simplification:

```text
InferFunctionAttrs
LowerExpect
SimplifyCFG
SROA
EarlyCSE
CallSiteSplitting
IPSCCP
CalledValuePropagation
GlobalOpt
Promote / mem2reg
InstCombine
```

Core optimization:

```text
inlining
function attribute propagation
global alias analysis
GVN / NewGVN equivalent
DSE
ADCE / DCE
LICM
LoopRotate
LoopDeletion
LoopUnswitch
LoopUnroll
LoopVectorize
SLPVectorizer
LoopSink
InstSimplify
DivRemPairs
TailCallElim
```

Size optimization:

```text
Oz policy
size-aware inlining
size-aware vectorization and unrolling decisions
merge functions if enabled
```

Sanitizer and coverage hooks:

```text
SanitizerCoverage
ThreadSanitizer instrumentation hooks used by Zig
san_cov_trace_pc_guard support
fuzzing instrumentation support
```

Deliverables:

```text
src/passes/*.zig
docs/passes/*.md
test/opt/*.zig
test/opt/*.ir
```

Every pass must have:

```text
LLVM source reference
Zig implementation file
before/after examples
correctness tests
known gaps
```

## 6. Reproduce Target Code Generation

LLVM codegen starts after IR optimization and lowers to target machine code. Replacing LLVM completely means implementing this path in Zig for every Zig target currently relying on LLVM.

Required codegen subsystems:

```text
target descriptions
ABI lowering
calling convention lowering
instruction selection
legalization
machine IR
register allocation
stack frame layout
prologue / epilogue insertion
instruction scheduling
branch relaxation
constant islands where needed
literal pools where needed
inline assembly lowering
atomic lowering
vector lowering
floating-point lowering
```

Target priority should follow Zig's practical needs:

```text
1. x86_64
2. aarch64
3. riscv64
4. wasm32/wasm64
5. arm/thumb
6. other LLVM-backed targets used by Zig release builds
```

Deliverables:

```text
src/target/x86_64/
src/target/aarch64/
src/target/riscv64/
src/codegen/mir.zig
src/codegen/regalloc.zig
src/codegen/isel.zig
docs/codegen.md
```

## 7. Reproduce MC, Assembly, and Object Emission

LLVM does not only optimize. Zig also uses LLVM to emit assembly and object files.

Replacement requirements:

```text
assembly syntax emission
machine code encoding
relocations
fixups
symbol tables
sections
COMDAT / weak / linkonce behavior
ELF object writing
Mach-O object writing
COFF object writing
Wasm object writing
DWARF relocation support
CodeView / PDB-related object records where needed
```

Deliverables:

```text
src/mc/encoder.zig
src/mc/asm.zig
src/object/elf.zig
src/object/macho.zig
src/object/coff.zig
src/object/wasm.zig
docs/object_emission.md
```

## 8. Reproduce Debug Info Support

Zig currently relies on LLVM for parts of debug metadata validation and emission on the LLVM path.

Replacement requirements:

```text
source file/line tracking
function debug info
local variable debug info
type debug info
DWARF generation
CodeView generation
debug info for optimized code
debug info verification tests
```

Deliverables:

```text
src/debug/dwarf.zig
src/debug/codeview.zig
docs/debug_info.md
test/debug_info/
```

## 9. Reproduce LTO and Bitcode-Relevant Behavior

Zig's current LLVM path supports LTO modes through LLVM's pipeline.

Replacement requirements:

```text
none / thin / full LTO modes
pre-link optimization pipeline
post-link optimization strategy
cross-module summary or equivalent
cross-module inlining strategy
global dead stripping support
bitcode-compatible migration artifacts if needed
```

This can be delayed until non-LTO object emission is correct.

## 10. Build Equivalence Tests Against LLVM

LLVM remains the oracle until the replacement is strong enough.

For each test:

1.  Compile with current Zig LLVM backend.
2.  Compile with the Zig replacement backend.
3.  Compare behavior.
4.  Compare ABI.
5.  Compare object/linker properties.
6.  Compare debug info when relevant.
7.  Compare performance for release-mode tests.

Test categories:

```text
behavior tests
ABI tests
compiler-rt tests
std tests
debug info tests
object format tests
optimization-specific tests
miscompilation regression tests
cross-target smoke tests
```

Deliverables:

```text
test/equivalence/
tools/compare_with_llvm.zig
docs/testing.md
```

## 11. Migration Strategy

The replacement should land as a parallel backend first.

Stages:

```text
stage 1: standalone z_llvm optimizer/codegen experiments
stage 2: compile selected tiny Zig functions
stage 3: compile Zig behavior tests for one target
stage 4: replace LLVM for Debug where native backend is missing
stage 5: replace LLVM for ReleaseFast on one target
stage 6: expand targets
stage 7: replace LLVM object/asm emission for supported targets
stage 8: replace LLVM LTO functionality
stage 9: remove mandatory libLLVM dependency for these paths
```

The backend must remain selectable while it is incomplete:

```text
-fllvm
-fno-llvm
-fzig-llvm-replacement
```

## First Milestone

The first milestone is not the final scope. It is the smallest useful slice of the complete replacement:

```text
parse a tiny internal IR
run a real pass manager
implement instcombine and dce
emit readable IR
compare against LLVM opt on equivalent examples
```

Deliverables:

```text
build.zig
src/main.zig
src/ir.zig
src/pass_manager.zig
src/passes/instcombine.zig
src/passes/dce.zig
test/inputs/instcombine.ir
docs/passes/instcombine.md
docs/inventory/zig_llvm_api_inventory.md
```

Example first transformation:

```text
input IR:
  %x = add %a, 0
  %y = mul %x, 1
  ret %y

after instcombine + dce:
  ret %a
```

## Long-Term Milestones

1.  Complete LLVM API inventory for Zig's current usage.
2.  Build the replacement IR and verifier.
3.  Build the pass manager and analysis manager.
4.  Reproduce the O0 pipeline.
5.  Reproduce the core O3 simplification pipeline.
6.  Reproduce the core O3 optimization pipeline.
7.  Implement x86_64 target codegen through object emission.
8.  Pass selected Zig behavior tests on x86_64.
9.  Add debug info support.
10. Add aarch64 target codegen.
11. Add riscv64 target codegen.
12. Add Wasm support.
13. Add LTO-equivalent functionality.
14. Pass the relevant Zig test matrix without LLVM for supported targets.
15. Remove or isolate libLLVM dependency for those compiler paths.
