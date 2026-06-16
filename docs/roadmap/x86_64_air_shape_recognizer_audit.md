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
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=152
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
top_typed_v2_fallback_reason=-
top_typed_v2_fallback_count=0
```

`structured_air-v1` is present for every accepted function and carries
instruction tags plus body/branch metadata. `structured_air-v2` is also present
for every accepted function after the contract bump; it currently carries
instruction result records, typed value operands, typed control targets, typed
sentinel operands, operand text details, and call signature records. z_llvm now
lowers the straight-line scalar, load/store, global pointer constants,
stack-slot, direct-call, runtime symbol pointer, simple block-result diamond
select, struct field-sum, array aggregate-sum, and base64 table-lookup subset from typed v2 records, using
`structured_air-v1` body topology
only where block structure is still required. Aggregate pair first/make-pair now validates typed-v2
aggregate ABI records before lowering to the scalar SysV representation. Error-union payload now
validates typed-v2 error-union branch/payload records before lowering to the selected payload value.
Maybe-error helpers now validate typed-v2 branch/return records before lowering to the selected
error-union scalar representation. Optional scalar-payload helpers now validate typed-v2
wrap/null-check/payload branch records. Optional pointer-payload helpers now validate typed-v2
null-check/payload/load records. Packed read/replace helpers now validate typed-v2
packed field pointer/load/store records before lowering to the scalar bit representation.
Slice-sum helpers now validate typed-v2 pointer-add/slice/len/element/loop records,
including the ReleaseSafe safety-expanded form. Selected monotonic atomic add and
empty inline-asm memory-barrier helpers now lower from typed-v2 records directly.
Accumulator-loop helpers now validate typed-v2 loop/repeat/branch records before lowering to
the phi-based loop IR. Dense-switch and conditional slot-update helpers now validate typed-v2
switch/branch and branch/store/update records before lowering. Error-switch and classifier helpers
now validate typed-v2 error-union switch, branch, payload, and classifier records before lowering
to the scalar error representation. Runtime optional-pointer and pointer load/store wrapper mains
now validate typed-v2 call, callee, branch, compare, and merge records before lowering. One
mixed C/Zig panic-edge function now validates typed-v2 negative-check, `defaultPanic`, global-load,
and add/add_safe records before lowering, preserving the named `debug.defaultPanic` runtime boundary.

The broad gates emit `typed-v2-fallback` diagnostics only when an accepted
function falls back to legacy AIR text. The summary records the first fallback
function/opcode/data kind/reason and the top fallback bucket. Generic typed-v2
validation failures report the concrete failing typed opcode and data kind
instead of a synthetic `typed_v2` bucket. The current broad gates have no typed
v2 fallback bucket.

No broad shape-recognizer families remain in `src/zig_air_lowering.zig`.

Backend generic CFG ownership is tracked separately from typed-v2 lowering.
The current broad x86_64 release gates report `generic_cfg_functions=83` /
`structural_matcher_functions=69` for ReleaseFast and ReleaseSmall, and
`84` / `68` for ReleaseSafe. The expanded frontier reports
`generic_cfg_functions=100` / `structural_matcher_functions=79` for
ReleaseFast and ReleaseSmall, and `102` / `77` for ReleaseSafe. Newly promoted
backend families include alloca-stored extern-struct field loads at offsets 0
and 4, branch-local field-0 updates, and existing slice/aggregate sum shapes
that pass strict generic CFG eligibility. Conditional slice-loop updates and
nested optional-pointer branch payloads still fail closed at typed AIR
`block/control_flow_shape`; volatile memory, broader aggregate field stores,
and larger loop-memory dependencies remain structural/backend frontier work.

Next typed-contract target:

- lower directly from typed `structured_air-v2` records instead of legacy AIR
  text
- convert control-flow, optional/error-union, pointer/slice/array, aggregate,
  lowering from recognizer families to generic typed AIR
  lowering
- keep `legacy_air_text_lowering_functions=0` and
  `shape_recognizer_functions=0` as broad coverage expands
