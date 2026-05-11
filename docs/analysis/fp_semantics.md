# Floating-Point Semantics

This analysis is the local APFloat-shaped boundary. It classifies accepted
floating-point literal spellings before any optimizer is allowed to fold FP
operations.

## LLVM Mapping

LLVM uses `APFloat` for semantic floating-point values, including signed zero,
NaN, infinity, normal values, subnormals, and target-specific semantics. The
local implementation in `src/analysis/fp_semantics.zig` is intentionally
smaller:

```text
zero
negative_zero
nan
infinity
normal
subnormal for known hex boundary spellings
```

The parser still preserves the original textual spelling in IR values. The
classifier is used by the verifier and future legality helpers; it does not
enable arithmetic folding by itself.

## Fixture Coverage

```text
fp_literal_preserve: ordinary decimal literals remain preserved
fp_special_literals_preserve: nan, inf, and negative zero are classified and
preserved without folding
```

## Gaps

```text
no APFloat arithmetic
no target rounding modes
no exception behavior
no signaling-vs-quiet NaN distinction
no complete hex bit-pattern decoding
no FP transform legality beyond classification
```

