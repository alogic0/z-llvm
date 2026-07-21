const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;

const ExpectedRole = enum {
    directory,
    regular_file,
};

const DescriptorIdentity = struct {
    device_major: u32,
    device_minor: u32,
    inode: u64,
    mount_id_unique: u64,
};

const DescriptorIdentityError = error{
    DescriptorIdentityCapabilityUnavailable,
    DescriptorIdentityBadDescriptor,
    DescriptorIdentityInvalidOrUnsupported,
    DescriptorIdentityAbiViolation,
    DescriptorIdentityPermissionDenied,
    DescriptorIdentityPathAcquisitionInconsistent,
    DescriptorIdentityObservationFailed,
    DescriptorIdentityMaskIncomplete,
    DescriptorIdentityRoleMismatch,
};

const ComponentValidationError = error{
    ComponentLexicallyInvalid,
    ComponentNameMismatch,
};

const AcquiredDirectory = struct {
    /// The caller owns this directory and must close it. The identity remains
    /// comparable only while this exact descriptor stays open.
    directory: std.Io.Dir,
    identity: DescriptorIdentity,
};

const TrustedHomeChain = struct {
    /// The caller owns both values and must close `home` before `root`.
    root: AcquiredDirectory,
    home: AcquiredDirectory,
};

const TrustedOlegChain = struct {
    /// The caller owns all values and must close oleg, then home, then root.
    root: AcquiredDirectory,
    home: AcquiredDirectory,
    oleg: AcquiredDirectory,
};

const TrustedProgChain = struct {
    /// The caller owns all values and must close prog, oleg, home, then root.
    root: AcquiredDirectory,
    home: AcquiredDirectory,
    oleg: AcquiredDirectory,
    prog: AcquiredDirectory,
};

fn assertNativeAbi() void {
    if (builtin.os.tag != .linux) {
        @compileError("INBOX-206 descriptor identity requires native Linux");
    }
    if (builtin.cpu.arch != .x86_64) {
        @compileError("INBOX-206 descriptor identity requires native x86_64");
    }
    if (@sizeOf(usize) != 8 or @sizeOf(isize) != 8 or @sizeOf(c_long) != 8) {
        @compileError("INBOX-206 descriptor identity requires LP64 and rejects x32");
    }
    const fd_info = @typeInfo(std.posix.fd_t).int;
    if (fd_info.signedness != .signed or fd_info.bits != 32) {
        @compileError("INBOX-206 descriptor identity requires a signed 32-bit Linux descriptor");
    }
    if (@sizeOf(linux.Statx) != 0x100) {
        @compileError("INBOX-206 descriptor identity requires the audited 256-byte statx layout");
    }
}

comptime {
    assertNativeAbi();
}

fn requiredMask() linux.STATX {
    var mask = linux.STATX.BASIC_STATS;
    mask.MNT_ID_UNIQUE = true;
    return mask;
}

fn requireSuccessfulErrno(errno_value: linux.E) DescriptorIdentityError!void {
    switch (errno_value) {
        .SUCCESS => return,
        .NOSYS => return error.DescriptorIdentityCapabilityUnavailable,
        .INVAL => return error.DescriptorIdentityInvalidOrUnsupported,
        .BADF => return error.DescriptorIdentityBadDescriptor,
        .FAULT => return error.DescriptorIdentityAbiViolation,
        .PERM, .ACCES => return error.DescriptorIdentityPermissionDenied,
        .NOENT, .NOTDIR, .LOOP, .NAMETOOLONG => return error.DescriptorIdentityPathAcquisitionInconsistent,
        else => return error.DescriptorIdentityObservationFailed,
    }
}

fn requireMask(actual: linux.STATX) DescriptorIdentityError!void {
    const actual_bits: u32 = @bitCast(actual);
    const required_bits: u32 = @bitCast(requiredMask());
    if (actual_bits & required_bits != required_bits) {
        return error.DescriptorIdentityMaskIncomplete;
    }
}

fn requireRole(mode: u16, expected_role: ExpectedRole) DescriptorIdentityError!void {
    const actual_role = mode & linux.S.IFMT;
    const expected_mode: u16 = switch (expected_role) {
        .directory => linux.S.IFDIR,
        .regular_file => linux.S.IFREG,
    };
    if (actual_role != expected_mode) return error.DescriptorIdentityRoleMismatch;
}

/// Observes an already-held descriptor without taking ownership of it. The
/// caller must keep the descriptor open for the complete comparison lifetime;
/// closing and reopening it invalidates comparisons with the returned value.
fn observeDescriptor(
    descriptor: std.posix.fd_t,
    expected_role: ExpectedRole,
) DescriptorIdentityError!DescriptorIdentity {
    var result = std.mem.zeroes(linux.Statx);
    const raw_result = linux.statx(
        descriptor,
        "",
        linux.AT.EMPTY_PATH | linux.AT.STATX_SYNC_AS_STAT,
        requiredMask(),
        &result,
    );
    try requireSuccessfulErrno(linux.errno(raw_result));
    try requireMask(result.mask);
    try requireRole(result.mode, expected_role);
    return .{
        .device_major = result.dev_major,
        .device_minor = result.dev_minor,
        .inode = result.ino,
        .mount_id_unique = result.mnt_id,
    };
}

fn validateComponentLexical(component: []const u8) ComponentValidationError!void {
    if (component.len == 0 or
        std.mem.eql(u8, component, ".") or
        std.mem.eql(u8, component, ".."))
    {
        return error.ComponentLexicallyInvalid;
    }
    for (component) |byte| {
        if (byte == '/' or byte == 0) return error.ComponentLexicallyInvalid;
    }
}

fn validateComponent(
    candidate: []const u8,
    expected: []const u8,
) ComponentValidationError!void {
    try validateComponentLexical(candidate);
    try validateComponentLexical(expected);
    if (!std.mem.eql(u8, candidate, expected)) return error.ComponentNameMismatch;
}

/// Borrows `parent` without closing it and opens exactly one validated child.
/// On success the caller owns `directory`, must close it, and must keep its
/// descriptor open for the complete lifetime of comparisons with `identity`.
fn acquireOneDirectoryComponent(
    parent: std.Io.Dir,
    io: std.Io,
    candidate: []const u8,
    expected: []const u8,
) !AcquiredDirectory {
    try validateComponent(candidate, expected);
    const child = try parent.openDir(io, candidate, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    errdefer child.close(io);
    const identity = try observeDescriptor(child.handle, .directory);
    return .{
        .directory = child,
        .identity = identity,
    };
}

/// Opens only the root of the process's current mount namespace. The caller
/// owns the returned directory and is solely responsible for closing it.
fn acquireTrustedRoot(io: std.Io) !AcquiredDirectory {
    const directory = try std.Io.Dir.openDirAbsolute(io, "/", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    errdefer directory.close(io);
    const identity = try observeDescriptor(directory.handle, .directory);
    return .{
        .directory = directory,
        .identity = identity,
    };
}

/// Transfers ownership of both held descriptors to the caller, which must
/// close the home descriptor before the root descriptor.
fn acquireTrustedHomeChain(io: std.Io) !TrustedHomeChain {
    const root = try acquireTrustedRoot(io);
    errdefer root.directory.close(io);
    const home = try acquireOneDirectoryComponent(root.directory, io, "home", "home");
    return .{
        .root = root,
        .home = home,
    };
}

/// Transfers all three held descriptors to the caller, which must close them
/// in oleg-before-home-before-root order.
fn acquireTrustedOlegChain(io: std.Io) !TrustedOlegChain {
    const home_chain = try acquireTrustedHomeChain(io);
    errdefer home_chain.root.directory.close(io);
    errdefer home_chain.home.directory.close(io);
    const oleg = try acquireOneDirectoryComponent(home_chain.home.directory, io, "oleg", "oleg");
    return .{
        .root = home_chain.root,
        .home = home_chain.home,
        .oleg = oleg,
    };
}

/// Transfers all four held descriptors to the caller, which must close them
/// in prog-before-oleg-before-home-before-root order.
fn acquireTrustedProgChain(io: std.Io) !TrustedProgChain {
    const oleg_chain = try acquireTrustedOlegChain(io);
    errdefer oleg_chain.root.directory.close(io);
    errdefer oleg_chain.home.directory.close(io);
    errdefer oleg_chain.oleg.directory.close(io);
    const prog = try acquireOneDirectoryComponent(oleg_chain.oleg.directory, io, "prog", "prog");
    return .{
        .root = oleg_chain.root,
        .home = oleg_chain.home,
        .oleg = oleg_chain.oleg,
        .prog = prog,
    };
}

fn expectAcquisitionError(
    expected_error: anyerror,
    parent: std.Io.Dir,
    io: std.Io,
    candidate: []const u8,
    expected: []const u8,
) !void {
    if (acquireOneDirectoryComponent(parent, io, candidate, expected)) |acquired| {
        acquired.directory.close(io);
        return error.TestUnexpectedResult;
    } else |actual_error| {
        try std.testing.expect(actual_error == expected_error);
    }
}

const snapshot_internal_ceiling: u64 = 64 * 1024;

const SnapshotTokenState = enum(u8) {
    unused,
    in_progress,
    consumed,
};

const SnapshotToken = struct {
    /// This atomic object's address is the uniqueness boundary. It must not be
    /// copied or moved while it is usable or an acquisition is in progress.
    state: std.atomic.Value(SnapshotTokenState) = .init(.unused),
};

const SnapshotExpectation = struct {
    exact_length: u64,
    supplied_maximum: u64,
    expected_digest: [std.crypto.hash.sha2.Sha256.digest_length]u8,
};

const SnapshotReadNextResult = union(enum) {
    bytes: usize,
    eof,
};

const SnapshotReadNextFn = *const fn (
    context: *anyopaque,
    destination: []u8,
) anyerror!SnapshotReadNextResult;

const SnapshotError = error{
    SnapshotTokenUnavailable,
    SnapshotLengthInvalid,
    SnapshotMaximumTooSmall,
    SnapshotInternalCeilingExceeded,
    SnapshotLengthOverflow,
    SnapshotReadFailed,
    SnapshotZeroProgress,
    SnapshotPartial,
    SnapshotTrailing,
    SnapshotDigestMismatch,
};

const VerifiedSnapshot = struct {
    allocator: std.mem.Allocator,
    bytes: []u8,

    fn deinit(self: *VerifiedSnapshot) void {
        self.allocator.free(self.bytes);
        self.* = undefined;
    }
};

fn observeVerifiedSnapshot(snapshot: *const VerifiedSnapshot) []const u8 {
    return snapshot.bytes;
}

/// Consumes one caller-owned token and one bounded synchronous byte supply.
/// Returned bytes are allocator-owned and are observable only through the
/// verified snapshot type after length, EOF, and digest checks all succeed.
fn acquireVerifiedSnapshot(
    allocator: std.mem.Allocator,
    expectation: SnapshotExpectation,
    token: *SnapshotToken,
    context: *anyopaque,
    read_next: SnapshotReadNextFn,
) (SnapshotError || std.mem.Allocator.Error)!VerifiedSnapshot {
    if (token.state.cmpxchgStrong(.unused, .in_progress, .acq_rel, .acquire) != null) {
        return error.SnapshotTokenUnavailable;
    }
    defer token.state.store(.consumed, .release);

    if (expectation.exact_length == 0) return error.SnapshotLengthInvalid;
    if (expectation.exact_length > expectation.supplied_maximum) {
        return error.SnapshotMaximumTooSmall;
    }
    if (expectation.exact_length > snapshot_internal_ceiling) {
        return error.SnapshotInternalCeilingExceeded;
    }
    const exact_length = std.math.cast(usize, expectation.exact_length) orelse
        return error.SnapshotLengthInvalid;
    const length_with_probe = @addWithOverflow(exact_length, @as(usize, 1));
    if (length_with_probe[1] != 0) return error.SnapshotLengthOverflow;
    _ = length_with_probe[0];

    const owned = try allocator.alloc(u8, exact_length);
    errdefer allocator.free(owned);

    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var filled: usize = 0;
    while (filled < exact_length) {
        const result = read_next(context, owned[filled..]) catch
            return error.SnapshotReadFailed;
        switch (result) {
            .eof => return error.SnapshotPartial,
            .bytes => |count| {
                if (count == 0) return error.SnapshotZeroProgress;
                if (count > exact_length - filled) return error.SnapshotReadFailed;
                const next = @addWithOverflow(filled, count);
                if (next[1] != 0) return error.SnapshotLengthOverflow;
                hasher.update(owned[filled..next[0]]);
                filled = next[0];
            },
        }
    }

    var trailing_probe: [1]u8 = undefined;
    const trailing_result = read_next(context, &trailing_probe) catch
        return error.SnapshotReadFailed;
    switch (trailing_result) {
        .eof => {},
        .bytes => |count| {
            if (count == 0) return error.SnapshotZeroProgress;
            if (count > trailing_probe.len) return error.SnapshotReadFailed;
            return error.SnapshotTrailing;
        },
    }

    var actual_digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    hasher.final(&actual_digest);
    if (!std.mem.eql(u8, &actual_digest, &expectation.expected_digest)) {
        return error.SnapshotDigestMismatch;
    }

    return .{
        .allocator = allocator,
        .bytes = owned,
    };
}

const SyntheticSnapshotReader = struct {
    input: []const u8,
    offset: usize = 0,
    chunk_size: usize = std.math.maxInt(usize),
    call_count: usize = 0,
    zero_progress_on_call: ?usize = null,
    fail_on_call: ?usize = null,

    fn readNext(
        raw_context: *anyopaque,
        destination: []u8,
    ) anyerror!SnapshotReadNextResult {
        const self: *SyntheticSnapshotReader = @ptrCast(@alignCast(raw_context));
        const call_index = self.call_count;
        self.call_count += 1;
        if (self.fail_on_call) |failure_index| {
            if (failure_index == call_index) return error.SyntheticSnapshotReadFailure;
        }
        if (self.zero_progress_on_call) |zero_index| {
            if (zero_index == call_index) return .{ .bytes = 0 };
        }
        if (self.offset == self.input.len) return .eof;

        const remaining = self.input.len - self.offset;
        const count = @min(destination.len, @min(self.chunk_size, remaining));
        @memcpy(destination[0..count], self.input[self.offset..][0..count]);
        self.offset += count;
        return .{ .bytes = count };
    }
};

const RecursiveSnapshotReader = struct {
    delegate: *SyntheticSnapshotReader,
    allocator: std.mem.Allocator,
    expectation: SnapshotExpectation,
    token: *SnapshotToken,
    recursive_error: ?anyerror = null,

    fn readNext(
        raw_context: *anyopaque,
        destination: []u8,
    ) anyerror!SnapshotReadNextResult {
        const self: *RecursiveSnapshotReader = @ptrCast(@alignCast(raw_context));
        if (self.recursive_error == null) {
            if (acquireVerifiedSnapshot(
                self.allocator,
                self.expectation,
                self.token,
                self.delegate,
                SyntheticSnapshotReader.readNext,
            )) |value| {
                var unexpected = value;
                unexpected.deinit();
                return error.SyntheticRecursiveCallUnexpectedlySucceeded;
            } else |actual_error| {
                self.recursive_error = actual_error;
            }
        }
        return SyntheticSnapshotReader.readNext(self.delegate, destination);
    }
};

const BlockingSnapshotReader = struct {
    delegate: SyntheticSnapshotReader,
    entered: *std.atomic.Value(bool),
    release: *std.atomic.Value(bool),
    callback_calls: *std.atomic.Value(usize),
    blocked_once: bool = false,

    fn readNext(
        raw_context: *anyopaque,
        destination: []u8,
    ) anyerror!SnapshotReadNextResult {
        const self: *BlockingSnapshotReader = @ptrCast(@alignCast(raw_context));
        _ = self.callback_calls.fetchAdd(1, .acq_rel);
        if (!self.blocked_once) {
            self.blocked_once = true;
            self.entered.store(true, .release);
            while (!self.release.load(.acquire)) std.atomic.spinLoopHint();
        }
        return SyntheticSnapshotReader.readNext(&self.delegate, destination);
    }
};

const CountingSnapshotReader = struct {
    delegate: SyntheticSnapshotReader,
    callback_calls: *std.atomic.Value(usize),

    fn readNext(
        raw_context: *anyopaque,
        destination: []u8,
    ) anyerror!SnapshotReadNextResult {
        const self: *CountingSnapshotReader = @ptrCast(@alignCast(raw_context));
        _ = self.callback_calls.fetchAdd(1, .acq_rel);
        return SyntheticSnapshotReader.readNext(&self.delegate, destination);
    }
};

const ClaimantThreadContext = struct {
    allocator: std.mem.Allocator,
    expectation: SnapshotExpectation,
    token: *SnapshotToken,
    reader: *BlockingSnapshotReader,
    snapshot: ?VerifiedSnapshot = null,
    failure: ?anyerror = null,

    fn run(self: *ClaimantThreadContext) void {
        self.snapshot = acquireVerifiedSnapshot(
            self.allocator,
            self.expectation,
            self.token,
            self.reader,
            BlockingSnapshotReader.readNext,
        ) catch |actual_error| {
            self.failure = actual_error;
            return;
        };
    }
};

fn fillSyntheticSnapshot(bytes: []u8) void {
    for (bytes, 0..) |*byte, index| {
        byte.* = @intCast((index * 131 + 17) % 251);
    }
}

fn syntheticExpectation(bytes: []const u8, supplied_maximum: u64) SnapshotExpectation {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return .{
        .exact_length = @intCast(bytes.len),
        .supplied_maximum = supplied_maximum,
        .expected_digest = digest,
    };
}

const SealedDescriptorError = error{
    SealedDescriptorCapabilityUnavailable,
    SealedDescriptorBadDescriptor,
    SealedDescriptorInvalidOrUnsupported,
    SealedDescriptorAbiViolation,
    SealedDescriptorPermissionDenied,
    SealedDescriptorSharedWritableMapping,
    SealedDescriptorSystemResources,
    SealedDescriptorOperationFailed,
    SealedDescriptorRoleMismatch,
    SealedDescriptorRequiredSealsMissing,
    SealedDescriptorSizeMismatch,
    SealedDescriptorPositionalIoFailed,
    SealedDescriptorPositionalIoZeroProgress,
    SealedDescriptorPositionalIoOverflow,
    SealedDescriptorOwnershipUnavailable,
};

const SealedReceiverCounters = struct {
    size_observations: usize = 0,
    callback_calls: usize = 0,
};

const OwnedSyntheticSealedDescriptor = struct {
    descriptor: std.posix.fd_t,
    close_count: *usize,
    owned: bool = true,

    fn close(self: *OwnedSyntheticSealedDescriptor) void {
        if (!self.owned) return;
        _ = linux.close(self.descriptor);
        self.owned = false;
        self.close_count.* += 1;
    }

    fn move(self: *OwnedSyntheticSealedDescriptor) SealedDescriptorError!OwnedSyntheticSealedDescriptor {
        if (!self.owned) return error.SealedDescriptorOwnershipUnavailable;
        const moved = OwnedSyntheticSealedDescriptor{
            .descriptor = self.descriptor,
            .close_count = self.close_count,
        };
        self.owned = false;
        return moved;
    }
};

const PositionalSealedReader = struct {
    descriptor: std.posix.fd_t,
    offset: u64 = 0,
    counters: *SealedReceiverCounters,

    fn readNext(
        raw_context: *anyopaque,
        destination: []u8,
    ) anyerror!SnapshotReadNextResult {
        const self: *PositionalSealedReader = @ptrCast(@alignCast(raw_context));
        self.counters.callback_calls += 1;
        if (destination.len == 0) return error.SealedDescriptorPositionalIoFailed;
        const offset = std.math.cast(i64, self.offset) orelse
            return error.SealedDescriptorPositionalIoOverflow;
        const raw_result = linux.pread(
            self.descriptor,
            destination.ptr,
            destination.len,
            offset,
        );
        try requireSealedSyscall(linux.errno(raw_result));
        const count = raw_result;
        if (count == 0) return .eof;
        if (count > destination.len) return error.SealedDescriptorPositionalIoFailed;
        const next = @addWithOverflow(self.offset, @as(u64, @intCast(count)));
        if (next[1] != 0) return error.SealedDescriptorPositionalIoOverflow;
        self.offset = next[0];
        return .{ .bytes = count };
    }
};

fn requiredSealedDescriptorMask() usize {
    // F_SEAL_SEAL is optional protocol closure, not event-freedom. Seals are
    // already irreversible, so this private proof requires only these bits.
    return linux.F.SEAL_WRITE | linux.F.SEAL_GROW | linux.F.SEAL_SHRINK;
}

fn requireSealedSyscall(errno_value: linux.E) SealedDescriptorError!void {
    switch (errno_value) {
        .SUCCESS => return,
        .NOSYS => return error.SealedDescriptorCapabilityUnavailable,
        .BADF => return error.SealedDescriptorBadDescriptor,
        .INVAL => return error.SealedDescriptorInvalidOrUnsupported,
        .FAULT => return error.SealedDescriptorAbiViolation,
        .PERM, .ACCES => return error.SealedDescriptorPermissionDenied,
        .BUSY => return error.SealedDescriptorSharedWritableMapping,
        .MFILE, .NFILE, .NOMEM => return error.SealedDescriptorSystemResources,
        else => return error.SealedDescriptorOperationFailed,
    }
}

fn positionalWriteAll(
    descriptor: std.posix.fd_t,
    bytes: []const u8,
) SealedDescriptorError!void {
    if (bytes.len == 0) return error.SealedDescriptorSizeMismatch;
    const total_length = std.math.cast(u64, bytes.len) orelse
        return error.SealedDescriptorPositionalIoOverflow;
    var offset: u64 = 0;
    while (offset < total_length) {
        const offset_usize = std.math.cast(usize, offset) orelse
            return error.SealedDescriptorPositionalIoOverflow;
        const offset_i64 = std.math.cast(i64, offset) orelse
            return error.SealedDescriptorPositionalIoOverflow;
        const remaining = bytes[offset_usize..];
        const raw_result = linux.pwrite(
            descriptor,
            remaining.ptr,
            remaining.len,
            offset_i64,
        );
        try requireSealedSyscall(linux.errno(raw_result));
        const count = raw_result;
        if (count == 0) return error.SealedDescriptorPositionalIoZeroProgress;
        if (count > remaining.len) return error.SealedDescriptorPositionalIoFailed;
        const next = @addWithOverflow(offset, @as(u64, @intCast(count)));
        if (next[1] != 0) return error.SealedDescriptorPositionalIoOverflow;
        offset = next[0];
    }
}

fn getSealedDescriptorMask(descriptor: std.posix.fd_t) SealedDescriptorError!usize {
    const raw_result = linux.fcntl(descriptor, linux.F.GET_SEALS, 0);
    try requireSealedSyscall(linux.errno(raw_result));
    return raw_result;
}

fn requireRegularSealedDescriptorRole(descriptor: std.posix.fd_t) SealedDescriptorError!void {
    var requested = std.mem.zeroes(linux.STATX);
    requested.TYPE = true;
    var result = std.mem.zeroes(linux.Statx);
    const raw_result = linux.statx(
        descriptor,
        "",
        linux.AT.EMPTY_PATH | linux.AT.STATX_SYNC_AS_STAT,
        requested,
        &result,
    );
    try requireSealedSyscall(linux.errno(raw_result));
    if (!result.mask.TYPE) return error.SealedDescriptorInvalidOrUnsupported;
    if (result.mode & linux.S.IFMT != linux.S.IFREG) {
        return error.SealedDescriptorRoleMismatch;
    }
}

fn requireFullSealedDescriptorMask(descriptor: std.posix.fd_t) SealedDescriptorError!void {
    const actual = try getSealedDescriptorMask(descriptor);
    const required = requiredSealedDescriptorMask();
    if (actual & required != required) {
        return error.SealedDescriptorRequiredSealsMissing;
    }
}

fn observeSealedDescriptorSize(
    descriptor: std.posix.fd_t,
    counters: *SealedReceiverCounters,
) SealedDescriptorError!u64 {
    counters.size_observations += 1;
    var requested = std.mem.zeroes(linux.STATX);
    requested.SIZE = true;
    var result = std.mem.zeroes(linux.Statx);
    const raw_result = linux.statx(
        descriptor,
        "",
        linux.AT.EMPTY_PATH | linux.AT.STATX_SYNC_AS_STAT,
        requested,
        &result,
    );
    try requireSealedSyscall(linux.errno(raw_result));
    if (!result.mask.SIZE) return error.SealedDescriptorInvalidOrUnsupported;
    return result.size;
}

/// Constructs private synthetic fixtures. The accepted path requests the
/// complete required mask; intentionally incomplete masks exist only to prove
/// that the receiver rejects them before size observation or snapshot entry.
fn createSyntheticSealedFixture(
    bytes: []const u8,
    seals: usize,
    close_count: *usize,
) SealedDescriptorError!OwnedSyntheticSealedDescriptor {
    const flags: u32 = linux.MFD.CLOEXEC | linux.MFD.ALLOW_SEALING;
    const raw_descriptor = linux.memfd_create("zllvm-inbox206ck", flags);
    try requireSealedSyscall(linux.errno(raw_descriptor));
    var owned = OwnedSyntheticSealedDescriptor{
        .descriptor = @intCast(raw_descriptor),
        .close_count = close_count,
    };
    errdefer owned.close();

    try positionalWriteAll(owned.descriptor, bytes);
    const raw_add = linux.fcntl(owned.descriptor, linux.F.ADD_SEALS, seals);
    try requireSealedSyscall(linux.errno(raw_add));
    const observed = try getSealedDescriptorMask(owned.descriptor);
    if (observed & seals != seals) {
        return error.SealedDescriptorRequiredSealsMissing;
    }
    return owned;
}

fn createSyntheticFullySealedDescriptor(
    bytes: []const u8,
    close_count: *usize,
) SealedDescriptorError!OwnedSyntheticSealedDescriptor {
    return createSyntheticSealedFixture(bytes, requiredSealedDescriptorMask(), close_count);
}

/// Moves creator ownership exactly once. The receiver closes the transferred
/// descriptor on every exit, while the returned snapshot has its own lifetime.
fn acquireVerifiedSealedSnapshot(
    allocator: std.mem.Allocator,
    expectation: SnapshotExpectation,
    token: *SnapshotToken,
    creator_owned: *OwnedSyntheticSealedDescriptor,
    counters: *SealedReceiverCounters,
) (SealedDescriptorError || SnapshotError || std.mem.Allocator.Error)!VerifiedSnapshot {
    var receiver_owned = try creator_owned.move();
    defer receiver_owned.close();

    try requireRegularSealedDescriptorRole(receiver_owned.descriptor);
    try requireFullSealedDescriptorMask(receiver_owned.descriptor);
    const actual_size = try observeSealedDescriptorSize(receiver_owned.descriptor, counters);
    if (actual_size != expectation.exact_length) {
        return error.SealedDescriptorSizeMismatch;
    }

    var reader = PositionalSealedReader{
        .descriptor = receiver_owned.descriptor,
        .counters = counters,
    };
    return acquireVerifiedSnapshot(
        allocator,
        expectation,
        token,
        &reader,
        PositionalSealedReader.readNext,
    );
}

fn expectSealedMaskRejection(seals: usize) !void {
    var bytes: [37]u8 = undefined;
    fillSyntheticSnapshot(&bytes);
    const expectation = syntheticExpectation(&bytes, bytes.len);
    var close_count: usize = 0;
    var creator_owned = try createSyntheticSealedFixture(&bytes, seals, &close_count);
    defer creator_owned.close();
    const saved_descriptor = creator_owned.descriptor;
    var token = SnapshotToken{};
    var counters = SealedReceiverCounters{};
    var no_storage: [0]u8 = .{};
    var allocation_must_not_run = std.heap.FixedBufferAllocator.init(&no_storage);

    try std.testing.expectError(
        error.SealedDescriptorRequiredSealsMissing,
        acquireVerifiedSealedSnapshot(
            allocation_must_not_run.allocator(),
            expectation,
            &token,
            &creator_owned,
            &counters,
        ),
    );
    try std.testing.expect(!creator_owned.owned);
    try std.testing.expectEqual(@as(usize, 1), close_count);
    try std.testing.expectEqual(@as(usize, 0), counters.size_observations);
    try std.testing.expectEqual(@as(usize, 0), counters.callback_calls);
    try std.testing.expectEqual(SnapshotTokenState.unused, token.state.load(.acquire));
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(saved_descriptor, .regular_file),
    );
}

test "compile-time ABI and essential mask closure" {
    comptime assertNativeAbi();
    const mask_bits: u32 = @bitCast(requiredMask());
    try std.testing.expectEqual(@as(u32, 0x47ff), mask_bits);
}

test "required mask accepts extras and rejects every essential omission" {
    const MaskInt = std.meta.Int(.unsigned, @bitSizeOf(linux.STATX));
    const exact = requiredMask();
    const required_mask: MaskInt = @bitCast(exact);
    try requireMask(exact);

    const frozen_non_required_bit: MaskInt = @as(MaskInt, 1) << @bitOffsetOf(linux.STATX, "BTIME");
    try std.testing.expectEqual(@as(MaskInt, 0), required_mask & frozen_non_required_bit);
    const with_extra: linux.STATX = @bitCast(required_mask | frozen_non_required_bit);
    try requireMask(with_extra);

    var omission_count: usize = 0;
    var bit_index: usize = 0;
    while (bit_index < @bitSizeOf(MaskInt)) : (bit_index += 1) {
        const bit: MaskInt = @as(MaskInt, 1) << @intCast(bit_index);
        if (required_mask & bit == 0) continue;
        const missing_mask: linux.STATX = @bitCast(required_mask & ~bit);
        try std.testing.expectError(
            error.DescriptorIdentityMaskIncomplete,
            requireMask(missing_mask),
        );
        omission_count += 1;
    }
    const required_count: usize = @popCount(required_mask);
    try std.testing.expectEqual(required_count, omission_count);
}

test "errno mapping preserves fail-closed attribution and E.INVAL precedence" {
    try requireSuccessfulErrno(.SUCCESS);
    try std.testing.expectError(
        error.DescriptorIdentityCapabilityUnavailable,
        requireSuccessfulErrno(.NOSYS),
    );
    try std.testing.expectError(
        error.DescriptorIdentityInvalidOrUnsupported,
        requireSuccessfulErrno(.INVAL),
    );
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        requireSuccessfulErrno(.BADF),
    );
    try std.testing.expectError(
        error.DescriptorIdentityAbiViolation,
        requireSuccessfulErrno(.FAULT),
    );
    try std.testing.expectError(
        error.DescriptorIdentityPermissionDenied,
        requireSuccessfulErrno(.ACCES),
    );
    try std.testing.expectError(
        error.DescriptorIdentityPathAcquisitionInconsistent,
        requireSuccessfulErrno(.NOENT),
    );
    try std.testing.expectError(
        error.DescriptorIdentityObservationFailed,
        requireSuccessfulErrno(.IO),
    );
}

test "held directory and regular-file descriptors have stable role-bound identities" {
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();

    const directory_first = try observeDescriptor(temp.dir.handle, .directory);
    const directory_second = try observeDescriptor(temp.dir.handle, .directory);
    try std.testing.expect(std.meta.eql(directory_first, directory_second));
    try std.testing.expectError(
        error.DescriptorIdentityRoleMismatch,
        observeDescriptor(temp.dir.handle, .regular_file),
    );

    const file = try temp.dir.createFile(io, "identity", .{
        .read = true,
        .exclusive = true,
    });
    defer file.close(io);
    const file_first = try observeDescriptor(file.handle, .regular_file);
    const file_second = try observeDescriptor(file.handle, .regular_file);
    try std.testing.expect(std.meta.eql(file_first, file_second));
    try std.testing.expectError(
        error.DescriptorIdentityRoleMismatch,
        observeDescriptor(file.handle, .directory),
    );
}

test "closed descriptor fails and MNT_ID_UNIQUE is never skipped" {
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();

    // This live observation deliberately propagates mask failure. A runtime
    // without MNT_ID_UNIQUE support fails the focused suite instead of skipping.
    _ = try observeDescriptor(temp.dir.handle, .directory);

    const file = try temp.dir.createFile(io, "closed", .{
        .read = true,
        .exclusive = true,
    });
    const closed_descriptor = file.handle;
    file.close(io);
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(closed_descriptor, .regular_file),
    );
}

test "single-component validation rejects lexical and mismatch errors before access" {
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();

    try temp.dir.createDir(io, "closed-parent", .default_dir);
    const closed_parent = try temp.dir.openDir(io, "closed-parent", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    closed_parent.close(io);

    const invalid_components = [_][]const u8{
        "",
        ".",
        "..",
        "two/parts",
        "nul\x00byte",
    };
    for (invalid_components) |invalid| {
        try expectAcquisitionError(
            error.ComponentLexicallyInvalid,
            closed_parent,
            io,
            invalid,
            "valid",
        );
        try expectAcquisitionError(
            error.ComponentLexicallyInvalid,
            closed_parent,
            io,
            "valid",
            invalid,
        );
    }
    try expectAcquisitionError(
        error.ComponentNameMismatch,
        closed_parent,
        io,
        "candidate",
        "expected",
    );
}

test "single-component directory acquisition preserves parent and child ownership" {
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();

    try temp.dir.createDir(io, "nested", .default_dir);
    const parent_before = try observeDescriptor(temp.dir.handle, .directory);
    const acquired = try acquireOneDirectoryComponent(
        temp.dir,
        io,
        "nested",
        "nested",
    );
    const parent_during = try observeDescriptor(temp.dir.handle, .directory);
    try std.testing.expect(std.meta.eql(parent_before, parent_during));
    const child_repeated = try observeDescriptor(acquired.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(acquired.identity, child_repeated));

    const child_handle = acquired.directory.handle;
    acquired.directory.close(io);
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(child_handle, .directory),
    );
    const parent_after = try observeDescriptor(temp.dir.handle, .directory);
    try std.testing.expect(std.meta.eql(parent_before, parent_after));
}

test "single-component directory acquisition rejects regular files and symlinks" {
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();

    const file = try temp.dir.createFile(io, "regular", .{
        .read = true,
        .exclusive = true,
    });
    defer file.close(io);
    try expectAcquisitionError(
        error.NotDir,
        temp.dir,
        io,
        "regular",
        "regular",
    );

    try temp.dir.createDir(io, "target", .default_dir);
    try temp.dir.symLink(io, "target", "link", .{ .is_directory = true });
    try expectAcquisitionError(
        error.NotDir,
        temp.dir,
        io,
        "link",
        "link",
    );
}

test "trusted current mount namespace root identity and caller ownership" {
    const io = std.testing.io;
    const first = try acquireTrustedRoot(io);
    var first_open = true;
    defer {
        if (first_open) first.directory.close(io);
    }
    const second = try acquireTrustedRoot(io);
    var second_open = true;
    defer {
        if (second_open) second.directory.close(io);
    }

    try std.testing.expect(std.meta.eql(first.identity, second.identity));
    const first_stable = try observeDescriptor(first.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(first.identity, first_stable));
    const second_stable = try observeDescriptor(second.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(second.identity, second_stable));

    const first_handle = first.directory.handle;
    first.directory.close(io);
    first_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(first_handle, .directory),
    );

    const second_after_first_close = try observeDescriptor(second.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(second.identity, second_after_first_close));
    second.directory.close(io);
    second_open = false;
}

test "trusted root-to-home chain identity and caller close order" {
    const io = std.testing.io;
    const chain = try acquireTrustedHomeChain(io);
    var root_open = true;
    defer {
        if (root_open) chain.root.directory.close(io);
    }
    var home_open = true;
    defer {
        if (home_open) chain.home.directory.close(io);
    }

    const root_stable = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_stable));
    const home_stable = try observeDescriptor(chain.home.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.home.identity, home_stable));

    const home_handle = chain.home.directory.handle;
    chain.home.directory.close(io);
    home_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(home_handle, .directory),
    );

    const root_after_home_close = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_after_home_close));
    const root_handle = chain.root.directory.handle;
    chain.root.directory.close(io);
    root_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(root_handle, .directory),
    );
}

test "trusted root-to-home-to-oleg chain identity and caller close order" {
    const io = std.testing.io;
    const chain = try acquireTrustedOlegChain(io);
    var root_open = true;
    defer {
        if (root_open) chain.root.directory.close(io);
    }
    var home_open = true;
    defer {
        if (home_open) chain.home.directory.close(io);
    }
    var oleg_open = true;
    defer {
        if (oleg_open) chain.oleg.directory.close(io);
    }

    const root_stable = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_stable));
    const home_stable = try observeDescriptor(chain.home.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.home.identity, home_stable));
    const oleg_stable = try observeDescriptor(chain.oleg.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.oleg.identity, oleg_stable));

    const oleg_handle = chain.oleg.directory.handle;
    chain.oleg.directory.close(io);
    oleg_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(oleg_handle, .directory),
    );

    const home_after_oleg_close = try observeDescriptor(chain.home.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.home.identity, home_after_oleg_close));
    const root_after_oleg_close = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_after_oleg_close));

    const home_handle = chain.home.directory.handle;
    chain.home.directory.close(io);
    home_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(home_handle, .directory),
    );

    const root_after_home_close = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_after_home_close));
    const root_handle = chain.root.directory.handle;
    chain.root.directory.close(io);
    root_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(root_handle, .directory),
    );
}

test "trusted root-to-home-to-oleg-to-prog chain identity and caller close order" {
    const io = std.testing.io;
    const chain = try acquireTrustedProgChain(io);
    var root_open = true;
    defer {
        if (root_open) chain.root.directory.close(io);
    }
    var home_open = true;
    defer {
        if (home_open) chain.home.directory.close(io);
    }
    var oleg_open = true;
    defer {
        if (oleg_open) chain.oleg.directory.close(io);
    }
    var prog_open = true;
    defer {
        if (prog_open) chain.prog.directory.close(io);
    }

    const root_stable = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_stable));
    const home_stable = try observeDescriptor(chain.home.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.home.identity, home_stable));
    const oleg_stable = try observeDescriptor(chain.oleg.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.oleg.identity, oleg_stable));
    const prog_stable = try observeDescriptor(chain.prog.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.prog.identity, prog_stable));

    const prog_handle = chain.prog.directory.handle;
    chain.prog.directory.close(io);
    prog_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(prog_handle, .directory),
    );

    const oleg_after_prog_close = try observeDescriptor(chain.oleg.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.oleg.identity, oleg_after_prog_close));
    const home_after_prog_close = try observeDescriptor(chain.home.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.home.identity, home_after_prog_close));
    const root_after_prog_close = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_after_prog_close));

    const oleg_handle = chain.oleg.directory.handle;
    chain.oleg.directory.close(io);
    oleg_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(oleg_handle, .directory),
    );

    const home_after_oleg_close = try observeDescriptor(chain.home.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.home.identity, home_after_oleg_close));
    const root_after_oleg_close = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_after_oleg_close));

    const home_handle = chain.home.directory.handle;
    chain.home.directory.close(io);
    home_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(home_handle, .directory),
    );

    const root_after_home_close = try observeDescriptor(chain.root.directory.handle, .directory);
    try std.testing.expect(std.meta.eql(chain.root.identity, root_after_home_close));
    const root_handle = chain.root.directory.handle;
    chain.root.directory.close(io);
    root_open = false;
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(root_handle, .directory),
    );
}

test "verified snapshot accepts exact generated bytes and admits only verified observation" {
    const synthetic_length = 29_834;
    var input: [synthetic_length]u8 = undefined;
    fillSyntheticSnapshot(&input);
    const expectation = syntheticExpectation(&input, synthetic_length);
    var token = SnapshotToken{};
    const chunk_size = 4093;
    var reader = SyntheticSnapshotReader{
        .input = &input,
        .chunk_size = chunk_size,
    };

    var snapshot = try acquireVerifiedSnapshot(
        std.testing.allocator,
        expectation,
        &token,
        &reader,
        SyntheticSnapshotReader.readNext,
    );
    defer snapshot.deinit();

    const observed = observeVerifiedSnapshot(&snapshot);
    try std.testing.expectEqualSlices(u8, &input, observed);
    try std.testing.expectEqual(SnapshotTokenState.consumed, token.state.load(.acquire));
    const data_call_count = (synthetic_length + chunk_size - 1) / chunk_size;
    try std.testing.expectEqual(data_call_count + 1, reader.call_count);
}

test "verified snapshot rejects invalid exact maximum and ceiling sizes before reading" {
    const empty = [_]u8{};
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(&empty, &digest, .{});

    const cases = [_]struct {
        expectation: SnapshotExpectation,
        expected_error: anyerror,
    }{
        .{
            .expectation = .{
                .exact_length = 0,
                .supplied_maximum = 0,
                .expected_digest = digest,
            },
            .expected_error = error.SnapshotLengthInvalid,
        },
        .{
            .expectation = .{
                .exact_length = 2,
                .supplied_maximum = 1,
                .expected_digest = digest,
            },
            .expected_error = error.SnapshotMaximumTooSmall,
        },
        .{
            .expectation = .{
                .exact_length = snapshot_internal_ceiling + 1,
                .supplied_maximum = snapshot_internal_ceiling + 1,
                .expected_digest = digest,
            },
            .expected_error = error.SnapshotInternalCeilingExceeded,
        },
    };

    for (cases) |case| {
        var token = SnapshotToken{};
        var reader = SyntheticSnapshotReader{ .input = &empty };
        try std.testing.expectError(
            case.expected_error,
            acquireVerifiedSnapshot(
                std.testing.allocator,
                case.expectation,
                &token,
                &reader,
                SyntheticSnapshotReader.readNext,
            ),
        );
        try std.testing.expectEqual(SnapshotTokenState.consumed, token.state.load(.acquire));
        try std.testing.expectEqual(@as(usize, 0), reader.call_count);
    }
}

test "verified snapshot rejects boundary partial and trailing supplies" {
    const expected = [_]u8{ 3, 5, 8, 13 };
    const expectation = syntheticExpectation(&expected, expected.len);
    const partial_inputs = [_][]const u8{
        &[_]u8{},
        expected[0 .. expected.len - 1],
    };
    for (partial_inputs) |partial| {
        var token = SnapshotToken{};
        var reader = SyntheticSnapshotReader{ .input = partial };
        try std.testing.expectError(
            error.SnapshotPartial,
            acquireVerifiedSnapshot(
                std.testing.allocator,
                expectation,
                &token,
                &reader,
                SyntheticSnapshotReader.readNext,
            ),
        );
    }

    const trailing_inputs = [_][]const u8{
        &[_]u8{ 3, 5, 8, 13, 21 },
        &[_]u8{ 3, 5, 8, 13, 21, 34 },
    };
    for (trailing_inputs) |trailing| {
        var token = SnapshotToken{};
        var reader = SyntheticSnapshotReader{ .input = trailing };
        try std.testing.expectError(
            error.SnapshotTrailing,
            acquireVerifiedSnapshot(
                std.testing.allocator,
                expectation,
                &token,
                &reader,
                SyntheticSnapshotReader.readNext,
            ),
        );
        try std.testing.expectEqual(@as(usize, 2), reader.call_count);
    }
}

test "verified snapshot closes zero-progress and callback failure" {
    const input = [_]u8{ 1, 2, 3 };
    const expectation = syntheticExpectation(&input, input.len);

    var zero_token = SnapshotToken{};
    var zero_reader = SyntheticSnapshotReader{
        .input = &input,
        .zero_progress_on_call = 0,
    };
    try std.testing.expectError(
        error.SnapshotZeroProgress,
        acquireVerifiedSnapshot(
            std.testing.allocator,
            expectation,
            &zero_token,
            &zero_reader,
            SyntheticSnapshotReader.readNext,
        ),
    );

    var failure_token = SnapshotToken{};
    var failure_reader = SyntheticSnapshotReader{
        .input = &input,
        .fail_on_call = 0,
    };
    try std.testing.expectError(
        error.SnapshotReadFailed,
        acquireVerifiedSnapshot(
            std.testing.allocator,
            expectation,
            &failure_token,
            &failure_reader,
            SyntheticSnapshotReader.readNext,
        ),
    );
}

test "verified snapshot rejects first middle and last digest mutations" {
    const synthetic_length = 29_834;
    var original: [synthetic_length]u8 = undefined;
    fillSyntheticSnapshot(&original);
    const expectation = syntheticExpectation(&original, synthetic_length);
    const mutation_positions = [_]usize{ 0, synthetic_length / 2, synthetic_length - 1 };

    for (mutation_positions) |position| {
        var mutated = original;
        mutated[position] ^= 1;
        var token = SnapshotToken{};
        var reader = SyntheticSnapshotReader{ .input = &mutated };
        try std.testing.expectError(
            error.SnapshotDigestMismatch,
            acquireVerifiedSnapshot(
                std.testing.allocator,
                expectation,
                &token,
                &reader,
                SyntheticSnapshotReader.readNext,
            ),
        );
    }
}

test "verified snapshot rejects recursive initially-in-progress second and retry use" {
    const input = [_]u8{ 2, 7, 1, 8 };
    const expectation = syntheticExpectation(&input, input.len);

    var recursive_token = SnapshotToken{};
    var delegate = SyntheticSnapshotReader{ .input = &input };
    var recursive_reader = RecursiveSnapshotReader{
        .delegate = &delegate,
        .allocator = std.testing.allocator,
        .expectation = expectation,
        .token = &recursive_token,
    };
    var recursive_snapshot = try acquireVerifiedSnapshot(
        std.testing.allocator,
        expectation,
        &recursive_token,
        &recursive_reader,
        RecursiveSnapshotReader.readNext,
    );
    defer recursive_snapshot.deinit();
    try std.testing.expect(recursive_reader.recursive_error.? == error.SnapshotTokenUnavailable);

    var concurrent_token = SnapshotToken{
        .state = std.atomic.Value(SnapshotTokenState).init(.in_progress),
    };
    var concurrent_reader = SyntheticSnapshotReader{ .input = &input };
    try std.testing.expectError(
        error.SnapshotTokenUnavailable,
        acquireVerifiedSnapshot(
            std.testing.allocator,
            expectation,
            &concurrent_token,
            &concurrent_reader,
            SyntheticSnapshotReader.readNext,
        ),
    );

    var second_reader = SyntheticSnapshotReader{ .input = &input };
    try std.testing.expectError(
        error.SnapshotTokenUnavailable,
        acquireVerifiedSnapshot(
            std.testing.allocator,
            expectation,
            &recursive_token,
            &second_reader,
            SyntheticSnapshotReader.readNext,
        ),
    );

    var retry_token = SnapshotToken{};
    var failing_reader = SyntheticSnapshotReader{
        .input = &input,
        .fail_on_call = 0,
    };
    try std.testing.expectError(
        error.SnapshotReadFailed,
        acquireVerifiedSnapshot(
            std.testing.allocator,
            expectation,
            &retry_token,
            &failing_reader,
            SyntheticSnapshotReader.readNext,
        ),
    );
    var retry_reader = SyntheticSnapshotReader{ .input = &input };
    try std.testing.expectError(
        error.SnapshotTokenUnavailable,
        acquireVerifiedSnapshot(
            std.testing.allocator,
            expectation,
            &retry_token,
            &retry_reader,
            SyntheticSnapshotReader.readNext,
        ),
    );
}

test "verified snapshot preserves allocation cleanup ownership and post-return bytes" {
    const input = [_]u8{ 4, 2 };
    const expectation = syntheticExpectation(&input, input.len);

    var no_storage: [0]u8 = .{};
    var fixed = std.heap.FixedBufferAllocator.init(&no_storage);
    var allocation_token = SnapshotToken{};
    var allocation_reader = SyntheticSnapshotReader{ .input = &input };
    try std.testing.expectError(
        error.OutOfMemory,
        acquireVerifiedSnapshot(
            fixed.allocator(),
            expectation,
            &allocation_token,
            &allocation_reader,
            SyntheticSnapshotReader.readNext,
        ),
    );
    try std.testing.expectEqual(
        SnapshotTokenState.consumed,
        allocation_token.state.load(.acquire),
    );
    try std.testing.expectEqual(@as(usize, 0), allocation_reader.call_count);

    var mutable_input = input;
    var ownership_token = SnapshotToken{};
    var ownership_reader = SyntheticSnapshotReader{ .input = &mutable_input };
    var snapshot = try acquireVerifiedSnapshot(
        std.testing.allocator,
        expectation,
        &ownership_token,
        &ownership_reader,
        SyntheticSnapshotReader.readNext,
    );
    defer snapshot.deinit();
    const saved_first = observeVerifiedSnapshot(&snapshot)[0];
    mutable_input[0] ^= 0xff;
    try std.testing.expectEqual(saved_first, observeVerifiedSnapshot(&snapshot)[0]);
    try std.testing.expectEqualSlices(u8, &input, observeVerifiedSnapshot(&snapshot));
}

test "verified snapshot atomically admits one of two actual concurrent callers" {
    const input = [_]u8{ 6, 2, 6, 4 };
    const expectation = syntheticExpectation(&input, input.len);
    var token = SnapshotToken{};
    var claimant_entered = std.atomic.Value(bool).init(false);
    var claimant_release = std.atomic.Value(bool).init(false);
    var claimant_callback_calls = std.atomic.Value(usize).init(0);
    var claimant_reader = BlockingSnapshotReader{
        .delegate = .{ .input = &input },
        .entered = &claimant_entered,
        .release = &claimant_release,
        .callback_calls = &claimant_callback_calls,
    };
    var claimant_context = ClaimantThreadContext{
        .allocator = std.testing.allocator,
        .expectation = expectation,
        .token = &token,
        .reader = &claimant_reader,
    };
    const claimant_thread = try std.Thread.spawn(
        .{},
        ClaimantThreadContext.run,
        .{&claimant_context},
    );
    var claimant_joined = false;
    defer {
        claimant_release.store(true, .release);
        if (!claimant_joined) claimant_thread.join();
        if (claimant_context.snapshot) |*snapshot| snapshot.deinit();
    }

    while (!claimant_entered.load(.acquire)) std.atomic.spinLoopHint();
    try std.testing.expectEqual(
        SnapshotTokenState.in_progress,
        token.state.load(.acquire),
    );

    var no_storage: [0]u8 = .{};
    var first_allocation_fails = std.heap.FixedBufferAllocator.init(&no_storage);
    var loser_callback_calls = std.atomic.Value(usize).init(0);
    var loser_reader = CountingSnapshotReader{
        .delegate = .{ .input = &input },
        .callback_calls = &loser_callback_calls,
    };
    try std.testing.expectError(
        error.SnapshotTokenUnavailable,
        acquireVerifiedSnapshot(
            first_allocation_fails.allocator(),
            expectation,
            &token,
            &loser_reader,
            CountingSnapshotReader.readNext,
        ),
    );
    try std.testing.expectEqual(
        @as(usize, 0),
        loser_callback_calls.load(.acquire),
    );
    try std.testing.expectEqual(
        SnapshotTokenState.in_progress,
        token.state.load(.acquire),
    );

    claimant_release.store(true, .release);
    claimant_thread.join();
    claimant_joined = true;

    try std.testing.expect(claimant_context.failure == null);
    try std.testing.expect(claimant_context.snapshot != null);
    var claimant_snapshot = claimant_context.snapshot.?;
    claimant_context.snapshot = null;
    defer claimant_snapshot.deinit();
    try std.testing.expectEqualSlices(
        u8,
        &input,
        observeVerifiedSnapshot(&claimant_snapshot),
    );
    try std.testing.expectEqual(
        @as(usize, 2),
        claimant_callback_calls.load(.acquire),
    );
    try std.testing.expectEqual(
        SnapshotTokenState.consumed,
        token.state.load(.acquire),
    );
}

test "sealed descriptor accepts the complete event-freedom mask" {
    var bytes: [257]u8 = undefined;
    fillSyntheticSnapshot(&bytes);
    const expectation = syntheticExpectation(&bytes, bytes.len);
    var close_count: usize = 0;
    var creator_owned = try createSyntheticFullySealedDescriptor(&bytes, &close_count);
    defer creator_owned.close();
    const saved_descriptor = creator_owned.descriptor;
    var token = SnapshotToken{};
    var counters = SealedReceiverCounters{};

    var snapshot = try acquireVerifiedSealedSnapshot(
        std.testing.allocator,
        expectation,
        &token,
        &creator_owned,
        &counters,
    );
    defer snapshot.deinit();

    try std.testing.expectEqualSlices(u8, &bytes, observeVerifiedSnapshot(&snapshot));
    try std.testing.expect(!creator_owned.owned);
    try std.testing.expectEqual(@as(usize, 1), close_count);
    try std.testing.expectEqual(@as(usize, 1), counters.size_observations);
    try std.testing.expectEqual(@as(usize, 2), counters.callback_calls);
    try std.testing.expectEqual(SnapshotTokenState.consumed, token.state.load(.acquire));
    try std.testing.expectError(
        error.DescriptorIdentityBadDescriptor,
        observeDescriptor(saved_descriptor, .regular_file),
    );

    var reuse_token = SnapshotToken{};
    var reuse_counters = SealedReceiverCounters{};
    var no_storage: [0]u8 = .{};
    var allocation_must_not_run = std.heap.FixedBufferAllocator.init(&no_storage);
    try std.testing.expectError(
        error.SealedDescriptorOwnershipUnavailable,
        acquireVerifiedSealedSnapshot(
            allocation_must_not_run.allocator(),
            expectation,
            &reuse_token,
            &creator_owned,
            &reuse_counters,
        ),
    );
    try std.testing.expectEqual(@as(usize, 1), close_count);
    try std.testing.expectEqual(@as(usize, 0), reuse_counters.size_observations);
    try std.testing.expectEqual(@as(usize, 0), reuse_counters.callback_calls);
    try std.testing.expectEqual(SnapshotTokenState.unused, reuse_token.state.load(.acquire));
}

test "sealed descriptor rejects future-write without required write" {
    try expectSealedMaskRejection(
        linux.F.SEAL_FUTURE_WRITE | linux.F.SEAL_GROW | linux.F.SEAL_SHRINK,
    );
}

test "sealed descriptor rejects missing grow before snapshot admission" {
    try expectSealedMaskRejection(linux.F.SEAL_WRITE | linux.F.SEAL_SHRINK);
}

test "sealed descriptor rejects missing shrink before snapshot admission" {
    try expectSealedMaskRejection(linux.F.SEAL_WRITE | linux.F.SEAL_GROW);
}
