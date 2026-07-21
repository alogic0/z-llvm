# INBOX-206CJ Variant-2 Sealed-Descriptor API Audit

## 1. Scope and disposition

This is a static evidence/API audit. It neither implements nor invokes a descriptor producer or consumer, supplies real bytes, selects CC Variant 2, or grants execution or production authority.

```text
slice=INBOX-206CJ
audit_kind=sealed_descriptor_creator_receiver_api
sealed_descriptor_api_support=conditionally_supported
creator_compile_time_api=available_on_pinned_linux_zig_0.16
runtime_support=unverified
receiver_origin_status=seal_capable_only
producer_binding=blocked
selected_variant=none
implementation_authority=none
real_byte_supply_authority=none
execution_authority=none
production_authority=none
D01=withheld
D02=unauthorized
ratchet=131
```

CF remains accepted only for its private synthetic snapshot consumer and atomic single-use token. CG remains the controlling real-byte boundary: final-byte verification, acquisition-time event-freedom, producer provenance, and lifecycle admission are separate claims.

## 2. Frozen evidence and static API authorities

| Authority | Frozen identity and relevant contract |
| --- | --- |
| Committed CG | commit `c96f92144cb29526d44078ee955481ba36df4195`; blob `9311a8980f9540769ef6a8c6f1dd7cd469c5ff02`; raw SHA-256 `352dc3dc444affc7202160c1e98cbb0954849c9964879ea2bed859d0336333b4`; `selected_variant=none` |
| Accepted CF source | commit `86e16bf3bb173d3d72ae1b17b6e64f9e9a3b4e2b`; tree `da1045a183412d5d0a957e0563ec1c85331e0a6f`; blob `77809d948ef6ee630f17c721cb071f7353feb3a8`; raw SHA-256 `f7adf9f37bf7b64b80ef4fe1077562a0a32390e2c07e4db9ddb6f55e4f7cbcef` |
| `std/posix.zig` | mode 0644; 60,638 bytes; SHA-256 `5b1462b18db6757d984e118e09c532ac8b98cf1cc1ed48f18fcdbb362b75b5e0`; exposes `memfd_create`/`memfd_createZ` and a partially coalesced error set |
| `std/os/linux.zig` | mode 0644; 291,416 bytes; SHA-256 `54d019f38778161dfd57e0da36fcf9ed0cd25e4ac792617dff2dc35b7513f185`; exposes raw `memfd_create`, `fcntl`, `pread`, `statx`, `errno`, `MFD`, `F`, `AT`, and `STATX` contracts |
| `std/c.zig` | mode 0644; 371,584 bytes; SHA-256 `f7062a55808aac78c515abd8bee5d36a596ee2de4116f61a51125107f84be158`; exposes libc declarations and aliases Linux `F`/`MFD` constants |
| `/usr/include/linux/memfd.h` | mode 0644; 1,467 bytes; SHA-256 `d06dd37df2ad2df29391c38239c1af6944efef8dc4040ed41833169cd4c4a3c9`; defines `MFD_CLOEXEC` and `MFD_ALLOW_SEALING` |
| `/usr/include/linux/fcntl.h` | mode 0644; 4,545 bytes; SHA-256 `ae5234007eb7755459bcd1c44846e9b1b4a3a2cea65afa4442aaf48fd8987c6f`; defines add/get operations and seal bits |
| `memfd_create(2)` | mode 0644 compressed reference; 5,595 bytes; SHA-256 `68fbaf5dedb2fd76b99006342a91fd92a610fd92e7c6afb42a670af55995a57c` |
| `fcntl(2)` | mode 0644 compressed reference; 18,551 bytes; SHA-256 `8e3b9107e6c80d418e7ce4542e156e01bcaf8bbf004dbc716891ea5fb59584a4` |

These are static API/reference identities, not runtime capability evidence. No syscall or descriptor was invoked in this audit.

## 3. Four claims that must remain independent

| Claim | Necessary evidence | What seals contribute | Current result |
| --- | --- | --- | --- |
| Content immutability during acquisition | The required seal mask is observed on the exact held descriptor before reading and remains kernel-enforced for its inode | `F_SEAL_WRITE` plus `F_SEAL_GROW` and `F_SEAL_SHRINK` can close content and size mutation; `F_SEAL_FUTURE_WRITE` is insufficient | conditionally supportable, runtime unproved |
| Returned-byte identity | The trusted Zig consumer owns a complete snapshot whose length is exactly 29,834, whose SHA-256 matches the expected raw digest, and whose exact-offset probe reaches EOF | None; seals do not identify returned bytes | closed only for CF synthetic input |
| Descriptor-origin provenance | A trusted chain proves which creator produced and transferred the exact descriptor | None; regular-file mode and successful `F_GET_SEALS` prove only seal capability | blocked |
| Git commit/tree/blob provenance | A trusted producer binds the supplied bytes to the exact BK commit/tree/blob and separately to raw length/SHA-256 | None; digest equality is not Git provenance | blocked |

Seals close only the first claim, and then only after the required mask is successfully observed. No pass may be borrowed between rows.

## 4. Compile-time API availability versus runtime support

For a Zig 0.16 Linux target, the pinned standard library provides:

- `std.posix.memfd_create` and `memfd_createZ`; on Linux the wrapper selects libc only when the pinned version check permits it, otherwise it uses `std.os.linux.memfd_create`;
- `std.os.linux.memfd_create`, `fcntl`, `pread`, `statx`, and `errno` raw wrappers, so no handwritten syscall ABI is needed;
- `std.os.linux.MFD.CLOEXEC` and `.ALLOW_SEALING`;
- `std.os.linux.F.ADD_SEALS`, `.GET_SEALS`, `.SEAL_WRITE`, `.SEAL_GROW`, `.SEAL_SHRINK`, `.SEAL_FUTURE_WRITE`, and `.SEAL_SEAL`;
- `std.os.linux.AT.EMPTY_PATH` and `STATX.SIZE`/`Statx.size` for a prospective descriptor-relative post-seal size observation.

This establishes compile-time symbol availability for the pinned native Linux design only. It does not establish that the running kernel implements `memfd_create`, recognizes the seal operations/bits, supports sealing on the supplied descriptor's filesystem, or supports the requested descriptor-relative size query.

The pinned `std.posix.memfd_create` maps Linux `EINVAL` to the combined `NameTooLong` error and routes other unlisted errno values through `UnexpectedError`; its Linux branch does not explicitly map `ENOSYS` to `SystemOutdated`. A future exact fail-closed implementation therefore needs a separately reviewed error adapter over the pinned raw Linux wrapper so it can distinguish runtime absence and invalid flags rather than relying on the coalesced high-level error alone. This audit authorizes no such adapter.

## 5. Seal-mask and ordering contract

```text
creation_flags=MFD_CLOEXEC|MFD_ALLOW_SEALING
event_freedom_mask=F_SEAL_WRITE|F_SEAL_GROW|F_SEAL_SHRINK
protocol_closure_bit=F_SEAL_SEAL
insufficient_substitute=F_SEAL_FUTURE_WRITE
```

`MFD_CLOEXEC` prevents inheritance across `execve`; it does not replace explicit ownership or transfer rules. `MFD_ALLOW_SEALING` is a creation precondition. Without it, a memfd starts with `F_SEAL_SEAL`, so the creator cannot add the required seals.

The creator must populate and size the object before sealing, remove every writable shared mapping, and then add the event-freedom mask. Successful addition of `F_SEAL_WRITE` is essential because the kernel rejects it with `EBUSY` while a writable shared mapping exists. `F_SEAL_FUTURE_WRITE` alone is forbidden: pre-existing writable shared mappings remain able to mutate content after that seal is set.

`F_SEAL_GROW` and `F_SEAL_SHRINK` are required alongside `F_SEAL_WRITE`; without both, the size can change even when ordinary content writes are blocked. `F_SEAL_SEAL` is only protocol closure: seals are already irreversible, and this bit merely prevents later seal additions. It does not prevent seal removal because removal is never allowed. A selected protocol may add it with the required mask and require its observation, but event-freedom derives from write/grow/shrink, not from `F_SEAL_SEAL`.

Neither creator nor receiver may claim event-freedom until `F_GET_SEALS` succeeds on the held descriptor and the observed mask contains every event-freedom bit. An unsupported operation, missing bit, or ambiguous result fails closed.

## 6. Creator matrix

| Stage | Creator obligation | Success evidence | Fail-closed cases and ownership |
| --- | --- | --- | --- |
| Target gate | Compile only for the separately accepted native Linux target and pinned Zig APIs | All required wrapper/types/constants are available at compile time | Unsupported target/API is a compile-time blocker; no fallback ABI |
| Create | Invoke the audited raw wrapper with only `MFD_CLOEXEC | MFD_ALLOW_SEALING`; creator owns the returned descriptor | Raw result has `errno == SUCCESS`; creator knows it made this call | `EFAULT` is an internal pointer invariant failure; `EINVAL` means bad flags/name or unsupported flag combination; `EMFILE`, `ENFILE`, `ENOMEM`, `EPERM`, `ENOSYS`, and every unexpected errno fail and leave no descriptor to transfer |
| Populate | A separately authorized pure-Zig producer writes exactly the trusted input and establishes exact size 29,834 | Producer-specific provenance record plus complete write/size success | Partial write, overflow, unexpected EOF/source failure, or unavailable real-byte authority closes and consumes the owned descriptor |
| Remove mutable aliases | End every creator-held writable shared mapping before requesting `F_SEAL_WRITE` | Creator-owned mapping ledger is empty | Any unclosed mapping or ambiguous alias state blocks sealing/transfer |
| Add seals | Call `F_ADD_SEALS` with write/grow/shrink and, if selected by protocol, seal-seal | Raw `fcntl` result has `errno == SUCCESS` | `EBADF`; `EBUSY` from a writable shared mapping; `EINVAL` for unknown operation/bit or unsupported filesystem; `EPERM` for nonwritable descriptor or existing seal-seal; any other errno: close, no transfer |
| Observe seals | Call `F_GET_SEALS` after add and interpret the result only after `errno == SUCCESS` | Observed mask contains write/grow/shrink and any required protocol-closure bit | `EBADF`; `EINVAL` for unknown operation or unsupported sealing; missing bit, negative/error result, or unrecognized role: close, no transfer |
| Verify post-seal size | Use a separately reviewed descriptor-relative size observation after seals are confirmed | Size field is present and exactly 29,834 | Unsupported/missing size field, nonregular role, size mismatch, or observation error: close, no transfer |
| Transfer | Transfer the exact owned descriptor and an independently trusted provenance record under one explicit protocol | Receiver obtains one owned descriptor and immutable administrative metadata | Duplicate/second transfer, unclear ownership, or incomplete provenance: close, no transfer |

The creator's knowledge that it called `memfd_create` is local creator provenance. It becomes receiver provenance only through a separately trusted, explicit transfer and identity protocol.

## 7. Receiver matrix

| Stage | Receiver obligation | Success evidence | Fail-closed cases and ownership |
| --- | --- | --- | --- |
| Admission | Accept exactly one transferred descriptor under an explicit owned-or-borrowed contract; the recommended prospective contract transfers ownership | One descriptor enters one unused CF token lifecycle | Reuse, recursion, concurrency loss, second supply, or ambiguous ownership returns unavailable without reading |
| Role | Treat an unproven received object only as a seal-capable descriptor | Descriptor is open, regular, and supports `F_GET_SEALS` | Regular-file mode or seal query success must not be described as proof of memfd origin; ambiguous role blocks |
| Observe seals | Run `F_GET_SEALS` before size or byte admission and require the event-freedom mask | `errno == SUCCESS` and write/grow/shrink are all present; protocol-closure bit is checked separately if required | `EBADF`, `EINVAL`, any unexpected errno, or any missing bit: close if owned, no callback/snapshot |
| Verify size | After seal observation, query the held descriptor without pathname reopening | Returned size field is supported and equals 29,834 | Overflow, unsupported query/field, size mismatch, or descriptor error: close if owned |
| Positional acquisition | Use a private checked offset and the pinned raw `pread`; never use or modify a shared current offset | Each successful count is nonzero, no larger than remaining, and advances a checked private offset | Any errno, zero progress before completion, count overflow, offset overflow/cast failure, or partial input fails the CF read contract |
| Exact-offset EOF | After exactly 29,834 bytes, issue one positional read into one stack byte at private offset 29,834 | Successful return count is exactly zero | Any byte is trailing; any errno or impossible count fails closed |
| Snapshot identity | CF copies and hashes identical bytes into one owned allocation and compares exact digest | Exact length, EOF, and digest all pass before `VerifiedSnapshot` is returned | Partial, trailing, read failure, zero progress, overflow, digest mismatch, or allocation failure consumes the token and frees once |
| Lifetime/close | Returned snapshot and transferred descriptor have separate owners; descriptor may close after acquisition, snapshot deinitializes once later | Receiver closes the owned descriptor exactly once on success or failure; snapshot caller deinitializes once | Leak, double close, use after close, descriptor reuse, or snapshot alias outside its verified type blocks acceptance |

For each positional call, the private offset must be representable as the pinned `pread` `i64` offset. Every offset-plus-count computation is checked before conversion and before the call. Errors do not advance the offset. This keeps acquisition independent of concurrent changes to an open file description's shared current offset.

## 8. F_ADD_SEALS and F_GET_SEALS error taxonomy

| Operation | Result | Required interpretation |
| --- | --- | --- |
| `F_ADD_SEALS` | success | Requested seals are kernel-enforced immediately; still perform `F_GET_SEALS` and mask observation |
| `F_ADD_SEALS` | `EBADF` | Descriptor is invalid; terminal failure |
| `F_ADD_SEALS` | `EBUSY` | Requested `F_SEAL_WRITE` conflicts with an existing writable shared mapping; terminal failure, never substitute future-write |
| `F_ADD_SEALS` | `EINVAL` | Operation/bit is unrecognized or the filesystem/object does not support sealing; terminal unsupported result |
| `F_ADD_SEALS` | `EPERM` | Descriptor is not writable or current seals already include seal-seal; terminal protocol failure |
| `F_ADD_SEALS` | other errno | Unexpected terminal failure; no optimistic mapping |
| `F_GET_SEALS` | nonnegative success value | Interpret only as a seal mask for this inode; it does not prove memfd origin |
| `F_GET_SEALS` | `EBADF` | Descriptor is invalid; terminal failure |
| `F_GET_SEALS` | `EINVAL` | Operation is unavailable or the filesystem/object does not support sealing; terminal unsupported result |
| `F_GET_SEALS` | other errno | Unexpected terminal failure; no mask claim |

Adding an already-set seal is a no-op only when seal-seal is not already set. Seals are inode properties shared by all descriptors for that inode and can only be added, never removed.

## 9. Administrative identity versus trusted producer binding

The administratively accepted BK identity is:

```text
spec_path=docs/evidence/inbox206bk_zig_materialization_readiness_design.md
spec_commit=f9b2f30a154e5422c53d04bc21cc1e92e667300b
spec_tree=174923e4bfd78f6ae003556a9ed17ddf950d74fd
spec_blob=573e128bb999d8aba15ae5ac6dc69a52ac3e8812
spec_raw_sha256=66b0dfdff5c61b00a16e815994bb9c06e3596260d611a2e35cb83cbe99b9e187
spec_raw_bytes=29834
```

Git blob identity and raw SHA-256 are distinct domains. A trusted pure-Zig producer must receive these expected values from an authorized immutable manifest; obtain the exact committed bytes through a separately authorized provenance-preserving input boundary; verify the Git-side identity without hiding extraction in Git plumbing, shell, agent transport, or another language; verify raw length and SHA-256 in Zig; populate the one owned descriptor; close every mutable alias; add and observe the required seals; verify post-seal size; and transfer that exact descriptor together with the immutable provenance record.

Current authority supplies the administrative constants and the synthetic CF consumer only. It authorizes no real BK-byte acquisition, Git-object extraction, external provisioner, trusted descriptor transfer, or runtime seal proof. Therefore the producer boundary is unclosed. Matching the raw digest would prove final byte equality, not that the descriptor came from the recorded Git commit/tree/blob.

## 10. Support verdict

| Question | Verdict | Reason |
| --- | --- | --- |
| Are the required Zig/Linux APIs and constants present in the pinned static sources? | yes, compile-time only | Raw standard-library wrappers and constants are present for Linux |
| Is runtime kernel/filesystem support established? | no | No syscall/descriptor probe or synthetic sealed-descriptor test is authorized or recorded |
| Can a creator establish content event-freedom prospectively? | conditionally | Only after successful write/grow/shrink seal addition and subsequent mask observation |
| Can a receiver infer memfd origin from regular mode and `F_GET_SEALS`? | no | Those observations prove only a seal-capable descriptor absent trusted provenance |
| Is returned snapshot identity covered? | synthetic only | CF verifies bounded length/hash/EOF only for synthetic input |
| Is Git provenance bound to a real descriptor producer? | no | No authorized pure-Zig real-byte/provenance boundary exists |
| May Variant 2 be selected now? | no | Runtime support and producer/provenance remain open |

```text
support_verdict=conditionally_supported
selected_variant=none
```

Any unsupported syscall, missing required seal, ambiguous descriptor role, arithmetic/offset overflow, incomplete close/ownership path, or unclosed producer provenance keeps this verdict fail-closed.

## 11. Smallest prospective recommendation

The smallest next step is a separately authorized private pure-Zig synthetic creator/receiver test slice using only generated non-BK bytes. It should exercise the pinned raw Linux wrappers, `MFD_CLOEXEC | MFD_ALLOW_SEALING`, write/grow/shrink seal addition, explicit rejection of future-write as a substitute, mask observation, post-seal size, checked positional reads, exact-offset EOF, ownership transfer, and close-on-all-paths behavior. It must report runtime unsupported cases rather than skip or infer support.

That prospective test would address runtime API support only. It would not supply real BK bytes, prove descriptor-origin provenance to a receiver, bind Git commit/tree/blob provenance, select Variant 2, or grant implementation, execution, provisioning, publication, or production authority. A later independently reviewed pure-Zig producer/provenance boundary would still be required.

## 12. Terminal boundary

CJ changes no source, build, tool, script, cache, output, continuation, store, or control state. It creates no descriptor, runs no syscall probe, and reads no real bytes or Git object contents. Registered worktrees remain protected.

```text
audit_complete=true
implementation_ready=false
real_byte_provisioning_ready=false
selected_variant=none
execution_authority=none
production_authority=none
D01=withheld
D02=unauthorized
ratchet=131
```
