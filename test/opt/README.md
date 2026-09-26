# LLVM opt Comparison Fixtures

These fixtures compare one reproduced `z_llvm` pass against the matching LLVM `opt` pass.

Fixture metadata lives in:

```text
test/opt/fixtures.tsv
```

Each row records:

```text
id
z_llvm pass or pipeline
LLVM opt pass or pipeline
input path
expected z_llvm output path
fixture kind: opt-equivalent, local-conservative, or parse-preserve-only
inventory pass names covered by the fixture
known normalization notes
```

The `inventory pass names` field ties every optimizer fixture back to
`docs/inventory/zig_llvm_pass_pipeline_inventory.md`.

Run `z_llvm`:

```bash
zig build run -- --passes=instcombine test/opt/inputs/instcombine.ll
zig build run -- --passes=instcombine,dce test/opt/inputs/select_fold.ll
zig build run -- --passes=dce test/opt/inputs/dce.ll
zig build run -- --passes=dce test/opt/inputs/memory_dce.ll
zig build run -- --passes=simplifycfg test/opt/inputs/simplifycfg.ll
zig build run -- --passes=simplifycfg test/opt/inputs/unreachable_simplifycfg.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_undef.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_if.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_loop.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_two_slots.ll
zig build run -- --passes=simplifycfg,mem2reg test/opt/inputs/mem2reg_unreachable.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_escape.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_store_slot.ll
zig build run -- --passes=mem2reg test/opt/inputs/gep_memory.ll
```

Run LLVM `opt` when available:

```bash
opt -passes=instcombine test/opt/inputs/instcombine.ll -S -o /tmp/llvm_instcombine.ll
opt -passes=instcombine,dce test/opt/inputs/select_fold.ll -S -o /tmp/llvm_select_fold.ll
opt -passes=dce test/opt/inputs/dce.ll -S -o /tmp/llvm_dce.ll
opt -passes=dce test/opt/inputs/memory_dce.ll -S -o /tmp/llvm_memory_dce.ll
opt -passes=simplifycfg test/opt/inputs/simplifycfg.ll -S -o /tmp/llvm_simplifycfg.ll
opt -passes=simplifycfg test/opt/inputs/unreachable_simplifycfg.ll -S -o /tmp/llvm_unreachable_simplifycfg.ll
opt -passes=mem2reg test/opt/inputs/mem2reg.ll -S -o /tmp/llvm_mem2reg.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_undef.ll -S -o /tmp/llvm_mem2reg_undef.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_if.ll -S -o /tmp/llvm_mem2reg_if.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_loop.ll -S -o /tmp/llvm_mem2reg_loop.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_two_slots.ll -S -o /tmp/llvm_mem2reg_two_slots.ll
opt -passes=simplifycfg,mem2reg test/opt/inputs/mem2reg_unreachable.ll -S -o /tmp/llvm_mem2reg_unreachable.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_escape.ll -S -o /tmp/llvm_mem2reg_escape.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_store_slot.ll -S -o /tmp/llvm_mem2reg_store_slot.ll
opt -passes=mem2reg test/opt/inputs/gep_memory.ll -S -o /tmp/llvm_gep_memory.ll
```

Expected `z_llvm` outputs are in `test/opt/expected/z_llvm/`.

Run all metadata-backed comparisons:

```bash
zig build compare-opt
```

`zig build optimizer-correctness` also executes 11 regression functions after
the focused optimizer passes and `release-o3`, comparing with an independent
LLVM 22 build. It covers branch and loop store facts, signed narrow constants,
wrapping wide arithmetic, and LICM sinking. The runner is included in readiness;
it requires `clang-22` and `opt-22`. Isolated unit tests remain tool-independent.

`opt-equivalent` rows are compared against normalized `opt` output.
`local-conservative` and `parse-preserve-only` rows are compared only against
their checked-in `z_llvm` expected output because LLVM intentionally does more
than the current local slice or emits IR outside the accepted parser surface.

Use a different `opt` binary:

```bash
OPT_BIN=opt zig build compare-opt
```

Run a custom metadata file:

```bash
zig build compare-opt -- test/opt/fixtures.tsv
```

The fixtures are intentionally limited to the reproduced subset of each LLVM
algorithm. LLVM may preserve extra module flags, attributes, or formatting when
run on richer input; compare normalized behavior rather than raw text.
