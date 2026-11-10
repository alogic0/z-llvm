# Owned stack-object addresses

Static scalar slots, 16-byte integer slots and i32 arrays carry
`stack_object` metadata with register width zero. That width describes storage;
it does not make the object's address a zero-width scalar. Inline copies consume
these homes through the typed `memcpy_pointer` form, independently of the i64
length form. The existing bounded memset contract remains separate.

Copy staging validates the complete object against the allocated frame and forms
its address directly in the requested 64-bit destination. It preserves pending
simultaneous operands, including sources temporarily held in RCX. It neither
loads the object's contents nor assigns a new identity to the original object.
The enclosing value-use transaction retains preservation, canonical resolution,
failure provenance, automatic rollback and action ownership.

Byte GEPs may use scalar frame objects and a named i64 offset. Address formation
does not itself access memory. Constant offsets retain the existing zero through
one-past envelope, and large arrays must fit the allocated frame. Existing
address-space, volatile and atomic boundaries remain.

Pointer PHIs can receive owned frame addresses in 64-bit registers or spill
slots. Before any destination write, an incoming pointer is snapshotted when a
preceding non-identity PHI transfer would overwrite it. This preserves parallel
PHI semantics for loop-carried swaps while leaving safe identity transfers
unchanged. Source identities are rebound only after their transfers. Ordinary
and boolean direct calls can pass the address of an owned array using the
existing call argument contracts.

The generator `tools/generate_stack_object_address_canary.zig` emits nineteen
functions and an independent C oracle. The registered population checks 9,480
observations per execution: exact copy lengths, untouched source and guard bytes,
unaligned outputs, local scalar/FP/pair/array storage, dynamic offsets, both PHI
edges, swapping loops, overlapping moves, clobbering calls and protected-page
boundaries. Ten numbered faults exercise the oracle. Focused tests also check
all five rollback boundaries, invalid frame extents and closed integer-length,
memset, metadata and address-space contracts.

## LLVM 22 mapping

- `llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`,
  `visitAlloca` and `visitGetElementPtr`, distinguishes frame allocation from
  pointer-valued address computation. `HandlePHINodesInSuccessorBlocks` explicitly
  materializes static alloca addresses used by PHIs.
- `llvm-project-22/llvm/lib/CodeGen/PHIElimination.cpp`, `LowerPHINode`, retains
  predecessor input values before replacing machine PHIs with transfers.
- `llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`,
  `visitIntrinsicCall`, carries source, destination, size and volatility into
  `DAG.getMemcpy`/`DAG.getMemmove`.
- `llvm-project-22/llvm/lib/Target/X86/X86SelectionDAGInfo.cpp`,
  `EmitTargetCodeForMemcpy`, stages pointer and exact byte-count operands for
  the x86 string-copy implementation.
- `llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp`, `LowerCall`,
  maps pointer-valued operands to the physical calling convention rather than
  interpreting their pointee storage as an argument value.

This capability proves selection and the registered native semantics. It does
not establish complete compiler object emission, startup or self-rebuild.
