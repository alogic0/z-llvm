# Profile-Guided And Size Optimization Boundary

This project preserves profile and size-related IR facts, but does not yet use
them for profitability or target-cost decisions.

## ReleaseSmall Boundary

Zig's `ReleaseSmall` LLVM path maps to an Oz-style pipeline. The local project
keeps two separate concepts:

```text
release-oz: inventory descriptor with placeholders for the discovered LLVM Oz pipeline
zig-release-small-accepted: corpus conformance pipeline over accepted stripped IR
```

The accepted ReleaseSmall corpus currently validates parser, verifier, aliases,
raw function attributes, size attributes such as `minsize` and `optsize`,
integer scalar/intrinsic lowering, and conservative scalar FP preservation. It
intentionally uses only implemented passes.

## Preserved Surface

```text
function prefix attributes: minsize, optsize
raw attribute groups containing minsize/optsize
branch profile metadata attachments such as !prof
opaque metadata records such as branch_weights
SimplifyCFG diamond select formation propagates accepted `!prof`
branch-weight metadata from the source branch to the new select
module flag records when present
target-cpu and target-features attribute strings for later target cycles
```

## Placeholder Surface

```text
require<profile-summary>
require<branch-probability>
require<block-frequency>
cg-profile
chr
mergefunc
```

These entries make the LLVM pipeline surface visible. They are no-op
placeholders until profile summaries, BranchProbabilityInfo,
BlockFrequencyInfo, and size-aware profitability rules are represented.

## Non-Goals

```text
no PGO instrumentation insertion
no profile-summary interpretation
no BFI/BPI computation
no general branch probability updates in CFG transforms beyond the
SimplifyCFG diamond-select branch-weight propagation slice
no size-cost model for inlining, loops, vectorization, or codegen
```

## Tests

```text
unit test: size attributes and branch profile metadata round-trip opaquely
opt fixture: simplifycfg_diamond_select_prof
corpus: tiny_scalar_release_small_captured
corpus: integers_release_small, floats_math_release_small, float_compare_release_small
pipeline placeholder test: require<branch-probability> and require<block-frequency>
```
