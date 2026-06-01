# Cycle 24 Corpus Refresh Differential Audit

Date: 2026-05-11

## Emitter Provenance

```text
stage4 emitter: ../ziglang/build/stage4/bin/zig
version: 0.17.0-dev.304+9787df942
source checkout: ../ziglang
source revision: 9787df942
check: zig build check-zig-stage4-emitter
result: emitter version matches checkout HEAD
```

## Refresh Sample

The refresh was bounded to representative rows and written under `tmp/`:

| Row | Refresh output | Checked comparison |
| --- | --- | --- |
| `tiny_scalar` Debug x86_64 | `tmp/zig_ir/cycle24/tiny_scalar.Debug.x86_64.ll` | future-only raw row; 344149 lines, not checked in |
| `tiny_scalar` ReleaseSafe x86_64 | `tmp/zig_ir/cycle24/tiny_scalar.ReleaseSafe.x86_64.ll` | future-only raw row; 268030 lines, not checked in |
| `tiny_scalar` ReleaseFast x86_64 | `tmp/zig_ir/cycle24/tiny_scalar.ReleaseFast.x86_64.ll` | byte-identical to `test/zig/captured/tiny_scalar.ReleaseFast.x86_64.ll` |
| `tiny_scalar` ReleaseSmall x86_64 | `tmp/zig_ir/cycle24/tiny_scalar.ReleaseSmall.x86_64.ll` | byte-identical to `test/zig/captured/tiny_scalar.ReleaseSmall.x86_64.ll` |
| `integers` ReleaseFast AArch64 | `tmp/zig_ir/cycle24/integers.ReleaseFast.aarch64.ll` | byte-identical to `test/zig/captured/integers.ReleaseFast.aarch64.ll` |

The checked manifest remains honest: mixed row revisions are recorded per row,
and new authoritative captures use the current stage4 emitter.

## Gates

```text
zig build check-zig-stage4-emitter
zig build readiness
```

`zig build readiness` completed:

```text
zig build test
zig build compare-opt --
zig build lint-zig-ir-manifest
zig build zig-corpus
zig build handoff
zig build generated-scalar-diff
```

Corpus summary:

```text
accepted=30
unsupported=3
future=5
debug-info-only=0
```

## Remaining Gaps

| Group | Remaining gap | Next-finish decision |
| --- | --- | --- |
| Correctness | Full LLVM verifier parity for metadata graphs, EH pads, atomics, vectors, operand bundles, and DataLayout edge cases. | Keep fail-closed parser/verifier tests first; only accept a construct when a source-backed row needs it. |
| Optimizer quality | GVN PRE, full ADCE control-dependence behavior, complete SROA slicing, FP legality, MemorySSA updater, and stronger alias stack. | Prioritize source-backed optimizer deltas that appear in accepted corpus rows before adding generic LLVM passes. |
| Target/backend | Multi-target ABI lowering, register allocation, stack layout, vector ABI, object/debug/unwind, and non-host codegen validation. | Keep local backend work validation-only; pull slices only when optimizer handoff needs assembly/object proof. |
| Debug | `llvm.dbg.value`, `llvm.dbg.declare`, variable locations, assignment tracking, metadata graph validation, and debug-info salvage. | Preserve opaque metadata that is already accepted; defer salvage until a Debug row requires transformation. |
| Atomics/concurrency | Atomic ordering semantics, syncscope, fences beyond representation, TLS lowering, and concurrency-aware optimization. | Continue treating atomics and inline asm as barriers unless a source-backed optimization needs precise ordering. |
| Vector | Vector cost model, vector combines, loop/SLP vectorization, vector FP legality, and target feature policy. | Keep vector rows parse/verify or future until target-cost and backend validation exist. |
| LTO/bitcode | Bitcode writer/parser, ThinLTO summary indexes, import/export, WPD, CFI, and post-link LTO. | Keep optimizer validation text-IR based; activate bitcode only for a concrete Zig handoff use case. |

## Next Wave

The next roadmap wave should be selected from the highest-value source-backed
gaps:

```text
1. Debug value intrinsic and variable-location boundary, if Debug rows become the next blocker.
2. FP legality and conservative transform audit, if ReleaseFast/ReleaseSmall FP quality becomes the next blocker.
3. MemorySSA/alias precision, if GVN, EarlyCSE, DSE, or LICM differences block accepted corpus quality.
4. Vector target-cost policy, if vector rows move from future to optimizer-input.
5. Native backend handoff validation, if a Zig-owned backend comparison needs object or assembly proof.
```
