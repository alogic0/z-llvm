# x86_64 Distribution AIR Inventory

This document tracks the count-only distribution inventory gate:

```sh
zig build distribution-zig-air-inventory
```

The gate is intentionally narrower than a replacement claim. It asks patched
stage4 Zig to export `zllvm-air-export-v1` metadata for real Zig distribution
sources in `ReleaseFast`, `ReleaseSafe`, and `ReleaseSmall` for
`x86_64-linux-gnu`, then parses and counts the exported metadata. It does not
require z_llvm lowering, optimization, object emission, native linking, or
executable proof.

Use `--slice=` to choose the inventory slice:

```sh
zig build distribution-zig-air-inventory -- --slice=runtime-libs
zig build distribution-zig-air-inventory -- --slice=compiler-core
zig build distribution-zig-air-inventory -- --slice=compiler-core-module
zig build distribution-zig-air-inventory -- --slice=all
```

The default is `slice=all`, which prints one summary per slice and mode.

## Selected Proof Gates

These gates are replacement evidence. They are listed here only to size the
inventory against the current proven replacement surfaces:

| Evidence | Scope | Current count |
| --- | --- | ---: |
| Source-owned release gate | selected source-owned rows | 100 rows |
| Scale real-AIR gate | cumulative selected/broad/expanded/scale corpus | 216 functions |
| Frontier strict release gate | isolated frontier corpus | 599 functions |

## Runtime-Libs Inventory

`slice=runtime-libs` uses real Zig distribution/runtime roots from
`../ziglang/lib`:

| Source | Class |
| --- | --- |
| `../ziglang/lib/compiler_rt.zig` | compiler-rt runtime root |
| `../ziglang/lib/ubsan_rt.zig` | safety/runtime root |
| `../ziglang/lib/c.zig` | libc boundary root |

Measured with:

```sh
zig build distribution-zig-air-inventory -- --slice=runtime-libs
```

| Mode | Sources | Functions | Globals | Calls | Varargs | Vectors | X87/f80/f128 | Packed/unaligned aggregate uses | Unsupported functions | Unsupported opcodes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 3 | 2381 | 1091 | 7419 | 17 | 863 | 6844 | 672 | 1781 | 10286 |
| ReleaseSafe | 3 | 2450 | 1154 | 11033 | 17 | 863 | 7000 | 700 | 1930 | 13600 |
| ReleaseSmall | 3 | 1571 | 682 | 3941 | 15 | 644 | 7240 | 122 | 1082 | 5042 |

Additional notable counters:

| Mode | Exported function heuristic | Generic/comptime-instantiated heuristic | TLS globals | Inline asm | Switches | Loops | Branches |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 418 | 762 | 4 | 20 | 524 | 1327 | 39959 |
| ReleaseSafe | 428 | 794 | 4 | 20 | 524 | 1331 | 50617 |
| ReleaseSmall | 418 | 420 | 4 | 19 | 361 | 776 | 31210 |

The gate prints one machine-readable `summary distribution-zig-air-inventory`
line per mode, fixed `unsupported category=...` lines, ranked
`top_unsupported` lines, `unknown_opcode` / `top_unknown_opcode` split lines,
`top_unknown_opcode_pair` concrete opcode/data-kind split lines, and ranked
`top_opcode` / `top_data_kind` lines for body-aware slices. Unsupported
category counts are feature occurrences or opcode occurrences in the inventory
stream; they are not lowering failures, because this gate does not lower code.

### Runtime-Libs Unsupported Category Signals

| Mode | Largest unsupported category | Count | First source | First function |
| --- | --- | ---: | --- | --- |
| ReleaseFast | aggregate-abi | 62598 | `../ziglang/lib/compiler_rt.zig` | `global` |
| ReleaseSafe | aggregate-abi | 67292 | `../ziglang/lib/compiler_rt.zig` | `global` |
| ReleaseSmall | aggregate-abi | 34355 | `../ziglang/lib/compiler_rt.zig` | `global` |

Other stable signals:

| Category | ReleaseFast | ReleaseSafe | ReleaseSmall | First observed example |
| --- | ---: | ---: | ---: | --- |
| varargs | 17 | 17 | 15 | `compiler_rt.rem_pio2_large.rem_pio2_large` |
| vector | 863 | 863 | 644 | `compiler_rt.memmove.memmoveFast` / ReleaseSmall `crypto.chacha20...` |
| X87/f80/f128 | 6844 | 7000 | 7240 | global metadata in `compiler_rt.zig` |
| packed aggregate | 672 | 700 | 122 | `compiler_rt.memmove.memmoveFast` / ReleaseSmall `process.abort` |
| inline asm | 20 | 20 | 19 | `compiler_rt.stack_probe.zig_probe_stack` |
| unknown opcode | 10286 | 13600 | 5042 | `compiler_rt.memset` |

## Compiler-Core Standalone Probe

`slice=compiler-core` is a standalone source probe over explicit compiler files
from `../ziglang/src`. It is intentionally retained as
`compiler-core-standalone-probe` evidence in this document because it shows
which obvious compiler roots cannot be inventoried outside Zig's real module
graph. It is not the compiler-path inventory.

| Source | Class | Current status |
| --- | --- | --- |
| `../ziglang/src/main.zig` | compiler entry | parse/import boundary: missing generated `build_options` module |
| `../ziglang/src/Compilation.zig` | compiler core | inventory-ok standalone root |
| `../ziglang/src/Zcu.zig` | current module-root equivalent | inventory-ok standalone root |
| `../ziglang/src/Sema.zig` | semantic analysis | inventory-ok standalone root |
| `../ziglang/src/Air.zig` | AIR definitions | inventory-ok standalone root |
| `../ziglang/src/codegen.zig` | codegen facade | inventory-ok standalone root |
| `../ziglang/src/codegen/llvm.zig` | LLVM codegen hook | parse/import boundary: import outside standalone module path |
| `../ziglang/src/link.zig` | linker facade | inventory-ok standalone root |
| `../ziglang/src/link/Elf.zig` | ELF linker root | parse/import boundary: import outside standalone module path |

Measured with:

```sh
zig build distribution-zig-air-inventory -- --slice=compiler-core
```

| Mode | Sources | Inventory-ok sources | Boundary sources | Functions | Globals | Calls | Unsupported functions | Unsupported opcodes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 9 | 6 | 3 | 1 | 90 | 0 | 1 | 0 |
| ReleaseSafe | 9 | 6 | 3 | 1 | 90 | 0 | 1 | 0 |
| ReleaseSmall | 9 | 6 | 3 | 0 | 10 | 0 | 0 | 0 |

The three boundary sources are the same in all modes:

| Category | Count | First source | First reason |
| --- | ---: | --- | --- |
| parse-import | 3 | `../ziglang/src/main.zig` | `missing-build-options-module` |
| module-root | 0 | - | - |
| comptime-dependency | 0 | - | - |
| non-standalone | 0 | - | - |

Compiler-core unsupported category signals:

| Mode | vector | aggregate-abi | X87/f80/f128 | packed aggregate | unknown opcode |
| --- | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 1 | 87 | 4 | 6 | 0 |
| ReleaseSafe | 1 | 87 | 4 | 6 | 0 |
| ReleaseSmall | 0 | 0 | 0 | 0 | 0 |

The compiler-core numbers are small because standalone type/root files mostly
export definitions and constants, not the fully instantiated compiler call
graph. The important signal is boundary classification: the real compiler path
needs generated build modules and the actual stage4 module graph.

## Compiler-Core Module Inventory

`slice=compiler-core-module` is the actual compiler-path inventory slice. It
invokes the real `../ziglang/build.zig` compiler executable build graph with:

```text
--build-file ../ziglang/build.zig
-Dno-bin -Dno-lib -Dno-langref
-Ddebug-extensions=true
-Dtarget=x86_64-linux-gnu
-Doptimize=<ReleaseFast|ReleaseSafe|ReleaseSmall>
```

The build graph provides the root module/import configuration used for the Zig
compiler executable, including generated `build_options` and the `aro` import.
No stubs are used. The inventory hook still does not require z_llvm lowering,
object emission, native linking, or executable proof.
For this count-only module slice, the runner sets
`ZLLVM_DISABLE_AGGREGATE_LAYOUT_FACTS=1`: AIR bodies, signatures, globals, and
typed payloads are still exported and scanned, but the large aggregate-layout
fact side channel is not emitted because this inventory does not consume it.

The first module-context result was signature/global-only because the real
compiler descriptor is gigabyte-scale. That result established the correct
build/module context but reported `instruction_payload_scan=0`, so calls and
opcode counts were not authoritative. The current slice scans each function's
typed `structured_air-v2` payload, validates that the typed instruction count
matches the descriptor's `instruction_count`, and reports
`instruction_payload_scan=1`. It still does not require z_llvm lowering, object
emission, native linking, or executable proof.

Measured with:

```sh
zig build distribution-zig-air-inventory -- --slice=compiler-core-module
```

| Mode | Sources | Real module context | Generated imports available | Stubbed imports | Functions | Functions with body | Declarations without body | Instructions | Globals | TLS globals | Boundary sources |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 1 | 1 | 1 | 0 | 61326 | 61326 | 0 | 6289585 | 59630 | 16 | 0 |
| ReleaseSafe | 1 | 1 | 1 | 0 | 61951 | 61951 | 0 | 6842493 | 60751 | 14 | 0 |
| ReleaseSmall | 1 | 1 | 1 | 0 | 59837 | 59837 | 0 | 4178468 | 55096 | 16 | 0 |

Compiler-core module body-aware category signals:

| Mode | Calls | Loads | Stores | Stack slots | Branches | Loops/backedges | Switches | Atomics | Inline asm |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 329937 | 589047 | 315284 | 372427 | 1036974 | 25428 | 15593 | 620 | 87 |
| ReleaseSafe | 414768 | 598366 | 317492 | 385116 | 1243546 | 25710 | 15618 | 619 | 88 |
| ReleaseSmall | 324995 | 577888 | 310553 | 366867 | 981856 | 24996 | 15463 | 615 | 86 |

Unsupported category signals now include function bodies:

| Mode | varargs | vector | aggregate-abi | X87/f80/f128 | packed aggregate | unknown opcodes | Unsupported functions |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ReleaseFast | 738 | 15820 | 2255777 | 6194 | 5039 | 340808 | 56211 |
| ReleaseSafe | 745 | 16024 | 2338212 | 6220 | 5548 | 407240 | 57216 |
| ReleaseSmall | 827 | 15808 | 2206792 | 6550 | 4863 | 333877 | 54849 |

The scanner now also emits `aggregate_surface` records to split aggregate
observations into `opcode-shape`, `metadata-type-surface`, and
`abi-type-surface`. The full compiler-core-module table above is the current
saved baseline from before that split was refreshed; the split output has been
validated on `runtime-libs` and the standalone `compiler-core` probe in
`tmp/runtime_libs_aggregate_surface_inventory.log` and
`tmp/compiler_core_standalone_aggregate_surface_inventory.log`. Refreshing the
full module-context table with those new counters remains a long count-only
inventory run, not a lowering milestone.

Top body opcode signals:

| Mode | Highest opcode counts |
| --- | --- |
| ReleaseFast | `dbg_stmt=1582916`, `block=482697`, `br=444541`, `alloc=372427`, `call=329937`, `store=315284`, `bitcast=291270`, `load=588943` |
| ReleaseSafe | `dbg_stmt=1608158`, `block=552975`, `br=514565`, `call=414768`, `alloc=385116`, `store_safe=268309`, `load=598263` |
| ReleaseSmall | `block=461641`, `br=412562`, `alloc=366867`, `call=324995`, `store=310553`, `bitcast=286673`, `load=577785` |

This is the first inventory result that answers "how large is the Zig compiler
path itself?" in the current patched stage4 context. It is much larger than the
current selected replacement proof gates and should drive the next distribution
frontier.

The body-aware priority report derived from these ranked opcode/data-kind,
unknown-opcode split, and unsupported-category summaries is recorded in
`docs/roadmap/x86_64_compiler_core_inventory_priorities.md`.

The strict frontier replacement proof currently covers 599 functions, while the
body-aware compiler module inventory sees roughly 60k functions and 4.1M-6.8M
typed AIR instructions depending on release mode. Existing frontier support
already exercises calls, stack slots, loops, switches, slices, optionals,
error-unions, aggregate ABI rows, atomics, inline asm boundaries, and runtime
safety edges, but the compiler module counts show those forms at two orders of
magnitude larger scale. The inventory therefore measures target size and
category priority; it is not itself lowering, object, linker, or executable
evidence.

## What Is Still Not Inventoried

The following remain outside the current inventory gate:

- Debug, AArch64, LTO, tests, and non-x86_64 target-specific rows;
- libc-heavy rows not visible through the runtime roots above;
- a de-duplicated per-function view across imports. Current counts are per
  exported descriptor root.

## Next Frontier

The largest visible inventory signal is now aggregate/type surface in the real
compiler module graph, followed by debug/value-location opcodes, generic CFG
block/branch volume, call volume, and memory/stack-slot volume. The next
implementation frontier should split those signals into:

1. aggregate metadata that is already representable but counted as broad
   aggregate surface by the inventory scanner;
2. real x86_64 SysV aggregate ABI gaps, especially MEMORY aggregates,
   byval/sret copies, mixed INTEGER/SSE leaves, and nested aggregate layouts;
3. vector and X87/f128 surfaces that should remain explicit ABI boundaries
   unless a deliberately scoped subset is implemented;
4. high-volume unknown opcode/data-kind buckets such as debug opcodes,
   `try`/`try_ptr`, union tag operations, vector reductions/comparisons, and
   switch dispatch forms;
5. call and memory-heavy compiler paths, especially functions combining calls,
   live values, stack slots, aggregate fields, and error-union control flow.

This is still inventory, not replacement evidence. The next replacement work
should pick the largest body-backed categories above and promote them through
typed AIR v2 lowering, generic CFG/codegen, z_llvm object emission, and Zig
native linker proof in focused frontier gates.
