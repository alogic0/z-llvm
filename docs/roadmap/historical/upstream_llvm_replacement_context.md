# Zig And LLVM Replacement Context

This note records the upstream direction that informed the original roadmap.
For present-day project decisions, see the [current proposal](../../next_steps.md)
and the [qualified compiler architecture](../../architecture.md).

Zig's goal is not to clone all of LLVM in one project before moving forward.
The direction is to remove LLVM, LLD, and Clang as hard libraries linked into
the main `zig` executable, while keeping optional or external paths where they
remain useful.

Useful references:

- Zig issue #16270, "make the main zig executable no longer depend on LLVM,
  LLD, and Clang libraries":
  <https://github.com/ziglang/zig/issues/16270>
- Zig issue #13265, "directly output LLVM bitcode rather than using LLVM's
  IRBuilder API":
  <https://github.com/ziglang/zig/issues/13265>
- Zig issue #20875, "`zig cc`, `zig c++`, `zig translate-c` and other
  subcommands without a clang/llvm dependency in the compiler binary":
  <https://github.com/ziglang/zig/issues/20875>
- Zig issue #20630, "move `@cImport` to the build system":
  <https://github.com/ziglang/zig/issues/20630>
- Zig 2025 devlog, "Self-Hosted x86 Backend is Now Default in Debug Mode":
  <https://ziglang.org/devlog/2025/>
- Zig 2026 devlog, "Incremental compilation with LLVM":
  <https://ziglang.org/devlog/2026/>
- Andrew Kelley and Loris Cro, "Zig's New Relationship with LLVM":
  <https://kristoff.it/blog/zig-new-relationship-llvm/>

## Upstream Direction

The public upstream direction can be summarized as:

```text
remove hard libLLVM/libLLD/libClang dependencies from the main zig executable
  -> use self-hosted Zig backends for fast/debug-oriented compilation
  -> keep LLVM IR/bitcode handoff possible without linking libLLVM
  -> replace LLD and Clang-adjacent tools separately
  -> improve Zig-owned optimization and codegen quality over time
```

This is a dependency-removal plan, not a single "rewrite LLVM" milestone.
LLVM can remain useful as an optional toolchain component while the core Zig
compiler becomes smaller, easier to bootstrap, faster for debug builds, and
better aligned with incremental compilation.

## How Zig Uses LLVM Today

Zig parses and semantically analyzes Zig code itself. The relevant internal
shape is:

```text
Zig source
  -> ZIR
  -> Sema
  -> AIR plus Liveness
  -> backend-specific lowering
```

The LLVM backend is one backend choice, not the whole compiler frontend. In the
local `../ziglang` checkout, the useful source anchors are:

| Zig source | Role |
| --- | --- |
| `ziglang/build.zig` | Build options such as `-Denable-llvm` and `-Dstatic-llvm`, plus LLVM/Clang/LLD wiring when enabled. |
| `ziglang/src/Compilation/Config.zig` | Chooses whether a compilation uses LLVM and whether libLLVM is available. |
| `ziglang/src/Compilation.zig` | Creates and flushes the LLVM object when the LLVM backend is active. |
| `ziglang/src/codegen/llvm.zig` | Lowers AIR to LLVM IR/bitcode and asks libLLVM to emit IR, bitcode, assembly, or object files. |
| `ziglang/src/codegen.zig` | Dispatches to the LLVM backend or self-hosted Zig backends. |
| `ziglang/src/Air.zig` | Typed, semantically checked IR consumed by codegen backends. |
| `ziglang/src/Air/Liveness.zig` | Liveness and death information consumed by native backends. |
| `ziglang/src/codegen/x86_64/` | Zig-owned x86_64 backend path. |
| `ziglang/src/link/` | Zig-owned linker/object placement paths. |

Short glossary:

- **ZIR**: source-level Zig IR produced from parsed Zig code.
- **Sema**: semantic analysis, type resolution, comptime execution, and
  declaration analysis.
- **AIR**: typed, analyzed function IR consumed by backends.
- **Liveness**: information about value deaths, block deaths, loop live-ins,
  and backend lowering safety.
- **MIR**: backend-specific machine IR used by Zig native backends.
- **LLVM IR / bitcode**: LLVM's IR, currently emitted by Zig's LLVM backend
  when that path is selected.

## Main Replacement Workstreams

### 1. Remove LLVM Library API Dependence

Issue #16270 tracks eliminating direct LLVM, LLD, and Clang library
dependencies from the main executable. Issue #13265 is one important LLVM-side
piece: generate LLVM bitcode directly instead of constructing modules through
LLVM's C++/C APIs.

That matters because Zig can keep an LLVM-compatible handoff artifact without
requiring the main compiler binary to link libLLVM. It also avoids being
limited by LLVM API gaps when Zig wants incremental behavior, such as removing
or updating declarations in a stored module.

Implication for this repository:

- Treat LLVM IR and bitcode compatibility as migration and comparison tracks.
- Do not require linking LLVM libraries for local optimizer experiments.
- Keep source-level inventories of Zig's current LLVM API and pass-pipeline
  use.

### 2. Self-Hosted Native Backends

The self-hosted native backends are the primary path for replacing LLVM as a
code generator. The 2025 Zig devlog states that the self-hosted x86_64 backend
became the default for Debug builds on Linux and macOS, with Windows still
blocked by COFF/linker work at that time.

Native backends lower Zig's own AIR and Liveness information toward
backend-specific MIR and emitted machine code. This is different from lowering
to LLVM IR and asking LLVM to optimize and emit object code.

Implication for this repository:

- Do not build a competing general backend here.
- Use local codegen/MC/object work only as validation or boundary study.
- Prefer documenting handoff points to Zig-owned AIR, Liveness, MIR, and linker
  behavior.

### 3. Incremental Compilation And In-Place Patching

LLVM is not designed around Zig's desired incremental model. Zig wants tight
control over frontend analysis, code generation, linker state, debug
information, and binary patching. The 2026 devlog also notes LLVM-backend
incremental improvements, while still observing that LLVM object emission time
remains LLVM-owned.

Implication for this repository:

- Optimizer and IR work should clarify which semantic facts survive handoff.
- Backend experiments should stay small unless they clarify incremental,
  debug, object, or linker boundaries.
- Avoid designing local object emission as the main replacement route.

### 4. Replace LLD And Clang-Adjacent Dependencies Separately

LLVM removal is broader than codegen. Issue #16270 includes LLD and Clang
dependencies. Issue #20875 describes moving `zig cc`, `zig c++`,
`translate-c`, and related Clang-backed utilities out of the main compiler
binary or into fetched/separate extras. Issue #20630 similarly moves
`@cImport` toward build-system-provided translate-c functionality.

Implication for this repository:

- Keep linker, archive, C frontend, Clang compatibility, and `zig cc` work out
  of the core optimizer roadmap.
- Inventory them only where they affect the LLVM backend boundary.
- Do not absorb LLD/Clang replacement into optimizer epics.

### 5. Improve Zig-Owned Optimization Quality Over Time

LLVM provides mature optimization quality. Zig's native backends prioritize
compile speed, debug usability, and control first. Release-quality optimization
parity is a long-term direction, not a prerequisite for every step in removing
LLVM as a hard dependency.

Implication for this repository:

- Implement optimizer behavior only when tied to Zig's real LLVM pipeline or a
  source-backed fixture.
- Start with semantic correctness and canonicalization before performance-only
  transforms.
- Compare LLVM-equivalent fixtures against LLVM 22.
- Document local conservative boundaries when LLVM is broader.

## What This Repository Should Do

This repository should help Zig's LLVM-removal path by producing:

- inventories of Zig's LLVM API and pass-pipeline use;
- real Zig-emitted LLVM IR fixtures from the current stage4 compiler;
- parser, verifier, and semantic docs for LLVM-compatible IR Zig emits;
- small optimizer replacements with `opt-22` comparison fixtures;
- conservative gap tables explaining where LLVM does more;
- native-backend handoff notes instead of duplicating Zig backends by default.

The aligned local path is:

```text
inventory
  -> Zig-emitted IR corpus
  -> verifier and semantic prerequisites
  -> P0/P1 optimizer slices
  -> native-backend handoff study
  -> bounded codegen/MC validation where useful
  -> optional bitcode/debug/LTO tracks when justified
```

This matches the current repository finish state: the accepted source-backed
optimizer corpus is clean, the remaining future rows are explicit boundaries,
and local backend/object work is validation-only.

## What This Repository Should Not Do

This repository should not:

- try to become a complete LLVM clone;
- replace Zig's AIR, Liveness, MIR, native backend, linker, or debug pipelines;
- implement broad register allocation, instruction scheduling, or target cost
  modeling without a source-backed need;
- treat LLD, Clang, `zig cc`, `translate-c`, or `@cImport` as optimizer work;
- claim full LLVM pass parity just because a same-named local pass exists.

The project can still implement LLVM-shaped algorithms, but the unit of work
must come from one of:

```text
a measured Zig-emitted IR blocker
a concrete opt-22 mismatch
a failing readiness check
a documented handoff question for Zig native backends
```

## Optimizer Priority

Replicating useful LLVM optimization behavior in Zig is less about copying
millions of lines of C++ and more about reproducing the semantic and pipeline
subsets Zig actually relies on.

The pass list must come from
[inventory/zig_llvm_pass_pipeline_inventory.md](../../inventory/zig_llvm_pass_pipeline_inventory.md),
not from a generic LLVM optimizer checklist.

Priority order:

1. Parser and verifier support for Zig-emitted LLVM IR.
2. Memory, side-effect, target, and DataLayout legality.
3. Mandatory canonicalization and correctness-preserving cleanup.
4. Source-backed scalar, memory, loop, global, and call optimizations.
5. Vector, FP, debug, sanitizer, LTO, and backend handoff work only when a
   measured source-backed row or opt comparison requires it.

The [LLVM reproduction levels](../llvm_algorithm_parity_gap_closure_plan.md#reproduction-levels)
define four statuses for optimizer passes.

```text
placeholder
LLVM-shaped subset
fixture-equivalent
algorithm-parity target
```

## How `z_llvm` Fits

`z_llvm` is not a direct Zig compiler. It consumes LLVM IR text:

```text
Zig source
  -> ../ziglang stage4 emits LLVM IR
  -> z_llvm parses/verifies/optimizes accepted IR
  -> optimized LLVM IR or tiny validation-only asm/object output
```

For arbitrary Zig programs, the missing work is complete backend and linker
correctness: instruction selection, register allocation, full ABI lowering,
stack frames, relocations, debug/unwind records, target support, and object
format behavior. Zig's native backends and linkers are the intended owners of
that path.

The valuable role of `z_llvm` is therefore:

```text
prove LLVM-compatible semantics for Zig-emitted IR
compare selected optimizer behavior with LLVM 22
record where local behavior is deliberately conservative
show which optimized facts are useful before native backend handoff
```

## Practical Workflow

Capture Zig-emitted LLVM IR from the authoritative stage4 compiler:

```sh
zig build capture-zig-ir -- test/zig/inputs/example.zig ReleaseFast x86_64-linux-gnu tmp/example.ll
```

Run the accepted local pipeline:

```sh
zig build -Doptimize=ReleaseFast

zig-out/bin/z_llvm \
  --passes=zig-release-fast-accepted \
  --input-limit=67108864 \
  tmp/example.ll > tmp/example.opt.ll
```

Verify the optimized IR:

```sh
zig-out/bin/z_llvm \
  --passes=verify \
  --pass-limit=0 \
  --quiet \
  --input-limit=67108864 \
  tmp/example.opt.ll
```

For tiny x86_64 validation-only cases:

```sh
zig-out/bin/z_llvm --emit=asm --target=x86_64-unknown-linux-gnu tmp/example.opt.ll > tmp/example.s
zig-out/bin/z_llvm --emit=obj --target=x86_64-unknown-linux-gnu tmp/example.opt.ll > tmp/example.o
```

That last step is not a general replacement backend. It exists to validate
small handoff facts when optimizer work needs object or assembly evidence.

## Current Local Finish Position

The current repository finish statement says the selected corpus and readiness
matrix are clean, with no unsupported rows in the finish corpus. The latest
accepted optimizer discovery sweeps across Debug, ReleaseFast, ReleaseSafe, and
ReleaseSmall completed with:

```text
candidates=1474
processed=1474
compile_skip=1009
emit_ok=465
local_ok=465
input_too_large=0
parse_fail=0
verify_fail=0
optimizer_fail=0
```

Future work should start only from
[roadmap/future_optimizer_backlog.md](../future_optimizer_backlog.md), a
new measured source-backed blocker, a concrete `opt-22` mismatch, or a failing
readiness check.
