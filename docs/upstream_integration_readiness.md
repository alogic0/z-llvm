# Upstream Integration Readiness

This document summarizes what the project can currently prove for Zig upstream
discussion and what must remain an external experiment.

## Reproducibility

```text
zig version
OPT_BIN=opt-22 bash scripts/compare_opt.sh
scripts/run_zig_corpus.sh
bash scripts/run_handoff_validation.sh
bash scripts/run_generated_scalar_diff.sh
bash scripts/run_readiness_checks.sh
```

The corpus docs record the Zig compiler version, target triple, optimize mode,
command, and captured IR path for each Zig-emitted fixture.

## Capability Map

| Subsystem | Current capability | Zig boundary |
| --- | --- | --- |
| Parser/printer/verifier | Accepted scalar/control-flow/memory/global/module records with SSA checks | LLVM-compatibility input validation |
| Scalar optimizer | Fixture-equivalent InstCombine, DCE, ADCE, SCCP, EarlyCSE, GVN, BDCE slices | Possible Sema/AIR/native optimizer design input |
| Memory optimizer | Mem2Reg, SROA, DSE, alias/mod-ref, MemoryLocation, conservative MemorySSA slice | LLVM-compatibility legality study; not a Zig stack model |
| Loop optimizer | LoopInfo, simple LCSSA helper, scalar LICM, loop placeholders | AIR/liveness loop optimization study |
| Metadata and mode handling | Debug/profile/module flags, attributes, ReleaseSmall, target features preserved opaquely | Mode and metadata preservation input |
| Backend handoff | Tiny x86_64 Machine IR, asm/object smoke checks | Validation-only, not a backend replacement |
| Differential testing | Generated scalar diff runner plus fail-closed negative generation | Regression infrastructure input |

## External Experiment Boundary

These parts should remain outside Zig upstream until they have stronger proof:

```text
full LLVM IR parser parity
full LLVM pass algorithm parity
target lowering, register allocation, scheduling, and ABI breadth
DWARF/CodeView/unwind emission
TLS lowering and linker integration
PGO, BFI/BPI, TTI, and size-cost decisions
EH pads, inline asm semantics, and full atomic memory model
bitcode writer, LTO, and ThinLTO summary behavior
```

## Upstreamable Design Input

The parts most useful for upstream discussion are:

```text
Zig LLVM dependency inventory and pass-pipeline inventory
source-backed Zig-emitted IR corpus manifest
fixture metadata separating opt-equivalent from local-conservative behavior
MemorySSA/alias legality lessons for avoiding unsafe load CSE/GVN
AIR/liveness handoff matrix separating LLVM facts from Zig-native concepts
readiness check script that reproduces current claims
```

## Next Roadmap Wave

The next wave should be selected from Zig's actual LLVM-removal blockers:

```text
expand the Zig-emitted corpus before adding generic LLVM features
promote generated differential failures into minimized fixtures
replace local-conservative memory cases with path-aware MemorySSA only when needed
advance native-backend handoff only from source-backed Zig fixtures
keep MC/object/debug/LTO work validation-only until upstream needs it
```

## Current Verdict

The project is useful as a structured LLVM-removal experiment and regression
corpus, but it is not an LLVM replacement. Its strongest upstream-facing value
is the inventory, fixture discipline, conservative legality boundaries, and
clear split between LLVM-compatible IR work and Zig-native backend ownership.
