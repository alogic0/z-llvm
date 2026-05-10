# Commit Policy

For repository changes made by Codex:

1.  Stage all changed files with `git add`.
2.  Create a temporary commit message file.
3.  Write the commit message with a short header and a list of changes.
4.  Commit with `git commit -F path_to_temp_file`.

This keeps commit messages inspectable before committing and avoids fragile shell quoting for multi-line messages.
