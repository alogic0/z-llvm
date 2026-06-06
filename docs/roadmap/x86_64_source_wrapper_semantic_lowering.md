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
   inventory starts from wrapper, fixture, and source-tag metadata; patched Zig
   then emits a stable source-derived descriptor file instead of using case-id
   ownership.
4. DescriptorV2 semantic proof: z_llvm consumes that descriptor input directly
   and lowers real typed DescriptorV2 programs into
   `src/structured_ir_builder.zig`, instead of routing through surface/body
   adapters, canned return descriptors, or manifest-shaped structured
   templates.

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
release_source_rows=100
source_wrapper_rows=100
descriptor_owned_rows=100
descriptor_v2_rows=100
real_descriptor_program_rows=100
zig_emitted_descriptor_rows=100
runner_generated_descriptor_rows=0
descriptor_file_consumed_rows=100
source_derived_descriptor_rows=100
tag_table_descriptor_rows=0
body_enum_dispatch_rows=0
surface_to_body_adapter_rows=0
canned_return_descriptor_rows=0
manual_fixture_dispatch_rows=0
legacy_semantic_record_rows=0
semantic_record_rows=0
external_writer_delegate_rows=0
semantic_lowering_rows=100
manifest_structured_rows=0
case_id_rows=0
surface_dispatch_rows=0
structured_direct_rows=100
generic_codegen_rows=100
zig_compile_context_descriptor_rows=100
env_source_tag_selector_rows=0
wrapper_body_selector_rows=0
source_tag_body_selector_rows=0
fixture_metadata_selector_rows=0
source_tag_env_present_rows=0
fallback_rows=0
local_fail=0
```

This gate closes the old wrapper/mode collision gap with distinct compiled
source wrappers and compile-context descriptor extraction. The accepted path no
longer receives `ZLLVM_SOURCE_TAG`; source fixture text is diagnostic only.
Patched Zig emits a stable `zllvm-source-facts-v1` fact stream, z_llvm
classifies that fact stream into DescriptorV2, verifies the DescriptorV2 program
with real blocks/instructions, and lowers it into structured IR without
consulting `IrWriterCase` as the ownership source or resolving a Zig-side
wrapper/fixture/tag table. The emitted writer header records
`zllvm_ir_writer_dispatch = "source-owned"`, `zllvm_ir_writer_source_fixture`,
`zllvm_ir_writer_source_tag`, `zllvm_semantic_descriptor = "descriptor-owned"`,
`zllvm_semantic_descriptor_version = "v2"`,
`zllvm_descriptor_program = "real"`,
`zllvm_source_derived_descriptor = "used"`,
`zllvm_tag_table_descriptor = "not-used"`,
`zllvm_body_enum_dispatch = "not-used"`,
`zllvm_surface_to_body_adapter = "not-used"`,
`zllvm_canned_return_descriptor = "not-used"`,
`zllvm_manual_fixture_dispatch = "not-used"`, and
`zllvm_surface_dispatch = "not-used"`; the row selector remains
`ZLLVM_CASE_ID=source-wrapper-dispatch`, so case ids are not the ownership
selector for this gate.

The source-owned release gate also reports a source-wrapper discovery bucket
from `test/zig/integrated/*.zig`: `discovered_source_wrappers=82`,
`descriptor_supported_wrappers=82`, `out_of_scope_wrappers=0`, and
`unsupported_with_reason=0`. This is a discovery bucket for the 100-row
source-owned gate, not an additional accepted row set in the narrower
source-wrapper compatibility gate.

## Semantic-Lowered Families

DescriptorV2 currently models these source-level program families before
building structured IR in the source-owned gate:

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

The narrower source-wrapper compatibility gate still reports 48 semantic-record
rows and one external writer delegate because it deliberately omits source
fixture/tag metadata. The source-owned gate is the stronger current claim for
release source-backed ownership, and it requires `descriptor_owned_rows=90`,
`descriptor_v2_rows=90`, `real_descriptor_program_rows=90`,
`zig_emitted_descriptor_rows=90`, `runner_generated_descriptor_rows=0`,
`descriptor_file_consumed_rows=90`, `source_derived_descriptor_rows=90`,
`tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`,
`surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`,
`manual_fixture_dispatch_rows=0`, `surface_dispatch_rows=0`, and
`external_writer_delegate_rows=0`.

## Boundary

This is not full Zig Sema, AIR, or Liveness replacement. DescriptorV2 is a
small local AIR-shaped descriptor language for selected x86_64 release
wrappers, and it feeds the structured IR builder. Normal Zig/libLLVM fallback
remains available when the external writer environment is unset, and no Debug,
LTO, AArch64, or target-complete backend claim is made.
