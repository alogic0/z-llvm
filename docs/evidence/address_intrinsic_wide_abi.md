# Constant addresses, intrinsic facts and wide integer ABI carriers

Status: accepted at `761ea199`; all 17 cumulative gates pass.
Plan: [constant addresses, intrinsic facts and wide ABI carriers](../plans/2026-11-08-address-intrinsic-wide-abi.md).
Raw evidence: `local-state/validations/address-intrinsic-wide-abi-20261108/`.
Baseline: accepted implementation `baf7a767`, documentation base `c471c743`.
Implementation commits: `8f803cc5` (addresses), `421be498` (intrinsic facts),
`761ea199` (integer carriers).
Machine-readable [acceptance record](address_intrinsic_wide_abi_acceptance_20261108.json).

## Shared contracts

The previous main memcpy-source group contained 1,771 constant pointers. Their
byte GEP expressions carry both `inbounds` and `nuw`, while the shared address
parser admitted only `inbounds`. It now recognizes the known `inbounds`, `nuw`
and `nusw` vocabulary. These poison constraints do not alter the address on a
defined execution. Duplicate or unknown flags, unsupported address spaces and
offsets outside the signed 32-bit relocation range remain rejected.

Module context can prove a supported alias chain reaches ordinary data. It
retains the original alias symbol for relocation, visibility and interposition;
it does not silently redirect the relocation to the underlying global. Alias
admission requires the complete dependency route. The data-alias proof rejects
weak, unknown, cyclic and function targets; global-property validation still applies.
The existing dependency, exact-width and transaction contracts remain in use.

The shared scalar-integer intrinsic validator now accepts validated advisory
facts through the ordinary ABI attribute validators. Integer saturation, min/max
and bit-reversal expansion use this admission contract. Private overflow calls
drop scalar return facts when their result becomes an aggregate, and widened
bit-reversal calls omit facts about the original narrow result. Argument facts
are omitted on the private overflow helper. Source IR remains unchanged;
unsupported calling conventions, envelopes and ABI promises stay rejected.

The existing narrow ABI legalizer now handles all non-native integer widths
from 1 through 63: widths below 32 use 32-bit carriers, and widths above 32 use
64-bit carriers. The receive mask precedes publication of the logical value.
Outgoing values preserve their low bits, and private carriers omit advisory
payload facts that do not describe unspecified padding. Explicit extension
requirements and other unsupported ABI forms retain their boundaries.

## Executable evidence

Three permanent native populations add nineteen functions:

| Population | Functions | Observations per mode and route | Main cases |
| --- | ---: | ---: | --- |
| `constant_pointer_memory` | 7 | 96 | GEP flags, alias chains, signed offsets, dynamic/zero lengths, exact writes, live values and a destination guard page |
| `intrinsic_facts` | 6 | 1,536 | Saturation boundaries, wrapped range facts, i23/i6 operations, bit reversal and live values across a real clobbering call |
| `wide_abi_carriers` | 6 | 1,536 | i33/i37/i49/i63, dirty incoming/returned padding, mixed register/stack arguments, PHIs, negative constants and clobbering calls |

Both final Debug and ReleaseFast compiler builds pass all three populations in
Fast, Safe and Small, through direct and release-pass routes. Each compiler
build checks 19,008 local observations against 9,504 LLVM-reference observations.
The previously accepted compiler rejects all three valid new fixtures. All
fifty prior registry entries and their fixture sources remain unchanged.
The intrinsic fixtures establish their range facts with masks or saturating
operations. The ABI driver supplies inputs within its wrapped ranges and
compares only logical return bits; unspecified padding is deliberately dirtied.

Unit coverage extends execution checks to every non-native width 1–63 and
checks source immutability, private carrier types, unsupported ABI attributes,
alias proof and relocation identity, and facts on generated aggregate results.
Debug and ReleaseSafe each pass 1,955 units and 21 structural checks. The two
profiling-process tests, five whole-compiler reporting tests and readiness pass.

## Complete unchanged-input replay

Every implementation slice replays all 8,928 compiler definitions and all 455
runtime definitions. Source/input/binary manifests and every per-function result
are retained for each checkpoint.

| Checkpoint | Compiler selected | Compiler rejected | Additional selections | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Baseline `baf7a767` | 4,341 | 4,587 | — | — |
| Addresses `8f803cc5` | 6,147 | 2,781 | 1,806 | 0 |
| Intrinsic facts `421be498` | 6,734 | 2,194 | 587 | 0 |
| Wide carriers `761ea199` | 6,752 | 2,176 | 18 | 0 |

The final compiler adds 2,411 selected identities while preserving all 4,341
baseline successes. Runtime remains 274 selected and 181 rejected at every
checkpoint, with no lost successes. Removing a first rejection can expose a
different one; the original group sizes were not predicted completion counts.

The final production ReleaseFast compiler matches the last diagnostic
classifier's selected identities and every failure tuple for both inputs. The
comparison maps only absent CLI tag/detail markers `-` to JSON null. The
production report verifies source/backend identity before and after each replay.
No complete compiler or runtime object is emitted, so compiler startup and
self-rebuild remain unaccepted.

The compiler and runtime streams contain 3,508,029 and 70,370 events. Audits
verify every sequence number, elapsed-time ordering, unique function identity,
balanced activity/legalizer/retry records and final counters. Compiler selection
takes 913.26 seconds with 6,520,732 KB maximum RSS; runtime takes 1.08 seconds.
These include profiling and concurrent validation and are not throughput
comparisons.

The final largest compiler first-failure groups are 372 global GEP property
rejections, 217 LLVM intrinsics, 184 register-pressure rejections, 160 comparison
right operands and 123 unsupported alloca types. These counts use the complete
diagnostic/tag/detail tuple; one additional intrinsic failure has a different
outer diagnostic. The intrinsic frontier contains no saturating-add rejection,
and the call argument/return width groups are empty.

One memcpy source remains: `hash.auto_hash.hash__func_10563` passes a dynamic
length from a `stack_scalar` allocation. This is outside the repaired constant
address contract. The next slice should classify the concrete global properties
behind the 372 rejections before extending their shared admission contract, then
replay both complete inputs and retain every current success.

## Cumulative acceptance and retention

The final cumulative run passes all seventeen gates in 3,654.77 seconds. All
53 native populations pass: 1,829,892 local observations against 914,946 LLVM
references. Every prior population retains its observation counts and fixture
sources. Only `full-acceptance.log` supplies cumulative acceptance.

Core counts remain 100 lowered/emitted/linked and twelve executed per mode,
with bypass ratchet 130 unchanged. All 36 records preserve selected-object bytes,
observations and linked executable sizes. Reference wrappers grow by 32 bytes
in 24 records; reference and linked hashes are compared separately, without
claiming complete executable byte identity.

The five fixed Zig programs pass all fifteen program/mode pairs with unchanged
source, manifest and emitter identities. The unchanged Zig input corpus passes
87 pairs and 603 controls, preserving independent expected observations and
prior selection counters. The C input corpus passes 138 pairs and 552 controls
with unchanged source/manifest identities and observations. Execution controls
match all 21 function/mode pairs, 22,788 observations and 54 fault detections.
The behavioral suite retains 6,528 observations.

Postchecks verify all 1,747 frozen compiler/tool/test/build inputs and membership,
both compiler identities, the default compiler, original compiler/runtime inputs,
the prior 577-artifact acceptance manifest and all thirteen scratch files.

An initial cleanup removes 2,366,296,064 allocated bytes from nineteen obsolete
project object-cache directories before admission. A later cleanup removes
1,119,113,216 allocated bytes from completed project/test caches and replaces
three duplicate 443,624,107-byte input allocations with hard links. All twelve
input paths and hashes remain, and the original capture inode is unchanged.
Retained compiler binaries, accepted evidence, original inputs and scratch files
are preserved. Removed allocations and duplicate payload bytes are recorded
separately from free-space changes during concurrent work.

The first cumulative attempt is excluded: removing a cache entry during its
behavioral phase left a later `zig build run` unable to install the compiler.
The audit found no open cache files, but later build steps still needed them.
Stale cache manifests were reset; the rebuild produced a different
binary identity, so the previously validated compiler was restored to its same
cache key and reinstalled. Both the cached/default and retained compiler hashes
were verified before the entire cumulative gate rerun. A setup-only retry
refused the retained scratch directory; the final run uses a fresh scratch root.
The runtime's first production wrapper also stopped at disk admission; the complete
`runtime-replay-final` report supplies its accepted result. These attempts
remain with their diagnostics. No archives were created. Admission remains
32,949,672,960 bytes and execution reserve remains 24,359,738,368 bytes.

The cumulative runner's minimum and final boundary sample is 29,818,310,656
bytes free. Eighty-five additional samples record a lower minimum of
28,366,610,432 bytes, still above the execution reserve.
