# x86_64 SysV ABI Bootstrap

LLVM references:

```text
llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td
llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp
llvm-project-22/llvm/lib/Target/X86/X86RegisterInfo.td
```

Upstream entry points to check:

```text
X86_64_SysV calling convention tables
X86TargetLowering::LowerFormalArguments
X86TargetLowering::LowerCall
X86TargetLowering::LowerReturn
X86FrameLowering::emitPrologue
X86FrameLowering::emitEpilogue
```

Implemented subset:

```text
i32 return value in %eax
i64 and pointer-class return values use the generic SysV GPR return path in %rax
f32/f64 return values in %xmm0 for selected rows
first six integer/pointer-class register arguments are recognized as %edi, %esi, %edx, %ecx, %r8d, and %r9d for i32 values
i64/pointer-class arguments use the corresponding 64-bit GPR view for selected rows
f32/f64 arguments use the independent SysV SSE stream; named source-frontier
proof currently reaches %xmm0..%xmm4, and backend constant materialization
reaches %xmm0..%xmm7
register-source f32/f64 argument permutations use planner-owned temporary
stack copies to snapshot source XMM registers before assigning outgoing SSE
argument slots for direct and function-pointer calls
i1 branch conditions use the matching low 8-bit argument registers
i32/i64/pointer direct-call operands use the first-six integer argument register order
the central SysV call planner assigns pointer call arguments through the same
scalar path as i64: register pointer arguments use 64-bit GPR moves, and
stack-passed pointer arguments reuse the outgoing stack-slot helper; null
pointer constants are supported for stack-passed pointer call slots
pointer return values from parameters and pointer-returning direct calls reuse
the same generic GPR return path as i64
f32/f64 direct-call operands use the independent SSE register order
up to eighteen scalar i32 stack-passed direct/indirect call arguments are supported, including constants and named incoming stack/register parameters; selected block-local computed i32/i64 stack arguments remain covered by the smaller existing rows
direct calls preserve SysV stack alignment by subtracting 8 from %rsp before callq and adding it back after the call
one live i32 caller argument can be spilled to (%rsp) across one call
up to six live i32 caller arguments can be spilled into aligned frame slots and reloaded after one direct call
more than six stack-passed live i32/i64 caller arguments can be reloaded after the
call once the local call frame is restored, including a selected disp32
incoming stack reload after a side-effecting void call
one live f32/f64 caller argument can be spilled from %xmm0 into an aligned
frame slot, reloaded after one direct C ABI void call, and returned from %xmm0
one stack-passed live f32 or f64 caller argument can be reloaded from the
restored incoming stack argument area after one direct C ABI void call
direct f32/f64 parameter returns now load stack-passed FP parameters from the
incoming stack argument area once the SSE register stream is exhausted
stack-passed f32/f64 helper-call arguments can be reloaded from the incoming
stack argument area into outgoing XMM registers for direct and pointer-callee
calls
the ninth and later `float`/`double` helper-call arguments can be assigned to
outgoing SysV stack slots for direct and pointer-callee calls, including named
parameters and immediate FP constants
direct i64/pointer parameter returns now load stack-passed parameters
from the incoming stack argument area once the GPR stream is exhausted
two or three live f32/f64 caller arguments can be spilled from %xmm0/%xmm1
or %xmm0/%xmm1/%xmm2 into aligned frame slots across one no-argument direct
C ABI void call and reloaded for post-call fadd returns
one fixed i32 stack slot can be reloaded into %edi before a direct call
small INTEGER/INTEGER aggregates up to the selected 16-byte `{ i64, i64 }` class return in %rax/%rdx
selected small INTEGER/INTEGER aggregate argument field reads use the SysV integer register pair or stack field locations
the reusable aggregate classifier now distinguishes INTEGER, SSE, mixed INTEGER/SSE, and MEMORY classes for <=16-byte aggregates, with packed/unaligned and too-large aggregates classified as MEMORY
selected nested mixed INTEGER/SSE aggregate field reads and construction returns use layout-backed byte offsets and the independent SysV GPR/SSE streams
selected shifted nested mixed INTEGER/SSE helper calls move both GPR and SSE aggregate halves through the shared register aggregate pass-through helper
selected stack-passed nested mixed INTEGER/SSE aggregate helper calls read nested `i32` fields from caller and callee stack slots through the same layout-derived offsets
selected mixed INTEGER/SSE aggregate low/high `i32`, `i64`, and `double` argument field reads and register returns use the independent SysV GPR/SSE streams
selected reversed mixed SSE/INTEGER aggregate low/high `i32`, `i64`, and `double` argument field reads and register returns use the independent SysV SSE/GPR streams
selected SSE/SSE aggregate argument field reads and register returns use the independent SysV SSE stream, including `[2]f64`, nested double leaves, and `[4]f32` split across two SSE eightbytes
selected shifted SSE/SSE aggregate field reads and helper calls move `double` fields from higher XMM argument registers through the generic XMM move path
selected deep stack-sourced SSE/SSE aggregate helper calls reload `[2]f64` eightbytes from disp32 stack offsets into outgoing XMM argument registers
selected stack-passed SSE/SSE aggregate helper calls load `[4]f32` fields from the caller and callee stack into arbitrary XMM temporaries with `movss`
leaf functions only
no stack frame for register-only leaf functions
```

Call stack rule:

```text
On x86_64 SysV function entry, %rsp % 16 == 8 because the return address has already been pushed.
Immediately before a nested callq, the caller must make %rsp % 16 == 0.
The current project uses a local-only conservative sequence for tiny call fixtures:
  subq $8, %rsp
  callq callee
  addq $8, %rsp
For one live caller argument, the 8-byte alignment slot is also used as a deterministic spill slot.
For the `call_stack_slot` handoff proof, the same fixed slot holds an explicit
i32 alloca value and is reloaded into `%edi` before the direct call.
For one to three live i32 values, the selected call frame uses:
  subq $24, %rsp
  movl %edi, (%rsp)
  movl %esi, 4(%rsp)
  movl %edx, 8(%rsp)
  ... argument setup ...
  callq callee
  movl (%rsp), %edi
  movl 4(%rsp), %esi
  movl 8(%rsp), %edx
  addq $24, %rsp
Four to six live i32 caller arguments use the same fixed-slot model in a
40-byte aligned frame at offsets 0, 4, 8, 12, 16, and 20.
```

Register preservation boundary:

```text
Caller-saved set considered clobbered by calls in this slice:
  %rax, %rcx, %rdx, %rsi, %rdi, %r8, %r9, %r10, %r11
Callee-saved registers are not allocated by this project yet; a focused
backend test keeps the selected allocator limited to `%rdi`, `%rsi`, `%rdx`,
`%rcx`, `%r8`, and `%r9`.
One to six live i32 argument registers across one direct call are accepted.
One live f32/f64 value in %xmm0 across one direct C ABI void call is accepted.
Two to six live f32/f64 values in %xmm0..%xmm5 across one no-argument direct C
ABI void call are accepted for the selected post-call add-return shape.
Stack-passed live i32 values beyond the current selected direct-call/void-call model, SSE
live values beyond the selected one- through six-live f32/f64 no-argument-call
shapes plus selected direct two-/three-/six-live FP-argument call shapes, and
live values across multiple calls beyond selected i32, direct/pointer-callee
two-result i64, selected direct/pointer-callee i64 result live-across-later-void,
selected two-result i64 live-across-later-void, and two-live f32/f64
two-void-call shapes fail
closed.
```

Upstream mapping:

```text
LLVM models x86_64 SysV calling conventions with target lowering tables and call-lowering code.
This project models the selected scalar register/stack assignments, the first
small INTEGER/INTEGER aggregate class, and the first selected MEMORY aggregate
sret/by-value forms needed by the release frontier. The aggregate classifier is
now reusable and records mixed INTEGER/SSE class decisions, but backend lowering
only accepts selected field-read/return forms.
LLVM often emits `pushq %rax`/`popq` around tiny calls at `-O0`; the local `subq`/`addq` sequence has the same stack-alignment purpose for the accepted fixtures.
```

First broader ABI closure wave:

```text
frontier_sysv_abi.Pair64 lowers as the selected small INTEGER/INTEGER class
aggregate return `{ i64, i64 }` uses %rax/%rdx
aggregate argument field 0/1 reads use the SysV integer register pair
register aggregate pass-through calls are supported when the source parameter is already in the exact destination SysV GPR/SSE slots
the reusable SysV planner now counts scalar and classified aggregate call returns as GPR, SSE, or MEMORY returns before row-specific emission
the selected direct-call frame spills and reloads up to six live i32 caller parameters
frontier_sysv_sret_byval.Big3 through Big20 lower as selected normal MEMORY classes:
  `{ i64, i64, i64 }` through the flat thirty-two-field `{ i64, ... }` form return through the hidden sret pointer in %rdi
  user i64 args are shifted through the SysV GPR stream after the hidden pointer
  the seven-field make row reads multiple stack-passed user fields after the hidden pointer
  the typed AIR builder generates field names and sret/byval attrs instead of using a fixed field-count table
  by-value stack aggregate field reads and byval-to-sret copies use layout-derived stack offsets for all scalar integer leaves in these selected normal MEMORY forms
  shape-validated scalar sret stores now cover `i8`, `i16`, `i32`, `i64`,
  pointer, `f32`, and `f64` leaves when every leaf is provided by a matching
  scalar parameter; `ScalarMixed` proves top-level leaves, `ScalarNested`
  proves recursive nested leaves, and `ScalarArray` proves array-backed leaves
  from real typed AIR through executable C ABI validation
  `{ { i64, i64, i64 }, { i64, i64, i64 } }` proves recursive leaf byte-offset reads and copies for nested normal MEMORY aggregates
  `{ i64, i32, i64, i32 }` proves mixed-width MEMORY copies with narrow stores for `i32` leaves
  `{ i8, { i16, i32 }, i64 }` proves nested narrow MEMORY copies with width-correct byte/word loads and stores
  nested `{ i8, { i16, i32 }, i64 }` proves layout-derived byte/word leaf copies use width-correct `%al`/`%ax` stores instead of widening the destination writes
  `{ [5 x i64] }` proves array-backed MEMORY copies and by-value edge field reads use the same integer-leaf byte-offset paths
  the flat `BigN` source type parser now covers larger normal integer-leaf MEMORY aggregates, with `Big20` proving construction, field-read, and byval-to-sret copy rows
  `{ double, double, double }` proves the first double-leaf byval-to-sret MEMORY aggregate copy path through XMM `movsd` stack loads and hidden-sret stores
  `{ [3 x double] }` proves array-contained `f64` MEMORY aggregate copy leaves through the same recursive byval-to-sret path
  `{ [2 x i32], [2 x double], ptr }` proves mixed array-contained integer, array-contained `f64`, and pointer leaves through the same recursive byval-to-sret path
  `{ float, float, float, float, float }` proves `f32` MEMORY aggregate copy leaves through XMM `movss` stack loads and hidden-sret stores
  `{ ptr, double, i64 }` proves mixed pointer/`double`/integer MEMORY aggregate copy leaves through the same layout-derived byte-offset path
frontier_sysv_aggregate_classes.Mixed proves the first mixed INTEGER/SSE
aggregate argument field reads and register aggregate return:
  field `i64` is returned from the aggregate's GPR class register
  field `double` is returned from the aggregate's SSE class register
  `{ i64, double }` construction returns through %rax/%xmm0
  a noinline helper-call row returns `{ i64, double }` directly from the private helper without scalarized wrapper lowering
  stack-passed INTEGER aggregate parameters can now be forwarded into outgoing register aggregate helper calls by loading the source stack eightbytes into the destination GPR pair
  stack-passed INTEGER/INTEGER aggregate parameters can also be forwarded into
  outgoing stack aggregate slots when preceding scalar arguments exhaust the
  callee GPR stream, including incoming aggregates that require disp32
  stack-source reloads
  register-sourced INTEGER/INTEGER aggregates use the same stack destination
  path and are pushed before scalar call arguments are assigned, so source GPRs
  are not clobbered by outgoing `%rdi`/`%rsi` reuse
  register-sourced SSE/SSE aggregates use the same stack destination path by
  materializing each outgoing eightbyte with `sub rsp, 8` plus `movsd` from the
  source XMM register before scalar FP arguments are assigned
  shifted in-register mixed aggregate parameters can move the INTEGER eightbyte
  between GPR argument slots before helper calls when the SSE eightbyte already
  occupies the required destination SSE slot
  stack-passed `{ i64, double }` mixed aggregates can now be forwarded into
  outgoing stack aggregate slots after both the callee GPR and SSE argument
  streams are exhausted, and helper field returns cover both the INTEGER
  eightbyte and the stack-loaded `double` field
frontier_sysv_aggregate_classes.SmallMixed and PackedMixed prove selected
`i32`/`double` mixed INTEGER/SSE field reads:
  low-lane and high-lane `i32` fields are returned from the aggregate's GPR class register
  field `double` is returned from the aggregate's SSE class register
  `{ i32, i32, double }` construction packs adjacent `i32` fields into %rax and returns the `double` in %xmm0
  `{ i64, float }` and `{ float, i64 }` construction returns cover single-f32
  SSE eightbytes in both mixed field orders
frontier_sysv_aggregate_classes.DoublePair proves the first SSE/SSE aggregate
argument field reads and register aggregate return:
  both `double` fields are read from the SysV SSE argument stream
  `{ double, double }` construction returns through %xmm0/%xmm1

frontier_sysv_aggregate_classes.FloatPair proves a single-eightbyte SSE
aggregate:
  `{ float, float }` is classified into one SSE eightbyte
  low/high f32 lane field reads return through %xmm0, with the high lane
    shuffled down before return
  construction packs the two f32 parameters into %xmm0 through the generic
    register aggregate return path
  direct, shifted, and pointer-callee helper calls pass the same f32 pair
    through the SysV SSE argument stream and lower the helper's f32 field-add
    body through generic aggregate field-add lowering

frontier_sysv_aggregate_classes.FloatArray proves a two-eightbyte f32 SSE/SSE
aggregate:
  `[4]f32` typed AIR array-element paths lower through the same aggregate
    field offset machinery
  field reads extract all four f32 lanes from `%xmm0`/`%xmm1`
  construction packs two f32 lanes into each SSE return register
  direct and pointer-callee helper calls preserve the paired SSE eightbytes
    while lowering the helper's four-lane f32 add body generically

frontier_sysv_aggregate_classes.ArrayDouble proves array-in-struct SSE/SSE
aggregate reads and register aggregate return:
  `[2]f64` typed AIR field and pointer-element GEPs lower through the generic
  pointer path
  the two `double` elements are read from the SysV SSE argument stream
  `[2]f64` construction returns through %xmm0/%xmm1

frontier_sysv_aggregate_classes.NestedDouble proves nested SSE/SSE aggregate
reads and register aggregate return:
  `{ { double }, { double } }` typed AIR nested field GEPs lower through
  layout-backed byte offsets
  both `double` leaves are read from the SysV SSE argument stream
  construction returns through %xmm0/%xmm1
frontier_sysv_aggregate_classes.ReverseMixed proves the first reversed
SSE/INTEGER aggregate argument field reads and register aggregate return:
  field `double` is returned from the aggregate's SSE class register
  field `i64` is returned from the aggregate's GPR class register
  `{ double, i64 }` construction returns through %xmm0/%rax
  shifted in-register reversed mixed aggregate parameters can move the SSE
  eightbyte between XMM argument slots before helper calls when the GPR
  eightbyte already occupies the required destination GPR slot
  pointer-callee reversed mixed aggregate calls reuse the same SSE/INTEGER
  planner assignments for arguments and register returns
frontier_sysv_aggregate_classes.SmallReverseMixed and PackedReverseMixed prove
selected reversed `double`/`i32` field reads through the same independent
SSE/GPR streams, including high-lane `i32` extraction and `{ double, i32, i32 }`
construction that packs adjacent `i32` fields into %rax
frontier_sysv_aggregate_classes.NestedPair and NestedMixed prove nested
aggregate field reads and construction:
  nested `{ i32, i32 }` fields are flattened by byte offset
  low/high 32-bit lanes are read from the SysV GPR pair without a
  function-name-specific backend path
  a noinline helper-call row passes `{ { i32, i32 }, { i32, i32 } }` through
  the SysV GPR pair and returns the helper's scalar sum
  `{ { i32, i32 }, { i32, i32 } }` construction returns trace typed AIR v2
  field-pointer store paths and pack both INTEGER eightbytes into %rax/%rdx
  `align(...)` pointer-qualified typed AIR field pointers are accepted for the
  nested mixed `{ { i32, i32 }, double }` row
  the nested mixed row reads INTEGER and SSE fields from independent streams and
  returns construction results through %rax/%xmm0
  shifted nested mixed helper calls move both INTEGER and SSE eightbytes before
  a private helper call
frontier_sysv_aggregate_classes.ArrayPair proves array-in-struct INTEGER
aggregate sums:
  `[2]i64` pointer-element GEPs are lowered from typed AIR v2
  the two i64 fields are read from the SysV GPR pair
  `[2]i64` construction returns trace typed AIR v2 pointer-element stores and
  return the two elements in %rax/%rdx
  after six leading `i64` arguments exhaust the GPR stream, `[2]i64` aggregate
  field reads use stack offsets derived from the same recursive aggregate GEP
  offset helper
frontier_sysv_abi proves the first selected SSE live-across-call frame:
  one live f32/f64 value is spilled from %xmm0 to an aligned frame slot
  another f32/f64 value is passed to an external C ABI void helper
  the saved value is reloaded to %xmm0 for return
  live i32 GPR parameters can be preserved across direct and pointer-callee
  f64-argument void calls through the shared scalar call planner
  two live f32/f64 values can also be spilled from %xmm0/%xmm1 across a
  no-argument external C ABI void helper and reloaded for a post-call fadd
  return
  three live f32/f64 values can also be spilled from %xmm0/%xmm1/%xmm2
  across the same no-argument helper shape and reloaded for a two-step
  post-call fadd return
  four, five, and six live f32/f64 values can also be spilled from
  %xmm0..%xmm5 across the same no-argument helper shape and reloaded for
  three-, four-, and five-step post-call fadd returns
  two live f32/f64 values can also be spilled across a direct void helper call
  that consumes the second live value as its first FP argument
  live i32 GPR parameters can also be preserved across direct and pointer-callee
  void helper calls that consume a named f64 argument
  a direct or pointer-callee C ABI f32/f64 call result and a live FP addend can be
  spilled across a later direct or pointer-callee side-effecting void call and
  reloaded for the final post-call fadd
  a first direct or pointer-callee C ABI f32/f64 call result can also be spilled
  across a second direct or pointer-callee FP-result call and reloaded for the
  final fadd
  a first f32 call result can also be extended to f64 after a second f64
  result call, including direct and pointer-callee variants for either call
  two live f32/f64 values can also be spilled across a no-argument
  pointer-callee void helper call and reloaded for a post-call fadd return
  five named f32/f64 arguments can be forwarded to external C ABI helpers
  through %xmm0..%xmm4; backend unit/object tests materialize immediate FP
  constant arguments through %xmm0..%xmm7
  up to eighteen stack-passed scalar `i32` call arguments are pushed in reverse
  order with 16-byte call-site alignment preserved; the same path can forward
  named incoming stack-passed `i32` parameters by copying their stack slots into
  the outgoing stack argument area or by loading them into outgoing GPR argument
  registers with disp8 or disp32 stack-source reloads, and can materialize
  selected block-local computed `i32` and `i64`
  values through `%eax`/`%rax` before pushing them into outgoing stack slots
  more than six stack-passed live i32/i64 parameters can be reloaded after a direct
  call once the local call frame is restored; current rows prove eight and
  twelve total stack-passed scalar call arguments plus seven, eight, twelve,
  thirteen, fourteen, and eighteen stack-passed live i32 values, plus deep
  stack-passed i32 and i64 reloads through disp32 incoming stack offsets after a
  void call
frontier executable probes validate the aggregate return/argument and call frame in ReleaseFast, ReleaseSafe, and ReleaseSmall
```

Known gaps:

```text
no callee-saved register saves
no full caller-saved clobber model beyond the selected one-to-six-live i32 GPR spill shapes, selected one- through six-live f32/f64 SSE spill shapes, selected f32/f64 register-source argument permutations, selected mixed i32/i64 plus f32/f64 one-GPR/one-SSE frames, selected direct two-/three-/six-live FP-argument call shapes, selected pointer-callee FP call shapes through six live values and five FP helper arguments, selected direct/pointer-callee f32/f64 call-result live-across-later-call frames, selected same-width two-result f32/f64 call frames, selected mixed f32/f64 two-result call frames, selected mixed i64/f64, i64/f32, f64/i64, and f32/i64 two-result call frames, selected direct/pointer-callee i64 result live-across-later-void frames, and selected direct/pointer-callee two-result i64 live-across-later-void frames
no varargs
no vectors
no full lowering for all classified SysV aggregate classes beyond selected INTEGER/INTEGER, nested/array INTEGER construction returns, single-eightbyte `{ f32, f32 }` SSE construction returns and helper-call pass-through, `[2]f64` SSE/SSE array construction returns, nested `{ { double }, { double } }` SSE/SSE construction returns, nested mixed INTEGER/SSE field reads/construction, selected mixed INTEGER/SSE and SSE/INTEGER low/high `i32`, `i64`, and `double` field-read/register forms, selected packed mixed construction returns, and SSE/SSE register forms
no arbitrary MEMORY, X87, packed/unaligned, or complex aggregate ABI classes beyond the selected normal supported-leaf sret/byval forms
no arbitrary non-selected sret/byval copy lowering outside supported `i8`/`i16`/`i32`/`i64`/pointer/`f32`/`f64` leaves; supported `ptr sret(...)` call arguments are assigned as hidden result pointers through the normal GPR planner path
no broad indirect calls beyond selected scalar, register-aggregate, and normal
supported-leaf MEMORY aggregate byval-to-sret forms, tail calls, or unsupported
non-default call conventions
no broader stack-passed or SSE live-across-call spill/reload-heavy call frames beyond the selected stack-passed i32/i64, computed stack-passed i32/i64, one- through six-live f32/f64 no-argument-call shapes, selected f32/f64 register-source argument permutations, selected direct two-/three-/six-live FP-argument call shapes, selected pointer-callee FP call shapes through six live values and five FP helper arguments, selected two-call six-live i32 GPR frame, selected two-call two-live f32/f64 direct and pointer-callee void-call frames, selected direct/pointer-callee f32/f64 call-result live-across-later-call frames, selected same-width and mixed f32/f64 two-result call frames, selected mixed i64/f64, i64/f32, f64/i64, and f32/i64 two-result call frames, selected direct/pointer-callee i64 result live-across-later-void frames, selected direct/pointer-callee two-result i64 live-across-later-void frames, and selected mixed i32/i64 one-GPR/one-SSE live one-/two-call direct/pointer-callee void-call frames
stack-passed live integer pressure beyond the current selected scheduling model is rejected explicitly rather than guessed
integer and pointer cyclic GPR argument shuffles use a generic push/pop
parallel-copy path for register-source call arguments; mixed non-register
source cycles remain explicitly rejected until a broader parallel-copy planner
is implemented
f32/f64 register-source argument shuffles use a generic XMM temporary-stack
copy path; mixed constant/stack-source XMM cycles remain explicitly rejected
until the broader planner handles non-register sources
```

## Remaining Blocker Table

This table is the single status list for the x86_64 SysV ABI/codegen frontier.
Accepted rows must be AIR-owned, typed-v2 lowered, generic-CFG codegen rows; a
row listed as a boundary must reject with a targeted diagnostic instead of
falling into a generic unsupported bucket.

| Blocker | Status | Current evidence / next implementation |
| --- | --- | --- |
| Varargs | Fail-closed boundary | Parser preserves varargs declarations/calls; x86_64 codegen rejects direct and function-pointer varargs calls with `UnsupportedVarargsAbi`. Varargs are excluded from the current x86_64 release replacement claim because the SysV `%al` SSE-count and register-save-area policy is not yet owned locally. |
| Vectors | Fail-closed boundary | Vector IR parse/verify coverage exists; x86_64 call/return codegen rejects scalar vector ABI forms, vector-containing aggregate ABI forms, and vector-bearing `sret`/`byval` payloads with `UnsupportedVectorAbi` before data-layout classification. Vector ABI is excluded from the current release replacement claim until a fixed SSE-register subset is implemented deliberately. |
| Arbitrary sret | Partially implemented | Normal supported-leaf MEMORY aggregate sret rows are proven for flat, nested, mixed-width, array-backed, `f32`, `double`, array-contained `double`, mixed array/pointer, and pointer/`double`/integer selected forms, including selected direct and indirect byval-to-sret calls for flat, nested, mixed-width, array-backed, pure-FP, and mixed pointer/FP/integer aggregates. The call planner accepts supported `ptr sret(...)` call arguments as hidden result pointers through the normal GPR argument path, including register-sourced and incoming-stack-sourced hidden result pointers, shifted user arguments that overflow into outgoing stack slots for both direct and function-pointer calls, and the current spill/reload helper preserves a selected live `i32` GPR across direct and function-pointer sret-pointer calls with or without outgoing stack arguments. The current layout-derived copy path supports `i8`, `i16`, `i32`, `i64`, pointer, `f32`, and `f64` leaves, and the `ScalarMixed`/`ScalarNested`/`ScalarArray` direct scalar-param-to-sret source rows support top-level, nested, and array-backed supported leaves. Next implementation is broader arbitrary MEMORY aggregate copy/storage for packed, unaligned, X87, vector, and other unsupported leaves. |
| Arbitrary byval | Partially implemented | Normal supported-leaf byval reads/copies are layout-derived for selected MEMORY aggregates, including `i8`, `i16`, `i32`, `i64`, pointer, `f32`, `double`, array-contained `double`, and mixed array/pointer leaves; selected direct and indirect MEMORY aggregate calls copy by-value stack slots into outgoing stack slots before call. The call planner now also accepts explicit `ptr byval(aggregate)` call arguments for supported aggregate payloads and emits an outgoing stack copy from register- or stack-sourced source pointers for direct and function-pointer calls, with unit proof for one-, two-, array-backed three-, nested three-, single-`i8`, single-`i16`, single-`i32`, `[3 x i32]` 4-byte-tail, composite 3-/5-/6-/7-byte tails, and max-sized exact-eightbyte payloads through the current 32-stack-argument limit. Source-owned executable frontier rows now prove `[17 x i8]`, `[21 x i8]`, `[22 x i8]`, `[23 x i8]`, `[9 x i16]`, and flat 32-eightbyte MEMORY byval-to-sret copies through direct and function-pointer calls. Function-pointer byval calls reload the callee into `%rax` after payload stack-copy loads so the call target is preserved, including selected live-`i32` spill/reload frames when the payload pointer arrives in either a GPR or an incoming stack slot. Next implementation is a general byval placement/copy path for unsupported layouts, alignments, packed/unaligned payloads, X87, vector leaves, and other unsupported aggregate forms. |
| Broader aggregate classes | Partially implemented | The reusable classifier handles INTEGER, SSE, mixed INTEGER/SSE, and MEMORY decisions for <=16-byte aggregates; the central call planner assigns register aggregates and normal MEMORY aggregate by-value arguments through the same direct/indirect path. Backend lowering accepts selected register and MEMORY forms, including single-eightbyte `{ f32, f32 }` SSE aggregate field reads/returns, mixed `double`/single-`float` SSE/SSE returns, and direct/shifted/indirect helper-call pass-through, stack-sourced INTEGER aggregate forwarding into GPR aggregate helper calls, stack-sourced SSE/SSE aggregate forwarding into XMM aggregate helper calls including disp32 stack-source reloads, stack-sourced mixed INTEGER/SSE aggregate forwarding into GPR/XMM aggregate helper calls for direct and pointer-callee calls, shifted in-register mixed aggregate GPR movement, shifted in-register reversed mixed aggregate SSE movement, pointer-callee reversed mixed SSE/INTEGER aggregate argument/return movement, and normal MEMORY stack passthrough. Next implementation is completing backend lowering for every planner-supported classified aggregate return and unsupported leaf layout. |
| Packed/unaligned aggregates | Fail-closed boundary | Packed aggregate call/return forms reject with `UnsupportedPackedAggregateAbi`; the parser rejects textual packed aggregate signatures and the SysV planner rejects direct packed call/return type inputs plus packed `sret`/`byval` payloads before they fall into the generic sret/byval boundary. Packed and unaligned aggregate ABI is excluded from the current release replacement claim unless represented by already selected scalar field paths; support requires layout-aware unaligned load/store/copy decisions. |
| X87 / long double | Fail-closed boundary | `x86_fp80`, `fp128`, X87-like classes, aggregates containing long-double leaves, and long-double `sret`/`byval` payloads reject with `UnsupportedLongDoubleAbi`. X87/long-double ABI is excluded from the current release replacement claim. |
| Indirect calls | Partially implemented | Function-pointer calls are accepted when typed AIR v2 exposes operand 0 as a pointer callee and arguments/returns are supported by the SysV planner. The frontier proves `i32` returns with incoming stack `i32` parameters loaded into outgoing GPR call slots, 12-, 14-, and 24-argument `i32` forwarding through outgoing stack slots, selected `f32`/`f64` calls returning through `%xmm0` with five SSE arguments, selected `i64` register/stack forwarding, selected INTEGER/INTEGER aggregate arguments/returns in GPR pairs, selected nested and array-in-struct INTEGER/INTEGER aggregate argument forwarding through function pointers, selected SSE/SSE `[2]f64` aggregate arguments/returns in XMM pairs, selected single-eightbyte `{ f32, f32 }` aggregate argument forwarding through the SSE stream, normal supported-leaf MEMORY aggregate byval-to-sret indirect calls through the hidden sret pointer, explicit byval stack-copy calls that preserve the pointer callee after payload loads including a selected live-`i32` frame, selected live `i32` values preserved across an indirect call through the shared spill/reload frame, selected indirect ordered-call result paths including second-call, later-void, and first-call pointer-callee variants, and selected live `f32`/`f64` values preserved across zero-, one-, two-, three-, or five-FP-argument indirect calls through the FP spill/reload frame. Varargs, tail calls, unsupported live-across-call mixes outside the selected GPR/SSE/byval frames, unsupported MEMORY aggregate leaves/layouts, and unsupported aggregate classes remain fail-closed boundaries. |
| Tail calls | Fail-closed boundary | Tail, musttail, and notail markers reject with `UnsupportedTailCallAbi`. Tail-call ABI is excluded from the current release replacement claim until normal call-frame ownership is broader. |
| Non-default call conventions | Fail-closed boundary | Unsupported call conventions reject with `UnsupportedCallConvAbi`. Current release rows remain default C/Zig-compatible only; any additional call convention needs a deliberate per-callconv policy table. |
| Full caller-saved handling | Partially implemented | Selected GPR and SSE live-across-call shapes spill/reload through explicit frame slots. Next implementation is liveness-driven caller-saved clobber assignment for arbitrary live scalar values across calls. |
| Callee-saved handling | Fail-closed boundary | The allocator currently avoids callee-saved registers; tests document the policy. Callee-saved allocation remains outside the current claim, and prologue/epilogue save/restore must be implemented before those registers can enter allocation. |
| More than six stack-passed live values | Implemented selected subset | Current rows prove up to eighteen outgoing stack-passed scalar `i32` call arguments, selected block-local computed `i32`/`i64` stack call arguments, named incoming stack-parameter forwarding for stack call slots, stack-parameter assignment into outgoing GPR argument registers with disp8/disp32 stack-source reloads, seven/eight/twelve/thirteen/fourteen/eighteen stack-passed live `i32` values via cursor-derived incoming stack offsets, direct deep stack `i64` and pointer returns, and deep post-call stack `i32`/`i64`/pointer reloads through disp32 incoming stack offsets. Remaining boundary is pressure beyond the backend's selected live-value scheduling model and computed outgoing stack values outside the selected integer add-immediate forms. |
| Broader SSE live-across-call | Partially implemented | Up to six no-argument-call live `f32`/`f64` values, selected direct stack-passed `f32`/`f64` parameter returns and selected stack-passed live `f32`/`f64` reloads through a disp32 incoming stack offset after a void call, selected repeated two-live direct and pointer-callee no-argument calls, selected direct two-/three-/six-live FP-argument calls, selected pointer-callee calls through six live values and five FP helper arguments, selected f32/f64 register-source argument permutations through planner-owned temporary stack copies for direct and pointer-callee calls, selected mixed i32/i64 one-GPR/one-SSE direct and pointer-callee void-call frames, and selected mixed-width FP two-result frames with one live `double` or `i64` addend are supported. Next implementation is a general SSE caller-saved live-range spill/reload model. |
| Multi-call live-value frames | Partially implemented | Generic CFG accepts selected straight-line direct and pointer-callee void-call sequences with up to six live `i32` GPR parameters across two calls, spilling/reloading through the shared live-param frame helper for each call. It also accepts selected two-live `f32`/`f64` values across two direct or pointer-callee no-argument `void` calls, selected mixed i32/i64 one-GPR/one-SSE values across one or two direct or pointer-callee `void` calls, and selected ordered `i32` result cases: a first C ABI `i32` call result plus live `i32` parameter across a later side-effecting `void` call, a first C ABI `i32` result across a second C ABI `i32` call whose scalar argument is assigned by the call planner, the pointer-callee variant where the second call target and argument are preserved across the first call then reloaded for `callq *%rax`, two ordered `i32` call results preserved across a later side-effecting `void` call, the pointer-callee variant of that later `void` call, and pointer-callee variants of the first ordered `i32` call, second ordered `i32` call, or both ordered `i32` calls with non-overlapping saved pointer-callee slots. Selected i64 result frames preserve one direct/pointer-callee `i64` result plus a live addend across a later direct/pointer-callee `void` call, selected two-result i64 frames preserve both `%rax` results across a later direct/pointer-callee `void` call, selected two-result i64 frames with a live addend preserve the second call target/argument plus the independent live addend across both non-void calls, and selected mixed i64/f64, i64/f32, f64/i64, and f32/i64 result frames preserve `%rax`, the FP result or argument, and any second pointer callee across both non-void calls. Selected FP result frames preserve one direct or pointer-callee `f64` result across a later direct/pointer-callee `void` call, across a second direct/pointer-callee `f64` result call, or across a mixed `float`/`double` two-result sequence with one independent live `double` or `i64` addend. Remaining boundary is arbitrary multi-call scheduling with mixed GPR/SSE/stack live values and non-void intermediate results beyond those selected direct/indirect/later-void `i32` result shapes, selected i64 result frames, and selected FP/mixed live frames. |
