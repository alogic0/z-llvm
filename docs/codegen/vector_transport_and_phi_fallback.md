# Vector addresses and owned PHI transport

Private integer-vector scalarization retains the existing i128 carrier boundary
for lane aliases of widths 65 through 127. Vector GEP indices become independent
scalar GEPs with the original source type, scalar base and corresponding lane
indices. This preserves stride, signed index interpretation and pointer lanes.

Indirect-edge PHI slots additionally carry the native two-double packed payload
used for binary128 representation. Whole SSA payload stores capture values before
an edge without floating arithmetic. A final optional fallback applies the same
owned slots and eager parallel snapshots to direct scalar/packed PHIs after
existing lowering declines them. Integer literal inputs normalize to their
original width before entering a wider slot, preserving unsigned high bits.
Literal carriers use the signed spelling of their final storage width, so
unsigned-spelled i32 all-ones values remain valid immediate stores.

For eight-byte scalar slots, a final address fallback materializes the owned
base before applying a constant sentinel offset. The existing object-address
authority and its two-word rejection boundaries remain unchanged.

Literal vector call arguments use temporary homes until their payloads reach
the ABI registers. The caller reclaims an allocation suffix only if it contains
exactly those staging homes and no durable spill allocation. This keeps repeated
calls bounded while retaining the established lifetime and rollback contracts.

The `vector_transport` native population checks wide-byte extraction through
ordinary calls, vector pointer addresses, raw packed PHI swaps and constants,
and a 97-call literal chain. Independent C expectations cover protected input
boundaries, unaligned exact stores, NaN payloads, caller clobbers and guards.
Original IR, value-use interfaces and frozen guard inventories remain unchanged.
