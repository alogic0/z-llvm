# Checked multiply operand transfers

Status: complete and accepted at `29e034a7`, following the quoted-symbol
checkpoint at `a9e9c0f1`. The complete serial integration run passes all 17
gates and 63 native populations. All 62 preceding populations are preserved.

Plan: [checked multiply operands](../plans/2026-11-08-checked-multiply-operands.md).
Contract and upstream mapping: [scalar transfers](../codegen/checked_multiply_operands.md).
Record: [acceptance JSON](checked_multiply_operands_acceptance_20261108.json).
Raw evidence: `local-state/validations/checked-multiply-20261108/`.

## Implementation

The shared scratch-register loader now accepts validated 32- and 64-bit integer
literals. Validation precedes any register preservation or instruction mutation.
The existing clobber authority preserves live destination aliases, and a direct
MOV materializes the literal without changing RAX or EFLAGS. A 32-bit transfer
clears the upper bits. Fixed-product RAX/RDX/RCX preservation and the existing
selection rollback contract are unchanged.

This closes the 59 observed unsigned overflow-multiply operand rejections.
Their spilled left operands mostly came from selects, and argument facts
prevented the optional literal rewrite from handling them. Those facts remain
on the original call. No name-specific selector or new literal rewrite is added.
Literal accumulator operands, unsupported widths, undef/poison values, and
unsupported ABI envelopes retain their preceding boundaries.

## Complete original-input replays

| Population | Before | After | Rejected | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 7,657 / 8,928 | 7,713 / 8,928 | 1,215 | 0 |
| Runtime | 284 / 455 | 284 / 455 | 171 | 0 |

All 56 additions belong to the targeted group. All 59 functions advance beyond
`composed-block-smulo-i64-rhs`; the observed intrinsic is unsigned despite the
diagnostic spelling. Three functions reach later existing limitations:

- `link.Coff.addReloc`: `composed-block-freeze-width`.
- `link.Elf2.addGlobalSymbol`: `composed-block-freeze-width`.
- `codegen.wasm.CodeGen.airSwitchBr`: `stage2-phi-dst`.

Both production replays match their diagnostic censuses on selected identities
and failure tuples. The compiler audit verifies 3,470,970 events with all 8,928
function starts and ends balanced; the runtime audit covers all 455 definitions.
Both intentionally return a complete blocked selection report. No complete
compiler/runtime object, startup or self-rebuild success is claimed.

## Validation

Debug and ReleaseSafe each pass 1,983 unit tests and 23 structural checks. All
nine readiness commands pass. New units execute full-width constants, signed
and unsigned products, register aliases, spills and neighboring values, and
verify invalid-literal rejection and late-selection rollback.

The new eight-function `checked_multiply` population has 2,048 observations per
executable. An independent C oracle checks products and overflow using 128-bit
arithmetic, live values across calls, aliases, PHIs and guarded memory. Both
direct and accepted-release routes pass in Fast/Safe/Small with frozen Debug
and ReleaseFast compilers: 12,288 local observations against 6,144 references
per compiler build. The prior accepted binary rejects all eight functions at
the target operand boundary. A deliberately wrong constant produces an
executable rejected by the oracle with exit status one.

The cumulative serial run passes all 17 gates in 3,534.12 seconds. All three
authenticated AIR cache hits preserve the prior keys and descriptor sizes.
No producer/cache infrastructure changed, so this code-only slice requires
one cumulative run. The suite records 1,968,132 local observations against
984,066 references across all 63 native populations.

All five fixed Zig programs pass all fifteen program/mode pairs. The Zig input
corpus preserves 87 input/mode pairs and 603 observation controls; the C corpus
preserves 138 pairs and 552 controls. Core fault controls preserve 21 pairs,
22,788 observations and 54 fault detections, exactly matching the prior report.

All three compiler-core modes retain 100 lowered/emitted/linked functions and
twelve executed/accepted functions, with zero local failures. All 36 records
preserve selected object bytes, descriptors and observations; linked sizes
match. Fast/Safe reference wrappers retain their sizes in six records per mode
and grow by eight bytes in the other six. Small reference wrappers retain exact
hashes and sizes. Linked hashes match for four Small records and differ in the
other 32 records. These metadata differences are retained separately; no
whole-executable byte-identity claim is made.

## Identity and retention

Implementation revision: `29e034a72a83844e1a3fdf856da9ae93e71548c7`.
Tree: `d8d0d0be6fd864eb355d166008e43cb47011acf6`.
The frozen manifest verifies 1,770 compiler/tool/test/build files; the complete
source-membership snapshot verifies 3,082 files before and after validation.

| Compiler build | SHA-256 |
| --- | --- |
| Debug | `d42208587b7e64284091d5ec9519d3f078289e83e23c2c66d8e98003f293b4b5` |
| ReleaseSafe | `342b1591aa1e3ccd07fa379193b523674feaddb1303455f3c8a294d54d0fa67d` |
| ReleaseFast | `bc6a282e7b8e6c58890c190bc38fafb0c97a140edadddc71ded3fd476b3457b7` |

The suite Debug binary matches the frozen Debug binary exactly. Integration
hooks and the larger Zig/C input corpora use the frozen ReleaseFast binary;
the upstream C/native population consumer uses the authenticated Debug binary.
The project compiler remains Zig 0.17.0; the fixture emitter remains at pin
`1c08b09d1`. The installed LLVM comparison compiler is clang 22.1.8.

Source, compiler, frontend, original-input and scratch hashes verify. The
artifact manifest seals 461 files with SHA-256
`5d183be6660b5ffb6bffb2e9e0f4b327da26c7771d6ff6ef61d91f61269913ff`.
Original inputs, prior evidence, AIR payloads and all thirteen scratch files
remain. No manual cache retirement or archives were performed.

Serial admission starts at 39,753,142,272 free bytes; the reported minimum is
36,237,893,632 bytes, above the unchanged 11,410,065,408-byte reserve. The
20 GB admission setting and 8 GiB working allowance are unchanged. Filesystem
samples and timings include concurrent activity; they are not exclusive disk
usage or compiler-throughput measurements.
