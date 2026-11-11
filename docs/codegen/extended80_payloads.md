# Extended80 payloads and direct calls

The private payload view represents `x86_fp80` values as exact `i80` bits and
uses the existing integer-pair normalization for register storage. External
loads and stores access exactly ten bytes. Owned allocations retain the
sixteen-byte allocation size and stride. Layouts with incompatible allocation
size or alignment, volatile/atomic accesses and address spaces remain closed.
Bitcasts, freezes, selects and PHIs preserve defined representation bits.

SysV parameters occupy aligned sixteen-byte stack slots independently of the
integer argument cursor. Private parameter and call-argument flags retain that
physical memory contract while their SSA types become integer carriers. Direct
integer/pointer calls reuse the existing outgoing stack locations, preservation
and pair-result handling. Mixed SSE calls retain independent register cursors
and stage complete memory arguments through the same physical layout. Indirect
calls, split integer words in mixed calls, SSE stack overflow, unsupported
attributes and `musttail` remain closed.

An extended80 result occupies ST0. Explicit machine transfers move an integer
pair to ST0 at return, and capture and pop ST0 after calls, including unused
results. Each transfer uses a balanced sixteen-byte stack temporary. Captures
zero the unused high forty-eight bits. A path-sensitive verifier checks x87
underflow, overflow, call boundaries, return depth and control-flow joins.
Literal returns are materialized in private IR before the existing pair-return
authority; the frozen bypass inventory is unchanged.

The generated `extended80_payload` native population covers arbitrary raw bits,
signaling NaNs, signed zero, exact access extents against a protected page,
sixteen-byte strides, PHIs, stable freezes, integer liveness, incoming memory
arguments, ST0 returns and nested direct calls. Its C driver uses integer
oracles, real register-clobbering providers, x87 TOP checks and memory guards.
The C extended type carries ABI bits; floating arithmetic does not provide the
oracle. Thirteen functions produce 53,248 observations per execution and three
injected fault controls exercise result, storage and guard checks.

This contract implements payload transport and direct ABI boundaries.
[Numerical conversions](extended80_conversions.md) have a separate helper and
rounding contract. Extended80 arithmetic and comparisons remain separate.
