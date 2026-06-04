# Upstream Integration Readiness

This document summarizes what the project can currently prove for Zig upstream
discussion and what must remain an external experiment.

## Reproducibility

```text
zig version
OPT_BIN=opt-22 zig build compare-opt --
zig build zig-corpus
zig build handoff
zig build generated-scalar-diff
zig build distribution-x86_64-selected-zllvm
zig build readiness
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
| Selected distribution replacement gate | `distribution-x86_64-selected-zllvm` proves 136 selected x86_64 release-mode structured-direct IR-writer rows, with 136/136 rows on generic x86_64 lowering, no textual boundary rows, no libLLVM module parse/print, no LLVM optimizer, no LLVM TargetMachine object emission, and Zig native `-fno-lld` linking | Selected release rows only; normal Zig/libLLVM fallback remains when env vars are unset |
| Broad source-backed structured gate | `distribution-x86_64-source-backed-structured` discovers x86_64 release `.ll` fixtures and proves 80 accepted source-backed rows as structured-direct/generic-codegen with 10 explicit skips and no fallback rows | ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 fixture rows only; unsupported fixture classes remain explicitly skipped |
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
bitcode writer, LTO, and ThinLTO summary behavior; Cycle 23 keeps these
deferred unless a concrete bitcode or linker-LTO handoff use case activates
that compatibility track
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
inline asm and atomicrmw IR representation with verifier fail-closed rules
vector lane-operation boundaries plus target-cost policy decisions
broader AArch64 promotion after target-independent scalar cleanup
Debug-mode reduction work for large source-backed Debug rows
path-aware MemorySSA only after a source-backed fixture requires it
```

The evidence behind that ordering is recorded in
`docs/roadmap/source_backed_readiness_audit.md`.

## Current Verdict

The project is useful as a structured LLVM-removal experiment and regression
corpus, but it is not an LLVM replacement. Its strongest upstream-facing value
is the inventory, fixture discipline, conservative legality boundaries, and
clear split between LLVM-compatible IR work and Zig-native backend ownership.
