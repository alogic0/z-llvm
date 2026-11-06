# Validation tools

The maintained Python tools were replaced by Zig 0.17.0 programs. The compiler
and its accepted populations are unchanged. Shared process mechanics come from
`zig-process` 0.6.1; file/JSON helpers and file-backed reports come from
`zig-test-support` 0.2.0. The [source ledger](../tools/vendor/README.md) records
their committed revisions and exact copied files. Standalone `zig run` commands
do not require another checkout at runtime.
The validated host is x86-64 Linux, matching the existing execution gates.

The [migration acceptance](evidence/python_tools_migration_20261105.json) and
[gate summary](evidence/python_tools_migration_20261105.summary) bind the source,
provider digests, output comparisons and cleanup. At `978ffaf9`, all 22 tests
pass in Debug and ReleaseSafe and all 17 integration gates pass with Python
blocked. The complete log matches 1,430 prior canonical records; the separate
fresh/cache pair matches all 24 records. Compiler acceptance remains unchanged.

The subsequent [shared-library adoption](evidence/shared_validation_libraries_20261105.md)
adds atomic JSON writes, shared append-safe logs and file-backed command reports,
streaming hashes and deterministic JSON helpers. Ordinary and benchmark commands
now use one deadline covering launch and execution. Structural JSON comparison
preserves object-order independence and distinguishes number representations;
empty strings use explicit permissive extraction. Compiler and Fibonacci policy
remain in this repository.

| Former Python role | Zig entry point / build step |
| --- | --- |
| Unchanged upstream Zig program, including capture hook | `tools/run_real_program.zig` / `real-program` |
| Upstream C program and 35 native populations | `tools/run_upstream_c_program.zig` / `upstream-c-program` |
| Fixed candidate selector | `tools/build_real_candidates_v3.zig` / `real-candidates-v3` |
| Checked semantic facts | `tools/validation/candidate_facts.zig` library |
| Fact freezing and replay proof | `tools/freeze_real_candidate_facts.zig` / `freeze-real-candidate-facts` |
| Frozen performance matrix | `tools/fixed_program_baseline.zig` / `fixed-program-baseline` |
| Three Python policy test modules | `tools/validation_tests.zig` / `real-program-policy-tests` |

Run tools from this checkout or a descendant directory. Set
`ZLLVM_PROJECT_ROOT` explicitly when invoking a compiled tool elsewhere.
Relative input paths resolve against the project root. New evidence paths
must be inside the project, with symlink escapes rejected. Program and
measurement runs require new output directories; fact freezing also refuses
existing proof/manifest paths. Candidate replay retains its explicit output
replacement behavior. Historical Python helpers in ignored validation evidence
remain historical records; they are not dependencies of the active workflow.
No archives were made.

Unchanged-program manifests can set `compile_timeout_ms` to a positive 32-bit
millisecond budget. It applies to reference/local compilation, selector-owner
replay and diagnostic re-emission; the default is 120,000 ms. Fibonacci uses
900,000 ms so a Debug compiler can process the Safe runtime. Links retain the
default command budget and executable observations retain their five-second
limit. Failed stage reports preserve the command outcome and actual termination
even when the compiler produces no stderr; command records include the budget.

The native population registry now lives in
[`test/real_programs/native_canaries.json`](../test/real_programs/native_canaries.json).
All function sets, expected outputs, observation counts, route flags and guard
probes were compared against the old Python registry. The fixed table and every
selected audit field must still match the frozen candidate authority.

```sh
zig build real-program-policy-tests verify-validation-sources
zig build real-program-policy-tests -Doptimize=ReleaseSafe
zig build real-program -- --output-root local-state/validations/my-program
zig build upstream-c-program -- --output-root local-state/validations/my-native
zig build real-candidates-v3 -- \
  --facts-manifest docs/evidence/real_candidates_release_v3_facts_manifest.json \
  --releasefast-inventory local-state/validations/current-pin-20261102/current-releasefast.tsv \
  --out local-state/validations/my-replay/candidates.tsv \
  --audit local-state/validations/my-replay/audit.json
```

The reusable command recorder replaces one-off Python telemetry wrappers.
It records exact arguments, merged binary logs, exit/signal status and free
space every two seconds. Labels beginning with `full-` additionally record raw
and cached AIR inode/allocation samples using the command's explicit root
arguments. The existing authoritative distribution runner continues to enforce
startup and runtime disk reserves; this wrapper only observes them.
Captured log descriptors use append mode so independent positional stdout or
stderr writers cannot overwrite earlier diagnostics. The unchanged-program
runner retains both the text summary and its original one-line JSON summary.

```sh
zig run tools/run_checked.zig -- \
  --output-root local-state/validations/my-run checks -- \
  zig build real-program-policy-tests
zig run tools/validation_progress.zig -- \
  --record local-state/validations/my-run/checks.json
zig run tools/validation_snapshot.zig -- \
  --output local-state/validations/my-run/source.json
zig run tools/validation_snapshot.zig -- \
  --verify local-state/validations/my-run/source.json
```

Snapshots check Git HEAD/tree, file membership and SHA-256 for tracked and
untracked, non-ignored files. Place snapshots in ignored evidence directories
so they do not include themselves. The program and benchmark reports record
the running binary hash and the validation source closure. Child groups and
reaping belong to `zig-process`; consumer signal handlers request cancellation
and retain the final report. The capture hook remains within its emitter's
owned group so stopping the emitter also stops the backend.

The benchmark keeps two warmups, nine samples, rotated route order, CPU affinity,
independent LLVM inputs, output/ownership checks, and deterministic object hashes.
Its clock is Zig's awake nanosecond clock. The shared file-command helper uses
provider readiness waits and exact-child cleanup under a deadline, including
launch. Reports identify this as `zig-process-0.6.1-readiness-v2`. Historical Python
and `zig-process-0.6.0-pidfd-v1` measurements remain records of their original
procedure; cross-engine differences do not establish a compiler speedup. Compiler
build time, links and verification remain outside the measured IR-to-object
interval. The adoption checks exercise timeout handling but do not rerun the
performance matrix or claim a speedup.
