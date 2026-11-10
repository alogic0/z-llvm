# Independent stack-address eligibility

The private `stack_addresses` rewrite chooses scalar address views separately
for each owned local allocation. An object with a runtime memory length outside
that rewrite's bounded contract retains its original allocation and every use.
Other objects with proven layout, alignment and uses remain eligible. Their
ordinary pointer values are emitted by the existing typed address authority.

The memory length, object extent, allocation alignment and address-space
contracts remain unchanged. A function whose only candidate is ineligible still
has no stack-address rewrite. The immutable source IR, canonical identities,
preservation and transaction guards retain their existing ownership.

The twelve-function `stack_address_eligibility` population combines a dynamic
twelve-byte copy object with an independent i8/i16/i32/i64/i128/array object.
Both select-arm orientations, all copy lengths, live input and seed values,
unchanged local contents, destination guards and protected-page boundaries are
checked against an independent C oracle and LLVM execution. The generator is
`tools/generate_stack_address_eligibility_canary.zig`.

## LLVM 22 mapping

- `llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`,
  `visitAlloca`, obtains frame ownership per allocation through the function's
  `StaticAllocaMap` and represents an owned static allocation with a frame index.
- In that file, `visitSelect` selects pointer values independently of unrelated
  memory lengths; `visitGetElementPtr` forms their address offsets.
- `visitIntrinsicCall` carries the original memcpy source, destination and
  length into `DAG.getMemcpy`. Transforming a separate address does not extend
  that memory operation's permitted extent.

The focused original-function replay is selection evidence. Complete unchanged
input census, independent production and cumulative validation still accept the
compiler total; this population alone establishes no startup or self-rebuild.
