# Scalable CFG selection and indirect scalar PHIs

Canonical indexes own block identities for graph construction, verifier block
lookups, planning and selector transfers. Quoted aliases share a canonical key;
numbered names and quoted numeric strings remain distinct. Duplicate canonical
blocks reject. The allocation plan owns its transferred graph index, including
all error paths. Existing raw SSA keys and PHI target-spelling comparisons retain
their existing limits.

Liveness uses a predecessor worklist and every terminator successor, including
indirect branches. Duplicate switch edges contribute to edge counts while each
predecessor is visited once per adjacency list. A changed live-in set requeues
predecessors; live-out is recorded even when live-in is unchanged. Tests compare
against an independent forward full-sweep solution for loops and unreachable
blocks. Queues and acyclicity storage use actual input sizes. The private block
ceiling is 65,536; larger graphs reject explicitly.

An indirect target containing live scalar PHIs receives distinct private slots
allocated in entry. Every incoming predecessor stores to those slots before its
original terminator, including direct predecessors. Target loads and casts retain
the original result names and types. Integer source widths 1 through 128,
pointers and half/float/double payloads use i32/i64/i128/ptr carriers. Named incoming
values are frozen; pointer values retain explicit address formation. Undefined
incoming values choose zero/null. Writes remain private, and inactive poison
values are never observed through another edge's slot.

The rewrite preserves source instruction arrays, public signatures, original
block addresses, indirect target lists and terminators. It introduces no new
machine opcode or trampoline identity. Unsupported types and entry-target shapes
reject. Distinct slots preserve simultaneous copies, including loop swaps and
full i128 high words. All allocation failures clean up without source mutation.

Value-use-owned identities admit at most 512 bytes with u16 lengths across the
three owned representations. Max-plus-one rejects, and shared prefixes do not
alias. Transaction storage remains bounded at 688,656 bytes, alignment 16; the
separate address-dependency identity limit stays 192 bytes. Label retention owns
its complete fallible allocation work before one machine-instruction scan; an
allocation failure restores the prior owned-label prefix.

The frozen untyped bypass inventory and `lowerFreeze` fingerprint remain unchanged.
The [acceptance evidence](../evidence/scalable_cfg_indirect_phi.md) keeps complete
selection matching separate from native execution and whole-program readiness.
