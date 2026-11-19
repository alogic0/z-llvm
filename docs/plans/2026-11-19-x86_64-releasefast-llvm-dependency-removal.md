# Remove the LLVM toolchain dependency from Zig ReleaseFast on x86_64 Linux

**Authorized on November 19, 2026.** The implementer has taken up the first
assignment, one ordinary `zig build-exe` of upstream Zig’s `cat` through the
finalized Zig IR builder, `z_llvm` and Zig’s native ELF linker. The subsequent
claims cover a shippable compiler and a clean compiler self-rebuild. This
plan covers baseline `x86_64-linux-gnu`, ReleaseFast, pure Zig source and
the compiler runtime, system libc and CRT inputs identified for that target.

## Starting evidence

M3 built two byte-identical Zig compilers and matched all 2,097 ordered
upstream behavior outcomes. It used Zig `1c08b09d`, backend `d968e3ac`,
an LLVM-enabled CMake configuration, a stage-4 seed and host-tool cache
warmups. Zig’s C++ preopt hook printed a module after libLLVM had parsed the
bitcode. The build linked LLVM and Clang shared libraries and supplied LLD
archives. Its compiler and runtime objects already came from `z_llvm`.
The proposed baseline for new work is backend source `3a9b6d8f`.
[M3 build, providers and behavior](../evidence/release_fast_compiler_preopt_self_rebuild_20261117.md)

Pinned Zig already has a general serializer. In `src/codegen/llvm.zig`,
`Object.emit` finalizes error tables, module assembly, used globals and
module flags at lines 385–539. At line 559 it prints the live
`std.zig.llvm.Builder` as text. It calls `toBitcode` at line 565 and
`parseBitcodeInContext2` at line 614. The existing external IR-writer hook
at line 374 returns before finalization and calls `z_llvm --emit=ir-writer`.
Its 146 selected executable rows and 90 broader source-backed rows already
cover their respective inputs. The new evidence is a normal source build
whose complete module reaches the optimizer through the general serializer.
[Existing writer coverage](../roadmap/x86_64_selected_ir_writer_source_coverage.md)

## 1. Build an unchanged upstream program through the general handoff

**First assignment.** The implementer owns the Zig driver and backend changes
needed for this handoff. The primary reviewer verifies the provenance and
failure control. Use `test/standalone/simple/cat/main.zig` from Zig
`1c08b09d`, Git blob `bc894d3881fd59658dc17ca65afc3dd934226560`.
It reads stdin and files in argument order and writes arbitrary bytes. It
requires no case registration, source wrapper or generated program body.

1. Give the ordinary driver an explicit choice of `z_llvm` as its object
   provider. Hand the finalized builder’s text directly to the ReleaseFast
   optimizer and pass its output to the local ELF object emitter. Propagate
   printer, optimizer and emitter errors through the driver. Use
   `-O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline` and
   `-fno-libllvm -fno-lld`, select the builder for the Zig module, and let
   the normal link consume the resulting object. Check its target triple
   and data layout. On an LLVM-enabled seed, instrument the target module’s
   libLLVM bitcode-parse and module-print calls. The previous C++ preopt
   route should exercise both, and the new route should exercise neither.
2. Start with empty local and global caches. Record the source and tool
   identities, arguments, finalized IR hash, optimizer input and output,
   emitter input and ELF hash, actual linker input and executable hash.
   Identify the producers of startup, compiler-rt and libc/CRT inputs
   separately. Bind the selected provider, its identity and pipeline to
   cache reuse. Switch providers on a shared cache and check the actual
   object provenance.
3. Run the executable with empty stdin, with bytes containing NUL and a
   newline, and with `fileA - fileB`. Check exact stdout against the supplied
   bytes in order, empty stderr and exit zero. Run an ordinary native-backend
   build as a control. Both providers may return identical output.
4. In a separate fresh cache, give the real object emitter malformed IR
   after a successful optimizer invocation on the same unchanged program.
   Require its specific nonzero diagnostic to reach `zig build-exe`,
   with no final link or executable. Record the injected bytes and the real
   child’s exit status. Test an absent output path and a separate path
   containing a working executable. Check existence, mode and bytes after
   failure, and run the existing executable again.

**Review decision.** Accept the handoff when the independently checked
hashes connect the builder to the object actually linked, the ordinary program
passes, and the forced failure is observed. If compilation stops, preserve
the first failing module, stage and diagnostic. Repair that boundary and rerun
the same source before advancing. A successful first assignment leaves the
seed driver’s own linkage as a separate distribution question.

### First observations on November 19

The pinned stage-4 compiler built the unchanged program with its native and
LLVM code generators. Each executable passed six byte-for-byte tests,
including 65,543 bytes of binary stdin, filenames containing spaces and
repeated reads of stdin. The stock builder route with `-fno-libllvm`
returned its existing refusal. The historical C++ route called libLLVM’s
parse and print functions on the same application module in the same
process. [Stock results](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-baseline/)
· [Observed application-module calls and output](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-boundary-stock-03/observed.json)

The stock builder printed 1,833 definitions. LLVM 22 rejected a duplicate
separator on 1,444 weighted branches and then a missing `types` field on
one `DISubroutineType`. Correcting just those two forms in a diagnostic
copy let the whole module pass the LLVM verifier with empty stderr. Driver
`eae25950` incorporates those source repairs. Its newly printed whole
module passes the verifier and its ordinary LLVM executable passes all
six byte tests.
The real object emitter rejects the negative control’s undefined value
with exit 1, `UnknownValue` and zero output bytes. The cold driver build,
link and propagation of that failure are still open.
[Verifier result](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-stock-metadata/finding.json)
· [First local optimizer result](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/first-boundary/optimizer.stderr)

The first cold build with that driver and backend `9698153d` reached
the real optimizer on `compiler_rt`. The builder and child read the same
9,751,146 bytes. Zig propagated exit 1 and `UnsupportedCallAttribute`.
The same driver’s native control passed all six tests. Primary review also
reproduced a publication bug. A failed rebuild truncated a working
8,119,577-byte `cat` to zero bytes. The implementer is staging the final
ELF until the native link succeeds. [Cold compiler result](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-01/compile-result.json)
· [Existing destination before and after failure](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-front-failure/observed.json)

The application module exposed a second issue. The parser treated the
parentheses in two `getelementptr` callees as the call arguments. Review
covers void and value-returning calls, the seven-argument call to
`os.linux.x86_64.clone`, and a nonzero offset. On a separately
LLVM-printed copy the baseline optimizer succeeded and the emitter
reported five failures among 1,833 functions. These involve startup,
signal return, thread creation and cleanup, and thread-local storage. The
ordinary driver run determines which repairs qualify.
[Application parser diagnostic](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/parse-trace-03/trace.stderr)
· [Reference emitter diagnostics](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-canonical-reference/emit.stderr)

Independent review compared the fixed printer with the same compilation's
own Zig bitcode. After removing debug information and local names and
omitting the generated module-ID comment, both modules were 6,856,433
bytes and had identical contents across all 1,833 functions. The reviewer
accepted the printer for this application. The parser now also handles
intrinsic declaration parameter names and the legacy pointer attribute
`nocapture`. Both complete inputs, `cat` and `compiler_rt`, passed the local
parser and verifier. [Printer comparison](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-printer-equivalence/comparison.json)
· [Parser tests and full-module results](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/native-focused-01/)

Helper `0b3a9cf7` passed the independent zero-offset callee test. The void
and value-returning calls produced 40, and a C callee observing all seven
arguments returned the expected weighted sum of 303. A nonzero offset
survived optimization and the emitter diagnosed an unsupported indirect
call without writing an object. On the two complete modules both local
optimizer runs succeeded and LLVM verified both outputs. Emission still
failed on legacy debug intrinsic calls and the application startup
sequence. Repeat the unchanged cold driver after those repairs and run the
standard library thread tests against the resulting code.
[Independent callee controls](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-gep-callee-02/observed.json)
· [Complete-module emitter results](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/actual-replay-01/)

To isolate the debug-record issue, the reviewer removed only complete
`llvm.dbg.value` and `llvm.dbg.declare` calls from diagnostic copies of
the optimized inputs. LLVM verified both copies. The emitter's failure
count fell from 1,756 to 24 in the application and from 910 to 6 in the
runtime.
[Diagnostic reduction and counts](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-legacy-debug/comparison.json)

The reviewer accepted the metadata repair at patch `d9a92c20`. On
helper `9a929dad`, both genuine optimized modules kept their original
hashes and debug records. Their emitter diagnostics now match the
diagnostic copies byte for byte. All 14 focused tests passed. Four
independently emitted objects linked and executed, including an ordinary
call alongside a debug intrinsic. Its side effect occurred exactly once
for each of six inputs. The implementer owns the remaining pointer
constants, followed by the four scalar shifts and startup. The pointer
controls check that a zero-length slice retains its sentinel address 1
and that a positive offset into an array remains observable.
[Real module replay](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/codegen-debug-replay/)
· [Independent native check](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-debug-native/results.json)
· [Pointer-constant baseline](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-pointer-constants-baseline/local.emit.stderr)

The reviewer repeated the original optimizer failure with the same helper
and revised driver `5c6c457c`. The working destination kept all 8,119,577
bytes, its SHA-256 and mode 0775, and passed all six runtime checks after
the failure. A separate cold run on this driver reached the real
compiler-runtime object emitter and left its previously absent executable
path absent. The target-module fault after successful optimization remains
part of the final handoff check.
[Existing executable and before/after identities](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-publication-fixed/observed.json)
· [Post-failure runtime cases](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-publication-fixed/post-failure-oracle.json)
· [Absent executable](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-02/compile-result.json)

Use ordinary `build-exe` for the positive and forced-failure handoffs.
For the shared-cache test also exercise `zig run` or the build runner’s
`build-exe --listen=-`. Pinned `src/main.zig` gives a direct
`build-exe -femit-bin=path` a fresh main compilation even when its runtime
subcompilations use the supplied cache. Verify warm reuse, then change the
selected provider’s contents at the same path and inspect its actual
invocations and the cached executable.

## 2. Qualify the shipped driver and helper

Build a candidate bundle containing Zig and the selected `z_llvm` helper.
In pinned Zig, `build.zig:132` controls LLVM inclusion through
`-Denable-llvm`, while `-Duse-llvm` at line 226 chooses how the seed compiles
the Zig executable. `-Dstatic-llvm` selects library integration and normally
enables LLVM. `-Dskip-llvm` changes test selection. For the distributed
compiler use `-Denable-llvm=false` and record the generated `have_llvm`
setting. The LLVM-enabled CMake entry probes LLVM, Clang and LLD at
`CMakeLists.txt:136`. Record the actual build entry and link closure.

`src/Compilation/Config.zig:357` normally selects native codegen when
libraries are disabled and binary emission is requested. Its guard at line
373 rejects explicit builder-based binary emission in that configuration.
`src/Compilation.zig:2358` creates the builder-backed object only when
`use_llvm` is selected. The new provider needs a narrowly scoped way
through both decisions. `-fno-llvm` selects Zig’s native code generator.
Linker selection is independent at `src/Compilation/Config.zig:387`.

| Dependency surface | Evidence required |
| --- | --- |
| Shared libraries | Inspect the driver, helper and executable children. Resolve the recursive ELF dependencies, interpreter and search paths. Record the libraries actually loaded, including runtime loads. |
| Statically linked code | Audit actual link commands, response files and link maps or archive-member traces for the driver and helper. Account for `zigcpp`, LLVM, Clang and LLD libraries, including packaged alternatives. Record supplied archives and which members entered each binary. |
| Tool invocations | Trace child executables **and arguments**. Zig can reinvoke itself as `zig ld.lld` or a Clang frontend. A restricted root must also exclude absolute tool paths and shared libraries. Run reference tools in a separate environment. |
| Runtime and system inputs | Name and hash the Zig library tree, compiler-rt, libc, CRT and loader used. Record how newly compiled objects were produced. Keep the host seed and its build tools in a separate ledger. |

**Review decision.** Install the candidate bundle in an isolated environment
with LLVM, Clang and LLD libraries and tools unavailable. With fresh caches,
repeat the first milestone, including the forced failure, using the shipped
entry points. A passing result requires both a clean link-input audit and a
successful isolated run. Classify any first dependency by component and
stage before expanding to a compiler rebuild.

## 3. Rebuild and qualify the compiler in the isolated environment

Record the seed executable, how it was produced, its libraries and every
host tool it prebuilds. The seed can build generation one in a separately
recorded environment. Then let generation one build generation two from
the pinned sources with fresh caches and install prefix, using the shipped
provider and native linker. Build the helper too for a self-rebuilding bundle
claim. Attribute every build runner, generated tool, compiler object,
compiler-rt object and final link. A required warmup belongs to the
generation that performs it, with its own input and output identities.

Run both generations on `cat` and the ordered ReleaseFast behavior suite.
Compare all 2,097 case names and outcomes, including the 34 expected skips,
against the authenticated reference. Run LLVM comparisons separately. Check
fresh compiler/runtime object provenance, apply a forced real-provider
failure and run the milestone preservation tier. Compare generation binaries
under the same reproducible settings, and report byte identity only when the
hashes agree. Record the first divergence otherwise. A bootstrap from sources
with a different seed is a separate claim. Pinned Zig also has the
`bootstrap.c` route through a host C compiler, `wasm2c` and the checked-in
`stage1/zig1.wasm`; that seed and its provenance can be qualified explicitly.
[Validation tiers](../validation_tiers.md)

## Evidence ownership

Use `local-state/validations/llvm-dependency-removal-20261119/` with separate
batches for the handoff, distribution and rebuild. Before execution, name
each producer, consumer and release condition in the batch and run
`retention.md`. Use `tools/run-validation` and its command mode for custom
checks. Keep compiler builds, fresh caches, IR, objects, sysroots and
executables in managed workspaces through their named consumers. Preserve
compact identities, commands, provenance, runtime and failure observations,
audit results and cleanup receipts. Keep a first failing input under an
explicit investigation until disposition. Release each completed pipeline,
collect at its boundary, and account for remaining roots.
[Development storage contract](../development_storage.md)

Milestone 1 uses `handoff-01/`. The implementer owns the separate source,
compiler, candidate, native-link and fault-test stages. The primary reviewer
owns `review-baseline/` for the independent program oracle and stock-Zig
controls, and subsequent `review-*` stages for the frozen candidate, cache
and link evidence. The stock baseline may retain its compiler-generated IR
through comparison or diagnosis. Each producer records its own lifetime.
The shipped-toolchain and self-rebuild batches open after their preceding
gate passes.
