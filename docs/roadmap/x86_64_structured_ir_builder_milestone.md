# x86_64 Structured IR Builder Milestone

This milestone adds `src/structured_ir_builder.zig` and moves the selected
x86_64 release IR-writer rows from handwritten body strings to a local
structured construction API. The selected rows now build z_llvm-owned internal
IR modules directly, bypassing textual LLVM IR serialization/parsing for the
selected replacement path.

## Measured Gate

```text
gate=zig build distribution-zig-ir-writer
total=146 executable_ok=146 link_only_ok=0 local_fail=0
structured_builder_rows=146
structured_direct_rows=146
structured_textual_rows=0
textual_boundary_rows=0
generic_codegen_rows=146
case_specific_codegen_rows=0
manifest_structured_rows=0
semantic_record_rows=136
external_writer_delegate_rows=10
minimal-ret0=0
ownership=llvm-module=not-used; llvm-optimizer=not-used;
          llvm-targetmachine=not-used; object-emission=z_llvm;
          linker=zig-native-fno-lld
```

The full selected gate fails if any selected row is not structured-direct, any
structured row reports textual LLVM parsing, any textual boundary row remains,
any structured-direct row reports case-specific codegen ownership, any selected
row reports `minimal-ret0`, any selected row reports libLLVM module
parse/print, or any selected row reports LLVM TargetMachine object emission.
The generic x86_64 lowering audit is tracked in
`docs/roadmap/x86_64_codegen_genericity_audit.md`.

## Converted Rows

All 146 selected rows now report `ir-construction=zllvm-structured-builder`.
This includes the original tiny scalar, integer, error-switch/select, direct
call, global load/update, loop/phi, pointer load/store, struct/array/slice, TLS,
atomic, inline asm, aggregate ABI, optional/error-union payload, FP
compare/select/div/rem, ReleaseSafe checked panic-edge, ReleaseSmall mixed
C/Zig, base64, and `strFromFloatHelp` rows.

The final conversion removed the selected textual-boundary bucket by converting
the reduced base64 slices first, then the full base64 decoder and
`strFromFloatHelp`. The compact selected gate therefore no longer tracks
textual-boundary reason accounting.

## Helper Families Covered

`src/structured_ir_builder.zig` models modules, functions, named blocks, values,
types, constants, globals, TLS globals, branches, conditional branches, returns,
phis, binary operations, casts, integer/FP compares, selects, calls, alloca,
GEP, loads, stores, lifetime intrinsics, memcpy, memset, checked signed
add/mul panic-edge helpers, and aggregate vector/array-style constants needed
by the selected runtime rows.

The selected writer path now uses structured helpers for:

- scalar and integer arithmetic rows
- error-switch/select rows
- direct-call and call-chain rows
- global load/update rows
- loop/phi and switch rows
- pointer load/store, volatile, slice, struct, and array rows
- optional payload and error-union payload rows
- TLS and simple atomic rows
- inline/compile-asm boundary rows
- FP literal, binary, compare, select, div, and rem rows
- ReleaseSafe checked arithmetic and panic-edge rows
- ReleaseSmall mixed C/Zig, hidden/global, i64 pass-through, and saturating rows
- reduced base64 slices, full base64 decoder, and `strFromFloatHelp`

## Boundary

This is not full Zig IR construction replacement. The structured builder covers
only selected x86_64 release-mode IR-writer rows and is invoked only under the
explicit external writer environment. It does not replace Zig's normal
libLLVM-backed IR construction, Debug/LTO/AArch64 paths, arbitrary source
lowering, LLVM IR parsing for normal fallback builds, compiler-rt/libc
replacement, or target-complete object coverage.

## Semantic Lowering Rung

The next ownership rung is tracked separately in
`docs/roadmap/x86_64_source_wrapper_semantic_lowering.md`. The selected
146-row gate now reports `semantic_record_rows=136`,
`external_writer_delegate_rows=10`, and `manifest_structured_rows=0`; the
source-wrapper compatibility gate reports `semantic_record_rows=48`,
`external_writer_delegate_rows=1`, and `manifest_structured_rows=0`. These
semantic rows are still emitted through `src/structured_ir_builder.zig`; the
improvement is that z_llvm now starts from small Zig-level semantic records for
those families instead of manifest-shaped structured templates.

The strongest current release-mode source-owned gate is
`zig build distribution-x86_64-release-source-owned`. It keeps the broad
90-row source-backed fixture inventory, emits a stable source-derived
descriptor input from wrapper, fixture, and source-tag metadata, makes z_llvm
consume that descriptor directly, and requires
`descriptor_v2_rows=90`, `real_descriptor_program_rows=90`,
`source_derived_descriptor_rows=90`, `tag_table_descriptor_rows=0`,
`body_enum_dispatch_rows=0`,
`surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`,
`legacy_semantic_record_rows=0`, `semantic_record_rows=0`, `external_writer_delegate_rows=0`,
`manifest_structured_rows=0`, `case_id_rows=0`, `surface_dispatch_rows=0`,
`structured_direct_rows=90`, and `generic_codegen_rows=90`.
