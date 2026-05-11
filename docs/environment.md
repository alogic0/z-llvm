# Development Environment

Current environment used for `z_llvm` development and LLVM comparison testing:

```text
OS: Ubuntu 24.04.4 LTS (noble)
Zig: 0.16.0
LLVM tools: 22.1.3
LLVM source checkout: llvm-project-22/
Zig source checkout for inventory work: ../ziglang
Authoritative Zig fixture emitter: ../ziglang/build/stage4/bin/zig
Project checkout: z_llvm/
```

The `Zig: 0.16.0` entry is the local default executable. Authoritative
Zig-emitted IR fixtures use `../ziglang/build/stage4/bin/zig`, which is built
from the same `../ziglang` source checkout used by the roadmap and inventory
source anchors.

LLVM command names in this environment are versioned:

```text
opt-22
llvm-config-22
```

Use `opt-22` for LLVM comparison fixtures:

```bash
opt-22 -passes=instcombine test/opt/inputs/instcombine.ll -S -o /tmp/llvm_instcombine.ll
opt-22 -passes=dce test/opt/inputs/dce.ll -S -o /tmp/llvm_dce.ll
opt-22 -passes=dce test/opt/inputs/memory_dce.ll -S -o /tmp/llvm_memory_dce.ll
opt-22 -passes=simplifycfg test/opt/inputs/simplifycfg.ll -S -o /tmp/llvm_simplifycfg.ll
opt-22 -passes=mem2reg test/opt/inputs/mem2reg.ll -S -o /tmp/llvm_mem2reg.ll
```

If a fresh Ubuntu machine does not have LLVM 22 installed:

```bash
sudo apt update
sudo apt install -y wget gnupg lsb-release software-properties-common

wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 22

sudo apt install -y llvm-22 llvm-22-dev llvm-22-tools clang-22 lld-22
```

Optional unversioned command setup:

```bash
sudo update-alternatives --install /usr/bin/opt opt /usr/bin/opt-22 100
sudo update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-22 100
```

Notes:

```text
LLVM `opt` output may include ModuleID, source_filename, inferred alignment, attributes, or formatting that `z_llvm` does not print yet.
Compare semantic behavior and normalized IR, not raw byte-for-byte output, unless the fixture explicitly says raw output is expected.
```
