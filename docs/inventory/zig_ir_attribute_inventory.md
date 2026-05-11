# Zig-Emitted IR Attribute Inventory

This inventory records the function/module attribute surface visible in the
current Zig-emitted corpus. It is intentionally a semantic boundary document:
most attributes are preserved textually, and only memory effects used by local
optimizer legality are interpreted.

## Accepted Textual Attributes

```text
function header: unnamed_addr, local_unnamed_addr, align N, #N groups
function attrs: mustprogress, nofree, norecurse, nosync, nounwind, willreturn
function attrs: uwtable, minsize, optsize, cold, noinline, alwaysinline
target attrs: "frame-pointer"="all"
target attrs: "target-cpu"="..."
target attrs: "target-features"="+feature,-feature,..."
intrinsic attrs: nocallback, nocreateundeforpoison, speculatable
memory attrs: memory(none), memory(read), memory(argmem: read)
memory attrs preserved conservatively: memory(readwrite, ...), target_memN fields
metadata: !llvm.module.flags preserved opaquely
```

## Semantic Interpretation

```text
memory(none) -> readnone call effect
memory(read) -> readonly call effect
memory(argmem: read) -> readonly call effect
readnone/readonly tokens -> matching call memory effects
unknown or readwrite memory(...) -> unknown call effect
```

`"target-cpu"`, `"target-features"`, `"frame-pointer"`, `uwtable`, size
attributes, and target memory fields are parser/printer-preserved metadata only.
No optimizer, cost model, vector legality rule, or backend selection rule is
allowed to use them until a target semantics cycle adds explicit tests.

## Source-Backed Rows

```text
tiny_scalar_release_fast: memory(none), uwtable, frame-pointer, target-cpu, target-features
tiny_scalar_release_small_captured: minsize, optsize, memory(none), target features
integers_release_fast: memory(none), intrinsic nocallback/nocreateundeforpoison/speculatable
pointers_memory_release_fast: parameter memory attrs plus volatile memory instructions
aggregates_release_fast: memory(argmem: read), memory(none), target features
control_flow_calls_release_fast: memory(none), always-inline-related attrs
globals_comptime_release_fast: memory(readwrite, argmem: none, inaccessiblemem: none, target_memN: none)
tls_concurrency_release_fast: memory(readwrite, ...), memory(read, ...)
floats_math_release_fast: memory(none), target feature strings
float_compare_release_fast: memory(none), target feature strings
aggregate_abi_release_fast: memory(none), target feature strings
packed_bits_release_fast: memory(none), target feature strings
error_switch_release_fast: memory(none), target feature strings
atomics_inline_asm_debug_release_fast: unsupported atomics/inline asm boundary
```

## Unsupported Or Fail-Closed

```text
sanitize_* attribute groups are rejected.
Unknown call memory effects remain mod/ref barriers.
Target feature strings are never used for optimizer legality.
Vector feature, scheduling, and CPU model semantics are not implemented.
```
