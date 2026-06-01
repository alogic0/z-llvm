# Build Steps

This file summarizes the project-specific `zig build` steps and what each one
is for. Use `zig build --help` to see the authoritative current list.

## Core Steps

| Step | Purpose |
| --- | --- |
| `zig build` | Build and install the `z_llvm` executable into `zig-out/bin/z_llvm`. |
| `zig build run -- <args>` | Run `z_llvm` with arguments passed after `--`. |
| `zig build test` | Run the unit test suite. Use this for ordinary implementation slices that touch parser, verifier, optimizer, codegen, or shared tool behavior. |

## Validation Gates

| Step | Purpose |
| --- | --- |
| `zig build readiness` | Run the full readiness gate: unit tests, optimizer comparison, manifest linting, Zig corpus validation, handoff validation, and generated scalar differential checks. Use for parser, verifier, pass-manager, manifest, or broad evidence changes. |
| `zig build handoff` | Run optimizer-to-codegen handoff validation and selected x86_64 asm/object smoke checks. Use when optimizer output, codegen handoff, assembly emission, object emission, or selected Debug/O0 handoff behavior changes. |
| `zig build distribution-all` | Run the selected no-LLVM-codegen distribution subset, native-link proof/probe, and conservative boundary gates. Use for release-milestone evidence or matrix status changes. |
| `zig build distribution-no-llvm` | Run the selected no-LLVM-codegen x86_64 subset: ReleaseFast, ReleaseSafe, ReleaseSmall, Debug focused object/executable gates, plus handoff validation. Use when validating the positive selected distribution subset without the extra boundary checks. |
| `zig build distribution-boundary` | Run conservative boundary gates: linker/CRT ownership, ReleaseSmall exclusions, Debug unwind/DWARF boundary, and AArch64 object target boundary. Use when boundary docs or boundary behavior changes. |
| `zig build distribution-native-link` | Run selected native Zig linker handoff proof. This emits local objects with `z_llvm`, compiles C harnesses with `zig cc -c`, links with `zig build-exe -fno-lld`, and runs the executables. Use when proving native-linker compatibility for selected local objects. |
| `zig build probe-native-linker` | Probe selected local objects against Zig native linker acceptance with `zig build-exe -fno-lld`, classifying the first failure by symbol, relocation, section, TLS model, COMDAT, alignment, ABI, or unknown linker compatibility. Use before promoting a native-linker object compatibility slice. |
| `zig build probe-native-linker-broad -- --mode=ReleaseFast\|ReleaseSafe\|ReleaseSmall\|Debug` | Probe broad optimized IR/input directories for link-only acceptance through Zig's native linker. This emits local `.o` files with `z_llvm`, generates safe stubs only for unresolved function symbols, links with `zig build-exe -fno-lld`, and records link-only counts separately from executable ABI proof. |
| `zig build distribution-native-link-releasefast` | Run the ReleaseFast native-link executable proof for the full current executable harness set. |
| `zig build distribution-native-link-releasesafe` | Run the ReleaseSafe native-link executable proof for the full current executable ABI set. |
| `zig build distribution-native-link-releasesmall` | Run the ReleaseSmall native-link executable proof for the full current executable ABI set. |
| `zig build distribution-native-link-debug` | Run only the selected Debug/O0 native-link executable proof. |
| `zig build probe-native-linker-releasefast` | Probe the ReleaseFast native-link object set for the full current executable harness set. |
| `zig build probe-native-linker-releasesafe` | Probe the ReleaseSafe native-link object set for the full current executable ABI set. |
| `zig build probe-native-linker-releasesmall` | Probe the ReleaseSmall native-link object set for the full current executable ABI set. |
| `zig build probe-native-linker-debug` | Probe only the selected Debug/O0 native-link object set. |
| `zig build distribution-musl-object` | Run selected x86_64 musl object subset gates. Use when target, object, ABI, relocation, or musl-specific object behavior changes. |
| `zig build distribution-musl-executable` | Run selected x86_64 musl executable ABI proof gates. Use when object output must be proven through Zig's musl linker/toolchain handoff. |

The executable gates hand local objects to Zig's driver through `zig cc`. They
prove Zig-driver/toolchain handoff, not necessarily native Zig linker use,
because Zig may still select an LLD-backed linker path internally.
`zig build distribution-native-link` is the stricter native-linker-only
execution proof for the selected ABI-stable subset. `zig build
probe-native-linker` is the matching selected acceptance probe. `zig build
probe-native-linker-broad -- --mode=...` is broader link-only evidence: it does
not claim ABI behavior, but it exposes object/linker compatibility problems.
A failure in either native-link probe becomes a local object compatibility task
unless evidence points to Zig-owned runtime/linker behavior.

## Utility Steps

These steps forward arguments after `--`.

| Step | Purpose |
| --- | --- |
| `zig build probe-distribution-objects -- <args>` | Run object-probe automation over an optimized-output directory. Use to produce stable ok/fail/excluded summaries and select the next measured object blocker. |
| `zig build capture-zig-ir -- <args>` | Capture authoritative Zig-emitted LLVM IR from the configured stage4 Zig emitter. Use when refreshing checked Zig source-backed fixtures. |

Examples:

```bash
zig build probe-distribution-objects -- \
  --input-dir=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir \
  --summary=tmp/zig_ir/release_small_object_probe.summary

zig build capture-zig-ir -- test/zig/inputs/tiny_scalar.zig ReleaseFast
```

## Shell Scripts

There are no supported shell compatibility entrypoints. Current usage goes
through `zig build` steps. Archived roadmap documents may still mention old
script commands as historical transcripts; use the build steps above for new
validation runs.
