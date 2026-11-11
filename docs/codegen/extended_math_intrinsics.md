# Ordinary scalar math intrinsics

The final optional stage maps supported float, double, extended80 and binary128 math
intrinsics to the GNU libm calls used by LLVM22 on this target. It covers
truncation, rounding, ceil/floor, logarithms, exponentials, trigonometric
functions and fused multiply-add. Binary128 square root uses `sqrtf128`;
the other square-root formats keep their separate native-instruction boundaries.

Exact intrinsic signatures, argument types and call envelopes are checked.
Constrained operations, unsupported attributes, unused results and indirect
calls remain closed. Original IR stays immutable. Private calls drop the
intrinsic's advisory promises and tail hints, retain its result identity and
use the existing extended80 stack/ST0 or binary128 SSE transfer authorities.
The original composed form is tried first, retaining previous successful
selection owners and objects.
Outlined symbol names use static storage that survives private selector
arenas and remains valid through ELF relocation emission.

Canonical helper identity and module alias-chain checks prevent direct or
aliased recursive outlining. Alias cycles also fail closed. The mapping adds
references to existing standard library functions, without synthetic helpers.
Native populations can declare an optional `libraries` list in the registry;
the Zig runner passes those dependencies to both reference and selected links.
Existing entries without this field retain their link command arguments.

The local LLVM source describes these mappings in
`llvm/include/llvm/IR/RuntimeLibcalls.td` and
`llvm/lib/CodeGen/SelectionDAG/LegalizeDAG.cpp`. Retained LLVM22 assembly probes
verify extended80 `sinl`/`floorl`, binary128 `sinf128`/`floorf128`/`sqrtf128`, and
the separate `fsqrt` instruction for extended80.
