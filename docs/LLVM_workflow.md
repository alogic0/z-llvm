# Exploring Zig's LLVM Workflow

This note is for investigating what happens after Zig has produced AIR and the LLVM backend is selected.

The important correction is that LLVM does not consume AIR directly. Zig lowers AIR into LLVM IR/bitcode in `src/codegen/llvm.zig`. After that, LLVM runs its own optimization and target code generation pipeline to produce assembly or object code.

## Pipeline

The rough path is:

```text
Zig source
  -> ZIR
  -> Sema
  -> AIR
  -> Zig LLVM backend
  -> LLVM IR / bitcode
  -> LLVM optimization passes
  -> LLVM target lowering / instruction selection / register allocation
  -> assembly or object code
  -> linker
  -> executable or library
```

Short terms:

*   **ZIR:** Zig's source-level intermediate representation.
*   **Sema:** Zig's semantic analysis phase. It resolves types, comptime execution, declarations, and errors.
*   **AIR:** Analyzed IR. This is typed, checked Zig IR consumed by code generation backends.
*   **LLVM IR:** LLVM's target-independent intermediate representation.
*   **Bitcode:** A binary encoding of LLVM IR.
*   **SelectionDAG / GlobalISel:** LLVM target-lowering frameworks that transform LLVM IR toward target instructions.
*   **Machine IR:** LLVM's low-level machine representation after target lowering, not the same thing as Zig's MIR.

## Build Requirements

To explore this from the Zig checkout, use a compiler built with LLVM and debug extensions:

```bash
zig build -Denable-llvm -Ddebug-extensions
```

`-Denable-llvm` enables the LLVM backend. `-Ddebug-extensions` enables debug flags such as `--verbose-air`.

Useful LLVM tools:

```text
llvm-dis
opt
llc
llvm-objdump
```

Use versions that match, or are close to, the LLVM version Zig is linked against.

## Useful Zig Flags

These flags let you capture each stage:

```bash
--verbose-air
--verbose-llvm-ir=pre.ll
--verbose-llvm-bc=pre.bc
-femit-llvm-ir=post.ll
-femit-llvm-bc=post.bc
-femit-asm=out.s
-fopt-bisect-limit=N
```

What they show:

*   `--verbose-air`: Zig AIR before LLVM lowering.
*   `--verbose-llvm-ir=pre.ll`: unoptimized LLVM IR produced by Zig's LLVM backend.
*   `--verbose-llvm-bc=pre.bc`: unoptimized LLVM bitcode.
*   `-femit-llvm-ir=post.ll`: optimized LLVM IR after LLVM passes.
*   `-femit-llvm-bc=post.bc`: optimized LLVM bitcode.
*   `-femit-asm=out.s`: final assembly.
*   `-fopt-bisect-limit=N`: run only the first `N` LLVM optimization passes. This is useful for finding which pass changes the IR in a way you care about.

## First Experiment

Create a small file:

```zig
export fn add_mul(a: u32, b: u32) u32 {
    const x = a + b;
    return x * 3;
}
```

Then compile it through the LLVM backend and capture the artifacts:

```bash
zig build-obj example.zig \
  -O ReleaseFast \
  -fllvm \
  --verbose-air \
  --verbose-llvm-ir=pre.ll \
  --verbose-llvm-bc=pre.bc \
  -femit-llvm-ir=post.ll \
  -femit-llvm-bc=post.bc \
  -femit-asm=out.s
```

Then compare:

```bash
diff -u pre.ll post.ll
llvm-dis pre.bc -o pre_from_bc.ll
opt -O2 pre.bc -S -o opt.ll
llc opt.ll -o llc.s
```

This lets you inspect:

*   what Zig emitted into LLVM IR;
*   what LLVM optimization changed;
*   what LLVM target codegen produced as assembly.

## Source Files To Read

In `/home/oleg/prog/ziglang`:

*   `src/Compilation/Config.zig:317-366`: decides whether to use the LLVM backend.
*   `src/Compilation.zig:2478-2480`: creates `zcu.llvm_object`.
*   `src/Zcu/PerThread.zig:4590-4596`: sends AIR function codegen to the LLVM object.
*   `src/codegen/llvm.zig:588-604`: creates the LLVM object and module builder.
*   `src/codegen/llvm.zig:1135-1141`: starts `updateFunc`, the function-lowering path from AIR into LLVM structures.
*   `src/Compilation.zig:3323-3370`: calls `llvm_object.emit`.
*   `src/codegen/llvm.zig:970-982`: initializes LLVM and parses Zig-produced bitcode for final emission.
*   `src/codegen/llvm.zig:1120-1124`: calls `target_machine.emitToFile`.

## LLVM Algorithms To Explore

Start with these in order:

1.  **AIR to LLVM IR lowering**
    *   Question: how does each AIR instruction become LLVM IR?
    *   Zig code: `src/codegen/llvm.zig` and `src/codegen/llvm/FuncGen.zig`.

2.  **LLVM IR canonicalization**
    *   Algorithms: instruction combine, simplify CFG, mem2reg, scalar replacement of aggregates.
    *   Tooling: `opt -passes=...`.

3.  **Scalar optimizations**
    *   Algorithms: constant propagation, global value numbering, dead code elimination.
    *   Goal: understand why `pre.ll` and `post.ll` differ.

4.  **Loop optimizations**
    *   Algorithms: loop invariant code motion, loop unrolling, vectorization.
    *   Use small loop examples and compare `pre.ll`, `post.ll`, and `out.s`.

5.  **Target lowering**
    *   Algorithms: instruction selection, legalizing, register allocation, scheduling.
    *   Tooling: `llc` and LLVM debug flags if available in your LLVM build.

6.  **Object and assembly emission**
    *   Question: where do target instructions become actual assembly or object bytes?
    *   Zig handoff: `target_machine.emitToFile(...)`.
    *   Tooling: `llvm-objdump -d`.

## Working Method

For each algorithm:

1.  Write a tiny Zig example that should trigger it.
2.  Capture AIR, pre-LLVM IR, post-LLVM IR, and assembly.
3.  Reduce the example until the transformation is obvious.
4.  Re-run with `-fopt-bisect-limit=N` to find where the transformation appears.
5.  Use `opt -passes=...` on `pre.bc` to reproduce the transformation outside Zig.
6.  Record the exact Zig source, command line, relevant IR diff, and final assembly difference.

The goal is to build a catalog of concrete transformations rather than a vague description of "LLVM optimizes it".
