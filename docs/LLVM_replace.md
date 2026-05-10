Zig and LLVM have a complex, "it's complicated" relationship. While Zig was originally built on top of LLVM, the project is currently in the middle of a "divorce" to gain independence, speed, and better control over the compilation process.

Here is the breakdown of how the Zig compiler interacts with LLVM.

---

## Concrete places in the Zig source

The current Zig checkout at `/home/oleg/prog/ziglang` shows LLVM as an optional backend selected during compilation configuration, not as the whole compiler frontend.

*   **Build-time LLVM support:** `/home/oleg/prog/ziglang/build.zig`
    *   `build.zig:111-112` defines `-Dstatic-llvm` and `-Denable-llvm`.
    *   `build.zig:314-347` wires LLVM/Clang/LLD into the compiler build, either through CMake-provided configuration or the static LLVM library list.
*   **The compilation flags:** `/home/oleg/prog/ziglang/src/Compilation/Config.zig`
    *   `Compilation/Config.zig:37-43` documents `use_llvm` and `use_lib_llvm`.
    *   `Compilation/Config.zig:190-198` decides whether libLLVM is available and should be used.
    *   `Compilation/Config.zig:317-366` decides whether this compilation should use the LLVM backend. Important cases are: LLVM is required for `emit_llvm_ir` / `emit_llvm_bc`, rejected if the target is unsupported by LLVM, preferred for release builds, and avoided for debug builds when a self-hosted backend is robust enough.
*   **Creating the LLVM backend object:** `/home/oleg/prog/ziglang/src/Compilation.zig`
    *   `Compilation.zig:2478-2480` creates `zcu.llvm_object = LlvmObject.create(...)` when `use_llvm` is true.
*   **Lowering Zig code into LLVM:** `/home/oleg/prog/ziglang/src/Zcu/PerThread.zig` and `/home/oleg/prog/ziglang/src/codegen/llvm.zig`
    *   `Zcu/PerThread.zig:4590-4596` says the LLVM backend is special: it does codegen but does not produce MIR for Zig's own linker pipeline.
    *   `codegen/llvm.zig:588-604` initializes the LLVM `Object` and LLVM module builder with the target triple and data layout.
    *   `codegen/llvm.zig:1135-1141` is the start of `updateFunc`, where a Zig function's AIR is lowered into the LLVM object.
*   **Emitting the final object / assembly / IR / bitcode:** `/home/oleg/prog/ziglang/src/Compilation.zig` and `/home/oleg/prog/ziglang/src/codegen/llvm.zig`
    *   `Compilation.zig:3323-3370` calls `llvm_object.emit(...)` during flush and passes paths for object output, assembly, LLVM IR, and bitcode.
    *   `codegen/llvm.zig:970-982` requires libLLVM for final emission, initializes the LLVM target, creates an LLVM context, and parses Zig-produced bitcode.
    *   `codegen/llvm.zig:1120-1124` calls `target_machine.emitToFile(...)`, which is the handoff to LLVM for emitting machine output.
*   **Backend dispatch:** `/home/oleg/prog/ziglang/src/codegen.zig`
    *   `codegen.zig:43-56` maps `.stage2_llvm` to `codegen/llvm.zig` and maps the self-hosted backends to their own Zig files.

In short: Zig parses and semantically analyzes Zig code itself, lowers functions into AIR, and then either sends that code through LLVM (`src/codegen/llvm.zig`) or through a self-hosted backend (`src/codegen/x86_64`, `src/codegen/aarch64`, `src/codegen/riscv64`, `src/codegen/wasm`, etc.).

---

## 1. The Multi-Backend Strategy
The modern Zig compiler (the "self-hosted" compiler) uses a tiered system for generating code. It doesn't rely on LLVM for everything anymore.

*   **The LLVM Backend:** Still used for **Release builds**. It provides world-class optimizations that have been refined for decades. Zig lowers its analyzed compiler IR into an LLVM module/bitcode path in `src/codegen/llvm.zig`, then asks libLLVM to emit the final object, assembly, IR, or bitcode.
*   **Native Backends (x86_64, ARM, etc.):** Used for **Debug builds**. Zig has its own machine-code emitters for major architectures. These are much faster than LLVM because they skip heavy optimization passes.
*   **The C Backend:** Zig can transpile Zig code into C code, allowing it to run on any platform that has a C compiler (even those not supported by LLVM).
*   **The Wasm Backend:** Direct emission of WebAssembly.



---

## 2. Why is Zig moving away from LLVM?
While LLVM is powerful, the Zig team identified several major drawbacks that hindered the language's goals:

| Issue | Impact on Zig |
| :--- | :--- |
| **Compile Speed** | LLVM is notoriously slow. In older versions of Zig, LLVM accounted for nearly **70-90%** of total compilation time. |
| **Binary Size** | Linking against LLVM makes the Zig executable massive (often over 150 MiB). Without it, the compiler is closer to 5-10 MiB. |
| **Memory Usage** | LLVM is a memory hog. Building Zig with LLVM can require 8GB+ of RAM; the self-hosted version uses significantly less. |
| **Incremental Builds** | Zig's "killer feature" is sub-millisecond incremental compilation (patching only the changed bytes in a binary). LLVM wasn't designed for this level of granularity. |

---

## 3. The `zig cc` and `zig c++` Magic
Even as Zig distances itself from LLVM for its own core, it still **bundles** parts of LLVM (specifically Clang and LLD). This allows Zig to act as a powerful, zero-dependency C/C++ compiler.

When you run `zig cc`, you are essentially using a version of Clang that is pre-configured to be:
*   **Cross-platform by default:** You can target Windows from Linux without installing a massive cross-compilation toolchain.
*   **Self-contained:** It includes all the necessary headers and libraries for different OSs and architectures in a single 50MB download.

---

## 4. The Future: "The LLVM Divorce"
The goal is to remove LLVM as a **hard dependency**. In the future, the core `zig` binary will not contain LLVM code. Instead, if you want to use the LLVM backend for a high-performance release build, Zig will likely interface with an external LLVM installation or use a "side-car" library.

This keeps the core compiler "small and light" for development while keeping the "heavy machinery" available when you're ready to ship production code.

Replacing LLVM is a massive engineering undertaking because LLVM provides three things that are incredibly difficult to replicate: **Target Support** (ARM, x86, RISC-V, etc.), **State-of-the-art Optimization**, and **Industrial-grade Linkers**.

To replace it, you have to rebuild the "Back End" of the compiler from scratch. Here is how that is currently being done, using the "Zig model" as the primary blueprint.

---

## 1. Implement "Native" Backends
The first step is to write code emitters that translate your language directly into machine code (hex bytes) for specific CPUs, bypassing LLVM IR entirely.
*   **Debug-First Strategy:** Instead of trying to beat LLVM’s optimizations (which take decades to perfect), you build a "fast and dirty" backend for development. This generates unoptimized code but does it 10x faster than LLVM.
*   **Architecture Support:** You have to manually write the logic for how each instruction (like `MOV` or `ADD`) is encoded for x86_64, AArch64, etc.

## 2. Build a Custom Linker
LLVM usually relies on `lld` (the LLVM linker) to combine object files into an executable. If you want a full "divorce," you must build your own:
*   **ELF/Mach-O/PE Linkers:** You need code that understands how to package the machine code into the specific formats used by Linux, macOS, and Windows.
*   **Incremental Linking:** One of the biggest reasons to replace LLVM is to support **In-place Binary Patching**. A custom linker can change a single function in an existing `.exe` without re-scanning the entire project, leading to sub-millisecond rebuilds.

## 3. Use "Tiered" Optimization
Replacing LLVM's optimizer (which has thousands of passes like Dead Code Elimination and Loop Unrolling) is the hardest part. The transition usually follows these stages:
1.  **Stage 0:** No optimization (Straight-to-machine-code for debug builds).
2.  **Stage 1:** Simple, local optimizations (Constant folding, basic register allocation).
3.  **Stage 2:** External tools. Instead of linking against the LLVM library, you output **LLVM IR text files** and call an external LLVM process to optimize them. This removes the "bloat" of LLVM from your compiler while keeping the performance.

---

## 4. Alternative "Lighter" Backends
If you don't want to write raw machine code but want to avoid LLVM's complexity, many modern projects look at these alternatives:

| Alternative | Description | Why use it? |
| :--- | :--- | :--- |
| **C Backend** | Transpile your language to C. | Let `gcc` or `clang` handle the heavy lifting. Portable to almost every chip ever made. |
| **Cranelift** | A WebAssembly-focused compiler backend (used by Rust for fast debug builds). | Much faster than LLVM and written in Rust. Designed for JIT and AOT. |
| **QBE** | A small C-style backend. | Extremely simple (only ~10k lines of code) compared to LLVM's millions. |

## Current Status (2026)
As of early 2026, the Zig project has largely succeeded in this "divorce." For **Debug builds**, Zig now defaults to its own native x86_64 and ARM backends, which is why it has become one of the fastest compilers in existence. For **Release builds**, it still uses LLVM as an optional "heavyweight" optimizer to ensure the final code is as fast as possible.

Replacing LLVM is a massive engineering undertaking because LLVM provides three things that are incredibly difficult to replicate: **Target Support** (ARM, x86, RISC-V, etc.), **State-of-the-art Optimization**, and **Industrial-grade Linkers**.

To replace it, you have to rebuild the "Back End" of the compiler from scratch. Here is how that is currently being done, using the "Zig model" as the primary blueprint.

To have a compiler written entirely in Zig, the development team is systematically replacing three specific "pillars" of LLVM. If you wanted to contribute to this "divorce," you would focus on the **Back End**, which is where the transition from abstract code to physical machine instructions happens.

Here is the specific roadmap of what is being rewritten in Zig to eliminate the LLVM dependency.

---

### 1. The Machine Code Emitters (The CPU Backends)
Currently, Zig uses LLVM to turn its internal representation into optimized assembly for different CPUs (x86, ARM, RISC-V). To replace this, Zig is implementing **Native Backends** written in 100% Zig.
*   **The Task:** You have to write code that takes Zig’s **AIR** (Analyzed Intermediate Representation) and converts it into the specific binary opcodes for a processor.
*   **Status:** As of 2026, the **x86_64** and **AArch64** (ARM) backends are highly functional for Debug builds. The community is currently focusing on completing **RISC-V** and **Wasm** backends to the same standard.

### 2. The Linkers (ELF, Mach-O, and PE)
LLVM comes with `lld`, a universal linker. Zig is replacing this with its own linkers to support its "incremental" compilation goals.
*   **The Task:** You must write Zig code that understands how to package machine code into the three main executable formats:
    *   **ELF:** For Linux and BSD.
    *   **Mach-O:** For macOS and iOS.
    *   **PE (Portable Executable):** For Windows.
*   **Why Zig?** A custom linker written in Zig can perform **Incremental Linking**, meaning if you change one function, the linker only updates that specific part of the binary on your disk rather than rewriting the whole file.

### 3. The "Machine IR" (MIR)
Between the high-level code and the final binary, LLVM uses its own "LLVM IR." Zig is replacing this with its own multi-layered IR system:
*   **ZIR (Zig IR):** Raw, untyped representation of your source code.
*   **AIR (Analyzed IR):** Fully typed and monomorphized code (after `comptime` has run).
*   **MIR (Machine IR):** An architecture-specific representation (e.g., x86_64 MIR) that handles register allocation.

> 

---

### Summary: What is left to do?
If you want to help achieve a "Zig-only" compiler, the work is currently concentrated in these areas:

| Component | Goal | Current Progress (2026) |
| :--- | :--- | :--- |
| **Optimizers** | Replicating LLVM's massive suite of speed optimizations. | **Early Stages.** Zig currently prioritizes build speed over peak optimization in its native backends. |
| **Windows Linker (PE)** | Full support for incremental linking on Windows. | **Active Development.** Still relies on LLVM for certain complex edge cases. |
| **Debug Info** | Writing DWARF and PDB debug information natively. | **In Progress.** This is crucial so that tools like GDB and LLDB can still debug Zig code without LLVM. |

### Why keep LLVM at all?
Even when the "Zig-only" compiler is finished, LLVM will likely remain as an **optional extension**. Writing an optimizer that produces code as fast as LLVM's `-O3` takes decades. By having a native Zig backend for development (speed) and an optional LLVM backend for production (performance), Zig gets the best of both worlds.

[Andrew Kelley: The Road to Zig 1.0 and LLVM Independence](https://www.youtube.com/watch?v=5_mHbSe_f9w)
This video from the creator of Zig details the architectural decisions and the specific engineering hurdles involved in moving away from LLVM.

Replicating LLVM's optimization suite in Zig is less about copying millions of lines of C++ and more about implementing the "Essential 80/20"—the small number of transformation passes that provide the vast majority of performance gains.

In the LLVM world, these are grouped into **Analysis** (understanding the code) and **Transform** (changing the code). To build this in Zig, you would focus on the `src/arch/[arch]/` directories in the Zig source, where AIR is lowered into MIR.

---

### Phase 1: The "Must-Have" Infrastructure (Analysis)
Before you can optimize, the compiler needs to "see" the code's structure. You would implement these as Zig structs that analyze the Control Flow Graph (CFG).

*   **Dominator Tree Construction:** This is the foundation. It tells the compiler which parts of the code *must* execute before others. Without this, you can't safely move code.
*   **Alias Analysis:** In Zig, this is critical because of pointers. You need a pass that can prove two pointers don't point to the same memory, allowing the compiler to keep values in registers instead of constantly reloading from RAM.

### Phase 2: The High-Impact Transforms
If you want to match `-O2` or `-O3` performance, these are the passes you should write first in Zig:

#### 1. SROA (Scalar Replacement of Aggregates)
Zig loves structs. SROA breaks a struct into its individual fields. Instead of passing a `Point` struct around, the compiler just passes two `f32` registers. This often triggers a cascade of other optimizations.

#### 2. InstCombine (Instruction Combination)
This is the "cleanup" pass. It looks for simple algebraic identities:
*   `x + 0` → `x`
*   `x * 2` → `x << 1`
*   `a = b; c = a + 1` → `c = b + 1`
In LLVM, this pass is massive because it handles thousands of edge cases. In Zig, you could start with the most common bitwise and arithmetic patterns.

#### 3. GVN (Global Value Numbering)
This detects redundant computations. If you calculate `(a + b)` on line 10 and again on line 20, and neither `a` nor `b` has changed, GVN replaces the second calculation with the result of the first.



---

### Phase 3: The "Loop" Suite
Since most programs spend 90% of their time in loops, these provide the biggest "bang for your buck":

*   **Loop Invariant Code Motion (LICM):** If a calculation inside a loop doesn't change every iteration, move it *outside* the loop.
*   **Loop Unrolling:** Repeat the loop body multiple times to reduce the "overhead" of the counter and branch.
*   **Induction Variable Simplification:** Turn complex math inside a loop into simple additions.

---

### How to start today in the Zig source
If you want to experiment with this, look at the **Self-hosted Compiler Pipeline**:

1.  **AIR (Analyzed IR):** This is where high-level, type-checked Zig lives. You can write "Middle-end" optimizations here that are CPU-independent (like Dead Code Elimination).
2.  **MIR (Machine IR):** This is architecture-specific. This is where you would write **Peephole Optimizers** (looking at 2-3 assembly instructions and replacing them with a faster single instruction).

### The Challenge: The "Phase Shift"
The reason Zig hasn't fully replicated these yet is **Compile Speed**. LLVM’s optimizations are slow because they run repeatedly until no more changes are found. To do this "The Zig Way," you would need to implement these passes to be **incremental**—only re-optimizing the functions that actually changed.

In the LLVM architecture, the "massive suite of speed optimizations" lives in the **Middle-end**.

While the Front-end (Clang) translates source code to Intermediate Representation (IR), and the Back-end (Target emitters) translates IR to machine code, the Middle-end is a massive "pipeline" that takes IR in and spits out a more efficient version of that same IR.

### 1. The Core Engine: The Pass Manager
The heart of LLVM's optimization is the **Pass Manager** (specifically the "New Pass Manager" introduced recently). It doesn't actually optimize the code itself; instead, it acts like a factory conveyor belt.
*   It schedules and runs hundreds of independent **Passes**.
*   It manages **Analysis Results** (like Dominator Trees), ensuring that if an optimization needs to know "which loop is this?", it doesn't have to re-calculate that information if it's already cached.
*   **Replicating this in Zig:** You would need a `PassManager` struct that can orchestrate transformations on your **AIR** (Analyzed IR).

---

### 2. The Transformation Passes (The "Workers")
This is where the actual logic for speed lives. In LLVM, these are C++ classes that inherit from a pass mixin. To replicate them in Zig, you would focus on these four categories:

#### A. Scalar Optimizations (The "Bread and Butter")
These focus on individual variables and instructions.
*   **SROA (Scalar Replacement of Aggregates):** Replaces structs with individual registers.
*   **InstCombine:** The largest pass in LLVM. It has thousands of rules to simplify math (e.g., changing `x * 2` to `x + x`).
*   **SimplifyCFG:** Cleans up the "spaghetti code" of jumps and branches.

#### B. Loop Optimizations (Where the Speed Is)
Since most CPU time is spent in loops, LLVM has a dedicated "Loop Pass Manager."
*   **LICM (Loop Invariant Code Motion):** Moves code that doesn't change out of the loop.
*   **Loop Vectorization:** Uses SIMD instructions to process 4 or 8 pieces of data at once.
*   **Loop Unrolling:** Reduces branch overhead.

#### C. Inter-Procedural Optimizations (IPO)
These look at the *entire program* rather than one function at a time.
*   **Inlining:** Replacing a function call with the actual code of the function. This is the "king" of optimizations because it enables all other passes to see more code.
*   **Dead Argument Elimination:** Removing parameters from functions that are never used.

#### D. Analysis Passes (The "Eyes")
These don't change code; they just provide information.
*   **Alias Analysis (AA):** Determines if two pointers might point to the same memory. This is the hardest part of a compiler to write but is required for high-performance code.



---

### 3. The "Opt" Tool
If you want to see exactly how LLVM does this, you can use the `opt` command-line tool. It allows you to run a single pass on a file to see exactly how it changes the code:
```bash
opt -passes=sroa input.ll -S -o output.ll
```
By comparing `input.ll` to `output.ll`, you can see the "before and after" of the optimization. This is the best way to "reverse engineer" LLVM's logic so you can rewrite it in Zig.

### How to approach the rewrite?
If you want to replicate this in Zig, the most efficient path is to target **Zig's AIR (Analyzed IR)**. 
1.  **Start with a Dead Code Elimination (DCE) pass.** It's the simplest to write and teaches you how to traverse the IR tree.
2.  **Move to Constant Folding.** Write logic that sees `1 + 2` in the IR and replaces it with `3`.
3.  **Build a Dominator Tree.** This is the "level up" moment where you can start doing real control-flow optimizations.

Are you more interested in the **math/logic** of the transformations, or the **software architecture** of the Pass Manager itself?
