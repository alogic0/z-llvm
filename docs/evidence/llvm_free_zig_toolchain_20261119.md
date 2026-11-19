# Installed Zig and z_llvm without LLVM, Clang or LLD

The primary accepted the first installed package on November 19 for
baseline x86_64 Linux GNU, ReleaseFast and the explicit z_llvm object
provider. The installed compiler built unchanged upstream `cat` through
Zig's finalized builder, the shipped optimizer and object emitter, and
Zig's native ELF linker in an empty root. The earlier seed used LLVM.
The clean rebuild of both tools has its own generation and test results.
[Implementation plan](../plans/2026-11-19-x86_64-releasefast-llvm-dependency-removal.md)

## Installed files and source

| Generation-one tool | Installed bytes | SHA-256 |
| --- | ---: | --- |
| `bin/zig` | 186,137,540 | `06c09683d36cb62768deb22657c6b9fd3a7ed7e387791695a9c0724199629fc0` |
| `bin/z_llvm` | 110,419,804 | `a95be5c7cd4da2442a9066de6b5799467afa47822e87049d1afe70695e746ad1` |

Two separately collected inventories agreed on all 19,503 entries. The
only binary artifacts were these two ELF files. Both have no interpreter
or shared-library dependencies. The SDK is installed under `lib/zig`.
The modified build-runner files and finalized builder match the source
bytes. The package reports `0.17.0`, the SDK version required by the
backend's build script. The local source revisions are Zig `bd0e36fadb`
and backend `8f2b12fb`. The primary compared both committed patches
with the inputs used for the install. The published Zig tree is `60e74519`.
[Independent file inventory](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-package-elf/package-inventory.json)
· [ELF headers and loader closure](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-package-elf/elf-closure.json)
· [Source tree and patch identities](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/source-02/source.json)

## What built the package

The recorded LLVM-enabled seed compiled generation-one Zig using its
native x86_64 backend with `have_llvm=false`. The seed loaded LLVM and
Clang, used `zig ld.lld` for its host build runner and supplied an
LLVM-generated compiler-runtime object. Runtime code from that object
is present in the installed Zig. The newly installed Zig then built
`z_llvm` with fresh caches and its own SDK. That build used its native
compiler runtime and linker. The reviewer checked bytes at the recorded ELF
offsets in both installed binaries. In the original helper report,
`memcpy` and `compiler_rt.memcpy.memcpyFast` name the same body.
[Seed build and inputs to the installed Zig](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-zig-link-03/report.json)
· [Installed Zig building the helper](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/g1-helper-link-03/report.json)
· [Archive member selection control](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/archive-reader-control/control.json)

## Ordinary builds in the isolated root

Each case started with empty caches. All 43 tested host paths to LLVM,
Clang and LLD were inaccessible. The selected build executed the
package's two optimizer and two object-emitter processes. All four
exited zero. Tracing recorded no shared-library mappings in the compile
tree. The native and selected executables each passed six byte-for-byte
I/O tests, including binary stdin, files with spaces and repeated stdin.
[Package commands and actual loader observations](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-positive/executions-and-loads.json)
· [Excluded host files](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-positive/host-exclusions.json)
· [Selected program](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-positive/result.json)
· [Native control](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-native/result.json)

The reviewer held read-only descriptors to the actual IR and the temporary
linker inputs. The application object was `173ba554`. Eight distinct
function bodies matched bytes of the final ELF. The compiler-runtime
object `253ddd54` matched the sole member of the archive named by the
native linker. That same member had matched all 17 LLVM numerical
reference results in the first milestone. The selected executable's
SHA-256 is `ef08cbf48a1e91ec3138cb5d933ce40c79c1645cf09554f8586320e1f6de1cc0`.
[Actual inputs, archive member and linked functions](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-positive/result.json)
· [17 numerical results on the same member](../../local-state/validations/llvm-dependency-removal-20261119/handoff-01/review-numeric-cold/observed.tsv)

In each failure control the real application optimizer exited zero.
The real emitter rejected the injected undefined value with
`UnknownValue`, exited 1, and Zig exited 1 before the target link.
An absent executable stayed absent. A pre-existing executable kept its
SHA-256, mode 0755 and all 12,903,512 bytes. It passed the same six
cases after the failure. Each run removed its temporary container image.
[Absent destination](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-fault/result.json)
· [Existing destination](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-fault-existing/result.json)
· [Six post-failure executions](../../local-state/validations/llvm-dependency-removal-20261119/distribution-01/review-cat-fault-existing/preserved-oracle.json)
