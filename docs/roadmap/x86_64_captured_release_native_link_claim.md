# x86_64 Captured Release Native-Link Claim

This document states the current narrow replacement claim for the captured
`x86_64-linux-gnu` release-mode distribution slice.

## Claim

For the named captured x86_64 release fixtures below, the project no longer
needs LLVM codegen for the selected IR-to-object path:

```text
parse/verify/optimize: z_llvm selected local implementation
asm/object: z_llvm selected x86_64 ELF relocatable object emission
final link: Zig native linker/toolchain only through zig build-exe -fno-lld
z_llvm linker ownership: none
```

Current source-backed evidence:

```text
ReleaseFast captured set:
  input=tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir
  broad_native_link=total=17 accepted=16 accounted=1 local_fail=0
  accounted=libc/compiler-rt=1

ReleaseSafe captured set:
  input=tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir
  broad_native_link=total=17 accepted=8 accounted=9 local_fail=0
  accounted=zig-panic-runtime=8, libc/compiler-rt=1

ReleaseSmall captured set:
  input=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir
  broad_native_link=total=465 accepted=271 accounted=192 local_fail=0
  excluded=2 accounted_total=465
  accounted=zig-startup-runtime=190, zig-tls-runtime=1, libc/compiler-rt=1
  exclusions=float-format-helper-boundary, full base64 decoder boundary
  reduced_closed=base64_table_lookup selected table lookup fixture
```

Validation gate:

```text
zig build distribution-native-link-boundary2
```

Executable ABI proof remains narrower than broad link-only proof:

```text
zig build distribution-native-link
zig build probe-native-linker
selected_total=45 accepted=45 failed=0
per_mode=ReleaseFast 27/27, ReleaseSafe 9/9, ReleaseSmall 8/8, Debug 1/1
```

Zig source integration proof is stronger than checked-IR fixture proof for the
selected rows:

```text
zig build distribution-zig-source-native-link
path=Zig source -> stage4 LLVM IR -> z_llvm object -> Zig native linker
total=10 executable_ok=9 link_only_ok=1 local_fail=0
ReleaseFast executable source rows=5
ReleaseSafe executable source rows=1
ReleaseSafe link-only runtime boundary rows=1
ReleaseSmall executable source rows=3
claim=LLVM codegen is not needed after Zig emits LLVM IR for this selected
      x86_64 source-backed release slice
```

## Boundaries

This is not a broad Zig distribution replacement claim. It does not include
full runtime behavior, CRT policy, libc integration, dynamic loading, archives,
shared libraries, linker scripts, broad Debug metadata/unwind quality, dynamic
TLS models, non-x86_64 object formats, or broad backend register allocation and
scheduling.

Remaining fallback or ownership boundaries:

```text
zig-panic-runtime: Zig runtime-owned panic paths
zig-startup-runtime: Zig startup/runtime entry paths
zig-test-runtime: Zig test/libfuzzer runtime helpers
zig-debug-runtime: Zig debug helper runtime paths
zig-tls-runtime: Zig/native-linker TLS ownership outside selected executable proof
libc/compiler-rt: external libc/compiler-rt functions such as fmod/fmodf/__eqtf2
ReleaseSmall float-format helper: broad multi-block float formatting
ReleaseSmall full base64 decoder: broad table/control-flow decoder lowering
```
