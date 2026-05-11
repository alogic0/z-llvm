# Zig LLVM Replacement Plan

Goal: make this project useful to Zig's actual LLVM-removal path. The project
does this by inventorying the LLVM behavior Zig still relies on, reproducing
the smallest correct subsets in Zig, and producing fixtures, docs, and
implementation notes that can guide Zig's self-hosted compiler work.

This is not an educational subset, not a line-for-line C++ port, and not a
promise to clone all of LLVM before helping Zig. LLVM remains the oracle for
comparison while Zig's native backends remain the primary direction for final
code generation. This repository should stay aligned with
[roadmap/zig_aligned_llvm_removal_plan.md](roadmap/zig_aligned_llvm_removal_plan.md).

## Scope

The architectural scope is the LLVM functionality Zig still depends on, but the
implementation order is intentionally narrower:

```text
inventory Zig's real LLVM dependency
  -> build a Zig-emitted LLVM IR corpus
  -> preserve optimizer-visible semantics
  -> reproduce required optimizer slices
  -> study native-backend handoff points
  -> keep backend/MC/object work bounded as verification experiments
```

The LLVM-backed path being studied is still:

```text
Zig AIR -> Zig LLVM lowering -> LLVM IR/bitcode -> LLVM optimization
  -> LLVM target emission -> assembly/object/IR/bitcode output
```

However, this project should not assume the final answer is a parallel LLVM-like
backend. Where Zig already has native backend infrastructure, this project
should prefer handoff, fixtures, and semantic notes over duplicating that
backend work.

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

Status: the first inventory lives in [inventory/zig_llvm_api_inventory.md](inventory/zig_llvm_api_inventory.md). It shows that the current project is phase-zero optimizer infrastructure: useful IR and pass groundwork, but still much narrower than the full Zig LLVM dependency surface. New implementation cycles should start from that inventory before adding more familiar LLVM passes.

## 2. Define the Aligned Architecture

The project is split into explicit compiler layers, but each layer has a
different role in the Zig-aligned plan:

```text
src/ir/
  LLVM-compatible semantic model for comparison, migration, and optimizer tests

src/passes/
  Zig-needed optimizer slices selected from Zig's actual LLVM pipeline

src/analysis/
  shared analyses needed by those optimizer slices

src/target/
  target triples, DataLayout, ABI facts, and target hooks required by IR semantics

src/codegen/
  bounded backend experiments and handoff studies; not the primary replacement
  for Zig native backends

src/mc/
  bounded MC/object experiments used to understand LLVM responsibilities

src/debug/
  debug metadata/information only when tied to Zig-emitted fixtures

src/bitcode/
  optional LLVM IR/bitcode compatibility layer for comparison and migration

src/tools/
  optimizer driver, IR dumper, pipeline explorer
```

The implementation should not depend on LLVM libraries. LLVM tools and source
remain comparison references.

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
src/ir/core.zig
src/ir/printer.zig
src/ir/verifier.zig
src/ir/parser.zig
docs/ir.md
```

Status: `src/ir.zig` is now a compatibility facade over `src/ir/core.zig`. Parser, printer, and verifier extraction should be done in later focused steps after inventory-backed behavior is stable.

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
LLVM classes/functions used as reference entry points
Zig implementation file
before/after examples
correctness tests
known gaps
```

Future implementation steps must satisfy the upstream mapping rule in `docs/development_cycle.md` before their checkbox is marked complete.

## 6. Native Backend Handoff and Bounded Codegen

LLVM codegen starts after IR optimization and lowers to target machine code, but
Zig already has native backend work. This project should not default to
building a general competing backend. Its first job is to document what optimized
IR results can be represented in Zig-owned backend inputs and where LLVM
`TargetMachine.emitToFile` still covers behavior Zig needs.

Backend work in this repo is useful when it is one of:

```text
native-backend handoff research
tiny end-to-end optimizer validation
LLVM TargetMachine responsibility inventory
minimal ABI/object experiments
```

Full backend subsystems remain deferred unless a Zig-aligned need is documented:

```text
general instruction selection
general register allocation
scheduling
multi-target machine code generation
debug/unwind emission
full object/linker behavior
```

Deliverables:

```text
docs/roadmap/zig_native_backend_handoff_epic.md
docs/codegen/zig_native_backend_handoff.md
bounded fixtures under test/codegen/
```

## 7. MC, Assembly, and Object Emission as Verification Track

LLVM does not only optimize. Zig also uses LLVM to emit assembly and object
files. In this project, MC/object work is a secondary verification track unless
the Zig-aligned roadmap promotes it for a concrete reason.

Current bounded role:

```text
prove tiny optimized IR can lower to inspectable assembly/object output
study ABI, relocation, symbol, and object metadata boundaries
avoid generalizing into a full backend while optimizer/IR semantics are weaker
```

Deliverables:

```text
docs/roadmap/historical/mc_object_bootstrap_epic.md
docs/roadmap/historical/calls_and_stack_frame_codegen_epic.md
docs/mc/*.md
test/codegen/
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

The useful migration path for this project is a proof and handoff path, not a
parallel backend by default.

Stages:

```text
stage 1: inventory Zig's real LLVM APIs and pass pipelines
stage 2: build a Zig-emitted IR semantic corpus
stage 3: strengthen verifier and optimizer-visible semantics
stage 4: reproduce P0/P1 optimizer slices selected from Zig's pipeline
stage 5: document native-backend handoff options
stage 6: use bounded codegen/MC fixtures only as validation
stage 7: add optional LLVM IR/bitcode compatibility work if needed
stage 8: provide upstream-useful fixtures, gap tables, and algorithm notes
```

Any future compiler integration must remain optional while incomplete.

## First Milestone

The first milestone is not a backend. It is the smallest useful slice aligned
with Zig's LLVM removal:

```text
build and maintain inventories
capture tiny Zig-emitted LLVM IR fixtures
strengthen verifier correctness
run named optimizer slices selected from Zig's real LLVM pipeline
compare LLVM-equivalent fixtures against opt-22
```

Deliverables:

```text
docs/inventory/zig_llvm_api_inventory.md
docs/inventory/zig_llvm_pass_pipeline_inventory.md
docs/inventory/zig_emitted_ir_inventory.md
docs/roadmap/03_llvm_compatible_ir_verifier_foundation.md
test/zig/
test/opt/
```

## Long-Term Milestones

1.  Complete LLVM API inventory for Zig's current usage.
2.  Complete Zig LLVM pass-pipeline inventory.
3.  Build a Zig-emitted IR corpus.
4.  Strengthen IR semantics and verifier.
5.  Reproduce P0 canonicalization and stack-promotion behavior.
6.  Reproduce P1 scalar, memory, and loop foundations.
7.  Document native-backend handoff strategy.
8.  Use bounded codegen/MC experiments to validate optimizer outputs.
9.  Add debug, sanitizer, LTO, vector, and bitcode tracks only when selected by
    the Zig-aligned roadmap.
10. Produce fixtures and algorithm notes that can guide upstream Zig work.
