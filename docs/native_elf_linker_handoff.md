# Native ELF Linker Handoff

This note scopes the handoff from `z_llvm` object emission to Zig's native ELF
linker. It does not move linker ownership into `z_llvm`.

## Zig Linker Selection

The local Zig checkout selects the linker in three layers:

1. CLI plumbing in `../ziglang/src/main.zig`:
   `-flld` sets `use_lld=true`, `-fno-lld` sets `use_lld=false`,
   `-fnew-linker` sets `use_new_linker=true`, and `-fno-new-linker` sets
   `use_new_linker=false`.
2. Policy in `../ziglang/src/Compilation/Config.zig`:
   LLD is selected only when the target object format supports it, LLVM is
   available, LTO does not force an incompatible choice, and the user has not
   forced `-fno-lld`. With Zig code, the default tracks `use_llvm`; without Zig
   code, the default can choose LLD because there is no self-hosted object to
   incrementally update.
3. Linker object construction in `../ziglang/src/link.zig`:
   if `comp.config.use_lld` is true, Zig opens `link.Lld`. Otherwise,
   `Tag.fromObjectFormat(ofmt, use_new_linker)` maps ELF to `link.Elf` for the
   old/self-hosted linker and to `link.Elf2` for the new linker.

For this repository's current proof, the accepted handoff command is:

```text
zig build-exe -fno-lld ...
```

The experimental stronger probe is:

```text
zig build-exe -fno-lld -fnew-linker ...
```

That path is valid only when this Zig checkout reports new-linker support for
the target object format/backend combination; otherwise Zig should classify the
failure as an unsupported Zig linker feature, not a `z_llvm` object-emission
failure.

## z_llvm Object Contract

Current selected x86_64 ELF objects handed to Zig's native linker are:

- ELF64 little-endian `ET_REL` relocatable objects for x86_64.
- No program headers.
- Sections:
  `.text` as `PROGBITS AX`, alignment 16;
  `.data` as `PROGBITS WA`, alignment 16;
  `.tdata` as `PROGBITS WAT`, alignment 4;
  `.rela.text` as `RELA`, entry size 24, alignment 8;
  `.symtab`, `.strtab`, and `.shstrtab`.
- Symbols:
  exported functions are `STT_FUNC GLOBAL DEFAULT` in `.text`;
  data globals are `STT_OBJECT GLOBAL DEFAULT` in `.data`;
  TLS globals are `STT_TLS GLOBAL DEFAULT` in `.tdata`;
  unresolved imports are `GLOBAL DEFAULT UND`.
- Relocations:
  `R_X86_64_PLT32` for direct calls with addend `-4`;
  `R_X86_64_PC32` for RIP-relative data/global references with addend `-4`;
  `R_X86_64_TPOFF32` for local-exec TLS references with addend `0`.
- TLS model:
  selected rows use local-exec x86_64 `%fs:symbol@TPOFF` lowering and require
  `STT_TLS` symbols plus `SHF_TLS` `.tdata`.
- COMDAT/group behavior:
  not emitted in the current handoff contract. If a future object needs
  `.group`/COMDAT, it must be added as a separate compatibility slice.
- `.eh_frame`/unwind behavior:
  not emitted in the current selected native-link handoff. If unwind metadata
  appears, it is a separate debug/unwind boundary rather than implicit linker
  evidence.

## Inspection Gate

`zig build distribution-native-link-object-inspection` emits each selected
native-link object with `z_llvm`, runs `readelf -W -h -S -s -r` and
`objdump -dr`, and validates the object before any Zig linker invocation.
With `--release-source-owned`, it reuses the same 100-row source-owned
ReleaseFast/ReleaseSafe/ReleaseSmall inventory as
`distribution-x86_64-release-source-owned` and emits each object through the
patched-Zig source-owned z_llvm hook before inspecting it.

The source-owned inspection mode is a milestone object-boundary confirmation,
not a tiny inner-loop check. Its setup validates the patched stage4 hook with
`tools/check_zig_stage4_emitter.zig` and runs `zig build` before inspecting the
100-row object boundary.

It reports:

```text
summary native-link-object-inspection inventory=<selected-native-link|release-source-owned> target=<target> mode=<mode> case=<case>
  inspected=<n>
  elf64_rel=<n>
  relocation_rows=<n>
  tls_rows=<n>
  undefined_import_rows=<n>
  comdat_rows=0
  eh_frame_rows=0
  unsupported_relocation_rows=0
  local_fail=0
```

Focused usage:

```text
zig build distribution-native-link-object-inspection -- --case=releasefast_tiny_scalar
zig build distribution-native-link-object-inspection -- --mode=ReleaseFast
zig build distribution-native-link-object-inspection -- --release-source-owned --case=releasefast_source_tiny_scalar
zig build distribution-native-link-object-inspection -- --release-source-owned --mode=ReleaseFast
```

Run this gate before native-link executable gates when changing object emission,
relocations, symbol tables, TLS lowering, or section layout.

Current source-owned boundary proof:

```text
zig build distribution-native-link-object-inspection -- --release-source-owned
summary native-link-object-inspection inventory=release-source-owned
  inspected=100
  elf64_rel=100
  relocation_rows=12
  tls_rows=8
  undefined_import_rows=0
  comdat_rows=0
  eh_frame_rows=0
  unsupported_relocation_rows=0
  local_fail=0
```

## Source-Owned Native Link

`zig build distribution-native-link -- --release-source-owned` is the matching
100-row native-link executable proof. It emits each row through the same
patched-Zig source-owned z_llvm object path, links with `zig build-exe
-fno-lld`, and keeps final linker ownership in Zig.

It separates object/link outcomes from runnable ABI evidence:

```text
summary distribution-native-link inventory=release-source-owned
  total=100
  executable_abi_proof_rows=100
  link_only_rows=0
  runtime_compiler_rt_libc_boundary_rows=0
  unsupported_zig_linker_feature_rows=0
  local_object_codegen_failures=0
  local_fail=0
```

`zig build probe-native-linker -- --release-source-owned` is the companion
link-acceptance probe over the same inventory and object path:

```text
summary native-link-probe inventory=release-source-owned
  accepted=100
  runtime_compiler_rt_libc_boundary_rows=0
  unsupported_zig_linker_feature_rows=0
  local_object_codegen_failures=0
  failed=0
```

## Failure Classes

Do not use a generic `link failed` bucket. Classify failures as:

- `missing-relocation-support`
- `bad-symbol-binding-type`
- `section-flag-alignment`
- `tls-model`
- `comdat`
- `unwind-boundary`
- `runtime/compiler-rt/libc-boundary`
- `zig-linker-bug-or-unsupported-feature`

The existing native-link probe keeps linker acceptance failures classified by
bad symbol binding/type, missing relocation support, section flag/alignment,
TLS model, COMDAT, ABI, runtime/compiler-rt/libc boundary, or Zig linker
bug/unsupported feature. The object-inspection gate catches object-contract
failures earlier, before Zig's linker is involved.
