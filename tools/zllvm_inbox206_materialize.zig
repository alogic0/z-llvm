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
