# Validation tools

The maintained Python tools were replaced by Zig 0.17.0 programs. That migration
left the compiler and its accepted populations unchanged. Shared process
mechanics come from `zig-process` 0.6.1; file/JSON helpers and file-backed reports come from
`zig-test-support` 0.2.0. The [source ledger](../tools/vendor/README.md) records
their committed revisions and exact copied files. Standalone `zig run` commands
do not require another checkout at runtime.
The validated host is x86-64 Linux, matching the existing execution gates.

`run_checked` participates in [automatic storage cleanup](storage_cleanup.md):
it holds a reader lease during a job, closes its own hold against the terminal
receipt, and hands off to minimal collection after closing job descriptors.
Storage admission time is excluded from the supervised command's wall time.
Failed jobs keep their exit code and diagnostics. Manual investigation holds
remain independent. Whole-compiler `backend/input.ll` captures use verified
read-only artifact-store aliases, preserving their content hashes and paths.

Checked commands, real-program validation, execution-breadth controls, upstream
behavior and the whole-compiler diagnostic allocate caches and executable
products under
`local-state/tmp/validations/.../.workspaces/`. Their original output root keeps
reports, logs, sources, captured inputs and traces. Each run writes a
`*.storage-layout.json` mapping. Successful workspaces are collected by the
storage tool; failed or interrupted workspaces remain available for review.
New cycles use the managed launcher and the
[development storage contract](development_storage.md), including custom
commands. See [storage cleanup](storage_cleanup.md) for the layout and lifetime
mechanics. Short standalone API examples below retain their legacy admission
rules; use a full `local-state/validations/SUITE/BATCH/RUN` root for new cycles.

The [migration acceptance](evidence/python_tools_migration_20261105.json) and
[gate summary](evidence/python_tools_migration_20261105.summary) bind the source,
provider digests, output comparisons and cleanup. At `978ffaf9`, all 22 tests
pass in Debug and ReleaseSafe and all 17 integration gates pass with Python
blocked. The complete log matches 1,430 prior canonical records; the separate
fresh/cache pair matches all 24 records. That migration did not change compiler
acceptance.

The subsequent [shared-library adoption](evidence/shared_validation_libraries_20261105.md)
adds atomic JSON writes, shared append-safe logs and file-backed command reports,
streaming hashes and deterministic JSON helpers. Ordinary and benchmark commands
now use one deadline covering launch and execution. Structural JSON comparison
preserves object-order independence and distinguishes number representations;
empty strings use explicit permissive extraction. Compiler and Fibonacci policy
remain in this repository.

| Validation role | Zig entry point / build step |
| --- | --- |
| Unchanged upstream Zig program, including capture hook | `tools/run_real_program.zig` / `real-program` |
| Whole-compiler build and self-rebuild with postopt or preopt captures | `tools/run_whole_compiler.zig` |
| Full pinned upstream behavior suite with named outcome comparison and optional local hook | `tools/run_upstream_behavior.zig` |
| Candidate frontend f80 layout and C ABI regression | `tools/run_frontend_f80.zig` |
| Audit a retained completed object against its command, owners, census and ELF | `tools/audit_captured_object.zig` |
| Inventory global decoding and shared ELF placement without object credit | `tools/inspect_global_data.zig` / `inspect-global-data` |
| Generate compiler global and runtime completion fixtures | `tools/generate_global_objects_canary.zig`, `tools/generate_runtime_frontier_canary.zig` |
| Final selection rejection types, attributes and locations | `src/selection_census.zig` |
| Upstream C program and registered native populations | `tools/run_upstream_c_program.zig` / `upstream-c-program` |
| One native population, optionally with injected failures | `tools/run_native_canary.zig` |
| Calibrate retained native executables and compare fault reports | `tools/run_native_fault_checks.zig` |
| Preserve native command outcomes, artifacts and registry entries | `tools/compare_native_runs.zig` |
| Generate flag-pair, freeze and atomic-storage fixtures | `tools/generate_ssa_transport_canaries.zig` |
| Permanent unchanged Fibonacci regression in three modes | `tools/run_real_program.zig` / `fibonacci-regression` |
| Unchanged Zig tool with runtime document inputs and exact file outputs | `tools/run_real_program.zig` / `zig-input-program` |
| Fibonacci, four fixed programs and the document-input tool in three modes | `tools/run_distribution_zig_integrated_exe.zig` / `distribution-all` |
| Added compiler-core execution and 54 negative controls | `src/distribution_execution_breadth_gate.zig` / `execution-breadth-controls` |
| Selected compiler build and retained build receipt | `tools/build_validation_compiler.zig` / `validation-compiler` |
| Fixed candidate selector | `tools/build_real_candidates_v3.zig` / `real-candidates-v3` |
| Checked semantic facts | `tools/validation/candidate_facts.zig` library |
| Fact freezing and replay proof | `tools/freeze_real_candidate_facts.zig` / `freeze-real-candidate-facts` |
| Frozen performance matrix | `tools/fixed_program_baseline.zig` / `fixed-program-baseline` |
| Generated-program Fast/Small runtime and ELF size | `tools/measure_preopt_programs.zig` with `oracles`, `prepare` and `sample`. [Protocol and storage](plans/2026-11-17-generated-program-performance.md) |
| Validation policy and lifecycle tests | `tools/validation_tests.zig` / `real-program-policy-tests` |

Run tools from this checkout or a descendant directory. Set
`ZLLVM_PROJECT_ROOT` explicitly when invoking a compiled tool elsewhere.
Relative input paths resolve against the project root. New evidence paths
must be inside the project, with symlink escapes rejected. Program and
measurement runs require new output directories; fact freezing also refuses
existing proof/manifest paths. Candidate replay retains its explicit output
replacement behavior. Historical Python helpers in ignored validation evidence
remain historical records; they are not dependencies of the active workflow.
No archives were made.

`tools/run_upstream_behavior.zig` runs the unchanged pinned `test/behavior.zig`
module in one explicitly selected mode (`Debug`, `ReleaseSafe`, `ReleaseFast`
or `ReleaseSmall`) on x86_64 Linux GNU with CPU `baseline` and libc. Supply
`--output-root`, `--compiler`, `--zig-source`, `--libc-file`, `--mode` and
`--route llvm|local`. A local route also requires `--zllvm` and records every
object invocation through the whole-compiler capture implementation. Compile
and execution outcomes remain separate. `--reference-report` compares every
named pass/skip outcome against a passed same-mode report. The default
`--resources normal` inherits stack and CPU settings; `accepted` explicitly
uses the historical CPU-0 / 1 GiB setup. `--test-filter` is diagnostic-only and
sets `full_suite=false`. Every invocation requires a new output directory.
The local-only `--profile-events` option retains a nonempty event stream and its
hash for every capture; ordered-event auditing is a separate completion check.

The local pipeline defaults to `--local-pipeline postopt`. Select `preopt` to
run the frontend's accepted local optimization pipeline before local object
emission; Debug is unsupported. Preopt requires both `--reference-report` and
`--reference-sha256`. The runner verifies the selected normal LLVM reference's
frontend, source/suite/libc, mode, resources, target/CPU command and complete named
outcomes. Full preopt runs also bind native startup/runtime provider identities.
Use `--record-providers` on a fresh normal LLVM reference to record and recheck
those inputs; unchanged libc configuration text alone does not establish unchanged
system runtime bytes.

Preopt reports separate `.optimizations` from object `.captures`. Optimizer
records retain original/effective arguments, input and output IR, actual command
outcomes and delivery path. Object captures bind their consumed input to that
delivered optimizer output by path, bytes and hash. Optimizer text never counts
as a completed object; failed optimization delivers no output or object. Stage
chains are checked before execution, while independent census/ELF/ordered-event
audits remain required before closing the inventory. Retained-object audits also
check the optimizer command and unchanged retained optimizer input/output.

Preopt connects the shared disk admission and reserve monitor. `--reserve-bytes`
can select a stronger reserve and also enable monitoring for another route; it
cannot lower the shared floor. `space-admission.json`, `space-samples.tsv` and
`space.json` record policy and observations. Resource stops are terminal failed
reports with `resource_stop=true`, a stage and the original error, so diagnosed
scratch can use the existing explicit workspace-release contract.

The [accepted ReleaseSafe run](evidence/release_safe_preopt_acceptance_20261116.md)
qualifies the complete 2,097-outcome suite, separate runtime/test inventories,
both optimizer/emitter chains and complete object/event audits. Its global hook
policy is `ZLLVM_ZIG_MODE=ReleaseSafe`, while compiler-runtime frontend mode is
recorded as Fast. The acceptance also binds the optimizer failure control,
native preservation and all four existing postopt modes. Failed outer receipts
stay failed; independently verified completed child results are identified
explicitly. Audited trace retirement and storage disposition are separate from
successful behavior execution.

The same runner qualified the full suite in Fast and Small. With
`ZLLVM_ZIG_MODE=ReleaseSmall`, the hook selects `zig-release-small-accepted`
and the compiler-rt frontend also uses Small. Runtime and test capture
populations are discovered separately for each mode. The Small run found
903 runtime definitions and 6,684 test definitions.
[Fast qualification](evidence/release_fast_preopt_acceptance_20261117.md)
and [Small qualification](evidence/release_small_preopt_acceptance_20261117.md)

For managed roots, private caches, the test executable and captured local objects
use the temporary workspace; reports, captured inputs, event traces and logs
stay in evidence. Pass this tool's `--retain-products` while independent object
audits or later comparisons still need those temporary products. Release its
`validation.storage-layout.json` after those consumers finish. Completed failures
record `status=failed` and keep their scratch until diagnosis and explicit
release; standalone legacy roots retain their old layout, while explicit
pipeline retention requires a managed root.
The [final acceptance](evidence/compiler_behavior_follow_up_acceptance_20261113.json)
contains all 16 complete results: two compiler generations, four modes and both
routes, with exact named pass/skip comparison against the reference.

`tools/run_frontend_f80.zig` compiles a retained Zig probe with the candidate's
normal LLVM route, links an independent C caller, and checks nine native
observations plus four compile-time layout assertions. It records the compiler,
source pin, inputs, inherited resources and output hashes, and uses owned local
and global caches. For the accepted regression, use the unchanged probe and C
driver identified by the final acceptance's f80 receipts:

```sh
zig run tools/run_frontend_f80.zig -- \
  --output-root local-state/validations/frontend-f80 \
  --compiler /absolute/path/to/candidate/zig \
  --zig-source /absolute/path/to/pinned/ziglang \
  --probe /absolute/path/to/retained/probe.zig \
  --driver /absolute/path/to/retained/driver.c
```

The integrated-executable wrapper has a six-hour aggregate deadline
(21,600,000 ms) for the entire suite. `ZLLVM_INTEGRATED_TIMEOUT_MS` overrides it
with a positive decimal u32 millisecond value; zero, empty, malformed and
overflowing values fail. Reports retain `aggregate_timeout_ms` and its scope.
Individual command deadlines remain owned by their runners and are unchanged.

Batch-08 fixture generation, research runs, oracle calibration and comparisons
also use maintained Zig entry points. The retained `generate-native-pairs.py`,
`staged-frontier/generate-fixtures.py` and `staged-frontier/generate-drivers.py`
are replaced by one deterministic generator:

```sh
zig run tools/generate_ssa_transport_canaries.zig -- \
  --output-root local-state/validations/generated-ssa-transport
```

It writes three LLVM fixtures, two C drivers and `functions.json`, with SHA-256
digests in `generation.json`. It constructs cases from typed width/variant
inventories and contains its own clobber template; it does not read generated
fixtures as templates. Optional `--verify-root DIR` checks all six outputs
against a retained directory. Generated files preserve the previous bytes.

The existing native runner replaces `staged-frontier/run-native-research.py`:

```sh
zig run tools/run_native_canary.zig -- \
  --population integer_freeze_values --zllvm /absolute/path/to/z_llvm \
  --fault-count 5 --output-root local-state/validations/freeze-native
```

Omitting `--mode` runs ReleaseFast, ReleaseSafe and ReleaseSmall. Each mode
checks independent LLVM, direct local selection and the accepted optimizer
pipeline, exact driver stdout and complete composed-owner membership. Optional
`--fault-count N` then requires every numbered injection to exit 1, write no
stdout and identify the exact `fault=N` token. It repeats the successful baseline
first. Timeouts, signals, missing executables and always-failing drivers cannot
pass calibration. Default runs retain their existing procedure and report fields.
A private research compiler remains research evidence; using this entry point
does not grant production acceptance.

Native registry runs accept `ZLLVM_NATIVE_CANARY_COMPILER_TIMEOUT_MS` as a
positive decimal deadline in milliseconds for each local helper optimization,
object emission and selection-owner command. The default is 120,000 ms.
The command ledger records each effective deadline and process outcome.

A registry `provider_fixture` builds a separate local object with reachable
selection by default. Set `provider_codegen_reachable` to `false` to exercise
default object emission on both sides of a two-object link. The
`table_private_link` regression uses this route to check colliding private and
internal table names; provider source, backend and object hashes remain recorded.

`tools/run_native_fault_checks.zig` replaces `check-pair-faults.py` and
`check-aggregate-faults.py` when binaries already exist. Its input manifest is:

```json
{
  "fault_count": 5,
  "runs": [
    {
      "root": "local-state/validations/freeze-native",
      "population": "integer_freeze_values",
      "build": "Debug",
      "modes": ["ReleaseFast", "ReleaseSafe", "ReleaseSmall"]
    }
  ]
}
```

```sh
zig run tools/run_native_fault_checks.zig -- \
  --input-manifest local-state/validations/fault-inputs.json \
  --output-root local-state/validations/fault-checks
```

Every input report must have passed. Modes may be omitted to select all three.
The runner records input/report and executable hashes, baseline observations,
supervised commands and each injected failure in a separate new output root.
Optional `--compare-with FILE` compares all control identities, statuses,
stdout, stderr and executable hashes against a prior detailed report. For old
single-population reports without population fields, also pass
`--legacy-population NAME`. Historical `fast`/`debug` labels normalize to
`ReleaseFast`/`Debug`. Wrapper telemetry with only an exit status and log is not
a detailed fault report. Keep wrapper output and application reports separate.

`tools/compare_native_runs.zig` replaces `compare-native-pairs.py` and the
registry-preservation part of `check-pair-faults.py`:

```sh
zig run tools/compare_native_runs.zig -- \
  --baseline-root local-state/validations/prior-native \
  --candidate-root local-state/validations/current-native \
  --added-populations flag_pair_values,integer_freeze_values,atomic_storage_views \
  --baseline-registry local-state/validations/prior-registry.json \
  --output-root local-state/validations/native-comparison
```

Both runs must pass with identical source hashes, all prior fixture hashes and
integer observation/control counters. Additional fixtures and commands must
belong to the explicitly named registry populations. Compiler paths and evidence
roots normalize for command matching; an occurrence index preserves repeated
identical command lines. Prior return codes, supervision outcomes, actual
statuses and timeouts must match, and successful compiler stdout artifacts must
be byte identical. Any artifact difference fails the comparison and is listed
for review. Optional registry comparison requires exact retention of every
prior entry in order and exactly the approved additions. Reports and command
manifests are hashed into the new comparison report.

Use `jqz` and the maintained Zig report tools for structured inspection,
`zigrep --no-config` for searches and file discovery, and patches for source
edits. For example:

```sh
jqz '{status, code_revision, complete_results: .matrix_modes, named_reference_outcomes_compared}' \
  docs/evidence/compiler_behavior_follow_up_acceptance_20261113.json
zigrep --no-config -n -F 'profile.events.jsonl' tools/validation docs/validation_tools.md
```

Check jqz's query syntax before assuming jq compatibility. Its default document
limit is 64 MiB; `--max-document-bytes 134217728` permits inspection of a retained
report up to 128 MiB. Use `zigrep --no-config --max-depth 1` for shallow discovery
in large generated-state roots. These inspection CLIs are separate tools, not build
dependencies. Historical Python files remain immutable evidence; new validation
commands do not invoke them or inline Python.

The [whole-compiler diagnostic plan](plans/2026-11-07-whole-compiler-diagnostic.md)
adds an opt-in runner outside the accepted gate inventory. It attempts the
pinned LLVM-enabled Zig compiler, x86_64 Linux GNU, baseline CPU, ReleaseFast.
The default postopt hook uses LLVM optimization. Original and
resolved CMake provider configurations, library hashes, closed hook environment,
commands and each exact backend input are retained. Explicit multiarch provider
paths avoid relying on native library discovery for the selected GNU target.

```sh
stage=local-state/validations/whole-compiler/batch-01/build
tools/run-validation --output-root "$stage" checks run_whole_compiler \
  --output-root "$stage/run" --zllvm "$backend" --libc-file "$libc" \
  --local-pipeline preopt --profile-events --retain-products
```

`--zig-source`, `--zig-emitter` and `--config-h` select the pinned checkout and
its existing frontend/CMake inputs. `--timeout-ms` defaults to 3,600,000 per
build/backend command. `--input-ir FILE` runs a separately labelled captured-IR
diagnostic without claiming a compiler build. All runs require new output
directories. Admission and sampled runtime reserve use the existing serial
space policy. `--reserve-bytes N` selects a stronger floor. The runner cancels
its process group on a reserve violation.

With `--local-pipeline preopt`, the frontend sends complete LLVM text to the
local ReleaseFast optimizer, then sends its output to the local object emitter.
The initial build records `optimizations` and `invocations`. The candidate's
own build records `self_rebuild_optimizations` and `self_rebuild_invocations`.
Each successful build checks the hook markers, optimizer output and emitter
input identity, compiler and runtime objects, and actual object delivery.
Preopt requires a fresh whole build. The nested `--retain-products` keeps its
two install prefixes and objects available for subsequent behavior and audits.
Declare those consumers in the checked stage's `retention.md` before launch.
[ReleaseFast self-rebuild plan](plans/2026-11-17-release-fast-compiler-preopt-self-rebuild.md)

`--libc-file FILE` selects an explicit native libc installation for host provider
libraries. The closed child environment receives a retained copy through
`ZIG_LIBC`; original/effective configuration and CRT/library hashes verify after
the run. This keeps the GNU target and baseline CPU while avoiding a mix of
Zig's default glibc stubs and newer host LLVM/C++ dependencies. Initial build and
self-rebuild use separate global/local cache and install roots. Each generation
warms its own host-tool cache with the pinned emitter and without the local
hook, then builds the requested baseline compiler through the hook. The
self-rebuild command uses the new candidate as its frontend. Host-tool setup
commands and emitter identity are retained separately and remain outside the
local compiler/runtime object claim.

`--self-cpu N` pins the self-build setup and actual frontend command to one
Linux processor through the recorded `/usr/bin/taskset` launcher. The initial
build keeps the caller's affinity, preserving exact captured-object reuse.
Reports retain the launcher identity, effective commands and inherited process
limits. This option and a caller-supplied 1 GiB main stack describe the historical
acceptance setup. The final normal-resource acceptance omits both affinity and
stack overrides: the controller and frontend inherit the pinned tooling Zig's
existing 46 MiB stack request and full 0–15 affinity. See
[current state](current_state.md) for the service/controller distinction. The
target CPU remains `baseline`, and the generated-frame guard remains unchanged.
Captured-IR mode rejects `--self-cpu`.

`--reuse-captured-objects ROOT` permits the initial build or captured-IR replay
to reuse completed local objects from a preceding runner root, including a run
whose outer link failed. Input hash, backend hash, compiler source map, backend
arguments, actual source command, profile/owners and ELF must validate. Input or
argument misses execute the backend; changed or failed retained artifacts fail
closed. Reuse chains are rejected. Reports distinguish delivery from backend
execution, retain source commands and identify copied profiling measurements.
The self-rebuild always executes the backend with reuse disabled.

For the original 455-definition runtime input, add `--runtime-checks` to a
captured-IR replay. The runner links the delivered local object and a separately
compiled LLVM reference to `test/whole_compiler/runtime_completion_driver.c`,
runs 21,792 observations on each, including 641 unsigned-division cases over
four helpers, and detects seven numbered failures per route (14 controls total).
The input hash is fixed; another module cannot silently replace this population.
These observations cover the exercised exports, not execution of every definition.
All object deliveries additionally require nonempty selected function symbols,
in-bounds symbols/relocations and no unresolved `llvm.*` intrinsic provider.

`tools/audit_captured_object.zig` can inspect retained output after runner
postprocessing failed:

```sh
zig run tools/audit_captured_object.zig -- \
  --capture-root /absolute/path/to/retained-run \
  --census /absolute/path/to/complete-census.jsonl \
  --output-root local-state/validations/retained-object-audit
```

It checks that the backend command completed with actual exit code zero, plus
exact arguments, input and binary hashes,
profile, owners, census and object contract. Add `--capture-directory DIR` to
select a unique complete capture recorded in the parent's `.captures`,
`.invocations` or `.self_rebuild_invocations` list. The directory must remain
inside the capture root and match its recorded capture identity. Retained
`input.ll` must match its recorded hash and the backend command's actual input.
An explicitly recorded capture may have a deleted transient frontend IR file;
if that original still exists, its hash must match too. The default fixed-input
route retains the strict original-input check.

For managed captures, the auditor resolves `local.o` through the run's validated
`validation.storage-layout.json` and holds a storage reader lease while checking
it. Legacy runs without a layout keep the capture-directory path. A missing
managed object is an error even if an evidence copy exists. Retain the producer's
workspace through the audit with its `--retain-products` option, then release it
after all consumers finish.

The focused `test-behavior-storage` build step exercises managed and legacy
captures with the real backend and independent auditor, including rejection of
a missing managed object despite a valid evidence copy. `test-preopt-behavior`
also runs the focused stage/reference/headroom units and real two-stage CLI
controls, including changed optimizer output, partial-output optimizer failure,
incorrect reference, unsupported mode/route and a stronger reserve.

The auditor writes a separate report and leaves the original runner receipt
unchanged. It requires one successful actual backend command. A reused initial
compiler object instead needs the separate source-object audit and exact binding
of input, object, profile, owners, events and semantic arguments recorded by the
final acceptance; reuse does not establish fresh execution. The self-rebuild
always disables reuse. Source and build-receipt binding remains a separate
requirement for both routes.

Exit zero means the requested route passed; a reproducible compiler rejection
still returns nonzero and is recorded as a blocked diagnostic, without changing
accepted counters. Report-all selection failures are grouped by diagnostic and
selector tag. Missing selection records after an earlier failure mean no census
was completed. Successful object delivery requires consistent counts, matching
profile/ownership names and a valid x86_64 ELF object. Hook capture retains raw
logs and GNU time measurements, whose maximum RSS is a process/descendant
high-water value rather than a sum of simultaneous memory use. Linking,
`zig version`, behavior checks and self-rebuild are conditional later stages.
If runtime compilation fails before the main compiler reaches the hook, a
separate compiler-module diagnostic reuses the recorded build-exe arguments,
disables binary/runtime emission, exports optimized LLVM IR and attempts local
object emission. The original runtime rejection remains a build blocker; this
continuation provides no link or self-hosting credit.

The selection rejection census parses and verifies the complete module, then
uses the production selection API with an optional observer. It records the
failing composed operation after private normalization/legalization, including
call and parameter types, attributes, operand origins and resolved locations.
Each new selection attempt clears the prior observation; only a context matching
the final selector diagnostic is published. An unattributed rejection stays null.
The original module is unchanged. Complete traversal is marked explicitly; an
optional function filter is diagnostic only and never counts as a full census.
Output creation is exclusive, so retained results cannot be overwritten.

```sh
zig run -O ReleaseFast src/selection_census.zig -- captured-compiler.ll new-census.jsonl
```

Three read-only syntax/verification census tools provide additional attribution after an early
failure. Global syntax census parses every complete global/alias line
independently and saves the first rejected line to a new file. Definition syntax
census parses each complete `define` body independently, records its original
line/header and saves the first rejected definition. It rejects unfinished
inventories, and never overwrites an existing extraction destination. Function
verification census preserves declarations, global data and function headers,
requires an all-unreachable-body baseline to verify, then restores each
original body in turn. These projections never emit or execute code and cannot
establish full-module verification or selection. A missing final count means
the census did not finish.

```sh
zig run -O ReleaseFast --dep ir \
  -Mroot=tools/whole_compiler_global_census.zig -Mir=src/ir.zig -- \
  captured-compiler.ll new-first-global.ll
zig run -O ReleaseFast --dep ir \
  -Mroot=tools/whole_compiler_function_census.zig -Mir=src/ir.zig -- \
  captured-compiler.ll new-first-definition.ll
zig run -O ReleaseFast --dep ir \
  -Mroot=tools/whole_compiler_verification_census.zig -Mir=src/ir.zig -- \
  captured-runtime.ll
```

Unchanged-program manifests can set `compile_timeout_ms` to a positive 32-bit
millisecond budget. It applies to reference/local compilation, selector-owner
replay and diagnostic re-emission; the default is 120,000 ms. Fibonacci and the
four execution-breadth manifests use 900,000 ms so a Debug compiler can process
the Safe runtime. Links retain the
default command budget and single executable observations retain their five-second
limit. File-corpus cases have ten seconds each. Failed compilation, link and owner-replay stages preserve the command
outcome and actual termination even when the compiler produces no stderr;
command records include the budget.

The [compiler throughput comparison](evidence/execution_breadth.md) measures Debug
and ReleaseFast compiler builds separately from generated-code performance.
The [validation performance delivery](evidence/validation_performance.md) extends
explicit selection to nested programs/native consumers and records their actual
build identities. Separate prefixes retain each requested compiler build mode
and the required Debug/ReleaseSafe coverage.

## Selecting and retaining validation compilers

Prepare one required compiler mode with a separate install prefix:

```sh
tools/run-validation \
  --output-root local-state/validations/example/batch-01/prepare build build_validation_compiler \
  --output-root local-state/validations/example/batch-01/compilers --mode ReleaseFast
```

This provides `local-state/validations/example/batch-01/compilers/ReleaseFast/bin/z_llvm`
as a stable alias, with an adjacent `.build.json` receipt. The actual compiler
and private build products live in a managed pipeline workspace. Release its
`ReleaseFast/compiler.storage-layout.json` after the last consumer completes.
`--mode Debug` and `--mode ReleaseSafe` use
separate directories. Optional `--zig`, `--target` and `--cpu` select build
inputs; the defaults are the project-pinned Zig, `x86_64-linux-gnu` and baseline
CPU. Symbols and frame pointers are retained. Zig validates its dependency cache
on every invocation; missing or corrupt installed binaries are rebuilt/reinstalled.
The receipt binds source/dependency and Zig library hashes, target, CPU, mode,
effective options, producer command and binary hash. An unchanged cached build
preserves the original receipt; its latest command remains in `commands.json`.

`ZLLVM_EXE` selects the compiler used throughout the integrated-executable gate,
including imported behavioral canaries, `hello_libc` and the C/native suite.
`ZIG_EMITTER` and `ZIG_SOURCE_DIR` reach nested consumers that support them.
Standalone program and C tools accept `--zllvm`, `--zig-emitter` and `--zig-source`;
the input-program tool accepts the first two. Selected paths, hashes and build
receipts are retained and checked again at completion. A caller-supplied binary
without a receipt is labelled unrecorded. Existing source, fixture, emitter
version and emitter-hash checks still apply. Compiler build mode is recorded
separately from the three generated-code input modes under test.

For a full run with a prepared ReleaseFast compiler and durable nested reports:

```sh
validation_emitter="$(realpath ../ziglang/build/stage4/bin/zig)"
ZLLVM_EXE="$PWD/local-state/validations/example/batch-01/compilers/ReleaseFast/bin/z_llvm" \
ZIG_EMITTER="$validation_emitter" \
ZIG_SOURCE_DIR="$PWD/../ziglang" \
ZLLVM_INTEGRATED_OUTPUT_ROOT=local-state/validations/my-validation/integrated \
zig build distribution-all -- --serial --fresh-real-rows \
  --zig-emitter="$validation_emitter" \
  --real-rows-validation-root=local-state/validations/my-validation/air/my-validation \
  --real-rows-cache-root=local-state/caches/my-validation \
  --serial-root=local-state/validations/my-validation/serial
```

Use new evidence paths. The real-row CLI requires the emitter's canonical
absolute path; nested program consumers can record valid aliases. The optional
integrated output directory is created exclusively inside the project and retained
on success or failure; an existing root is rejected. Without it, the runner uses
its ordinary temporary-directory lifecycle. Build artifact reuse and passing-gate
reuse follow separate rules in [validation tiers](validation_tiers.md).

The execution-control gate reuses a freshly compiled harness within each
function/mode, preserving separate independent references and all 54 controls.
`--fresh-harness` selects the earlier source-compilation route for comparison;
`--mode ReleaseFast|ReleaseSafe|ReleaseSmall` restricts a diagnostic. Acceptance
still requires the default complete three-mode population. Command histories
remain complete atomically published JSON after every command. The
[performance evidence](evidence/validation_performance.md) records the measured
benefit and retained Debug/ReleaseSafe coverage.

Unchanged Zig programs now obtain ownership and a phase profile from the captured
object-emission run. `run_real_program --replay-owners` additionally selects the
captured IR independently and requires identical ownership. Compilation-route
tests permanently check object equality with profiling/sidecars enabled and
sidecar/replay equality.

`zig build input-program -- --output-root DIR` compiles the unchanged pinned
`jsmn` JSON-dump example once per Fast/Safe/Small mode, then runs 46 frozen stdin
inputs per executable. The [manifest](../test/real_programs/jsmn_jsondump.json)
authenticates the unchanged sources and independently specified stdout, stderr
and exit status. Reports retain all 138 input/mode observations, ownership
replay, phase profiles and 552 observation-mutation controls. These controls test
the oracle's rejection of wrong status/output and abnormal termination; they
are not compiler mutation or allocation-failure tests. File-backed stdin is
reopened for each execution and its hash is recorded with the command.

`zig build zig-input-program -- --output-root DIR` compiles the unchanged pinned
language-reference migration tool once per release mode and runs the
[29-case file corpus](../test/real_programs/migrate_langref.md). Each execution
has a fresh working directory. Both routes must match independently specified
status, streams and the exact output files; inputs must remain unchanged.
The gate requires independent ownership replay and retains compilation profiles.
Its negative controls mutate completion, status, streams and file observations.
The manifest is authenticated before and after execution, alongside the source,
tools and compiler binaries. This is a separate input/mode population from the
fixed Zig examples, C corpus and compiler-core cohort.

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
zig build execution-breadth-controls -- --output-root local-state/validations/my-cohort-controls
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
tools/run-validation \
  --output-root local-state/validations/example/batch-01/my-run checks \
  --command zig build real-program-policy-tests
zig run tools/validation_progress.zig -- \
  --record local-state/validations/example/batch-01/my-run/checks.json
zig run tools/validation_snapshot.zig -- \
  --output local-state/validations/example/batch-01/my-run/source.json
zig run tools/validation_snapshot.zig -- \
  --verify local-state/validations/example/batch-01/my-run/source.json
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
## Launch current tools with another source checkout

Use the tracked launcher for copied fixtures or a sibling Git worktree. Select
the source project and storage owner independently:

```sh
ZIG=/home/oleg/.zig/0.17.0/files/zig tools/run-validation \
  --project-root /absolute/source-worktree \
  --storage-root /absolute/storage-owner \
  --output-root local-state/validations/example/batch-01/check native-check run_native_canary \
  --output-root /absolute/storage-owner/local-state/validations/example/batch-01/check/native \
  --population module_dependencies --mode ReleaseFast --zllvm /absolute/compiler
```

The launcher compiles the current checkout's checked runner and selected tool in
ReleaseFast mode. `--project-root` / `ZLLVM_PROJECT_ROOT` selects the inputs and
command working directory; it does not select frozen tool sources.
`--storage-root` defaults to the launcher's checkout and exports
`ZLLVM_STORAGE_ROOT`. The launcher's relative output root is resolved against
that owner. Pass absolute owner paths to child tools, whose relative arguments
still resolve against the source project.

The launcher sets `ZLLVM_REQUIRE_MANAGED_STORAGE=1`: its output and child output
roots must be under the owner's `local-state/validations/SUITE/BATCH/RUN`.
Unmanaged paths and symlink escapes fail before output creation or execution.
The checked child uses the owner's workspace for default caches and temporary
files, and the collector records the external source directory only as job
identity. It never treats that directory as a deletion root. The owner's
reusable bootstrap cache lives in `local-state/tmp/validation-tools`.
The launcher builds the checked runner under a bootstrap lock and executes it
directly, so a waiting `zig run` parent cannot falsely hold completed output
during collection.

For scripts and other executables, replace the tool name with
`--command COMMAND [ARG...]`. Arguments are forwarded literally. The child gets
`ZLLVM_RUN_ROOT` for maintained reports and `ZLLVM_TEMP_ROOT` for disposable work.
The receipt's `storage` object records the roots, layout path, lifetime and
caller-owned environment overrides. To keep these temporary products through
later consumers, pass `--retain-products` before `--output-root`, then release
the named layout after those consumers finish. This flag controls the checked
command's workspace; a nested tool's own workspace uses that tool's retention
option. Failed/interrupted work remains available for diagnosis.

```sh
tools/run-validation --retain-products \
  --output-root local-state/validations/example/batch-01/compare compare \
  --command bash /absolute/path/to/compare.sh
```

For an automated `bash -c` wrapper, use `exec` for its final launcher command.
A surviving supervisor whose argv still names the run deliberately defers
collection until that supervisor exits.
Explicit cache environment overrides still take precedence and remain
caller-owned; omit them when using the workspace defaults. Running a previously
cached executable or `zig run` against a frozen checkout keeps that old tool's
behavior; updating the main checkout alone cannot migrate such jobs.
