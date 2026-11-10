# SSA transport and atomic-storage slice

Batch 08 adds typed private normalization for literal integer/pointer-and-flag
SSA values: PHIs, selects, insert/extract operations and stable freezes. Integer
freezes use exact native carriers, including named widths 33..63 and i65/i96.
Owned and interior atomic storage addresses use the existing stack-address
transfer contracts. General storage normalization preserves atomic attributes,
ordering, volatility, neighboring bytes and symbolic addresses; restricted legacy
storage and ordinary volatile barriers keep their previous bounds.

No function-name admission, public aggregate ABI expansion, new opcode,
source-guard fingerprint edit or weakened negative assertion is introduced.
Fifteen new semantic, rollback and allocation-failure tests accompany the shared
contracts. Native drivers check return values, full output fields, clobbered
registers, alias stability, poison refinement, memory effects and guard bytes.

Evidence root:
`local-state/validations/compiler-selection-completion-20261108/batch-08/`.
The validated compiler snapshot is `source-aggregate-v2.json` (3,157 files).
Compiler build receipts bind ReleaseFast SHA-256
`9606724d246718a58a63a54cb7c0fbb63c1a74a9b6903a70d5113d772ce0c5b3`
and Debug SHA-256
`fa8732cb773016be8e65c05d2fd1d5ecad9b27f78b88a9b598e6d72ed6740afc`.

- `units-aggregate-{debug,safe}-v2.{json,log}`: each build mode passes 2,061
  unit tests, 24 structural checks and two profile/interruption checks.
- `focused-aggregate/`: all three new populations pass all release modes and
  direct/release/reference routes with both frozen compiler builds.
- `native-all-debug-aggregate/` and
  `integrated-aggregate/unchanged-upstream-c/`: all 79 registered populations
  pass with Debug and ReleaseFast compilers respectively. The three additions
  are `flag_pair_values`, `integer_freeze_values` and `atomic_storage_views`.
- `zig-migration/compare-aggregate-{debug,fast-result}/report.json`: each build
  retains all 76 old registry entries, all 2,837 old command outcomes and all
  1,161 prior compiler artifacts byte for byte. Additional commands are limited
  to the three named new populations.
- `zig-migration/aggregate-faults-final/report.json`: all 270 injections are
  detected, following 54 successful baselines, with executable hashes and
  supervised command records. Historical script details and migration checks
  are documented [separately](batch08_zig_helpers.md).
- `targets-aggregate-v2.jsonl` and `target-aggregate-comparison.json`: all
  nineteen retained original definitions select, up from eleven before this
  group. The expanded diagnostic selects 24/25, preserving preceding successes.
  `codegen.aarch64.Select.Value.Index.load` reaches an i65 call boundary requiring
  a seventh physical argument slot; it remains an explicit later capability.
- `runtime-aggregate-v2.jsonl` and `runtime-aggregate-comparison.json`: complete
  traversal of 455 runtime definitions retains 285 selections and the preceding
  intrinsic slice's owner identities, with no lost selections.
- `readiness-aggregate/`: the seven remaining readiness commands pass freshly,
  including optimizer/corpus/handoff checks, 6,528 generated behavioral
  observations and release-pipeline policy. The unit/structural and profile
  commands reuse the results above; `aggregate-check-reuse-after-tools.json`
  verifies unchanged compiler, test, provider and tabular contract inputs after
  the tooling migration. Thus all nine readiness procedures are covered.
- `full-aggregate.{json,log}`: checked return code zero, all 17 serial integration
  gates pass. `source-aggregate-verified-after-full.log` verifies the frozen
  snapshot afterward. Serial run ID `e948f7a36368e168534ab0e44f3c788e`; the
  100-row source-owned object bundle is produced once and consumed by all three
  independent inspection/link/probe gates. Executions are not cached.

Failed and superseded evidence remains intact. The first integer-pair-only full
run stopped after twelve passing gates when a temporary host Zig cache object
was missing during a harness link. The exact harness passed in isolated caches;
the final combined run above uses separate host caches. Initial combined unit
failures prompted private freeze legalization and retention of legacy volatile
barriers, without changing protected consumers or tests. The final source above
supersedes those earlier source variants.

The first-source 264-target diagnostic timed out after one hour, with 211
complete function records and no terminal census event, while lowering the
large LoongArch instruction parser. Its smaller filtered diagnostic supplies
classification only. Neither proves complete compiler coverage. Bounded
profiling on the final compiler confirms ordinary liveness/hash lookups dominate
that function; an isolated performance prototype investigates the required replay.

This is a validated capability slice, not whole-compiler acceptance. The original
compiler input remains SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`,
with all 8,928 definitions required. Accepted counts remain 8,664/8,928 and
285/455 until a complete original-input census and independent production replay
pass together. Compiler startup and self-rebuild are not established here.
