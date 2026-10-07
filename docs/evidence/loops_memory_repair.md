# Loop-memory optimizer TypeMismatch repair

This slice reproduces and repairs the frozen `loops_memory/release-o3` optimizer
`TypeMismatch` limitation, proves semantic equivalence against the original
program and independent LLVM, adds focused regression tests, versions the
performance manifest to v2 with all 15 pairs supported, and records baseline
measurements.

## Root cause analysis and reproduction

The behavioral fixture [`test/behavioral/loops_memory.ll`](../../test/behavioral/loops_memory.ll)
allocates a single-element array:
```llvm
%slot = alloca [1 x i32], align 4
store i32 %x, ptr %slot, align 4
```
Direct accesses inside the loop load and store `i32` via opaque `ptr %slot`
without intermediate `getelementptr` instructions:
```llvm
%old = load i32, ptr %slot, align 4
...
store i32 %new, ptr %slot, align 4
```

Under the `--passes=release-o3` pipeline, two independent issues interacted to
cause a fatal IR verifier crash:

1. **SROA GEP-only slice collection and type mismatch**:
   `src/passes/sroa.zig` previously collected partition slices exclusively from
   `gep` instructions in `AllocaSlices.collect`. Because `loops_memory.ll` has no
   GEPs, zero slices were collected. The fallback `hasWholeAggregateAllocaAccess`
   only recognized accesses matching the full aggregate type (`[1 x i32]`),
   ignoring direct scalar accesses (`i32`) to the zero-offset field. Consequently,
   SROA left `%slot = alloca [1 x i32]` untouched.

2. **mem2reg missing alloca-type invariant check**:
   When `mem2reg` executed next in the pipeline, `isPromotableStackSlot` verified
   that memory accesses had no memory barriers, atomic operations or escapes,
   but failed to check that `load.ty` and `store.ty` matched `alloca.allocated_ty`.
   It promoted `%slot` using `instruction.kind.alloca.allocated_ty` (`[1 x i32]`),
   inserting `%slot.0 = phi [1 x i32] ...`, but populated incoming values from the
   stores (which had type `i32`). The SSA IR verifier rejected this with
   `error.TypeMismatch` in `verifyPhiIncomingValue`.

## Implementation

The repair addresses both layers:

- **`src/passes/mem2reg.zig`**:
  `isPromotableSingleBlockSlot` and `isPromotableStackSlot` now require that every
  load and store targeting the alloca strictly matches `alloca.allocated_ty`.
  If an alloca has mismatched direct accesses, `mem2reg` leaves it in memory
  intact, matching the behavior of LLVM's `PromoteMemoryToRegister`.

- **`src/passes/sroa.zig`**:
  - `AllocaSlices.collect` inspects direct `load` and `store` instructions targeting
    aggregate allocas. When an access matches the type of field 0
    (`memory_location.aggregateFieldType(root_ty, 0)`), an aggregate field slice
    at offset 0 is created.
  - `aggregateAllocaOnlyUsesPartitions` validates direct field accesses via
    `directFieldAccessMatches`.
  - `validateAggregatePartitionConsumers` permits GEPs on the alloca root when
    validating direct field partitions.
  - `partitionForPointerAndType` binds loads and stores to the replacement alloca
    matching the access type.
  - SROA transforms `%slot = alloca [1 x i32]` into `%slot.sroa.0 = alloca i32`,
    enabling `mem2reg` to promote `%slot.sroa.0` into pure SSA registers
    (`%slot.sroa.0.0 = phi i32 [ %x, %entry ], [ %new, %body ]`).

## Verification and test coverage

1. **Focused regression tests**:
   [`src/tests/codegen_x86_64_opt_and_normalization.zig`](../../src/tests/codegen_x86_64_opt_and_normalization.zig)
   adds two unit tests:
   - `sroa scalarizes single-element array with direct load and store accesses`:
     verifies that SROA scalarizes and promotes `%slot = alloca [1 x i32]` with
     direct `i32` accesses into register SSA identical to LLVM.
   - `mem2reg leaves mismatched alloca and load/store types intact`:
     verifies that `mem2reg` on its own preserves un-scalarized mismatched allocas
     without raising `TypeMismatch`.

2. **Test suite**:
   - `zig test src/tests.zig`: 1,503/1,503 tests pass.
   - `zig build test-unit`: passes.
   - `zig build structural-smoke artifact-store-test check-docs`: passes.

3. **Behavioral differential suite**:
   - `zig build behavioral-diff`: 24/24 programs pass across 3 modes, 10/10 composed
     functions, 0 fallbacks, 6,528 observations matching Clang-22.

4. **Semantic and runtime driver equivalence**:
   - Semantic harness (`test/behavioral/harness.zig`) against Clang-22 -O3:
     all 272 boundary and LCG observations match byte-for-byte.
   - Runtime performance driver (`test/behavioral/performance_scalar.zig`):
     35,651,584 calls produce identical digest `b177366ad40000` matching LLVM-O3.

## Versioned performance matrix and measurements

The original frozen manifest is preserved at
[`test/behavioral/performance_manifest_v1.json`](../../test/behavioral/performance_manifest_v1.json),
and the original baseline evidence is preserved at
[`docs/evidence/fixed_program_baseline.md`](fixed_program_baseline.md).

[`test/behavioral/performance_manifest.json`](../../test/behavioral/performance_manifest.json)
is versioned to schema 1, population `fixed-architecture-programs-v2`, with
`"unsupported": {}`. All 15 pairs are fully supported.

The standalone runner [`tools/fixed_program_baseline.py`](../../tools/fixed_program_baseline.py)
executed two full measurement runs on logical CPU 2 (`AMD Ryzen 7 7840HS`, Zig 0.17.0,
LLVM 22.1.8). Raw measured samples, summaries and identities are retained in
[`docs/evidence/loops_memory_repair/`](loops_memory_repair/).

### Run 1 medians

| Workload | Route | Compile total (ms) | Runtime ± MAD (ms) | Object bytes | Code sections (bytes) | Selection owner |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| arguments_branches | direct | 2.456 | 75.797 ± 0.814 | 816 | 116 | composed_cfg |
| arguments_branches | release-o3 | 2.858 | 75.845 ± 0.730 | 816 | 116 | composed_cfg |
| arguments_branches | llvm-O3 | 22.524 | 44.708 ± 0.457 | 616 | 22 | — |
| **loops_memory** | **direct** | 2.656 | 249.542 ± 1.157 | 816 | 127 | composed_cfg |
| **loops_memory** | **release-o3** | **3.269** | **282.391 ± 0.781** | **816** | **125** | **composed_cfg** |
| **loops_memory** | **llvm-O3** | 24.649 | 80.895 ± 0.655 | 720 | 124 | — |
| nested_calls | direct | 2.005 | 140.147 ± 0.771 | 920 | 88 | composed_block |
| nested_calls | release-o3 | 2.542 | 140.855 ± 0.725 | 920 | 88 | composed_block |
| nested_calls | llvm-O3 | 22.725 | 48.638 ± 0.448 | 712 | 59 | — |
| register_pressure | direct | 2.140 | 98.035 ± 0.490 | 896 | 199 | composed_block |
| register_pressure | release-o3 | 3.040 | 98.141 ± 0.720 | 896 | 199 | composed_block |
| register_pressure | llvm-O3 | 22.933 | 56.993 ± 0.603 | 1040 | 74 | — |
| memset | direct | 3.964 | 63.846 ± 0.354 | 1944 | 798 | composed_block |
| memset | release-o3 | 5.259 | 63.548 ± 0.384 | 1944 | 798 | composed_block |
| memset | llvm-O3 | 26.584 | 15.986 ± 0.435 | 1832 | 275 | — |

### Run 2 comparison

Run 2 confirms stability:
- All 15 object file sizes and executable code section sizes are byte-identical between runs.
- `loops_memory/release-o3`: compile median 3.202 ms (-2.0%), runtime median 288.522 ms (+2.2%), object 816 bytes, code sections 125 bytes.
- All semantic outputs reproduce LLVM-O3 exactly across all 30 executions.
