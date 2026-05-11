# MC/Object Bootstrap Epic

Goal: prove that the project can cross the boundary from optimized IR into a
real target-specific output artifact for a tiny function subset. This epic
should start only after the Target DataLayout and AIR-to-IR Bridge Epic can
produce verified, target-aware, optimized IR for small scalar functions.

This is not a full native backend. The first milestone is one target, one object
format, and a deliberately tiny instruction subset with precise ABI behavior.

## Relationship To Other Epics

Historical roadmap order:

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
- Under the current [Zig-Aligned LLVM Removal Plan](zig_aligned_llvm_removal_plan.md),
  this epic is a bounded verification experiment, not the primary replacement
  path for Zig's native backends. New backend expansion should pause unless it
  validates optimizer output or clarifies a specific LLVM emission boundary.

Current status:

- Completed as a bootstrap milestone in Cycle 39 after the
  [Target DataLayout and AIR-to-IR Bridge Epic](target_datalayout_air_bridge_epic.md)
  was closed.
- The implemented path is intentionally tiny: x86_64-linux SysV scalar i32 leaf
  functions, simple conditional returns, assembly text, direct instruction
  encoding, and ELF64 relocatable object metadata.
- Full instruction selection, general register allocation, stack frames,
  relocations, calls, debug info, linking, and multi-target support remain out
  of scope for this epic.

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

Status: assembly and ELF object bootstrap implemented and verified in Cycle 39.

- [x] Choose the first target/object pair, preferably `x86_64-linux-elf`, because it is easy to inspect with common binutils and maps well to the local development environment.
- [x] Document why other targets are deferred: Mach-O, COFF/PE, Wasm object format, AArch64, RISC-V, debug info, and relocation-heavy code.
- [x] Define the accepted input subset: one module, internal/external scalar functions, integer/pointer parameters, integer return, straight-line blocks first.
- [x] Define the initial output contract: assembly text first, then relocatable ELF object once instruction encoding and symbol layout are stable.
- [x] Keep LLVM IR parsing and optimizer paths intact; MC/object work consumes verified project IR after target/data-layout resolution.

Suggested slice boundary:

- [x] First accept only one straight-line function returning an integer constant
      or parameter.
- [x] Then add two-operand scalar integer expressions.
- [x] Defer branches until labels and control-flow printing are stable.

## 2. Machine IR Foundation

- [x] Add `src/codegen/` with a minimal MachineFunction and MachineInstr model for the chosen target.
- [x] Lower project IR function signatures to machine-level virtual registers and stack/frame metadata.
- [x] Lower scalar integer operations: return constant, return parameter, add/sub/and/or/xor, simple compare result where needed.
- [x] Lower simple control flow only after straight-line return works: unconditional branch, conditional branch, two-block if/else.
- [x] Represent target registers explicitly enough to model the chosen ABI return register and first integer parameter registers.
- [x] Document the mapping to LLVM CodeGen concepts: IRTranslator/SelectionDAG or GlobalISel analogues, MachineFunction, MachineInstr, and target register info.

Suggested slice boundary:

- [x] Keep Machine IR target-specific at first. A premature target-independent
      layer will likely obscure the register and encoding facts this epic is
      meant to expose.
- [x] Add a machine verifier early: every virtual/physical register use must be
      defined, every return must set the ABI return register, and every branch
      target must exist.

## 3. ABI and Calling Convention Slice

- [x] Implement the chosen target's scalar integer/pointer calling convention for parameters and return values.
- [x] Support leaf functions with no calls first.
- [x] Add prologue/epilogue only when needed; avoid stack frame setup for simple register-only leaf functions if the ABI permits it.
- [x] Add stack slot support only for spills or alloca-backed examples selected for this epic.
- [x] Document callee-saved vs caller-saved register policy, even if the initial implementation avoids needing most of it.
- [x] Add tests for argument register assignment and return register selection.

Suggested slice boundary:

- [x] Start with register-only scalar parameters and returns.
- [x] Reject stack-passed parameters explicitly until stack frame layout is
      implemented.
- [x] Keep varargs and aggregate returns out of this epic unless a later roadmap
      promotes them with ABI docs and fixtures.

## 4. Instruction Selection and Register Allocation Bootstrap

- [x] Start with a deterministic trivial register assignment for expression trees that fit available caller-saved registers.
- [x] Add explicit failure diagnostics when the function needs spilling or unsupported register pressure handling.
- [x] Select instructions for immediate constants, register moves, binary integer ops, compare/test, branch, and return.
- [x] Keep multiplication, division, shifts, memory addressing, calls, and vector/floating-point instructions out of scope unless promoted with tests.
- [x] Add a tiny liveness or use-count helper only if required to avoid clobbering live values.
- [x] Document the current boundary compared with LLVM register allocation, instruction selection, scheduling, and legalization.

Suggested slice boundary:

- [x] Use a deterministic register plan before calling it register allocation:
      map known SSA values to a small fixed caller-saved register set and fail
      when the expression exceeds it.
- [x] Add failure fixtures for unsupported register pressure before adding spill
      support.

## 5. Assembly Printer

- [x] Add `src/mc/` with an assembly printer for the chosen target's tiny instruction subset.
- [x] Print function labels, global/local symbol spelling, instruction mnemonics, registers, immediates, and branch labels.
- [x] Emit target directives needed for a minimal assemblable `.s` file.
- [x] Add golden assembly tests for the first function shapes.
- [x] Validate generated assembly by assembling it with an external assembler when available, but keep text golden tests as the core local contract.
- [x] Compare selected output against LLVM-generated assembly from equivalent tiny IR or Zig source where normalization is practical.

Suggested slice boundary:

- [x] Normalize assembly before comparing: ignore harmless directive ordering,
      comments, and local label spelling if they are not semantically relevant.
- [x] Keep one fixture per function shape so assembly diffs stay readable.

## 6. ELF Object Writer Bootstrap

- [x] Add the smallest ELF relocatable object writer needed for one text section and one symbol table.
- [x] Emit `.text`, section headers, symbol table, string table, and relocation records only when they become necessary.
- [x] Start with no external references and no relocations if possible.
- [x] Add relocations for internal branches only if the encoder/object layout requires them; otherwise resolve local branch offsets directly.
- [x] Add `readelf`/`objdump` verification docs and optional scripts for inspecting generated objects.
- [x] Keep linking, archives, COMDAT, TLS, unwind info, debug info, and platform-specific link semantics out of scope.

Suggested slice boundary:

- [x] Write object sections from already-encoded bytes, not directly from IR.
      This keeps instruction encoding testable without ELF layout.
- [x] Add object metadata tests before relocation tests: ELF header, `.text`,
      `.symtab`, `.strtab`, and section headers.

## 7. Binary Encoding

- [x] Encode the chosen target's minimal instruction subset directly, with tests for byte sequences.
- [x] Add an instruction encoding table or small typed encoder; avoid ad hoc byte writes scattered through codegen.
- [x] Test encodings independently from object writing.
- [x] Verify encodings with `objdump` or another disassembler when available.
- [x] Add clear unsupported-instruction diagnostics for every IR operation that reaches codegen without an encoder.

Suggested slice boundary:

- [x] Keep encoders table-driven or type-driven from the start. Scattered byte
      writes will become hard to audit once branches and relocations land.
- [x] Test every instruction encoding independently from function lowering.

## 8. End-to-End Tiny Function Fixtures

- [x] Add fixtures for `return_constant`, `return_arg`, `add_args`, `bitwise_args`, and simple two-block conditional return.
- [x] For each fixture, store project IR input, expected assembly, and expected object/disassembly if object writing has landed.
- [x] Add a run path that lowers IR to assembly without writing an object.
- [x] Add a run path that lowers IR to an object file once the object writer is ready.
- [x] Compare against LLVM-generated assembly/object behavior where feasible; otherwise document local-only bootstrap behavior.
- [x] Add failure fixtures for unsupported IR: calls, memory-heavy alloca, division, vectors, floats, globals, and debug metadata.

## 9. CLI and Build Integration

- [x] Add CLI flags such as `--emit=ir`, `--emit=asm`, and eventually `--emit=obj`.
- [x] Add a target selection flag that reuses the DataLayout/target module from the previous epic.
- [x] Keep optimizer-only behavior as the default until codegen is mature enough to avoid surprising existing tests.
- [x] Add build steps or scripts for codegen fixture verification.
- [x] Ensure generated temporary objects live under `zig-out/` or `tmp/`, not under tracked fixture directories.

## 10. Documentation and Inventory Updates

- [x] Add `docs/codegen/machine_ir.md`.
- [x] Add `docs/codegen/abi_x86_64_sysv.md` or the equivalent chosen-target ABI doc.
- [x] Add `docs/mc/assembly_printer.md`.
- [x] Add `docs/mc/elf_object_writer.md`.
- [x] Update `docs/inventory/zig_llvm_api_inventory.md` for the first covered `TargetMachine.emitToFile`, MC, target-register, and object-emission responsibilities.
- [x] Update `docs/unsupported_ir.md` with codegen-specific unsupported constructs.
- [x] Update `docs/testing.md` with assembly/object fixture workflows.

## 11. Verification Gate

- [x] Run `zig fmt` on touched Zig files.
- [x] Run `zig build test`.
- [x] Run existing optimizer comparison tests.
- [x] Run machine-code unit tests for instruction selection and encoding.
- [x] Run assembly golden tests.
- [x] If object writing is enabled, inspect generated objects with `readelf` and `objdump` or document why those checks were unavailable.
- [x] Confirm every unsupported codegen path fails with a targeted diagnostic.

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

Historically, the next backend epic could be **Debug Info and Runtime Metadata
Bootstrap** or **Calls and Stack Frame Codegen**. Under the current Zig-aligned
direction, the default next work should return to the verifier, Zig-emitted IR
corpus, and optimizer slices selected from the LLVM pass-pipeline inventory.
Continue backend epics only when they are needed as targeted validation.
