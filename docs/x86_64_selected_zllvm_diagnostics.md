# x86_64 Selected z_llvm Gate Diagnostics

`zig build distribution-x86_64-selected-zllvm` is the stable compact gate for
the current selected x86_64 release-mode replacement claim. It runs the
selected IR-writer integration path and prints one machine-readable result line:

```text
selected-zllvm status=ok total=<rows> executable_ok=<count> link_only_ok=<count> structured_direct_rows=<count> structured_textual_rows=0 textual_boundary_rows=0 generic_codegen_rows=<count> case_specific_codegen_rows=0 minimal-ret0=0 ownership=<marker> first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=- first_failure_error=-
```

The ownership marker for a passing selected row set is:

```text
structured-direct:<count>;structured-textual:0;textual-boundary:0;ir-construction=zllvm-structured-builder:<count>;ir-construction=z_llvm-external-textual-subset:0;llvm-text-parse=not-used-for-structured;llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
```

## Reproducibility

Required local inputs for the current claim:

```text
patched Zig commit: 6113ae4b19f0c1307f405b56694a13c156aa4bef
patched Zig path: ../ziglang/build/stage4/bin/zig
z_llvm path: zig-out/bin/z_llvm
target triple: x86_64-linux-gnu
normalized marker target: x86_64-unknown-linux-gnu
```

Exact selected-writer environment set by the gate:

```text
ZIG_USE_ZLLVM_IR_WRITER=1
ZLLVM_IR_WRITER_MODE=external
ZLLVM_PIPELINE=preopt
ZLLVM_EXE=zig-out/bin/z_llvm
ZLLVM_ZIG_MODE=<ReleaseFast|ReleaseSafe|ReleaseSmall>
ZLLVM_CASE_ID=<selected case id>
ZLLVM_WRAPPER=<paired wrapper path>
ZLLVM_IR_PATH=<temporary external writer artifact path>
ZLLVM_MARKER_PATH=<temporary marker path>
```

The source-wrapper proof uses the same hook plus:

```text
gate: zig build distribution-zig-source-structured-direct
ZLLVM_CASE_ID=source-wrapper-dispatch
ZLLVM_IR_WRITER_DISPATCH=source-wrapper
```

That gate fails if any row reports `case_id_rows != 0`, fallback ownership,
textual LLVM parsing, non-generic codegen, or incomplete lowering accounting.
It currently reports `source_wrappers=49`, `semantic_record_rows=48`,
`external_writer_delegate_rows=1`, and `manifest_structured_rows=0`.

The stronger source-owned release proof uses:

```text
gate: zig build distribution-x86_64-release-source-owned
ZLLVM_CASE_ID=source-wrapper-dispatch
ZLLVM_IR_WRITER_DISPATCH=source-owned
ZLLVM_SOURCE_FIXTURE=<covered release fixture path>
ZLLVM_SOURCE_TAG=<source-backed tag or ->
```

That gate covers the full current x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall
source-backed inventory and fails unless it reports
`release_source_rows=90`, `source_wrapper_rows=90`,
`descriptor_owned_rows=90`, `manual_fixture_dispatch_rows=0`,
`descriptor_v2_rows=90`, `zig_emitted_descriptor_rows=90`,
`runner_generated_descriptor_rows=0`, `descriptor_file_consumed_rows=90`,
`legacy_semantic_record_rows=0`,
`semantic_record_rows=0`, `external_writer_delegate_rows=0`,
`semantic_lowering_rows=90`, `manifest_structured_rows=0`, `case_id_rows=0`,
`surface_dispatch_rows=0`, `structured_direct_rows=90`,
`generic_codegen_rows=90`, `fallback_rows=0`, and `local_fail=0`.

`ZIG_EMITTER`, `ZIG_SOURCE_DIR`, `ZLLVM_EXE`, and `TARGET` may be overridden by
the caller, but the selected claim is only for the target above and the
currently patched stage4 Zig emitter.

## Common Failures

`missing hook env`:
The detailed runner failed to find a hook marker, or the marker lacks
`ir_writer=external` / `ir_writer_mode=external`. Confirm the selected gate is
used instead of a raw `zig build-obj` command, and confirm the patched Zig
emitter is `../ziglang/build/stage4/bin/zig`.
For the source-wrapper gate, also confirm the marker reports
`case_id=source-wrapper-dispatch` and the emitted IR header reports
`zllvm_ir_writer_dispatch = "source-wrapper"`.
For the source-owned gate, also confirm the emitted IR header reports
`zllvm_ir_writer_dispatch = "source-owned"` plus the expected
`zllvm_ir_writer_source_fixture` and `zllvm_ir_writer_source_tag` fields,
`zllvm_semantic_descriptor = "descriptor-owned"`, and
`zllvm_semantic_descriptor_version = "v2"`,
`zllvm_zig_emitted_descriptor = "used"`,
`zllvm_runner_generated_descriptor = "not-used"`,
`zllvm_descriptor_file_consumed = "used"`,
`zllvm_manual_fixture_dispatch = "not-used"`, and
`zllvm_surface_dispatch = "not-used"`. Unsupported descriptor failures print
the first unsupported construct with wrapper, fixture, mode, and source tag.

`wrong z_llvm`:
The marker points at an unexpected tool, the binary is missing, or the emitted
IR lacks the expected `zllvm_ir_writer_surface` comment. Run `zig build` first
and use `ZLLVM_EXE=zig-out/bin/z_llvm` unless intentionally testing another
binary.

`libLLVM fallback detected`:
The selected runner fails if a selected IR-writer row reports libLLVM-backed IR
construction, libLLVM module parse/print, LLVM TargetMachine object emission,
`minimal-ret0`, any selected row reports textual LLVM parsing, any textual
boundary row remains, `structured_direct_rows != 146`,
`generic_codegen_rows != 146`, or any structured-direct row reports
case-specific codegen ownership.
Env var unset is normal Zig/libLLVM behavior, but the
selected gate treats fallback as a failure.

`unsupported target`:
The marker must report `target=x86_64-unknown-linux-gnu` and a Zig target
containing `zig_target=x86_64`. Debug, LTO, AArch64, wasm, and other targets are
outside this selected replacement claim.

`linker failure`:
The selected path links with `zig build-exe -fno-lld -fno-compiler-rt -lc`.
Failures here are native-linker or C runtime handoff issues, not proof of LLVM
TargetMachine use. The compact failure line includes the first case ID when the
detailed runner reported it.

## Fallback Policy

If the external writer env vars are unset, patched Zig uses its normal
Zig/libLLVM behavior. That fallback remains available for ordinary Zig builds.
The selected gate is intentionally stricter: it fails on fallback and only
claims selected x86_64 release-mode IR-writer rows.
