# Shared packed aggregate repair

Status: accepted at `1bf7b020`; all 17 integration gates pass. The
[machine-readable record](packed_aggregate_acceptance_20261107.json) binds the
implementation, compiler binaries, diagnostics and retained validation artifacts.
The [plan](../plans/2026-11-07-packed-aggregate-support.md) repairs the first
boundary from the [whole-compiler diagnostic](whole_compiler_diagnostic.md).
Raw evidence is under `local-state/validations/packed-aggregate-20261107/`.

## Implementation and scope

The shared IR structure view distinguishes `<{ ... }>` from vectors and ordinary
structures, preserves quoted/nested fields, and exposes packing to the parser,
DataLayout, memory field queries, bounded storage and global constant encoder.
The verifier uses the main type parser. Packed constants round-trip as
aggregates, including empty structures and arrays of packed constants.

Packed field placement omits inter-member alignment; each member still occupies
its allocation size. Nested ordinary structures retain their internal padding,
and arrays advance by the complete packed object size. Queries without a target
layout remain conservative. Global encoding retains explicit alignment, exact
integer bytes, unaligned data/function pointer relocations, and its existing
bounded element/layout envelope. Unsupported aggregate calling conventions
still reject in the ABI planner after successful parsing.

Address normalization composes runtime allocation strides and constant nested
structure offsets through the existing byte-address path. Both packed and
ordinary structures share this path. Invalid field indices, unresolved layouts,
non-i32 structure indices and unsupported address spaces remain boundaries.
No new machine instruction or separate register-transfer mechanism was added.

## Focused evidence

The permanent `packed_globals` native population has six functions and 768
observations per route/mode. Fast, Safe and Small each execute direct and
optimized local objects against LLVM compiling the same IR. Across the three
modes this is 4,608 local observations and 2,304 LLVM observations, with references
reused across routes. Ownership remains composed selection for every function.
The driver checks defined global bytes, nested packed arrays, explicit 64-byte
alignment, data and callable function pointers, negative runtime indices,
nested ordinary padding, i24/x86_fp80 allocation padding, unaligned stores and
surrounding guard bytes.

Unit checks cover parsing and serialization, empty structures, the exact first
rejected real compiler global, malformed constants, arithmetic overflow,
unresolved members, retained ABI rejection, and wrapping runtime address
arithmetic for packed and ordinary structures. The latter also confirms the
source function remains unchanged. Final ReleaseSafe validation passes 1,921
unit tests and 19 structural tests. Final Debug/readiness passes the unit/ABI,
optimizer, parser corpus, handoff, generated behavioral and pipeline-policy
checks. Full integration passes all 17 gates and all 46 native populations:
1,772,268 local observations and 886,134 LLVM observations. All prior native
fixtures and population counts are unchanged. The fixed Zig programs pass;
the migration corpus passes 87 input/mode pairs and 603 observation controls,
and the JSON corpus passes 138 pairs and 552 observation controls. Migration
observations and selection counters match the prior accepted run.

All three core-mode gates pass on the final compiler: 100 lowered/emitted/linked
functions and the existing 12 executed functions per mode. The 36 executed-row
records retain identical descriptors, selected object bytes/hashes, linked
sizes, results, witnesses, observations and statuses. Strict comparison with
the earlier fresh run does not pass: 24 reference wrapper sizes differ, and
independently rebuilt wrapper hashes are not stable identities. The isolated
validation output directory also differs. `core-semantic-equivalence.json`
records every size delta and the three explicitly excluded wrapper fields;
this is not a strict fresh/cache or reference-binary identity claim. The
production comparator and gate expectations are unchanged.

An initial native attempt rejected two multi-index GEPs; the shared address
composition repair above resolves them without altering the fixture. The first
integration invocation failed during root setup before any gate: its new
validation directory was missing and needed the existing cache generation's
basename. The corrected invocation uses an isolated existing directory and the
unchanged accepted AIR cache. Earlier logs and compiler binaries are retained.

## Whole-compiler replay and remaining boundaries

The unchanged compiler input retains SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`
and size 443,624,107 bytes. The independent global syntax census now parses all
36,959 global/alias lines, with zero rejections (previously 111). This is a
syntax result, not a claim that every global can be emitted.

The exact full module now stops later in parsing with `InvalidLabel`. A new
independent definition syntax census examines all 8,928 definitions: 8,921
parse and seven reject. Five report `InvalidLabel`, one `UnsupportedType`, and
one `UnsupportedInstructionMetadata`. Full headers and original line numbers
are retained in `function-census.jsonl`; the first rejected complete definition
is retained in `first-function-failure.ll`.

The first rejection is `codegen.x86_64.CodeGen.InstTracking.trackSpill` at input
line 1,417,786. Its switch default has `[` inside a quoted label. The switch
parser chooses the first `[` without respecting quotes. A reduced LLVM-valid
fixture reproduces the local error; this parser repair is outside this slice.
The syntax census also passes a three-definition control, reports the reduced
one-definition rejection, refuses an existing output/input destination without
changing its hash, and fails unfinished input without reporting completion.

Replaying the unchanged 1,856,543-byte runtime input with the final compiler
still reports `InvalidCast`; vector-fptrunc remains a separate known blocker.
No whole-compiler verification, selection, object, link, startup or self-rebuild
success is claimed. Compiler-core and compiler-rt accepted counters remain
unchanged. The new native population is separate from those fixed populations.

## Resource and provenance policy

Full validation supplies the final ReleaseFast compiler through `ZLLVM_EXE` and
uses the pinned frontend, isolated output directories and existing core AIR
cache. The hello and upstream-C/native runners retain their existing default
to `zig-out/bin/z_llvm`, which is the final Debug build; the broader Zig and
JSON input programs explicitly receive the ReleaseFast binary. Both binaries
are built from the same frozen source.
The full command and reuse rationale are in `cycle-notes.md`. `final-sources.sha256`
freezes compiler, tooling, corpus and build inputs; original scratch files and
prior compiler identities are retained separately. Admission remains
32,949,672,960 bytes and runtime reserve 24,359,738,368 bytes. No archives are
created. The complete run took 3,367.25 seconds. Its gate-boundary free-space
minimum is 30,116,372,480 bytes; additional samples inside the native gate reach
28,582,387,712 bytes and remain above the reserve. These are sampled minima,
not a continuous disk trace.

The 1,725-file source manifest covers `src/`, `tools/`, `test/` and build inputs;
both content and membership verify after the full run. Reports identify the
pre-commit working-tree base `a5f931d8`; the acceptance record binds those
frozen source bytes to the subsequent implementation commit. Original 13
scratch probes and the prior compiler verify unchanged. The final report audit
checks all gates, profiles, corpus controls, native counts and source/compiler
identities. The 24 reference-wrapper size differences described above remain
an explicit limitation of comparison with the older run.
