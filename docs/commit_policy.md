# Commit Policy

For repository changes made by Codex:

1.  Stage all changed files with `git add`.
2.  Create a temporary commit message file.
3.  Write the commit message with a short header and a list of changes.
4.  Commit with `git commit -F path_to_temp_file`.

This keeps commit messages inspectable before committing and avoids fragile shell quoting for multi-line messages.

Before committing an LLVM reproduction step, update the relevant documentation with the upstream LLVM source mapping required by [development_cycle.md](development_cycle.md).

Never put full local file paths in commit messages or comments. Use paths relative to the `prog` directory instead, for example `z_llvm/src/main.zig` or `llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp`.
