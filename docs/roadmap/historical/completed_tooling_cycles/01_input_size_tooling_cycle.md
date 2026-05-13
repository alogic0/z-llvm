# Cycle 01: Input Size Tooling

## Goal

Resolve the remaining `input-too-large` discovery bucket as tooling policy, not
as parser, verifier, or optimizer work.

The latest full discovery sweep produced no parse, verify, or optimizer
failures under the current CLI input limit:

- processed: 1474 / 1474
- emitted IR: 465
- local verify OK: 343
- input-too-large: 122
- parse-fail: 0
- verify-fail: 0
- optimizer-fail: 0

## Scope

- [x] Add an explicit local IR input-size limit option to `z_llvm`.
- [x] Add the same explicit limit option to the normalizer CLI if it shares the
      same read cap.
- [x] Add a discovery-harness option that forwards the local input limit to the
      local `z_llvm` check.
- [x] Add discovery-harness controls for the local check executable/build mode
      so large accepted rows can run through an optimized `z_llvm` instead of
      an unoptimized `zig build run`.
- [x] Make local trace output opt-in for focused debugging rather than the
      default full-sweep path.
- [x] Keep the default limit conservative unless the caller opts into a larger
      corpus sweep.
- [x] Document the exact command for rerunning the 122 `input-too-large` rows
      with a larger limit.
- [x] Reclassify any failures exposed after the larger-limit sweep into normal
      bug packets.

## Rerun Command

Use a fresh output directory so the previous sweep remains available:

```bash
zig run tools/zig_corpus_discovery.zig -- \
  --out-dir=tmp/zig_ir/large_input_discovery_01 \
  --source-report=tmp/zig_ir/agent_discovery_01/report.tsv \
  --source-status=input-too-large \
  --local-input-limit=67108864 \
  --progress-every=25
```

If the run is meant to reproduce the exact current source-backed baseline, keep
the default `--zig-source-dir=../ziglang`, `--mode=ReleaseFast`,
`--target=x86_64-linux-gnu`, and `--passes=verify`.

## Current Probe Result

The first previous `input-too-large` row was:

```text
c_abi/main.zig
tmp/zig_ir/agent_discovery_01/ir/c_abi_main.zig.ReleaseFast.x86_64.ll
```

Default limit behavior:

```bash
zig build run -- --passes=verify \
  tmp/zig_ir/agent_discovery_01/ir/c_abi_main.zig.ReleaseFast.x86_64.ll
```

Result: `StreamTooLong`.

Large-limit behavior:

```bash
zig build run -- --input-limit=67108864 --passes=verify \
  tmp/zig_ir/agent_discovery_01/ir/c_abi_main.zig.ReleaseFast.x86_64.ll
```

Original result before Cycle 08: `UnsupportedGlobalVariable`.

That means the tooling cycle successfully converts the row from a size-policy
bucket into a normal source-backed parser blocker. The parser blocker should be
handled by a separate `discover -> fix -> review -> commit` bug packet after the
larger-limit sweep confirms the full set of exposed root causes.

Cycle 08 fixed that first parser blocker by preserving semicolons inside quoted
LLVM C string literals. The same row now progresses to the next parser blocker:
`UnsupportedType`.

Filtered discovery replay probe:

```bash
zig run tools/zig_corpus_discovery.zig -- \
  --out-dir=tmp/zig_ir/large_input_probe \
  --source-report=tmp/zig_ir/agent_discovery_01/report.tsv \
  --source-status=input-too-large \
  --local-input-limit=67108864 \
  --max=1 \
  --progress-every=1
```

Result:

```text
processed=1/122
input-too-large=0
parse-fail=1
```

Later full-sweep status after parser fixes:

```text
ReleaseFast full sweep:
processed=1474/1474
emit-ok=465
local-ok=465
input-too-large=0
parse-fail=0
verify-fail=0
optimizer-fail=0
```

ReleaseSafe exposed one source-backed parser blocker in
`standalone/windows_bat_args/test.zig`; that blocker was fixed by making switch
case-list close detection quote-aware. A follow-up full ReleaseSafe sweep showed
no correctness failures through `1275/1474`, then exposed a tooling throughput
problem: the default local check path used unoptimized `zig build run --trace`,
causing `standalone/coff_dwarf/main.zig` to consume more than 19 minutes of CPU.

The discovery harness now supports:

```bash
zig build -Doptimize=ReleaseFast
zig run tools/zig_corpus_discovery.zig -- \
  --out-dir=tmp/zig_ir/release_safe_fast_local \
  --mode=ReleaseSafe \
  --local-input-limit=67108864 \
  --local-zllvm-exe=zig-out/bin/z_llvm \
  --progress-every=25
```

Focused smoke result for `../ziglang/test/standalone/coff_dwarf` with the
prebuilt ReleaseFast local verifier:

```text
processed=2/2
emit-ok=2
local-ok=2
input-too-large=0
parse-fail=0
verify-fail=0
optimizer-fail=0
```

Full ReleaseSafe sweep after the tooling fix:

```text
out-dir=tmp/zig_ir/full_discovery_17_release_safe_fast_local
processed=1474/1474
compile-skip=1009
emit-ok=465
local-ok=465
input-too-large=0
parse-fail=0
verify-fail=0
optimizer-fail=0
```

## Non-Goals

- Do not broaden LLVM IR parsing or verification in this tooling cycle.
- Do not treat large input acceptance as optimizer parity.
- Do not remove memory limits entirely for default user-facing commands.

## Acceptance Checks

- [x] `zig build test`
- [x] `zig build`
- [x] `git diff --check`
- [x] `zig build run -- --input-limit=<N> --passes=verify <large.ll>` works
      for a previously `input-too-large` corpus row, or produces a real
      parser/verifier failure that can become a bug packet.
- [x] Filtered discovery replay can select the previous `input-too-large`
      bucket from `tmp/zig_ir/agent_discovery_01/report.tsv`.
- [x] `zig run tools/zig_corpus_discovery.zig -- --local-input-limit=<N> ...`
      records fewer `input-too-large` rows, ideally zero.
- [x] Large local-check smoke can use a prebuilt ReleaseFast `z_llvm` through
      `--local-zllvm-exe=zig-out/bin/z_llvm`.
