# Testing

The replacement uses LLVM-compatible normalized IR as its first debugging contract.

The comparison loop is:

```text
input LLVM-compatible IR
  -> parse into z_llvm IR
  -> run selected z_llvm passes
  -> print normalized LLVM-compatible IR
  -> compare against a golden file or LLVM `opt` output
```

The first golden comparison covers the implemented `instcombine` and `dce` subsets:

```text
test/inputs/instcombine.ll
test/expected/instcombine_dce.ll
```

LLVM `opt` comparison fixtures live under:

```text
test/opt/inputs/
test/opt/expected/z_llvm/
```

Use these to compare each reproduced pass with the matching LLVM pass when `opt` is installed.
The current development environment uses versioned LLVM 22 commands; see [environment.md](environment.md).

```bash
opt-22 -passes=instcombine test/opt/inputs/instcombine.ll -S -o /tmp/llvm_instcombine.ll
opt-22 -passes=dce test/opt/inputs/dce.ll -S -o /tmp/llvm_dce.ll
opt-22 -passes=adce test/opt/inputs/adce_chain.ll -S -o /tmp/llvm_adce.ll
opt-22 -passes=gvn test/opt/inputs/gvn_dominating_expr.ll -S -o /tmp/llvm_gvn.ll
opt-22 -passes='loop-mssa(licm)' test/opt/inputs/licm_invariant.ll -S -o /tmp/llvm_licm.ll
opt-22 -passes=sroa test/opt/inputs/sroa_zero_gep.ll -S -o /tmp/llvm_sroa.ll
opt-22 -passes='instcombine,dce' test/opt/inputs/instcombine_scalar_simplify.ll -S -o /tmp/llvm_scalar_simplify.ll
opt-22 -passes=simplifycfg test/opt/inputs/simplifycfg.ll -S -o /tmp/llvm_simplifycfg.ll
```

Run all currently mapped LLVM comparisons:

```bash
bash scripts/compare_opt.sh
```

The comparison matrix includes scalar IR round-trip coverage for casts,
division/remainder, `freeze`, and `nsw`/`nuw`/`exact` flag preservation through
the `scalar_ir_surface` fixture. It also includes defined scalar cast/div/rem
fold coverage through `instcombine_scalar_simplify`.

Target-aware infrastructure currently has unit-test-only coverage for:

```text
target triple parsing
initial target matrix recognition for x86_64-linux-gnu, x86_64-linux-musl, aarch64-linux-gnu, and wasm32-wasi
target datalayout preservation and pointer/integer alignment queries
scalar ABI classification for void, integer, and pointer signatures
target-aware project IR function signature classification
AIR-like scalar builder lowering for tiny binary and cast functions
AIR-like control-flow builder lowering for conditional branches, returns, and unreachable
AIR-like stack-memory builder lowering for alloca/load/store/GEP
AIR-like canonical loop builder verified with LoopInfo
AIR-like bridge driver pre/post optimization output through `memory-foundation`
normalized Zig-emitted LLVM IR fixture for tiny scalar functions
AIR-like project-lowered and project-optimized fixture pair for the same tiny scalar signatures
source_filename preservation
scalar global and constant global preservation
function linkage and raw function-header attribute preservation
function visibility and raw parameter attribute preservation
calling convention preservation for ccc/fastcc/coldcc-compatible header parsing
function declaration and direct call round-tripping
direct call verifier mismatch and unsupported-call diagnostics
void function and ret void round-tripping
explicit unsupported global diagnostics
```

Use a different `opt` binary:

```bash
OPT_BIN=opt bash scripts/compare_opt.sh
```

Named pipeline and pass-manager debugging commands:

```bash
zig build run -- --passes=scalar-foundation test/opt/inputs/instcombine.ll
zig build run -- --pipeline=memory-foundation test/opt/inputs/mem2reg.ll
zig build run -- --passes=scalar-foundation --trace test/opt/inputs/instcombine.ll
zig build run -- --passes=scalar-foundation --time test/opt/inputs/instcombine.ll
zig build run -- --passes=scalar-foundation --pass-limit=2 test/opt/inputs/instcombine.ll
zig build run -- --pipeline=zig-scalar-foundation --target=x86_64-unknown-linux-gnu --datalayout=e-m:e-p:64:64-i64:64 test/opt/inputs/instcombine.ll
zig build run -- --emit=asm --target=x86_64-unknown-linux-gnu test/codegen/inputs/add_args.ll
zig build run -- --emit=obj --target=x86_64-unknown-linux-gnu test/codegen/inputs/add_args.ll > /tmp/z_llvm_add_args.o
```

Negative target diagnostics checked during development:

```bash
zig build run -- --emit=asm --target=wasm32-wasi test/codegen/inputs/add_args.ll
zig build run -- --pipeline=zig-scalar-foundation --target=x86_64-unknown-linux-gnu --datalayout=p:bad test/opt/inputs/instcombine.ll
```

Assembly and object bootstrap commands:

```bash
zig build run -- --emit=asm --target=x86_64-unknown-linux-gnu test/codegen/inputs/add_args.ll
zig build run -- --emit=obj --target=x86_64-unknown-linux-gnu test/codegen/inputs/add_args.ll > /tmp/z_llvm_add_args.o
bash scripts/compare_codegen_asm.sh
bash scripts/compare_codegen_objdump.sh
readelf -h -S -s /tmp/z_llvm_add_args.o
objdump -d /tmp/z_llvm_add_args.o
```

The assembly/object path currently has unit-test coverage plus tiny CLI smoke
inputs. It covers x86_64 SysV i32 leaf functions, simple conditional returns,
minimal instruction encoding, ELF64 relocatable metadata, and explicit
diagnostics for unsupported control flow.

LLVM algorithms covered so far:

```text
InstCombine: arithmetic, bitwise, shift, select, relational icmp, constant scalar cast/div-rem folding, conservative scalar flag/division preservation, and commutative canonicalization subsets
DCE: unused pure instruction removal subset
ADCE: unused side-effect-free instruction chain removal subset
SimplifyCFG: constant branch folding, unreachable block removal, phi cleanup, block merge, and empty-block threading subsets
EarlyCSE: same-block repeated pure-expression elimination subset
Mem2Reg: entry-block alloca discovery plus single-block, multi-block, undef, multi-slot stack promotion, and volatile alloca-user rejection subsets
SROA: zero-offset GEP alloca forwarding subset
GVN: dominating repeated pure-expression elimination subset with memory-effect rejection
LoopInfo: natural-loop, preheader, exiting-block, and exit-block analysis subset
LICM: pure scalar loop-invariant instruction hoisting subset, including integer casts, variant-operand rejection, SSA dominance preservation, and conservative memory rejection fixtures
Target/DataLayout: target triple parsing, initial target matrix recognition, minimal DataLayout query subset, and scalar/function ABI classification
Module IR: source filename, target records, scalar globals, function linkage/visibility, calling conventions, raw function and parameter attributes, and void return preservation
Call IR: function declarations, direct calls, scalar call signature verification, and conservative unknown memory-effect classification
AIR-like bridge: tiny scalar binary/cast, control-flow, stack-memory, and canonical-loop function lowering into project IR
AIR-like bridge driver: pre/post pipeline output for `memory-foundation`
Pipeline integration: `zig-scalar-foundation` alias and CLI target/datalayout record injection
Target diagnostics: invalid datalayout and unsupported `--emit=asm` target messages
Zig-emitted IR harness: normalized tiny scalar module records and function signatures
Zig fixture pair: project-lowered and optimized outputs compared structurally with normalized Zig-emitted signatures
MC/CodeGen: tiny x86_64 Machine IR, assembly printer, instruction encoder, and ELF64 relocatable object bootstrap
```

Exact byte-for-byte matching with LLVM is not the long-term contract. The normalized form should make semantic differences visible while ignoring harmless formatting differences.

Pass and analysis docs should classify fixture coverage with these labels:

```text
opt-22 equivalent: expected z_llvm output is compared with normalized LLVM opt output
local-only conservative: checked against z_llvm golden output because LLVM currently does more than this project deliberately implements
unit-test only: covered by Zig unit tests rather than the opt fixture table
```

Current memory legality examples:

```text
opt-22 equivalent: scalar LICM/GVN/DCE behavior beside volatile memory, volatile load preservation
local-only conservative: aligned load not hoisted, atomic/store barriers preserved
unit-test only: MemoryLocation offset/size queries, known disjoint stack offsets, unknown pointer aliasing remains may-alias/ref
```
