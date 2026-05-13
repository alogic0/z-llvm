# Development Cycle

Each implementation cycle uses `docs/next_steps.md` as the active checklist.

For every future step that reproduces LLVM behavior, completion requires an upstream mapping before the step is committed.

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

Use these scripts for fixture work:

```bash
scripts/check_zig_stage4_emitter.sh
scripts/capture_zig_ir.sh test/zig/inputs/<group>.zig ReleaseFast
scripts/lint_zig_ir_manifest.sh
```

Readiness checks run manifest linting but do not regenerate fixtures.

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
```

The mapping belongs in the relevant document:

```text
docs/passes/<pass>.md
docs/analysis/<analysis>.md
docs/ir.md
docs/codegen.md
```

If the upstream mapping is incomplete, the implementation can land only if the doc explicitly says what still needs to be checked.

## Step Completion Rule

A checkbox in `docs/next_steps.md` can be marked complete only after:

1.  the implementation is done;
2.  tests or fixtures are added;
3.  the relevant upstream LLVM mapping is documented;
4.  the known unsupported behavior is documented;
5.  the step is committed separately using the commit policy.

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
