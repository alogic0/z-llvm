# LLVM IR reference

The parser reads LLVM-compatible text into the shared IR. The verifier checks
the invariants that optimization passes and code generation rely on.
[Compiler architecture](../architecture.md) · [Verifier rules](verifier.md) · [Unsupported constructs](unsupported.md)

| Working with | References |
| --- | --- |
| Modules and symbols | [Module records and globals](module.md) · [Module-level assembly](module_asm.md) · [Named types](named_types.md) · [Identifier spelling and identity](../ir_identifiers.md) |
| Instructions and operands | [Values and constants](values.md) · [Scalar operations](scalar.md) · [Select](select.md) · [Vectors](vectors.md) |
| Blocks and edges | [Control flow](control_flow.md) · [Exception handling](exception_handling.md) |
| Memory and concurrency | [Memory operations](memory.md) · [Atomics and inline assembly](atomics_inline_asm.md) · [Concurrency and thread-local storage](concurrency_tls.md) |

For evidence from actual Zig output, start with the [fixture corpus](../fixtures/zig_ir/README.md).
