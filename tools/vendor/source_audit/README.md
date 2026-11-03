# zig-source-audit

Zig 0.17.0 source metrics, import graphs and configurable architecture checks.
One independent `source_audit` library and a `zig-source-audit` CLI, using only
the Zig standard library. Initial qualified host: Linux x86_64.

```sh
zig build install
zig-out/bin/zig-source-audit --root /path/to/project --include src --json
zig build run -- --root /path/to/project --include src --rules architecture.json
```

The CLI reports function/test spans, bytes, decisions, switch arms, nesting,
dense control-flow lines, literal imports, reverse dependencies and cycles.
Metrics advise review; they do not calculate a difficulty score or impose size
thresholds. Named-module imports and expression imports remain explicit evidence;
this is not the compiler's resolved module/build graph.

Boundary rules are consumer-owned JSON. Constraints inside one selector are
ANDed, selector lists are ORed, and the first matching rule labels a violation:

```json
{"schema_version":1,"rules":[
  {"name":"core independence","from":[{"prefix":"src/core/","tests":"exclude"}],
   "deny":[{"prefix":"src/ui/"},{"tests":"only"}]}
]}
```

Selectors support `exact`, `prefix`, `suffix`, `contains`, `exclude_paths` and
`tests` (`any`, `only`, `exclude`). Violations include the complete reachable
import chain. Production inline-test imports are excluded from the graph, and
test files are not traversed as intermediate dependencies. Explicitly selected
test origins can still be checked. No product-specific paths are built in.

Repeat `--include`/`--exclude` with canonical relative paths; selection defaults
to the whole root. Git, build/package caches, node_modules and vendor directories
are skipped, as are symlinks. Admission is bounded at 100,000 files, 16 MiB per
file, 256 MiB total source and 1 MiB of rule JSON. Oversized input fails without
a partial report. Exit status: 0 success, 1 syntax/rule failures, 2 usage/IO or
admission errors. Missing local imports and cycles are reported rather than
automatically rejected. JSON output is sorted and reproducible for fixed inputs.

## Library

Add `.source_audit = .{ .path = "../zig-source-audit" }` during development, or
pin the verified source archive. Copy it to `vendor/`, run
`zig fetch vendor/zig-source-audit-0.1.1.tar.gz`, and compare the printed hash
with the distribution receipt. Add a `.source_audit` dependency with
`.url = "file:vendor/zig-source-audit-0.1.1.tar.gz"` and `.hash` set to that
verified hash. The command uses a filesystem path; relative `file:` URLs belong
in the manifest. Commit both files and check the consumer with an empty global
cache. Version 0.1.1 corrects these installation instructions without changing
the 0.1.0 analysis algorithms. Wire the module into a consuming root:

```zig
const dep = b.dependency("source_audit", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("source_audit", dep.module("source_audit"));
```

```zig
const audit = @import("source_audit");
var report = try audit.analyze(allocator, &.{
    .{ .path = "src/example.zig", .text = "fn example() void {}" },
});
defer report.deinit();
```

The owned report copies inputs and retains all output data until `deinit`.
It records invalid syntax per file, and returns allocation/path/duplicate-source
errors. `report.check(rules)` returns diagnostics owned by the same report.
The original `structure`, `imports` and `readability` modules are also exported;
their allocating low-level APIs are intended for a caller-owned report arena.
See [DESIGN.md](DESIGN.md) for exact scope and lifetime boundaries.

```sh
zig fmt --check build.zig build.zig.zon src tests
zig build test check --summary all
zig build test check -Doptimize=ReleaseSafe --summary all
cd tests/package
zig build test --summary all
zig build test -Doptimize=ReleaseSafe --summary all
```

The CLI can also run as `zig run src/main.zig -- ...`, allowing canonical source
snapshots in tooling that launches standalone Zig programs. Source notices are
in [NOTICE](NOTICE); code is [MIT licensed](LICENSE). Consumer acceptance remains
separate from provider tests. No network service or external runtime is needed.
