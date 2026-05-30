# instcombine

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/InstCombine/
```

Upstream entry points to check:

```text
InstCombinePass::run
InstructionCombiningPass
InstCombinerImpl::canonicalizeOperands
InstCombinerImpl::visitAdd
InstCombinerImpl::visitSub
InstCombinerImpl::visitMul
InstCombinerImpl::visitAnd
InstCombinerImpl::visitOr
InstCombinerImpl::visitXor
InstCombinerImpl::visitShl
InstCombinerImpl::visitLShr
InstCombinerImpl::visitAShr
InstCombinerImpl::visitUDiv
InstCombinerImpl::visitSDiv
InstCombinerImpl::visitURem
InstCombinerImpl::visitSRem
InstCombinerImpl::visitTrunc
InstCombinerImpl::visitZExt
InstCombinerImpl::visitSExt
InstCombinerImpl::visitICmpInst
InstCombinerImpl::visitSelectInst
InstCombinerImpl::foldOpIntoPhi
InstCombinerImpl::simplifyDemandedInstructionBits
InstructionSimplify helpers used by InstCombine
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/InstCombine/
  llvm-project-22/llvm/lib/Transforms/AggressiveInstCombine/
  llvm-project-22/llvm/lib/Analysis/InstructionSimplify.cpp

LLVM entry points/classes:
  InstCombinePass::run
  InstCombinerImpl::run
  InstCombinerImpl::canonicalizeOperands
  AggressiveInstCombinePass

Required analyses:
  None for the implemented local subset.

Required IR invariants:
  Verified scalar integer IR with valid SSA dominance and PHI structure.

Core LLVM algorithm data structures:
  Worklist-style instruction combining
  InstructionSimplify query helpers
  Operand canonicalization for commutative instructions
  Conservative poison/undef/freeze refusal rules

Local target status:
  fixture-equivalent for listed fixtures

Implemented subset:
  Local instruction scan with alias replacement
  Arithmetic, bitwise, shift, cast, ICmp, select, div/rem, and freeze-constant
  scalar simplifications delegated to the InstSimplify helper
  Checked `nuw`/`nsw`/`exact` identity folds and APInt-shaped add/sub/mul/shift
  constant folds for the listed integer fixtures
  Checked `nuw`/`nsw`/`exact` zero-result folds for multiply and shifts when
  the result is independent of the poison-generating flag
  Same-constant-lane extract-after-insert vector lane fold
  Target-independent identical-arm vector-valued select fold with scalar `i1`
  condition
  Constant-on-RHS canonicalization for supported commutative binary ops

Intentional divergences:
  The local pass is a linear scan, not LLVM's full fixed-point worklist.
  Selected mode pipelines repeat InstCombine and SimplifyCFG to model the
  repeated canonicalization shape used by LLVM.
  AggressiveInstCombine is an explicit placeholder until concrete rules are
  implemented.

Analysis preservation/invalidation:
  InstCombine mutates IR and invalidates analyses under the local pass-manager
  policy. The pass manager verifies after execution.

Fixture coverage:
  instcombine
  instcombine_bitwise
  instcombine_icmp_rel
  instcombine_commute
  instcombine_scalar_simplify
  instcombine_safe_scalar
  instcombine_flagged_identities
  instcombine_flagged_constants
  instcombine_flagged_zero_results
  instcombine_flagged_overflow_reject folds an overflowing `nsw` integer
  constant expression to the APInt-wrapped constant like `opt-22`.
  instcombine_flagged_shl_constants folds in-range flagged constant left shifts
  to APInt-wrapped constants like `opt-22`.
  instcombine_shift_constants folds in-range `lshr` and `ashr` constants,
  including `exact` spellings, to APInt-wrapped constants like `opt-22`.
  instcombine_shift_oversized_poison folds constant shifts with counts outside
  the type bit width to `poison` like `opt-22`.
  instcombine_pointer_compare
  vector_extract_insert_fold
  vector_extract_insert_mismatch_reject rewrites extract-after-insert to
  extract from the original vector when constant lanes differ.
  vector_select_same_arms
  select_fold
  fp_instcombine_preserve
  fp_special_literals_preserve
  fp_extended_instcombine_preserve
  fp_fast_math_preserve
  fp_strict_sensitive_preserve
  fp_strict_sensitive_preserve is local-conservative after Cycle 05: LLVM folds
  some strict identities such as `fsub x, 0.0`, `fmul x, 1.0`, `fdiv x, 1.0`,
  and rewrites self-compare to orderedness, but the local implementation keeps
  them until the exact LLVM legality proof is reproduced.
  fp_strict_arith_constants
  fp_strict_fcmp_fold
  fp_strict_fcmp_constants
  fp_strict_orderedness_fold is local-conservative: the local APFloat-shaped
  classifier folds only ord/uno constant orderedness and avoids general FP
  comparison arithmetic.
  fp_fast_math_flags_boundary
  fp_fast_math_sensitive_conservative is local-conservative: LLVM may fold
  fast-math-sensitive identities after proving flag semantics, but the local
  optimizer preserves them until the FP legality model exists.

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
```

This pass canonicalizes and folds simple instructions. The first Zig implementation is intentionally small and covers only enough behavior to prove the pass infrastructure and LLVM-compatible IR comparison loop.

Implemented subset:

```text
x + 0 -> x
0 + x -> x
commutative binary constants on the LHS are swapped to the RHS
x - 0 -> x
x * 1 -> x
1 * x -> x
x * 0 -> 0
0 * x -> 0
integer constant folding for add/sub/mul
integer constant folding for and/or/xor
x & 0 -> 0
x & -1 -> x
x & x -> x
x | 0 -> x
x | x -> x
x ^ 0 -> x
x ^ x -> 0
x << 0 -> x
x >> 0 -> x for logical and arithmetic shift
0 << x -> 0
0 >> x -> 0 for logical and arithmetic shift
icmp eq/ne constant folding
icmp eq/ne same-operand folding
icmp signed and unsigned relational constant folding
icmp signed and unsigned relational same-operand folding
select constant-condition folding
select identical-arm folding
select identical-vector-arm folding for scalar `i1` conditions
fold selected `nsw`, `nuw`, and `exact` neutral identities when the flag cannot
change overflow behavior
fold selected `nsw`, `nuw`, and `exact` zero-result identities when the zero
operand makes the result independent of overflow or exactness
fold selected flagged integer add/sub/mul and in-range shift constants to the
APInt-wrapped result
fold constant shifts with counts outside the type bit width to `poison`
constant `trunc`, `zext`, and `sext` folding for integer constants
defined constant `udiv`, `sdiv`, `urem`, and `srem` folding
safe variable div/rem identities: x / 1 -> x and x % 1 -> 0
pointer null/self ICmp folds through same-operand comparison simplification
extractelement (insertelement V, X, C), C -> X for fixed vectors and constant C
freeze of an integer constant -> that same constant
strict `fcmp false` -> false
strict `fcmp true` -> true
strict scalar `float`/`double` literal `fcmp` predicates fold for finite values
and NaN ordered/unordered behavior
strict scalar `float`/`double` literal `fadd` and `fmul` fold for selected
positive-zero and one identities when the result reuses an existing literal
spelling
strict `fcmp ord` and `fcmp uno` for classified scalar FP constants
`fadd nsz x, +0.0` -> x
`fcmp nnan oeq x, x` -> true
preserve `freeze` instructions
```

Upstream mapping:

```text
This reproduces a small identity-folding and constant-folding subset of InstCombine.
LLVM's InstCombine is much broader: flags, poison semantics, canonicalization, reassociation, casts, vectors, division/remainder transforms, and target-specific combines all matter upstream.
The current implementation uses `nsw`, `nuw`, and `exact` only for explicitly
listed neutral identities, zero-result identities, and selected APInt-shaped
constant folds.
Floating-point `fadd`, `fsub`, `fmul`, `fdiv`, and `frem` are preserved rather
than folded because NaN, signed-zero, rounding, and exception legality are not
modeled. `fcmp false`/`true` and constant `ord`/`uno` orderedness folds are the
first enabled strict FP literal comparison folds use APFloat-shaped
ordered/unordered semantics for scalar `float` and `double` constants. Strict
`fadd` and `fmul` constant folds are limited to identities where the result can
reuse one operand spelling until a full APFloat result printer exists. Parsed
fast-math flags are interpreted only through `docs/analysis/fast_math.md`; the
first enabled fast-math folds are `fadd nsz x, +0.0` and `fcmp nnan oeq x, x`.
Common local folds now live in [inst_simplify.md](inst_simplify.md) so GVN and EarlyCSE can share scalar expression equivalence with InstCombine.
Debug-location-only folds may remove an instruction carrying `!dbg`; the
local pass now transfers that location to the first later metadata-free user of
the replaced value. This is a narrow debug-location salvage slice, not full
LLVM `salvageDebugInfo` or variable-location rewriting.
```

Example:

```text
before:
  %x = add i32 %a, 0
  %y = mul i32 %x, 1
  ret i32 %y

after instcombine + dce:
  ret i32 %a
```

Known gaps:

```text
no general use of nsw/nuw/exact for folds beyond the listed neutral and
zero-result identities and APInt-shaped constants
no general strict FP result-producing arithmetic folds yet; `fadd 1.0, 2.0`
and similar cases need an APFloat-compatible result spelling before they can be
made opt-equivalent
no materialized poison/undef simplification beyond oversized constant shifts
no non-constant freeze simplification
no vector folds beyond same-constant-lane extract-after-insert; vectorizers and
target-cost-sensitive vector combines remain placeholders
non-constant and demanded-bits-driven shift simplification remains unsupported
no demanded-bits cleanup in InstCombine; the first source-backed integer mask
quality case is implemented in the separate `bdce` pass
unsigned constant folding is limited to integer widths below 128 bits
no non-constant cast simplification yet
no unsafe division/remainder simplification
no canonical reassociation
no non-constant operand complexity ordering
no floating-point arithmetic folds or reassociation
no general ordered FP comparison folds
no fast-math-driven FP folds beyond the listed nsz/nnan identities
no debug-info salvage beyond one removed-instruction `!dbg` transfer to a
metadata-free user; no variable-location salvage
no target-specific combines
```
