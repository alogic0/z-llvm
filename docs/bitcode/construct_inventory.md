# LLVM Bitcode Construct Inventory

This inventory records what must be understood before this project implements
any LLVM-compatible bitcode writer or parser.

## Zig Source Anchors

```text
ziglang/src/codegen/llvm/bindings.zig:
  MemoryBuffer.createMemoryBufferWithMemoryRange
  Context.parseBitcodeInContext2

ziglang/src/codegen/llvm.zig:
  Object.emit bitcode buffer creation through builder.toBitcode
  bitcode-only write path before libLLVM TargetMachine emission
  libLLVM parse check for the generated bitcode buffer

ziglang/src/zig_llvm.cpp:
  ZigLLVMTargetMachineEmitToFile
  WriteBitcodeToFile for LTO and explicit bitcode output

llvm-project-22/llvm/include/llvm/Bitcode/BitcodeWriter.h
llvm-project-22/llvm/lib/Bitcode/Writer/BitcodeWriter.cpp
llvm-project-22/llvm/lib/Bitcode/Reader/BitcodeReader.cpp
```

## Current Local Status

```text
no bitcode writer
no bitcode parser
text LLVM-compatible IR remains the active comparison format
bitcode is optional compatibility work, not a blocker for local optimizer slices
LTO pre-link validation is text-IR and pipeline based; it is not a bitcode
handoff implementation
Cycle 23 decision: defer bitcode/LTO compatibility until an activation
criterion in docs/bitcode/lto_compatibility_decision.md is met
```

## Requirement Classification

| Zig use case | Classification | Reason |
| --- | --- | --- |
| Local optimizer comparison against `opt-22` | needed now, text IR only | The accepted corpus and pass fixtures compare normalized text IR. |
| `-femit-llvm-ir` style migration output | needed later | Text IR compatibility can be validated before a bitcode writer exists. |
| `-femit-llvm-bc` / explicit bitcode output | deferred | Requires type/value numbering, metadata policy, use-list order, and LLVM bitcode verification. |
| LTO handoff to LLD | deferred | Requires bitcode writer output even when pre-link optimization is represented. |
| ThinLTO import/export and WPD | deferred | Requires module summary index and combined-index behavior. |
| Bitcode input parsing | out of scope until proven | No current accepted fixture uses bitcode as the only handoff artifact. |
| Native backend/object validation | no bitcode need | Uses local IR, machine lowering, assembly, or ELF object checks. |

## Zig Mode Boundary

| Zig mode/path | Bitcode/LTO local need | Current project action |
| --- | --- | --- |
| `Debug` without explicit bitcode output | no local bitcode need | Keep text IR fixtures and Debug metadata preservation separate. |
| `ReleaseFast` / `ReleaseSafe` / `ReleaseSmall` without LTO | no local bitcode need | Use text IR corpus rows and accepted local pipelines. |
| explicit `-femit-llvm-bc` / LLVM bitcode output | writer/output compatibility | Deferred until a bitcode writer is selected as a migration artifact. |
| non-debug `-flto=thin` | writer/output plus ThinLTO summaries later | Model the pre-link optimizer boundary only; defer summary index emission. |
| non-debug `-flto=full` | writer/output for linker handoff | Model the pre-link optimizer boundary only; defer bitcode output. |
| bitcode input through `parseBitcodeInContext2` | parser/input compatibility | Deferred until a fixture proves text IR is not the handoff artifact. |

## Required Construct Groups

| Construct group | Required local source before implementation | Current coverage |
| --- | --- | --- |
| Module block | source filename, target triple, datalayout, flags, named metadata | text IR has source/triple/datalayout and raw top-level metadata |
| Type table | integers, ptr, void, arrays, structs, vectors, function types | integers, ptr, void, textual array/aggregate surface, and scalar function signatures only |
| Constants | integer constants, undef, null, aggregate constants, global initializers | integer constants, undef, and scalar globals only |
| Value symbol table | function, parameter, block, instruction, global, declaration names | text IR names for accepted scalar/control-flow/memory/global subset |
| Function bodies | blocks, instructions, terminators, phi incoming edges | accepted scalar/control-flow/memory/call/global subset only |
| Attributes | function, parameter, return, call-site attributes | raw function/parameter attributes preserved; call attributes mostly rejected |
| Metadata | named metadata, DI nodes, debug locations, TBAA, prof, range, loop metadata | raw top-level records, opaque instruction `!dbg`, and opaque branch `!prof`/loop attachments |
| Comdat and aliases | COMDAT groups, aliases, ifuncs, unnamed addr | aliases accepted; COMDAT records and references preserved conservatively; ifuncs and full unnamed_addr semantics missing |
| Operand bundles | deopt, funclet, clang.arc, ptrauth, custom bundles | missing |
| Use-list order | deterministic use-list preservation for bitcode round-trip | missing |
| Summary index | ThinLTO module summary and combined index records | missing |

## Accepted Corpus Construct Coverage

| Corpus row/group | Bitcode construct groups exercised | Writer readiness |
| --- | --- | --- |
| `release_safe_safety_reduced` | module source record, scalar function type, conditional branch, `unreachable`, opaque `!prof` metadata | text-only; enough to inventory metadata records, not enough to start writer |
| `tiny_scalar_release_fast` and captured scalar rows | module target records, aliases, scalar functions, integer arithmetic, raw attrs | text-only; value numbering/use-list order not documented |
| `tiny_scalar_release_small_captured` | scalar functions, aliases, size-oriented attrs | text-only; size attrs are preserved but not encoded |
| `integers_release_fast` | integer operations, shifts, min/max intrinsic surface | text-only; intrinsic encoding policy missing |
| `pointers_memory_release_fast` | load/store, volatile memory spelling, pointer attrs | text-only; memory metadata and address spaces missing |
| `aggregates_release_fast` | textual array/aggregate surface and GEP patterns | text-only; structured type table layout not complete |
| `control_flow_calls_release_fast` | PHI, loops, direct calls, assume, loop metadata | text-only; call-site attrs and metadata graph not complete |
| `globals_comptime_release_fast` | globals, aliases, global loads/stores | text-only; COMDAT/unnamed addr/global initializer breadth missing |

## First Writer Slice Criteria

Do not start a writer until these are true:

```text
accepted text IR subset is stable for a concrete Zig-emitted fixture group
type/value numbering rules are documented for that subset
metadata policy is explicit: preserve, reject, or omit with diagnostic
LLVM 22 can parse the produced bitcode for the selected fixtures
round-trip comparison uses llvm-dis-22 or opt-22 as an external verifier
```

## First Parser Slice Criteria

Do not start a parser until a fixture proves text IR is insufficient:

```text
input artifact is bitcode, not just text IR
the bitcode contains only construct groups selected for the slice
unknown records produce explicit unsupported diagnostics
parsed module can be printed back to normalized LLVM-compatible text IR
```

## Deferred Behavior

```text
ThinLTO summary index
debug metadata graph interpretation
operand bundles
COMDAT, aliases, ifuncs
type uniquing beyond the accepted scalar subset
bitcode upgrades across LLVM versions
```
