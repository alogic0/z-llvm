# MC/Object Bootstrap Epic

Goal: prove that the project can cross the boundary from optimized IR into a
real target-specific output artifact for a tiny function subset. This epic
should start only after the Target DataLayout and AIR-to-IR Bridge Epic can
produce verified, target-aware, optimized IR for small scalar functions.

This is not a full native backend. The first milestone is one target, one object
format, and a deliberately tiny instruction subset with precise ABI behavior.

## Relationship To Other Epics

Roadmap order:

```text
Pipeline-Ready Optimizer Epic
  -> Target DataLayout and AIR-to-IR Bridge Epic
  -> MC/Object Bootstrap Epic
```

- Previous epic: [Target DataLayout and AIR-to-IR Bridge Epic](target_datalayout_air_bridge_epic.md).
- Earlier foundation: [Pipeline-Ready Optimizer Epic](pipeline_ready_optimizer_epic.md).
- This epic consumes verified target-aware IR and crosses into assembly/object
  output for one tiny target subset.
- Keep this epic separate from target/DataLayout and AIR lowering work; unresolved
  IR or ABI questions should be fixed in the previous epic first.

## Suggestions Before Starting

- Do not start this epic until the previous target/DataLayout epic has one
  target with verified scalar function signatures. MC/object work will otherwise
  mix backend problems with unresolved IR and ABI problems.
- Make assembly text the first executable milestone. It is easier to inspect,
  compare with LLVM, and reduce than a relocatable object file.
- Pick one target/object pair and freeze it for the first pass. The practical
  default is `x86_64-linux-elf` with the SysV calling convention, because local
  tools can inspect it and the ABI is well documented.
- Keep codegen independent from the optimizer. The codegen pipeline should
  consume verified project IR, but optimizer changes should not be required to
  debug instruction selection or object emission.
- Require targeted unsupported diagnostics from the first slice. Silent
  fallback or partial output is more dangerous in codegen than in parser-only
  work.
- Compare at three levels where practical: machine IR shape, assembly text, and
  disassembly/object metadata. A byte-perfect object comparison should not be
  the first contract.

## 1. Scope and Target Choice

Status: in progress as Cycle 18 in `docs/next_steps.md`.

- [ ] Choose the first target/object pair, preferably `x86_64-linux-elf`, because it is easy to inspect with common binutils and maps well to the local development environment.
- [ ] Document why other targets are deferred: Mach-O, COFF/PE, Wasm object format, AArch64, RISC-V, debug info, and relocation-heavy code.
- [ ] Define the accepted input subset: one module, internal/external scalar functions, integer/pointer parameters, integer return, straight-line blocks first.
- [ ] Define the initial output contract: assembly text first, then relocatable ELF object once instruction encoding and symbol layout are stable.
- [ ] Keep LLVM IR parsing and optimizer paths intact; MC/object work consumes verified project IR after target/data-layout resolution.

Suggested slice boundary:

- [ ] First accept only one straight-line function returning an integer constant
      or parameter.
- [ ] Then add two-operand scalar integer expressions.
- [ ] Defer branches until labels and control-flow printing are stable.

## 2. Machine IR Foundation

- [ ] Add `src/codegen/` with a minimal MachineFunction and MachineInstr model for the chosen target.
- [ ] Lower project IR function signatures to machine-level virtual registers and stack/frame metadata.
- [ ] Lower scalar integer operations: return constant, return parameter, add/sub/and/or/xor, simple compare result where needed.
- [ ] Lower simple control flow only after straight-line return works: unconditional branch, conditional branch, two-block if/else.
- [ ] Represent target registers explicitly enough to model the chosen ABI return register and first integer parameter registers.
- [ ] Document the mapping to LLVM CodeGen concepts: IRTranslator/SelectionDAG or GlobalISel analogues, MachineFunction, MachineInstr, and target register info.

Suggested slice boundary:

- [ ] Keep Machine IR target-specific at first. A premature target-independent
      layer will likely obscure the register and encoding facts this epic is
      meant to expose.
- [ ] Add a machine verifier early: every virtual/physical register use must be
      defined, every return must set the ABI return register, and every branch
      target must exist.

## 3. ABI and Calling Convention Slice

- [ ] Implement the chosen target's scalar integer/pointer calling convention for parameters and return values.
- [ ] Support leaf functions with no calls first.
- [ ] Add prologue/epilogue only when needed; avoid stack frame setup for simple register-only leaf functions if the ABI permits it.
- [ ] Add stack slot support only for spills or alloca-backed examples selected for this epic.
- [ ] Document callee-saved vs caller-saved register policy, even if the initial implementation avoids needing most of it.
- [ ] Add tests for argument register assignment and return register selection.

Suggested slice boundary:

- [ ] Start with register-only scalar parameters and returns.
- [ ] Reject stack-passed parameters explicitly until stack frame layout is
      implemented.
- [ ] Keep varargs and aggregate returns out of this epic unless a later roadmap
      promotes them with ABI docs and fixtures.

## 4. Instruction Selection and Register Allocation Bootstrap

- [ ] Start with a deterministic trivial register assignment for expression trees that fit available caller-saved registers.
- [ ] Add explicit failure diagnostics when the function needs spilling or unsupported register pressure handling.
- [ ] Select instructions for immediate constants, register moves, binary integer ops, compare/test, branch, and return.
- [ ] Keep multiplication, division, shifts, memory addressing, calls, and vector/floating-point instructions out of scope unless promoted with tests.
- [ ] Add a tiny liveness or use-count helper only if required to avoid clobbering live values.
- [ ] Document the current boundary compared with LLVM register allocation, instruction selection, scheduling, and legalization.

Suggested slice boundary:

- [ ] Use a deterministic register plan before calling it register allocation:
      map known SSA values to a small fixed caller-saved register set and fail
      when the expression exceeds it.
- [ ] Add failure fixtures for unsupported register pressure before adding spill
      support.

## 5. Assembly Printer

- [ ] Add `src/mc/` with an assembly printer for the chosen target's tiny instruction subset.
- [ ] Print function labels, global/local symbol spelling, instruction mnemonics, registers, immediates, and branch labels.
- [ ] Emit target directives needed for a minimal assemblable `.s` file.
- [ ] Add golden assembly tests for the first function shapes.
- [ ] Validate generated assembly by assembling it with an external assembler when available, but keep text golden tests as the core local contract.
- [ ] Compare selected output against LLVM-generated assembly from equivalent tiny IR or Zig source where normalization is practical.

Suggested slice boundary:

- [ ] Normalize assembly before comparing: ignore harmless directive ordering,
      comments, and local label spelling if they are not semantically relevant.
- [ ] Keep one fixture per function shape so assembly diffs stay readable.

## 6. ELF Object Writer Bootstrap

- [ ] Add the smallest ELF relocatable object writer needed for one text section and one symbol table.
- [ ] Emit `.text`, section headers, symbol table, string table, and relocation records only when they become necessary.
- [ ] Start with no external references and no relocations if possible.
- [ ] Add relocations for internal branches only if the encoder/object layout requires them; otherwise resolve local branch offsets directly.
- [ ] Add `readelf`/`objdump` verification docs and optional scripts for inspecting generated objects.
- [ ] Keep linking, archives, COMDAT, TLS, unwind info, debug info, and platform-specific link semantics out of scope.

Suggested slice boundary:

- [ ] Write object sections from already-encoded bytes, not directly from IR.
      This keeps instruction encoding testable without ELF layout.
- [ ] Add object metadata tests before relocation tests: ELF header, `.text`,
      `.symtab`, `.strtab`, and section headers.

## 7. Binary Encoding

- [ ] Encode the chosen target's minimal instruction subset directly, with tests for byte sequences.
- [ ] Add an instruction encoding table or small typed encoder; avoid ad hoc byte writes scattered through codegen.
- [ ] Test encodings independently from object writing.
- [ ] Verify encodings with `objdump` or another disassembler when available.
- [ ] Add clear unsupported-instruction diagnostics for every IR operation that reaches codegen without an encoder.

Suggested slice boundary:

- [ ] Keep encoders table-driven or type-driven from the start. Scattered byte
      writes will become hard to audit once branches and relocations land.
- [ ] Test every instruction encoding independently from function lowering.

## 8. End-to-End Tiny Function Fixtures

- [ ] Add fixtures for `return_constant`, `return_arg`, `add_args`, `bitwise_args`, and simple two-block conditional return.
- [ ] For each fixture, store project IR input, expected assembly, and expected object/disassembly if object writing has landed.
- [ ] Add a run path that lowers IR to assembly without writing an object.
- [ ] Add a run path that lowers IR to an object file once the object writer is ready.
- [ ] Compare against LLVM-generated assembly/object behavior where feasible; otherwise document local-only bootstrap behavior.
- [ ] Add failure fixtures for unsupported IR: calls, memory-heavy alloca, division, vectors, floats, globals, and debug metadata.

## 9. CLI and Build Integration

- [ ] Add CLI flags such as `--emit=ir`, `--emit=asm`, and eventually `--emit=obj`.
- [ ] Add a target selection flag that reuses the DataLayout/target module from the previous epic.
- [ ] Keep optimizer-only behavior as the default until codegen is mature enough to avoid surprising existing tests.
- [ ] Add build steps or scripts for codegen fixture verification.
- [ ] Ensure generated temporary objects live under `zig-out/` or `tmp/`, not under tracked fixture directories.

## 10. Documentation and Inventory Updates

- [ ] Add `docs/codegen/machine_ir.md`.
- [ ] Add `docs/codegen/abi_x86_64_sysv.md` or the equivalent chosen-target ABI doc.
- [ ] Add `docs/mc/assembly_printer.md`.
- [ ] Add `docs/mc/elf_object_writer.md`.
- [ ] Update `docs/inventory/zig_llvm_api_inventory.md` for the first covered `TargetMachine.emitToFile`, MC, target-register, and object-emission responsibilities.
- [ ] Update `docs/unsupported_ir.md` with codegen-specific unsupported constructs.
- [ ] Update `docs/testing.md` with assembly/object fixture workflows.

## 11. Verification Gate

- [ ] Run `zig fmt` on touched Zig files.
- [ ] Run `zig build test`.
- [ ] Run existing optimizer comparison tests.
- [ ] Run machine-code unit tests for instruction selection and encoding.
- [ ] Run assembly golden tests.
- [ ] If object writing is enabled, inspect generated objects with `readelf` and `objdump` or document why those checks were unavailable.
- [ ] Confirm every unsupported codegen path fails with a targeted diagnostic.

## Out of Scope

- Full instruction selection.
- General register allocation.
- Spilling.
- Scheduling.
- Function calls.
- Varargs.
- Floating-point and vector code.
- Debug info.
- Unwind info.
- Linking.
- Archives.
- LTO.
- Multiple object formats.
- Multiple architectures.

## Success Criteria

This epic succeeds when the project can take a tiny verified scalar IR function
for the chosen target and emit either:

```text
normalized IR -> machine IR -> assembly
```

or, for the deeper milestone:

```text
normalized IR -> machine IR -> encoded instructions -> relocatable ELF object
```

The result does not need to be competitive with LLVM. It must be inspectable,
tested, target-aware, and honest about unsupported codegen cases.

## Next Epic After This

If this epic succeeds, the next natural epic is **Debug Info and Runtime
Metadata Bootstrap** or **Calls and Stack Frame Codegen**, depending on whether
the project wants to prioritize debugger correctness or broader executable code
coverage.
