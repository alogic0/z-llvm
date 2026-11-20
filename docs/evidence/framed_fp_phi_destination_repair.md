# Framed Scalar FP Phi Destination Repair

schema_version: 1
directive: `INBOX-30` in-flight P0 repair
target: `x86_64-linux-gnu`
result: pass

Executable proof for the newly emitting half-log rows exposed a stale FP phi
edge: an early predecessor copied its branch-local computed value into an XMM
phi destination, a later CFG boundary migrated that destination to a spill
slot, and the merge reloaded the slot without the earlier edge ever having
written it. In `__log2h`, the correctly computed negative infinity from
`-1.0 / (x * x)` was therefore replaced by stale positive zero.

The repair gives scalar FP phi results a stable allocator-owned spill
destination immediately after frame preparation whenever the function already
has a frame. It allocates through `allocateSpillSlot`; it does not create a
parallel frame namespace or alter register-only, integer, vector, or unframed
phi handling.

The permanent executable regression computes distinct float results inside
both predecessor blocks, merges them through a framed phi, and checks raw bits
for both paths. It detects the original defect with `-1.0 / +0.0` and now
passes with `0xff800000`; the alternate path returns `2.0` exactly.

Audit: no previously accepted executable closure is invalidated. Existing
tanf/sinf/cosf row canaries passed, and the prior permanent FP phi test only
forwarded values already available before its predecessor blocks. The first
observed semantic failure was in the unaccepted INBOX-30 half-log row proof.

Focused repair-only validation passed `911/911` tests. The single cumulative
INBOX-30 Tier 3 run also includes this repair and passed all 17 subgates under
the staged source identity recorded in
`docs/evidence/distribution_all_after_inbox30_half_zero_fcmp.md`.

Log: `tmp/inbox30_fp_phi_repair_test.log`, sha256
`38bb1fee0c5cd453cfb40aa4865f9cdc89eb1471935f98ee6f71ed803339c848`.
