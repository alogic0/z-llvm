# Narrow integer freeze

Status: complete and accepted at `7080d454`, following the checked-multiply
checkpoint at `29e034a7`. All 17 serial integration gates and 64 native
populations pass, preserving all 63 preceding populations.

Plan: [narrow freeze](../plans/2026-11-08-narrow-freeze.md).
Contract and upstream mapping: [freeze aliases](../codegen/narrow_freeze.md).
Record: [acceptance JSON](narrow_freeze_acceptance_20261108.json).
Raw evidence: `local-state/validations/narrow-freeze-20261108/`.

## Implementation and classification

Defined i1 through i32 values now freeze as aliases of their existing 32-bit
argument, scratch or EAX register, or scalar spill slot. Freeze emits no
instruction or mask, preserving EFLAGS and any wider live alias. Consumers
retain their logical width interpretation. Existing i64/i128 admission and
physical location checks are preserved. Unsupported widths/types, incompatible
locations and explicit undef/poison literals retain their preceding boundaries.

The final rejection observer copies private freeze types, results and operand
origins/locations through the state authority. The diagnostic census accepts
an explicit JSON list of function names and rejects empty, invalid, duplicate
or missing entries. This diagnostic extension reproduces all 94 prior failure
tuples before the semantic change. Their widths are i1 (24), i3 (two), i8 (64),
i10 (one) and i16 (three); locations are EAX (22), scratch32 (one) and spill64
(71). No name-specific admission or frozen bypass inventory change is added.

## Complete original-input replays

| Population | Before | After | Rejected | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 7,713 / 8,928 | 7,799 / 8,928 | 1,129 | 0 |
| Runtime | 284 / 455 | 284 / 455 | 171 | 0 |

All 86 additions belong to the targeted group. All 94 freeze-width first
failures advance; eight reach later existing limits:

- Immediate comparison range: `codegen.x86_64.CodeGen.Select.TempSpec.Kind.lock`
  and `codegen.x86_64.CodeGen.resolveCallingConventionValues`.
- FP load pointer: `fmt.parse_float.parseFloat__func_13667` and
  `fmt.parse_float.parseFloat__func_26825`.
- Load width: `link.Elf.markEhFrameAtomsDead` and
  `codegen.aarch64.Select.Value.Index.load`.
- Integer comparison form: `sort.block.binaryFirst__func_14074`.
- Half-precision binary operation: `codegen.spirv.Assembler.parseOperand`.

Both production replays match their complete diagnostic censuses on selected
identities and every rejection tuple. The compiler audit covers 3,466,255
ordered events and 8,928 balanced function starts/ends. The runtime audit
covers 70,654 events and all 455 definitions. Both intentionally return complete
blocked-selection reports. No complete compiler/runtime object, startup or
self-rebuild success is claimed.

## Validation

Debug and ReleaseSafe each pass 1,989 unit tests and 23 structural checks.
All nine readiness commands pass. Executable units cover dirty upper bits,
wider aliases, repeated freezes, boolean branches and rollback. Four historical
limb near-miss snippets now execute through ordinary composed lowering and
explicitly exclude specialized limb pseudo instructions. The source guard
retains its frozen bypass inventory; the existing alias function's reviewed
body fingerprint is updated.

The ten-function native `narrow_freeze` population checks 2,560 observations
per executable, including loads, PHIs, parameters, live values across clobbering
calls and guarded memory. Direct and accepted-release routes pass in
Fast/Safe/Small with frozen Debug and ReleaseFast compilers: 15,360 local
observations against 7,680 LLVM references per compiler build. The prior binary
rejects all ten functions at freeze-width. The independent C oracle rejects a
deliberately wrong low-bit result. The JSON-name filter passes its positive
case and four rejection controls.

The cumulative run passes all 17 gates in 3,558.16 seconds. All three
authenticated AIR cache hits preserve preceding keys and descriptor sizes.
No producer/cache infrastructure changed, so this code-only slice requires
one cumulative run. The suite records 1,983,492 local observations against
991,746 references across 64 native populations; all 63 prior records match.

All five fixed Zig programs pass all fifteen program/mode pairs. The Zig
input corpus preserves 87 pairs and 603 observation controls; the C corpus
preserves 138 pairs and 552 controls. Core fault controls preserve 21 pairs,
22,788 observations and all 54 fault detections, matching the prior report.

All three compiler-core modes retain 100 lowered/emitted/linked functions,
twelve executed/accepted functions and zero local failures. All 36 records
preserve selected objects, descriptors, observations and linked sizes. Fast/Safe
reference wrappers shrink by sixteen bytes in six records per mode and eight
bytes in the other six; their hashes differ. Small reference wrappers preserve
exact hashes/sizes. Three Small linked hashes match and the other 33 linked
hashes differ. These metadata differences are retained separately; no
whole-executable byte-identity claim is made.

## Identity and retention

Implementation revision: `7080d4544ee966079b76270081c6cf10e1d3bd32`.
Tree: `3d78027ce8914fa6c6ec0601aef593774316a4ec`.
The frozen manifest verifies 1,773 compiler/tool/test/build files and the
complete membership snapshot verifies 3,089 files before and after validation.

| Compiler build | SHA-256 |
| --- | --- |
| Debug | `390a68c15dc6d63ade04416b0029f8717203e6adc606baeb58336593043b040e` |
| ReleaseSafe | `52614e382cf8b940f948b6caec55fe2f345e0a4f529ef787f11b986095c52554` |
| ReleaseFast | `868c9734fda533ebc58cba7ae66cf4fad1c94f8a836e98f4d3d3279cca9d8700` |

The suite Debug binary matches the frozen Debug binary exactly. Integration
hooks and the larger Zig/C input corpora use the frozen ReleaseFast binary;
the upstream C/native consumer uses the authenticated Debug binary. Project
Zig remains 0.17.0, the emitter pin remains `1c08b09d1`, and the installed LLVM
comparison compiler is clang 22.1.8. The local LLVM primary-source mapping,
revision and source hashes are retained.

Source, compiler, frontend, original-input and scratch hashes verify. The
preceding sealed 461-artifact manifest also verifies. The new manifest seals
602 artifacts with SHA-256
`aca44d17590daaf93a6d4c7bb5a3ae9127f77367b75741553cfe2c927a404b4a`.
Original inputs, preceding evidence, AIR payloads and all thirteen scratch files
remain. No manual cache retirement or archives were performed.

Serial admission records 52,901,662,720 free bytes; its minimum is
44,723,109,888 bytes. The outer capture's lowest sample is 43,169,914,880 bytes.
Both remain above the unchanged 11,410,065,408-byte reserve. Admission remains
20 GB with the existing 8 GiB working allowance. Timings and filesystem samples
include concurrent activity and are not exclusive usage or throughput measures.
