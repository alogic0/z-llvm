# Storage contract for development cycles

Every new development cycle declares what it produces before running expensive
commands. Its plan names the evidence root, temporary producers, downstream
consumers and closure steps. Write the cycle's concrete decisions in
`RUN/retention.md`; the generated `*.storage-layout.json` files bind actual
temporary trees to their producers and results. The note explains intent;
collector checks still decide whether removal is safe.

Use a fresh `local-state/validations/SUITE/BATCH/RUN` for each run. Keep different
attempts and compiler generations separate. The matching temporary trees live
under `local-state/tmp/validations/.../.workspaces/KEY`.

Put `retention.md` in the checked command's root and name any nested tool roots
there. Tools such as `run_upstream_behavior` require their own output directory
to be absent at startup; let the tool create that directory instead of putting
the note there first. The checked command and nested tool use separate roots.

## Classify outputs

| Class | Examples | Location and release condition |
| --- | --- | --- |
| Temporary validation work | Private caches, build trees, intermediate assembly, objects and test executables | Producer workspace; a successful terminal result permits collection. Failed/interrupted scratch remains for diagnosis until the owner resolves it. |
| Temporary pipeline work | Baseline/candidate compilers, objects awaiting equality checks, executables awaiting fault tests, raw `perf.data` and expanded sampling stacks | Pipeline workspace; retain through the named consumers, then publish an explicit workspace release. Build completion alone does not close these consumers. |
| Maintained evidence | Commands, terminal outcomes, diagnostic logs, comparison/audit reports, measured summaries, source/input identities, unique reproductions | Evidence root. State the result or investigation each group supports. Keep compact records after temporary bytes are gone. |
| Maintained input or replay dependency | Unique captured IR, adopted reference inputs, exact objects or compilers required by an accepted comparison or replay contract | Evidence root or immutable artifact store, with a named consumer and release condition. Repeated immutable inputs should use the artifact store's sharing API. |
| Raw compiler event trace | `profile.events.jsonl` needed for ordered-event/audit proof | Evidence root until verified semantic audit and explicit trace retirement. It never belongs in disposable scratch. |

Directory names and age do not establish retention. Ordinary old Debug/Release
binaries, objects and private caches need no new source/configuration archive
before removal. An exact-binary investigation or replay dependency is a separate
declared use. Put any other output family in the table before producing it.

For every retained exception record **path, purpose, consumer, release condition**.
For example:

```text
Evidence root: local-state/validations/example/batch-01/compare
Temporary producer: compare.storage-layout.json (pipeline)
Temporary products: baseline/candidate executables, emitted objects, private caches
Consumers: object comparison, native fault checks, unprofiled measurement pairs
Maintained: commands/results, comparison hashes, timings, input identities
Exception: accepted.ll — fixed replay input — next cycle — replace after successor acceptance
Closure: finish consumers, retain result records, release compare workspace, collect
```

Shared cache overrides and reusable tool-bootstrap caches also need owners.
`local-state/tmp/validation-tools` belongs to `tools/run-validation`;
`local-state/tmp/storage-cleanup-build` belongs to `tools/clean-storage`.
Their build locks protect reuse. Task-specific tool-build scratch must be named
in the task plan and removed after qualification; it is not historical evidence.

## Run through the managed launcher

Use current maintained Zig tools through `tools/run-validation`. For a custom
script, benchmark, unit build or profiling command, use its `--command` mode:

```sh
ZIG=/path/to/pinned/zig tools/run-validation \
  --output-root local-state/validations/example/batch-01/unit checks \
  --command /path/to/pinned/zig build test-unit

ZIG=/path/to/pinned/zig tools/run-validation --retain-products \
  --output-root local-state/validations/example/batch-01/compare compare \
  --command bash /absolute/path/to/compare.sh
```

`ZIG` selects the launcher's compiler. The command after `--command` is executed
as supplied; use its explicit compiler path too when it differs from `PATH`.
The child runs in the selected source checkout and receives:

- `ZLLVM_RUN_ROOT`: maintained evidence for this checked command.
- `ZLLVM_TEMP_ROOT`: this command's temporary workspace.
- `TMPDIR`, `ZIG_LOCAL_CACHE_DIR`, `ZIG_GLOBAL_CACHE_DIR`: workspace defaults.

A custom script writes reports under `$ZLLVM_RUN_ROOT` and ordinary generated
products under `$ZLLVM_TEMP_ROOT`. The launcher provides ownership and lifetime
tracking; it does not sandbox arbitrary script writes. Existing environment or
command-line cache overrides remain caller-owned. Environment overrides outside
the workspace are listed in the receipt's `storage.caller_owned_overrides`;
declare their purpose and closure separately, or omit them to use defaults.

The command receipt records both roots, the layout path and `validation` or
`pipeline` lifetime. `--retain-products` retains the checked command's workspace
after success. Nested maintained tools still control their own workspaces; use
their retention option when later consumers need their products. Keep the parent
lease over the whole pipeline or declare queued work before releasing that lease.
A bare `flock --shared ...` provides concurrency protection only; it does not
replace this ownership/lifetime record.

The launcher attempts guarded minimal collection before starting each checked
command; the checked runner attempts it again on completion. The first pass
retries work left by earlier busy readers. Cleanup uses the storage owner's
policy even when the command runs in another source checkout. A busy or failed
cleanup is reported and the command keeps its own outcome.

For sibling checkouts, use `--project-root SOURCE --storage-root OWNER` as
described in [validation tools](validation_tools.md#launch-current-tools-with-another-source-checkout).
Never use a source snapshot as an implicit new storage owner.

## Keep identities separate from retention pins

Record temporary artifact hashes and original paths in result JSON or an
ordinary provenance file such as `identities.txt`. These describe what ran even
after the bytes are retired. A checksum retention manifest is a requirement to
keep referenced bytes, not just a convenient list of every generated file.

Build accepted manifests from an explicit maintained-file list. Do not checksum
the entire run or temporary tree into an acceptance/seal manifest. If an object
becomes an adopted baseline, copy or publish that selected file into maintained
storage before the workspace closes, record its purpose, and pin that maintained
path. Do not hardlink mutable scratch into maintained evidence.

Existing accepted manifests, replay dependencies and independent holds remain
effective. Changing their lifetime requires a reviewed transition; changing a
filename or adding a note does not remove that dependency.

## Collect throughout the cycle

- Use a managed command for each build, test or measurement stage whose lifetime
  can close independently. Completed ordinary work is collected after that stage.
- Release a retained pipeline as soon as its last consumer finishes, then run
  `tools/clean-storage --minimal --apply` at that boundary.
- Resolve failed scratch and retire audited raw traces when the diagnosis or
  audit completes. Preserve the original result and required diagnostics.
- Retry deferred collection at the next idle boundary before starting more work.
  An enclosing live lease can defer both automatic passes: split independent
  stages into separate top-level commands, and retain shared inputs through
  their declared pipelines. Keep leases over work that is still active.

## Close the cycle

1. Finish all declared consumers and save the reports, diagnostics and identity
   records that support the result. Give remaining failures a specific
   investigation owner and resolution condition.
2. Close this cycle's manual/queued hold after confirming it has no remaining
   consumer, keeping other holds. Scope any continuing hold to the actual
   dependency instead of the whole historical suite. Do this before publishing
   a release: an effective hold correctly blocks release publication.
3. Release each completed pipeline workspace. Resolve a failed workspace only
   after its diagnosis is recorded. For example:

   ```sh
   tools/clean-storage release-workspace \
     --layout local-state/validations/example/batch-01/compare/compare.storage-layout.json \
     --reason 'Object comparison, fault checks and measurement pairs completed'
   tools/clean-storage --minimal --apply
   ```

4. Report the collector receipt, remaining temporary roots and why they remain.
   Account for new output families against `retention.md`; an unexplained file
   stays unresolved until reviewed. Record the reason when a pin or another
   consumer prevents release. Do not mark all leftover data as required.

The end-of-cycle review confirms these earlier collections and closes any final
consumers. Keep the terminal receipts for deferred collection. Completion includes a
recorded storage disposition even when a real consumer requires retention.
See [storage cleanup](storage_cleanup.md) for verified release formats and guards.
