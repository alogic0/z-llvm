# Compiler function parsing and runtime vector casts

Status: complete at `57a78095`; all 17 integration gates pass. See the
[evidence](../evidence/compiler_parser_vector_casts.md) and
[acceptance record](../evidence/compiler_parser_vector_casts_acceptance_20261107.json).

Resolve the seven retained compiler function-parser failures first, then the
runtime vector floating-point cast boundary. Keep the complete original inputs
unchanged and distinguish syntax, verification, selection and execution evidence.

1. Isolate each rejected definition and repair the shared parsing rules behind
   the five `InvalidLabel`, one `UnsupportedType` and one
   `UnsupportedInstructionMetadata` results. Add positive and malformed-input
   regressions with quoted names and round-trip preservation.
2. Repeat the full 8,928-definition syntax census and exact compiler-module
   replay. Retain the new actual boundary without expanding this slice to
   unrelated compiler capabilities.
3. Verify equal-lane vector floating-point casts with correct element widths,
   implement the runtime conversion through existing lowering/register
   contracts, including exact-width pair memory accesses and the existing
   fully defined f64x2 PHI contract. Execute permanent regressions against LLVM.
   Replay the exact runtime input and retain independent subsequent boundaries.
4. Run focused parser/verifier/selector tests, Debug and ReleaseSafe units,
   readiness, required native/object checks and one cumulative 17-gate full
   integration run. Preserve compiler-core counters and the bypass ratchet.
   Record source/input/compiler identities and commit implementation and evidence.

Evidence root: `local-state/validations/parser-vector-20261107/`. Reuse the pinned
frontend and accepted core AIR cache. Admission remains 32,949,672,960 bytes and
runtime reserve 24,359,738,368 bytes. Preserve original scratch probes, prior
compilers and evidence. Create no archives.

All 8,928 compiler definitions and the complete compiler module now parse.
All 455 runtime definitions verify. The five-function vector-cast population
passes 7,680 local observations against 3,840 LLVM references in all three
modes and both routes, with Debug and ReleaseFast compiler builds. Debug and
ReleaseSafe each pass 1,930 units and 19 structural checks; readiness and all
47 native populations pass. The 12-function core cohort and ratchet 130 remain
unchanged. Original probes and prior compilers verify; no archives were created.

The next compiler verifier boundary is `allocptr` on `free`'s declaration,
with an LLVM-valid reproducer retained. Runtime selection reports 265 successes
and 190 failures without publishing a complete object; `sincos_f32` next rejects
ordinary scalar FP pointer loads. These are separate follow-up capabilities.
