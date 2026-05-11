# Source-Backed Readiness Audit

This audit closes the first source-backed roadmap wave. It records what the
current corpus proves and which next blockers should drive future slices.

## Refresh Evidence

- `scripts/check_zig_stage4_emitter.sh` confirms
      `../ziglang/build/stage4/bin/zig` is
      `0.17.0-dev.304+9787df942` and matches `../ziglang` HEAD `9787df942`.
- Fresh `tiny_scalar` `ReleaseFast` and `ReleaseSmall` captures are
      byte-identical to the tracked stripped captures.
- Fresh `floats_math` `ReleaseSmall` capture is byte-identical to the tracked
      stripped capture.
- Fresh `tiny_scalar` `ReleaseSafe` raw capture still expands to broad safety
      and std support, so reduced current-revision safety fixtures remain the
      checked evidence.
- The manifest remains intentionally mixed-generation for older rows. The
      `zig_emitter` and `zig_source_revision` columns record row provenance;
      current captures use `0.17.0-dev.304+9787df942` and `9787df9421`.

## Blocker Inventory

Parser:

- Inline asm calls from `atomics_inline_asm_debug_release_fast` are accepted
      only when side-effecting and modeled as conservative memory barriers.
- `atomicrmw` is accepted only in narrow parser/verifier forms and modeled as
      a conservative memory barrier.
- Vector IR is represented only by the future boundary fixture.

Verifier:

- Full atomic ordering, inline asm constraints, and vector lane-operation invariants have
      no verifier contract yet.
- Debug metadata is preserved for reduced fixtures, but large Debug-mode Zig IR
      still needs smaller source-backed reductions before verifier policy can be
      tightened further.

Optimizer:

- Path-aware MemorySSA is still the highest-value precision gap for replacing
      local scans in load CSE/GVN/DSE when source-backed rows require it.
- FP optimizations remain conservative without fast-math, NaN, signed-zero, and
      target-cost modeling.
- AArch64 rows now have a narrow target-independent optimizer-input gate, while
      DataLayout-sensitive memory, ABI, target-cost, and non-host codegen
      transforms remain blocked.

Target:

- AArch64 DataLayout is parsed, and optimizer-input policy blocks broad
      non-host target rows except for the explicit `aarch64-target-independent`
      scalar cleanup alias.
- Target feature and CPU model strings are normalized/preserved, not interpreted
      by pass cost models.

Debug:

- Compile-unit, subprogram, lexical block, and location metadata survive the
      accepted reduced fixtures.
- Debug value salvage, DIExpression details, and large Debug-mode std support
      remain outside the accepted corpus.

Atomics:

- Atomic stores and loads are treated as hard conservative barriers in pass
      fixtures.
- Source-backed `atomicrmw` has a reduced optimizer-input fixture. Full
      syncscope and ordering semantics remain fail-closed.

Backend handoff:

- Machine IR, assembly, and object checks are validation-only.
- TLS lowering, unwind/debug object records, register allocation, and ABI
      lowering are not replacement-ready.

## Next Wave

The next wave should stay source-backed and pull only one bounded blocker at a
time:

1. Vector lane operation boundaries plus target-cost policy decisions.
2. Broader AArch64 promotion after DataLayout-sensitive, ABI, and target-cost
      gates are independently proven.
3. Debug-mode reduction work for large source-backed Debug rows.
4. Path-aware MemorySSA only after a source-backed fixture demonstrates that the
      current conservative scan blocks a needed transform.
