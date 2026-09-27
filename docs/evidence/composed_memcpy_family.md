# Composed memcpy family

This slice adds shared x86-64 composed lowering for the retained
`compiler_rt.ssp.__memcpy_chk` and `compiler_rt.memcpy.memcpyFast` definitions.
The ordinary nonvolatile `llvm.memcpy.p0.p0.i64` uses the existing transaction-owned
copy action. Byte loads/stores, unaligned `<16 x i8>` transfers, default-space
`ptrtoint` to i64, and metadata-only alias-scope declarations supply the remaining
operations. Admission depends on IR shape, with no function-name predicate.

## Retained input and scope

The source is `tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll`, SHA-256
`9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1`.
The [permanent family fixture](../../test/behavioral/memcpy_family.ll) preserves
both definitions byte for byte, including their attribute groups. Aliases expose
the private definitions to the native harness.

| Definition | SHA-256 |
| --- | --- |
| `ssp.__memcpy_chk` | `0f16b4dcaaafc82023bfd1e451838251e13450242c7c24dc6061d9011e23e338` |
| `memcpyFast` | `e80a2cf2aafce20cb63734b7304f32e5fe4ec235ccb97b361cea947965f4a2ea` |

Discovery on the saved baseline compiler and the new compiler uses:

```sh
z_llvm --target=x86_64-linux --input-limit=67108864 \
  --generic-cfg-selector --report-all-codegen-failures --emit=obj \
  tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
```

The 443-function population changes from 267 emitted / 176 rejected to
269 emitted / 174 rejected. Exactly the two definitions above become supported;
no previously emitted function is lost. This discovery population is distinct
from the accepted 285-function compiler-rt and 100-row compiler-core populations.
Accepted counters and fallback ratchets remain unchanged.

New ordinary byte-pointer and byte-vector transfers are limited to acyclic CFGs.
`ssp.__strncpy_chk` now rejects at `composed-block-byte-transfer-cyclic-cfg`.
Comparison loops retain their structural fallbacks. An exploratory broader
admission exposed `ReturnRegisterUndefined` for composed `bcmp`/`memcmp`; those
CFG/return-register proofs are a separate follow-up. Existing readonly integer
load families keep their prior admission.

Subsequent work in the [scalar byte-loop slice](composed_byte_loops.md) resolves
this scalar CFG/return-register boundary and closes retained `ssp.__strncpy_chk`.
The acyclic restriction remains for byte-vector transfers. The counts and
measurements on this page describe the earlier memcpy checkpoint.

Volatile/atomic accesses, other vector shapes, nondefault address spaces,
non-i64 pointer casts, malformed alias markers, unsupported intrinsic attributes,
constant copy lengths, other length widths and memmove remain outside the newly
admitted slice. These are composed-path boundaries, not compiler-wide rejection
claims. Copy pointers and lengths use named scalar homes; general stack-object
and null-pointer copies are not newly admitted. No broader parsing or vector
arithmetic support is claimed.

## Correctness and ownership

Native testing exposed a byte-GEP defect: staging an index already in rcx skipped
preservation before destructive addition. The transaction planner now records
that write even when source and destination registers match. Constant offsets
have the same rule. The regression checks preservation and rollback; the native
offset composition and both retained definitions exercise the resulting code.

Pointer staging uses value-use transactions, and byte-vector stores use the
existing shape-aware vector materializer. The frozen bypass inventory is
unchanged. The two updated source-guard fingerprints reflect the additional
frame trigger and the no-emission pointer cast; operation counts are unchanged.
The unaligned instruction flag defaults to false, preserving existing aligned
encodings. Tests check exact MOVUPS bytes and assembly alongside the old MOVAPS
encoding.

## Executable coverage

`zig build memcpy-diff` verifies IR with opt-22, requires composed ownership for
both real definitions and seven [compositions](../../test/behavioral/memcpy_compositions.ll),
and compares native results with clang-22. The independent reference always uses
the original IR. Direct and release-o3 routes each run with ReleaseFast,
ReleaseSafe and ReleaseSmall harnesses.

Each route/mode checks 8,967 observations: 30 lengths from zero through 1,024,
49 independent source/destination offset pairs, copied and untouched bytes,
unchanged sources, returned pointers, repeated/offset copies, live scalar and
vector values, byte zero extension and pointer alignment bits. The six runs total
53,802 observations. Two bounds failures per run must trap with SIGILL in both
the reference and generated subprocesses: 12 paired trap checks in total.
The integrated-executable gate invokes this same canary.

## Validation evidence

Evidence is retained under `local-state/validations/composed-memcpy-20260926/`.
`input-identities.json` records source, definition and fixture hashes;
`discovery-comparison.json` records the exact failure-set change.

Validation uses Zig 0.16.0 and the retained patched Zig emitter. Completed checks:

- Debug units: 1,495/1,495, including the unchanged source-guard inventory
  (`unit-final.log`); structural tests: 8/8 (`structural.log`).
- Focused ReleaseFast: 15/15 composed-memcpy tests and 7/7 byte-address tests
  (`focused-releasefast-accepted.log`, `gep-releasefast.log`). This does not
  claim a full ReleaseFast unit-suite pass.
- Native canary: six route/mode runs, 53,802 observations and 12 paired trap
  checks (`native-final.log`), repeated successfully inside integration.
- ABI differential: 60/60 paired cases across three modes, with 10 real
  functions matched per mode and negative controls passing
  (`abi-differential.log`).
- Full Tier 3: all 17 distribution subgates pass, `local_fail=0`, in
  2,485,554 ms wall time (`distribution-all.log`). The three real-row modes
  each lower, emit and link 100 rows and execute four cohort members. Their
  reported object caches are hits; executions are not cached. This is new
  development evidence, not a migration of accepted counters.
- The 1,386 source/tool/test/build files recorded before Tier 3 are unchanged
  after it (`source-before-tier3.json`, `source-after-tier3-check.json`).
- The fixed-program comparison below passes all supported semantic checks.

`tier3-trigger.txt` records why new full validation was required: capability
closure, frame/ABI staging changes and the reproduced byte-GEP wrong-code bug.
The initial missing-root preflight ran no subgates; the completed run above is
the integration evidence.

## Fixed-program comparison

The unchanged [baseline protocol](fixed_program_baseline.md) was rerun with the
new ReleaseFast compiler, Zig 0.16.0 and LLVM 22 on CPU 2 of the same host,
before the integration gate. Two warmups and nine measured samples per supported
pair were retained without filtering. All 14 supported outcomes and semantic
outputs match; the loop-memory release-o3 rejection remains `TypeMismatch`.
[Tool/input identities](composed_memcpy_identity.json) pin this run.
[Raw samples](composed_memcpy_performance.json) retain medians, min/max/MAD and
object identities; commands, host/tool/source identities and artifacts are in
`performance-after/` under the evidence root.

Comparison below uses baseline run 2. Times are milliseconds, sizes bytes.
Each timing column shows baseline → after. LLVM codegen timing includes clang's
optimizer as before; local release-o3 timing includes both processes.

| Workload | Route | Compile median | Runtime median | Object bytes | Code bytes |
| --- | --- | ---: | ---: | ---: | ---: |
| arguments_branches | llvm-O3 | 23.717 → 22.314 | 52.991 → 52.330 | 616 → 616 | 22 → 22 |
| arguments_branches | direct | 2.817 → 2.496 | 64.799 → 65.320 | 816 → 816 | 116 → 116 |
| arguments_branches | release-o3 | 3.305 → 3.246 | 66.562 → 64.532 | 816 → 816 | 116 → 116 |
| loops_memory | llvm-O3 | 27.127 → 25.844 | 84.258 → 79.063 | 720 → 720 | 124 → 124 |
| loops_memory | direct | 3.052 → 3.041 | 264.720 → 253.776 | 816 → 816 | 127 → 127 |
| loops_memory | release-o3 | unsupported: TypeMismatch | — | — | — |
| nested_calls | llvm-O3 | 23.423 → 23.205 | 42.502 → 42.447 | 712 → 712 | 59 → 59 |
| nested_calls | direct | 2.223 → 2.145 | 148.668 → 147.927 | 920 → 920 | 88 → 88 |
| nested_calls | release-o3 | 3.094 → 2.858 | 148.380 → 148.370 | 920 → 920 | 88 → 88 |
| register_pressure | llvm-O3 | 24.075 → 24.751 | 49.868 → 49.461 | 1040 → 1040 | 74 → 74 |
| register_pressure | direct | 2.409 → 2.470 | 101.832 → 97.783 | 896 → 896 | 199 → 199 |
| register_pressure | release-o3 | 3.443 → 3.445 | 100.611 → 98.041 | 896 → 896 | 199 → 199 |
| memset | llvm-O3 | 27.481 → 26.778 | 33.124 → 32.833 | 1832 → 1832 | 275 → 275 |
| memset | direct | 4.965 → 4.825 | 88.812 → 63.687 | 1944 → 1944 | 787 → 798 |
| memset | release-o3 | 6.568 → 6.052 | 78.568 → 64.008 | 1944 → 1944 | 787 → 798 |

Twelve objects are byte-identical. The local memset objects retain their 1,944-byte
file size; executable sections grow from 787 to 798 bytes. Disassembly attributes
the 11-byte increase to preserving the rcx offset in `fill_offset` before the
byte-GEP addition. The same preservation is required when that offset remains
live, as in the new memcpy regression. This conservative staging tradeoff is
recorded rather than hidden by changing the frozen program.

Runtime differences are observations, not an attributed speedup: even identical
objects vary, and the baseline already showed substantial shared-host noise.
No general performance improvement or acceptance-counter change is claimed.
