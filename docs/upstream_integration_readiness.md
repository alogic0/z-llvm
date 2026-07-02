# Upstream Integration Readiness

This document summarizes what the project can currently prove for Zig upstream
discussion and what must remain an external experiment.

## Reproducibility

```text
zig version
OPT_BIN=opt-22 zig build compare-opt --
zig build zig-corpus
zig build handoff
zig build generated-scalar-diff
zig build distribution-x86_64-selected-zllvm
zig build distribution-x86_64-release-source-owned
zig build distribution-zig-source-structured-direct
zig build readiness
```

The corpus docs record the Zig compiler version, target triple, optimize mode,
command, and captured IR path for each Zig-emitted fixture.

## Capability Map

### Parser/printer/verifier

Current capability:
Accepted scalar, control-flow, memory, global, and module records with SSA
checks.

Zig boundary:
LLVM-compatibility input validation.

### Scalar optimizer

Current capability:
Fixture-equivalent InstCombine, DCE, ADCE, SCCP, EarlyCSE, GVN, and BDCE
slices.

Zig boundary:
Possible Sema/AIR/native optimizer design input.

### Memory optimizer

Current capability:
Mem2Reg, SROA, DSE, alias/mod-ref, MemoryLocation, and conservative MemorySSA
slice.

Zig boundary:
LLVM-compatibility legality study; not a Zig stack model.

### Loop optimizer

Current capability:
LoopInfo, simple LCSSA helper, scalar LICM, and explicitly budgeted loop/pass
placeholders. Placeholder accounting is registry-backed by
`zig build release-pipeline-policy`; placeholders prove the upstream pipeline
surface is known, not that the local algorithm is implemented.

Zig boundary:
AIR/liveness loop optimization study.

### Metadata and mode handling

Current capability:
Debug/profile/module flags, attributes, ReleaseSmall, and target features are
preserved opaquely.

Zig boundary:
Mode and metadata preservation input.

### Backend handoff

Current capability:
Tiny x86_64 Machine IR plus asm/object smoke checks.

Zig boundary:
Validation-only, not a backend replacement.

### Selected distribution replacement gate

Current capability:
`distribution-x86_64-selected-zllvm` proves selected x86_64 release-mode
structured-direct IR-writer rows:

```text
total_rows=146
generic_x86_64_lowering_rows=146
textual_boundary_rows=0
libLLVM_module_parse_print_rows=0
llvm_optimizer_rows=0
llvm_targetmachine_rows=0
linker=zig-native-fno-lld
```

Zig boundary:
Selected release rows only; normal Zig/libLLVM fallback remains when env vars
are unset.

### Broad source-backed structured gate

Current capability:
`distribution-x86_64-source-backed-structured` discovers 55 x86_64 release
`.ll` fixtures and proves all accepted fixture families as structured rows:

```text
fixture_families=55
structured_direct_rows=90
generic_codegen_rows=90
skipped_with_reason=0
fallback_rows=0
textual_llvm_parse_fallback_rows=0
llvm_optimizer_rows=0
llvm_targetmachine_rows=0
object_emission=z_llvm
linker=zig-native
```

Zig boundary:
ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 fixture inventory only; future
fixture expansion must fail closed on the first unsupported class.

### Source-owned DescriptorV2 gate

Current capability:
`distribution-x86_64-release-source-owned` proves the current 100-row x86_64
ReleaseFast/ReleaseSafe/ReleaseSmall source-owned wrapper inventory from
patched Zig compile-context facts.

The path does not use `ZLLVM_CASE_ID`, `ZLLVM_SOURCE_TAG`, wrapper basenames,
fixture metadata, body enum dispatch, or template-expansion ownership. Patched
Zig emits frozen `zllvm-source-facts-v1` `generic-compiler-facts`; z_llvm
classifies those facts into DescriptorV2 before verification and lowering.

Required ownership counters:

```text
release_source_rows=100
source_wrapper_rows=100
descriptor_owned_rows=100
descriptor_v2_rows=100
real_descriptor_program_rows=100
full_descriptor_program_rows=100
serialized_function_rows=100
serialized_instruction_rows=100
serialized_global_rows=100
semantic_serialized_rows=100
serialized_return_stub_rows=0
descriptor_body_name_rows=0
zllvm_body_expansion_rows=0
descriptor_program_body_expansion_rows=0
functions_for_body_rows=0
globals_for_body_rows=0
air_derived_descriptor_rows=100
static_descriptor_map_rows=0
zig_compile_context_descriptor_rows=100
env_source_tag_selector_rows=0
wrapper_body_selector_rows=0
source_tag_body_selector_rows=0
fixture_metadata_selector_rows=0
source_tag_env_present_rows=0
zig_emitted_descriptor_rows=100
runner_generated_descriptor_rows=0
descriptor_file_consumed_rows=100
source_fact_stream_rows=100
concrete_source_fact_rows=100
source_derived_descriptor_rows=100
tag_table_descriptor_rows=0
body_enum_dispatch_rows=0
surface_to_body_adapter_rows=0
canned_return_descriptor_rows=0
manual_fixture_dispatch_rows=0
legacy_semantic_record_rows=0
semantic_record_rows=0
external_writer_delegate_rows=0
manifest_structured_rows=0
case_id_rows=0
surface_dispatch_rows=0
structured_direct_rows=100
generic_codegen_rows=100
fallback_rows=0
local_fail=0
```

Additional ownership requirements:

```text
air_extracted_descriptor_rows=100
template_descriptor_rows=0
wrapper_body_map_rows=0
source_tag_body_map_rows=0
fact_derived_classification_rows=100
root_source_classification_fallback_rows=0
source_fact_program_rows=100
source_fact_program_direct_rows=100
source_fact_body_wrapper_rows=0
body_enum_fallback_rows=0
```

Release canonicalizer counters:

```text
release_canonicalizer_rows=100
observed_int_fold_rows=57
observed_fp_fold_rows=5
observed_dead_local_rows=41
observed_select_fcmp_rows=7
applied_int_fold_rows=57
applied_fp_fold_rows=5
applied_dead_local_rows=41
applied_select_fcmp_rows=7
checked_rows=9
checks_preserved_rows=9
```

Source-wrapper discovery counters:

```text
discovered_source_wrappers=82
descriptor_supported_wrappers=82
out_of_scope_wrappers=0
unsupported_with_reason=0
```

Zig boundary:
Current release source-owned wrapper inventory only. All 100 rows use
serialized AIR-shaped semantic records with compile-context fact provenance and
direct SourceFactProgram DescriptorV2 construction. This is not full Zig
Sema/AIR/Liveness replacement or full ReleaseSmall optimizer parity.

### Source-owned ELF object inspection

Current capability:
`distribution-native-link-object-inspection -- --release-source-owned` proves
the same 100-row boundary emits ELF64 relocatable x86_64 objects through the
patched-Zig source-owned z_llvm object path before Zig native linker handoff.

```text
inspected=100
elf64_rel=100
relocation_rows=12
tls_rows=8
undefined_import_rows=0
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Zig boundary:
Object-format proof only. Final linking, CRT policy, libc, dynamic loader
behavior, archives, linker scripts, and new-linker feature gaps remain Zig
linker/toolchain ownership.

### Source-owned native-link handoff

Current capability:
`distribution-native-link -- --release-source-owned` and
`probe-native-linker -- --release-source-owned` prove the same 100-row
source-owned boundary reaches Zig native `-fno-lld` linker handoff.

Executable gate counters:

```text
total=100
executable_abi_proof_rows=100
link_only_rows=0
runtime_compiler_rt_libc_boundary_rows=0
unsupported_zig_linker_feature_rows=0
local_object_codegen_failures=0
local_fail=0
```

Companion probe counters:

```text
accepted=100
runtime_compiler_rt_libc_boundary_rows=0
unsupported_zig_linker_feature_rows=0
local_object_codegen_failures=0
failed=0
```

Zig boundary:
Native linker ownership remains Zig-owned. This proves handoff acceptance and
runnable ABI behavior for selected source-owned wrappers, not a z_llvm linker
implementation.

### Uncurated real AIR compatibility gate

Current capability:
`distribution-zig-air-uncurated-release` discovers `test/zig/inputs/*.zig`,
asks patched Zig for `zllvm-air-export-v1` plus `structured_air-v1`
body/branch metadata and typed `structured_air-v2` records, and lowers real
ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 AIR without case IDs, wrapper maps,
source-fact body classification, or canned DescriptorV2 construction.

Current counters for each mode:

```text
source_rows=19
discovered_functions=44
structured_functions=44
generic_codegen_functions=44
structured_air_v1_functions=44
structured_air_v2_functions=44
typed_air_type_functions=44
typed_air_operand_functions=44
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=44
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
case_id_rows=0
source_fact_classification_rows=0
local_fail=0
```

Zig boundary:
Narrow compatibility gate retained for regression coverage. The broad real-AIR
release gates below carry the current strongest typed-v2 ownership claim.

### Broad uncurated ReleaseFast/ReleaseSafe/ReleaseSmall AIR discovery

Current capability:
`distribution-zig-air-uncurated-releasefast-broad`,
`distribution-zig-air-uncurated-releasesafe-broad`, and
`distribution-zig-air-uncurated-releasesmall-broad` discover
`test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`.

Discovery counters for each mode:

```text
source_rows=101
discovered_functions=152
structured_functions=152
generic_codegen_functions=152
generic_cfg_functions=152
structural_matcher_functions=0
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
case_id_rows=0
source_fact_classification_rows=0
local_fail=0
```

Object progress counters:

```text
object_emitted_functions=152
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object-inspection counters:

```text
inspected=101
elf64_rel=101
relocation_rows=14
tls_rows=3
undefined_import_rows=3
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

ReleaseFast and ReleaseSmall native-link progress:

```text
native_link_accepted_rows=100
executable_ok_rows=0
link_only_rows=100
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Executable proof counters for ReleaseFast, ReleaseSafe, and ReleaseSmall:

```text
native_link_accepted_rows=100
executable_ok_rows=100
link_only_rows=0
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Zig boundary:
Broad real-AIR lowering/codegen/object evidence for all three release modes.
The named runtime boundary is `debug.defaultPanic`. These gates stay out of
`distribution-all` until runtime and executable proof cost is known.

The focused release optimizer milestone gate is
`zig build distribution-air-release-broad`. It composes the broad real-AIR
ReleaseFast, ReleaseSafe, and ReleaseSmall executable-progress path and keeps the
proof outside `distribution-all` during iteration. Current per-mode counts are
`source_rows=101`, `discovered_functions=152`, `generic_codegen_functions=152`,
`generic_cfg_functions=152`, `structural_matcher_functions=0`,
`object_emitted_functions=152`, `native_link_accepted_rows=100`,
`executable_ok_rows=100`, `link_only_rows=0`, `runtime_boundary_rows=1`,
`native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and
`local_fail=0`. It fails closed if any broad function returns to structural
matcher fallback.

### Expanded uncurated release AIR frontier

Current capability:
`distribution-zig-air-uncurated-releasefast-expanded`,
`distribution-zig-air-uncurated-releasesafe-expanded`, and
`distribution-zig-air-uncurated-releasesmall-expanded` add explicit sources
under `test/zig/expanded/*.zig` on top of the closed broad corpus.

Discovery counters for all three release modes:

```text
source_rows=109
discovered_functions=199
structured_functions=199
generic_codegen_functions=199
generic_cfg_functions=199
structural_matcher_functions=0
structured_air_v2_functions=199
typed_air_operand_functions=199
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=199
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
local_fail=0
```

Object progress:

```text
object_emitted_functions=199
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

The frontier safety-edge slice includes typed-v2/generic-CFG lowering for
optional-pointer unwrap/null panic, checked int-from-float
`integerPartOutOfBounds`, direct bounds loads, and checked unsigned add helper
rows across ReleaseFast, ReleaseSafe, and ReleaseSmall.

Object inspection:

```text
inspected=109
elf64_rel=109
relocation_rows=18  # 19 for ReleaseSafe
tls_rows=4
undefined_import_rows=3  # 6 for ReleaseSafe
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Native-link progress:

```text
ReleaseFast/ReleaseSmall:
native_link_accepted_rows=108
link_only_rows=108
runtime_boundary_rows=1

ReleaseSafe:
native_link_accepted_rows=105
link_only_rows=105
runtime_boundary_rows=4
```

Executable proof for all three modes:

```text
native_link_accepted_rows=108
executable_ok_rows=108
link_only_rows=0
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

The focused aggregate gate `zig build distribution-air-release-expanded`
composes expanded discovery, object progress, executable progress, and strict
finish for ReleaseFast, ReleaseSafe, and ReleaseSmall. It currently reports
`source_rows=109`, `discovered_functions=199`,
`generic_cfg_functions=199`, `structural_matcher_functions=0`,
`object_emitted_functions=199`, `native_link_accepted_rows=108`,
`executable_ok_rows=108`, `link_only_rows=0`, `runtime_boundary_rows=1`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0` per mode.

Zig boundary:
New frontier only. The slice closes additional scalar CFG, memory, call,
optional/error, branch/select, global/TLS, aggregate, atomic, inline-asm, and
expanded stack/mixed SysV ABI rows. Remaining non-selected ABI boundaries are
full aggregate classification beyond selected INTEGER/normal integer-leaf
MEMORY forms, arbitrary non-selected sret/byval copies, varargs, vectors, and
high-register-pressure spill/reload-heavy call frames.
The latest frontier ABI slices narrow that sret/byval gap for supported normal
MEMORY leaves with `ScalarMixed`, `ScalarNested`, and `ScalarArray` direct and
pointer-callee copies, and narrow nested mixed aggregate call coverage with
pointer-callee `{ { i32, i32 }, double }` argument/return rows. Varargs and
vectors remain explicit fail-closed boundaries, not accepted frontier rows.

### Scale uncurated release AIR frontier

Current capability:
`distribution-zig-air-uncurated-releasefast-scale`,
`distribution-zig-air-uncurated-releasesafe-scale`, and
`distribution-zig-air-uncurated-releasesmall-scale` add explicit sources under
`test/zig/scale/*.zig` on top of the expanded corpus.

Discovery and object counters:

```text
source_rows=112
discovered_functions=216
structured_functions=216
generic_codegen_functions=216
generic_cfg_functions=216
structural_matcher_functions=0
structured_air_v2_functions=216
typed_air_operand_functions=216
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=216
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=216
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection:

```text
inspected=112
elf64_rel=112
unsupported_relocation_rows=0
local_fail=0

ReleaseFast/ReleaseSmall:
relocation_rows=20
undefined_import_rows=3

ReleaseSafe:
relocation_rows=21
undefined_import_rows=6
```

Native-link progress:

```text
ReleaseFast/ReleaseSmall:
native_link_accepted_rows=111
link_only_rows=111
runtime_boundary_rows=1

ReleaseSafe:
native_link_accepted_rows=108
link_only_rows=108
runtime_boundary_rows=4
```

Executable proof:

```text
native_link_accepted_rows=111
executable_ok_rows=111
link_only_rows=0
runtime_boundary_rows=1
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

The focused aggregate gate `zig build distribution-air-release-scale` composes
scale discovery, object progress, and executable progress for ReleaseFast,
ReleaseSafe, and ReleaseSmall. It is a green frontier/progress gate with
fail-closed local failure classification, not yet a strict counter-locked
finish gate. It currently reports `source_rows=112`,
`discovered_functions=216`, `generic_cfg_functions=216`,
`structural_matcher_functions=0`, `object_emitted_functions=216`,
`native_link_accepted_rows=111`, `executable_ok_rows=111`,
`link_only_rows=0`, `runtime_boundary_rows=1`, `llvm_targetmachine_rows=0`,
`lld_rows=0`, and `local_fail=0` per mode.
The strict `zig build distribution-air-release-scale-finish` gate locks the
same scale counters with `--strict-finish`, while
`distribution-air-release-scale` remains the lower-cost progress command.

Zig boundary:
Frontier only. It keeps broad/expanded claims intact while adding broader SysV
call shapes, memory loops, branch-local pointer memory, extern two-i32 field
updates, direct-call branch merges, globals, and TLS.

### Frontier uncurated release AIR corpus

Current capability:
`distribution-zig-air-uncurated-release-frontier` covers only
`test/zig/frontier/*.zig`, separate from the cumulative broad, expanded, and
scale gates.

ReleaseFast/ReleaseSafe/ReleaseSmall counters:

```text
source_rows=14
discovered_functions=753
structured_functions=753
generic_codegen_functions=753
generic_cfg_functions=753
structural_matcher_functions=0
structured_air_v2_functions=753
typed_air_operand_functions=753
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=753
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=753
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection:

```text
inspected=13
elf64_rel=13
relocation_rows=5
tls_rows=1
undefined_import_rows=1
unsupported_relocation_rows=0
local_fail=0
```

Native-link and executable proof:

```text
native_link_accepted_rows=14
executable_ok_rows=14
link_only_rows=0
runtime_boundary_rows=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

The strict `zig build distribution-air-release-frontier` gate runs the isolated
frontier corpus in ReleaseFast, ReleaseSafe, and ReleaseSmall with object
progress, executable progress, and strict counter checks. It requires the
14-source / 753-function counters above plus `native_link_accepted_rows=14`,
`executable_ok_rows=14`, `link_only_rows=0`, `runtime_boundary_rows=0`,
`unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0` for each mode.
The frontier optionals/errors proof now includes typed-v2 ownership for AIR
`error_name`: the patched Zig exporter emits a typed unary record carrying the
error-set operand, and z_llvm lowers the selected sentinel `u8` slice length
path from those facts without AIR-text recovery or sidecars. The claim is
limited to source-backed `@errorName(err).len` behavior for selected concrete
error-set rows. The latest row covers a three-name error set by selecting the
string pointer and length from exported error-set names and a runtime error
code. ReleaseSafe now keeps the integer-to-error validation enabled for that
row: the patched Zig exporter emits a versioned typed unary
`error_set_has_value` membership record with the checked operand and
destination error-set type, and z_llvm lowers the selected dense concrete
error-set membership check from those facts. The executable harness checks
valid values and child-process trap behavior for an invalid error code.
Arbitrary sparse/non-dense error-set membership and arbitrary error-name
payload lowering remain future work.
The optionals/errors frontier also covers a selected helper that returns one of
two errors, a caller catch path that extracts the `i16` error tag, and a switch
returning distinct scalar classifications. The helper return is lowered from
typed AIR/generic terminal values, and the caller uses the generic error-tag
switch path plus shared SysV scalar call argument assignment rather than a
function-name-specific emitter.
The same source now proves a catch-side `cond_br` remap: the error path
compares the unwrapped `i16` tag and returns packed `i64` error-union
constants, while the success path rewraps payload arithmetic. This closes a
branch-owned `unwrap_errunion_err` / `wrap_errunion_err` shape without AIR text
recovery or source-name admission.
The catch/helper-call rows now cover the next compiler-core-shaped siblings:
one catches a payload-returning error-union helper, and the newer row catches
an `Error!void` helper where the success continuation returns ordinary `i32`
arithmetic. Both are tied to the refreshed ReleaseFast compiler-core
`try:pl_op` / `unwrap_errunion_err:ty_op` family and are admitted by typed AIR
and generic CFG data flow, not by row name.
The same `Error!void` success form is now also proven with a catch-side
`switch (err)` merge. That row mirrors the `root.main() catch |err| switch
(err)` compiler-core/startup topology and keeps error-tag switch admission
data-flow based rather than payload-only.
The producer-side `frontier_try_void_payload_match` row covers the same
compiler-core `try:pl_op` family from inside an `Error!i32` helper: the inner
`try` operand is `Error!void`, the hot path wraps a generic `i32` expression as
the success payload, and the cold path rewraps the original error tag. This
extends typed-v2 try lowering to void payload continuations without adding an
AIR-text recovery path.
The follow-up `frontier_try_void_chain_match` row covers the repeated
`Error!void` try-chain shape seen in the preserved ReleaseFast compiler-core
descriptor: two sequential void-success `try` operations inside an
`Error!void` helper, final void success, and a caller catch classifier for the
propagated error. Admission remains typed-v2/generic-CFG data-flow based, not
row-name based.
The producer-side branch row now also proves terminal `cond_br` arms that
return wrapped error constants directly, so `wrap_errunion_err` is not limited
to the previous switch-to-phi frontier proof.
The frontier scalar-transform proof now includes AIR `byte_swap` for selected
integer widths: `u16`, `u32`, and `u64`. Zig exports a versioned
`zllvm-byte-swap-v1` typed `ty_op` record with the operand ref, result integer
type, and bit width, and z_llvm lowers those facts to x86_64
`rolw`/`bswapl`/`bswapq` without preserving `llvm.bswap.*` as unresolved
linker symbols. Vector byte swaps, aggregate `byteSwapAllFields`, `u8`
identity policy, and odd-width integer byte swaps remain future/boundary work.
The same proof now includes typed AIR `max` and `min` for selected signed
`i32` rows: Zig exports the operands as typed `bin_op` records, z_llvm lowers
them to signed compare/select forms, and x86_64 emits the shared signed
max/min patterns with executable C ABI checks. Unsigned max/min, wider integer
max/min, vector max/min, and odd-width scalar forms remain future work.
The selected signed `i32` `@abs` scalar row is also typed-AIR owned: Zig
exports `abs` as a versioned `zllvm-abs-v1` typed `ty_op` record, z_llvm
validates the `i32 -> u32` form, lowers it through generic compare/sub/select
IR, and the executable harness checks positive, negative, and zero inputs.
Wider integer abs, vector abs, odd-width abs, and explicit ReleaseSafe
overflow/minInt negative-path proof remain future work.
The frontier proof now includes the selected tagged-union tag/payload switch
row: Zig emits versioned typed-v2 union-tag and switch case facts, and z_llvm
lowers both tag arms from those facts without AIR text fallback, shape
recognizer ownership, or function-name admission. Reversed source switch-arm
ordering is accepted only when the exported case tag indexes prove the selected
tag set, and either selected tag arm may now prove the payload store as the raw
second argument or a constant add of that argument. The selected lowering now
uses structured-air branch bodies to map the `cond_br` true/false arms to tag
indexes, so reordered union field/tag indexes are proven without a function-name
admission path. General union ABI/layout lowering remains outside this selected
frontier row.

Source-backed ABI and pointer/slice boundary proof is tracked separately by
`zig build distribution-air-release-frontier-boundaries`. It runs
`test/zig/frontier_boundaries/*.zig` in ReleaseFast, ReleaseSafe, and
ReleaseSmall and currently reports per mode: `source_rows=10`,
`discovered_functions=18`, `varargs_boundary_rows=2`,
`vector_boundary_rows=4`, `x87_boundary_rows=2`,
`packed_aggregate_boundary_rows=2`, `tail_call_boundary_rows=1`,
`callconv_boundary_rows=1`, `stack_pressure_boundary_rows=0`,
`safety_edge_boundary_rows=0`,
`pointer_slice_boundary_rows=2`,
`tag_name_boundary_rows=1`,
`union_payload_boundary_rows=1`,
`optional_error_mix_boundary_rows=2`,
`unexpected_accept_rows=0`,
`wrong_diagnostic_rows=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and
`local_fail=0`. These rows prove explicit fail-closed ABI boundaries for
varargs, vectors, long-double/X87, packed aggregates, tail calls,
non-default call conventions, pointer/slice volatile and atomic forms, and
union `@tagName` string/sentinel-slice lowering. Checked slice-element loads and
stores moved into the accepted strict frontier corpus with executable
hot/trap-path proof, while the two remaining pointer/slice boundary rows are
volatile and atomic derived-pointer forms. The prior
Big80/Big81/Big96/Big128/Big160/Big192/Big224/Big256 stack-source forwarding
boundary is now
accepted in the strict frontier corpus, and the boundary counter remains at
`stack_pressure_boundary_rows=0` as a regression guard; boundary rows are not
part of the accepted executable frontier counters.
The selected slice-panic runtime-call row now uses the release generic CFG
slice runtime-call helper subset, which derives direct integer lengths and
`{ ptr, i64 }` aggregate slice constant lengths, i64 parameter lengths, loaded
i64 lengths, and simple computed i64 add/sub lengths from IR rather than using
a selected message-length constant. Selected multi-input length selection now
lowers through typed AIR `select` values, and selected loaded payload pointer
objects are materialized when the payload remains a `{ ptr, i64 }` panic slice;
arbitrary phi/control-flow length selection and computed payload pointers remain
future work.
The frontier safety-edge executable harnesses use child-process death checks for
non-constant panic-slice calls, explicit signed/unsigned checked-overflow panic
rows, and ReleaseSafe bounds/null/int-conversion panic rows. They also resolve the cold
`outOfBounds`, `integerPartOutOfBounds`, and `unwrapNull` symbols with local
trap stubs so the stable non-panic C ABI probes link and run without turning
those symbols into native-link runtime-boundary rows.
The latest SysV aggregate slice adds direct and pointer-callee nested mixed
aggregate forwarding rows: `{ { i32, i32 }, double }` remains a register-class
aggregate and returns through `%rax`/`%xmm0`, while typed-v2 sret rewriting is
kept to non-register aggregate candidates.
The follow-up stack-source row reloads the same nested mixed aggregate from the
caller stack into `%rax`/`%xmm0` once preceding scalar arguments exhaust both
the GPR and SSE streams.
The SSE/SSE follow-up does the same for a stack-passed `[2]f64` aggregate,
reloading caller-stack eightbytes into `%xmm0`/`%xmm1` for the pass-through
return.
The single-eightbyte SSE follow-up covers stack-passed `{ f32, f32 }` by
reloading the caller-stack eightbyte into `%xmm0`.
The companion pointer-callee row uses the same stack-source reload before
`callq *%rax`, proving the indirect SysV planner path for this class.
The mixed stack-argument rows call external C ABI helpers directly and through
function pointers with both overflowing `i32`/`i64` and `float`/`double` argument
streams, proving the GPR and SSE cursors assign outgoing stack slots
independently in the same call.
The reversed mixed follow-up covers the opposite SSE/INTEGER order by reloading
stack-passed `{ double, i64 }` into `%xmm0`/`%rax`.
The aggregate/type-layout refactor starts the next ownership phase: named
aggregate decoding, field offsets, recursive leaf lookup, supported scalar-leaf
collection, generic CFG aggregate field/copy lowering, and SysV aggregate
classification now share `src/zig_air_type_layout.zig`. This preserves the
strict 14-source / 669-function frontier executable proof while removing the
former long fixture-path mapping block from `src/zig_air_types.zig`. The
follow-up removes the former ambiguous nominal `Pair` compatibility rule:
nominal `Pair` normalizes as `{ i32, i32 }`, and runtime aggregate-pair
compatibility lowerers now admit by normalized layout and data-flow structure
rather than exact symbol names. `AggregateLayoutPlan` is now the shared
normalized field/leaf plan for pair admission and sret/byval aggregate copy
and make planning. Typed-v2 register aggregate construction admission validates
operands against the same plan before using typed AIR pointer paths for
insertvalue indices, and SysV classification consumes the same normalized
aggregate type. `AggregateLayoutSummary` records descriptor-exported facts,
sidecar-exported facts, static-source facts, or boundary-provider ownership.
The compatibility fallback table has been removed, the temporary static source
fact provider is empty, and the sidecar files are header-only. The patched
Zig stage4 emitter writes `zllvm-aggregate-layout-facts-v1` directly into AIR
descriptors for supported aggregate semantic layouts; z_llvm parses the
optional `aggregate_layout_facts_bytes` section and gives descriptor facts
precedence over compatibility sidecars. The current empty-sidecar provider
audit reports `exported_facts=0`, `static_source_facts=0`,
`boundary_provider=2`, `generated_examples=0`, `sidecar_exported_facts=0`,
and `descriptor_exported_facts=0`; the former 3 non-frontier sidecar
compatibility facts have been retired. The audit can now read saved AIR
descriptors with `--from-air=<descriptor>`; `tmp/aggregate_hook_check.air`
reports `exported_facts=14`, `descriptor_exported_facts=14`,
`sidecar_exported_facts=0`, and `static_source_facts=0`, making Zig-emitted
descriptor ownership machine-readable evidence outside the gate. Packed/unaligned aggregate ABI
remains a 2-row targeted boundary through
`src/zig_air_aggregate_layout_boundaries.zig` rather than a fallback layout.
Register
aggregate construction and sret/byval make rows now perform mechanical typed
AIR inference from ret_ptr, field/element pointer stores, and ret_load before
admission. Register aggregate construction and direct sret aggregate make
validation now classify and plan from the inferred layout before provider facts
when the store paths prove the shape, so those rows are checked by
function-local construction evidence rather than nominal layout facts alone.
Sret/byval copy rows now also prove the
terminal return is the typed aggregate argument, and sret/byval call-wrapper
rows prove that the typed aggregate argument feeds the single call and that the
aggregate terminal return is produced by that call. The static source-aggregate
facts table is currently empty, and the compatibility fallback table has been
removed; replacing sidecar facts with exported Zig field facts or broader
function-local inference is the next ownership step.

Strict release baselines now cover the cumulative broad, expanded, and scale
corpora plus the isolated frontier corpus: broad is inputs + integrated,
expanded adds `test/zig/expanded`, scale adds `test/zig/scale`, and frontier
is `test/zig/frontier` only.

Accepted frontier evidence:

```text
typed_air_v2=accepted
generic_cfg=accepted
selected_nested_loop_memory=accepted
selected_aggregate_field_pointer_gep_global_tls=accepted
selected_sysv_integer_integer=accepted
selected_nested_integer_aggregate=accepted
selected_nested_mixed_aggregate=accepted
selected_array_integer_and_sse_aggregate=accepted
selected_f32_pair_aggregate_call_passthrough=accepted
selected_stack_passed_register_aggregate_fields=accepted
selected_memory_sret_byval_integer_leaf=accepted
selected_mixed_width_memory_aggregate=accepted
selected_array_backed_memory_copy_read=accepted
selected_deep_supported_leaf_memory_sret_byval=accepted
selected_mixed_integer_sse_and_sse_integer=accepted
selected_sse_sse_aggregate=accepted
selected_f32_array_aggregate=accepted
selected_up_to_six_live_i32_spills=accepted
selected_up_to_six_stack_passed_live_i32=accepted
selected_six_stack_passed_i32_call_args=accepted
selected_two_call_six_live_i32_gpr_frame=accepted
selected_ordered_i32_call_result_across_second_call=accepted
selected_two_i32_call_results_across_calls=accepted
selected_indirect_two_i32_call_results_across_calls=accepted
selected_two_i32_call_results_across_later_void_call=accepted
selected_two_i32_call_results_across_indirect_later_void_call=accepted
selected_two_i64_call_results_across_calls=accepted
selected_i64_call_result_across_later_void_call=accepted
selected_two_i64_call_results_across_later_void_call=accepted
selected_one_to_six_live_f32_f64_spills=accepted
selected_two_live_f32_f64_arg_call_spills=accepted
selected_xmm0_to_xmm4_call_args=accepted
backend_fp_constants_xmm0_to_xmm7=accepted
```

Remaining non-accepted blockers:

```text
broader aggregate lowering beyond selected INTEGER/SSE/MEMORY frontier
arbitrary non-selected sret/byval copies
varargs
vectors
stack-passed live-value scheduling beyond the current selected direct-call/void-call
model
broader SSE live-across-call helpers beyond selected no-argument-call shapes, selected
direct/repeated-direct/pointer-callee/repeated-pointer-callee stack-passed FP addend
sums after no-argument calls, selected six-XMM-plus-up-to-twelve-stack FP addend sums
after direct/pointer-callee no-argument calls, selected one-FP-argument
direct/pointer-callee stack-passed FP addend sums, selected repeated two-live
direct/pointer-callee no-argument shapes, selected mixed one-GPR/one-SSE i32/i64
one-/two-call direct/pointer-callee shapes, selected direct two-/three-/six-live
FP-argument shapes, pointer-callee shapes through six live values and five FP helper
arguments, selected direct/pointer-callee f32/f64 call-result live-across-later-call
frames, selected direct/pointer-callee f32/f64 result live-across-later
constant-stack-argument FP call frames, selected same-width two-result f32/f64 call
frames, selected mixed f32/f64 two-result call frames, selected mixed f32/f64 two-result
frames with one live double, float, or i64 addend, selected mixed i64/f64, i64/f32,
f64/i64, and f32/i64 two-result frames, selected direct/pointer-callee i64 result
live-across-later-void frames, and selected direct/pointer-callee two-result i64
live-across-later-void frames
alternate safety-guard control flow
```

Zig boundary:
New source-frontier evidence only. Accepted rows use typed AIR v2 and generic
CFG; unsupported rows remain measured boundaries.

### Source-wrapper compatibility gate

Current capability:
`distribution-zig-source-structured-direct` proves 49 selected x86_64 release
Zig source wrappers without case-id dispatch ownership:

```text
source_wrappers=49
case_id_rows=0
structured_direct_rows=49
generic_codegen_rows=49
fallback_rows=0
semantic_record_rows=48
external_writer_delegate_rows=1
```

Zig boundary:
Unambiguous wrapper/mode subset only; weaker than the source-owned release gate.

### Differential testing

Current capability:
Generated scalar diff runner plus fail-closed negative generation.

Zig boundary:
Regression infrastructure input.

## External Experiment Boundary

These parts should remain outside Zig upstream until they have stronger proof:

```text
full LLVM IR parser parity
full LLVM pass algorithm parity
target lowering, register allocation, scheduling, and ABI breadth
DWARF/CodeView/unwind emission
TLS lowering and linker integration
PGO, BFI/BPI, TTI, and size-cost decisions
EH pads, inline asm semantics, and full atomic memory model
bitcode writer, LTO, and ThinLTO summary behavior; Cycle 23 keeps these
deferred unless a concrete bitcode or linker-LTO handoff use case activates
that compatibility track
```

## Upstreamable Design Input

The parts most useful for upstream discussion are:

```text
Zig LLVM dependency inventory and pass-pipeline inventory
source-backed Zig-emitted IR corpus manifest
fixture metadata separating opt-equivalent from local-conservative behavior
MemorySSA/alias legality lessons for avoiding unsafe load CSE/GVN
AIR/liveness handoff matrix separating LLVM facts from Zig-native concepts
source-wrapper dispatch and source-owned semantic-record lowering ladder for
selected rows
readiness check script that reproduces current claims
```

## Next Roadmap Wave

The next wave should be selected from Zig's actual LLVM-removal blockers:

```text
inline asm and atomicrmw IR representation with verifier fail-closed rules
vector lane-operation boundaries plus target-cost policy decisions
broader AArch64 promotion after target-independent scalar cleanup
Debug-mode reduction work for large source-backed Debug rows
path-aware MemorySSA only after a source-backed fixture requires it
```

The evidence behind that ordering is recorded in
`docs/roadmap/source_backed_readiness_audit.md`.

## Current Verdict

The project is useful as a structured LLVM-removal experiment and regression
corpus, but it is not an LLVM replacement. Its strongest upstream-facing value
is the inventory, fixture discipline, conservative legality boundaries, and
clear split between LLVM-compatible IR work and Zig-native backend ownership.
