# INBOX-206BL Zig descriptor-identity API audit

## 1. Scope and disposition

This document is the sole INBOX-206BL result. It is a read-only API and
architecture audit for the prospective pure-Zig 0.16 materializer described by
`docs/evidence/inbox206bk_zig_materialization_readiness_design.md`. It does not
implement, compile, format, build, install, test, execute, validate, or generate
evidence with that tool.

```text
design_kind=zig_descriptor_identity_api_audit
descriptor_identity_status=conditionally_supported
implementation_authority=none
execution_authority=none
build_authority=none
install_authority=none
evidence_generation_authority=none
D01=withheld
D02=unauthorized
ratchet=131
continuation_root_created=false
evidence_file_created=false
```

`conditionally_supported` is the only support conclusion justified by this
audit. The installed Zig 0.16 standard library exposes a sufficiently explicit
Linux raw-ABI route to call `statx(fd, "", AT.EMPTY_PATH, mask, &result)` and to
interpret its result fail-closed. This slice did not invoke the syscall, a Zig
compiler, or any runtime probe, so neither the running kernel nor the backing
filesystems have demonstrated the required `STATX_MNT_ID_UNIQUE` capability.
That missing runtime observation prevents `supported_runtime_checked`. The
fully specified raw-ABI contract below prevents `blocked`, provided the future
implementation is restricted to the audited target and treats every capability
or identity shortfall as terminal.

## 2. Operating and retained authority

The audit is bound to this non-merge operating state:

| Identity | Value |
|---|---|
| HEAD | `5b3007a502be13a3b6673b6cb47244592c2e09e8` |
| direct parent | `f9b2f30a154e5422c53d04bc21cc1e92e667300b` |
| tree | `0346b5d4942612630f125e757e47180899be3767` |
| sole operating-commit path | `docs/next_steps.md` |
| `docs/next_steps.md` SHA-256 | `9f8a5fcad3702a7db91dade60bedbb62a1062a388ba1c4a5bb4632981c7bbf3c` |
| `docs/worker_inbox.md` SHA-256 | `0d4303f27ba06c058550aaab4323830e5486a15f530dd4582c958e737e4b3654` |
| accepted BK commit | `f9b2f30a154e5422c53d04bc21cc1e92e667300b` |
| accepted BK document SHA-256 | `66b0dfdff5c61b00a16e815994bb9c06e3596260d611a2e35cb83cbe99b9e187` |
| accepted BK document bytes/mode | `29834` / `0644` |
| installed Zig standard-library root | `/home/oleg/.zig/0.16.0/files/lib/std` |
| installed Zig version identity | `0.16.0` (path-bound; compiler not invoked) |

The accepted BK document remains byte-for-byte unchanged. Its references to
“section 11” and “section 11.4” are bounded editorial errata: the intended
targets are sections 12 and 12.3 respectively. This audit records that mapping
without editing BK or changing its technical design.

## 3. Read authority and implementation-source ledger

The initial read set was limited to BK and the four exact standard-library
files named by INBOX-206BL. Three further standard-library implementation files
were read only because the named files directly import or alias them and they
were necessary to close the raw call ABI. No registered-worktree directory was
entered.

### 3.1 Initially authorized files

| Path | SHA-256 | Relevant symbol or reason |
|---|---|---|
| `docs/evidence/inbox206bk_zig_materialization_readiness_design.md` | `66b0dfdff5c61b00a16e815994bb9c06e3596260d611a2e35cb83cbe99b9e187` | accepted prospective-tool architecture |
| `/home/oleg/.zig/0.16.0/files/lib/std/os/linux.zig` | `54d019f38778161dfd57e0da36fcf9ed0cd25e4ac792617dff2dc35b7513f185` | `statx`, `errno`, `AT`, `STATX`, `Statx` |
| `/home/oleg/.zig/0.16.0/files/lib/std/Io/Dir.zig` | `413302d836c509684352d7fa92ae377e469da504b6ec771e53fb5475fafe5b46` | `Dir.Handle`, `OpenOptions`, descriptor-relative directory opens |
| `/home/oleg/.zig/0.16.0/files/lib/std/Io/File.zig` | `ef1600af9cfcb35e4f2ad626a28ce3a45bdb04c84fcf9309d027767da0e00330` | `File.Handle`, `OpenFileOptions`, `File.Stat` |
| `/home/oleg/.zig/0.16.0/files/lib/std/Io/File/Atomic.zig` | `bc31d9be7cb7bb27bb643fee1bd34dbf35d89d5af0e4961e91ca74b21eba7cc9` | exclusive atomic publication behavior |

### 3.2 Directly referenced implementation files

| Path | SHA-256 | Direct-reference reason | Audited symbol |
|---|---|---|---|
| `/home/oleg/.zig/0.16.0/files/lib/std/os/linux/x86_64.zig` | `b3d40d530aa21b6f10752f8ca000e8901188f87eb569953200c39ed965447572` | `std.os.linux` selects this architecture implementation for Linux x86_64 outside the x32 ABI; the call convention cannot be closed without it | `syscall5` |
| `/home/oleg/.zig/0.16.0/files/lib/std/os/linux/syscalls.zig` | `76f37d6fa92d2a450dab935445a0276f5f51a05930b161a6554f8df9dedef184` | `std.os.linux` imports its `SYS` enumeration; the syscall number is part of the audited ABI | `X64.statx = 332` |
| `/home/oleg/.zig/0.16.0/files/lib/std/posix.zig` | `5b1462b18db6757d984e118e09c532ac8b98cf1cc1ed48f18fcdbb362b75b5e0` | both named `Io.Dir` and `Io.File` define `Handle` as `std.posix.fd_t`; its target type is needed for the raw-call conversion contract | `fd_t` |

No other implementation source is relied upon by this conclusion.

## 4. Actual Zig 0.16 call surface

The installed source declares this raw wrapper in `std.os.linux`:

```zig
pub fn statx(
    dirfd: i32,
    path: [*:0]const u8,
    flags: u32,
    mask: STATX,
    statx_buf: *Statx,
) usize
```

It forwards the five operands directly through `syscall5(.statx, ...)`. On the
audited Linux x86_64 ABI, syscall number 332 is placed in `rax`; arguments are
placed, in order, in `rdi`, `rsi`, `rdx`, `r10`, and `r8`; the `syscall`
instruction returns the raw result in `rax` and clobbers `rcx`, `r11`, and
memory. The wrapper returns that raw machine word. It is not an error union and
does not translate errno itself.

`std.os.linux.errno(raw_result)` performs the required conversion: a bitcast
signed result in the Linux error interval `(-4096, 0)` becomes the corresponding
positive `E` enum value; any other result is `E.SUCCESS`. The future tool must
call `errno` exactly once for each raw `statx` return and may inspect the output
structure only when it is `SUCCESS`.

On the audited native target, `std.Io.Dir.Handle` and `std.Io.File.Handle` alias
`std.posix.fd_t`, whose Linux representation is `i32`. The implementation must
still close this at compile time rather than silently narrowing:

```text
builtin.os.tag == .linux
builtin.cpu.arch == .x86_64
target ABI is not x32
@sizeOf(std.os.linux.Statx) == 0x100
std.Io.Dir.Handle == i32
std.Io.File.Handle == i32
```

If a future Zig spelling cannot express the last two type equalities directly,
the design permits an equivalent compile-time type/size/signedness assertion
followed by a checked conversion. It does not permit an unchecked cast. A target
that does not satisfy every restriction is rejected before materialization.

## 5. Exact call, flags, mask, and result contract

For each already-open directory or regular-file descriptor `fd`, the future
implementation's descriptor-identity operation is semantically fixed as:

```zig
var result: std.os.linux.Statx = std.mem.zeroes(std.os.linux.Statx);
const raw = std.os.linux.statx(
    fd,
    "",
    std.os.linux.AT.EMPTY_PATH | std.os.linux.AT.STATX_SYNC_AS_STAT,
    std.os.linux.STATX.BASIC_STATS | .{ .MNT_ID_UNIQUE = true },
    &result,
);
const err = std.os.linux.errno(raw);
```

This is specification pseudocode, not compiled authority. The implementation
must use the syntax accepted by the separately authorized Zig 0.16 build while
preserving these exact values:

| Operand | Required value | Reason |
|---|---:|---|
| `dirfd` | the held descriptor, represented as checked `i32` | bind identity to the opened object, not a re-resolved path |
| `path` | a sentinel-terminated empty string | select the descriptor itself |
| flags | `AT.EMPTY_PATH | AT.STATX_SYNC_AS_STAT`, numeric `0x1000` | permit an empty pathname and request normal synchronization semantics |
| mask | `STATX.BASIC_STATS | STATX.MNT_ID_UNIQUE`, numeric `0x47ff` | request type, mode, inode, standard metadata, and a non-reused mount identity |
| result | zero-initialized, aligned `Statx` object | prevent stale caller bytes from being interpreted |

The returned mask is authority, not the requested mask. Success requires:

```text
errno(raw) == SUCCESS
(result.mask & STATX.BASIC_STATS) == STATX.BASIC_STATS
result.mask.MNT_ID_UNIQUE == true
```

Requiring the complete `BASIC_STATS` set is deliberately stronger than merely
checking its `TYPE`, `MODE`, and `INO` bits. The installed `STATX` definition has
no separate validity bits for `dev_major` and `dev_minor`; therefore the audit
does not invent any. Their admission is tied to successful return of the full
basic-stat set. The required identity tuple is:

```text
descriptor_identity = {
    dev_major: result.dev_major,
    dev_minor: result.dev_minor,
    inode: result.ino,
    mount_id_unique: result.mnt_id,
}
```

`result.mnt_id` is accepted as a unique mount identity only when the returned
mask contains `MNT_ID_UNIQUE`. A response containing only `MNT_ID` is rejected:
ordinary mount IDs can be reused and do not satisfy the ABA defense. The same
storage field has different authority according to the returned mask, so no
consumer may detach the value from that mask check.

The tool must also use the returned `TYPE` and `MODE` information to match the
role expected for that descriptor. A correct tuple on an object of the wrong
type or permission mode is a failure, not identity success.

## 6. Error taxonomy and fail-closed mapping

Every non-success errno is terminal for the current materialization attempt.
There is no path-based `stat`, `/proc/self/fd`, inode-only, ordinary-mount-ID, or
best-effort fallback.

| Error class | Representative Linux `E` values | Stable attribution | Required outcome |
|---|---|---|---|
| capability unavailable | `NOSYS`; success with missing `MNT_ID_UNIQUE` | kernel/filesystem cannot furnish the audited identity | `DescriptorIdentityCapabilityUnavailable`; stop before any write |
| descriptor invalid | `BADF` | closed, invalid, or inappropriate descriptor | `DescriptorIdentityBadDescriptor`; stop |
| ambiguous invalid argument or capability | `INVAL` from any descriptor-identity `statx` callsite | the raw result cannot distinguish an unsupported flag/mask/kernel path from an invalid ABI or argument at that callsite | `DescriptorIdentityInvalidOrUnsupported`; stop before any write; this classification takes precedence over both capability-unavailable and caller/ABI-invalid classifications |
| caller/ABI invalid | `FAULT`; impossible success return shape | pointer, layout, flags, or ABI defect | `DescriptorIdentityAbiViolation`; stop |
| permission/policy | `PERM`, `ACCES` | kernel security or access policy denies observation | `DescriptorIdentityPermissionDenied`; stop |
| pathname/acquisition inconsistency | `NOENT`, `NOTDIR`, `LOOP`, `NAMETOOLONG` | a prior component/open assumption is no longer true | preserve the first component-specific acquisition attribution; stop |
| resource/transient kernel failure | `INTR`, `IO`, `NOMEM` and every other non-success errno | observation did not complete | `DescriptorIdentityObservationFailed`; stop without retry in the consuming one-shot gate |
| returned-mask deficiency | any missing `BASIC_STATS` bit or missing `MNT_ID_UNIQUE` after syscall success | result is partial or lacks non-reused mount identity | `DescriptorIdentityMaskIncomplete`; stop |
| role mismatch | returned type or mode differs from the exact role contract | descriptor is not the authorized object kind | `DescriptorIdentityRoleMismatch`; stop |
| tuple mismatch | any tuple field differs across required observations | namespace/object binding changed | `DescriptorIdentityChanged`; stop |

At every descriptor-identity `statx` callsite, `E.INVAL` is attributed first
and exclusively to `DescriptorIdentityInvalidOrUnsupported`. No callsite may
reclassify it as either capability absence or caller/ABI invalidity without a
separately authorized discriminator that was not established by the frozen BL
source evidence.

The future error set may use different Zig identifiers only if a separately
reviewed mapping preserves these stable first-attributed categories one to one.
It must never coalesce capability absence with identity mismatch, because those
conditions have different remediation authority.

## 7. Descriptor acquisition and traversal contract

Identity observation is meaningful only inside a closed acquisition discipline.
The future tool must:

1. Acquire the trusted starting descriptor by calling
   `std.Io.Dir.openDirAbsolute` on the exact literal `/` with
   `OpenOptions{ .access_sub_paths = true, .iterate = false,
   .follow_symlinks = false }`, and retain that descriptor. A descriptor
   obtained by resolving a longer absolute path is not a trusted anchor.
2. Validate every configured path component before access: nonempty; not `.` or
   `..`; no slash; no NUL; and exactly the canonical byte spelling authorized by
   the typed configuration.
3. Acquire each literal component with `std.Io.Dir.openDir` relative to the
   immediately retained parent descriptor, again using
   `OpenOptions{ .access_sub_paths = true, .iterate = false,
   .follow_symlinks = false }`, and retain every descriptor in the chain. This
   requirement applies independently to every ancestor and final component; a
   no-follow check on only the final component cannot protect its ancestors.
4. Reject the component if the opened object's descriptor-relative statx type or
   mode does not match its exact role.
5. Record the four-field identity tuple for every component while all ancestor
   descriptors remain open.
6. Repeat an independent descriptor-relative walk from the trusted anchor before
   publication, compare every tuple in order, and retain both chains until that
   comparison and publication decision complete.
7. Perform the exclusive publication relative to the retained authorized final
   directory descriptor, never by re-resolving an absolute or ambient path.
8. Repeat the walk and tuple comparison after publication before claiming the
   audit record complete.

`std.Io.Dir.OpenOptions` in the inspected Zig 0.16 source exposes
`follow_symlinks`, but does not expose a `resolve_beneath` option comparable to
`std.Io.File.OpenFileOptions.resolve_beneath`. This is not permission for a
generic string walk. The accepted narrow substitute is one descriptor-relative
open per validated single component, with no separators or traversal tokens,
starting at and remaining under the retained trusted anchor. If the future
implementation cannot preserve those literal component boundaries in the
available `Io.Dir` API, it is blocked and must not fall back to a multi-component
path open.

## 8. Threat-model closure

### 8.1 Rename and namespace rebinding

An open descriptor continues to designate the opened object across rename. That
is required, not a defect: publication remains relative to the authorized held
directory rather than an attacker-controlled re-resolution. The independent
pre- and post-publication walks determine whether the configured namespace path
still resolves to the same object chain. A rename-away, exchanged directory, or
replacement inode changes at least one tuple and fails closed. Moving the same
object away and back without changing any held-object identity does not create a
different authority object and is not falsely classified as one.

### 8.2 Mount replacement and mount-ID reuse

The device/inode pair alone is insufficient because mounts and inodes can be
reused. `MNT_ID_UNIQUE` is mandatory precisely to distinguish mount instances
without accepting the reusable ordinary `MNT_ID`. A mount replacement, bind
mount change, or namespace-visible remount that changes the mount instance must
change `mount_id_unique` and fail the ordered tuple comparison. If the kernel or
filesystem cannot return the unique field, the entire materializer is
capability-blocked before writing.

The tuple's authority is limited to one running-kernel lifetime. It is not a
durable identity across reboot, kernel restart, or evidence imported from a
different host. No persisted tuple may authorize a later run.

### 8.3 Inode reuse and descriptor lifetime

All descriptors from the first observation remain open until the independent
comparison and publication boundary complete. Consequently, unlinking a
component cannot free its referenced inode for reuse while that first descriptor
is held. The comparison still includes device and unique mount identity. Closing
the first chain before the second observation would reopen an inode-reuse ABA
window and is prohibited.

### 8.4 Mount namespaces and process state

All observations and publication occur in one process and its unchanged mount
namespace. The tool must not call `setns`, `unshare`, spawn a helper that performs
identity observation, or accept identity tuples from another process. The unique
mount ID is evaluated only in that fixed runtime context. A future launcher that
cannot prove this single-process boundary is a structural blocker.

### 8.5 TOCTOU boundary

The protected object is the held descriptor, not a pathname snapshot. Namespace
rewalks immediately before and after the exclusive publication prove that the
configured path binding agreed with that held object at both boundaries. A
concurrent change between those observations either leaves publication safely
targeting the held authorized object or is detected by the post-publication
comparison. Detection after an exclusive write does not authorize cleanup,
replacement, retry, or authority transition; the partial publication and records
remain for a later directive.

## 9. Publication coupling

Descriptor identity does not itself publish bytes. It is a prerequisite for the
BK exclusive-publication design. The future implementation must retain the final
directory descriptor and the complete first observation chain while it:

- creates and fully writes the private staging object;
- flushes that object according to the reviewed durability contract;
- uses the standard-library atomic link/no-replace behavior relative to the held
  final directory;
- treats `PathAlreadyExists` as a fail-closed conflict, never overwrite authority;
- performs the post-publication descriptor-chain observation; and
- records success only after byte, mode, schema, identity, and durability closure.

If the available Zig API cannot make the link relative to the already validated
directory descriptor without ambient-path re-resolution, that is a separate
local-API blocker. It cannot weaken the descriptor-identity contract audited
here.

## 10. Required future checks before support may advance

The status can advance from `conditionally_supported` to
`supported_runtime_checked` only under separate explicit authority that permits
implementation, build, and a bounded synthetic runtime check. That future slice
must establish all of the following without touching real authority or stores:

1. The compile-time target/layout/handle assertions in section 4 pass under the
   pinned Zig 0.16 toolchain.
2. The exact empty-path statx call returns `SUCCESS` for synthetic held directory
   and regular-file descriptors.
3. The returned mask contains all `BASIC_STATS` bits and `MNT_ID_UNIQUE`.
4. The result's type/mode and tuple fields are stable across a no-change rewalk.
5. Synthetic rename, replacement, symlink, mount-capability absence where safely
   injectable, closed descriptor, and wrong-role cases map to the required
   fail-closed categories.
6. No alternate identity source or production/public reachability is introduced.

Until then, `conditionally_supported` is a design result only. It grants no
implementation, build, install, execution, evidence-generation, D01, D02,
validation, authority-transition, or production credit.

## 11. Protected-state confirmation

The main and supplemental control repositories were clean at the operating
gate. The control repository remained on `main` at its frozen identity with no
remote. The watcher and PID 3206208 were not disturbed. The stash, pins, bypass
inventory, source, tools, build files, stores, retained evidence roots, all 43
registered worktrees, and ratchet 131 were preserved. No registered-worktree
directory and no `.claude/settings.local.json` path was accessed. No BI evidence
file or continuation was created.

This document is an inert audit. Its commit does not change BK, create the
prospective tool, or authorize any downstream action.
