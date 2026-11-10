# Batch-08 helpers in Zig

The seven ad hoc Python helpers under
`local-state/validations/compiler-selection-completion-20261108/batch-08/`
are replaced by maintained Zig tools. Historical scripts and command records
remain intact; active commands and subsequent inspections use no Python.

| Previous helper | Replacement |
| --- | --- |
| `generate-native-pairs.py` | `tools/generate_ssa_transport_canaries.zig` |
| `staged-frontier/generate-fixtures.py` | same generator |
| `staged-frontier/generate-drivers.py` | same generator |
| `check-pair-faults.py` | `tools/run_native_fault_checks.zig` and `tools/compare_native_runs.zig` |
| `check-aggregate-faults.py` | `tools/run_native_fault_checks.zig` |
| `compare-native-pairs.py` | `tools/compare_native_runs.zig` |
| `staged-frontier/run-native-research.py` | `tools/run_native_canary.zig --fault-count 5` |

The [usage guide](../validation_tools.md) documents all arguments, manifests,
process supervision, comparison rules and evidence ownership. Shared JSON,
hashing, file and process providers remain unchanged. No gate inventory, cache
policy, native fixture bytes or compiler acceptance counter changes here.

Evidence root: `batch-08/zig-migration/` within the validation root above.
`tooling-files.sha256` identifies the staged tool and documentation bytes,
verified again after promotion to the main checkout. `migration.json` and
`README.md` record the checks and retained failed attempts.

- `generated-final/generation.json`: all six outputs byte identical to retained
  LLVM fixtures, C drivers and the function inventory. The generator uses its
  own typed cases/templates, without reading generated files as templates.
- `pair-faults-final/report.json`: all 90 historical control identities, return
  codes, stdout, stderr and executable hashes match exactly.
- `aggregate-faults-final/report.json`: 270 injected failures detected, plus 54
  successful baseline executions. The historical wrapper exited zero and its
  log records 270 detections. It overwrote the original detailed aggregate JSON,
  so historical aggregate equivalence is limited to count and outcome.
- `compare-pairs-debug/report.json`: the prior script's result is reproduced,
  preserving 2,837 command outcomes and 1,161 compiler artifacts byte for byte.
- `compare-aggregate-debug/report.json` and
  `compare-aggregate-fast-result/report.json`: each compiler build preserves
  those same 2,837 outcomes and 1,161 artifacts against the current 79-population
  run. All 76 original registry entries remain exact; 108 additional commands
  belong to the three explicitly named new populations.
- `research-freezes/report.json` and `research-atomics/report.json`: the same
  private research compiler passes both populations in every mode/route and all
  90 injected failures. This remains research evidence.
- `policy-final-debug-v3.{json,log}` and `policy-final-safe-v2.{json,log}`:
  42/42 policy tests pass in each build mode. New controls reject always-failing
  drivers, incorrect failure markers/status/stdout, duplicate or altered fault
  records, lost duplicate command occurrences, artifact/outcome/count/fixture
  changes, unrelated commands and registry mutations.

Root-checkout generator/fault commands and the ReleaseFast comparison have
separate durable `root-*` / `compare-aggregate-fast` command receipts. Tool changes
were staged separately until the concurrent compiler checkpoint finished all
17 integration gates and verified its unchanged source snapshot. Those compiler
results bind the pre-migration snapshot; the optional new tooling is verified
by the differential checks above. Compiler-count acceptance still requires a
complete original-input census and independent production replay.
