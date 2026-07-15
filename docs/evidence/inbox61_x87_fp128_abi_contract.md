# ADR: x86_fp80 And fp128 SysV ABI / Register-Class Contract

status: provisional; stop and request review
directive: `INBOX-61`
date: 2026-07-15
baseline: `a1b739b7501d46a66034936e5253139524c78bcf`
target: `x86_64-linux-gnu`, SysV ABI, baseline CPU
zig_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
accepted_report: 443 selected / 285 emitting / 158 failing

## Scope And Decision

This is the read-only X1 architecture slice. It authorizes no selector,
verifier, test, gate, reporter, ABI-harness, encoder, object-writer, or
capability change. No gate or Tier 3 was run. The decision is that LLVM
`x86_fp80` and LLVM `fp128` are two independent ABI and register-class tracks:

| Concern | `x86_fp80` | `fp128` |
| --- | --- | --- |
| LLVM meaning | x87 80-bit extended format | IEEE-754 binary128 |
| SysV scalar class | `X87` + `X87UP` | `SSE` + `SSEUP` |
| Scalar parameter | memory, 16-byte slot/alignment | one XMM register, or one 16-byte stack object when the register assignment cannot be made |
| Scalar return | ST0, one 80-bit x87 value | XMM0, all 128 bits |
| Memory object | 10 significant bytes in a 16-byte object; 6 undefined padding bytes | 16 significant bytes; no padding |
| Native compute owner | x87 where its semantics match LLVM | no baseline x86 binary128 arithmetic; software lowering/helper |
| Transport owner | memory plus the x87 stack | XMM or memory |
| Spill owner | 16-byte-aligned frame object, `fstpt`/`fldt`, 10 significant bytes | 16-byte frame object, full-width XMM move |
| Fail-closed boundary | aggregates, complex x87, unmodeled stack depth/control state, or unqualified encodings | aggregates, partial XMM definitions, unavailable soft operation, or recursive helper lowering |

The classes above come from the official [x86-64 psABI classification and
passing rules](https://gitlab.com/x86-psABIs/x86-64-ABI/-/raw/master/x86-64-ABI/low-level-sys-info.tex).
LLVM independently defines [`x86_fp80` as an x87 80-bit type and `fp128` as
IEEE-754 binary128](https://llvm.org/docs/LangRef.html#floating-point-types).
The similar storage alignment does not make the two types interchangeable.

## Frozen Evidence And Topology

The reviewed capture is
`tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`.
Its observed MD5 is the pinned
`b0eda7a6427c3084fdf096a68696f19c`. A read-only signature join between that
capture and `tmp/inbox56_fma_report.log` reproduces the entire 118-row wall:

| Signature population | Parameter frontier | Return frontier | Total |
| --- | ---: | ---: | ---: |
| `x86_fp80` only | 18 | 47 | 65 |
| `fp128` only | 17 | 34 | 51 |
| mixed `x86_fp80` / `fp128` | 0 | 2 | 2 |
| **Total** | **35** | **83** | **118** |

The two mixed rows are `compiler_rt.trunctfxf2.__trunctfxf2`, returning
`x86_fp80` from `fp128`, and `compiler_rt.extendxftf2.__extendxftf2`, returning
`fp128` from `x86_fp80`. Both currently stop at the return frontier. The
diagnostic presentation is 18 `UnsupportedLongDoubleAbi`, 99
`UnsupportedCodegenControlFlow`, and one `UnsupportedCodegenInstruction`;
those labels do not alter the ABI root classification. The 65 / 51 / 2 and
83 / 35 topology is frozen until a separately authorized implementation slice
states and proves an exact expected delta.

This population remains a separate ABI/register-class project, not ordinary
scalar capability work and not part of O0-O6.

## Current Ownership Inventory And Invariant Gaps

| Surface | Evidence at HEAD | Contract gap |
| --- | --- | --- |
| Layout | `src/target/datalayout.zig` reports store sizes 10/16 bytes and 128-bit ABI/preferred alignment for `x86_fp80`/`fp128`; `src/analysis/memory_location.zig` agrees on significant byte size | No first-class distinction between fp80 significant size and 16-byte allocation/stride in every frame/call path |
| Capability boundary | `src/zig_air_capabilities.zig:boundaryForIrType` maps both types to `.x87` | `fp128` must have its own SSE-transport/software-compute boundary |
| SysV classifier | `src/codegen/x86_64/sysv_abi.zig` forces both scalar types and aggregate leaves to memory and `isScalarSseAbiType` excludes `fp128` | Missing scalar X87/X87UP and SSE/SSEUP classes, argument cursors, return locations, and aggregate recursion |
| Existing fp80 leaf | `src/codegen/x86_64/air_patterns_fp.zig` recognizes one exact fneg shape; machine/assembly/encoding emit `fldt 8(%rsp); fchs` | Exact leaf demonstrates bytes only; it does not supply general x87 value locations, stack-depth liveness, spills, calls, or return proof |
| Existing fp128 leaves | Exact fneg toggles the sign bit in XMM0; C ABI/debug rows contain full-width loads, stores, comparisons, and synthetic constants | Function/shape-specific paths are not a generic scalar ABI, allocation, call, spill, or software-operation contract |
| Verifier | `src/codegen/x86_64/verify.zig` tracks scalar SSE XMM0 only for half/float/double and currently groups both special fneg instructions with EAX definitions | No x87 stack state; no 128-defined-bit XMM scalar state; the special leaves can satisfy the wrong return proof |
| Encoder/printer | Exact fp80 fneg, fp128 sign toggle, and selected aligned fp128 moves exist | No typed general x87 instruction family, unaligned fp128 move choice, spill/call forms, or feature/operand verification |
| ELF writer | `src/mc/elf.zig` can append fp128 global bytes and attach PC-relative relocations to selected synthetic fp128 constant loads | No generic fp80 constant object; fp128 support is partly name-specific and does not cover generic constant identity/alignment/relocation selection |
| Semantics | `src/zig_air_semantics.zig` includes `fp128` in selected FP operation classification but excludes `x86_fp80` there | Type admission can diverge from ABI, lowering, verifier, and executable semantic qualification |

Existing exact leaves may remain quarantined, but they are not evidence that
either general track is implemented. A future route must not reach them by
claiming the other type's class.

## `x86_fp80` Contract

### Representation And Defined Bits

- An LLVM `x86_fp80` scalar carries 80 semantic representation bits. In
  little-endian SysV memory the low-address eight bytes contain the explicit
  64-bit significand and the next two bytes contain sign/exponent. The
  allocation size, ABI alignment, array stride, parameter slot, and spill
  object are 16 bytes.
- Bytes 10 through 15 are tail padding and undefined. They are never part of
  equality, hashing, constant identity, return comparison, or declared memory
  effects. Stores may leave them unchanged or unspecified; loads must not
  consume them. Canary coverage surrounds the 16-byte object but does not
  promote its padding into semantic data.
- Non-math transport must preserve all 80 representation bits. `fneg` changes
  only the sign bit, consistent with LLVM's [representation-preservation
  rule](https://llvm.org/docs/LangRef.html#behavior-of-floating-point-nan-values).
  No transport step may canonicalize NaNs, the explicit integer bit, zeros,
  pseudo-denormals, or unsupported encodings through an incidental arithmetic
  instruction. Arithmetic or conversion admission must separately qualify the
  LLVM-defined input domain and result semantics; otherwise it fails closed.

### Parameter, Return, And Register State

- The scalar classification is two eightbytes, `X87` followed by `X87UP`.
  For parameters both classes are passed in memory. The caller allocates one
  16-byte-aligned 16-byte stack object and supplies the 10 significant bytes;
  this argument consumes no GPR or XMM argument register.
- A scalar result is returned as one 80-bit x87 value in ST0. It is not sret.
  This compiler contract establishes no caller-live x87 value before a call;
  at the return boundary ST0 is defined and the logical x87 stack has depth
  one. ST1-ST7 contain no callee-owned live values. A void or non-x87 return
  must leave no leaked callee-owned x87 entries.
- The x87 stack is a distinct register class with depth, top, definedness, and
  value identity. ST numbers are stack-relative aliases, not eight ordinary
  independently allocatable registers. Every push, pop, exchange, spill,
  reload, call, branch join, and return updates one verifier-owned abstract
  x87 state atomically.
- All x87 data registers and the status word are caller-saved. The x87 control
  word is callee-saved. A lowering that changes precision, rounding, or mask
  controls must restore it on every exit. MMX aliasing is outside this track;
  any encountered MMX/x87-mode transition fails closed.

### Computation, Calls, Varargs, Spills, And Constants

- x87 owns native scalar `x86_fp80` arithmetic, comparisons, and conversions
  only when the selected instruction sequence is proven to implement LLVM's
  operation and floating-environment contract. Memory owns incoming
  parameters, constants, stable homes, and spills. SSE may copy opaque chunks
  only in a separately proven bit-transport path and never owns an fp80
  semantic value or result.
- Before an ordinary call, every caller-live x87 value has a stable spill home
  and no unmodeled temporary remains on the x87 stack. A call returning
  `x86_fp80` defines one new ST0 result; other calls invalidate caller-saved
  x87 data state. Direct, indirect, tail, invoke/unwind, and recursive calls
  are distinct admissions; unimplemented forms fail before emission.
- A variadic `x86_fp80` argument remains a 16-byte-aligned memory argument. It
  does not enter the register-save area and does not increment the hidden AL
  vector-register count. `va_arg` must align the overflow pointer, read only
  the 10 significant bytes, and advance by the 16-byte object. General varargs
  remain rejected until both caller and callee/`va_list` sides are executable.
- A spill is a 16-byte-aligned frame object. `fstpt` stores and pops exactly
  the significant 10 bytes; `fldt` reloads and pushes them. Spilling is not a
  raw register rename: stack depth and ownership change together. Branch joins
  require identical abstract x87 depth and compatible value homes.
- A generic fp80 constant is a 16-byte-aligned object with a 10-byte payload
  derived from the LLVM constant spelling and six non-semantic padding bytes.
  It needs ordinary symbol/section ownership and a normal relocation-bearing
  address/load path; a function-name or synthetic fixed-name constant table is
  not acceptable generic support.

### Conversions And Exclusions

- `x86_fp80` to/from f32, f64, and integers may use modeled x87 operations or
  proven software. The implementation must honor LLVM rounding, poison, NaN,
  and constrained/default-environment distinctions. It may not round through
  an intermediate f64 unless that is the specified operation.
- `x86_fp80` to/from `fp128` is the final mixed track. It requires a dedicated
  bit-level conversion or a non-recursive correctly rounded helper. It may not
  bitcast, route through host `long double`, or double-round through f64.
- `complex x86_fp80` (`COMPLEX_X87`, ST0/ST1), aggregates containing fp80,
  byval/sret interactions, varargs bodies, tail calls, exceptions/unwind, and
  non-SysV targets are independent later contracts. They remain rejected even
  after scalar argument/return transport is introduced.

## `fp128` Contract

### Representation And Defined Bits

- LLVM `fp128` is IEEE-754 binary128: 128 semantic bits in a 16-byte object
  with 16-byte ABI alignment and 16-byte array/spill stride. There is no
  padding. Memory comparisons, constant identity, spills, and declared effects
  cover all 16 bytes.
- A register value occupies one full 128-bit XMM register. Its low eightbyte
  is class `SSE`; its high eightbyte is `SSEUP` in the same XMM register, not a
  second XMM register. A definition is valid only when all 128 bits are known.
  Scalar-f32/f64 lane-definedness is not sufficient for `fp128`.
- Non-math transport and `fneg` preserve the entire representation except for
  the specified sign-bit change. Arithmetic follows LLVM binary128 semantics,
  including correctly rounded non-NaN results in the default environment;
  raw host `long double` is not a substitute.

### Parameter, Return, And Register State

- A scalar parameter consumes one of XMM0-XMM7 when one is available. The
  SSEUP half shares the same register. If the argument's complete register
  assignment cannot be made, that whole argument is reverted to one
  16-byte-aligned 16-byte stack object; it is never split between register and
  memory.
- A scalar return defines all 128 bits of XMM0. It is neither x87 nor sret.
  XMM registers are caller-saved, so no implementation or ABI-harness check
  may require their preservation across calls.
- The selector state and verifier need an `fp128` XMM value class carrying
  `defined_bits=128`, value identity, spill home, and ABI role. Every full or
  partial XMM instruction declares uses and defined lanes. A return, store,
  call argument, compare, or conversion fails if any of the 128 bits is not
  proven defined.

### Computation, Calls, Varargs, Spills, And Constants

- XMM owns transport and bitwise manipulation, not binary128 arithmetic.
  Baseline x86-64 has no scalar IEEE binary128 arithmetic instruction. Add,
  subtract, multiply, divide, compare, classification, and most conversions
  therefore require a reviewed integer/software lowering or an ABI helper.
  A compiler-rt helper body may not lower its defining operation by calling
  itself, an alias, or a cycle of equivalent helpers; recursion analysis is a
  fail-closed prerequisite.
- Call planning advances the XMM argument cursor once for an in-register
  scalar fp128 and preserves every caller-live XMM value before staging.
  Exhaustion reverts the whole fp128 argument to memory. A call result defines
  XMM0:128 and invalidates other caller-saved XMM values unless preserved.
- For variadic/prototype-less calls, an in-register fp128 contributes one to
  the hidden AL upper bound on vector registers used. The callee's register
  save and `va_arg` logic consumes one 16-byte XMM save slot; an overflow
  argument consumes one aligned 16-byte stack object. General varargs stay
  rejected until the fixed/variadic boundary, AL, register-save area, XMM
  exhaustion, and overflow path are all proven together.
- A spill is a 16-byte frame object. Use an aligned full-width move only when
  the address proof guarantees 16-byte alignment; otherwise select a legal
  unaligned full-width move. No spill/reload may use an f64-width instruction
  or leave the upper 64 bits stale.
- A generic fp128 constant is exactly 16 LLVM representation bytes with
  16-byte alignment. Both modern and legacy LLVM constant spellings must map
  deterministically to those bytes. The object writer must support ordinary
  local/global symbol ownership and the selected RIP-relative relocation; the
  current fixed synthetic symbol names are not a generic constant contract.

### Conversions And Exclusions

- f32/f64/integer to/from fp128 use reviewed software or non-recursive helpers
  with LLVM rounding, poison, NaN, and constrained/default-environment rules.
  x87 must not silently stand in for binary128 and an intermediate f64 is not
  permitted unless the IR explicitly requests it.
- Aggregate recursion involving fp128 must eventually implement the complete
  psABI eightbyte merge and post-merge rules. It is not implied by scalar
  SSE/SSEUP support. Complex fp128, byval/sret, varargs bodies, tail calls,
  exception/unwind paths, and non-SysV targets remain separately rejected.

## Verifier, Encoder, And Object Requirements

The verifier is the admission boundary, not a post-hoc byte check.

| Authority | Required `x86_fp80` proof | Required `fp128` proof |
| --- | --- | --- |
| ABI classifier | exact X87/X87UP parameter-memory and ST0-return classification; stack slot alignment/size | exact SSE/SSEUP single-XMM classification, cursor use, whole-argument rollback, and XMM0 return |
| Value locations | x87 value identity, logical depth/TOP, significant width, stable memory home | one-XMM identity with 128 defined bits, stable 16-byte home |
| Machine use/def | stack pushes/pops/exchanges and control-word effects; calls invalidate caller-owned state | per-lane/full-register definitions, caller clobbers, SSEUP tied to preceding SSE |
| CFG join | equal depth and compatible value homes on every predecessor | compatible full-width location/home and no partially defined merge |
| Return | exactly one defined ST0 result and restored control word/frame | XMM0 defined through bit 127 and restored frame |
| Negative/fail-closed | underflow/overflow, leaked x87 entry, wrong TOP, control-word clobber, MMX transition | upper-half undef, two-XMM split, partial register/memory argument, accidental x87 use |

Encoder/printer work must be typed rather than a new collection of terminal
byte recipes. Required forms include the chosen x87 loads/stores, stack
operations, arithmetic/conversion instructions, x87 environment access needed
by verification/harnesses, full-width aligned and unaligned XMM moves, and
ordinary call/branch forms. Each form needs operand validation, exact size,
assembly, encoding, feature legality, and instruction-level use/def metadata.

Object support requires deterministic 16-byte constant alignment, correct
section size/content, ordinary symbols, relocation kind/addend/range checks,
and readelf/objdump-visible identity. fp80 emits a 10-byte semantic payload in
its 16-byte object; fp128 emits all 16 semantic bytes. Relocations must target
the actual constant symbol and selected addressing form. Missing alignment,
symbol, relocation, or range support rejects emission rather than substituting
an absolute address, a host runtime value, or a name-specific constant.

## Staged Implementation Boundaries

These are proposed review units, not authorization. Tracks F80 and Q128 may be
scheduled independently after the shared model, but neither may borrow the
other's register class or acceptance claim.

| Stage | Bounded scope | Measurable exit | Fail-closed edge |
| --- | --- | --- | --- |
| X1-A shared model | Split `.x87` and `.fp128` capability boundaries; represent X87/X87UP/SSEUP and typed 10-of-16 versus 16-of-16 layout; retain the frozen ABI row census | Classification tables match the decision; accepted 443/285/158 and 65/51/2, 83/35 remain unchanged | No selector admission, success-owner observability, or machine emission |
| F80-1 scalar boundary | One fp80 memory parameter, ST0 return, x87 stack/control verifier, typed `fldt`/`fstpt`/`fchs` transport | Identity and fneg execute across object boundaries; padding is ignored; negative stack/control cases reject | No calls, general arithmetic, aggregate, complex, or varargs |
| F80-2 homes and calls | Frame spills/reloads, constants/relocations, direct non-variadic calls, caller-live preservation | Nested call and spill pressure preserve values/depth/control word; object inspection proves constants/relocs | No indirect/tail/unwind or variadic calls |
| F80-3 semantics | One reviewed operation/conversion family at a time, including constrained/default FP qualification | Every admitted operation has bit-differential edge coverage and no host-libm substitution | No mixed fp128 conversion; no recursive helper |
| Q128-1 scalar boundary | One-XMM parameter/return, 128-bit definedness, full-width transport/fneg, XMM exhaustion stack fallback | XMM0-XMM7 and stack cases execute; upper-half-undef negatives reject | No arithmetic, aggregate, calls needing helpers, or varargs |
| Q128-2 homes and calls | Full-width spills/reloads, constants/relocations, direct calls and caller-live preservation | Alignment/unaligned paths, call clobbers, constant bytes and relocations are executable/object-proven | No indirect/tail/unwind or variadic calls |
| Q128-3 software semantics | One non-recursive software operation/conversion family at a time | Exact binary128 differential results and helper-call graph audit pass | No aggregate generalization or mixed fp80 conversion |
| VARG | Separate caller/callee varargs slice for each type | AL count, save-area/overflow access, exhaustion, alignment, and `va_copy`/iteration cases execute | Neither type's varargs success admits the other |
| MIX | The two frozen conversion rows only after both scalar tracks are accepted | `__trunctfxf2` and `__extendxftf2` pass exact differential and ABI-state proof with no f64 intermediate | No aggregate/complex widening |

Every stage states its expected row and owner delta before implementation.
Unexpected capture, a different frontier, a need for a function-name predicate,
or a new register/frame/object authority is a stop condition. No stage may
batch ABI infrastructure, arithmetic families, aggregates, varargs, and mixed
conversions into one review.

## Executable Differential Strategy

Once separately authorized, extend the non-gating INBOX-60 ABI harness rather
than create a second provenance model. Reference and candidate remain separate
executables built from one frozen source/body digest with the pinned
LLVM-backed Zig and z_llvm respectively. Inlining/substitution stays disabled;
object symbol/body inspection or a linker map proves which implementation is
executed. Results are never cached. The internal counters remain
`real_execution_attempted` and `real_execution_matches`; no distribution
counter or Tier-2 ratchet changes as part of X1.

Use two separately reported manifests:

| Proof | `x86_fp80` executable observation | `fp128` executable observation |
| --- | --- | --- |
| Input ABI | wrapper places 10 initialized bytes in an aligned 16-byte stack object; padding is deliberately varied but ignored | wrapper supplies all 128 bits in the selected XMM register and separately forces register exhaustion/stack fallback |
| Return bits | wrapper pops ST0 with `fstpt` into an initialized aligned object and compares exactly bytes 0-9 | wrapper stores full XMM0 and compares all 16 bytes |
| ABI state | existing GPR/RSP/canary/DF checks plus x87 depth/TOP, leaked entries, and callee-saved control word | existing checks; XMM remains caller-saved, but return/argument definedness is checked at the typed boundary |
| Calls/spills | nested leaf and non-leaf cases with live x87 values, forced spill/reload, branch join, and control-word negative | live XMM pressure, XMM0-XMM7 exhaustion, forced aligned/unaligned homes, call clobber and return |
| Varargs | stack alignment/advance, no AL increment, no register-save-area read | one XMM/AL contribution, save-area access, then overflow-stack access |
| Objects | exact 10-byte payload, 16-byte object/alignment, symbol and relocation | exact 16-byte payload/alignment, symbol and relocation |

Fixed UB-free inputs cover both signs of zero, exact finite normals, minimum
normal/subnormal boundaries, infinities, and quiet/signaling NaN payloads for
operations whose result bits are specified. fp80 raw-transport cases also
cover explicit-integer-bit edge encodings without using them as arithmetic
inputs unless LLVM/reference behavior is qualified. Comparisons distinguish
bit-preserving operations from arithmetic operations whose NaN result payload
is not uniquely specified. No case uses host `fma`, libm, printf conversion,
or host C `long double` as the oracle.

Required negative controls include swapped register classes (fp80 in XMM or
fp128 in x87), comparison of fp80 padding, x87 underflow/overflow or leaked
stack entries, control-word clobber, fp128 undefined upper 64 bits, fp128 split
across two XMM registers, misaligned/partial spill, wrong variadic AL count,
wrong relocation/constant bytes, recursive reference substitution, timeout,
and unauthorized memory writes. Any mismatch, missing provenance, unsupported
termination class, or semantically unqualified case fails closed.

Promotion into mandatory Tier 2 is a later decision. At promotion, Tier 2 must
cover the whole frozen captured-row cohort and exact expected topology delta;
Tier 3 follows only the separately accepted milestone trigger.

## Handoff And Stop State

`INBOX-61` is acknowledged. The only change in this cycle is this contract and
its embedded handoff. No selector, test, fixture, gate, reporter, harness,
ratchet, code generator, verifier, encoder, object writer, retention data, or
frozen evidence was changed, and no gate or Tier 3 was run.

Stop here for Supervisor/Reviewer review. Implementation must not begin until
a specific stage above is separately authorized with its expected topology
delta and validation budget. O0-O6, all X1 implementation stages, preopt
sharding, retention cleanup, ABI-harness promotion, and distribution-counter
migration remain unauthorized.
