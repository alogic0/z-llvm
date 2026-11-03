# Source audit boundary

The library owns syntax evidence and a graph of literal source-relative imports.
Consumers own file selection, generated/test classification, architecture rules,
failure policy and presentation. IO is confined to the CLI. The compiler's public
AST/tokenizer APIs are used at the pinned Zig 0.17.0 version; other compiler
versions and platforms need separate qualification.

The extracted algorithms retain their original measurements and tests. Function
bytes include comments and physical formatting inside the declaration span;
decisions, switch arms and nesting remain separate signals. Nested functions/test
helpers have their own owners. Import decoding ignores string/comment decoys,
distinguishes literal named modules from file imports and retains unresolved
expressions, missing scanned targets and root escapes. Named build modules are
reported, not resolved or guessed. `_test.zig` and `/testing.zig` are the existing
test-file convention; inline test scopes are recognized through the AST.

`analyze` allocates a stable arena owner from the caller's allocator. Source and
paths are copied into it, parsed once, and graph construction reuses those import
records. The returned report survives input release. One `deinit` releases all
retained data; partial construction uses the same cleanup owner. Avoid copying
and releasing a report twice. Invalid syntax creates a null per-file structure
result and an error count; input and allocation errors abort construction.

The low-level allocating APIs preserve their report-arena contract for existing
consumers. Their slices/maps and temporary graph construction allocations do not
have independent deinitializers; use the owned API for arbitrary allocator use.
The nonallocating readability tokenizer only borrows input during the call.

Boundary selectors contain consumer paths. Traversal is iterative and reports a
single reachable chain per origin/target even when rules overlap. Scratch maps
and queues are reused; predecessor links avoid allocating every intermediate
chain prefix. Inline-test edges do not inflate production dependencies, and
intermediate test files are not followed. Worst-case transitive checking visits
the graph for every selected origin; scope rules to the desired owners. SCC
discovery is also iterative, including long chains and self-cycles.

The CLI uses selective directory traversal, skips dependency/build/vendor trees
and symlinks, sorts paths before analysis and enforces explicit source limits.
It writes one JSON/text report, without storing code or making network calls.
Limits bound admitted bytes and file count, not total AST/report peak memory.
Consumer UI/backend behavior, database operations and application authorization
are outside this package.
