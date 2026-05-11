# AArch64 Optimizer-Input Policy

This policy controls when non-host Zig LLVM IR captures can move from
`parse,verify,target-layout,future` to `optimizer-input`.

## Current AArch64 Corpus Shape

The source-backed row is:

```text
docs/fixtures/zig_ir/manifest.tsv:
  integers_release_fast_aarch64

test/zig/captured/integers.ReleaseFast.aarch64.ll:
  target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32"
  target triple = "aarch64-unknown-linux5.10.0-gnu2.31.0"
```

Visible differences from accepted x86_64 rows:

```text
no f80 layout component
i8 and i16 ABI/preferred alignment are explicitly 8:32 and 16:32
native integer widths are n32:64 instead of n8:16:32:64
function pointer ABI marker Fn32 is present
the target triple selects aarch64 rather than x86_64
```

## Promotion Rule

An AArch64 row may become `optimizer-input` only when every pass in its selected
local pipeline is classified for that row as one of:

```text
target-independent for the accepted IR surface
DataLayout-aware with AArch64 fixture coverage
disabled for the row's local-pipeline alias
```

The current `integers_release_fast_aarch64` row stays
`parse,verify,target-layout,future`. It proves parser/verifier/DataLayout
acceptance, but it must not run the broad release pipeline until all selected
passes are audited for AArch64 target facts.

## Current Pass Classification

Target-independent for scalar integer fixtures:

```text
verify
dce for unused side-effect-free scalar instructions
adce for unused side-effect-free scalar instructions
simplifycfg for target-neutral CFG rewrites
instcombine folds that depend only on integer identities and explicit bit widths
sccp integer lattice cases that do not query type allocation size
```

Target/DataLayout-sensitive:

```text
sroa
dse
gvn and early-cse when loads/stores or MemoryLocation are involved
licm when memory, speculation, or target-cost legality is involved
any ABI, codegen, object, or native backend handoff behavior
```

## Fixture Coverage

```text
test/opt/inputs/aarch64_instcombine_target_independent.ll
test/opt/expected/z_llvm/aarch64_instcombine_target_independent.ll
```

The fixture carries the AArch64 target triple and DataLayout but only exercises
target-independent scalar integer InstCombine/DCE behavior. It is compared with
`opt-22`.
