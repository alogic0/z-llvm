# Remaining scalar floating and integer conversions

Ordinary half, float, double and binary128 casts to integer widths one through
128 use standard signed or unsigned 128-bit conversion helpers when the prior
composed form cannot select. Half first widens exactly to binary32. Every
defined source result fits the wider helper result; integer narrowing retains
the requested bits. Narrow results pass through the existing native word
carrier before their final truncation. No out-of-range floating cast acquires
a defined source result from this implementation choice.
Direct i128-to-i52 truncations also pass through the existing clean 64-bit
word action, preserving the original low 52 bits for named and literal inputs.

Integer casts to binary128 extend exactly to a signed or unsigned i128 before
calling the existing standard helper. That helper performs the single required
floating rounding. Literal inputs use the shared exact integer-pair builder.
Canonical helper symbols, including quoted identifiers, cannot outline
themselves into an immediate recursive call.

These rewrites are the final optional stage and try the original composed form
first, preserving existing successful owners and object bytes. Original IR,
result identities and source flags remain immutable. Constrained intrinsics
retain their existing boundaries.
