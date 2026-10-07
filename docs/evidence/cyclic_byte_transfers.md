# Cyclic byte-vector transfers and loop-carried XMM ownership proof

This slice admits cyclic `<16 x i8>` byte-vector loads and stores in composed
x86-64 loops by establishing a verified proof of loop-carried XMM register
ownership. It closes the deferred cyclic byte-vector capability identified in
[composed_byte_loops.md](composed_byte_loops.md) and [next_steps.md](../next_steps.md).

## Problem analysis and XMM ownership proof

Previously, `src/codegen/x86_64/generic_cfg/composed_selector_memory.zig` enforced
an acyclic CFG check (`byteTransfersAreAcyclic`) that rejected any byte-vector
transfer inside a loop. The guard was established because vector transfers lower
through XMM scratch registers (`%xmm0`), and unregulated admission in cyclic CFGs
could clobber loop-carried floating-point or vector values, create inter-iteration
register conflicts, or exceed scratch register availability.

The new proof replaces the blanket acyclic rejection with
`byteVectorTransferIsAdmissible` and `hasLoopCarriedXmmPhi`, establishing five
strictly verified invariants for any cyclic basic block containing vector transfers:

1. **Block-local vector life cycle**:
   Every `<16 x i8>` vector value defined by a load inside a cyclic block must be
   consumed by a store in the *same* basic block. Vector values are not permitted to
   escape the block or cross basic block boundaries.

2. **Sequential single-register ownership**:
   Within a cyclic block, vector loads and stores must be strictly sequential: each
   vector load must be consumed by a corresponding vector store before any subsequent
   vector load is encountered. This guarantees that at most one vector transfer is
   active at any given instruction, ensuring the single temporary `%xmm0` scratch
   register is never subject to overlapping live ranges.

3. **Absence of loop-carried XMM phi values**:
   `hasLoopCarriedXmmPhi` inspects all phi nodes in every cyclic block in the CFG.
   Any phi node whose type is a floating-point scalar (`f16`, `f32`, `f64`, `f80`,
   `f128`) or vector type is rejected. This guarantees that `%xmm0` (and other vector
   registers) cannot carry state across loop backedges that would conflict with
   vector transfer scratch usage.

4. **Absence of external vector definitions**:
   Vector stores in cyclic blocks cannot store vector values defined outside the
   cyclic block (such as function parameters or pre-loop loads).

5. **Acyclic fallback preservation**:
   Acyclic CFGs continue to be unconditionally admitted under the existing verified
   rules.

## Implementation details

- **`src/codegen/x86_64/generic_cfg/composed_selector_memory.zig`**:
  - Implemented `byteVectorTransferIsAdmissible(selector)` to replace `byteTransfersAreAcyclic`.
  - Implemented `hasLoopCarriedXmmPhi(selector)` to verify the absence of loop-carried
    floating-point and vector phi nodes across all cyclic blocks.
  - Implemented `cyclicBlockHasSafeVectorTransfers(function, block)` to verify
    block-local consumption and non-overlapping sequential vector lifetimes.

- **`src/ir/verifier.zig`**:
  - Implemented support for the LLVM `dead_on_unwind` parameter ABI attribute
    introduced by Stage4 Zig 0.17.0 emissions on pointer parameters.

- **`test/zig/integrated/aggregate_sse_returns_start.zig`**:
  - Replaced vector member in `extern struct` with discrete float fields to conform
    to Zig 0.17.0 language specification rules while preserving exact SysV ABI
    register return semantics (`xmm0`).

- **`src/distribution_execution_cohort_v1.zig`**:
  - Updated external revision pin (`1c08b09d1c`), selector version (`0.17.0-dev.11+1c08b09d1`),
    binary length, and SHA-256 constants for Zig 0.17.0 stage4 emitter.

- **`src/distribution_real_rows_gate.zig`**:
  - Updated type reflection from `@"struct".fields` to `@"struct".field_names` for
    Zig 0.17.0 compatibility.

## Verification and test coverage

1. **Focused regression tests (`src/tests/composed_memcpy.zig`)**:
   - Negative rejection tests:
     - Vector load without store in cyclic block (`composed-block-byte-transfer-cyclic-cfg`).
     - Overlapping vector loads before stores (`composed-block-byte-transfer-cyclic-cfg`).
     - Escaping vector use outside defining cyclic block (`composed-block-byte-transfer-cyclic-cfg`).
     - Vector store of value defined outside loop (`composed-block-byte-transfer-cyclic-cfg`).
     - Conflicting loop-carried floating-point phi (`composed-block-byte-transfer-cyclic-cfg`).
   - Positive acceptance tests:
     - Vector copy loop (`@vector_copy_loop`): machine instruction verification,
       assembly check (`movups 0(%rcx), %xmm0` and `movups %xmm0, 0(%rcx)`), and
       bit-exact runtime execution via `mmap` across 0, 32, and 64 byte inputs.
     - Sequential multi-vector loop (`@multi_vector_copy_loop`): verified composed
       selection of multiple sequential vector transfers in a single loop block.

2. **Unit test suite**:
   - `zig test src/tests.zig`: 1,506/1,506 tests pass in Debug mode.
   - `zig test -O ReleaseFast src/tests.zig`: 1,506/1,506 tests pass in ReleaseFast mode.
   - `zig build test-unit`: passes cleanly.
   - `zig build structural-smoke artifact-store-test check-docs`: passes cleanly.

3. **Behavioral and memory-family canaries against Clang-22**:
   - `zig build behavioral-diff`: 24/24 programs pass across 3 modes, 10/10 composed
     functions, 0 fallbacks, 6,528 observations matching Clang-22 byte-for-byte.
   - `zig build memset-diff`: 6/6 programs pass across 3 modes and 2 routes, 9/9
     composed functions, 0 fallbacks, 8,652 observations, 12/12 bounds traps checked.
   - `zig build memcpy-diff`: 6/6 programs pass across 3 modes and 2 routes, 9/9
     composed functions, 0 fallbacks, 53,802 observations, 12/12 bounds traps checked.
   - `zig build byte-loops-diff`: 6/6 programs pass across 3 modes and 2 routes, 7/7
     composed functions, 0 fallbacks, 195,888 observations, 12/12 bounds traps checked.

4. **Integration subgates**:
   - Subgate 1 (`selected-object-suite`): passes.
   - Subgate 2 (`selected-object-inspection`): passes.
   - Subgate 3 (`selected-native-link`): passes.
   - Subgate 4 (`selected-native-probe`): passes.
   - Subgate 5 (`zig-source-native-link`): passes (10/10 cases accepted).
   - Subgate 6 (`integrated-object-postopt`): passes.
   - Subgate 7 (`integrated-object-preopt`): passes.
   - Subgate 8 (`integrated-object-ir-writer`): passes.
   - Subgate 9 (`integrated-object-release`): passes.
   - Subgate 13 (`integrated-executable`): passes (all canaries, executables, and differential suites green).
   - Subgate 14 (`release-object-inspection`): passes.
   - Subgate 15 (`release-native-link`): passes.
   - Subgate 16 (`release-native-probe`): passes (100/100 accepted, 0 failed).
   - Subgate 17 (`boundary-gates`): passes.
