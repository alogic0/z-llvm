# Project agent instructions

## Search and JSON tools

Every agent working on z_llvm must read and follow the shared
[jqz and zigrep workflow](/home/oleg/prog/docs/jqz-and-zigrep-workflow.md).

- Start with `~/bin/zigrep` for text searches and file discovery. Use
  `--no-config` for reproducible searches and `rg` for reference comparisons.
- Use `~/bin/jqz` for JSON and NDJSON queries. Check jqz's own query syntax.
- When project work exposes a tool bug or missing feature, reproduce it and
  follow the shared workflow to assign the fix in the owning repository,
  qualify and install the ReleaseFast build, and rerun the original case.

## Development storage

Before producing build, validation or profiling data, read
[the development storage contract](docs/development_storage.md).

- Declare the cycle's evidence root, temporary producers, retained exceptions,
  consumers and release conditions in its plan and in the run's `retention.md`.
- Use `tools/run-validation` for maintained tools and its `--command` mode for
  scripts. Custom commands write evidence to `ZLLVM_RUN_ROOT` and temporary
  products to `ZLLVM_TEMP_ROOT`. A bare reader lock does not record ownership.
- Use pipeline retention when later consumers need temporary products; release
  the workspace after those consumers finish. Failed work remains until its
  diagnosis and disposition are recorded.
- Collect at completed stage boundaries and immediately after releasing a
  pipeline or resolving an investigation. Retry deferred collection at the next
  idle boundary. Use separate managed stages so long outer leases do not delay
  cleanup of unrelated completed work until the end of the whole cycle.
- Record ordinary binary/object identities without turning them into retention
  pins. Accepted manifests list only deliberately maintained files. Existing
  accepted artifacts, exact replay dependencies and independent holds retain
  their contracts.
- Close the cycle's own completed holds and pipelines, collect eligible work,
  and record the receipt plus reasons for remaining temporary roots. Do not
  classify unexplained leftovers as required data.

Use [the working cycle](docs/working-cycle.md) and
[validation tiers](docs/validation_tiers.md) for the rest of the development flow.
