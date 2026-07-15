# INBOX-60 Minimal ABI Differential Evidence

Status: **provisional, non-gating; stop and request review**

Directive: `INBOX-60`

Evidence run: 2026-07-15, `tmp/inbox60_abi_diff/accepted7`

Accepted baseline: `0025b18b3339c98018d3e276c7120d73b6ad1682`

This checkpoint adds no Tier-2 requirement or ratchet, changes no distribution
counter, and runs no distribution, Tier-2, Tier-3, preopt-sharding, AIR-export,
or patched-Zig-build path. Promotion and the `real_programs_ok` /
`real_executed` migration remain separately unauthorized. O0-O6 and X1 also
remain unauthorized.

## Pinned construction

| Field | Frozen value |
|---|---|
| Zig source | `bdee02bc0c7f227c0f11bc9a449df673fe803540` |
| Reference compiler | `0.17.0-dev.364+bdee02bc0` from `../ziglang/build/stage4/bin/zig` |
| z_llvm source baseline | `0025b18b3339c98018d3e276c7120d73b6ad1682` |
| z_llvm executable SHA-256 | `5653cc7eda5f1a915a4a2c583b37868048c2c345ca9425de53ee3806314401be` |
| Target | `x86_64-linux-gnu` |
| CPU/features | `baseline` / baseline target features |
| Modes | `ReleaseFast`, `ReleaseSafe`, `ReleaseSmall` |
| Cohort body SHA-256 | `5377aa82439bf2be1dcb804fc2772392eef204e1e6160e868719cfe8005595d3` |
| Harness SHA-256 | `40ff1703d842ea4ed81a0907721519d61d68465c05912a6b7408e42c4d4aa207` |
| ABI shim SHA-256 | `5c3123b586af78786e2371a0b8b623997f47238043d0bdec0979cc29dabd6dac` |
| Scratch ceiling / observed | 268,435,456 / 39,225,114 bytes |

The harness and shim are compiled once and the same object bytes are linked
into reference and candidate executables. Each mode compiles
`test/abi_diff/cohort.zig` twice: ordinary pinned LLVM-backed Zig for the
reference object and the accepted postopt object hook with
`ZIG_USE_ZLLVM_OBJECT=1` for the candidate object. `-fno-lto` and separate
objects prohibit cross-boundary inlining or body replacement.

Provenance fails closed unless all ten exported symbols occur exactly once in
each body object, are disassemblable, the candidate hook marker says
`pipeline=postopt`, target and mode match, reference and candidate object
digests differ, and every linked function begins with the exact instruction
bytes from its selected body object. This proves that no reference body was
substituted into the candidate executable. The frozen cohort-source digest is
the body identity across modes; mode-specific object digests are recorded in
the result table below.

## Audited leaf cohort

All inputs are compile-time fixed, initialized, and UB-free. Integer negation
and the memory-row addition use explicit wrapping operations. FP cases are
finite, exactly representable values; there are no NaNs, random values,
uninitialized padding bytes, poison-dependent operations, or compared absolute
addresses.

| Symbol and exact C ABI signature | Fixed cases | Purity and compared effect |
|---|---|---|
| `abi_neg_u64(u64) -> u64` | `0`, `UINT64_MAX` | Deterministic call-free leaf; no memory access; exact 64 return bits. |
| `abi_select_i32(i32, i32, u8) -> i32` | `INT32_MIN`, `INT32_MAX`, selector 0/1 | Deterministic call-free leaf; no memory access; exact 32 return bits. |
| `abi_identity_u8(u8) -> u8` | `UINT8_MAX` | Narrow-return leaf; low 8 bits authoritative, upper RAX diagnostic only. |
| `abi_identity_i16(i16) -> i16` | `INT16_MIN` | Narrow-return leaf; low 16 bits authoritative, upper RAX diagnostic only. |
| `abi_pointer_load_store(*const u32, *u32) -> u32` | source `0xfffffff0`, destination `0x11223344` | Reads exactly source and writes exactly destination with wrapping `+7`; initialized surrounding canaries and unchanged source are required. |
| `abi_load_u32(*const u32) -> u32` | `0x80000001` | Reads exactly one initialized `u32`, writes nothing. |
| `abi_identity_ptr(*const u8) -> *const u8` | initialized array element 3 | Performs no dereference or write; returned address is compared only as normalized offset `3`. |
| `abi_neg_u128(u128) -> u128` | zero and `0x0123456789abcdeffedcba9876543210` | Deterministic call-free leaf; exact RDX:RAX 128-bit return. |
| `abi_add_f32(f32, f32) -> f32` | `1.5 + 2.25`, `-8 + 0.5` | Finite FP leaf; exact declared f32 bits from XMM0. |
| `abi_mul_f64(f64, f64) -> f64` | `-3.5 * 8`, `0.5 * 0.25` | Finite FP leaf; exact declared f64 bits from XMM0. |

The common runner emits only declared return bits, declared memory state,
normalized pointer offsets, ABI status, and canonical `term=normal` to its
comparison stream. Raw upper-RAX values for `u8` and `i16` are emitted on a
separate diagnostic stream and are deliberately excluded from equality.
Non-normal exit, signal, or timeout is rejected rather than compared through
unstable text or addresses.

## ABI shim

`test/abi_diff/abi_shim.S` preserves the runner's incoming ABI state, seeds and
checks RBX, RBP, and R12-R15, verifies RSP restoration and pre-call alignment,
checks two stack-frame canaries, and tests then clears the direction flag.
Status bits are RBX `1`, RBP `2`, R12 `4`, R13 `8`, R14 `16`, R15 `32`, RSP
restore `64`, RSP alignment `128`, canaries `256`/`512`, and DF `1024`.
Every accepted call returned status zero. XMM registers are intentionally not
preserved or checked because they are caller-saved in the x86_64 SysV ABI.

## Three-mode results

| Mode | Reference object SHA-256 | Candidate object SHA-256 | Fresh comparisons | Result |
|---|---|---|---:|---|
| ReleaseFast | `f682376dccce90a26592b41322d0445844a897c2694907e0f0bfeab3f53ea1c0` | `7c8b3c62d835d5b7e759a38c5f5d6cd8d7185f665ca16346747c83548bc2046a` | 15/15 | match, normal termination |
| ReleaseSafe | `ff20d07915ad54d2541d60532adf73e2c35a72167a46f60e44a76b2c32174410` | `7c8b3c62d835d5b7e759a38c5f5d6cd8d7185f665ca16346747c83548bc2046a` | 15/15 | match, normal termination |
| ReleaseSmall | `ce84e57ba942b38b6a4fa23917588405aa57a7003f82b00a5f854719e2b901f2` | `7c8b3c62d835d5b7e759a38c5f5d6cd8d7185f665ca16346747c83548bc2046a` | 15/15 | match, normal termination |

Internal, non-distribution counters are
`real_execution_attempted=45` and `real_execution_matches=45`.
`real_programs_ok` remains reserved and unchanged. The tool requires a new,
nonexistent scratch directory and always executes both binaries; execution
results are never cached or reused.

## Negative controls

| Deliberate fault | Required observation | Result |
|---|---|---|
| Flip one declared value in the candidate stream | exact comparison rejects | rejected |
| Present the reference body as the candidate body | provenance rejects equal object digest | rejected |
| Assembly leaf clobbers RBX | ABI status bit `1` is observed | rejected |
| Assembly leaf never returns | one-second supervisor yields canonical timeout | rejected |
| Assembly leaf writes one byte before its declared buffer | initialized left canary changes | rejected |

## Reproduction and stop state

Use a fresh path; the command is evidence-only and is intentionally not wired
into any gate:

```sh
tools/run_abi_differential.sh tmp/inbox60_abi_diff/review-run
```

The command surface contains only small `build-obj` invocations, common C/asm
compilation and linking, object inspection, and bounded executable runs. It has
an explicit 256 MiB hard ceiling and never invokes `zig build`, a full AIR
export, a patched-Zig build, distribution-all, Tier 2, Tier 3, or preopt.

`INBOX-60` is acknowledged. This delivery stops here and requests review.
Preopt sharding remains deferred for user-supplied headroom. No promotion,
counter migration, retention action, O0-O6/X1 slice, or later checkpoint step
has begun.
