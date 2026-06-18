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
f32/f64 arguments use the independent SysV SSE stream (%xmm0, %xmm1 for the current selected rows)
i1 branch conditions use the matching low 8-bit argument registers
i32/i64/pointer direct-call operands use the first-six integer argument register order
f32/f64 direct-call operands use the independent SSE register order
up to three constant i32 stack-passed direct-call arguments are supported
direct calls preserve SysV stack alignment by subtracting 8 from %rsp before callq and adding it back after the call
one live i32 caller argument can be spilled to (%rsp) across one call
up to six live i32 caller arguments can be spilled into aligned frame slots and reloaded after one direct call
one live f32/f64 caller argument can be spilled from %xmm0 into an aligned
frame slot, reloaded after one direct C ABI void call, and returned from %xmm0
two live f32/f64 caller arguments can be spilled from %xmm0/%xmm1 into aligned
frame slots across one no-argument direct C ABI void call and reloaded for a
post-call fadd return
one fixed i32 stack slot can be reloaded into %edi before a direct call
small INTEGER/INTEGER aggregates up to the selected 16-byte `{ i64, i64 }` class return in %rax/%rdx
selected small INTEGER/INTEGER aggregate argument field reads use the SysV integer register pair or stack field locations
the reusable aggregate classifier now distinguishes INTEGER, SSE, mixed INTEGER/SSE, and MEMORY classes for <=16-byte aggregates, with packed/unaligned and too-large aggregates classified as MEMORY
selected nested mixed INTEGER/SSE aggregate integer-field add chains use layout-backed byte offsets and the independent SysV GPR/SSE streams
selected mixed INTEGER/SSE aggregate argument field reads and register returns use the independent SysV GPR/SSE streams
selected reversed mixed SSE/INTEGER aggregate argument field reads and register returns use the independent SysV SSE/GPR streams
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
Callee-saved registers are not allocated by this project yet.
One to six live i32 argument registers across one direct call are accepted.
One live f32/f64 value in %xmm0 across one direct C ABI void call is accepted.
Two live f32/f64 values in %xmm0/%xmm1 across one no-argument direct C ABI void
call are accepted for the selected post-call add-return shape.
Stack-passed live values, broader SSE live values, and live values across multiple calls fail closed.
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
the selected direct-call frame spills and reloads up to six live i32 caller parameters
frontier_sysv_sret_byval.Big3 through Big7 lower as selected normal MEMORY classes:
  `{ i64, i64, i64 }` through `{ i64, i64, i64, i64, i64, i64, i64 }` returns store through the hidden sret pointer in %rdi
  user i64 args are shifted through the SysV GPR stream after the hidden pointer
  the seven-field make row reads multiple stack-passed user fields after the hidden pointer
  the typed AIR builder generates field names and sret/byval attrs instead of using a fixed field-count table
  by-value stack aggregate field reads and byval-to-sret copies use layout-derived stack offsets for all fields in these selected normal i64 MEMORY forms
frontier_sysv_aggregate_classes.Mixed proves the first mixed INTEGER/SSE
aggregate argument field reads and register aggregate return:
  field `i64` is returned from the aggregate's GPR class register
  field `double` is returned from the aggregate's SSE class register
  `{ i64, double }` construction returns through %rax/%xmm0
frontier_sysv_aggregate_classes.DoublePair proves the first SSE/SSE aggregate
argument field reads and register aggregate return:
  both `double` fields are read from the SysV SSE argument stream
  `{ double, double }` construction returns through %xmm0/%xmm1
frontier_sysv_aggregate_classes.ReverseMixed proves the first reversed
SSE/INTEGER aggregate argument field reads and register aggregate return:
  field `double` is returned from the aggregate's SSE class register
  field `i64` is returned from the aggregate's GPR class register
  `{ double, i64 }` construction returns through %xmm0/%rax
frontier_sysv_aggregate_classes.NestedPair and NestedMixed prove nested
INTEGER aggregate field add chains:
  nested `{ i32, i32 }` fields are flattened by byte offset
  low/high 32-bit lanes are read from the SysV GPR pair without a
  function-name-specific backend path
  `align(...)` pointer-qualified typed AIR field pointers are accepted for the
  nested mixed `{ { i32, i32 }, double }` row while preserving its SSE field
  classification
frontier_sysv_aggregate_classes.ArrayPair proves array-in-struct INTEGER
aggregate sums:
  `[2]i64` pointer-element GEPs are lowered from typed AIR v2
  the two i64 fields are read from the SysV GPR pair
frontier_sysv_abi proves the first selected SSE live-across-call frame:
  one live f32/f64 value is spilled from %xmm0 to an aligned frame slot
  another f32/f64 value is passed to an external C ABI void helper
  the saved value is reloaded to %xmm0 for return
  two live f32/f64 values can also be spilled from %xmm0/%xmm1 across a
  no-argument external C ABI void helper and reloaded for a post-call fadd
  return
frontier executable probes validate the aggregate return/argument and call frame in ReleaseFast, ReleaseSafe, and ReleaseSmall
```

Known gaps:

```text
no callee-saved register saves
no full caller-saved clobber model beyond the selected one-to-six-live i32 GPR spill shapes, selected one-live f32/f64 SSE spill shape, and selected two-live f32/f64 no-argument-call spill shape
no varargs
no vectors
no full lowering for all classified SysV aggregate classes beyond selected INTEGER/INTEGER, nested mixed INTEGER/SSE integer-field add chains, mixed INTEGER/SSE, SSE/INTEGER, and SSE/SSE register forms
no arbitrary MEMORY, X87, packed/unaligned, or complex aggregate ABI classes beyond the selected normal i64 sret/byval forms
no arbitrary non-selected sret/byval copy lowering
no indirect calls, tail calls, or unsupported non-default call conventions
no stack-passed or broader SSE live-across-call spill/reload-heavy call frames
```
