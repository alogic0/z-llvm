# INBOX-59 Cache Inventory

observation: 2026-07-15T04:40:00-05:00 (`1784108400`)
baseline: `a3f39035`
accepted_report: 443 selected / 285 emitting / 158 failing
filesystem: `/dev/nvme0n1p2` (`ext4`, mounted at `/`)
mode: read-only inventory and report-only reporter

## Inventory

| Cache class | Exact path | Real bytes | Apparent bytes | Scope and owner | Selection | Active use | Disposition |
| --- | --- | ---: | ---: | --- | --- | --- | --- |
| Per-INBOX/per-run temporary artifacts | `/home/oleg/prog/z_llvm/tmp`, excluding `real_rows_air_export_cache` | 5,166,628,864 | 5,216,386,821 | Project-dedicated; many accepted INBOX and focused-run owners | Explicit per-command cache/install/output paths under repo `tmp/` | No Zig, z_llvm, distribution, or sharding process was active at observation | Classify by acceptance, grace, two-hour rule, and explicit pins; report only |
| Real-row AIR export cache | `/home/oleg/prog/z_llvm/tmp/real_rows_air_export_cache` | 4,011,126,784 | 4,011,022,348 | Project-dedicated; Zig pin `bdee02bc0c7f227c0f11bc9a449df673fe803540`, exporter `3553582a0269368c84c6bbb3273c28fc307c7edcde0a02096d57f9fdeb1451de` | Distribution real-row exporter cache contract and semantic metadata | No active producer or consumer at observation | Protect one complete pair for each ReleaseFast/Safe/Small; all three present pairs are healthy |
| Patched-Zig build-local cache | `/home/oleg/prog/ziglang/.zig-cache` | 1,894,752,256 | 2,167,907,014 | Project-dedicated to the patched Zig worktree; current HEAD/pin `bdee02bc0c7f227c0f11bc9a449df673fe803540`, branch `experimental-z-llvm-object-hook` | Zig build cwd-local default, confirmed by build command `--cache-dir .zig-cache`; global argument is `/home/oleg/.cache/zig`; no cache env override | No `zig` process and no open file under this cache or `build/stage4` at observation | Protect current opaque generation; prefer future per-pin roots; no entry-level pruning proposed |

The complete repo `tmp/` observation was 9,177,755,648 real bytes and
9,227,409,169 apparent bytes. The two `tmp/` rows above partition that
container for inventory purposes; individual reporter rows use deterministic
logical tree sizes and therefore differ slightly from GNU `du` accounting for
directory blocks.

## Patched-Zig cache location finding

The patched executable is
`/home/oleg/prog/ziglang/build/stage4/bin/zig`, version
`0.17.0-dev.364+bdee02bc0`. The patched worktree HEAD matches the tracked
stage4 pin. `zig env` reports no `ZIG_GLOBAL_CACHE_DIR` or
`ZIG_LOCAL_CACHE_DIR` override. Historical stage4 rebuild command evidence
shows `--cache-dir .zig-cache --global-cache-dir /home/oleg/.cache/zig` while
running in `/home/oleg/prog/ziglang`; this resolves the build-local cache above.
The global directory itself occupied only one filesystem block and is not the
patched build-local cache inventoried here.

The directive's approximate 29 GB Zig-cache observation could not be
corroborated. A root-filesystem name scan found no `.zig-cache`, `zig-cache`,
or Zig global-cache directory near that size; the largest relevant cache was
the 1.89 GB real patched-Zig local cache. The only similarly sized directory
found was `/home/oleg/prog/gen-z-sitter/tmp` at about 30.93 GB. It belongs to a
different project, is not selected by patched Zig, is outside INBOX-59 scope,
and is neither included as reclaimable nor proposed for cleanup.

## Current semantic export pairs

| Mode | Cache key | Pair bytes | Status |
| --- | --- | ---: | --- |
| ReleaseFast | `92de5d7dc23761e92d01694ca13470b6d3c34da543554791dfbe70fd15d6cb61` | 1,373,716,341 | protected |
| ReleaseSafe | `196f53065eb715990b6e24d04afcb875285675e5adb675a6a30bae4de6873192` | 1,501,643,803 | protected |
| ReleaseSmall | `283ed9184522c06666973850c5c3a8158e1743a7076d17962281c70fcf34e8d8` | 1,135,662,204 | protected |

Each pair is complete, uses the current Zig pin and exporter state, and is
listed explicitly in the live-pin manifest.

## Report-only proof

The reporter was compiled directly and run only with `--retention-report`.
The fixture forced
`test/tools/clean_tmp_report_only_fixture/distribution_real_rows_fixture` to
be a cleanup candidate while preserving its sentinel. The reporter emitted:

```text
fixture report-only path=test/tools/clean_tmp_report_only_fixture/distribution_real_rows_fixture/sentinel.bin preserved=true
```

The retained sentinel SHA-256 is
`163050306ad5d7f1dc7490ece2d7f09f2f8faeb09c5c5f52c3709f7ba87c6846`.
No cleanup or gate ran.
