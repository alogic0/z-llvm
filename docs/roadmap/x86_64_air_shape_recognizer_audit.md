# x86_64 Broad Real-AIR Shape Recognizer Audit

Current measured gates:

```text
zig build distribution-zig-air-uncurated-releasefast-broad
zig build distribution-zig-air-uncurated-releasesafe-broad
```

Both modes currently report:

```text
structured_functions=152
structured_air_v1_functions=152
structured_air_v2_functions=152
typed_air_type_functions=152
typed_air_operand_functions=0
legacy_air_text_lowering_functions=152
generic_lowering_functions=120
shape_recognizer_functions=32
unsupported_functions=0
codegen_failures=0
```

`structured_air-v1` is present for every accepted function and carries
instruction tags plus body/branch metadata. `structured_air-v2` is also present
for every accepted function after the contract bump; it currently carries
instruction result records and structural operand refs. Operand type authority
is still not enabled (`typed_air_operand_functions=0`) because the first safe v2
transport avoids AIR type queries that crash on control-flow/runtime-boundary
refs. z_llvm still uses legacy AIR text for lowering authority, so
`legacy_air_text_lowering_functions=152` remains expected until typed operands
and generic v2 lowering land.

The remaining shape recognizer families in `src/zig_air_lowering.zig` are:

- accumulator loop
- integer switch block
- conditional slot update
- array sum
- struct sum
- base64 table lookup
- runtime optional pointer main
- optional pointer
- runtime pointer load/store main
- optional payload
- error switch and classifier
- error-union payload
- slice sum
- packed read flag
- packed replace low
- aggregate pair first/make pair
- mixed C/Zig add-may-panic
- maybe-error helper
- inline asm barrier

Next typed-contract target:

- extend `structured_air-v2` from structural operand refs to typed operand
  records without crashing stage4
- convert control-flow, optional/error-union, pointer/slice/array, aggregate,
  and packed-field lowering from recognizer families to generic typed AIR
  lowering
- drive `legacy_air_text_lowering_functions` and
  `shape_recognizer_functions` down as v2 coverage lands
