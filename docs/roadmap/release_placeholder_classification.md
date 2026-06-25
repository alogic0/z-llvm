# Release Placeholder Classification

This inventory classifies the active non-LTO `release-o3` and `release-oz`
formerly-placeholder surfaces by their relevance to the x86_64 release
replacement goal. The accepted Zig release gates still use the reduced local
pipelines; this table prevents the full upstream release descriptors from
looking more complete than they are.

Evidence source: current source-backed manifests and real-AIR/frontier docs only
tag these passes through release pipeline descriptors. No accepted
x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall row supplies forced-attribute policy
or duplicate-identical-function size evidence for `mergefunc`; debug/profile
discriminators and annotation remarks are not consumed by object/codegen,
native-link, or executable proof rows.

## Active Placeholder Table

| Pass | Upstream path | Pipelines | Expected upstream effect | Current local status | Classification |
| --- | --- | --- | --- | --- | --- |
| `add-discriminators` | `llvm/lib/Transforms/Utils/AddDiscriminators.cpp` | `release-o3`, `release-oz` | Debug/profile discriminator metadata. | Out-of-scope registry entry. | Out-of-scope for x86_64 release object/codegen rows. |
| `forceattrs` | `llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp` | `release-o3`, `release-oz` | Apply externally configured forced function attributes. | Boundary-noop registry entry. | Boundary-noop until a release row supplies forced-attribute policy. |
| `inferattrs` | `llvm/lib/Transforms/IPO/InferFunctionAttrs.cpp` | `release-o3`, `release-oz` | Infer function memory/effect attributes. | Conservative wrapper over the local direct-call `function-attrs` subset. | Subset. |
| `aggressive-instcombine` | `llvm/lib/Transforms/AggressiveInstCombine/` | `release-o3`, `release-oz` | Larger scalar canonicalization patterns. | Conservative wrapper over the local `instcombine` subset. | Subset. |
| `lower-constant-intrinsics` | `llvm/lib/Transforms/Scalar/LowerConstantIntrinsics.cpp` | `release-o3`, `release-oz` | Lower constant-foldable intrinsic calls. | Conservative integer min/max intrinsic subset for observed Zig shapes. | Subset. |
| `mergefunc` | `llvm/lib/Transforms/IPO/MergeFunctions.cpp` | `release-o3`, `release-oz` | Merge identical functions for code size. | Boundary-noop registry entry. | Boundary-noop for current executable/codegen rows; ReleaseSmall size parity remains future work. |
| `annotation-remarks` | `llvm/lib/Transforms/Scalar/AnnotationRemarks.cpp` | `release-o3`, `release-oz` | Emit optimization remarks for annotations. | Out-of-scope registry entry. | Out-of-scope diagnostics surface. |

## Implementation Order

The first conservative subsets are intentionally narrow:

1. `inferattrs`: existing source-backed rows already exercise release attribute
   inference through `function-attrs`, so `inferattrs` now delegates to that
   audited direct-call subset instead of staying a no-op.
2. `aggressive-instcombine`: the current scalar canonicalization evidence is
   already owned by local InstCombine. The release descriptor now uses that
   bounded implementation rather than implying full AggressiveInstCombine
   parity.
3. `lower-constant-intrinsics`: current integer fixtures include
   `llvm.smin.*`/`llvm.umax.*` style shapes. The local subset only lowers
   same-operand and constant min/max calls already supported by
   `inst_simplify`.

No ambiguous placeholders remain in `release-o3` or `release-oz`. The remaining
non-transforming entries are explicit `boundary-noop` or `out-of-scope` registry
entries and are counted separately by `zig build release-pipeline-policy`.
`mergefunc` remains future ReleaseSmall size-parity work until source-backed
evidence shows duplicate identical functions whose merging affects accepted
size evidence.
