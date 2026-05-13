# Native Backend Handoff Validation Matrix

This matrix ties accepted optimizer facts to Zig-native backend questions. It is
not a backend implementation plan; it is a regression map for deciding whether a
local LLVM-compatible optimization should feed Zig-owned AIR/native backend work
or remain LLVM-compatibility-only.

## Validation Fixtures

| Area | Local fixture | Validation command | Zig-native handoff question |
| --- | --- | --- | --- |
| Scalar canonicalization | `test/opt/inputs/instcombine_safe_scalar.ll` | `zig build run -- --passes=instcombine,dce ...` | Should Sema/AIR or native instruction selection learn the same safe scalar identities? |
| Memory/store cleanup | `test/opt/inputs/dse_overwrite.ll` | `zig build run -- --passes=dse ...` | Can the native path prove overwritten stack stores are unobservable before codegen? |
| Loop scalar motion | `test/opt/inputs/licm_invariant.ll` | `zig build run -- --passes=licm ...` | Can AIR loop lowering or native MIR represent pure invariants without unsafe live-range growth? |
| Global cleanup | `test/opt/inputs/globaldce_basic.ll` | `zig build run -- --passes=globaldce ...` | Which global liveness facts belong in Zig-owned global analysis instead of backend lowering? |
| Optimized scalar codegen handoff | `test/handoff/inputs/scalar_add_zero.ll` | `bash scripts/run_handoff_validation.sh` | Can an LLVM-equivalent scalar canonicalization result pass through local x86_64 assembly/object emission with the same instruction bytes as LLVM `llc`? |
| Tiny x86_64 backend smoke | `test/codegen/inputs/add_args.ll` and related codegen inputs | `bash scripts/compare_codegen_asm.sh` | Do target/ABI and Machine IR assumptions still produce inspectable assembly for tiny accepted shapes? |
| Explicit scalar return handoff | `test/codegen/inputs/return_constant.ll` | `bash scripts/run_handoff_validation.sh` | Can a folded scalar value reach return lowering without extra LLVM-only structure? |
| Explicit direct-call handoff | `test/codegen/inputs/call_one_arg.ll` | `bash scripts/run_handoff_validation.sh` | Are direct scalar calls represented at the handoff boundary without pulling in register allocation policy? |
| Explicit stack-slot handoff | `test/codegen/inputs/stack_slot.ll` | `bash scripts/run_handoff_validation.sh` | Can fixed local stack slots be validated independently from LLVM alloca promotion? |
| Explicit stack-memory-to-call handoff | `test/codegen/inputs/call_stack_slot.ll` | `bash scripts/run_handoff_validation.sh` | Can a fixed local stack slot feed a direct scalar call while preserving SysV call alignment? |

Run all current handoff checks with:

```sh
bash scripts/run_handoff_validation.sh
```

For the optimized scalar codegen handoff row, the script compares local
optimized IR with `opt-22`, then compares local object disassembly with
`llc-22` object disassembly. Other rows deliberately compare local optimizer
outputs against checked local fixtures, not against broad Zig native backend
output. A direct Zig-native comparison should be added only when the same Zig
source shape can be compiled through a selected native backend with stable
output expectations.

LLVM source anchors for the optimized handoff row:

```text
llvm/lib/Passes/PassBuilderPipelines.cpp: optimizer pipeline construction
llvm/lib/CodeGen/TargetPassConfig.cpp: target codegen pass pipeline ownership
llvm/lib/Target/X86/X86ISelLowering.cpp: x86_64 target lowering
llvm/lib/Target/X86/X86InstrInfo.td: x86 instruction selection descriptions
llvm/lib/Target/X86/X86AsmPrinter.cpp: assembly/object emission boundary
```

## Handoff Classification

| Optimizer fact | Handoff classification | Reason |
| --- | --- | --- |
| Verifier dominance, use-before-def, and PHI validity | semantic validation | These facts prove local rewrites preserve SSA-like value availability, but Zig native backends use AIR ordering and Liveness rather than LLVM PHIs. |
| InstCombine and InstSimplify scalar folds | possible Zig optimizer input | Safe scalar identities may belong in Sema/AIR or a Zig-owned optimizer if they improve release native output. |
| SimplifyCFG and SCCP branch pruning | possible Zig optimizer input | Branch pruning can reduce native backend work, but the native representation need not mirror LLVM block structure. |
| Mem2Reg and SROA stack cleanup | semantic fixture source | Useful for proving stack traffic can disappear, but Zig native backends should not adopt LLVM alloca/GEP mechanics. |
| DCE, ADCE, DSE, EarlyCSE, and GVN memory facts | legality contract | Side-effect and alias facts must be explicit before any native handoff; MemorySSA-level precision remains future work. |
| LoopInfo and LICM scalar hoisting | handoff study | Pure scalar loop facts can guide AIR/MIR optimization, while memory LICM remains blocked on alias and MemorySSA precision. |
| Target triple, DataLayout, and scalar ABI | hard backend precondition | Native lowering, MC validation, and object metadata must agree before backend comparison is meaningful. |
| Assembly/object experiments | validation-only | They prove tiny target assumptions; they do not replace Zig's native backends or linkers. |

## LLVM-IR-Specific Facts

These facts should not be ported directly into Zig's native path:

```text
LLVM PHI node shape as a required backend input
LLVM alloca promotion mechanics as the native stack model
LLVM GEP slicing as the native aggregate model
LLVM metadata graphs as optimizer legality unless a Zig mode requires them
LLVM pass pipeline names as the native optimizer architecture
LLVM call-site metadata as the native call representation
```

## Target And ABI Blockers

Before this project can make stronger handoff claims, these blockers need their
own source-backed slices:

```text
multi-target ABI classification beyond scalar integer and pointer cases
aggregate, vector, and byval/byref calling convention lowering
stack alignment and red-zone policy beyond tiny x86_64 fixtures
debug/unwind metadata preservation through backend emission
atomic, volatile, inline asm, and concurrency barriers in codegen
object/linker ownership boundaries for relocations, COMDAT, TLS, and sections
```

## Next Roadmap Wave Driver

The next roadmap wave should be chosen from measured gaps:

```text
if optimizer legality gaps block handoff, prioritize MemorySSA and alias precision
if loop shapes diverge from Zig-native needs, prioritize loop optimization parity
if scalar output quality is the bottleneck, prioritize scalar optimization quality
if target emission assumptions block validation, prioritize Machine IR/object boundaries
```
