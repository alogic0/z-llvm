# Publishing on GitHub

Publish the tracked Git repository. Local caches, validation runs, raw captures,
scratch experiments, and installed binaries are excluded by [.gitignore](../.gitignore).
The tracked acceptance summaries remain available under `docs/evidence/`;
their machine-local artifact paths describe the original validation environment.

## Before the first push

Use a clean branch containing the intended source and documentation changes.
Run the commands in [CONTRIBUTING.md](../CONTRIBUTING.md), review `git status`
and `git diff --check`, and inspect the staged file list before committing.
The project license is [MIT](../LICENSE); retain all
[third-party notices](../THIRD_PARTY_NOTICES.md).

Create an empty GitHub repository with the desired owner and visibility.
The repository already supplies its README, license, and ignore rules.

From the prepared branch, replace `YOUR_ACCOUNT` and the repository name:

```sh
git remote add origin git@github.com:YOUR_ACCOUNT/z_llvm.git
git push -u origin HEAD:main
```

Set `main` as the default branch on GitHub. The command publishes the current
branch and its history. Local worktree branches and ignored artifacts stay local.
If `origin` is already configured, inspect `git remote -v` and use that
repository's established remote.

## Continuous integration

[CI](../.github/workflows/ci.yml) runs on pushes, pull requests, and manual
dispatches. It uses Ubuntu 24.04 x86-64 and the official Zig 0.17.0 archive with
a pinned SHA-256 digest. Update the workflow's version and checksum together
with [.zigversion](../.zigversion) when changing compilers; the build enforces
the exact version.

Both Debug and ReleaseSafe run the build, unit, structural, artifact-store,
profiling, regex, and validation-policy checks. CI also verifies vendored
source identities and the current documentation links and status blocks.
LLVM differential suites and the full compiler replay require the separately
configured integration environment documented in [environment.md](environment.md).
