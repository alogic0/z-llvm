# LLVM opt Comparison Fixtures

These fixtures compare one reproduced `z_llvm` pass against the matching LLVM `opt` pass.

Run `z_llvm`:

```bash
zig build run -- --passes=instcombine test/opt/inputs/instcombine.ll
zig build run -- --passes=dce test/opt/inputs/dce.ll
zig build run -- --passes=dce test/opt/inputs/memory_dce.ll
zig build run -- --passes=simplifycfg test/opt/inputs/simplifycfg.ll
zig build run -- --passes=mem2reg test/opt/inputs/mem2reg.ll
```

Run LLVM `opt` when available:

```bash
opt -passes=instcombine test/opt/inputs/instcombine.ll -S -o /tmp/llvm_instcombine.ll
opt -passes=dce test/opt/inputs/dce.ll -S -o /tmp/llvm_dce.ll
opt -passes=dce test/opt/inputs/memory_dce.ll -S -o /tmp/llvm_memory_dce.ll
opt -passes=simplifycfg test/opt/inputs/simplifycfg.ll -S -o /tmp/llvm_simplifycfg.ll
opt -passes=mem2reg test/opt/inputs/mem2reg.ll -S -o /tmp/llvm_mem2reg.ll
```

Expected `z_llvm` outputs are in `test/opt/expected/z_llvm/`.

The fixtures are intentionally limited to the reproduced subset of each LLVM algorithm. LLVM may preserve extra module flags, attributes, or formatting when run on richer input; compare normalized behavior rather than raw text.
