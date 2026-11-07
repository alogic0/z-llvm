# Whole-compiler diagnostic baseline

Status: diagnostic complete; whole-compiler object emission is blocked.
Authorized by the user's “Write this as a plan and implement” after review of
the staged whole-compiler proposal. See the [results](../evidence/whole_compiler_diagnostic.md)
and [machine-readable report](../evidence/whole_compiler_diagnostic_20261107.json).

## Intended result

Attempt the complete pinned Zig compiler for x86_64 Linux GNU, ReleaseFast,
through the existing postopt object hook. LLVM still owns optimization; z_llvm
owns attempted object emission. Use the LLVM-enabled compiler configuration,
the existing CMake link configuration and explicit external providers. This is
a diagnostic baseline, not a claim that LLVM has been replaced or that the
compiler can self-host. A reproducible failure is a valid diagnostic result.

This experiment takes priority over the isolated `fmt.charToDigit` repair.
The existing twelve-member execution cohort and all accepted counters remain
unchanged. The older worker-inbox directive is historical and superseded.

## Implementation order

1. Add a standalone Zig runner using the existing process and evidence helpers.
   Pin frontend source and executable, backend executable, target, CPU, build
   options, LLVM configuration, environment, caches and command deadlines.
   Warm the build runner without the object hook, then attempt the actual
   compiler build with the postopt hook enabled and a capture proxy.
2. Retain each hook invocation independently: original and effective arguments,
   exact optimized IR and its hash, backend stdout/stderr, profile, ownership
   manifest when available, elapsed time and peak RSS. Size the input limit for
   the retained file rather than relying on the hook's 64 MiB default. Request
   conservative dependency selection and all codegen failures.
3. Produce a machine-readable report distinguishing frontend/optimization,
   parsing, verification, selection, object writing and linking. Group reported
   selection failures by diagnostic and selector capability; retain each raw
   function name. An earlier fatal stage means later functions were not tested,
   not that they were accepted. Unknown references retain conservative closure.
   If a runtime sub-compilation stops the build before the compiler module,
   retain that rejection and separately export the complete compiler's postopt
   LLVM IR from the recorded build-exe arguments with binary/runtime emission
   disabled. Feed that exact IR to the same local backend. This diagnostic
   continuation cannot bypass the runtime failure or earn linking credit.
4. Count emission as successful only after complete selection accounting and
   matching object ownership; reject empty/partial output or missing hook proof.
   Preserve required globals, aliases and declared runtime/external providers.
   Do not use stubs or substitute LLVM-generated compiler functions.
5. If the compiler object and link succeed, run `zig version`, then compile and
   execute unchanged small programs and check rejection of invalid source.
   Attempt a self-rebuild only after those observations pass. Keep startup,
   behavior and rebuild results separate; stop at the first unresolved stage.
6. Publish the actual obstacle report and choose the next shared capability
   from it. Keep the retained AIR census separate from this LLVM IR route; AIR
   currently allows partial lowering and needs complete rejection accounting
   before it could establish whole-compiler emission.

## Validation and resource policy

Exercise the runner's failure accounting with focused fixtures: early parse
failure, multiple selection failures, missing/partial reports, and a successful
small hook invocation. Check the actual whole-compiler run and its retained
inputs. Reuse accepted full-integration evidence only for unchanged compiler,
gate, pin and corpus inputs; this standalone diagnostic advances no capability
or ratchet. Any production compiler repair or gate-contract change requires
the corresponding validation tier before acceptance.

Use `local-state/validations/whole-compiler-20261107/` for retained evidence and
runner-owned caches. Admission remains 32,949,672,960 bytes and execution reserve
24,359,738,368 bytes, with cancellation if sampled free space crosses the
reserve. Record timeouts, signals and resource stops separately from compiler
rejections. Reuse existing provider libraries, preserve original scratch files,
current AIR, accepted compilers and prior evidence, and create no archives.

## Recorded outcome

The complete compiler module reaches the local backend as 443,624,107 bytes of
optimized IR with 8,928 definition lines. Parsing stops on a packed aggregate
global; the independent syntax census records 111 packed-global rejections.
The original executable build separately stops on runtime verification:
`compiler_rt.sincos.sincos_f32` contains a vector floating-point truncation
rejected as `InvalidCast`. One of 455 runtime bodies fails the diagnostic
verification projection. These are distinct populations and stages, with no
selection or executable acceptance credit. Linking, startup, behavior and
self-rebuild remain conditional, unexecuted stages.

Focused report tests, actual CLI controls, the postopt/native smoke, both
censuses and preservation checks pass. Production sources and accepted counters
remain unchanged. The next implementation priority is shared packed aggregate
support, followed by the separate vector floating-point cast boundary.
