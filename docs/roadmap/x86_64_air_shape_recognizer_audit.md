# x86_64 Broad Real-AIR Shape Recognizer Audit

Current measured gates:

```text
zig build distribution-zig-air-uncurated-releasefast-broad
zig build distribution-zig-air-uncurated-releasesafe-broad
zig build distribution-zig-air-uncurated-releasesmall-broad
```

All three release modes currently report:

```text
structured_functions=152
structured_air_v1_functions=152
structured_air_v2_functions=152
typed_air_type_functions=152
typed_air_operand_functions=152
legacy_air_text_lowering_functions=152
generic_lowering_functions=121
shape_recognizer_functions=31
unsupported_functions=0
codegen_failures=0
```

`structured_air-v1` is present for every accepted function and carries
instruction tags plus body/branch metadata. `structured_air-v2` is also present
for every accepted function after the contract bump; it currently carries
instruction result records, typed value operands, typed control targets, and
typed sentinel operands. z_llvm still uses legacy AIR text for lowering
authority, so `legacy_air_text_lowering_functions=152` remains expected until
generic v2 lowering lands.

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

Next typed-contract target:

- lower directly from typed `structured_air-v2` records instead of legacy AIR
  text
- convert control-flow, optional/error-union, pointer/slice/array, aggregate,
  and packed-field lowering from recognizer families to generic typed AIR
  lowering
- drive `legacy_air_text_lowering_functions` and
  `shape_recognizer_functions` down as v2 coverage lands
