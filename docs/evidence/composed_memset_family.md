# Composed memset family

This slice adds shared x86-64 composed lowering for nonvolatile
`llvm.memset.p0.i64`, pointer returns, and `i8 zeroext` entry parameters. The
selector uses a transaction-owned fill action, preserves live operands across
the existing byte-fill machine sequence, and reserves spill space for staging.
It contains no function-name admission rule and retires no structural fallback.

## Retained input and scope

The retained compiler-rt input is
`tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll`, SHA-256
`9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1`.
On baseline `dc0c79ab`, its composed discovery run selected 443 functions,
emitted 264, and rejected 179. The same run after this change emits 267 and
rejects 176. Exactly these three failures are removed; no new failures appear:

| Function | Exact extracted definition SHA-256 |
| --- | --- |
| `compiler_rt.__memset` | `eb4150e0530d29609e9cbae3dd495ad703d3ca0af2d82f3d2a41520713ed3111` |
| `compiler_rt.memset` | `b1345961c10f79a506c4abab657520dd77837083c167c5a51352130906801023` |
| `compiler_rt.ssp.__memset_chk` | `26ec29b271db1f088b6c15d3de0c6a2a2c106799dc6bede943ea56128c93ffe6` |

The [permanent family fixture](../../test/behavioral/memset_family.ll) retains
those definitions byte for byte, including their attributes. Test aliases expose
them to the native harness. This 443-function discovery population is distinct
from the accepted 285-function compiler-rt and 100-row compiler-core populations.
No accepted counters or denominators change.

`ssp.__strncpy_chk` remains unsupported; pointer-return admission moves it to its
next load-width blocker. Copy and string operations are outside this byte-fill
slice. Volatile fills, other intrinsic address spaces/length widths, opaque
argument attributes, qualified pointer returns, and narrow entry parameters
without `zeroext` remain explicit composed-path rejections. Existing structural
fallback admission is unchanged; these are not compiler-wide rejection claims. Destination operands are named scalar pointer homes;
general stack-object and null fill destinations are not newly admitted.

## Executable coverage

`zig build memset-diff` requires clang-22 and opt-22. It executes the three real definitions and six additional
[composition functions](../../test/behavioral/memset_compositions.ll), comparing
with clang-22 and checking memory against explicit expected bytes. Both direct
lowering and a separate `release-o3` optimization followed by lowering require
composed ownership for every function. The LLVM reference always compiles the
original IR. Harness builds use ReleaseFast, ReleaseSafe, and ReleaseSmall.

Each route/mode run checks 1,442 observations: zero and variable lengths,
all-zero/high-bit/nonzero bytes, unaligned offsets, returned pointers, untouched
surrounding bytes, constants, repeated fills, and arithmetic values live across
the intrinsic. Both bounds-failure paths are checked in separate reference and
generated-code subprocesses.
The six runs total 8,652 observations and 12 checked traps. These counts are a
separate family-and-composition population, not whole compiler program counts.
The integrated-executable distribution gate invokes the same runner.

## Validation

Evidence is retained under
`local-state/validations/composed-memset-20260926/`:

- `discovery-before.log`, `discovery-after.log`, and `discovery-comparison.json`:
  unchanged discovery command and exact failure-set comparison.
- `input-identities.sha256` and `definition-identities.json`: input hashes and
  byte-for-byte correspondence to the retained function definitions and attributes.
- `family-before.log`: all three permanent extracted definitions fail on the
  saved baseline compiler at `stage2-ret-type`.
- `unit-debug.log`: 1,470 unit tests and eight structural smoke tests pass.
  The additions cover acceptance, nearby rejection, pointer returns, dead
  accumulator staging, and rollback after preservation, each argument stage,
  and machine append.
- `focused-debug.log` and `focused-releasefast.log`: focused tests pass in both
  modes. This does not claim that the full ReleaseFast unit suite passes; its
  previously recorded half-NaN bit-pattern mismatch is outside this slice.
- `native-final.log`: all six native route/mode runs pass, with 8,652
  observations and 12 checked traps.
- `interrupted-run.txt` and `distribution-all-interrupted.log`: the first full
  attempt stopped after nine subgates when boundary review identified missing
  address-space rejection in the new pointer-return path. A regression test
  and explicit composed rejection were added before restarting acceptance.
- `distribution-all.log`: the final corrected run passes all 17 subgates,
  with `local_fail=0`, in 2,327,891 ms (38m 48s). The mandatory integrated
  executable gate also passes the complete memset canary. Each compiler-core
  mode lowers, emits, and links 100 rows and passes four execution probes.
- `source-before-tier3.sha256` and `source-verification.txt`: all compiler, tool,
  test, and build sources are unchanged across the final run. `tier3-trigger.txt`
  records the command and ABI/frame trigger; `full-final/` and
  `project-improvement/` retain the runner artifacts.

The final Tier-3 result accepts this bounded real-function family closure.
Accepted population counters remain unchanged; no counter migration or broader
copy/string capability is claimed.
