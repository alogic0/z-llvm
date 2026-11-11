# Private integer shift operands

An otherwise unsupported 32/64-bit shift with a literal left operand and a
named count can materialize the literal through the existing full-word identity
operation. The ordinary typed named-shift action then owns emission, count
placement and preservation. The private view retains the original opcode,
flags, count, result name and ABI. The immutable source and mandatory semantic
normalization contracts remain unchanged. Established original forms retain
their existing transactional retry.

The pair arithmetic view also expands constant logical right shifts below
64 through its existing scalar-word shift builder. A plain `lshr i128 ..., 64`
remains the primitive high-word projection used by split/finish; known expanded
words can still discharge that projection directly. The existing `shl ..., 64`
constructor remains primitive. Fixed-point checks cover zero, both sides of the
word boundary and the largest defined counts, including temporary-name clashes.

The 36-function `integer_shift_operands` population contains:

- Twenty-four scalar functions: both widths, all three shift operations, signed
  and unsigned spellings, full-width bit patterns, live counts and eight live
  register/stack inputs. Every defined count is executed.
- Eleven pair functions: ten constant counts and every defined named count,
  nonzero upper words, unaligned guarded stores, and pair values preserved
  across a helper that clobbers all caller-saved general registers.
- A digest-shaped function retaining every body instruction from the original
  SipHash fixture, with a C entry name/convention. An independent C round model
  checks both output words, all 56 state bytes, every tail length, byte-count
  wrapping and protected-page boundaries.

Each execution checks 22,536 observations. The four driver faults exercise the
literal result, pair result, destination guard and unchanged digest state.
The retained standalone original fixture reproduces its earlier shift rejection;
the smaller projections already passed and receive no before/after failure claim.

## LLVM 22 mapping

`llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp` builds
typed shift operands through ordinary values. Integer legalization in
`llvm/lib/CodeGen/SelectionDAG/LegalizeIntegerTypes.cpp` separates expanded
integer words and joins cross-word shift bits. These private views reuse the
existing scalar and pair authorities and preserve defined shift semantics.

Native execution proves these operand and preservation cases. Complete original
census and independent production remain necessary to accept compiler coverage;
complete objects, startup and self-rebuild are separate results.
