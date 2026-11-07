# Allocation attributes and runtime memory

Status: implementation accepted at `9d3f24b3`, following the parser/vector-cast
checkpoint without changing its original inputs. The complete whole-compiler
selection census remains outstanding after the bounded diagnostic timed out.

1. Validate and preserve `allocptr` on pointer parameters and call arguments,
   including allocation-family/function annotations through optimization.
   Admit the supported advisory attributes through shared call lowering and
   add positive, invalid-input and executable allocation regressions.
2. Replay all 8,928 compiler definitions. Diagnose subsequent verifier failures
   in the original module, starting with vector GEP result typing. Implement
   well-defined shared IR contracts and retain explicit unsupported selection
   boundaries. Seek a complete verifier pass and an all-function selection
   report; record any remaining blocker without granting emission credit.
3. Extend ordinary scalar floating-point memory accesses and nonvolatile memset
   attributes through existing memory/register contracts. Compare guarded,
   input-driven executions against LLVM in all modes and both routes, then
   replay the unchanged 455-definition runtime input.
4. Run focused tests, Debug/ReleaseSafe units, readiness, captured-object and
   native checks, followed by one cumulative full integration acceptance.
   Preserve the compiler-core cohort and bypass ratchet; commit implementation
   and evidence with their precise capability limits.

Evidence root: `local-state/validations/allocation-memory-20261107/`. Admission
remains 32,949,672,960 bytes and the execution reserve 24,359,738,368 bytes.
Preserve the original scratch probes, prior evidence and compiler binaries.
Create no archives.

The [evidence](../evidence/allocation_runtime_memory.md) and
[acceptance record](../evidence/allocation_runtime_memory_acceptance_20261107.json)
record 1,937 unit tests per build mode, 20 structural checks per mode, readiness,
all 17 integration gates and 48 native populations. All 8,928 compiler definitions
verify in the complete unchanged module. Runtime selection improves from 265/455
to 272/455 without regressions among previously selected functions.

The compiler replay retains 5,949 reported failures before the existing one-hour
deadline, with no completed selection totals, final profile or complete object.
This is the limit of step 2, not full selection acceptance. Add progress/timing
diagnostics for large functions and address shared memcpy/call-attribute gaps
before another complete selection census. The original compiler and runtime
still earn no whole-object, startup or self-rebuild credit from these diagnostics.
