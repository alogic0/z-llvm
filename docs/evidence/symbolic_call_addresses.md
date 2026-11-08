# Symbolic integer call arguments and the readonly-table frontier

Status: complete and accepted at `b43dd3dc`. Both complete production/event
replays, all 17 integration gates and all 61 native populations pass.
Plan: [symbolic call addresses](../plans/2026-11-08-symbolic-call-addresses.md).
Record: [full acceptance](symbolic_call_addresses_acceptance_20261108.json).
The [earlier focused receipt](symbolic_call_addresses_focused_20261108.json)
remains historical and unchanged.
Raw evidence: `local-state/validations/symbolic-call-20261108/`.

Implementation is frozen at `b43dd3dc`, following `d2903a1c` for shared address
materialization. The baseline implementation is `111f2e0a`, documented at
`088ae654`: 7,116 of 8,928 compiler definitions and 284 of 455 runtime definitions
select. Source, tool, test and build files are hashed before final validation.

## Shared address materialization

The existing symbolic-address parser now recognizes i64 `ptrtoint` constants
whose operands satisfy its existing global/alias and byte-GEP contract. A private
legalization exposes a pointer GEP and same-width SSA cast before each consuming
call. Ordinary calls, indirect calls and the closed Linux syscall path then use
their existing argument transfers, register effects and live-value preservation.
This adds no dedicated constant-address call emitter.

The [LLVM ptrtoint semantics](https://llvm.org/docs/LangRef.html#ptrtoint-to-instruction)
preserve pointer representation bits for equal-width integer casts. Admission
requires the existing integral, little-endian, default-space 64-bit layout and
checked signed 32-bit relocation addends. Unknown widths, spaces, layouts,
expressions, global properties and TLS models retain their boundaries. GEP flags
preserve the address on defined executions. Original IR and call attributes are
unchanged; normalization is idempotent and temporary names account for canonical
quoted identifiers. Integer undef and poison arguments are outside this repair.

The new `symbolic_call` population contains seven functions. Independent C
oracles check ordinary and indirect calls, data-alias identity, a negative address
offset, three symbolic stack arguments, reversed register arguments, PHIs, memory
guards, and live GPR/SSE values across a helper that actually zeroes caller-saved
registers. Syscalls write global bytes, report a bad file descriptor and read into
another region while preserving surrounding bytes. Unit checks verify real GPR
and SSE spills, retained alias relocation identity, rejected grammar/layouts,
global/TLS admission and source-IR ownership.

Each compiler build executes 6,912 local and 3,456 reference observations across
direct/release routes and Fast/Safe/Small modes. The initial fixture combined SSE
parameters with incoming stack parameters, which lies outside the current entry
contract. The final live-value fixture uses six GPR parameters; a separate
function tests outgoing stack arguments. No mixed incoming-stack/SSE capability
is claimed.

## Rejection observations

Readonly-table failures now retain the actual final private GEP, index type,
origin and location, resolved global type/properties, initializer representation,
and decoder error if present. The observer copies these before private IR expires.
A regression compares observed and ordinary rejection results, verifies rollback
and checks that attempt reset clears retained attribution.

## Acceptance boundary

Both complete censuses finish. Compiler selection rises from 7,116 to 7,441 of
8,928 definitions; failures fall from 1,812 to 1,487, a reduction of 325 (17.94%).
Runtime selection remains 284 of 455. Every preceding success is preserved.
Of the 326 targeted functions, 325 select and `main.lldMain` reaches a later
unknown-argument call containing i64 poison. None retains the symbolic-address
candidate. All 115 current unknown-argument calls contain one unresolved
nonliteral candidate: 86 i32 undef, 23 i64 poison and six i64 undef.

All 225 baseline readonly-table failures remain and have complete observations.
Every final GEP has i8 source type and a quoted global pointer. They refer to two
private `unnamed_addr` globals, aligned to eight bytes, with scalar-array
initializers: 213 refer to `[4 x i64]`, and twelve to `[8 x i64]`. All globals
resolve; the closed table decoder declines their shapes. The ordinary pointer
legalizer cannot materialize their quoted names through the current ASCII-only
symbol-address parser. The next shared repair should use the existing canonical
identifier contract throughout symbolic-address handling, including quoted and
escaped names, aliases and ELF relocation identity. Extending the specialized
table-shape list is unnecessary for these ordinary integer arrays.

Frozen Debug and ReleaseSafe each pass 1,970 unit tests and 22 structural checks.
Both frozen Debug and ReleaseFast compilers pass the new native population in
all three modes. The two profile tests, five whole-compiler report tests and
readiness also pass. Both complete production replays match diagnostic selected
identities and failure tuples. Event audits account for all 8,928 compiler and
455 runtime definitions, with no unfinished function or legalizer activity.

All 17 cumulative gates and 61 native populations pass, totaling 1,949,700 local
observations against 974,850 references. Every preceding native population is
preserved. The twelve-function core cohort retains all 36 selected-object and
execution-observation records. Local linked sizes match. Twenty-four Fast/Safe
reference wrappers shrink by 16 bytes, consistent with the shorter validation
path; that explanation is an inference. Their metadata is recorded separately,
without claiming old/new ELF section identity. Ratchet 130 remains unchanged.

All five fixed Zig programs pass in three modes. The larger unchanged Zig
program passes 87 input/mode pairs and 603 observation controls; the C corpus
passes 138 pairs and 552 observation controls. Core controls retain 21
function/mode pairs, 22,788 observations and all 54 fault detections.

## Compiler identity and retained evidence

The suite's first object gate invokes `zig build run`, rebuilding default Debug
after the earlier cache retirement. The final exact-binary check detected a
different hash. Both binaries are retained: focused Debug starts `71b319f7`,
and suite Debug starts `31b84769`. The upstream C/native report authenticates the
suite binary; the full 1,763-file source manifest is unchanged. ReleaseFast
remains `27719fda` and supplies the complete production replays and broader
input-program hooks.

An ELF comparison finds identical machine code, seven identical allocated
sections, unchanged BSS/TLS-zero layouts and byte-identical contents of all
22,132 declared readonly data objects (1,524,002 bytes). The 156,468 differing
allocated bytes lie outside those object ranges in `.data.rel.ro`; debug and
symbol metadata also differ. This establishes the stated section/object
comparisons, not whole-file identity or behavior of arbitrary reads outside
declared objects. The source audit and completed execution suite support
acceptance of the separately identified rebuild. The initial failed comparison
is retained; no compiler source or test expectation was changed to accept it.

Original input IR, prior accepted artifacts, AIR caches and all thirteen scratch
files are preserved. Inactive project caches were retired before builds and
again after focused checks/readiness finished. Thirty-six obsolete temporary
behavioral executables were removed with their sources, objects and logs retained.
Identical completed replay inputs and compiler/object snapshots share storage
through hardlinks; all paths and content hashes remain, and the original frontend
and backend captures remain independent. No archives were created. The storage
inventory and before/after checks are retained under the evidence root. Admission
and execution reserve remain 32,949,672,960 and 24,359,738,368 bytes.

The initial full-suite and runtime-production attempts stopped at admission
before compilation. Resumed validation began with 44.65 GB free and performed
no cleanup while running. Its lowest additional disk sample is 30.82 GB;
final postcheck space is 31.92 GB. The suite took 62.4 minutes. Diagnostic
timings include concurrent validation and profiling and are not throughput
comparisons.

Source, compiler, frontend, original input and scratch identities verify. The
prior accepted artifact manifest and immutable 271-file focused manifest also
verify. Full acceptance seals 831 retained files. Gross allocation accounted
for by the earlier cache retirements, obsolete binaries and identical-file
sharing is 4.35 GB; this differs from net free-space change on the concurrently
used filesystem.

No complete compiler/runtime object, compiler startup or self-rebuild is claimed.
