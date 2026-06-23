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
i64 and pointer-class return values in %rax for selected rows
f32/f64 return values in %xmm0 for selected rows
first six integer/pointer-class register arguments are recognized as %edi, %esi, %edx, %ecx, %r8d, and %r9d for i32 values
i64/pointer-class arguments use the corresponding 64-bit GPR view for selected rows
f32/f64 arguments use the independent SysV SSE stream; named source-frontier
proof currently reaches %xmm0..%xmm4, and backend constant materialization
reaches %xmm0..%xmm7
i1 branch conditions use the matching low 8-bit argument registers
i32/i64/pointer direct-call operands use the first-six integer argument register order
f32/f64 direct-call operands use the independent SSE register order
up to twelve scalar i32/i64 stack-passed direct-call arguments are supported, including constants, named incoming stack/register parameters, and selected block-local computed i32/i64 values
direct calls preserve SysV stack alignment by subtracting 8 from %rsp before callq and adding it back after the call
one live i32 caller argument can be spilled to (%rsp) across one call
up to six live i32 caller arguments can be spilled into aligned frame slots and reloaded after one direct call
more than six stack-passed live i32 caller arguments can be added after the
call once the local call frame is restored, within the backend's current
disp8-safe incoming stack offset model
one live f32/f64 caller argument can be spilled from %xmm0 into an aligned
frame slot, reloaded after one direct C ABI void call, and returned from %xmm0
two or three live f32/f64 caller arguments can be spilled from %xmm0/%xmm1
or %xmm0/%xmm1/%xmm2 into aligned frame slots across one no-argument direct
C ABI void call and reloaded for post-call fadd returns
one fixed i32 stack slot can be reloaded into %edi before a direct call
small INTEGER/INTEGER aggregates up to the selected 16-byte `{ i64, i64 }` class return in %rax/%rdx
selected small INTEGER/INTEGER aggregate argument field reads use the SysV integer register pair or stack field locations
the reusable aggregate classifier now distinguishes INTEGER, SSE, mixed INTEGER/SSE, and MEMORY classes for <=16-byte aggregates, with packed/unaligned and too-large aggregates classified as MEMORY
selected nested mixed INTEGER/SSE aggregate field reads and construction returns use layout-backed byte offsets and the independent SysV GPR/SSE streams
selected mixed INTEGER/SSE aggregate low/high `i32`, `i64`, and `double` argument field reads and register returns use the independent SysV GPR/SSE streams
selected reversed mixed SSE/INTEGER aggregate low/high `i32`, `i64`, and `double` argument field reads and register returns use the independent SysV SSE/GPR streams
selected SSE/SSE aggregate argument field reads and register returns use the independent SysV SSE stream
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
Stack-passed live i32 values beyond the current disp8-safe selected model, SSE
live values beyond the selected one- through six-live f32/f64 no-argument-call shapes plus the
two-live FP-argument call shape, and live values across multiple calls fail
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
  `{ i64, i64, i64 }` through the flat twenty-field `{ i64, ... }` form return through the hidden sret pointer in %rdi
  user i64 args are shifted through the SysV GPR stream after the hidden pointer
  the seven-field make row reads multiple stack-passed user fields after the hidden pointer
  the typed AIR builder generates field names and sret/byval attrs instead of using a fixed field-count table
  by-value stack aggregate field reads and byval-to-sret copies use layout-derived stack offsets for all scalar integer leaves in these selected normal MEMORY forms
  `{ { i64, i64, i64 }, { i64, i64, i64 } }` proves recursive leaf byte-offset reads and copies for nested normal MEMORY aggregates
  `{ i64, i32, i64, i32 }` proves mixed-width MEMORY copies with narrow stores for `i32` leaves
  `{ [5 x i64] }` proves array-backed MEMORY copies and by-value edge field reads use the same integer-leaf byte-offset paths
  the flat `BigN` source type parser now covers larger normal integer-leaf MEMORY aggregates, with `Big20` proving construction, field-read, and byval-to-sret copy rows
  `{ double, double, double }` proves the first double-leaf byval-to-sret MEMORY aggregate copy path through XMM `movsd` stack loads and hidden-sret stores
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
  callee GPR stream
  register-sourced INTEGER/INTEGER aggregates use the same stack destination
  path and are pushed before scalar call arguments are assigned, so source GPRs
  are not clobbered by outgoing `%rdi`/`%rsi` reuse
  register-sourced SSE/SSE aggregates use the same stack destination path by
  materializing each outgoing eightbyte with `sub rsp, 8` plus `movsd` from the
  source XMM register before scalar FP arguments are assigned
  shifted in-register mixed aggregate parameters can move the INTEGER eightbyte
  between GPR argument slots before helper calls when the SSE eightbyte already
  occupies the required destination SSE slot
frontier_sysv_aggregate_classes.SmallMixed and PackedMixed prove selected
`i32`/`double` mixed INTEGER/SSE field reads:
  low-lane and high-lane `i32` fields are returned from the aggregate's GPR class register
  field `double` is returned from the aggregate's SSE class register
  `{ i32, i32, double }` construction packs adjacent `i32` fields into %rax and returns the `double` in %xmm0
frontier_sysv_aggregate_classes.DoublePair proves the first SSE/SSE aggregate
argument field reads and register aggregate return:
  both `double` fields are read from the SysV SSE argument stream
  `{ double, double }` construction returns through %xmm0/%xmm1
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
  five named f32/f64 arguments can be forwarded to external C ABI helpers
  through %xmm0..%xmm4; backend unit/object tests materialize immediate FP
  constant arguments through %xmm0..%xmm7
  up to twelve stack-passed scalar `i32` call arguments are pushed in reverse order
  with 16-byte call-site alignment preserved; the same path can forward named
  incoming stack-passed `i32` parameters by copying their stack slots into the
  outgoing stack argument area or by loading them into outgoing GPR argument
  registers, and can materialize selected block-local computed `i32` and `i64`
  values through `%eax`/`%rax` before pushing them into outgoing stack slots
  more than six stack-passed live i32 parameters can be added after a direct
  call once the local call frame is restored; current rows prove eight and
  twelve stack-passed live i32 values
frontier executable probes validate the aggregate return/argument and call frame in ReleaseFast, ReleaseSafe, and ReleaseSmall
```

Known gaps:

```text
no callee-saved register saves
no full caller-saved clobber model beyond the selected one-to-six-live i32 GPR spill shapes, selected one- through six-live f32/f64 SSE spill shapes, and selected two-live FP-argument call shape
no varargs
no vectors
no full lowering for all classified SysV aggregate classes beyond selected INTEGER/INTEGER, nested/array INTEGER construction returns, `[2]f64` SSE/SSE array construction returns, nested `{ { double }, { double } }` SSE/SSE construction returns, nested mixed INTEGER/SSE field reads/construction, selected mixed INTEGER/SSE and SSE/INTEGER low/high `i32`, `i64`, and `double` field-read/register forms, selected packed mixed construction returns, and SSE/SSE register forms
no arbitrary MEMORY, X87, packed/unaligned, or complex aggregate ABI classes beyond the selected normal supported-leaf sret/byval forms
no arbitrary non-selected sret/byval copy lowering outside supported `i32`/`i64`/pointer/`f64` leaves
no broad indirect calls beyond selected scalar, register-aggregate, and normal
supported-leaf MEMORY aggregate byval-to-sret forms, tail calls, or unsupported
non-default call conventions
no broader stack-passed or SSE live-across-call spill/reload-heavy call frames beyond the selected disp8-safe stack-passed i32/i64, computed stack-passed i32/i64, one- through six-live f32/f64 no-argument-call shapes, two-live FP-argument call shape, and selected two-call six-live i32 GPR frame
stack-passed live integer pressure beyond the current disp8-safe incoming stack offset model is rejected explicitly rather than guessed
```

## Remaining Blocker Table

This table is the single status list for the x86_64 SysV ABI/codegen frontier.
Accepted rows must be AIR-owned, typed-v2 lowered, generic-CFG codegen rows; a
row listed as a boundary must reject with a targeted diagnostic instead of
falling into a generic unsupported bucket.

| Blocker | Status | Current evidence / next implementation |
| --- | --- | --- |
| Varargs | Fail-closed boundary | Parser preserves varargs declarations/calls; x86_64 codegen rejects varargs with `UnsupportedCodegenAbi`. Next implementation is a dedicated SysV varargs call planner including `%al` SSE-count and register-save-area policy. |
| Vectors | Fail-closed boundary | Vector IR parse/verify coverage exists; x86_64 call/return codegen rejects vector ABI forms. Next implementation is either a fixed SSE-register subset or a permanent explicit boundary for release replacement rows. |
| Arbitrary sret | Partially implemented | Normal supported-leaf MEMORY aggregate sret rows are proven for flat, nested, mixed-width, array-backed, `f32`, `double`, and pointer/`double`/integer selected forms. The current layout-derived copy path supports `i32`, `i64`, pointer, `f32`, and `f64` leaves. Next implementation is broader arbitrary MEMORY aggregate copy/storage for packed, unaligned, X87, vector, and other unsupported leaves. |
| Arbitrary byval | Partially implemented | Normal supported-leaf byval reads/copies are layout-derived for selected MEMORY aggregates, including `f32`, pointer, and `double` leaves. Next implementation is a general byval placement/copy path for unsupported layouts and alignments. |
| Broader aggregate classes | Partially implemented | The reusable classifier handles INTEGER, SSE, mixed INTEGER/SSE, and MEMORY decisions for <=16-byte aggregates; backend lowering accepts selected register and MEMORY forms, including stack-sourced INTEGER aggregate forwarding into GPR aggregate helper calls, stack-sourced SSE/SSE aggregate forwarding into XMM aggregate helper calls, shifted in-register mixed aggregate GPR movement, and shifted in-register reversed mixed aggregate SSE movement. Next implementation is a central call planner that assigns all supported classified aggregate args/returns. |
| Packed/unaligned aggregates | Fail-closed boundary | Packed/unaligned aggregate ABI classes are classified as MEMORY/rejected unless represented by already selected scalar field paths. Next implementation requires layout-aware unaligned load/store/copy decisions. |
| X87 / long double | Fail-closed boundary | `x86_fp80` and X87-like classes are not accepted by local codegen. Next implementation is deferred; rows must remain explicit runtime/ABI boundaries. |
| Indirect calls | Partially implemented | Function-pointer calls are accepted when typed AIR v2 exposes operand 0 as a pointer callee and arguments/returns are supported by the SysV planner. The frontier proves `i32` returns with incoming stack `i32` parameters loaded into outgoing GPR call slots, 12-argument and 14-argument `i32` forwarding through outgoing stack slots, selected `f32`/`f64` calls returning through `%xmm0` with five SSE arguments, selected `i64` register/stack forwarding, selected INTEGER/INTEGER aggregate arguments/returns in GPR pairs, selected SSE/SSE `[2]f64` aggregate arguments/returns in XMM pairs, normal supported-leaf MEMORY aggregate byval-to-sret indirect calls through the hidden sret pointer, and selected live `i32` values preserved across an indirect call through the shared spill/reload frame. Varargs, tail calls, unsupported live-across-call mixes, unsupported MEMORY aggregate leaves/layouts, and unsupported aggregate classes remain fail-closed boundaries. |
| Tail calls | Fail-closed boundary | Tail, musttail, and notail markers are rejected. Next implementation is deferred until normal call-frame ownership is broader. |
| Non-default call conventions | Fail-closed boundary | Unsupported call conventions reject with `UnsupportedCodegenAbi`. Next implementation is a per-callconv policy table; release rows remain default C/Zig-compatible only. |
| Full caller-saved handling | Partially implemented | Selected GPR and SSE live-across-call shapes spill/reload through explicit frame slots. Next implementation is liveness-driven caller-saved clobber assignment for arbitrary live scalar values across calls. |
| Callee-saved handling | Fail-closed boundary | The allocator currently avoids callee-saved registers; tests document the policy. Next implementation is prologue/epilogue save/restore when allocation starts using them. |
| More than six stack-passed live values | Implemented selected subset | Current rows prove eight and twelve outgoing stack-passed scalar `i32` call arguments, selected block-local computed `i32`/`i64` stack call arguments, named incoming stack-parameter forwarding for stack call slots, stack-parameter assignment into outgoing GPR call registers for `i32` and `i64`, and eight/twelve stack-passed live `i32` values via cursor-derived incoming stack offsets. Remaining boundary is pressure beyond the backend's disp8-safe stack offset model and computed outgoing stack values outside the selected integer add-immediate forms. |
| Broader SSE live-across-call | Partially implemented | Up to six no-argument-call live `f32`/`f64` values and selected two-live FP-argument calls are supported. Next implementation is a general SSE caller-saved live-range spill/reload model. |
| Multi-call live-value frames | Partially implemented | Generic CFG accepts selected straight-line void-call sequences with up to six live `i32` GPR parameters across two calls, spilling/reloading through the shared live-param frame helper for each call. Remaining boundary is arbitrary multi-call scheduling with mixed GPR/SSE/stack live values and non-void intermediate results. |
