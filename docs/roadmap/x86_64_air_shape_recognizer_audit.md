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
legacy_air_text_lowering_functions=33
typed_v2_fallback_functions=33
generic_lowering_functions=121
shape_recognizer_functions=31
unsupported_functions=0
codegen_failures=0
top_typed_v2_fallback_reason=shape_recognizer:aggregate_make_pair:-
top_typed_v2_fallback_count=2
```

`structured_air-v1` is present for every accepted function and carries
instruction tags plus body/branch metadata. `structured_air-v2` is also present
for every accepted function after the contract bump; it currently carries
instruction result records, typed value operands, typed control targets, typed
sentinel operands, operand text details, and call signature records. z_llvm now
lowers the straight-line scalar, load/store, global pointer constants,
stack-slot, direct-call, runtime symbol pointer, and simple block-result diamond
select subset from typed v2 records, using `structured_air-v1` body topology
only where block structure is still required. `legacy_air_text_lowering_functions=33` remains for families
that still need generic typed control-flow, aggregate, pointer/slice,
optional/error-union, runtime-boundary, and packed-field lowering.

The broad gates now emit one `typed-v2-fallback` diagnostic per accepted
function that still falls back to legacy AIR text. The summary records the first
fallback function/opcode/data kind/reason and the top fallback bucket. Generic
typed-v2 validation failures now report the concrete failing typed opcode and
data kind instead of a synthetic `typed_v2` bucket; the current top bucket is
`shape_recognizer:aggregate_make_pair:-` with 2 functions.

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
