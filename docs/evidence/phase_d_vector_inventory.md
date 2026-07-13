# Phase D Soft-Float Vector Inventory

INBOX-22 is acknowledged by this evidence-contract cycle.

## Baseline

- Plan-adoption commit: `8e6c4e7c`
- Last code commit: `a9f95ddf`
- Accepted report: `tmp/inbox21_tanf_final_report.log`
- Report summary: 443 selected, 190 emitted, 253 failed
- Captured IR: `tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`
- Captured-IR MD5: `b0eda7a6427c3084fdf096a68696f19c`
- Stage4 Zig pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`

This is a read-only inventory. It uses only the accepted report and captured
IR above. No selector, allocator, frame, ABI, machine, or gate input changed,
and no gate was run.

`Observed` below means the diagnostic is present in the accepted report.
`Predicted` means the captured IR exposes a later vector shape after the
reported first failure; it is not an emission or semantic-acceptance claim.
The report has no per-function success line, so functions absent from its
failure rows are described only as `not failed in accepted report`.

## Census

The captured compiler-rt IR contains 31 soft-float functions with explicit
lane operations or vector-bearing signatures/bodies. The six immediate rows
and 23 latent failed rows below partition the 29 failed functions. The two
`rem_pio2` support functions are not failed rows in the accepted report.

| Shape | Width | Unique functions | Operations seen |
| --- | ---: | --- | --- |
| `<2 x double>` | 128 bits | `tan`, `tanf`, `sin`, `sinf`, `cos`, `cosf`, `sincos`, `sincosf`, `log`, `log2`, `log10`, `__exp2h`, `exp2f`, `exp_f128.exp`, `exp_f128.exp2`, `fma`, `__divdc3`, `rem_pio2`, `rem_pio2_large` (19) | `insertelement`, `extractelement`, `shufflevector`, `fadd`, `fsub`, `fmul`, `phi`, `select`, `fcmp`, intrinsic calls, bitcast |
| `<2 x float>` | 64 bits | `__logh`, `__log2h`, `log2f`, `__log10h`, `log10f`, `logf`, `__unordsf2`, `__divsc3`, plus the `__mulsc3` aggregate return (9) | lane insert/extract/shuffle, `fadd`, `fsub`, `fmul`, `fcmp`, `select`, intrinsic calls, bitcast, aggregate load/return |
| `<2 x i1>` | 2 logical bits | `__unordsf2`, `__divdc3`, `__divsc3` (3) | comparison result, lane extraction, vector select condition |
| `<2 x i64>` | 128 bits | `tan`, `__divdc3` (2) | bitcast result and lane extraction |
| `<4 x double>` | 256 bits | `__muldc3` (1) | insert, arbitrary shuffle, `fmul`, extract, `fcmp`, intrinsic call |
| `<4 x float>` | 128 bits | `__mulsc3` (1) | insert, arbitrary shuffle, `fmul`, `fadd`, `fsub`, extract, `fcmp`, intrinsic call |
| `<4 x half>` | 64 bits | `__mulhc3` (1) | insert, arbitrary shuffle, `fmul`, extract, `fcmp`, intrinsic call |
| `<4 x i1>` | 4 logical bits | `__muldc3`, `__mulsc3`, `__mulhc3`, `__multc3` (4) | comparison result and bitcast to `i4` |

Constant `<2 x i32>` and `<4 x i32>` shuffle-mask operands occur throughout
these functions but are control data, not candidate runtime vector locations.
Every captured `insertelement` and `extractelement` index is a constant `i64`;
all captured shuffle masks are constant. No runtime-dependent lane index was
found.

The captured IR also contains `<16 x i8>` loads in memcpy/memmove helpers.
They are outside this soft-float inventory and are not evidence for widening
the Phase D slice.

## Population 1: Immediate Vector Frontiers

Four rows fail directly on a lane instruction. Two more fail on a return type
that contains a vector. The latter are vector/aggregate ABI boundaries, not
candidate packed-arithmetic rows.

| Function | Observed immediate diagnostic | Vector demand at the boundary | Recorded-slice effect |
| --- | --- | --- | --- |
| `compiler_rt.tan.tanf` | `UnsupportedCodegenControlFlow / unsupported_instruction / insertelement` | `<2 x double>` (128): poison lane-0 insert, `<0,0>` splat, full constants, packed `fmul`/`fadd`, lane-0/1 extract | Advances through all vector operations in this body; predicted next unsupported operation is scalar `fdiv`. Does not emit from this slice alone. |
| `compiler_rt.sin.sinf` | `UnsupportedCodegenControlFlow / unsupported_instruction / insertelement` | `<2 x double>` (128): splat plus lane-0/lane-1 packing, packed `fmul`/`fadd`, extracts | Lane-0-only candidate advances the first polynomial fragment, then stops on lane-1 insertion. Revised candidate below advances all vector operations; scalar `fsub` remains predicted. |
| `compiler_rt.sincos.sincosf` | `UnsupportedCodegenControlFlow / unsupported_instruction / insertelement` | `<2 x double>` (128): splat plus lane-0/lane-1 packing, packed `fmul`/`fadd`, extracts | Same result as `sinf`: lane-0-only is partial; revised insertion supports the captured vector forms, after which scalar/memory work remains. |
| `compiler_rt.comparef.__unordsf2` | `UnsupportedCodegenInstruction / unsupported_instruction / insertelement` | `<2 x float>` (64), vector `fabs`, bitcast to `<2 x i32>`, vector integer compare to `<2 x i1>`, two mask-lane extracts | Unchanged. Element type, packed intrinsic, integer-vector bitcast/compare, and mask representation are all excluded. |
| `compiler_rt.divsc3.__divsc3` | `UnsupportedCodegenControlFlow / unsupported_type / unsupported-return-type` | Signature returns `{ <2 x float> }`; body additionally needs `<2 x float>` arithmetic, vector `fabs`/`copysign`, `<2 x i1>` comparisons/selects, arbitrary shuffles, and vector aggregate load/return | Unchanged. This is a vector-containing aggregate ABI plus masks/calls, explicitly outside the candidate. |
| `compiler_rt.mulsc3.__mulsc3` | `UnsupportedCodegenControlFlow / unsupported_type / unsupported-return-type` | Signature returns `{ <2 x float> }`; body uses `<4 x float>` (128), arbitrary four-lane shuffles, packed arithmetic, `<4 x i1>`, vector intrinsic calls, and aggregate load/return | Unchanged. The physical width alone is insufficient; shape, masks, shuffle semantics, calls, and return ABI are excluded. |

Representative `tanf` shape:

```llvm
%v0 = insertelement <2 x double> poison, double %x2, i64 0
%splat = shufflevector <2 x double> %v0, <2 x double> poison,
                       <2 x i32> zeroinitializer
%p0 = fmul <2 x double> %splat, <double C0, double C1>
%p1 = fadd <2 x double> %p0, <double C2, double C3>
%hi = extractelement <2 x double> %p1, i64 1
%lo = extractelement <2 x double> %p1, i64 0
```

Representative second-lane pack used by `sinf` and `sincosf`:

```llvm
%v0 = insertelement <2 x double> poison, double %a, i64 0
%v1 = insertelement <2 x double> %v0, double %b, i64 1
%p = fmul <2 x double> %v1, %coefficients
```

## Population 2: Latent Vector-Bearing Rows

These failed rows contain vector IR but stop on an earlier scalar, frame, ABI,
or extended-format boundary. Their vector frontier is predicted from the
captured body and has not been observed by a refreshed report.

| Functions | Observed first failure | Predicted vector shapes and opcodes | Candidate relationship |
| --- | --- | --- | --- |
| `tan`, `sin`, `sincos`, `cos` | `unsupported_type / alloca` | `<2 x double>` insert/extract, splats, lane packs, packed `fadd`/`fsub`/`fmul`; bodies also contain cross-input or lane-shift shuffles such as `<0,3>` and `<1,poison>`; `tan` also bitcasts to `<2 x i64>` | Partial only after alloca closure. Arbitrary shuffles, packed `fsub`, and integer-vector bitcasts remain blocked. |
| `cosf` | `unsupported_instruction / fsub` | `<2 x double>` splats, lane-0/lane-1 packs, full constants, packed `fmul`/`fadd`, extracts | Revised candidate covers the captured vector portion after scalar `fsub` closes; later scalar/memory/call behavior is not claimed. |
| `__log2h`, `log2`, `log2f` | `unsupported_instruction / fdiv` | `<2 x float>` for half/float rows and `<2 x double>` for `log2`; insert/extract, splats, lane-shift shuffles, packed `fmul`/`fadd`; double body also packs independent lanes | Only the initial `<2 x double>` forms are partial candidates. Float vectors and non-splat shuffles remain blocked. |
| `__log10h`, `log10`, `log10f` | `unsupported_instruction / fdiv` | Same float/double split as `log2`, with packed arithmetic; double body additionally uses cross-input `<0,3>` and lane-shift shuffles | Partial for the double body's simple fragments only; no row-level advance until scalar `fdiv` closes. |
| `__logh`, `log`, `logf` | `log`: `unsupported_instruction / fsub`; half/float: `unsupported_instruction / fdiv` | `<2 x float>` or `<2 x double>` insert/extract/shuffle and packed `fadd`/`fsub`/`fmul` | Partial for simple double fragments. Float vectors, packed `fsub`, and non-splat shuffles are excluded. |
| `__exp2h`, `exp2f` | `unsupported_instruction / fsub` | `<2 x double>` splat, full constants, lane-0/lane-1 pack, packed `fmul`/`fadd`, extracts | Revised candidate covers the captured vector portion after scalar `fsub` closes. |
| `exp_f128.exp`, `exp_f128.exp2` | `unsupported_type / unsupported-return-type` | Scalar `fp128` signatures with internal `<2 x double>` insert/splat, packed `fmul`/`fadd`, extracts | No actionable row advance: fp128 return and scalar fp128 ownership remain prior architectural boundaries. |
| `fma` | `unsupported_instruction / fcmp` | `<2 x double>` lane-0/lane-1 pack, packed `fmul`, `fsub`, `fadd`, extracts | Partial after scalar comparison closure; packed `fsub` remains excluded. |
| `__divdc3` | `unsupported_type / unsupported-return-type` for `{ double, double }` | `<2 x double>` and `<2 x i64>`, vector phi, arbitrary shuffles, packed `fadd`/`fsub`/`fmul`, vector `fabs`/`copysign`, `<2 x i1>` comparisons/selects | Unchanged at the observed aggregate-return boundary; most body requirements exceed the candidate. |
| `__muldc3` | `unsupported_type / unsupported-return-type` for `{ double, double }` | `<4 x double>` (256), arbitrary four-lane shuffles, packed `fmul`, vector `fabs`, `<4 x i1>` compare and bitcast | Unchanged; requires a width/representation beyond one XMM plus mask and intrinsic ownership. |
| `__mulhc3` | `unsupported_type / alloca` | `<4 x half>` (64), arbitrary shuffle, packed `fmul`, vector `fabs`, `<4 x i1>` compare and bitcast | Unchanged; different lane type and mask/intrinsic family. |
| `__multc3` | `unsupported_type / unsupported-param-type` for scalar `fp128` | `<4 x i1>` comparison result bitcast to `i4` | Unchanged; the predicate artifact does not justify vector data support before fp128 parameters. |

Two additional vector-bearing support functions are not failed rows:

| Function | Accepted-report status | Captured vector shape |
| --- | --- | --- |
| `compiler_rt.rem_pio2.rem_pio2` | Not failed in accepted report; no per-function success claim available | Packs two scalars with two constant `<2 x double>` insertions. |
| `compiler_rt.rem_pio2_large.rem_pio2_large` | Not failed in accepted report; no per-function success claim available | Packs two scalars with two constant `<2 x double>` insertions. |

## Population 3: Minimal-Slice Candidates

This population is a predictive overlay, not a third disjoint set.

| Candidate group | Functions | Expected benefit | Still blocked after the slice |
| --- | --- | --- | --- |
| Current `<2 x double>` frontiers | `tanf`, `sinf`, `sincosf` | All three diagnostics advance. With the recorded lane-0-only rule, only `tanf` clears its complete vector demand; with the revision below, all three clear their captured vector operations. | `tanf`: scalar `fdiv` predicted. `sinf`: scalar `fsub` predicted. `sincosf`: scalar/memory/call work, including `fsub`, remains. No emission claim follows from the vector slice alone. |
| Same simple shape behind one scalar blocker | `cosf`, `__exp2h`, `exp2f` | After their current scalar `fsub` blocker closes, the revised candidate covers their `<2 x double>` splat/pack/`fmul`/`fadd`/extract fragments. | Their current report rows do not move during a vector-only cycle because `fsub` remains first. Later scalar, memory, or call requirements remain unproven. |
| Partial `<2 x double>` beneficiaries | `tan`, `sin`, `sincos`, `cos`, `log`, `log2`, `log10`, `fma`, `__divdc3` | Reuses representation, constants, copies, spills, simple splats, `fadd`, `fmul`, and extracts once earlier blockers close. | Non-splat/cross-input shuffles, packed `fsub`, vector phis, masks, integer-vector bitcasts, intrinsic calls, and aggregate ABI stop these rows. |
| Explicitly outside first slice | `__unordsf2`, float/half logarithm rows, `__divsc3`, `__mulsc3`, `__muldc3`, `__mulhc3`, `__multc3`, `exp_f128.exp`, `exp_f128.exp2` | None claimed. | Different element types/widths, vector masks/comparisons, vector calls/returns, aggregate ABI, or fp128 ownership. |

## Candidate-Slice Evaluation

The recorded candidate has the right architectural center:

- one typed `<2 x double>` shape sharing the existing XMM register bank;
- static lane-definedness attached to the SSA value;
- constant masks and fail-closed rejection of unsupported lanes/shuffles;
- packed `fadd`/`fmul`, full constants, copies, lane extraction;
- one logical 16-byte spill/reload using the existing atomic two-unit frame
  allocation, 8-byte alignment, and an unaligned move;
- no vector ABI, calls, phis, comparisons, masks, dynamic indexes, or wider
  shape.

One revision is warranted by the inventory. Replace:

> constant-index `insertelement` into lane 0 from a poison vector

with:

> constant-index `insertelement` into lane 0 or lane 1 of a poison or existing
> `<2 x double>` value, with the result's static defined-lane set equal to the
> source's defined lanes plus the inserted lane.

Reasons:

1. `sinf` and `sincosf` reach lane-1 insertion immediately after the same
   lane-0/splat polynomial form as `tanf`.
2. `cosf`, `__exp2h`, and `exp2f` use the identical two-insertion pack after
   their scalar `fsub` frontier.
3. The adopted design already requires lane-definedness propagation and
   constant-index extraction; lane 1 does not introduce a new representation,
   register class, shuffle family, spill rule, or runtime index.
4. Keeping insertion limited to lane 0 would turn the first slice into a
   `tanf`-specific shape despite a directly shared typed operation being
   present in the captured IR.

The revision does not add arbitrary shuffles. The only admitted shuffle remains
the `<0,0>` splat. Cross-input masks (`<0,3>`), lane shifts
(`<1,poison>`), swaps, and four-lane masks remain precise failures.

The executable microcanary should therefore include both construction paths:
lane-0 insertion followed by `<0,0>` splat, and lane-0 plus lane-1 insertion
with distinct scalar values. It must consume both lanes, overlap live XMM
values, force at least one 16-byte unaligned spill/reload, and compare exact
result bits for the adopted zero, finite, subnormal, infinity, and NaN cases.

## Review Boundary

The inventory confirms that Phase D is an architectural checkpoint. The
recommended first implementation slice is the recorded candidate with the
constant lane-0/lane-1 insertion revision above. It directly advances three
observed rows but is not predicted to make any of them emit by itself; scalar
`fdiv`/`fsub` work follows under the normal scalar phases. All other vector
families remain explicit boundaries.

No vector implementation is authorized or included here. Phase D
architectural review is required before adding vector value locations,
allocation classes, packed instructions, spills, or verifier semantics.
