# x86_64 Source Wrapper and Semantic Lowering Milestone

This milestone separates four local ownership proofs for the x86_64 release
subset:

1. Fixed selected-row proof: `ZLLVM_CASE_ID` still selects the 146 stable
   registry rows used by `zig build distribution-zig-ir-writer`.
2. Source-wrapper dispatch proof: patched Zig passes wrapper path, optimize
   mode, target, output, and marker metadata; z_llvm resolves the structured
   module from wrapper/source metadata instead of using the case id as the
   primary selector.
3. Source-owned release proof: the full current 90-row source-backed release
   inventory is selected from wrapper, fixture, and source-tag metadata, not
   from case-id ownership.
4. Semantic lowering proof: source-owned rows lower Zig-level semantic records
   through `src/zig_semantic_lowering.zig` into
   `src/structured_ir_builder.zig`, instead of reporting manifest-shaped
   structured templates.

## Source-Wrapper Gate

```text
gate=zig build distribution-zig-source-structured-direct
source_wrappers=49
structured_direct_rows=49
case_id_rows=0
generic_codegen_rows=49
manifest_structured_rows=0
semantic_record_rows=48
external_writer_delegate_rows=1
case_specific_rows=0
fallback_rows=0
local_fail=0
```

This gate intentionally starts with the unambiguous wrapper/mode subset of the
current broad source-backed inventory. Rows that share the same wrapper and mode
with multiple fixture meanings stay in the fixed selected/broad gates until the
source metadata can disambiguate them without reintroducing case-id selection.

Every accepted source-wrapper row must report:

```text
ir-construction=zllvm-structured-builder
llvm_text_parse=not-used
codegen=generic-x86_64-lowering
llvm-module=not-used
llvm-optimizer=not-used
llvm-targetmachine=not-used
object-emission=z_llvm
linker=zig-native-fno-lld
```

## Source-Owned Release Gate

```text
gate=zig build distribution-x86_64-release-source-owned
release_source_rows=90
source_wrapper_rows=90
semantic_record_rows=90
external_writer_delegate_rows=0
semantic_lowering_rows=90
manifest_structured_rows=0
case_id_rows=0
structured_direct_rows=90
generic_codegen_rows=90
fallback_rows=0
local_fail=0
```

This gate closes the wrapper/mode collision gap by passing source fixture
metadata and a source-backed tag such as `tls-concurrency-checked-bump` or
`tls-concurrency-checked-read`. The emitted writer header records
`zllvm_ir_writer_dispatch = "source-owned"`,
`zllvm_ir_writer_source_fixture`, and `zllvm_ir_writer_source_tag`; the row
selector remains `ZLLVM_CASE_ID=source-wrapper-dispatch`, so case ids are not
the ownership selector for this gate.

## Semantic-Lowered Families

`src/zig_semantic_lowering.zig` currently models these source-level program
families before building structured IR in the source-owned gate:

- scalar integer arithmetic and wrap/cmp/shift checks
- error-switch/select rows
- direct calls and simple call chains
- branches, phis, and counted loop sums
- mutable global update
- pointer load/store
- struct, array, optional payload, error-union payload, and slice rows
- FP literal returns
- comptime scalar constant multiplication
- debug-location add-immediate rows
- local-exec TLS read
- simple atomic add
- checked ReleaseSafe panic-edge families
- packed/volatile/optional-pointer details
- FP compare/binary/div/rem source-backed shapes
- inline asm and aggregate ABI pair boundaries
- ReleaseSmall mixed C/Zig/i64 boundary rows
- full base64, reduced base64 slices, and `strFromFloatHelp`

The narrower source-wrapper compatibility gate now reports 48 semantic-record
rows and one external writer delegate because it deliberately omits source
fixture/tag metadata. The source-owned gate is the stronger current claim for
release source-backed ownership, and it requires `external_writer_delegate_rows=0`.

## Boundary

This is not full Zig Sema, AIR, or Liveness replacement. The semantic records
are small local descriptions for selected x86_64 release wrappers, and they
feed the structured IR builder. Normal Zig/libLLVM fallback remains available
when the external writer environment is unset, and no Debug, LTO, AArch64, or
target-complete backend claim is made.
