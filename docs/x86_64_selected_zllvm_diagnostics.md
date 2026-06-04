# x86_64 Selected z_llvm Gate Diagnostics

`zig build distribution-x86_64-selected-zllvm` is the stable compact gate for
the current selected x86_64 release-mode replacement claim. It runs the external
IR-writer integration path and prints one machine-readable result line:

```text
selected-zllvm status=ok total=<rows> executable_ok=<count> link_only_ok=<count> minimal-ret0=0 ownership=<marker> first_failure_case_id=- first_failure_wrapper=- first_failure_mode=- first_failure_pipeline=- first_failure_error=-
```

The ownership marker for a passing selected row set is:

```text
ir-construction=z_llvm-external-textual-subset;llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
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
ZLLVM_IR_PATH=<temporary external textual IR path>
ZLLVM_MARKER_PATH=<temporary marker path>
```

`ZIG_EMITTER`, `ZIG_SOURCE_DIR`, `ZLLVM_EXE`, and `TARGET` may be overridden by
the caller, but the selected claim is only for the target above and the
currently patched stage4 Zig emitter.

## Common Failures

`missing hook env`:
The detailed runner failed to find a hook marker, or the marker lacks
`ir_writer=external` / `ir_writer_mode=external`. Confirm the selected gate is
used instead of a raw `zig build-obj` command, and confirm the patched Zig
emitter is `../ziglang/build/stage4/bin/zig`.

`wrong z_llvm`:
The marker points at an unexpected tool, the binary is missing, or the emitted
IR lacks the expected `zllvm_ir_writer_surface` comment. Run `zig build` first
and use `ZLLVM_EXE=zig-out/bin/z_llvm` unless intentionally testing another
binary.

`libLLVM fallback detected`:
The selected runner fails if a selected IR-writer row reports libLLVM-backed IR
construction, libLLVM module parse/print, LLVM TargetMachine object emission,
or `minimal-ret0`. Env var unset is normal Zig/libLLVM behavior, but the
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
