# ReleaseSafe preopt preservation differences

Both qualified native preservation checks passed. Each host build retains all
**8,204 prior command outcomes** and compares all **3,399 backend artifacts**:
**3,381 identical hashes and 18 exact qualified transitions**. Each comparison
uses its corresponding historical host build. The original strict comparisons
remain failed with their original receipts. Fixed-input and four-mode postopt
preservation, followed by final storage closure, remain required for acceptance.

Evidence is under
`local-state/validations/release-safe-preopt-20261115/batch-01/`.
`native-archive-provider/` qualifies exact, byte-verified emitter/source argument
projection, with actual changed/missing provider rejection. Candidate artifacts
are hashed live. The original accepted historical hash manifest remains
`184a43fc349af600d3beda1c086ee26c1f99c85903da696675835642f987e0de`.

| Artifacts per build | Cause | Required proof |
| --- | --- | --- |
| 9 C optimizer/object outputs | The canonical source path changes `__FILE__` and its C array length. | The retained historical input must reproduce every original backend hash and both C cases on both current compilers in all three release modes. The two complete inputs must otherwise be byte-identical after the explicit path/array-length transformation. |
| 6 optimizer outputs for `floating_signs` and `extended_sret` | The qualified D1 repair gives extended negative zero its type-specific hexadecimal spelling. | Reverse only those two literal spellings and recover each original accepted hash exactly. Require LLVM verification of current output, rejection of the historical invalid spelling, and the existing exact-payload native checks. |
| 3 copies of the 455-definition runtime provider object | Two register-source bytes exchange the operands of one commutative 32-bit multiply. | Compare every byte with the retained original object, check the exact two offsets and disassembly, retain identical sections/owners, and complete the independent fixed-runtime census/object/event audits, native observations and faults on both host builds. |

`native-preservation-r4/checks.json` passed on the unchanged candidate. All
**6,724 original faults** are covered: 3,348 native injections and fourteen
fixed-runtime controls per host build. The five addition populations remain
separate, with **207 controls per build**, 414 total. Nine artifact mutation
controls and eight fault-projection mutation controls reject changed, missing,
duplicate, incomplete and unrelated evidence. The nine unchanged artifact
controls reuse their actual completed qualification with explicit provenance.

`preservation-diagnosis/checks.json` passed. The runtime objects have equal size,
3,085,376 bytes, and equal section tables. The only byte changes are offsets
588667 (`f1` to `f9`) and 588669 (`f8` to `f0`). In `__sqrth`,
`movl %esi,%ecx; movl %edi,%eax` becomes
`movl %edi,%ecx; movl %esi,%eax` immediately before `imull %ecx,%eax`.
Both source registers survive the two moves; the product and resulting flags
are the same. The next instruction, `movl %eax,%ecx`, overwrites the differing
scratch operand with that same product, restoring equal register state before
the following shift. No ABI, frame, instruction count or object-layout change occurs.
The old hash is `0c8d7d0f39cf20f4a95fee6ba9a49e4d3fe9a9bcfd025b03fe26046bf3bb428d`;
the current hash is `bf211368ab7408d7a0a264177e7d35da7f91797cfda4dd6e43cbfc0f8dfcf3dd`.

Both `fixed-runtime-Debug/` and `fixed-runtime-ReleaseFast/` complete all 455
definitions with identical owners, independent census/object/ELF audits and
whole-stream event audits. Each passes 21,792 local observations, 21,792 LLVM
observations and fourteen faults. Their original outer checks remain failed
solely at the strict original object-hash assertion, after those consumers
completed. The narrowly qualified runtime transition binds both complete runs.

The runtime object also changes linked executables for `limb_divisions`.
`native-link-proof-r2/checks.json` passed: 36 relinks reproduce every exact
historical/current executable hash across both host builds, all three modes
and direct, release and reference routes. Only the provider input bytes change;
the original object basename is preserved because it affects an ELF file symbol.
All 36 baselines and 108 focused faults pass. The earlier basename-sensitive
failure remains failed and diagnosed.

The qualified fault comparison projects only nine proven executable identities
and 27 associated fault records per build into the unchanged maintained comparer.
The other 3,321 fault executable records retain exact hash equality; identities,
completion, detection, exits and diagnostics remain strict for all 3,348 records.
The original raw executable-hash rejection remains failed. Debug reuses its
actual completed injections from the earlier attempt with explicit provenance;
the final Fast injections execute separately. Neither result receives a claim
that all historical executable bytes are unchanged.

`preservation-delta-proof-r2/checks.json` passed. Both current compilers reproduce
the historical C memory output `04bae115`, release output `898b3801` and object
`ae1a0cfe` in every release mode, with all 12 local and 12 reference case
executions passing. The input transformation checks complete bytes, including
the exact assertion string and its array length. Both old floating texts are
recovered by literal substitution with their exact accepted hashes. LLVM rejects
both with an extended-type constant error, while both current texts verify.
Eight Debug/Fast and default/release combinations pass 1,056 exact payload
observations each, including zeros, infinities, NaNs and adjacent memory guards.
The earlier helper-only compilation failure remains failed and diagnosed.

A qualified preservation result must retain the raw failed comparison and bind
these proofs, exact normalized command keys and both hashes for every reviewed
difference. Missing, duplicate, changed or additional transitions fail. All other
hashes, command outcomes, timeout contracts, counters, fixtures and registry
entries remain strict; the five new native populations remain separate.
Rejection controls have passed before acceptance of this route. The remaining
postopt and closure requirements remain pending. This is an
explicit account of required repair/provider differences, not a new historical
baseline, artifact pin, cross-host equality claim or generic difference waiver.

The fixed compiler preservation run subsequently emitted all 8,928 definitions
and passed identical-owner, independent census/object/ELF and complete event
audits, then failed its original object-hash assertion. That failure remains
preserved. The old object is `d10d0545`; the new object is `16666f10`, both
149,620,056 bytes. Function-level comparison isolates one changed body among
8,929 function symbols: `codegen.sparc64.CodeGen.structFieldPtr`, 10,461 old bytes
and 10,355 new bytes. The other 8,928 function bodies are identical, as are both
data sections. The complete text prefix and suffix outside that function also
match after accounting for its 106-byte size reduction. Its stack frame is
208 bytes smaller and its return block layout differs. These observations
alone do not waive the failed assertion.

`fixed-compiler-diagnosis-r2/` and `fixed-compiler-code-diff/` retain the complete
function comparison and bounded instruction diff. A separate paired-compiler
diagnostic checks the affected field-pointer paths using the real old/new
objects. Its temporary compilers are x86-64 programs; the function's SPARC name
identifies code within the compiled Zig program and grants no new z_llvm target
acceptance. The first helper module-path failure and missing system unwind-link
failure remain diagnosed with their original outcomes.

`compiler-function-native-r2/` passed. Five original field-pointer exports match
the unchanged generation-1 frontend, and 32 additional field-layout exports
match across old/current/generation-1 compilers in Fast, Safe and Small. All ten
completed target compilations are reused with exact identities and retained AIR.
Native execution of both actual function bodies checks 2,048 unused-result and
all 65,535 nonzero error-code paths per object: 135,166 guarded observations.
An actual 24-to-16-byte return-copy mutation is detected. The initial C harness
alignment crash occurred before the target call; its original failure and GDB
diagnosis remain, and the corrected harness uses the actual eight-byte alignment.

`fixed-object-transition/` qualifies this exact compiler pair and the separate
Small-runtime pair, with ten actual rejection controls. It verifies 46,189
compiler symbols, 219,162 outside relocations and all 24 relocation targets and
addends inside the changed function. Other text/data bytes and normalized
metadata remain strict. The original compiler emission is not repeated.

The Small-runtime run completes all 503 definitions and every independent audit,
then retains its strict hash failure. Object `5e1b10b5` becomes `3ce07e71` through
exactly two bytes, offsets 325120 and 325122, in the same `__sqrth` commutative
multiply sequence described above. Every other file byte, symbol and relocation
is identical. This is a separate exact pair, not a general runtime difference
allowance.

The fixed Debug run completes all 7,874 definitions and every independent audit,
then retains its strict hash failure: `4ea9c9b3` to `92825c8e`. Of 7,936 function
symbols, only the vector-float helper and wrapped-squaring test bodies differ;
7,934 bodies and all data sections are identical. `fixed-debug-transition/`
passes the exact layout/relocation qualification and six actual rejection
controls. It verifies 13,754 symbols, 66,809 outside relocations and the twelve
vector-helper and twenty squaring-test relocation targets/addends. Vector code
grows by 1,820 bytes, squaring code shrinks by 1,222 bytes, and existing alignment
padding absorbs the 598-byte net change. All other text, padding and data bytes
are checked completely. The extra native experiment compares all 2,097
ordered old/current local outcomes and detects an injected squaring-test failure.
Both have one pre-existing `behavior.floatop.test.@exp with vectors` failure in
the historical fixed-input experiment. The original fixed-input acceptance was
object delivery/audit proof; this extra experiment earns no normal LLVM outcome
acceptance credit and changes no reference. The separate fresh postopt Debug
suite now matches all 2,097 original normal LLVM outcomes. The
[final acceptance](release_safe_preopt_acceptance_20261116.md) records all four
postopt modes, complete event audits and final storage disposition.
