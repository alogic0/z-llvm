# Compiler-core memory and width execution

Status: focused implementation complete; full acceptance pending.
Authorized by the user's “Do the next”.
Successor to the accepted large-function selection performance checkpoint.

## Intended result

Expand the callable compiler-core cohort from nine to twelve functions per
release mode without changing the authenticated 100-row prefix. Add
`Io.Event.reset`, `InternPool.PackedU64.get` and `InternPool.PackedU64.init`.
Exercise event mutation with neighboring guards, repeated resets and both legal
non-waiting states. Exercise packed values across both 32-bit halves, high bits,
boundary patterns and deterministic runtime-generated inputs. Keep the unchanged
source definitions, typed AIR, symbol and x86_64 calling contract authenticated.

The prefix mostly contains small accessors and predicates; these additions are
a bounded memory-and-width slice, not evidence for general compiler readiness.
An exploratory extraction of `fmt.charToDigit` from the pinned compiler AIR
fails typed lowering with `unsupported:instruction_type:lowering`; its
`error{InvalidCharacter}!u8` return is outside the current i32 error-union
contract. Preserve that diagnostic as the next input/error-path capability gap.
Do not substitute a rewritten function or count a failed probe as execution.

## Implementation order

1. Extract exact three-mode function frames from the retained authenticated AIR.
   Bind the additional upstream source files and regenerate the source-authority
   cache key. Preserve the denominator and original nine members.
2. Add independent value/state oracles and exact x86_64 ABI declarations.
   Add wrong-result/effect, wrong-symbol, neighboring-memory-clobber and
   high-half-loss controls as appropriate. Require explicit semantic rejection,
   not a crash or timeout. Verify fixture/source/ABI drift fails closed.
3. Extend cohort membership and strict output validation together. Preserve
   atomic acceptance: missing, duplicate or wrong observations earn no partial
   cohort credit. Report actual function-mode and observation totals.
4. Run focused controls and cohort units, Debug/Safe units and affected runner
   policy checks. Compare fresh and required-cache execution across all three
   modes, including exact source/descriptor identity and old-member invariance.
5. Freeze the implementation revision, run all 17 integration gates, inspect
   all retained execution populations, and promote counters only after the
   frozen run and postchecks pass. Commit implementation and accepted evidence.

## Boundaries and evidence

Use Zig tooling and frontend pin `1c08b09d1c847f4f02c8216e3b62df323861a437`.
Keep source changes out of the frontend; use shared lowering for any demonstrated
compiler repair. Preserve both input corpora, all fixed Zig programs, 45 native
populations and bypass ratchet 130. Full validation is required because the
execution population and gate contract change; the prior nine-member run cannot
prove this milestone.

Evidence root: `local-state/validations/core-execution-20261107/`.
Cache root: `local-state/caches/core-execution-20261107/`.
Initial available space is 51.25 GB. Admission remains 32,949,672,960 bytes and
execution reserve 24,359,738,368 bytes. Preserve the thirteen original scratch
probes, current AIR, accepted compilers and evidence. Create no archives.

## Focused results

All twelve members execute successfully in each fresh release-mode run; the
100-row prefix lowers, emits and links without failures. The strict comparator
validates all 45 core records. Nine new frames/objects match fresh extraction.
All 21 function/mode control pairs and 54 negative controls pass, covering
22,788 observations per route. Explicit cohort/row/runner unit suites pass in
Debug and ReleaseSafe (32/42/37 checks respectively), and the log comparator
passes 43 checks. Policy checks pass in both modes; unchanged compiler unit and
structural suites reuse valid cached results. Source/probe snapshots verify.

The original 27 member/mode records preserve descriptors, selected objects,
linked sizes, results and observation counts. Rebuilt reference-wrapper sizes
differ slightly in eighteen records; the raw deltas are retained. This is not a
claim that prior reference binaries are byte-identical. The standard comparator
will require fresh/cache byte-count equality within the new root. Full acceptance
is pending; the accepted status remains at the prior nine-member checkpoint.
