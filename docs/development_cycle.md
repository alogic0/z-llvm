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

For corpus discovery, keep the same split:

- stage4 Zig emits authoritative LLVM IR through `--zig-exe` or the default
  `../ziglang/build/stage4/bin/zig`;
- local checks build and run `z_llvm` with `zig` on `PATH` in ReleaseFast mode
  by default;
- use `--local-zllvm-exe=zig-out/bin/z_llvm` after an explicit
  `zig build -Doptimize=ReleaseFast` when repeating large sweeps;
- use `--local-trace` only for focused debugging, not full discovery sweeps.

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
