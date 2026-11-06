# Input-driven execution and phase measurements

All 17 integration gates pass at `1e513b68`, with the source snapshot verified
after the run. The [acceptance record](input_driven_execution_acceptance_20261106.json)
binds the source tree, compiler builds, reports and 171 retained artifact hashes.
This implements [the plan](../plans/2026-11-06-input-driven-execution.md) after
[the execution-breadth checkpoint](execution_breadth.md).

## Unchanged program and runtime corpus

The pinned `jsmn` v1.1.0 JSON-dump example and parser are byte-identical to upstream
revision `fdcef3ebf886fa210d14956d3c068a653e76a24e`; its MIT license is retained.
The manifest authenticates all three files. The program reads stdin, reallocates
its input and token buffers, mutates parser/token state and recursively traverses
the result. The corpus contains 46 inputs: empty and whitespace-only streams,
objects, arrays, primitives, escapes, UTF-8 strings, malformed and incomplete
input, duplicate keys, 24 levels of nesting, repeated token-capacity boundaries
and inputs spanning multiple read buffers.

Each reference/local program is compiled once per Fast/Safe/Small mode and must
match frozen exit status, stdout and stderr independently. All 138 input/mode
pairs pass; 552 observation-mutation controls reject abnormal termination and
wrong status/stdout/stderr. Nine definitions are emitted through composed
selection. These counts are separate from compiler-core execution and native
canary observations. This is C frontend evidence through local release pipelines;
it does not expand Zig frontend coverage, test allocation failure, or enable C
sanitizers. The existing five unchanged Zig programs remain required.

The initial corpus split an unquoted primitive at an 8,192-byte input boundary.
LLVM exposed the upstream permissive parser finishing that primitive early.
The final growth case uses quoted values, whose partial-token behavior supports
chunk boundaries. The initial diagnostic remains retained; expected output was
constructed independently of the local compiler. This is not a JSON conformance
claim.

## Shared repairs and lowering consolidation

Stack promotion previously emitted one PHI incoming per unique predecessor,
losing repeated switch/conditional edges. CFG analysis now preserves edge
multiplicity alongside unique traversal; promotion emits an incoming per edge.
Numeric stack-slot names also produced invalid names such as `4.0`. Promotion
now creates valid, collision-free identities, including quoted-name collisions.
Unresolvable pointer-PHI rewrites fail explicitly instead of repeating forever.

Named-struct field addresses use the same complete storage-layout authority as
frame storage and pointer strides, then ordinary byte-address transactions.
Regressions cover padded and packed fields, wrapping addresses and rejected
unknown or incomplete layouts. The upstream program exposed these gaps without source
changes or function-specific lowering.

Optional legalization uses one ordered, bounded driver instead of recursive
selector calls. Mandatory normalization remains checked on every iteration.
Original-form retries retain their transaction semantics; generated switch labels
are retained in reverse pending order. The existing shared transfer contract
continues to own scalar copies. Pair/vector PHIs, spill destinations and ordinary
CLI structural fallback remain separate boundaries.

## Ownership and phase measurements

`--selection-owner-output=PATH` records ownership from the successful object
selection run. Sorting references leaves object function order intact.
`--profile=PATH` writes exclusive phase timings and counters to separate JSON.
Timings use the monotonic awake clock and measure elapsed time, not sampled CPU
time. State is explicit and local to a compilation. `verify` measures shared
preparation verification; `optimize` includes verification performed inside the
pass manager. `other` includes setup, cleanup and work outside instrumented phases.
Spill counts are emitted spill instructions, not unique slots or live spills.
Legalizer rewrite counts include candidates discarded after original-form success.

Permanent route checks compare profiled/unprofiled objects and same-run/replayed
ownership. The unchanged Zig runner consumes same-run ownership by default and
supports `--replay-owners`. The input-corpus gate retains replay in every mode.
A failed-module control confirms empty object stdout, no ownership sidecar and a
failed profile when one selected function cannot be emitted.

On the retained Safe Fibonacci IR (1,568 definitions), ReleaseFast object emission
without profiling took 30.88 s; combined profiled object/ownership took 31.76 s;
independent ownership replay took 31.01 s. The Debug combined run took 350.05 s.
Objects and ownership match both the preceding checkpoint and every current
route byte-for-byte. These are single samples concurrent with validation, not
an overhead estimate or generated-code performance claim.

| Exclusive phase | ReleaseFast compiler, seconds | Debug compiler, seconds |
| --- | ---: | ---: |
| Selection | 15.840 | 208.895 |
| Optional legalization | 12.818 | 115.160 |
| Reachability | 2.683 | 17.649 |
| Mandatory normalization | 0.183 | 1.968 |
| Parsing | 0.087 | 1.438 |
| Preparation verification | 0.069 | 1.424 |
| Object writing | 0.053 | 1.726 |
| Ownership writing | 0.0005 | 0.0033 |
| Other | 0.015 | 1.770 |
| Input | 0.006 | 0.006 |

AIR lowering and optimization are zero for this already optimized textual IR.
The new parser's complete local pipeline, including optimization, takes about
0.09 s per mode with the ReleaseFast compiler in the retained focused run.

Both compiler builds record identical counters for Fibonacci.
There are 139,415 legalizer attempts, 7,233 candidate rewrites, 2,869 original-form
retries and 1,034 original-form successes. The maximum is 20 selection iterations
per function. The report records 425,136 emitted instructions, including 74,247
spill instructions. These measurements justify investigating repeated optional
legalization and selection work next; they do not identify individual CPU hotspots.

## Validation and retained evidence

The full run completes with exit 0 and all 17 gates passing. Its 1,471 canonical
records pass structural validation. All 36 compiler-core records match the prior
fresh-export run: 100 functions lowered, emitted and linked, with nine executed
per mode. The 45 native populations pass 1,767,660 local observations against
883,830 reference observations. Those populations retain their previous definitions.

All five unchanged Zig programs pass in Fast, Safe and Small, with profiles and
ownership from object emission. Their selected-definition counts match the
preceding checkpoint: Fibonacci 34/1,568/34, optionals 33/1,567/33, global tagged
storage 1,484/1,575/660, anonymous aggregate arrays 1,485/1,576/661 and runtime
loops 33/1,567/33. The 27 existing compiler-core negative controls also pass.
The input corpus passes with both Debug and ReleaseFast compiler builds and
again inside full integration; each run checks 138 input/mode pairs and 552
observation mutations. Counts are not added across these repeated runs.

Debug and ReleaseSafe unit suites pass 1,906 tests each. Policy suites pass 28
checks each; structural checks pass 19 and ABI comparisons pass 60. Route checks
pass. Prior accepted evidence, all thirteen original scratch probes, diagnostic
worktrees and authenticated AIR caches are preserved. Thirty obsolete test
binaries and eight compiler binaries were deleted from the rebuildable cache,
recovering 2,812,456,960 allocated bytes. Their hashes and sizes are recorded; no
archives were created. Start and reserve thresholds remain 32,949,672,960 and
24,359,738,368 bytes.

The full run starts with 33,624,625,152 free bytes and observes a minimum of
30,624,657,408, above the reserve. Its recorded finish is 32,265,183,232 bytes;
the post-verification observation is 32,266,227,712 bytes. Evidence is retained
under `local-state/validations/input-driven-20261106/`, including raw logs, program
reports, profiles, ownership manifests, timing samples, the source snapshot and
the two cleanup manifests. The tracked acceptance record authenticates them.

## Reproduction

The focused input corpus is part of `distribution-all` and can also run alone:

```sh
zig build input-program -- --output-root local-state/validations/input-program-new
```

The directory must be new. `--zllvm` selects a retained compiler build;
`--zig-emitter` selects the pinned frontend. `--mode` restricts a diagnostic run,
while acceptance requires all three modes. The frozen manifest remains the
authority for source hashes, expected functions, inputs and observations.

The retained phase-measurement script records the ReleaseFast commands. The Debug
sample uses the same combined object/profile/ownership options with the retained
Debug executable. Full acceptance used:

```sh
ZLLVM_EXE=/home/oleg/prog/z_llvm/local-state/validations/input-driven-20261106/compiler-fast/bin/z_llvm \
zig run tools/run_distribution_all_gates.zig -- --serial \
  --zig-emitter=/home/oleg/prog/ziglang/build/stage4/bin/zig \
  --real-rows-validation-root=local-state/validations/execution-breadth-20261106 \
  --real-rows-cache-root=local-state/caches/execution-breadth-20261106 \
  --serial-root=tmp/input-driven-20261106-final
```

Use a fresh serial root for another run. The accepted cache identities are retained.
Current measurements use the same Safe Fibonacci IR as the preceding checkpoint;
they do not re-export or silently substitute a smaller workload.
