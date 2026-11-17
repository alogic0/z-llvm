# Private construction for two small rewrites

Status: Tier-2 accepted with storage closure after table admission at `aa9149a1`.
Evidence root is
`local-state/validations/compiler-generalization/follow-up-20261116/stage-03`.

The builder composes the existing lazy `Candidate` and `TemporaryNames` helpers.
Floating pair loads and memory bitcasts retain their eligibility, temporary-name
order and instruction selection. Replacements stay at the source SSA position;
memory-bitcast allocas remain after entry PHIs. The candidate is published only
after complete construction, including any entry prefix.

The caller owns an arena for private candidate arrays, generated names and
replacement payloads. Unchanged source payloads, labels, parameters and metadata
remain borrowed and immutable. The builder closes its indexing and prefix
buffers; the caller closes the candidate lifetime. Mutable replacements use
`Instruction.clone`. Unsupported or allocation-failing attempts publish nothing
and preserve the complete source module.

Three regressions cover backing-allocation failures with source serialization
equality, snapshot order/metadata/PHIs, name collisions, borrowed storage,
idempotence and unchanged attempts. Metadata checks cover the project's raw
attachment preservation; they do not claim LLVM debug-metadata validity.
Fresh production checks pass all eleven selected tests in Debug/Fast and all
2,436 Fast units plus all 74 structural checks. Production compiler
`b6e3e883...` builds with unchanged source identities and the pinned SDK/library,
target and flags. Fixed Debug object and owner bytes remain exact. Both affected
native populations pass in all three modes through direct, optimized and
independent reference routes, with all 81 actual injected-failure controls.
Captured-row smoke, all 60 ABI cases, three hello_libc modes, fixed arithmetic
canaries and all 27 M1 executables pass. Final storage checks also pass.

The table predecessor is released after its consumers close. Final collector
receipt `1794911109412421958-4073179` reclaims 967,131,136 allocated bytes from
that compiler and closed qualification scratch. Earlier boundaries collect
425,787,392 unit bytes, 265,379,840 build bytes and 51,736,576 nested native bytes.
All seven current manifests verify, with seventeen holds and policy unchanged.
Only the rewrite compiler adopted for the byte-facts comparison and the isolated
prototype source/compiler remain owned pipelines, each with a named release.

This is construction maintenance with no scheduling or performance claim.
The earlier measured scheduling deferral remains unchanged. Final cumulative
integration is required before closing the later maintenance tracker.
