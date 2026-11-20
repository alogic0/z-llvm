# z_llvm documentation

## Use the compiler

| Task | Guide |
| --- | --- |
| Install Zig and its object provider on x86-64 Linux | [Install the reviewed SDK or rebuild from pinned sources](install_toolchain.md) |
| Compile a program or try the standalone optimizer | [Compile hello with the SDK](../README.md#use-the-packaged-compiler) · [Build the optimizer from a fresh clone](../README.md#build-the-standalone-optimizer) |
| Check which parts need LLVM | [Dependencies by task](../README.md#do-i-need-llvm) · [Development environment](environment.md) |
| See what works and how fast it is | [Supported targets, modes and workloads](current_state.md) · [Performance compared with LLVM](performance.md) |

## Work on the compiler

- Follow a change from setup to review. [Contributing](../CONTRIBUTING.md) · [Build targets](build_steps.md) · [Validation tiers](validation_tiers.md)
- Trace a compilation from the Zig driver through optimization, object emission and linking. [Architecture](architecture.md) · [IR reference](ir/README.md) · [Pass pipelines](passes/pipelines.md) · [Native ELF linker](native_elf_linker_handoff.md)
- Look up terminology used in compiler reports. [Glossary](glossary.md)
- Investigate a difference or a slowdown. [Differential testing](differential_testing.md) · [Compiler profiling](compiler_profiling.md) · [Validation tools](validation_tools.md)
- Run a development cycle and manage its outputs. [Working cycle](working-cycle.md) · [Development storage](development_storage.md) · [Storage cleanup](storage_cleanup.md)

## Follow project decisions

- [Next steps](next_steps.md) gives the current proposal, baseline and acceptance criteria.
- [Release qualification](evidence/llvm_free_self_rebuild_20261119.md) records how the installed compiler rebuilt itself and what passed. The [package manifest](evidence/artifacts/zig-z_llvm-releasefast-x86_64-linux-gnu-20261119.json) identifies the reviewed archive.
- [Historical roadmaps](roadmap/historical/README.md) connects completed milestones to their plans, results and original design notes.
