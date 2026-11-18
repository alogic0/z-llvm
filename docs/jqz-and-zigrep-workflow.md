# Working with jqz and zigrep

Use `zigrep` for text searches and file discovery. Use `jqz` to filter,
compare and summarize JSON and newline-delimited JSON (NDJSON). The commands
below use the tools on `PATH`. When diagnosing a problem, record which binaries
ran with `command -v zigrep`, `command -v jqz` and their `--version` output.

## Search files with zigrep

Run searches from the project directory. Name the input path explicitly,
use `--no-config` for reproducible checks and `-F` for literal text.

```sh
zigrep --no-config --files -g '*.md' .
zigrep --no-config -n -F 'TODO' .
```

Normal file discovery respects ignore rules. When inspecting generated or
hidden files, scope `--hidden --no-ignore` to the directory you intend to
inspect. Use `rg` as a reference when checking search compatibility or speed.
[zigrep documentation](https://github.com/alogic0/zigrep)

When another decision depends on a search, distinguish all three outcomes.
This shell example checks one literal entry in a newline-delimited listing.
Set `wanted` to the entry and `listing` to the file.

```sh
probe_status=0
zigrep --no-config -F -x -- "$wanted" "$listing" >/dev/null || probe_status=$?
case "$probe_status" in
  0) printf '%s\n' 'Entry present' ;;
  1) printf '%s\n' 'Entry absent from this listing' ;;
  *) printf 'Search failed (exit %s)\n' "$probe_status" >&2
     exit "$probe_status" ;;
esac
```

An unsupported option or unreadable input leaves the answer unknown. Preserve
stderr and pause the dependent decision. If another command produced the
listing, check its exit status too. A successful search of a partial listing
can give a misleading answer.

## Query JSON with jqz

Choose the input mode from the data. A pretty-printed JSON document is still
one document. Use `each` to stream the items of an array and `--ndjson` when
each input line contains a separate JSON record.

```sh
# One document with an array. The missing status becomes "pending".
printf '%s\n' '{"tasks":[{"name":"build","status":"ok"},{"name":"lint"}]}' |
  jqz '.tasks | each | {name, status: .status? ?? "pending"}'

# Two records. The build group has count 2 and sum 50.
printf '%s\n' '{"job":"build","ms":20}' '{"job":"build","ms":30}' |
  jqz --ndjson 'sum_by(.job,.ms)'
```

- `take(1)` limits stream items. To read the first task, use `.tasks[0]` or
  `.tasks | each | take(1)`. Use `.field?` and `??` for optional fields and
  defaults. For a data-dependent array lookup, use `each` and `where`. Use
  `input_filename()` when an individual record's filename identifies it.
  Check jqz's query syntax when adapting an expression from jq.
- Use `-p` for indented output. Use `fromjson`, `try_fromjson` or `tojson`
  for embedded JSON strings. A literal prefilter is useful for a known compact
  NDJSON serialization. Search fields structurally when escaping, whitespace
  or field order can vary.
- Filter and project the fields you need before sorting or building an index.
  Use `count_by` or `sum_by` for grouped totals. For joins, `--slurpfile`
  binds a named input and `root()` refers to the current expression stage's
  input. The tool repository includes worked examples in
  `examples/cleanup/README.md`. [jqz documentation](https://github.com/alogic0/zig-json-query)
- Match the limit to the operation. `--max-document-bytes` bounds an ordinary
  input document, `--max-retained-bytes` bounds values kept by pipeline stages,
  and `--max-slurp-bytes` bounds slurped input. For a membership query, index
  only the key fields before increasing a memory budget.

Shell and filesystem utilities work well for orchestration. Reusable Zig
tools can import the public modules `zigrep` and `query`. For filesystem
inventory and guarded hashing, `zig-file-audit` supplies file identities,
allocated bytes and hardlink information. Preserve file sizes, inode numbers
and nanosecond timestamps as exact integers. Apply the consuming project's
retention rules before acting on inventory results.

## When a tool falls short

**Pause the decision that needs a trustworthy result.** If a tool might
silently omit a match, miscount records or lose integer precision, check the
result against a known answer or an independent method before using it.
Independent work can continue. For a missing convenience feature, record a
small reproducer and use a narrow, verified workaround. The project can
proceed while the tool owner qualifies a fix.

1. Reproduce the issue with the installed binary. Record expected and actual
   output, command, input size, stdout, stderr and exit status. For a slowdown,
   keep bounded timings on the real workload and a small shareable fixture.
2. File the request in the owning repository with its impact and acceptance
   checks. Start one implementation agent in that repository to own the edits,
   tests and installation. Agree on any handoff. Keep private inputs out of committed fixtures.
   Shared regex changes belong in `zig-regex`. Consumers can then adopt the
   qualified, hash-pinned package.
3. Follow the tool repository's agent instructions, pinned Zig version,
   versioning and commit rules. Add a native regression for the failure and
   compare observable output and exit status with the reference where
   applicable. For scaling issues, measure growing inputs and the original
   workload. Keep machine-dependent timing thresholds out of unit tests.
4. Run the native Debug checks and qualify the configuration users will install.
   For the ReleaseFast CLIs, run these commands in the respective source
   checkouts. Finish with the ReleaseFast build that supplies the binary.

   ```sh
   # In the zigrep checkout
   zig build check
   zig build check --release=fast
   zig build --release=fast

   # In the zig-json-query checkout
   zig build test
   zig build test --release=fast
   zig build --release=fast
   ```

5. Coordinate one installer per binary. On Unix, stage the qualified binary
   with mode 0755 in the destination directory, compare its bytes with the
   build, and rename it atomically. Rerun the original command through the
   installed path. Record the source revision, build command, checks, installed
   version and SHA-256. Retire the workaround and release temporary fixtures
   and caches when their consumers finish.

## Using this guide in a project

Keep a copy in the repository and link it from the project's root agent
instructions. Put project-specific paths, schemas, examples and storage rules
under a separate heading in that copy. When a practice applies across projects,
update the shared guide and carry the change into the copies that use it.

## z_llvm additions

This repository carries the full workflow for use in any checkout. On the
development workstation the shared source is
`~/prog/docs/jqz-and-zigrep-workflow.md`. The installed tools are
`~/bin/zigrep` and `~/bin/jqz`. Their source repositories are `~/prog/zigrep`
and `~/prog/zig-json-query`. Shared regex and file-audit code live in
`~/prog/zig-regex` and `~/prog/zig-file-audit`.

### Inspect compiler and storage records

From the repository root, these read-only commands find trace-handling code
and extract the outcome of a recorded compiler run.

```sh
zigrep --no-config -n -F 'profile.events.jsonl' tools/validation docs/validation_tools.md
jqz '{status, code_revision, complete_results: .matrix_modes, named_reference_outcomes_compared}' \
  docs/evidence/compiler_behavior_follow_up_acceptance_20261113.json
```

For a specific run, set `run_dir` to its evidence directory under
`local-state/validations/`. Include ignored files explicitly when locating
manifests. A shallow search can use `--max-depth 1`.

```sh
zigrep --no-config --files --hidden --no-ignore \
  -g '*.sha256' -g 'record.json' "$run_dir"
```

For the storage inventory, this Bash pipeline ranks candidate run roots by
unique allocated bytes. `inventory` names the compressed NDJSON inventory.
Check the pipeline status before using the totals.

```bash
set -o pipefail
gzip -dc -- "$inventory" |
  jqz --ndjson \
    'where((.category? ?? "") == "generated_review") |
     sum_by(.run_root,.unique_allocated_bytes_first_observation) |
     sort_by(-.sum) | take(20)'
```

A 113,221,765-byte compiler metadata document needed
`--max-document-bytes 134217728`. A separate inventory join fit the existing
64 MiB retained budget by projecting `{path}` before `index_by(.path)`.
Choose the remedy that matches the reported limit. For acceptance decisions,
check the producer's terminal status and the delivered artifact alongside the
capture record. [Validation tools](validation_tools.md)

### Respect validation and storage ownership

Use the installed CLIs for inspection and the maintained Zig tools for
validation. Produce validation evidence through `tools/run-validation`,
using `--command` for scripts. Put reports under `ZLLVM_RUN_ROOT` and scratch
under `ZLLVM_TEMP_ROOT`. A search miss only establishes absence from the
inspected input. The collector checks live consumers, holds, manifest pins,
hashes and aliases before removing anything. [Development storage](development_storage.md)
· [Storage cleanup](storage_cleanup.md)

Once consumers close, the collector can retire ordinary Debug, Release and
test binaries, objects and private caches without creating new source or
build-configuration archives. Preserve receipts and accounting. Adopted
baselines and exact replay dependencies keep their recorded lifetimes. Raw
compiler event traces require a verified semantic audit and explicit
retirement. A failed tool query leaves the dependent acceptance or cleanup
decision open while independent compiler work can continue.
