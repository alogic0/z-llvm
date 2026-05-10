# LLVM opt Comparison Fixtures

These fixtures compare one reproduced `z_llvm` pass against the matching LLVM `opt` pass.

Fixture metadata lives in:

```text
test/opt/fixtures.tsv
```

Each row records the fixture id, `z_llvm` pass name, LLVM `opt` pass name, input path, expected `z_llvm` output path, and known normalization notes.

Run `z_llvm`:

```bash
zig build run -- --passes=instcombine test/opt/inputs/instcombine.ll
zig build run -- --passes=dce test/opt/inputs/dce.ll
zig build run -- --passes=dce test/opt/inputs/memory_dce.ll
zig build run -- --passes=simplifycfg test/opt/inputs/simplifycfg.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_if.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg_loop.ll
zig build run -- --passes=simplifycfg,mem2reg test/opt/inputs/mem2reg_unreachable.ll
```

Run LLVM `opt` when available:

```bash
opt -passes=instcombine test/opt/inputs/instcombine.ll -S -o /tmp/llvm_instcombine.ll
opt -passes=dce test/opt/inputs/dce.ll -S -o /tmp/llvm_dce.ll
opt -passes=dce test/opt/inputs/memory_dce.ll -S -o /tmp/llvm_memory_dce.ll
opt -passes=simplifycfg test/opt/inputs/simplifycfg.ll -S -o /tmp/llvm_simplifycfg.ll
opt -passes=mem2reg test/opt/inputs/mem2reg.ll -S -o /tmp/llvm_mem2reg.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_if.ll -S -o /tmp/llvm_mem2reg_if.ll
opt -passes=mem2reg test/opt/inputs/mem2reg_loop.ll -S -o /tmp/llvm_mem2reg_loop.ll
opt -passes=simplifycfg,mem2reg test/opt/inputs/mem2reg_unreachable.ll -S -o /tmp/llvm_mem2reg_unreachable.ll
```

Expected `z_llvm` outputs are in `test/opt/expected/z_llvm/`.

Run all metadata-backed comparisons:

```bash
bash scripts/compare_opt.sh
```

Use a different `opt` binary:

```bash
OPT_BIN=opt bash scripts/compare_opt.sh
```

Run a custom metadata file:

```bash
bash scripts/compare_opt.sh test/opt/fixtures.tsv
```

The fixtures are intentionally limited to the reproduced subset of each LLVM algorithm. LLVM may preserve extra module flags, attributes, or formatting when run on richer input; compare normalized behavior rather than raw text.
