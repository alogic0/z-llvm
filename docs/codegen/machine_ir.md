# x86_64 machine representation

The current implementation is in [machine.zig](../../src/codegen/x86_64/machine.zig).
It is the shared output of the supported structural and composed lowering paths,
and feeds machine verification, assembly output, and ELF object emission.
See [current architecture](../architecture.md) for route and ownership details.

## Representation and lowering

`MachineFunction` owns its instruction list and generated labels. It also records
its return type, codegen path, selection owner, and entry XMM definition bits.
The instruction union describes target-specific operations used by the accepted
x86_64 subset. This is not LLVM's pre-register-allocation Machine IR.

Current code includes multiple-block/loop lowering, scalar memory operations,
calls and ABI handling, integer and floating-point operations, and bounded
register/spill planning. These capabilities are limited by the individual
selector, ABI, and emission implementations; their presence does not establish
arbitrary combinations or general pressure handling.

| Responsibility | Source owner |
| --- | --- |
| Lowering dispatch and structural fallbacks | [air_patterns_impl.zig](../../src/codegen/x86_64/air_patterns_impl.zig) |
| Legacy/composed selection and rollback | [generic_cfg_selector.zig](../../src/codegen/x86_64/generic_cfg_selector.zig) |
| CFG liveness and bounded allocation planning | [stage2_planning.zig](../../src/codegen/x86_64/generic_cfg/stage2_planning.zig) |
| Composed block/CFG lowering | [composed_selector.zig](../../src/codegen/x86_64/generic_cfg/composed_selector.zig) |
| SysV classification and call/return planning | [sysv_abi.zig](../../src/codegen/x86_64/sysv_abi.zig) |
| Machine verification | [verify.zig](../../src/codegen/x86_64/verify.zig) |
| Assembly and object emission | [MC modules](../../src/mc) |

The composed selector uses a transaction to restore machine state after an
unsupported attempt. Successful selection assigns an owner and the outer
lowering path verifies the resulting machine function. The composed selector is
opt-in; its unsupported result can still reach a structural fallback. Tests
requiring composed ownership must check the owner explicitly.

## Boundaries and validation

The current lowering entrypoint accepts x86_64 Linux. Bounded spill planning
exists; the earlier bootstrap description of an i32-only backend with no memory,
no general CFG path, and only fixed argument-register moves is historical.
No claim of a general allocator, scheduler, multi-target backend, or complete
LLVM object/debug parity follows from the current subset.

Assembly/encoding/object fixtures, machine verification, composed behavioral
comparisons, and integrated native execution exercise different parts of this
representation. The [validation tiers](../validation_tiers.md) select required
checks for changes. The [backend handoff](zig_native_backend_handoff.md) keeps
final executable linking with Zig. Current support/evidence is described in
[current state](../current_state.md), not inferred from the instruction union.
