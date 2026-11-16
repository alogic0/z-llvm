# ReleaseSafe preopt preservation differences

The original strict Debug comparison retains all **8,204 prior command outcomes**
and compares all **3,399 backend artifacts**. It reports **3,381 identical hashes
and 18 differences**. Its failed receipt remains unchanged; this note does not
turn that result into an identity pass. Preservation and final acceptance are
still pending.

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
Qualify rejection controls before using this route. The fixed-input and postopt
requirements remain pending, including the runtime audits above. This is an
explicit account of required repair/provider differences, not a new historical
baseline, artifact pin, cross-host equality claim or generic difference waiver.
