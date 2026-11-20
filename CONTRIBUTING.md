# Contributing

Use the exact Zig version in [.zigversion](.zigversion). The supported development
and CI environment is Linux x86-64; see [environment](docs/environment.md).
Compiler and tool dependencies are included in the repository where needed for
the isolated checks below.

## Build and check a change

From the repository root, run the isolated CI checks with Zig 0.17.0 on PATH.
For unit tests alone, use `zig build test-unit`. The `zig build test` target
also runs the ABI differential gate and requires the integration tools.

```sh
zig build -Doptimize=Debug -j2
zig build test-unit structural-smoke artifact-store-test test-profile-events -Doptimize=Debug -j2
zig build test-tool-regex real-program-policy-tests verify-source-audit -Doptimize=Debug -j2
zig build check-docs
```

Repeat the build and test commands with `-Doptimize=ReleaseSafe`. CI checks
documentation once, in the Debug job. The isolated checks use the source
checkout and the pinned compiler. [GitHub Actions](.github/workflows/ci.yml)

Use `zig build test-unit -Dtest-filter=NAME` for focused iteration. Format
changed first-party Zig files with `zig fmt`. Keep vendored sources unchanged;
their digests and provenance are recorded in [tools/vendor](tools/vendor/README.md).

## Compiler changes

Start with the [architecture](docs/architecture.md) and
[validation tiers](docs/validation_tiers.md). Add a minimal regression case to
the existing test suite and keep the fix in the shared implementation that owns
the behavior.

Code generation, ABI, optimizer, and parser changes can require additional
integration evidence. For a milestone, use the [managed full integration
run](docs/validation_tiers.md#run-the-full-integration-suite). The
[environment guide](docs/environment.md) lists the patched fixture emitter
and LLVM 22 comparison tools.

When changing coverage or performance claims, identify the source revision,
input identities, commands, outcomes, and comparison scope. Keep selection,
object emission, linking, execution, and self-rebuild results distinct.

## Reports and pull requests

For a bug, include the Zig version, operating system, exact command, smallest
reproducing input, expected result, and observed output. For a pull request,
explain the behavior change and record the checks actually run.

Keep generated binaries, caches, raw captures, and local experiments in the
ignored locations described by the [retention policy](docs/retention_headroom_policy.md).
Preserve the original evidence locally when reducing a regression test.

The project uses the [MIT license](LICENSE). Third-party source and fixture
notices are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
