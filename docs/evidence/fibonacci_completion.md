# Fibonacci completion and compilation contracts

The accepted compiler at `7e1c8bd7` executes unchanged pinned `test/cases/recursive_fibonacci.zig`
in ReleaseFast, ReleaseSafe and ReleaseSmall. All six assertions complete with
the same exit status, stdout and stderr as the LLVM reference. All 17 integration
gates pass on the frozen checkpoint. The [acceptance record](fibonacci_completion_acceptance_20261106.json)
binds the source snapshot, reports, commands and validation results.

The source pin is `1c08b09d1c847f4f02c8216e3b62df323861a437`; the source SHA-256 is
`bd530890b4e111b0a9b8e260d766253a243c1a4d8523a01dde073ee2fd44e05b`.
The program is compiled with baseline x86-64, libc and single-threaded startup.
Both objects link against the same pinned Zig compiler runtime and CRT.
LLVM still constructs the input IR. This is not a self-hosting claim.

Raw reports are under
`local-state/validations/fibonacci-completion-20261105/`. The decisive program
report is `fibonacci-full-acceptance-report.json`, retained from
`full-acceptance-v3`. The earlier focused result remains in
`fibonacci-three-modes-symbols/report.json`. The Safe object contains
1,568 selected definitions: 1,072 `composed_cfg` and 496 `composed_block`.
Its final object SHA-256 is
`700420531292c9e8b3811fc6c14c02c2c267fd7f513a56a3dc0ab2979e0b8451`.
Emission counts describe coverage; program execution supplies the behavioral
check. Most runtime helpers are not exercised by Fibonacci's successful path.

## Changes

Mandatory semantic normalization now runs before generic x86-64 selection. It refines scalar
undef/poison PHI inputs, normalizes narrow comparisons and integer width semantics,
and checks that no required normalization remains. Original source IR and ABI
parameters remain unchanged. Seventeen existing limb and pointer whole-function
forms retain their envelope proofs and explicit classification. Optional instruction-form rewrites
still use recursive selection and may retry already normalized input; removing
that remaining dispatch dependence is future work.

The shared compilation API separates verification, explicit optimization and
selection. Ordinary object and assembly emission honor `--passes` and
`--pipeline`; pass traces and timing go to diagnostics, outside object bytes.
Route checks compare staged and direct preparation, reject unknown passes,
honor pass limits, exercise AIR input, and execute 201 input values. Structured
IR-writer and descriptor envelopes carry a versioned, validated preparation
recipe. Passes execute when the adapter builds its typed module; transporting
the envelope does not claim to produce optimized LLVM IR. Chained requests keep
their order, limits and diagnostic options without changing module ownership.
Typed adapter modules enter the generic selector after preparation. These
fixtures remain bounded semantic recipes; they do not add unchanged-program
execution coverage.

The first full acceptance attempt stopped at integration gate 8 because the
IR-writer optimizer call was rejected. Focused adapter checks then exposed a
legacy Base64 matcher that errored on unrelated removed instructions, TLS
attribute and calling-convention mismatches, missing checked-operation records
and declarations, and indirect calls represented as direct calls. Every
structured case and direct descriptor program now has verification coverage.
The descriptor slice loop now reads its array and length and returns zero on
the empty path. Both preparation routes execute 289 data/length combinations,
the null empty case and the existing wrapper main. A closed nonreturning CFG
may end in a checked local jump; trailing fallthrough and unknown targets stay
rejected. Literal half/float/double bitcasts preserve raw bits, with executable
negative-zero, NaN-payload and subnormal checks. Failed logs remain retained.
Array addressing covers register-held i32 array pointers and normalizes a
leading-zero byte-array GEP to a byte offset. The executable checks include
constant, dynamic and negative offsets; custom layouts remain checked.

Executing the prepared Base64 recipes exposed an incorrect padding-length
expectation: `6 + sext(true) + sext(true)` is 4, not 8. LLVM independently
confirms the original fixture's failure. The fixture is corrected and the
legacy matcher that returned constant success is removed. Eight combinations
of padding bytes and comparison values now agree with LLVM through direct and
optimized generic selection; legacy selection rejects unsupported forms.
The recipe input and output buffers now cover their actual accesses, and
lifetime intrinsics apply to local allocations. These repairs preserve the
upstream source and do not expand the unchanged-program claim.
All 146 IR-writer executions and 100 direct descriptor executions pass focused
checks. The 24 rendered Base64 recipes compile and execute with LLVM 22 and
AddressSanitizer (`base64-reference-v4.json` and `.log`), including corrected
value/block name separation in the textual rendering.

The second full run passes gates 1–12, then stops in the Fibonacci executable
gate. Fast and Small match; Safe's Debug compiler exceeds the program runner's
default 120-second compile deadline. The isolated
`fibonacci-debug-deadline-repro/commands.json` records `timed_out`, return code
124, actual termination -15, and 120.012 seconds for the local compile. The
earlier three-mode focused run used a ReleaseFast compiler. The Fibonacci
manifest now gives compilation and selection-owner replay a 900,000 ms budget;
executable observations retain their five-second limit. Failed compilation,
link and owner-replay stages retain command outcome, return code, deadline,
timing and diagnostics, and the runner prints the termination reason. The
standalone Debug check passes in 739.805 seconds, including a 400.564-second
compile and 324.408-second owner replay. The subsequent full run also passes
all three Fibonacci modes; its Safe compile takes 390.588 seconds. The Safe
object is byte-identical to the earlier passing ReleaseFast-compiler result.

Shared register repairs cover overlapping compare moves, accumulator divisors,
live RCX shift sources, 32-bit shift writeback, and odd-width cast sources. The
reviewed C52-0 authority policy reuses a final-use source, preserves a live source
with an existing frame, and otherwise allocates scratch. It adds no direct
register-authority bypass. The entry binding fingerprint changes with the
reviewed vector ABI binding; the bypass ratchet remains 130.
The reviewed floating-bitcast fingerprint also changes: literal materialization
uses the existing clobber and binding paths without adding authority bypasses.

Bounded lowering closes Linux system assembly, i65/i96 carriers, checked
33–63-bit and two-word arithmetic, exact two-word memory, integer vector lanes,
128-bit SysV vector arguments/results, aligned local stacks, indirect branches,
block addresses and nested packed global records. New machine operations state
their register and control-flow effects. Native differential populations exercise
widths, aliases, calls, PHIs, dirty upper bits, pressure and memory boundaries.

ELF symbol lookup and serialization now share quoted/escaped identity across
composed and legacy lowering. This resolves Safe's local definitions instead of
creating quoted undefined imports. Temporary-name collision attempts release
their allocations; a testing-allocator regression covers parameter, block and
instruction-name collisions.
The subsequent Debug re-emission of the original retained Safe input succeeds
with 1,568 emitted definitions, zero failures and no allocator leak diagnostics
(`retained-safe-clean.json` and `.log`).

## Focused execution evidence

Every report below compares local direct and optimized objects with LLVM in all
three modes. Counts are observations, not unique source programs.

| Population | Local observations | LLVM observations | Report directory |
| --- | ---: | ---: | --- |
| System assembly | 6,912 | 3,456 | `system-assembly-final` |
| i65/i96 operations | 73,728 | 36,864 | `wide-modes` |
| Two-word memory | 32,256 | 16,128 | `pair-stack-memory-modes` |
| Checked two-word arithmetic | 49,152 | 24,576 | `checked-pair-modes` |
| Checked scalar arithmetic | 110,592 | 55,296 | `checked-scalar-modes` |
| Integer vectors | 795,648 | 397,824 | `variable-vectors-modes` |
| Aligned stacks | 36,864 | 18,432 | `aligned-stack-modes` |
| Indirect branches and packed records | 18,432 | 9,216 | `packed-branches-modes` |
| Vector ABI | 15,360 | 7,680 | `vector-abi-modes-v3` |

The full unit suite passes 1,897 tests in Debug and ReleaseSafe. The validation
policy suite passes 26 tests in each mode, including silent timeout reporting
and compile-budget validation. Compilation contract checks pass.
All 19 structural checks, 60 ABI comparisons and readiness components pass.
The unit, structural, ABI and readiness results precede the timeout-only tooling
commit; their compiler sources and build configuration are unchanged. The
acceptance record binds that source comparison and the new policy results.
The initial reference-link failure (missing compiler runtime), quoted-symbol
link failure, and earlier vector failures remain in the raw evidence.

## Full acceptance

`full-acceptance-v3` passes all 17 gates in 3,678.023 seconds. Its 44 native
populations check 1,718,508 local observations against 859,254 LLVM observations
across three modes and both local routes. The unchanged compiler-core prefix
still lowers, emits and links 100 functions and executes five per mode. Its
24 canonical records match the preceding accepted checkpoint. The full log's
1,443 canonical records pass structural validation; self-comparison is not a
claim that the expanded log equals the older one.

The 2,915-file source snapshot verifies unchanged after the run. Minimum free
space is 47,936,503,808 bytes, above the 24,359,738,368-byte execution reserve.
The original 13 scratch files and diagnostic worktree remain intact. No
archives were created. Both earlier failed full runs remain retained.

## Boundaries and next work

Vector PHIs, oversized vectors, stack-passed vectors, arbitrary wide-memory and
wide-ABI shapes, indirect-branch PHI edges, unsupported assembly, and custom
layouts outside the checked envelopes remain rejected. General i128 products
are not admitted by the bounded constant checked-multiply lowering. The new
symbol boundary does not change the IR verifier's existing name lookup rules.

`zig build fibonacci-regression -- --output-root DIR` runs the permanent
three-mode check. Full integration also runs it after the existing unchanged
program gate. The [execution-breadth plan](../plans/2026-11-06-execution-breadth.md)
adds diverse unchanged programs and more callable compiler-core functions.
Exploratory tagged-union and aggregate programs still fail Fast/Small emission;
their largest observed blocker is parallel register-copy cycles. These probes
are not accepted execution coverage. Historical performance measurements remain
separate; this work does not establish an optimization-quality or speed claim.
