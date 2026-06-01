# Object, Debug, And Unwind Boundary

This cycle keeps object emission as a validation aid for optimizer/backend
handoff facts. It does not claim to replace LLVM MC, DWARF, or unwind emission.

## Source Anchors

```text
llvm-project-22/llvm/lib/MC/ELFObjectWriter.cpp
llvm-project-22/llvm/lib/MC/MCELFStreamer.cpp
llvm-project-22/llvm/lib/CodeGen/AsmPrinter/DwarfDebug.cpp
llvm-project-22/llvm/lib/CodeGen/AsmPrinter/DwarfCFIException.cpp
z_llvm/src/mc/elf.zig
z_llvm/src/mc/assembly.zig
z_llvm/docs/debug/metadata_inventory.md
```

## Current Validation Surface

| Area | Local artifact | Validation command | Boundary |
| --- | --- | --- | --- |
| Assembly text | `test/codegen/expected/asm/*.s` | `zig build compare-codegen-asm` | Readable tiny x86_64 lowering smoke only. |
| ELF relocatable object | `--emit=obj` over tiny x86_64 fixtures | `zig build compare-codegen-objdump` | Encoded text bytes and direct-call relocation smoke only. |
| Symbols and relocations | `readelf -r -s` over call fixtures | `zig build compare-codegen-readelf` | Direct-call `R_X86_64_PLT32` and symbol-table visibility checks. |
| Debug metadata | opaque IR metadata preservation | `zig build zig-corpus` | Parser/printer preservation only, not DWARF emission. |
| Unwind/CFI | none | none | Out of scope until call/frame lowering requires frame directives. |

## Activation Criteria

Object/debug/unwind work should be added only when one of these happens:

```text
an optimizer handoff fixture needs an object-level symbol or relocation check
a call/frame lowering fixture needs CFI/unwind correctness
a debug-preservation fixture needs DWARF emission rather than IR metadata round-trip
a linker-boundary fixture needs COMDAT, TLS, sections, or non-text relocations
```

## Deliberate Non-Goals

```text
no broad ELF writer parity
no Mach-O, COFF, Wasm object support
no DWARF or CodeView emission
no exception/unwind table emission
no linker integration
no relocation kinds beyond the documented direct-call subset
```

## Current Smoke Matrix

```text
zig build handoff
```

The handoff script now runs optimizer checks, assembly smoke checks, objdump
checks, and readelf relocation/symbol checks. These are local bootstrap
contracts, not `opt-22` equivalence tests.
