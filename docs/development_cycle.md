# Development Cycle

Each implementation cycle uses `docs/next_steps.md` as the active checklist.

The development cycle exists to replace the LLVM library dependency used by
Zig's distribution. Work should therefore be selected and closed by evidence
from Zig's actual LLVM use: Zig-emitted IR, Zig's PassBuilder configuration,
target/backend handoff requirements, or a measured gap in the current local
replacement.

For every future step that reproduces LLVM behavior, completion requires an upstream mapping before the step is committed.

## Work Selection Priority

Pick work in this order:

1.  A source-backed Zig IR row that fails to parse, verify, optimize, or hand
    off through the local replacement.
2.  A Zig distribution mode or target requirement that still needs an LLVM
    library fallback.
3.  A concrete `opt-22` mismatch for a pass or pipeline that Zig actually
    invokes.
4.  A backend, object, ABI, debug, sanitizer, LTO, or target-feature gap that
    blocks removing LLVM from a named Zig distribution configuration.
5.  Optional optimizer-quality work only when it is tied to source-backed Zig
    IR or an accepted pipeline fixture.

Do not promote a pass just because it appears in LLVM's generic pipeline. If
the pass is not exercised by Zig's configured LLVM path, or if the current
finish definition deliberately treats it as a boundary, keep it in the backlog
until a measured replacement need appears.

An `opt-22` mismatch is promotable only when it is visible in one of these
places:

- an accepted Zig pipeline;
- a source-backed reduced fixture;
- an x86_64 handoff or codegen shape needed by the replacement matrix.

Boundary closure is valid work when it changes the replacement matrix. A cycle
may close by proving that a row is a local conservative boundary, out of scope
for the current x86_64 milestone, or blocked on missing infrastructure, as long
as the evidence and upstream behavior are documented.

## Empty Active Queue

When `docs/next_steps.md` has no active slice, do not continue with generic
pass parity probing. Start from replacement evidence:

1.  Inspect the latest source-backed corpus, accepted-pipeline, readiness, and
    handoff records.
2.  Decide whether that evidence is still fresh using the evidence freshness
    rules below.
3.  If the evidence is stale, run the smallest x86_64 discovery or validation
    command that can refresh the affected stage.
4.  Promote exactly one measured blocker, matrix gap, or documented boundary
    closure into `docs/next_steps.md`.
5.  If no blocker appears, record the clean row or boundary and move to the
    next x86_64 stage before considering non-x86_64 work.

## Accepted Optimizer Triage

When recent work may affect accepted optimizer behavior and there is no active
slice, tighten discovery to this order:

1.  Check `ReleaseFast` first. It is the primary optimizer replacement row and
    the best signal for regressions in canonicalization passes such as
    SimplifyCFG.
2.  Record new evidence only when the sweep is clean and reproducible. Include
    exact mode, pass pipeline, target/triple, local commit, output directory,
    and summary path.
3.  Check `ReleaseSafe` only when the changed behavior can affect
    safety/runtime-call CFG shapes, or when the existing `ReleaseSafe` evidence
    is stale.
4.  Check `ReleaseSmall` next only as milestone evidence. `Oz` may expose
    different canonical forms, but it is not a default per-cycle habit.
5.  Keep `Debug` optional unless debug metadata, O0 pipeline behavior, or
    Debug evidence freshness changed.
6.  Promote the first parse, verify, optimizer, input-size, handoff, or codegen
    failure into `docs/next_steps.md` as the next real implementation slice.
7.  Treat explicit future rows as boundaries unless new evidence changes their
    status. Reaffirm the boundary rather than reclassifying it when no new
    requirement appears.
8.  Run x86_64 handoff or codegen checks only when refreshed optimizer output
    introduces a new shape relevant to handoff.
9.  Update readiness and evidence docs only when there is new data. Evidence
    docs should lag as little as possible, but should not churn for unchanged
    facts.
10. If no blockers appear, leave `docs/next_steps.md` empty unless a boundary
    closure advances the x86_64 replacement matrix.

Each active checklist in `docs/next_steps.md` should state:

```text
Replacement goal:
Zig evidence:
LLVM fallback removed or reduced:
Mode/target/stage row:
Upstream mapping:
Known boundary:
Validation gate:
Commit:
```

Use `unknown` only while selecting the slice. Before implementation is marked
complete, replace `unknown` with a concrete answer or document why the slice is
only preparatory infrastructure.

## Evidence Freshness

Previously clean evidence becomes stale for the affected stage when one of
these changes lands:

- parser, verifier, printer, pass-manager, or shared-analysis behavior;
- target parsing, DataLayout, ABI classification, calling convention, object,
  codegen, or handoff behavior;
- `test/zig/manifest.tsv` or any checked Zig-emitted fixture;
- stage4 Zig revision or fixture emitter version;
- accepted pipeline expansion, pass ordering, or pass alias behavior;
- a readiness gate failure that contradicts the recorded matrix status.

When evidence is stale, refresh only the affected mode, target, or stage unless
the change is a release milestone or matrix status upgrade.

## Source-Owned Inner Loop

For x86_64 ReleaseFast, ReleaseSafe, and ReleaseSmall source-owned work, do
not use `distribution-all` as the development loop. `distribution-all` is a
milestone confirmation gate for handoff and broad claim changes.

Use this ladder:

```text
1. zig run tools/run_distribution_zig_integrated_object.zig -- --release-source-owned --case=<case-id>
2. zig build test
3. zig build distribution-x86_64-release-source-owned
4. zig build distribution-x86_64-selected-zllvm
5. zig build check-zig-stage4-emitter  # only when ../ziglang changed
6. zig build distribution-native-link-object-inspection -- --release-source-owned  # milestone object-boundary proof
7. zig build distribution-native-link -- --release-source-owned  # milestone native-link executable proof
8. zig build probe-native-linker -- --release-source-owned  # milestone native-link acceptance probe

For real AIR work, keep the loop source-driven and release-mode focused:

1. export or run one source through `ZLLVM_AIR_EXPORT_PATH`
2. run `zig build test`
3. run `zig build distribution-zig-air-uncurated-releasefast` or
   `zig build distribution-zig-air-uncurated-releasesafe`
4. run `zig build distribution-zig-air-uncurated-release` after a mode-shared
   AIR lowering change

The uncurated gate discovers `test/zig/inputs/*.zig`; it does not use selected
case IDs or source-fact body classification. Its current hook contract is
`zllvm-air-export-v1` plus a `structured_air-v1` body/branch metadata section;
iterate in z_llvm unless that generic contract is missing a real compiler fact.
Do not add `distribution-all`, ELF inspection, or native-link probes to this
inner loop.
9. zig build distribution-all          # milestone confirmation only
```

Run step 5 only when the Zig hook contract or patched Zig source changed. Run
steps 6-8 when confirming the full 100-row source-owned object/link boundary,
not for ordinary row iteration; they check the patched stage4 hook and run
`zig build` before object inspection or native-link handoff. Run
step 9 only before handoff, before committing a broad evidence/matrix claim, or
when a change affects several distribution gates at once.

Do not rebuild stage4 for every row. Patch `../ziglang` only when the hook
contract changes. The stable accepted hook emits generic `zllvm-source-facts-v1`
`generic-compiler-facts`: root source path, mode, target, function inventory,
exported/main signature, parameter and return types, block/instruction counts,
instruction-category summaries, globals, TLS, calls, atomics, and inline-asm
capability facts. The hook does not read or token-count wrapper source. z_llvm
owns fact-stream classification into DescriptorV2 rows, and the focused runner
includes wrong-tag and wrong-facts probes. New source-owned rows should usually
require z_llvm runner/descriptor/lowering changes only.

For this milestone the Zig hook is frozen. Patch Zig only for deliberate
`zllvm-source-facts-v1` contract-version changes, not for row expansion or
surface classification.

## Distribution Replacement Matrix

Roadmap and cycle docs should keep progress visible as a replacement matrix,
not only as a pass list. For each promoted slice, identify the affected row:

```text
mode: Debug | ReleaseFast | ReleaseSafe | ReleaseSmall | LTO pre-link
target: x86_64-linux-gnu | x86_64-linux-musl | aarch64-linux-gnu | wasm32-wasi | other named target
stage: parse | verify | optimize | codegen handoff | asm/object | link/LTO handoff
status: local replacement | local conservative boundary | LLVM fallback required | out of scope
```

A task moves the project toward the goal only if it changes one of those rows,
adds evidence for a row, or explains why the row is not part of the current
replacement milestone.

## Initial Target Policy

Start the distribution replacement effort with one hardware target. The default
initial target is:

```text
x86_64
```

Use `x86_64-linux-gnu` as the primary validation triple unless a cycle is
explicitly about another OS/ABI boundary. Other targets stay documented as
future or conservative boundaries until the x86_64 replacement path has enough
parse, verify, optimize, codegen handoff, asm/object, and link/LTO evidence to
justify expanding the matrix.

Do not require every cycle to prove every Zig mode and target. A non-x86_64
check belongs in a cycle only when the selected work changes target parsing,
DataLayout, ABI classification, target features, object format, calling
convention behavior, or backend lowering that can plausibly differ by target.

## Linker Ownership Rule

`z_llvm` must not grow a standalone executable, shared-library, archive, or
linker-script implementation. Its distribution role stops at LLVM-compatible
IR, selected optimization, and selected relocatable object emission. Final
executable and library linking belongs to Zig's linker/toolchain
(`ziglang/src/link/*`, or Zig's selected LLD path).

The boundary is executable evidence, not just policy: `z_llvm --emit=exe` must
remain rejected, and selected executable validation must continue to hand local
objects to Zig's toolchain instead of adding a local linker path. Use
`zig build distribution-boundary` for the explicit linker/CRT ownership gate,
`zig build distribution-native-link` for the selected `-fno-lld` executable
proof, or `zig build distribution-all` when the positive no-LLVM-codegen
subset, native-link proof/probe, and conservative boundary gates all need to be
proven.

Executable validation should emit local `.o` files with `z_llvm` and then hand
them to Zig's linker/toolchain through `zig cc` or the selected Zig driver
path. Treat failures as object ABI, symbol, relocation, section, or Zig-linker
integration gaps unless evidence proves a Zig linker change is required.
Because `zig cc` may still select an LLD-backed path internally, current
executable gates prove Zig-driver/toolchain handoff only. They do not prove
native Zig linker coverage unless the gate explicitly selects and records a
native-linker path. Native linker replacement is Zig-owned; this repository can
only validate that its emitted objects are acceptable inputs to that path.
The selected native-linker proof is `zig build distribution-native-link`: it
emits local objects with `z_llvm`, compiles C harnesses without linking, then
links with `zig build-exe -fno-lld` before running the executables.
`zig build probe-native-linker` uses the same selected object set to classify
native-linker acceptance failures as local object compatibility work.

## Validation Scope

Use the smallest validation gate that proves the selected slice:

```text
docs-only change
  -> no test run required; inspect the rendered diff

single pass or analysis fixture
  -> run the focused opt fixture or unit test for that pass

single pass implementation touching shared pass logic
  -> run the focused fixture and `zig build test`

parser, verifier, printer, pass manager, or shared analysis change
  -> run the focused fixture plus `zig build readiness`

target, ABI, codegen, object, or handoff change
  -> run the focused gate plus `zig build handoff`

linker, CRT, executable handoff, non-x86_64 target boundary, or debug unwind boundary
  -> run `zig build distribution-boundary`

native Zig linker handoff change
  -> run `zig build distribution-native-link`

corpus manifest or Zig-emitted fixture change
  -> run the affected mode sweep only

release milestone or replacement-matrix status upgrade
  -> run `zig build readiness` plus the relevant distribution gate, usually
     `zig build distribution-all`
```

Full Debug, ReleaseFast, ReleaseSafe, ReleaseSmall, and multi-target sweeps are
milestone evidence, not default per-cycle work. If a focused gate is skipped,
the completion note must say why the touched surface is docs-only,
fixture-only, or otherwise covered by a narrower check.

## Compiler Selection

Follow the compiler policy in [environment.md](environment.md):

- use `zig` on `PATH` for building and testing `z_llvm` itself;
- use `../ziglang/build/stage4/bin/zig` for authoritative Zig-emitted LLVM IR
  fixtures;
- do not use `../ziglang/build/stage3/bin/zig` for fixture generation unless a
  step explicitly says it is testing bootstrap behavior.

When a step updates Zig-emitted IR fixtures, record the emitter version and
`../ziglang` source revision in the fixture manifest before marking the step
complete.

Use these build steps for fixture work:

```bash
zig build check-zig-stage4-emitter
zig build capture-zig-ir -- test/zig/inputs/<group>.zig ReleaseFast
zig build lint-zig-ir-manifest
```

The equivalent build aliases for common fixture and gate workflows are listed
in [build_steps.md](build_steps.md). Prefer `zig build readiness`,
`zig build handoff`, `zig build distribution-all`, and
`zig build distribution-boundary` for current validation. Archived roadmap
documents may still show old script commands as historical transcripts; do not
add new shell-script entrypoints for current validation.

Readiness checks run manifest linting and accepted corpus validation through
Zig build steps, but do not regenerate fixtures.

For corpus discovery, use `tools/zig_corpus_discovery.zig` and keep the same
compiler split:

- stage4 Zig emits authoritative LLVM IR through `--zig-exe` or the default
  `../ziglang/build/stage4/bin/zig`;
- local checks build and run `z_llvm` with `zig` on `PATH` in ReleaseFast mode
  by default;
- use `--local-zllvm-exe=zig-out/bin/z_llvm` after an explicit
  `zig build -Doptimize=ReleaseFast` when repeating large sweeps;
- keep the default `--local-quiet` behavior for large sweeps so local verify
  checks do not print the whole normalized module for every row;
- for default `--passes=verify` discovery sweeps, the tool adds
  `--pass-limit=0` to the local `z_llvm` invocation because `z_llvm` already
  parses and verifies the module before entering the pass manager;
- use `--local-trace` only for focused debugging, not full discovery sweeps.

The usual command shape is:

```bash
zig build -Doptimize=ReleaseFast

zig run tools/zig_corpus_discovery.zig -- \
  --out-dir=tmp/zig_ir/<sweep-name> \
  --mode=<Debug|ReleaseFast|ReleaseSafe|ReleaseSmall> \
  --local-input-limit=67108864 \
  --local-zllvm-exe=zig-out/bin/z_llvm \
  --progress-every=50
```

To start or restart a discovery cycle:

1.  Check whether any old discovery process is still running:

    ```bash
    ps -ef | rg 'zig_corpus_discovery|stage4/bin/zig|zig-out/bin/z_llvm'
    ```

2.  Build the local checker once in ReleaseFast mode:

    ```bash
    zig build -Doptimize=ReleaseFast
    ```

3.  Pick the first mode that has not completed cleanly. Use a new
    `tmp/zig_ir/<sweep-name>` directory; do not reuse an interrupted output
    directory.

4.  Run `tools/zig_corpus_discovery.zig` with the command shape above.

5.  After the sweep finishes, inspect the summary and failure rows:

    ```bash
    cat tmp/zig_ir/<sweep-name>/summary.txt
    rg -n '^(parse-fail|verify-fail|optimizer-fail|input-too-large)' \
      tmp/zig_ir/<sweep-name>/report.tsv
    ```

6.  If the sweep is clean, record the clean mode and continue to the next mode.
    If it finds a failure, reduce and fix that blocker before starting another
    broad sweep. If it reveals tooling or verifier throughput trouble, fix and
    commit that first, then restart the interrupted mode in a fresh directory.

When a full source-backed verify sweep has no local failures, keep looking for
blockers by repeating the sweep across Zig optimization modes in this order:

```text
Debug -> ReleaseFast -> ReleaseSafe -> ReleaseSmall
```

If all emitted rows in a mode pass local verification, treat that mode as clean
for parser/verifier discovery and move to the next mode. If a sweep exposes a
tooling or verifier throughput blocker before a semantic failure, close that
blocker first, commit the reviewed fix, then rerun the interrupted sweep from a
fresh output directory.

After verify discovery is clean in all four modes, start optimizer discovery
with the accepted corpus pipelines:

```text
Debug -> zig-debug-accepted
ReleaseFast -> zig-release-fast-accepted
ReleaseSafe -> zig-release-safe-accepted
ReleaseSmall -> zig-release-small-accepted
```

Optimizer sweeps use the same compiler split and output-directory rules, but
must pass the accepted pipeline explicitly. Do not rely on `--pass-limit=0` for
optimizer discovery; that shortcut is only for default verify-only sweeps. The
usual optimizer command shape is:

```bash
zig build -Doptimize=ReleaseFast

zig run tools/zig_corpus_discovery.zig -- \
  --out-dir=tmp/zig_ir/<optimizer-sweep-name> \
  --mode=<Debug|ReleaseFast|ReleaseSafe|ReleaseSmall> \
  --passes=<zig-*-accepted> \
  --local-input-limit=67108864 \
  --local-zllvm-exe=zig-out/bin/z_llvm \
  --progress-every=50
```

Add `--capture-optimized-output` when a cycle needs canonical-form evidence for
handoff triage. The discovery report then includes `optimized_ir_path`, and the
normalized local optimized output is written under
`tmp/zig_ir/<sweep-name>/optimized-ir/`. A captured output directory is a
baseline unless it is compared against an earlier captured optimized-output
directory; ordinary quiet reports prove pass/fail status only.

If an optimizer sweep fails, classify the first row as pass behavior,
transform-legality, or post-transform verifier failure. Reduce and fix that
blocker before continuing broad optimizer sweeps. If the accepted pipeline is
deliberately conservative compared with LLVM, document the local boundary and
compare only the cases where upstream parity is expected.

## Required Upstream Mapping

Each pass, analysis, IR feature, or codegen feature must document:

```text
LLVM source files
LLVM classes/functions used as reference entry points
reproduced behavior
known missing behavior
test fixtures or opt commands used for comparison
Zig distribution path or fallback boundary affected
```

The mapping belongs in the relevant document:

```text
docs/passes/<pass>.md
docs/analysis/<analysis>.md
docs/ir.md
docs/codegen.md
```

If the upstream mapping is incomplete, the implementation can land only if the doc explicitly says what still needs to be checked.

## LLVM-Shaped Fix Rule

When a bug or missing feature corresponds to LLVM behavior, the fix must
implement the LLVM-shaped behavior for the selected slice, not a conservative
stub that merely avoids the failing case.

Before editing code, identify the LLVM source entry point and the accepted IR
preconditions for the slice. The implementation should reproduce that behavior
for the local supported IR surface, with fixtures that compare against LLVM
when LLVM accepts the input.

A conservative result is allowed only when it is the actual LLVM-compatible
boundary for the current IR surface, or when LLVM needs infrastructure this
project does not yet have. In that case, the code, fixture classification, and
docs must say so explicitly:

```text
local-conservative: reason, missing infrastructure, and upstream behavior
```

Do not land placeholder behavior as a completed fix. If the LLVM-shaped slice
is too large for one cycle, reduce the selected slice until it can be
implemented with upstream mapping, focused fixtures, known unsupported behavior,
and a reviewable diff.

## Step Completion Rule

A checkbox in `docs/next_steps.md` can be marked complete only after:

1.  the implementation is done;
2.  tests or fixtures are added;
3.  the relevant upstream LLVM mapping is documented;
4.  the known unsupported behavior is documented;
5.  the affected Zig distribution mode, target, or fallback boundary is
    recorded;
6.  the step is committed separately using the commit policy.

Each commit should close exactly one promoted slice or one prerequisite
tooling/doc fix. If one discovery session reveals multiple independent fixes,
split them into separate commits.

If a step improves local quality but does not remove or reduce an LLVM fallback,
the completion note must say that explicitly and point to the source-backed
reason for doing it anyway.

Each completed slice should leave a short completion note in the relevant doc
or checklist stating one of:

```text
LLVM fallback reduced:
evidence added only:
local conservative boundary closed:
out of scope for current x86_64 milestone:
```

## Discovery Fix Review Loop

Source-backed blocker work follows this cycle:

```text
discover -> fix -> review -> commit
```

The discovery step writes one selected bug packet. The fix step implements only
that packet and writes a fix report. The review step independently checks the
bug packet, fix report, code, fixtures, and focused reproduction.

If review is positive, commit the reviewed code and any tracked docs before
starting the next blocker. If review is rejected, do not commit the fix; return
the finding to the fixer or create the next bug packet from the finding.

For the three-role version of this workflow, use
[three_agent_bug_discovery_fix_review_scheme.md](three_agent_bug_discovery_fix_review_scheme.md).
