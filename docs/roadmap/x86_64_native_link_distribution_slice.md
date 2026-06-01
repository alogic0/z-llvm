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
broad_probe=zig build probe-native-linker-broad -- --mode=...
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
  releasefast_call_chain
  releasefast_error_switch
  releasefast_float_compare
  releasefast_floats_math
  releasefast_fp_constants
  releasefast_fp_extended_ops
  releasefast_comptime_const
  releasefast_globals_counter
  releasefast_optional_ptr_value
  releasefast_packed_bits
  releasefast_pointers_memory
  releasefast_tls_concurrency
  releasefast_dense_switch
  releasefast_aggregate_abi_pair
  releasefast_aggregates_error_union_payload
  releasefast_aggregates_optional_payload
  releasefast_aggregates_slice_sum
  releasefast_aggregates_struct_sum
  releasefast_aggregates_array_sum
  releasefast_atomics_debug_location
  releasefast_atomics_inline_asm_barrier
  releasefast_atomics_atomic_add

ReleaseSafe:
  releasesafe_checked_add
  releasesafe_aggregates_checked_sums
  releasesafe_atomics_debug_location_checked
  releasesafe_control_flow_calls_checked
  releasesafe_error_switch
  releasesafe_globals_comptime_checked
  releasesafe_pointers_memory_checked
  releasesafe_branch_mix_checked
  releasesafe_tls_concurrency_checked

ReleaseSmall:
  releasesmall_i64_return
  releasesmall_unchecked_arith_i64
  releasesmall_hidden_access
  releasesmall_mix_c_files_add_zig
  releasesmall_mix_c_files_add_may_panic
  releasesmall_libfuzzer_runner_futex_wait
  releasesmall_libfuzzer_runner_test_name

Debug:
  debug_shared_library_mathtest_add_o0
```

Latest probe result:

```text
executable_abi_proof=zig build distribution-native-link
selected_link_probe=zig build probe-native-linker
accepted=44
failed=0
ReleaseFast accepted=27 failed=0
ReleaseSafe accepted=9 failed=0
ReleaseSmall accepted=7 failed=0
Debug accepted=1 failed=0
failure_categories=symbol, relocation, section, TLS model, COMDAT, alignment,
                   ABI, unknown linker compatibility
```

Latest broad link-only probe result:

```text
gate=zig build probe-native-linker-broad -- --mode=ReleaseFast
summary=tmp/zig_ir/native_link_broad_releasefast.summary
total=17 accepted=17 failed=0 excluded=0 first_failure=-

gate=zig build probe-native-linker-broad -- --mode=ReleaseSafe
summary=tmp/zig_ir/native_link_broad_releasesafe.summary
total=17 accepted=9 failed=8 excluded=0
first_failure=aggregates.zig.ReleaseSafe.x86_64.optimized.ll
first_failure_category=runtime-symbol
boundary=debug.FullPanic runtime symbol ownership remains Zig-owned

gate=zig build probe-native-linker-broad -- --mode=ReleaseSmall
summary=tmp/zig_ir/native_link_broad_releasesmall.summary
total=465 accepted=272 failed=191 excluded=2
first_failure=cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll
first_failure_category=runtime-symbol
boundary=start.posixCallMainAndExit startup/runtime ownership remains Zig-owned

gate=zig build probe-native-linker-broad -- --mode=Debug
summary=tmp/zig_ir/native_link_broad_debug.summary
total=10 accepted=7 failed=3 excluded=0
first_failure=load_dynamic_library_add_o0.ll
first_failure_category=runtime-symbol
boundary=Debug/O0 panic runtime and TLS ownership remain Zig-owned boundaries
```

Broad link-only evidence is not executable ABI evidence. It proves that local
objects can be accepted by Zig's native linker after safe unresolved function
stubs are generated. Runtime symbols, data symbols, TLS symbols, COMDAT,
section, relocation, alignment, ABI, and unknown linker failures remain
classified separately.

Focused native-link object handoff shapes:

```text
tls=ReleaseFast tls_concurrency selected object links through native linker;
    Debug/O0 external TLS symbol C_k remains a TLS-symbol boundary
global_relocation=ReleaseFast globals_comptime and ReleaseSmall hidden-access
                  selected objects link through native linker
private_constants=ReleaseSmall c_abi_main fp128 constants and Debug/O0
                  libfuzzer byte arrays are defined in local ELF objects
comdat=no current selected local object emits COMDAT groups; COMDAT remains a
       classified probe category and future compatibility boundary
```

Per-mode gates:

```text
zig build distribution-native-link-releasefast
zig build distribution-native-link-releasesafe
zig build distribution-native-link-releasesmall
zig build distribution-native-link-debug
zig build probe-native-linker-releasefast
zig build probe-native-linker-releasesafe
zig build probe-native-linker-releasesmall
zig build probe-native-linker-debug
zig build probe-native-linker-broad -- --mode=ReleaseFast
zig build probe-native-linker-broad -- --mode=ReleaseSafe
zig build probe-native-linker-broad -- --mode=ReleaseSmall
zig build probe-native-linker-broad -- --mode=Debug
```

## Boundaries

This slice does not claim broad executable replacement. It excludes broad CRT
policy, libc integration, dynamic loading, archives, shared libraries, linker
scripts, non-x86_64 object formats, full Debug DWARF/unwind, and runtime paths
that require Zig-owned linker or runtime behavior beyond selected stubs.

The first future native-link probe failure becomes the next local object
compatibility slice unless evidence proves the failure belongs to Zig's
runtime, TLS, or linker implementation. Closed local compatibility examples in
this slice include synthesized fp128 constant emission for ReleaseSmall
`c_abi_main` and generic byte-array constant emission for Debug/O0 libfuzzer
runner objects.
