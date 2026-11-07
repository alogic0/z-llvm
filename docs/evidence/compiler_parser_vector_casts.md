# Compiler function parsing and runtime vector casts

Status: accepted at `57a78095`; all 17 integration gates pass. The
[acceptance record](compiler_parser_vector_casts_acceptance_20261107.json) binds
the implementation, compiler identities, input diagnostics and retained evidence.
The [plan](../plans/2026-11-07-compiler-parser-vector-casts.md) follows the packed
aggregate repair. Raw evidence is retained under
`local-state/validations/parser-vector-20261107/`.

## Parser repair

The unchanged 443,624,107-byte compiler input has SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
All 8,928 independently examined definitions now parse, with zero rejections.
The complete module also parses successfully: the retained ReleaseFast parser
probe takes 4.59 seconds and reaches 3,364,920 KiB maximum RSS locally.
These are syntax diagnostics, not function verification or execution counts.

Four rejected definitions had switch labels containing brackets inside quoted
identifiers. Another had an indirect-branch destination containing spaces and
commas. Shared quote-aware delimiter scanning and the existing label-operand
parser now preserve these identifiers, including escaped quotes. The remaining
failures were vector GEP index syntax in `link.Elf.flushInner` and switch loop
metadata in `Zcu.populateReferenceTrace`. GEP indices now use the shared leading
type/value parser, and `!llvm.loop` is retained on the switch.

Permanent round-trip tests also reject missing switch delimiters, trailing label
or index text, and unknown metadata. Parsing vector GEP indices does not grant
them scalar pointer semantics: the current GEP result contract is scalar-only,
so verification explicitly returns `UnsupportedVectorGetElementPtr` for them.

## Runtime cast implementation

Floating width-cast verification accepts equal-lane vectors with FP elements and
the required strict width direction. Mismatched lane counts, scalar/vector
mixing, integer/pointer elements and invalid width direction still reject.
Selection supports precisely two-lane float-to-double extension and
double-to-float truncation. It uses existing scalar SSE conversions, explicit
operands and the common live-register/spill owner; defined-lane masks survive
conversion. No new machine instruction or parallel-transfer path is introduced.

The runtime stores the narrowed two-float result to memory. The existing pair
memory legalizer now handles ordinary two-lane float/double accesses through
exact-width integer loads/stores and scalar bitcasts. It preserves access order,
alignment bounds and metadata. Volatile/atomic operations, nondefault address
spaces and wider FP vectors remain outside this expansion. The production
inspector now admits the existing fully defined f64x2 PHI transfer contract;
partial and f32x2 PHIs retain their separate unsupported boundaries.
The final production CLI independently rejects both excluded PHI fixtures,
reporting `stage2-phi-src` and `phi` respectively, with zero emitted functions
and no object bytes (`excluded-phis.*`).

The unchanged 1,856,543-byte runtime input has SHA-256
`ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af`.
Full module verification now succeeds. The in-context diagnostic census passes
all 455 definitions, including `compiler_rt.sincos.sincos_f32`, compared with
454 previously. This census does not attempt code generation.

## Executable evidence

The permanent `vector_fp_casts` population contains five functions. Direct and
optimized local routes in Fast, Safe and Small check 7,680 observations against
3,840 LLVM references reused across routes. Inputs include signed zero, rounding
ties, subnormals, float overflow, infinities and NaNs. Result comparison is exact
except that two NaNs are considered equivalent; NaN payload preservation is not
claimed. Separate byte comparisons require original live inputs to survive.

The driver checks unaligned accesses and guarded 8/16/128-byte destinations,
both PHI edges, partially defined vectors, eight occupied XMM argument registers,
four simultaneously live vector conversions and a helper that clobbers XMM0–7.
JIT unit execution independently checks 144 pairs of explicit rounding cases,
source aliases and both PHI edges, with machine verification before execution.
The population is separate from compiler-core and compiler-rt accepted counters.

## Acceptance

The final ReleaseFast compiler passes the same native regression as the final
Debug build. Both Debug and ReleaseSafe pass 1,930 unit and 19 structural tests.
Readiness and all 17 integration gates pass. The 47 native populations check
1,779,948 local observations against 889,974 LLVM references. All prior native
fixtures and counts are unchanged. The five fixed Zig programs pass in all
three modes; migration matches 87 input/mode pairs and 603 observation controls,
and the C input workload matches 138 pairs and 552 controls. Migration oracle
observations and selection counters match the previous accepted run. The
execution controls pass 21 function/mode pairs, 22,788 observations and 54
deliberate fault rejections.

The three compiler-core gates pass at 100 lowered/emitted/linked and
12 executed functions per mode. All 36 executed-row records retain identical
descriptors, selected object bytes/hashes, linked sizes, results, witnesses,
observations and statuses. Independently built reference wrappers retain their
path-dependent identity boundary: twelve are 16 bytes smaller and twelve are
8 bytes smaller than the prior accepted run. Reference-wrapper size and both
wrapper hashes are explicitly excluded from that semantic comparison. Strict
wrapper-byte equivalence is not claimed, and the production comparator is
unchanged. The final audit retains these differences separately.

The 1,729-file compiler/tool/test/build snapshot matches both the tested working
tree based on `1b6b8e33` and committed implementation `57a78095`. The final
ReleaseFast binary is supplied explicitly to integrated hooks, broader Zig
programs and the C input workload. The existing hello and upstream-C/native
runner defaults use the final Debug build. Both compiler hashes and all
13 original scratch probes verify; previous accepted compilers are preserved.
No frontend, AIR export, cohort or cache implementation changes are made.
The existing accepted AIR cache is authenticated again, while compilation,
linking and execution are rerun; no fresh/cache infrastructure benchmark is
claimed.

Admission remains 32,949,672,960 bytes; execution reserve is 24,359,738,368 bytes.
The full run takes 3,629.756 seconds. Gate-boundary samples reach a minimum of
52,450,471,936 bytes free; additional periodic samples during the executable
gate reach 50,645,360,640 bytes, above the reserve. These are sampled minima,
not a continuous disk trace. Original probes and prior evidence are retained.
No archives were created.

## Original input replay and remaining boundaries

The exact compiler-module replay advances from parsing to verification and now
reports `UnsupportedCallAttribute`. The original input, effective arguments,
profile and diagnostics are retained in `compiler-replay-final/`. No complete
compiler verification, object, link, startup or self-rebuild is claimed.
An isolated parameter diagnostic identifies `free`'s declaration at input line
737421: `ptr allocptr noundef align 1 captures(none)`. The exact declaration
and its attribute group are retained in `next-allocptr.ll`; Clang-22 accepts
this reproducer, while local verification returns `UnsupportedCallAttribute`.
This diagnostic does not alter the original input or the frozen implementation.

The exact runtime-module replay advances from verification to selection.
Report-all examines all 455 selected definitions and reports 265 successful
function emissions and 190 failures. The complete list is retained in
`runtime-replay-final/backend/report.json`, with grouping by diagnostic and
selector detail in `runtime-failure-groups.json`. This is partial selection evidence;
the backend publishes no complete runtime object. The first failure is
`compiler_rt.fastMemset` with `composed-block-memset-attrs`.
`compiler_rt.sincos.sincos_f32` now reaches its independent ordinary scalar FP
pointer-load boundary (`composed-block-load-fp-ptr`). Resolving the vector cast
does not close those other runtime capabilities. Accepted compiler-core counts
and the compiler-rt bypass ratchet remain unchanged.
