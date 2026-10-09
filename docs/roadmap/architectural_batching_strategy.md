# Architectural Batching Strategy for Real-Rows Convergence

This document establishes the architectural batching methodology for traversing the 14,185-candidate real-rows corpus in `z_llvm`. It defines the transition from reactive, row-by-row pattern probing to proactive compiler capability unlocks, reducing the remaining convergence effort by approximately 8x.

---

## 1. Executive Summary: Linear Probing vs. Architectural Batching

### The Linear Probing Bottleneck (Status Quo)
Historically, the expanded-frontier development has advanced via linear, reactive probing:
1. Run the gate against the next failing row index $N$.
2. Observe a gate rejection or crash (e.g. `unsupported:function_type:Foo` or unhandled IR opcode envelope).
3. Hardcode a string comparison in [`src/zig_air_types.zig`](../../src/zig_air_types.zig) or a narrow pattern envelope in [`src/codegen/x86_64/generic_cfg/`](../../src/codegen/x86_64/generic_cfg/).
4. Re-test, advance by 5–8 rows, commit, and repeat.

**Cost**:
- Average velocity: ~5–8 rows per commit, taking 1.0–1.5 hours per cycle.
- Projected commits to traverse the 14,185 corpus: **~350–400 commits** (~400–600 engineering hours).
- Fragmentation: High risk of duplicate, brittle pattern matchers and monolithic string tables.

### The Architectural Batching Paradigm
Instead of reacting to row index $N$, architectural batching groups the corpus by **orthogonal compiler subsystems**:
1. Identify high-leverage compiler capabilities that block clusters of rows.
2. Implement generalized lowering logic in the core generic engine (verified with comprehensive unit tests across operand widths and register classes).
3. Run the real-rows gate across large ranges (50–200+ rows) to harvest entire families of functions in a single sweep commit.

---

## 2. Empirical Analysis of the 14,185 Candidate Corpus

Analysis of [`tmp/test_real_candidates.tsv`](../../tmp/test_real_candidates.tsv) demonstrates extreme repetition resulting from Zig comptime monomorphization:

| Corpus Tier | Row Range | Total Rows | Dominant Structural Patterns | Redundancy & Leverage Factor |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Remaining** | 666–1,143 | **478 rows** | • `MultiArrayList.capacityInBytes`: **187 rows (39.1%)**<br>• Capacity arithmetic (`imul`/`shl`): **~65 rows**<br>• Small switches & enums (`Token.tag`): **~50 rows**<br>• Small aggregate returns (`Format`, slices): **~85 rows**<br>• Pointer offset RMW (`abs`/`negate`/flags): **~91 rows** | **>80%** of all remaining Tier 1 rows belong to just **5 generic structural templates**. |
| **Tier 2: Calls** | 1,144–2,428 | **1,285 rows** | `ArrayList.append`, `MultiArrayList.set`, internal helper calls | **1 capability** (SysV direct caller dispatch) blocks the entire tier. |
| **Tier 3: Globals** | 2,429–2,692 | **264 rows** | String literals, RIP-relative rodata symbols | **1 capability** (RIP-relative global addressing) blocks the entire tier. |
| **Tier 4: CFG & Loops** | 2,693–14,185 | **11,493 rows** | Top 20 container families account for >2,500 rows | Loops, phi nodes, memory aggregates, error unions. |

---

## 3. The 5 Core Architectural Batches

```
+-----------------------------------------------------------------------------------+
|                           5 CORE ARCHITECTURAL BATCHES                            |
+-----------------------------------------------------------------------------------+
| Batch 1: Automated Dynamic Nominal Type Ingestion                                 |
|          Uses 6,186 pre-exported layout facts -> eliminates unsupported type errs |
+-----------------------------------------------------------------------------------+
| Batch 2: Generalized SysV Eightbyte Packing Engine                                |
|          Offset/size driven packing into %rax:%rdx / sret -> replaces shape stubs |
+-----------------------------------------------------------------------------------+
| Batch 3: Straight-Line Arithmetic, Bitwise & Pointer RMW DAG Engine               |
|          Generalized i8/i16/i32/i64 binary ops -> harvests 187 rows at once       |
+-----------------------------------------------------------------------------------+
| Batch 4: Small-Switch to Speculative Select / Range Check Transform               |
|          <= 4 arms to select/cmov or range bias -> avoids multi-block CFG bloat   |
+-----------------------------------------------------------------------------------+
| Batch 5: Generic SysV Direct Callee Calling Convention (Tier 2 Opener)            |
|          GPR arg mapping, stack alignment, call dispatch -> unlocks 1,285 rows    |
+-----------------------------------------------------------------------------------+
```

### Batch 1: Automated Dynamic Nominal Type & Layout Ingestion
- **Root Problem**: New nominal types trigger `unsupported:function_type`, requiring manual string entries in [`src/zig_air_types.zig`](../../src/zig_air_types.zig).
- **Architectural Solution**:
  - The compiler-core AIR cache already contains **6,186 nominal layout facts** (`fact nominal="..." aggregate="{ ... }"`).
  - In [`src/zig_air_exported_aggregate_layout_facts.zig`](../../src/zig_air_exported_aggregate_layout_facts.zig), connect the active nominal layout table directly into `parseZigType`:
    ```zig
    if (aggregate_layout_facts.findNominal(trimmed)) |summary| {
        return .{ .ir_type = summary.ir_type, .byte_size = summary.total_size };
    }
    ```
- **Corpus Impact**: Permanently eliminates `unsupported:function_type` for every nominal struct in the corpus.

---

### Batch 2: Generalized SysV Eightbyte Classification & Packing Engine
- **Root Problem**: Every new aggregate return shape (`{ ptr, i8 }`, `{ ptr, ptr }`, `{ i64, i8 }`) requires bespoke packers and pattern matching.
- **Architectural Solution**:
  - In [`src/codegen/x86_64/generic_cfg/cabi_aggregate_return_lowering.zig`](../../src/codegen/x86_64/generic_cfg/cabi_aggregate_return_lowering.zig), implement standard SysV classification driven by field byte offsets:
    - Offset $[0, 8)$: pack into `%rax` (shift by `offset * 8`, OR into `%rax`).
    - Offset $[8, 16)$: pack into `%rdx` (shift by `(offset - 8) * 8`, OR into `%rdx`).
    - Total size $> 16$ bytes: route to memory `sret` buffer passed in `%rdi`.
- **Corpus Impact**: Replaces dozens of per-struct emitters with a unified, standards-compliant 120-line ABI engine.

---

### Batch 3: Straight-Line Arithmetic, Bitwise & Pointer RMW DAG Engine
- **Root Problem**: Narrow pattern envelopes exist for specific bitwidths or operations (`lowerMulConstReturn` for 32-bit, `packTwoU32`, etc.).
- **Architectural Solution**:
  - In [`src/codegen/x86_64/generic_cfg/core_single_block_scalar_rows.zig`](../../src/codegen/x86_64/generic_cfg/core_single_block_scalar_rows.zig):
    1. **Constant Binary Return**: Generalized evaluator for `return op(arg, imm)` and `return op(imm, arg)` for `op ∈ {add, sub, mul, and, or, xor, shl, shr}` across all bitwidths `i8, i16, i32, i64`.
    2. **Pointer RMW**: Generalized evaluator for `[arg0 + off] = op([arg0 + off], imm/arg1)`.
- **Corpus Impact**: Generalizing 64-bit `imul` alone instantly unlocks **187 rows of `MultiArrayList.capacityInBytes`**. Generalized RMW covers `math.big.int.Managed.{abs, negate}` and atomic/flag setters.

---

### Batch 4: Small-Switch to Speculative Select / Range Check Transform
- **Root Problem**: Small switch statements or enum tag checks fail because full multi-block switch lowering introduces significant control flow machinery.
- **Architectural Solution**:
  - In [`src/zig_air_lowering_context_typed_cfg.zig`](../../src/zig_air_lowering_context_typed_cfg.zig), generalize `lowerTypedSwitchValueBlock`:
    - Case count $\le 4$: synthesize balanced `select` / `cmov` instructions within a single basic block.
    - Contiguous case sub-ranges: transform into unsigned subtraction and compare `(val - min) <= (max - min)`.
- **Corpus Impact**: Solves ~50 enum classification and token tagging functions in Tier 1 without multi-block CFG overhead.

---

### Batch 5: Generic SysV Direct Callee Calling Convention (Tier 2 Opener)
- **Root Problem**: 1,285 functions in Tier 2 call internal helper functions, failing on `call_class: external` or non-leaf calls.
- **Architectural Solution**:
  - In [`src/codegen/x86_64/generic_cfg/cabi_call_lowering.zig`](../../src/codegen/x86_64/generic_cfg/cabi_call_lowering.zig):
    - Map arguments to SysV register order: `%rdi, %rsi, %rdx, %rcx, %r8, %r9`.
    - Stack alignment: maintain 16-byte RSP alignment across calls.
    - Emit `call <callee_symbol>` and retrieve results from `%rax` / `%xmm0`.
- **Corpus Impact**: Unlocks the entire 1,285-row Tier 2 block in 2–3 milestone commits.

---

## 4. Projected Velocity & Effort Comparison

| Metric | Linear Probing Workflow | Architectural Batching Workflow |
| :--- | :--- | :--- |
| **Tier 1 (478 remaining)** | ~50 commits (~5–10 rows/commit) | **3–4 capability commits** |
| **Tier 2 (1,285 rows)** | ~120 commits (callee-by-callee) | **2–3 commits** (Generic Direct Call ABI Engine) |
| **Tier 3 (264 rows)** | ~25 commits (symbol-by-symbol) | **1 commit** (RIP-relative rodata addressing) |
| **Tier 4 (11,493 rows)** | ~200+ commits | **35–45 commits** (Container families & loop CFG) |
| **Total Estimated Commits** | **~395 commits** | **45–55 commits (~8x velocity improvement)** |

---

## 5. Execution Protocol for Subagent Sprints

When directing subagents during real-rows sprints, follow this operational sequence:

1. **Pre-Flight Analysis**:
   - Inspect the upcoming row block in `tmp/test_real_candidates.tsv`.
   - Identify the dominant structural family (e.g. `MultiArrayList.capacityInBytes`, `Managed.abs`, `Thunk.fmt`).
2. **Subsystem Generalization**:
   - Implement the generic emitter or ABI rule in the appropriate `src/codegen/x86_64/` module rather than writing a single-row envelope.
   - Support standard integer bitwidths (`i8`, `i16`, `i32`, `i64`).
3. **Inner-Loop Verification**:
   - Validate unit test suite: `zig build test-unit`.
   - Validate documentation: `zig build check-docs`.
4. **Batch Gate Probing**:
   - Run the gate across the target window using cached AIR state:
     ```sh
     ZIG_EMITTER=$(realpath ../ziglang/build/stage4/bin/zig) ZLLVM_REAL_ROWS_PRUNING=suspended \
     zig run src/distribution_real_rows_gate.zig -- \
       --mode=ReleaseFast --start-index=<start> --limit=<target> \
       --candidate-file=tmp/test_real_candidates.tsv \
       --export-cache-root=local-state/caches/test-real-rows \
       --runner-temp-root=local-state/validations/test-real-rows
     ```
5. **Multi-Mode Certification & Commit**:
   - Verify `ReleaseFast`, `ReleaseSafe`, and `ReleaseSmall` pass with `local_fail=0`.
   - Update `plan.md` with the new frontier boundary.
