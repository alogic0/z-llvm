# Whole-compiler diagnostic baseline

The diagnostic implementation is committed at `10dbc168`; whole-compiler
object emission is blocked.
No compiler executable was linked or run, and no self-hosting or accepted
capability counter advances. The [machine-readable report](whole_compiler_diagnostic_20261107.json)
binds the retained inputs and observations. Production compiler sources,
frontend sources and accepted compiler binaries are unchanged.

## Configuration and actual results

The source pin is `1c08b09d1c847f4f02c8216e3b62df323861a437`, using stage4
`0.17.0-dev.11+1c08b09d1`. The compiler configuration is x86_64 Linux GNU,
baseline CPU, ReleaseFast, stripped output, full development features and
LLVM enabled. The postopt route retains LLVM optimization and explicitly
records the existing C++/LLVM/Clang/LLD/system providers. It does not replace
those libraries. The backend is the unchanged accepted ReleaseFast binary,
SHA-256 `28962d94a9c832f56098273a55ae92fbe809598f3eb5e670e29b475c1ba53a4a`.

| Input | Retained size | Definition lines | First rejected stage | Diagnostic |
| --- | ---: | ---: | --- | --- |
| Complete compiler module | 443,624,107 bytes | 8,928 | Parsing | `UnsupportedGlobalVariable` |
| Compiler runtime module | 1,856,543 bytes | 455 | Verification | `InvalidCast` |

Definition counts are textual observations, not successful local selections.
Neither input reaches function selection or object writing. Link, `zig version`,
behavior and self-rebuild stages consequently remain untested for this compiler.

The original executable build stops on `compiler_rt` before the compiler's own
module reaches the hook. A separate continuation reuses the recorded compiler
build-exe arguments, disables runtime/binary emission, and requests optimized
LLVM IR for the complete `src/main.zig` configuration. That frontend operation
succeeds. The exact exported module is then handed to z_llvm with conservative
dependency selection, generic selection, report-all diagnostics and profiling.
This continuation does not bypass the runtime failure or earn linking credit.

The compiler IR SHA-256 is
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
The original export and retained backend input have identical hashes. Its
target triple is `x86_64-unknown-linux5.10.0-gnu2.31.0`; it also contains 473
declaration lines and 36,959 global/alias lines. The runtime input hash is
`ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af`.

## Failure attribution

The compiler's first rejected global is `@__anon_756545`, at input line 11,597.
It contains a packed aggregate type and nested constant initializer. Independent
syntax parsing of all 36,959 global/alias records rejects **111**, all with
packed aggregate constant syntax. Their names, line numbers, diagnostics and
prefixes are retained in `verified-global-census.jsonl`. The unchanged parser
currently routes angle-bracket types through vector parsing. The exact first
rejection is retained as [packed_global.ll](../../test/whole_compiler/packed_global.ll).
These results establish a shared parsing boundary; they do not prove that
packed layout, verification and constant/object emission already work.

For the runtime, a diagnostic projection keeps all declarations, global data
and function headers, replaces other bodies with `unreachable`, and first
requires that baseline to verify. It then restores each original body in turn.
Of 455 bodies, one is rejected: `compiler_rt.sincos.sincos_f32`, with
`InvalidCast`. A reduced [vector fptrunc](../../test/whole_compiler/vector_fptrunc.ll)
reproduces the error with the unchanged backend. The 454 other bodies passing
this projection earn no selection, emission or execution credit. No projected
program is emitted or executed. These observations are not an exhaustive list
of later compiler obstacles.

The next implementation priority is shared packed aggregate support, including
correct layout and constant emission rather than syntax admission alone.
Replay the retained compiler input after each repair to expose the next stage.
Vector floating-point casts form a separate runtime capability slice. The
earlier AIR `error!u8` probe remains a deferred gap, on a different input route.

## Reproduction and validation

The [runner documentation](../validation_tools.md) gives the maintained entry
points. The authoritative run is `attempt-4` under
`local-state/validations/whole-compiler-20261107/`. It retains exact arguments,
closed environments, source hashes, CMake configurations, provider hashes,
input IR, raw diagnostics, profiles and timing. Original configuration is
unchanged; a retained derived configuration resolves installed multiarch
providers to explicit paths. Earlier attempts retain the corrected build-runner
option error, library-discovery failure and initial runtime rejection.

```sh
zig run -O ReleaseFast tools/run_whole_compiler.zig -- \
  --output-root local-state/validations/new-whole-compiler \
  --zllvm local-state/validations/large-function-performance-20261107/compiler-fast/bin/z_llvm
```

Use `--input-ir` with the retained compiler module for a backend-only replay;
fresh frontend generation is unnecessary when only the backend changes. The
census tools reproduce both reports exactly. They explicitly separate syntax,
verification and selection results. A global-context error stops the function
census, and extracting a rejected global refuses to overwrite an existing file.

Four report tests pass in both Debug and ReleaseSafe. Five actual CLI fixtures
cover a successful object, early parsing failure, two selection failures plus
one selected function, the captured packed global, and the reduced vector cast.
A real pinned-frontend postopt hook emits a checked object, and a native driver
passes four full-width arithmetic observations. That small smoke program is
separate from the unbuilt compiler. Missing/partial counts, substituted owners,
duplicate reports and incomplete ownership are rejected by report controls.

The prior 17-gate acceptance is reused only for unchanged production compiler,
registered gate, pin, pipeline and corpus inputs. This opt-in diagnostic adds
no accepted population and makes no new compiler-readiness claim. All 13
original scratch probes, both accepted compiler hashes, frontend source state,
provider/configuration hashes and the 62 retained evidence artifacts verify.
The artifact manifest is `artifacts.sha256` under the evidence root.
The final runner also replays both exact retained inputs and reproduces their
parse/verify failures. A final guard requires the compiler's own object capture
in any future self-rebuild; that later branch remains unexecuted because the
current inputs fail earlier. The primary-run and final runner binaries remain
separately identified in the artifact manifest.
All 742 current compiler/tool/diagnostic-fixture source paths and hashes match
the final replay snapshot; the committed implementation is the tested source.

Frontend generation of the compiler IR takes 313.16 seconds, with GNU time
maximum RSS 2,499,648 KiB. The local backend rejects parsing in 0.71 seconds,
maximum RSS 869,856 KiB. These are single observations, not a performance
comparison. Primary-attempt free space starts at 42.02 GB and reaches a sampled
minimum of 40.33 GB; postcheck free space is 39.64 GB. Admission remains
32,949,672,960 bytes and execution reserve 24,359,738,368 bytes. No archives
were created and previous AIR, compilers and evidence remain.
