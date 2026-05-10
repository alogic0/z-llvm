# Calls and Stack Frame Codegen Epic

Goal: extend the x86_64 MC/Object bootstrap from scalar leaf functions to a
small ABI-correct call and stack-frame subset.

This is not a general backend. The proof is narrower: the project can lower
tiny call-capable functions to inspectable assembly and ELF64 relocatable
objects while preserving x86_64 SysV stack alignment, argument passing, return
values, and relocation records.

## Relationship To Other Epics

Roadmap order:

```text
Pipeline-Ready Optimizer Epic
  -> Target DataLayout and AIR-to-IR Bridge Epic
  -> MC/Object Bootstrap Epic
  -> Calls and Stack Frame Codegen Epic
```

- Previous epic: [MC/Object Bootstrap Epic](mc_object_bootstrap_epic.md).
- This epic consumes the existing x86_64-linux SysV Machine IR, instruction
  encoder, assembly printer, and ELF64 object writer.
- Keep this epic separate from optimizer and AIR-lowering work. It should
  consume verified project IR and fail clearly for unsupported call/frame cases.
- Do not start debug info, unwind info, linking, dynamic linking, varargs, or
  aggregate ABI work here.

Current status:

- First slice implemented: IR declarations and direct call parser/printer/verifier
  support is in place. Direct-call x86_64 assembly lowering is in place for tiny
  i32 register-argument fixtures, including the minimal stack-alignment
  adjustment and one deterministic i32 spill. ELF call relocations and general
  stack frames are still open.
- Target/object pair is fixed to `x86_64-linux-elf` with SysV ABI.
- The previous epic already supports register-only scalar i32 leaf functions,
  simple conditional returns, assembly text, instruction bytes, and ELF64
  relocatable object metadata without relocations.

## Upstream Alignment

LLVM references to check before marking slices complete:

```text
llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp
llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td
llvm-project-22/llvm/lib/Target/X86/X86FrameLowering.cpp
llvm-project-22/llvm/lib/Target/X86/X86RegisterInfo.td
llvm-project-22/llvm/lib/Target/X86/MCTargetDesc/X86MCCodeEmitter.cpp
llvm-project-22/llvm/lib/MC/ELFObjectWriter.cpp
llvm-project-22/llvm/lib/MC/MCELFStreamer.cpp
```

Relevant LLVM concepts:

```text
X86TargetLowering::LowerFormalArguments
X86TargetLowering::LowerCall
X86TargetLowering::LowerReturn
X86FrameLowering::emitPrologue
X86FrameLowering::emitEpilogue
MachineFrameInfo
TargetFrameLowering
TargetRegisterInfo
MCFixup
MCRelocationInfo
ELFObjectWriter
```

Every completed slice must document whether it is:

```text
LLVM-aligned subset: same observable behavior for the selected tiny fixture.
local-only conservative: intentionally rejects behavior LLVM supports.
bootstrap-only: proves project structure but is not yet LLVM-equivalent.
```

## 1. IR Surface and Input Contract

- [x] Reconfirm the selected target/object pair: `x86_64-linux-elf`, SysV ABI,
      ELF64 relocatable objects.
- [x] Add a `FunctionDecl` or equivalent declaration representation for
      `declare` records.
- [x] Add a `CallInst` representation to core IR:
      callee symbol, return type, argument values/types, optional result name,
      and preserved calling convention/attribute spelling where supported.
- [x] Parse direct calls and function declarations before codegen lowering:
      `declare i32 @callee(i32)` and `%r = call i32 @callee(i32 %a)`.
- [x] Print declarations and call instructions in normalized LLVM-compatible
      text form.
- [x] Verify direct call type consistency:
      declared/defined callee exists when required, argument count/type match,
      result name exists only for non-void calls, and void calls have no result.
- [x] Add unsupported diagnostics for indirect calls, inline asm calls,
      varargs, unsupported calling conventions, operand bundles, invoke,
      callbr, musttail/tail attributes, and call attributes not yet modeled.
- [x] Define accepted function shapes:
      direct calls only, scalar integer/pointer arguments, scalar integer/pointer
      returns, no varargs, no aggregates, no floats/vectors, no EH.
- [x] Define accepted call targets:
      direct internal function symbols and direct external declarations.
- [x] Define accepted stack use:
      fixed frame slots and deterministic spills selected by this epic only.
- [x] Keep existing optimizer and parser behavior independent from codegen.

Suggested first slice:

- [x] Implement declarations, direct `call`, parser/printer/verifier support,
      and unsupported diagnostics without changing Machine IR or codegen.
- [x] Add IR round-trip tests before adding any call lowering.

## 2. ABI Call Classification

- [x] Extend x86_64 SysV ABI docs from leaf arguments/returns to call operands.
- [x] Write the concrete SysV stack rule in the ABI docs:
      on function entry `%rsp % 16 == 8`; immediately before a nested `callq`,
      the caller must have `%rsp % 16 == 0`.
- [x] Model integer/pointer argument registers:
      `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9` and their 32-bit forms.
- [x] Model return registers:
      `%rax`/`%eax` for scalar integer/pointer returns.
- [x] Model caller-saved and callee-saved register sets.
- [x] Reject stack-passed call arguments until outgoing stack argument layout is
      implemented.
- [x] Reject varargs, aggregate args, sret/byval/inalloca, floats, vectors, and
      non-default calling conventions.
- [x] Compare tiny call ABI examples with LLVM assembly from `llc-22`.

Suggested slice boundary:

- [x] Start with `call_no_args` and `call_one_arg` where no caller value is live
      across the call.

## 3. Machine Call Representation

- [x] Add Machine IR instructions for:
      direct call symbol, argument register moves, return register capture, and
      caller-saved clobber boundary.
- [ ] Extend the machine verifier:
      all call arguments are defined before the call, `%eax` is defined after a
      non-void call, and unsupported live caller-saved values are rejected.
- [x] Keep a deterministic physical-register plan. Do not introduce general
      register allocation in this epic.
- [ ] Add failure tests for live values across a call before spills exist.

Suggested slice boundary:

- [x] Implement calls only when the return value is immediately returned or
      unused.

## 4. Assembly Call Printing

- [x] Print `callq symbol` for direct internal/external calls.
- [x] Preserve existing function labels and local labels.
- [x] Add assembly golden fixtures for:
      `call_no_args`, `call_one_arg`, `call_two_args`, and `call_return_used`.
- [x] Compare selected assembly shape with `llc-22`, normalizing comments,
      `.cfi_*`, and harmless directive differences.
- [x] Keep PLT spelling, GOT references, tail calls, and indirect calls out of
      scope.

## 5. Object Relocations for Calls

- [ ] Add ELF64 relocation section support for `.rela.text`.
- [ ] Add undefined external function symbols to `.symtab`.
- [ ] Emit relocation records for direct `callq` targets that cannot be resolved
      as local fixed offsets.
- [ ] Use `R_X86_64_PLT32` for external direct `callq` relocations at first,
      with the usual x86_64 PC-relative addend for a 32-bit call displacement.
- [ ] Compare the relocation kind/addend against LLVM or assembler output for a
      tiny external-call object before marking relocation support complete.
- [ ] Inspect generated objects with:
      `readelf -r -s` and `objdump -dr`.
- [ ] Document mapping to LLVM `MCFixup`, `MCELFStreamer`, and
      `ELFObjectWriter`.
- [ ] Keep PLT/GOT, weak symbols, COMDAT, TLS, and dynamic linker semantics out
      of scope.

Suggested slice boundary:

- [ ] First support external direct call relocations.
- [ ] Then decide whether internal calls use relocations or resolved local
      displacements.

## 6. Stack Frame Foundation

- [ ] Add a frame model:
      fixed local slots, spill slots, frame size, stack alignment, and whether a
      frame pointer is used.
- [ ] Choose the first frame policy:
      no frame pointer, no red zone, fixed `%rsp`-relative offsets, and introduce
      `%rbp` only in a later slice if fixtures require it.
- [ ] Emit prologue and epilogue only for functions that need a frame.
- [x] Preserve SysV stack alignment before every `callq`:
      for call-capable functions without a full frame, subtract/add 8 around the
      call or create the minimal fixed frame needed to make `%rsp % 16 == 0`
      before the call.
- [ ] Add frame verifier checks:
      aligned frame size, non-overlapping slots, valid stack offsets, and no
      frame references without a frame.
- [ ] Document unsupported frame features:
      dynamic alloca, stack realignment, unwind metadata, shrink wrapping, stack
      probes, stack canaries, split stacks.

Suggested slice boundary:

- [ ] Implement a frame only for one fixed local slot or one deterministic spill,
      not for arbitrary alloca lowering.

## 7. Stack Slot Loads and Stores

- [ ] Add frame-index Machine IR operands.
- [ ] Add x86_64 stack-relative addressing for `%rsp` or `%rbp` based on the
      selected frame policy.
- [ ] Encode and print loads/stores for the integer widths required by fixtures.
- [ ] Lower simple scalar stack loads/stores selected for this epic.
- [ ] Reject volatile/atomic stack memory, unknown address spaces, unsupported
      widths, and pointer arithmetic outside the selected frame-index pattern.

Suggested slice boundary:

- [ ] Add stack slot assembly/encoding before integrating it with call spills.

## 8. Deterministic Spills Across Calls

- [x] Add explicit spill/reload Machine IR instructions.
- [x] Spill only known caller-saved values required by tiny call fixtures.
- [x] Reload spilled values after the call before their next use.
- [x] Add tests proving values survive calls.
- [ ] Document the boundary from deterministic spill insertion to real register
      allocation.
- [ ] Keep general liveness, coalescing, rematerialization, and spill-cost
      heuristics out of scope.

Suggested slice boundary:

- [x] Support one live value across one call before allowing multiple spills.

## 9. End-To-End Fixtures

- [ ] Add positive IR, expected assembly, and expected objdump/readelf fixtures:
      `call_no_args`, `call_one_arg`, `call_two_args`, `call_return_used`,
      `call_external`, `call_with_spill`, `call_with_local_stack_slot`.
- [ ] Add negative fixtures:
      varargs, aggregate args, floats, vectors, too many args, indirect calls,
      unsupported calling convention, call with unsupported live pressure.
- [ ] Keep each fixture tiny and independently reducible.
- [ ] Compare assembly with LLVM when the local accepted behavior is intended to
      match LLVM for the selected subset.

## 10. CLI and Test Workflow

- [ ] Keep `--emit=asm` and `--emit=obj` as the codegen entry points.
- [ ] Extend codegen fixture scripts to cover call assembly and objdump output.
- [ ] Add relocation inspection checks when `readelf` and `objdump` are
      available.
- [ ] Keep generated temporary objects under `/tmp` or `zig-out/`.
- [ ] Keep optimizer comparison tests independent from call-codegen tests.

## 11. Documentation and Inventory Updates

- [ ] Add `docs/codegen/calls.md`.
- [ ] Add `docs/codegen/stack_frame.md`.
- [x] Extend `docs/codegen/abi_x86_64_sysv.md` with call, stack alignment, and
      caller/callee-saved register rules.
- [ ] Extend `docs/mc/instruction_encoding.md` for `callq` and stack-relative
      load/store encodings.
- [ ] Extend `docs/mc/elf_object_writer.md` for `.rela.text` and undefined
      symbols.
- [ ] Update `docs/inventory/zig_llvm_api_inventory.md` for call lowering,
      frame lowering, relocation handling, and covered `TargetMachine.emitToFile`
      responsibilities.
- [ ] Update `docs/unsupported_ir.md` with call/frame codegen limitations.
- [ ] Update `docs/testing.md` with call/frame fixture workflows.

## 12. Verification Gate

- [ ] Run `zig fmt` on touched Zig files.
- [ ] Run `zig build test`.
- [ ] Run `bash scripts/compare_opt.sh`.
- [ ] Run assembly golden tests.
- [ ] Run objdump comparison tests.
- [ ] Inspect relocation records with `readelf -r -s` where available.
- [ ] Compare selected accepted cases with `llc-22` assembly shape.
- [ ] Confirm every unsupported call/frame path fails with a targeted diagnostic.

## Out Of Scope

- General register allocation.
- General spilling.
- Tail calls.
- Indirect calls.
- Varargs.
- Aggregate ABI classification.
- Floating-point and vector calls.
- Stack-passed arguments until explicitly promoted by a later slice.
- Dynamic alloca.
- Stack realignment.
- Stack probes and stack canaries.
- Exception handling and unwind info.
- Debug info.
- Linking, PLT/GOT policy, archives, and dynamic loader behavior.
- Multiple architectures or object formats.

## Success Criteria

This epic succeeds when the project can emit inspectable x86_64 assembly and
ELF64 relocatable objects for tiny direct-call functions while preserving:

```text
scalar argument registers
scalar return registers
SysV stack alignment before calls
minimal call relocations
deterministic local stack slots or spills
clear diagnostics for unsupported call/frame cases
```

The result does not need to be fast or general. It must be ABI-aware,
inspectable with local tools, aligned with LLVM's architecture at the subsystem
boundary, and honest about unsupported backend behavior.
