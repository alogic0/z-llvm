# INBOX-66 Mandatory Audited Compiler-rt ABI Gate

Directive: `INBOX-66`

Status: implementation, mandatory Tier 2, and the INBOX-66C acceptance
continuation are complete. Acceptance criteria are satisfied and Supervisor
acceptance is requested. See `inbox66c_acceptance_continuation.summary.md`.

## Population and counter decision

This gate promotes the INBOX-60 differential mechanism, but replaces every
synthetic function with exactly ten accepted real compiler-rt rows. It does
not execute or make claims about the separate 100-row compiler-core
distribution population.

The explicit schema migration is:

- `distribution-real-rows-v1` allowed a candidate-only zero exit to increment
  `real_executed` and then `real_programs_ok`. That was not a behavioral match.
- `distribution-real-rows-v2` ends the compiler-core row gate at native-link
  evidence. Its existing 100/100/100 ratchets are unchanged; `real_executed`
  and the whole-program-reserved `real_programs_ok` remain zero.
- `abi-diff-v2` is a separate compiler-rt summary containing only
  `abi_diff_cases_attempted`, `abi_diff_cases_matched`, and
  `abi_diff_real_functions_matched`. The accepted ratchets are 20/20/10 in
  each execution mode and 60/60/30 overall.

No historical evidence file is rewritten by this migration.

## Audited cohort

The authoritative machine-readable audit is
`test/abi_diff/cohort_manifest.tsv`. It records the category, exact accepted
row identity, exported ABI alias and signature, accepted selection owner,
accepted captured-function digest, pinned upstream source and digest,
leaf/effect audit, declared memory effects, and fixed case ids.

The category split is exactly 2 integer, 2 narrow-return, 2 pointer-memory, 2
i128, and 2 finite-FP rows. `composed_block` and `composed_cfg` are both
represented. The two f16 narrow returns use their declared XMM0 bits; no
unspecified upper register bits participate in a match. The pointer/memory
rows may initialize exactly one caller-owned `c_int`; canaries immediately
outside that object must remain unchanged. All fixed inputs respect the shift
preconditions, avoid signed-negation minima, use valid aligned pointers, and
use finite FP values.

The extracted Zig module freezes source-identical bodies and the target-
specialized compile-time branches from the pinned compiler-rt sources. These
bodies are compiled as the canonical ReleaseFast accepted compiler-rt body
population. The surrounding harness and z_llvm mode identities are exercised
as ReleaseFast, ReleaseSafe, and ReleaseSmall. This avoids injecting ordinary
ReleaseSafe application safety calls into compiler-rt rows that are not in the
accepted captured cohort. The separate controlled panic object is compiled
ReleaseSafe.

## Provenance and comparison

Every run uses a new scratch directory and builds fresh executables. The
runner fails closed on a missing tool or identity mismatch and records:

- current z_llvm commit and executable digest; pinned Zig commit/version;
  target, CPU/features, mode, postopt hook marker, captured IR digest, and
  frozen accepted-capture identity;
- reference and hook-produced candidate object digests;
- ELF symbol type/binding/visibility, executable section and flags, exact
  offset and size, body bytes/digest, and relocations for every real row;
- the separate C harness and assembly ABI-shim identities; and
- a native linker map whose candidate `.text` range contains every executed
  alias and whose `LOAD` entry names the exact candidate object.

Re-emitting the captured candidate IR must reproduce all candidate text bytes.
Reference and candidate object digests are allowed to be equal. The reference-
substitution negative instead fails the exact candidate-object path plus
linker-map resolution authority.

Each of the twenty fixed inputs runs in its own reference and candidate
process. The attempted counter increments immediately before that pair. A
match is counted only after exact declared-return bits, bounded memory effects,
all ABI-shim bits, and normal termination agree. The function counter moves
only after both cases for that row match.

The assembly shim checks RBX, RBP, R12-R15, RSP restoration and call alignment,
two stack canaries, and the direction flag. XMM registers remain caller-saved.

## Termination and negative controls

The designated ReleaseSafe `@panic` case is outside the ten normal rows. Its
source/object/symbol provenance converts the expected SIGILL trap into the
canonical `panic` class on both sides. Normal rows accept only normal exit;
timeouts always fail. Raw signals retain their signal number.

Mandatory controls reject value mismatch, reference substitution through
provenance, callee-saved register clobber, timeout, out-of-bounds write,
normal-versus-panic, and panic-versus-SIGSEGV. None has a skip-on-unavailable
path.

## Tier-2 integration

`zig build abi-differential` exposes the focused mandatory gate. `zig build
test` depends on it, so the strengthened Tier-2 unit-test boundary cannot pass
without all real executions, provenance checks, counter ratchets, the
controlled panic, and every negative control.
