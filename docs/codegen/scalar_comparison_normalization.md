# Scalar comparison normalization

Scalar integer comparisons retain their source width and `samesign` flag in
the original IR. The selector normalizes a private copy before any lowering
path can observe unrelated upper carrier bits. Narrow operands are masked or
extended to the existing 32-bit or 64-bit comparison form; signed narrow
ordering uses a sign-bit bias where appropriate.

The same normalization applies to `samesign` comparisons. Different-sign
source operands produce poison under the LLVM contract, so the private form
can choose a concrete result for those inputs. For defined same-sign inputs,
it must preserve the exact predicate result. The private comparison clears
`samesign` after establishing its width interpretation. Function signatures,
the original instruction, and the original flag remain unchanged.

An unsigned spelling of an i32 bit pattern also has a signed interpretation.
For example, `2147483648` denotes the same 32 bits as `-2147483648`.
Immediate comparisons use the existing checked i32 bit-pattern conversion
for signed and unsigned predicates. Values outside that conversion's admitted
range still reject without publishing speculative state.

The repaired case truncates `0xdeadbeef00000100` to i8, then compares it with
`icmp samesign ult i8 ..., 100`. Both operands have the same sign and the
truncated value is zero, so the result is true. The preceding binary observed
dirty upper bits and returned false. The repaired compiler and LLVM return true.

Implementation: [comparison forms](../../src/codegen/x86_64/generic_cfg/comparison_forms.zig)
and [comparison actions](../../src/codegen/x86_64/generic_cfg/value_use/actions/control_compare.zig).
The LLVM 22 mapping is the `icmp`/`samesign` contract in
`llvm/docs/LangRef.rst`, retained by hash from `../llvm-project-22/`.

Executable units cover all ten predicates, fourteen widths from i1 to i64,
dirty carriers, and signed/unsigned literal spellings. The native population
covers named and literal operands, guarded sign domains, live values, calls,
and output guards in both routes and all release modes. See the
[accepted checkpoint](../evidence/scalar_comparisons_pointer_freeze.md).
