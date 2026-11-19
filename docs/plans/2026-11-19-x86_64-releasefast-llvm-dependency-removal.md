# Remove the LLVM toolchain dependency from Zig ReleaseFast on x86_64 Linux

**Authorized on November 19, 2026.** The primary accepted the first
assignment, one ordinary `zig build-exe` of upstream Zig’s `cat` through the
finalized Zig IR builder, `z_llvm` and Zig’s native ELF linker. The
implementer landed Zig `ac359bdcd1` and z_llvm `8573a3df` locally.
The primary compared both committed diffs with the actual build inputs.
The primary also accepted the installed toolchain on Zig `bd0e36fadb`
and backend `8f2b12fb` after the isolated application and failure tests
and both link audits. The third assignment uses that package to rebuild
both tools and compare their upstream behavior. This
plan covers baseline `x86_64-linux-gnu`, ReleaseFast, pure Zig source and
the compiler runtime, system libc and CRT inputs identified for that target.

**Current handoff.** An ordinary cold build of unchanged upstream `cat`
exited zero on driver `5c6c457c` and helper `e1cfa98f`. The local
backend emitted all 1,833 application functions and all 921 compiler
runtime functions. Zig's native linker listed the local application
object and compiler-runtime archive. All six I/O cases passed. The first
run's post-build audit treated a relative path as absolute. The corrected
audit joined all four recorded paths under the compiler's working
directory. An independent cold build produced the same executable and
matched eight distinct application function bodies to its bytes. All
six shared-cache transitions passed, as did 75 upstream standard-library
tests, including join, detach and thread-local storage. After a forced
target-emitter failure the reviewer ran all six I/O cases on the preserved
executable. The archive audit traced both native link inputs and located
the application's `_start` at the final ELF entry point. All 17 serial
Tier 3 gates passed. The reviewer verified fresh exports for all three
real-input modes and the expected reference and native counts for each
of the 237 canary populations.
[Independent handoff review](../evidence/finalized_zig_builder_handoff_20261119.md)
[Cold driver and executable](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05/compile-result.json)
· [Six runtime cases](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05/runtime.json)
· [Reconciled cold audit](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05-audit/report.json)
· [Function bodies in the independently linked executable](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-positive/linked-code.json)
· [Shared-cache transitions](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-handoff-cache/observations.json)
· [Upstream thread tests](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-thread-runtime/result.json)
· [Complete runtime and application objects](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-replay/)
· [Serial preservation result](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-shifts-02-tier3/report.json)

The first startup revision, `fd145609`, emitted the application while
four runtime functions still failed. Independent review found that this
startup revision also omitted an explicit trap
after a returning call in both the one-block and multi-block forms.
The reviewer accepted the revised startup patch (`0cc47bcb`). The
same returning C target reached the explicit trap in all six LLVM and
local executions. The genuine 3,009,064-byte application object remained
byte-identical across the startup and arithmetic corrections.
[First whole application object and runtime selection](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/startup-replay/)
· [Cold driver result](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-03/compile-result.json)
· [Independent startup disassembly and reference execution](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-startup-trap/results.json)
· [Revised single-block and multi-block executions](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-startup-trap-fixed/results.json)

For Zig source promotion and package assembly, use the full patch
`a38ad006` captured by the build of driver `5c6c457c`. Pre-publication
review found that the proposed handoff pointed to an earlier development
snapshot, `f6779ada`. Three driver source files changed after that
snapshot. Reapply the five build-runner changes to the tested source and
compare the resulting installed SDK inputs before using it for a package.
[Driver build patch and input hashes](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/driver-build-04/inputs.txt)
· [Independently reconstructed source and SDK trees](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-source-reconciliation/report.json)

Zig's native linker consumed that application object with the known-good
compiler runtime from the native control. The resulting ELF, `2719a352`,
passed all six byte-for-byte tests. It has the same bytes as the fresh
provider-built executable. A fresh link with the application as its sole
input also produced those exact bytes and passed the six tests. The
runtime archive's own executable coverage comes from separate native
math calls.
[Link inputs and executable identity](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/startup-cat-link/result.json)
· [All six program executions](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/startup-cat-link/runtime.json)
· [Application-only link and runtime archive comparison](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-runtime-contribution/result.json)

The reviewer accepted the pointer-constant fix (`a6d28ef6`). The
four previously rejected runtime shifts all held their left operand in RCX,
which loading the count overwrote. The count occupied a spill slot in `ldexp`
and `log_f64`, and RAX in `sqrt_f64` and the unsigned-to-double
conversion. The 64-bit correction, `de5b293d`, passed its alias,
rollback and historical narrow-shift tests. The original conversion
routine passed all 4,545 independent numerical comparisons. The original
input replay produced a 3,061,936-byte runtime object (`b4f14c7a`).
The cold driver produced a distinct 3,061,992-byte member (`253ddd54`).
The reviewer extracted that member from the archive named by Zig's
native linker and linked each object to the same numerical caller. Both
objects matched the LLVM reference bit for bit on all 17 cases. They differ
in the ELF symbol and string tables. Their code, data, thread-local data
and relocation sections have identical bytes.
[Selection and operand traces](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/runtime-trace/census.stderr)
· [Independent pointer return and store checks](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-pointer-constants/review.json)
· [Historical narrow-shift checks](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/pointer-shift-boundary/test.stderr)
· [Rejected instructions and operands](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-arithmetic-census/selection.jsonl)
· [Native numerical reference](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-reference/observed.tsv)
· [Replay object results](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-runtime/observed.tsv)
· [Cold archive member](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-cold/archive.json)
· [Cold member results](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-cold/observed.tsv)
· [Section and IR comparisons](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/cold-app-05-ir-diff/comparison.json)
· [Reduced conversion and reference results](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-conversion-baseline/results.json)
· [Corrected conversion and 4,545 comparisons](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-conversion-fixed/results.json)

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
path absent. The later target-module fault after successful optimization
also preserved an existing executable and left an absent path absent.
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

The implementer owns the package build, actual link inputs and the
build-runner option that forwards the provider to the Zig and helper
compilation steps. Include that option in the standard library shipped
with generation one. Both generations will report the SDK compatibility
version `0.17.0` required by the backend project's existing exact
`.zigversion` check. Record the upstream development version
`0.17.0-dev.11+1c08b09d1`, published source revisions and actual
binary identities separately. Use the default release settings for
debug extensions. The reviewer owns the installed-file inventory,
recursive ELF dependency resolution, child arguments, mapped libraries
and independent program and failure runs. Start each isolated root empty.
Mount only the installed package, test inputs, named system libraries,
test controls and its own fresh workspace. Use an unprivileged mount
namespace when available. A locally imported empty container image is a
fallback. Record its unique tag and remove it after the run's last
consumer. Check actual host LLVM, Clang and LLD paths from inside the root.

For each package, the reviewer traces the real optimizer and emitter
arguments and exits and the native linker's input paths. Keep read-only
descriptors for the fresh driver-owned IR and object files through the
link. Zig removes some of those paths after a successful build. Hash the
actual files, compare the runtime object with its archive member and
locate application code in the final executable. Record the same evidence
for the complete upstream behavior run in each generation.

### First installed-compiler build

The seed started an ordinary native build from the reconciled Zig source
tree `94993cf8`, with fresh caches. The generated build options set both
`have_llvm` and `enable_debug_extensions` to false. The compiler build
exited 1 before installing `bin/zig`. A historical AIR export hook in
`captureZllvmAirFunction` called `Air.write`, which requires debug
extensions at compile time. No export had been requested.

The implementer owns a narrowly scoped repair to the optional hook.
Preserve the release defaults and test both an explicit export request
on the release compiler and the exporter on a debug-extension build.
Rebuild the installed compiler from fresh caches and record the updated
source for both generations. The failed command, generated build options
and diagnostic remain available through diagnosis and verification.
[Original compiler command and source tree](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-zig/entry.json)
· [Compiler diagnostic](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-zig/build.stderr)
· [Install outcome](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-zig/build-result.json)

The three-line change in Zig patch `7582370e` guards the optional
capture and diagnoses a requested export before opening its path. On
corrected source tree `60e74519`, the default compiler installed and
reported version `0.17.0`. It rejected an explicit export with exit 1,
preserved both existing files and left both absent destinations absent.
The same source built with debug extensions enabled and reproduced the
reference's 2,012-byte export exactly.
[Corrected driver source](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/source-02/zig.incremental.patch)
· [Enabled and disabled exporter controls](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/air-export-controls/control.json)
· [Original build and compiler-server exit statuses](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-first-failure-02/failure.json)

The installed driver `06c09683` then built and installed helper
`a95be5c7` using its own SDK and fresh caches. Both are x86_64 ELF
executables with no dynamic section. The implementer is tracing their
actual link inputs. The primary is checking the complete installation and
running both entry points in the isolated environment.
[Installed compiler](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-zig-02/build-result.json)
· [Installed helper and its compiler](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-helper/entry.json)
· [Helper installation result](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-helper/build-result.json)

**Package decision.** Both installed binaries have no interpreter or
shared-library dependencies. In an empty root, all 43 host dependency
paths were inaccessible. Both the native and selected builds of unchanged
`cat` passed all six cases. The two real emitter-failure controls
preserved their absent or existing destinations. The primary accepted
this package and assigned both isolated rebuilds to the implementer.
The primary owns the full behavior comparison for each generation.
[Installed toolchain and independent execution review](../evidence/llvm_free_zig_toolchain_20261119.md)

## 3. Rebuild and qualify the compiler in the isolated environment

The first full-suite compilation from the shipped G1 package and the
first isolated G2 Zig build both stopped in the selected optimizer with
`UnsupportedCallAttribute`. The G1 suite reached the runtime archive
and stopped before linking the test executable. The G2 Zig build
installed the SDK files and stopped before installing the compiler.
The primary owns reduction of the 46,421,094-byte behavior module.
The implementer owns the compiler and helper build witnesses, source
repair and fresh installs. Recheck the affected original modules, then
use the revised installed package for the ordinary builds and both
generations' behavior runs. Keep the earlier receipts with their
original package identities. [First full-suite result](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-g1-behavior/result.json)
· [First isolated compiler build](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-zig/build-result.json)

The first behavior failure came from upstream's ten-line empty-struct
method test. At line 282,884 of the generated module, a pointer argument
has alignment, read-only and non-null attributes followed by an outer
`getelementptr` and an inner `inttoptr`. The parser selected the inner
expression as the argument. The verifier then saw part of the outer
expression among the attributes. The implementer is correcting the
operand boundary and the primary is checking the original source,
observable pointer offsets and malformed-input behavior.
[Original verifier result and function](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-behavior-attribute/diagnosis.json)

The G2 compiler contained the same split in `InternPool.Key.hash64` at
line 845,782 of its 305,089,486-byte module. The reviewer isolated the
original behavior test as an ordinary `zig test`. LLVM and G1's native
backend each ran it successfully. The original G1 provider reproduced
the failure on the same argument. A separate LLVM executable read 66
from a real four-byte array through a nested pointer expression. The
original helper read 66 using the single-operation control and rejected
the nested form. Both rejected alignment 3.
[Original G2 compiler diagnosis](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/g2-zig-attribute-02/diagnosis.json)
· [Ten-line Zig test and three compiler routes](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-empty-struct-source/result.json)
· [Independent LLVM, positive and malformed IR controls](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-behavior-attribute-oracles/result.json)

The primary accepted the parser correction after the revised installed
helper ran the original test. All three original modules now optimize.
The implementer is repairing the remaining mandatory tail transfer in
the behavior suite and the four failed helper functions, and classifying
the full compiler's object results. The reviewer checks the original
tail-call pair under a bounded stack and exercises the helper arithmetic
against native LLVM and independent numerical expectations. In
`review-helper-arithmetic-boundaries`, the reviewer also checks both
fields of the i80 overflow intrinsics and signed i96 maximum on two
variable operands. The compiler trial subsequently emitted all 65,078
selected functions. Link and installation will be checked on the fresh
ordinary self-build.

The tail-call repair landed locally at `864af769`. Its trial emitted
all 7,459 behavior definitions. The reviewer also links that full trial
object to the existing G1 runtime to identify runtime failures early.
The generation qualification uses the actual link from each installed
toolchain's ordinary `zig test`.

That diagnostic link ran all 2,097 cases and found one additional
failure, the upstream `optimized float mode` test at row 866. The original
module contains both strict and fast additions and subtractions of
`2^40`. Its legacy debug-variable calls caused five optimizer passes
to be skipped. The implementer owns a correction that preserves debug
values. The reviewer checks the original source, the fast and strict
binary64 results, and inputs with debug uses of the intermediate and
final result. The ordinary generation suites must both match all rows.

The decimal repair landed at `e524d2e3`. Its native-built helper
restored all 45,448,870 reference bytes and all 21 independently
observed i256 values. The combined G1 build also includes the four
arithmetic repairs, which landed at `bb4f4c22`. The complete original
helper now emits all 14,820 functions. The tail-only G1 installation
compiled and ran all 2,097 upstream cases. Its two failures were the
wide shift at row 1098 and optimized floating point at row 866.

The first two combined installations are diagnostic builds. Their
floating correction preserved debug users by emitting a constant
floating-point select that the native backend could not lower. The
implementer built the floating correction at `g1-helper-06`. Its
ordinary installation produced helper `600cb8c4` and Zig `06c09683`.
The broader repository suite then identified a frozen selector
inventory violation and a stale capture-attribute test.
[Self-rebuild results and open source failures](../evidence/llvm_free_self_rebuild_20261119.md)

Use a typed immediate-to-register operation for the frameless
arithmetic repair. The selector guard must retain its frozen
inventory. Update the call-attribute test to check the supported
legacy pointer spelling and three invalid or unsupported cases.
The implementer owns both repairs and a full repository test run.
The reviewer checks the source diff, original helper functions and
numerical boundaries. Build the resulting ordinary G1 at
`g1-helper-07`, use it in `g2-zig-04` and `g2-helper-04`, then
test the newly extracted G2 archive before publishing it. Both
generations require the package, application, runtime and complete
ordered upstream checks. The G2-03 builds were still waiting for input
when their launchers were superseded.

The revised floating trial passed the complete upstream runtime with
the original G1 suite archive. All 2,097 ordered entries matched the
reference, including both earlier failures. On the corrected test
source, the implementer ran 576 exact f16, f32 and f64 selections.
The normal installed G1 and relocated G2 suites use their own cold
compilations, runtime archives and native links.
[Exact ordered trial result](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-float-linked-behavior-03/result.json)

The reviewer linked the two complete trial objects with the runtime
archives from their respective original isolated builds. Both static
executables started. Zig printed `0.17.0`, and the helper folded
`add i32 %x, 0` to `ret i32 %x`. The original producers keep their
objects and archives for the remaining ordinary-link comparisons.
[Native link and startup observations](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-trial-startup/result.json)

The second ordinary G1 behavior attempt reproduced the single tail-call
emission failure. Comparing its complete optimized module with the trial
helper's output uncovered a separate correctness defect. Given identical
builder bytes, the native-built installed helper changed one i256 argument
from `340282366920938463463374607431768211461` to `5`. The implementer
traced it to checked signed decimal multiplication in the native-built
helper. The reviewer checked positive and negative i256 limits and
keeps both full outputs for comparison with the revised installation.
[Installed suite attempt](../../local-state/validations/llvm-dependency-removal-20261119/rebuild-01/review-g1-behavior-02/result.json)

Record the seed executable, how it was produced, its libraries and every
host tool it prebuilds. The seed can build generation one in a separately
recorded environment. Then let generation one build generation two from
the pinned sources with fresh caches and install prefix, using the shipped
provider and native linker. Build the helper too for a self-rebuilding bundle
claim. Pinned Zig's build script sets `exe.use_llvm`; inspect how the
build runner passes the provider to the actual compiler and helper builds.
Add the corresponding native build option if needed. Check the selected
provider in each child command and match the emitted object to its link.
Attribute every build runner, generated tool, compiler object,
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

The final deliverable includes a relocatable local archive of the accepted
generation-two installation. The implementer retains that prefix while
the reviewer makes the archive, extracts it to a new directory and checks
every installed file and symlink against the original inventory. Use the
relocated tools for the independent package checks. After acceptance,
publish the archive to the project's immutable artifact store and record
its manifest and extraction command. Release the build prefixes once
their named consumers finish.

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

The independent reviewer checked the isolation procedure with the host's
small `true` executable while first-milestone preservation was running.
The local mount-namespace tool could not initialize loopback. The empty
Docker root ran the control and denied all 43 host LLVM, Clang and LLD
paths tested. Ordinary tracing recorded the child and its libc mapping.
The reviewer removed the temporary local image. The same stage reproduced
the archived behavior reference's ordered digest for all 2,097 cases.
The shipping review repeats the isolation checks with the actual package.
[Isolation method and control](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/isolation-01/preflight.json)
· [Discarded temporary image](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/isolation-01/scratch-image-release.json)
· [Ordered reference calibration](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/isolation-01/ordered-comparison.json)

Under the same file restrictions, the first-milestone driver's
`zig version` exited 127 at the missing `libclang-cpp.so.22.1`.
Its ELF also directly requires `libLLVM.so.22.1`. The actual static
`cat` from that driver passed all six cases in the same root. The
reviewer removed the run's temporary image.
[Known-dependent seed and independent program](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/seed-control-01/result.json)
· [Seed and program loader closure](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/seed-control-01/known-closure.json)
· [Image release](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/seed-control-01/scratch-image-release.json)

The reviewer accepted the build-runner changes on Zig patch `bb2b6f10`
and backend build-script patch `17abee8f` for the scoped package build.
Five ordinary installs used the existing seed and draft SDK. With the
option selected, the actual `build-exe --listen=-` received the whole
provider path, including spaces, as one argument. The unset route omitted
it. Replacing the selected executable at its original path triggered the
real emitter's `UnknownValue` error and preserved the installed `cat`.
Restoring the bytes reused that executable with zero root provider calls.
The implementer retains the draft source through transfer to the
distribution build. [Five ordinary builds](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/build-plumbing-03/summary.json)
· [Actual compiler and provider arguments](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/build-plumbing-03/transitions.json)
· [Preserved installed executable](../../local-state/validations/llvm-dependency-removal-20261119/review-preflight/build-plumbing-03/changed/oracle.json)

Set `ZIG_GLOBAL_CACHE_DIR` for the host-maker bootstrap and use
`--cache-dir` for the local directory. The public `zig build` command
rejects `--global-cache-dir`. Maker supplies that option to its
`build-exe` children after it has received the intended global root.

For the arithmetic and startup review, the implementer keeps the
original module inputs and candidate objects through the fresh driver
run. The reviewer uses separate temporary workspaces for the numerical
callers, entry tests and cache comparisons. The replay script now records
object and optimized-IR hashes in ordinary identity files. The reviewer
checked all 16 earlier entries against their targets and preserved their
contents when correcting their filenames. Each run records its exact
producer version. The explicit workspace release and collection receipts
go in the batch's storage directory.
[Original collector finding](../../local-state/retirements/automatic-storage-cleanup/1795084041675785218-849350/pin-references.json)
· [Reviewed identity transition](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-storage-identities/transition.json)
