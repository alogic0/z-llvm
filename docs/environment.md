# Development Environment

Current environment used for `z_llvm` development and LLVM comparison testing:

```text
OS: Ubuntu 24.04.4 LTS (noble)
Local z_llvm build/test Zig: exactly 0.17.0 (tracked .zigversion)
LLVM tools: 22.1.3
LLVM source checkout: llvm-project-22/
Zig source checkout for inventory work: ../ziglang (pin: docs/evidence/ziglang_pin.txt)
Authoritative Zig fixture emitter: ../ziglang/build/stage4/bin/zig
Project checkout: z_llvm/
```

## Zig Compiler Selection Policy

Use different Zig executables for different jobs:

| Task | Compiler | Reason |
| --- | --- | --- |
| Build and test `z_llvm` itself | Zig 0.17.0, explicitly selected | Build tools inherit the selected executable directory; PATH may contain another version. |
| Emit authoritative Zig LLVM IR fixtures | `../ziglang/build/stage4/bin/zig` | Fixtures must come from the same `../ziglang` source checkout used by inventory and roadmap source anchors. |
| Inspect current upstream Zig behavior | `../ziglang/build/stage4/bin/zig` plus `../ziglang` sources | Stage4 currently matches the checked-out Zig source revision. |
| Bootstrap/debug the Zig compiler build | `../ziglang/build/stage3/bin/zig` only when explicitly needed | Stage3 can lag behind the source checkout and must not be used for authoritative fixture generation. |

Before regenerating Zig-emitted IR fixtures, verify the source/compiler pair:

```bash
zig build check-zig-stage4-emitter
```

The stage4 version string must include the same commit prefix as
`../ziglang` HEAD. If it does not, rebuild `../ziglang` before regenerating
fixtures.

Do not use the `zig` on `PATH` to regenerate authoritative Zig-emitted IR
fixtures unless `zig version` is intentionally pinned to the same source
revision as `../ziglang` and the manifest records that fact.

Use the checked capture helper for new source-backed rows:

```bash
zig build capture-zig-ir -- test/zig/inputs/tiny_scalar.zig ReleaseFast
zig build capture-zig-ir -- test/zig/inputs/tiny_scalar.zig Debug
```

By default, `ReleaseFast` and `ReleaseSmall` captures write to
`test/zig/captured/`. Broad `Debug` and `ReleaseSafe` captures write to
`tmp/zig_ir/raw/` unless a reduced checked fixture path is passed explicitly.

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
