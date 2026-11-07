# Compiler-core memory and width execution

Focused validation passes; full acceptance is pending. The fixed 100-row compiler-core prefix now has harnesses for
twelve functions in each release mode, extending the previous nine with:

| Function | Cases per mode | Contract checked |
| --- | ---: | --- |
| `Io.Event.reset` | 512 | Unset/set states, repeated reset, three positions inside a guarded u32 array; only the selected state may change. |
| `InternPool.PackedU64.get` | 1,040 | Both 32-bit fields survive the packed u64 argument/return boundary. |
| `InternPool.PackedU64.init` | 1,040 | Both halves survive construction of the packed u64 result. |

Packed inputs contain sixteen boundaries/patterns and 1,024 generated values.
Each call is checked independently; result and witness totals provide additional
output authentication. There are 7,856 observations per complete cohort/mode,
or 23,568 across three modes, for each of the local and reference routes.

Exact function frames were extracted from the retained pinned compiler AIR.
The nine new frames and their emitted objects also match fresh AIR extraction
byte for byte. `lib/std/Io.zig` and `src/InternPool.zig` are now included in source
authentication. This intentionally changes the AIR cache key without changing
the candidate file, selector, denominator or frontend pin. The output contract
is `distribution-execution-cohort-v5` and rejects the old nine-member summary,
missing/duplicate rows and wrong results, witnesses or observation counts.

The shared negative-control gate now covers 21 function/mode pairs and 22,788
observations per route. Its 54 controls include wrong results/effects, wrong
symbols, neighboring writes and loss of the upper 32 bits. Runtime controls
must produce the explicit `OracleMismatch` error and exit 1; crashes/timeouts
are rejected as evidence. Symbol controls must fail linking with the intended
symbol in the diagnostic. The original members retain their existing controls.

No compiler implementation, frontend, pass, register-transfer or ABI planner
changes were needed. Accepted Debug and ReleaseFast compiler hashes remain
unchanged. The focused source covers gate code, oracles and fixtures; compiler
unit/structural results are reusable where Zig reports cache hits. Cohort,
real-row and runner units were run explicitly in Debug and ReleaseSafe; log
comparison and policy checks also run. Full acceptance will replay the fresh
cohort through required cache hits and preserve the other seventeen-gate
populations. Fresh execution passes 100 lowered/emitted/linked and twelve
executed members in every mode, with all 45 canonical records valid. Explicit
cohort/row/runner suites pass 32/42/37 checks in both Debug and ReleaseSafe;
log comparison passes 43 checks and policy checks pass 30 in each mode.

The old nine members retain identical descriptors, selected objects, linked
sizes, results and observations in all 27 member/mode records. Eighteen reference
wrapper sizes differ slightly after rebuilding under the new root. The raw
comparison retains these differences; no prior reference-byte equality is
claimed. Fresh/cache acceptance keeps the standard strict byte-count comparison.

Raw evidence is under `local-state/validations/core-execution-20261107/`:
`cohort-fresh.log`, `focused-controls/report.json`, `fixture-equivalence.log`,
`old-member-equivalence.json`, unit/policy logs, and the verified focused source
snapshot. The future full run is declared in `cycle-notes.md` and
`full-acceptance.sh`. Minimum sampled fresh-run free space is 43.38 GB, above the
24.36 GB reserve. Original probes remain unchanged; no archives were created.

This slice does not test concurrent event callers or allocator error behavior.
Packed conversions remain small functions. An exploratory `fmt.charToDigit`
extraction fails typed lowering with `unsupported:instruction_type:lowering`.
Its `error{InvalidCharacter}!u8` payload exceeds the current wrapping contract
for 32-bit payloads; this is a bounded next investigation, not a claim that all
other ABI or error-code requirements are already met. The exact diagnostic frame
is retained, and the function earns no execution credit.
