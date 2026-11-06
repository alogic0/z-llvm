# Fibonacci completion and compilation contracts

The working compiler executes unchanged pinned `test/cases/recursive_fibonacci.zig`
in ReleaseFast, ReleaseSafe and ReleaseSmall. All six assertions complete with
the same exit status, stdout and stderr as the LLVM reference. This focused
result is not full integration acceptance.

The source pin is `1c08b09d1c847f4f02c8216e3b62df323861a437`; the source SHA-256 is
`bd530890b4e111b0a9b8e260d766253a243c1a4d8523a01dde073ee2fd44e05b`.
The program is compiled with baseline x86-64, libc and single-threaded startup.
Both objects link against the same pinned Zig compiler runtime and CRT.
LLVM still constructs the input IR. This is not a self-hosting claim.

Raw reports are under
`local-state/validations/fibonacci-completion-20261105/`. The decisive program
report is `fibonacci-three-modes-symbols/report.json`. The Safe object contains
1,568 selected definitions: 1,072 `composed_cfg` and 496 `composed_block`.
Its final object SHA-256 is
`700420531292c9e8b3811fc6c14c02c2c267fd7f513a56a3dc0ab2979e0b8451`.
Emission counts describe coverage; program execution supplies the behavioral
check. Most runtime helpers are not exercised by Fibonacci's successful path.

## Changes

Mandatory semantic normalization now runs before selection. It refines scalar
undef/poison PHI inputs, normalizes narrow comparisons and integer width semantics,
and checks that no required normalization remains. Original source IR and ABI
parameters remain unchanged. Existing whole-function forms retain their complete
envelope proofs and explicit classification. Optional instruction-form rewrites
still use recursive selection and may retry already normalized input; removing
that remaining dispatch dependence is future work.

The shared compilation API separates verification, explicit optimization and
selection. Ordinary object and assembly emission honor `--passes` and
`--pipeline`; pass traces and timing go to diagnostics, outside object bytes.
Route checks compare staged and direct preparation, reject unknown passes,
honor pass limits, exercise AIR input, and execute 201 input values.

Shared register repairs cover overlapping compare moves, accumulator divisors,
live RCX shift sources, 32-bit shift writeback, and odd-width cast sources. The
reviewed C52-0 authority policy reuses a final-use source, preserves a live source
with an existing frame, and otherwise allocates scratch. It adds no direct
register-authority bypass. The entry binding fingerprint changes with the
reviewed vector ABI binding; the bypass ratchet remains 130.

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

The full unit suite passes 1,889 tests in Debug and ReleaseSafe. The validation
policy suite passes 24 tests in each mode. Compilation contract checks pass.
The initial reference-link failure (missing compiler runtime), quoted-symbol
link failure, and earlier vector failures remain in the raw evidence.

## Boundaries and next acceptance

Vector PHIs, oversized vectors, stack-passed vectors, arbitrary wide-memory and
wide-ABI shapes, indirect-branch PHI edges, unsupported assembly, and custom
layouts outside the checked envelopes remain rejected. General i128 products
are not admitted by the bounded constant checked-multiply lowering. The new
symbol boundary does not change the IR verifier's existing name lookup rules.

`zig build fibonacci-regression -- --output-root DIR` runs the permanent
three-mode check. Full integration also runs it after the existing unchanged
program gate. Accepted status remains at `9a8cc1c9` until all 17 integration gates
pass on the completed checkpoint. The next breadth milestone adds diverse
unchanged programs and executes more callable compiler-core functions. Historical
performance measurements remain separate; this work does not establish an
optimization-quality or speed claim.
