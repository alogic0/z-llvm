# Complete compiler selection census

Status: complete. Accepted implementation `5ad6c51c`; see
[evidence](../evidence/selection_census_completion.md) and the
[acceptance record](../evidence/selection_census_completion_acceptance_20261107.json).
Follow allocation/runtime-memory acceptance `9d3f24b3`.
Preserve the unchanged compiler/runtime IR, prior compiler binaries and thirteen
original scratch files. Create no archives. Use Zig for diagnostic tooling.

1. Extend existing profiling with opt-in, flushed JSONL events for function,
   phase, legalizer and retry progress. Preserve the existing final profile
   schema and output behavior when disabled. Test completed and interrupted
   runs, output identity and invalid output paths.
2. Use those events to identify the actual large-function bottleneck. Retain
   the original module context for focused diagnostics, repair the measured
   shared algorithm, and check semantic/output equivalence and scaling. Do not
   skip functions, weaken selection or increase capability counters to finish.
3. Classify the observed memcpy and call-attribute failures. Extend common
   validated advisory-attribute contracts while keeping ABI-changing payloads
   explicit. Add malformed-input and executable regressions with memory bounds,
   aliases, calls and relevant widths.
4. Replay both original inputs with the final compiler. Require a completed
   8,928-function compiler selection census with retained profiling and failure
   groups, and preserve all 272 previously selected runtime functions. Run
   focused comparisons, Debug/ReleaseSafe units, readiness and one cumulative
   full integration acceptance on frozen sources. Commit implementation and
   precise evidence; keep compiler-core counts and bypass ratchet unchanged.

Evidence root: `local-state/validations/selection-census-20261107/`. Admission
remains 32,949,672,960 bytes and execution reserve 24,359,738,368 bytes.
Selection counts remain separate from complete-object, link and execution
credit. Full compiler rejection is an expected diagnostic outcome; an incomplete
selection census does not satisfy this plan's final replay requirement.

All four steps are complete. The compiler census selects 3,524 functions and
rejects 5,404 after attempting all 8,928. The runtime selects 274 of 455,
preserving all prior 272 successes. Both event streams pass complete audits.
All 17 cumulative gates and 49 native populations pass; compiler-core counts
remain 100 lowered/emitted/linked and 12 executed per mode, with ratchet 130.
