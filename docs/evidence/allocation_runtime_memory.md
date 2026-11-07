# Allocation attributes, compiler verification and runtime memory

Status: accepted at `9d3f24b3`; all 17 integration gates pass. The
[acceptance record](allocation_runtime_memory_acceptance_20261107.json) binds the
cumulative implementation in `ec9539bb` and `9d3f24b3` to the tested source and
retained results. The [plan](../plans/2026-11-07-allocation-runtime-memory.md)
records the completed implementation and incomplete whole-compiler selection
census. Raw evidence lives in `local-state/validations/allocation-memory-20261107/`;
original inputs and prior compiler binaries remain intact. No archives were created.

The complete unchanged 443,624,107-byte compiler IR now passes verification:
8,928 definitions, no verifier rejection. The repairs validate pointer-only
`allocptr`, preserve allocator metadata, admit `uitofp nneg`, and derive a
vector-of-pointers result for a scalar-base GEP with matching integer vector
indices. Vector-base GEP syntax, native vector address selection and other
unsupported vector conversions remain separate capabilities. This is bounded
IR support, not a claim of complete LLVM verification.

The exact compiler replay reaches selection, then the existing one-hour deadline
stops it with return code 124 (`timed_out`, `process_completed=false`). It retains
5,949 rejected functions but no completed selection counts or final profile.
This is an incomplete census; no complete compiler object, native link, startup
or self-rebuild is claimed. Input identity, effective arguments, source/backend
verification and every reported failure remain in `compiler-replay-v2/`.

The largest groups among those reported failures are:

| First rejected capability | Reported functions |
| --- | ---: |
| `composed-block-memcpy-attrs` | 1,798 |
| `UnsupportedCallAttributeAbi` | 1,648 |
| `composed-block-call-arg-width` | 539 |
| `composed-block-llvm-intrinsic` | 398 |
| `composed-block-param-i8-extension` | 294 |
| `composed-block-call-form` | 190 |

These counts cover the reported portion only and identify one failure per
function; removing a blocker can expose another. The last reported failure is
definition 6,648, `Zcu.codegenFail__func_31713`. The next source definition is
`codegen.loongarch.Assemble.parseInstruction`, with 196,657 IR lines. Its role as
the long-running bottleneck is inferred from sequential progress, not confirmed
by a completed per-function profile. The environment prevented stack attachment;
no system restriction was changed. Large-function progress/timing diagnostics
and the shared memcpy/call-attribute gaps are the next work before repeating
the complete selection census.

Pointer calls and nonvolatile memset share validation of supported advisory
attributes; ABI payloads and address spaces retain their existing restrictions.
Allocation annotations survive release optimization, and calls with deallocation
side effects are retained. LLVM's allocation attributes describe allocator
behavior, while vector GEP arguments determine a vector result; these facts
follow the [LLVM language reference](https://llvm.org/docs/LangRef.html).

Ordinary float/double loads and stores use exact-width integer memory transactions
and FP bitcasts. Existing symbolic tables and typed stack addresses keep their
owners through a linear address-root worklist, including unordered blocks and
PHIs. The XMM owner/liveness authority chooses a free explicit bitcast destination
before spilling. No new machine instruction, calling convention or frame layout
was introduced. Atomic/volatile accesses, other address spaces and half/wider FP
memory remain outside this new rewrite.

The seven-function `runtime_memory` population checks exact FP payload bits,
including signed zeros, subnormals, infinities and signaling/quiet NaNs; unaligned
and aliased memory; live values across register-clobbering calls; returned
pointers and register pressure; zero/runtime memset lengths and high-bit fills;
allocation/reallocation success and error paths; and nonnegative integer-to-float
conversion. Guard pages enforce access extent. It contributes 8,466 local and
4,233 LLVM-reference observations over Fast/Safe/Small and direct/release routes.
The complete focused matrix passes with both Debug and ReleaseFast compilers.

The unchanged runtime replay selects 272 of 455 functions and rejects 183,
compared with 265/190 previously. No previously selected function regresses.
Newly selected functions are `fastMemset`, `ssp.__memset_chk`, `rem_pio2f`,
`rem_pio2`, double `sincos`, `sin` and `cos`. `sincos_f32` now reaches
`composed-vector-shuffle-form`. The report retains every rejected function and
groups it by diagnostic/tag/detail. No complete runtime object is published.

Debug and ReleaseSafe unit suites pass with 1,937 tests, and structural suites
pass 20 checks per mode. The final Debug unit invocation reuses a valid cached
run from the same frozen sources. Readiness passes. The batched diagnostic census has an independent test
for multiple body errors with unchanged cross-function context. It splits only
failing ranges instead of reconstructing all module context for every function.

Initial diagnostics caught padded-half stack and symbolic-table regressions in
the proposed FP rewrite. Both were repaired before acceptance, with permanent
boundary tests and a zero-regression runtime census. Initial compiler replay was
terminated during that repair and is explicitly recorded as process-interruption;
an overlapping readiness attempt rejected a changed-source build. Final evidence
uses the frozen repaired sources and supersedes those incomplete attempts.

The original compiler input has SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`;
the 1,856,543-byte runtime input has SHA-256
`ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af`.
The compiler replay shares the host with integration work, and its deadline
prevents a complete timing profile. No compiler-throughput speedup is claimed.

All 17 integration gates and 48 native populations pass. The full native matrix
checks 1,788,414 local observations against 894,207 LLVM references. Existing
native fixtures and population counts are unchanged. All five fixed Zig
programs pass in three modes; migration matches 87 input/mode pairs and 603
observation controls, and the C input workload matches 138 pairs and 552
controls. Migration observations and selection counters match the prior run.
The execution controls pass 21 function/mode pairs, 22,788 observations and 54
deliberate fault rejections.

Compiler-core counts remain 100 lowered/emitted/linked and 12 executed functions
per mode; the separate compiler-rt bypass ratchet stays 130. All 36 core records
retain identical selected object bytes, descriptors and execution observations.
Twenty-four independently built reference wrappers are 16 bytes larger than
before. Reference size and the two wrapper hashes are explicitly excluded from
that comparison; all other fields match. Strict wrapper-byte identity is not
claimed, and the production comparator is unchanged.

The 1,731-file compiler/tool/test/build snapshot matches both the tested working
tree based on `3ebec6c4` and committed implementation `9d3f24b3`. The final
ReleaseFast binary is supplied to integrated hooks, broader Zig programs and
the C input workload; existing hello and upstream-C/native runner defaults use
the final Debug build. Both binary identities and the thirteen original scratch
probes verify. No frontend, AIR export, cohort or cache implementation changes
are made. The existing authenticated AIR cache is reused while compilation,
linking and execution are rerun; no fresh/cache infrastructure benchmark is claimed.

Admission remains 32,949,672,960 bytes and execution reserve 24,359,738,368 bytes.
The full integration run takes 3,824.286 seconds. Gate-boundary samples reach
42,944,204,800 bytes free; additional periodic samples reach 41,872,187,392 bytes,
above the reserve. These are sampled minima, not a continuous trace. The run
finishes with 43,747,864,576 bytes free. Prior evidence and original probes remain.
