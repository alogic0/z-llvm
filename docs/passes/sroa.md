# SROA

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Transforms/Scalar/SROA.h
llvm-project-22/llvm/lib/Transforms/Scalar/SROA.cpp
llvm-project-22/llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp
```

Upstream entry points to check:

```text
SROAPass::run
SROA::splitAlloca
SROA::rewritePartition
SROA::propagateStoredValuesToLoads
AllocaSlices
PromoteMemToReg
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Transforms/Scalar/SROA.h
  llvm-project-22/llvm/lib/Transforms/Scalar/SROA.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp

LLVM entry points/classes:
  SROAPass::run
  SROA::splitAlloca
  presplitLoadsAndStores
  SROA::rewritePartition
  AllocaSlices::SliceBuilder
  AllocaSlices::partition_iterator
  AllocaSliceRewriter
  AllocaSlices
  PromoteMemToReg

Required analyses:
  DataLayout for real slice offsets
  Local mem2reg promotion after rewrites

Required IR invariants:
  Verified alloca, GEP, load, and store uses for the accepted memory subset.

Core LLVM algorithm data structures:
  Alloca slice collection
  Slice partitioning
  Rewrite decisions
  PromoteMemToReg handoff for scalarized slots

Local target status:
  LLVM-shaped subset for listed fixtures

Implemented subset:
  AllocaSlice records for GEP users rooted in an alloca
  SlicePartition lookup by GEP result
  SlicePartition construction for accepted fixed struct/array field ranges
  overlap rejection for partitions that cover different fields
  Synthetic fixed field partitions for whole-aggregate alloca loads/stores
  DataLayout-like offset/size facts through `src/analysis/memory_location.zig`
  Zero-offset partition forwarding to the base alloca
  Nested zero-offset partition forwarding to the base alloca
  Textual struct aggregate parsing for the narrow `{ iN, iN, ... }` surface
  Fixed array aggregate parsing for the narrow `[N x iM]` surface
  Struct-field GEP offset calculation for constant field indices
  Array-element GEP offset calculation for constant element indices
  Exact-cover scalar integer field/element alloca splitting for simple
  aggregate allocas
  DataLayout-backed pointer field splitting for simple aggregate allocas,
  using the opt-22 default layout when a module has no DataLayout
  Rewriting of matching scalar field loads/stores to replacement allocas through
  the partition builder
  Rewriting of debug-free whole-aggregate loads/stores through scalar field
  extract/store and load/insertvalue reconstruction
  mem2reg handoff after forwarding

Intentional divergences:
  The aggregate type model is textual and only accepts the small struct shape
  and fixed integer array shape needed by the current SROA fixtures. It is not
  a full LLVM type system.
  Replacement allocas are created only for scalar integer fields and
  DataLayout-backed pointer fields reached by constant two-index struct/array
  GEPs.
  Volatile, atomic, escaped, variable-index, vector, packed, and unknown-size
  cases are rejected locally for now. LLVM SROA can scalarize some
  volatile field cases more precisely; this project keeps that as a documented
  conservative gap until memory-use rewriting is stronger.

Analysis preservation/invalidation:
  SROA mutates pointer uses and then runs mem2reg, so it invalidates analyses
  under the local pass-manager policy. The pass manager verifies after
  execution.

Fixture coverage:
  sroa_zero_gep
  sroa_nested_zero_gep
  sroa_struct_two_i32
  sroa_array_three_i32
  sroa_struct_one_field
  sroa_struct_ptr_field
  sroa_struct_ptr_field_no_layout_reject
  sroa_aggregate_load_store
  sroa_struct_volatile_reject
  sroa_struct_escape_reject
  debug_sroa_dbg_drop
  sroa_debug_declare_reject
  sroa_byval_param_boundary

Zig-emitted aggregate coverage:
  The checked Zig `aggregates` corpus row captures struct-field GEPs, arrays,
  slices, optionals, and error unions from Zig output. The first accepted local
  aggregate SROA fixture is a reduced two-field integer struct alloca matching
  the shape that SROA must handle before the full Zig aggregate corpus can be
  parsed.

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
```

LLVM SROA rewrites aggregate and sliced stack objects into smaller scalar
allocas and promotes simple scalar stack slots when possible.

Implemented subset:

```text
recognize getelementptr instructions whose base pointer is an alloca
recognize nested zero-offset getelementptr chains whose root is an alloca
collect alloca-rooted GEPs as slices with offset, size, source type, and
compatibility state
build partitions for accepted struct/array fields by grouping exact field or
element ranges
reject overlapping partitions that refer to different fields
look up the rewrite partition for each GEP result
require every GEP index to be integer constant zero
replace uses of that zero-offset GEP result with the base alloca pointer
parse small textual struct aggregate types
parse small textual fixed array aggregate types
calculate constant struct-field GEP offsets
calculate constant fixed-array element GEP offsets
split simple integer struct-field/array-element partitions into scalar allocas
split DataLayout-backed pointer struct-field partitions into scalar allocas,
using the opt-22 default layout when a module has no DataLayout
rewrite exact-cover field loads/stores to those scalar allocas
create synthetic scalar field partitions for debug-free whole-aggregate
load/store users
rewrite whole-aggregate stores into per-field extractvalue plus scalar stores
rewrite whole-aggregate loads into scalar loads plus insertvalue reconstruction
run the existing mem2reg promotion after forwarding
```

This matches the first useful AllocaSlices-shaped alloca-forwarding and scalar
aggregate splitting cases needed before full LLVM SROA rewriting. It lets
trivial zero-offset GEPs and simple integer/pointer aggregate fields stop
blocking stack promotion.

Fixture coverage:

```text
opt-22 equivalent:
  sroa_zero_gep
  sroa_nested_zero_gep
  sroa_struct_two_i32
  sroa_array_three_i32
  sroa_struct_one_field
  sroa_struct_ptr_field
  sroa_struct_ptr_field_no_layout_reject
  sroa_aggregate_load_store
  sroa_struct_escape_reject
  sroa_byval_param_boundary

local-only conservative:
  debug_sroa_dbg_drop
  sroa_struct_volatile_reject
  sroa_debug_declare_reject

unit-test only:
  sroa rejects volatile aggregate field accesses locally
  memory location aggregate helpers classify array elements as fields
```

Known gaps:

```text
no full aggregate type model
no complete LLVM AllocaSlices partition iterator; the local builder only forms
exact fixed struct/array field partitions
no partial load/store rewriting beyond the exact whole-aggregate load/store
shape listed above
no memcpy/memmove rewriting
no padding, integer widening, vector, or packed-aggregate handling
pointer-field scalarization uses module-level target DataLayout or the same
default layout used by opt-22 for modules with no DataLayout, but the local type
model still covers only the current integer and pointer struct/array subset
debug declare salvage blocks aggregate rewriting until variable-location update
semantics are modeled
debug-location-only aggregate rewrites may drop `!dbg` locations attached to
removed alloca/GEP/load/store instructions; no LLVM-style variable-location
salvage is attempted
```
