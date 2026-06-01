# x86_64 Native-Link Distribution Slice

This slice defines the first selected x86_64 distribution path where `z_llvm`
owns LLVM-compatible IR parsing, selected optimization, selected object
emission, and final executable proof through Zig's native linker path.

## Contract

`z_llvm` may emit:

```text
ir
asm
obj
```

`z_llvm` must not emit:

```text
exe
shared library
archive
linker script
CRT or dynamic-loader output
```

Final executable, library, archive, CRT, libc, dynamic-loader, and linker-script
ownership remains in Zig's linker/toolchain. Native-linker evidence in this
repository must use:

```text
zig build-exe -fno-lld
```

Plain `zig cc` executable gates are still useful, but they are Zig
driver/toolchain handoff evidence because Zig may select an LLD-backed path
internally.

## Current Slice

```text
name=x86_64-selected-no-llvm-codegen-native-link
target=x86_64-unknown-linux-gnu
cc_target=x86_64-linux-gnu
local_stages=parse, verify, optimize, asm/object
native_linker=zig build-exe -fno-lld
gate=zig build distribution-native-link
probe=zig build probe-native-linker
status=local conservative boundary for selected ABI-stable fixtures
```

Selected fixtures:

```text
ReleaseFast:
  releasefast_tiny_scalar
  releasefast_add_wrap
  releasefast_cmp_shift
  releasefast_branch_mix
  releasefast_loop_sum
  releasefast_comptime_const

ReleaseSafe:
  releasesafe_checked_add
  releasesafe_error_switch

ReleaseSmall:
  releasesmall_i64_return
  releasesmall_unchecked_arith_i64
  releasesmall_hidden_access

Debug:
  debug_shared_library_mathtest_add_o0
```

Latest probe result:

```text
accepted=12
failed=0
failure_categories=symbol, relocation, section, TLS model, COMDAT, alignment,
                   ABI, unknown linker compatibility
```

## Boundaries

This slice does not claim broad executable replacement. It excludes broad CRT
policy, libc integration, dynamic loading, archives, shared libraries, linker
scripts, non-x86_64 object formats, full Debug DWARF/unwind, and runtime paths
that require Zig-owned linker or runtime behavior beyond selected stubs.

The first future `zig build probe-native-linker` failure becomes the next local
object compatibility slice unless evidence proves the failure belongs to Zig's
linker implementation.
