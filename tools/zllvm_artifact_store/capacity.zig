const std = @import("std");
const builtin = @import("builtin");

pub const CapacityObservation = struct {
    free_bytes: u64,
    free_inodes: u64,
};

pub const CapacityRequirement = struct {
    validation_reserve: u64,
    primary_bytes: u64,
    snapshot_bound: u64,
    manifest_bound: u64,
    compatibility_peak: u64 = 0,
    required_inodes: u64,

    pub fn requiredBytes(requirement: CapacityRequirement) !u64 {
        var total = try std.math.add(u64, requirement.validation_reserve, requirement.primary_bytes);
        total = try std.math.add(u64, total, requirement.snapshot_bound);
        total = try std.math.add(u64, total, requirement.manifest_bound);
        return std.math.add(u64, total, requirement.compatibility_peak);
    }

    pub fn validate(requirement: CapacityRequirement, observed: CapacityObservation) !void {
        if (observed.free_bytes < try requirement.requiredBytes()) return error.InsufficientFreeBytes;
        if (observed.free_inodes < requirement.required_inodes) return error.InsufficientFreeInodes;
    }
};

const LinuxStatFs = extern struct {
    fs_type: i64,
    block_size: i64,
    blocks: u64,
    blocks_free: u64,
    blocks_available: u64,
    files: u64,
    files_free: u64,
    fs_id: [2]i32,
    name_length: i64,
    fragment_size: i64,
    flags: i64,
    spare: [4]i64,
};

pub fn freshCapacity(dir: std.Io.Dir) !CapacityObservation {
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64) {
        @compileError("INBOX-193A descriptor capacity requires the pinned x86_64-linux host");
    }
    var info: LinuxStatFs = undefined;
    const rc = std.os.linux.syscall2(
        .fstatfs,
        @as(usize, @bitCast(@as(isize, dir.handle))),
        @intFromPtr(&info),
    );
    switch (std.os.linux.errno(rc)) {
        .SUCCESS => {},
        else => |err| return std.posix.unexpectedErrno(err),
    }
    const signed_unit = if (info.fragment_size > 0) info.fragment_size else info.block_size;
    if (signed_unit <= 0) return error.InvalidCapacityObservation;
    return capacityFromFields(info.blocks_available, @intCast(signed_unit), info.files_free);
}

fn capacityFromFields(
    available_blocks: u64,
    block_size: u64,
    free_inodes: u64,
) !CapacityObservation {
    if (block_size == 0) return error.InvalidCapacityObservation;
    return .{
        .free_bytes = try std.math.mul(u64, available_blocks, block_size),
        .free_inodes = free_inodes,
    };
}

test "capacity arithmetic counts each component once and fails closed" {
    const accepted: CapacityRequirement = .{
        .validation_reserve = 49_112_001_332,
        .primary_bytes = 3_112_270_055,
        .snapshot_bound = 6_230_928_384,
        .manifest_bound = 67_108_864,
        .required_inodes = 3_362,
    };
    try std.testing.expectEqual(@as(u64, 58_522_308_635), try accepted.requiredBytes());
    try accepted.validate(.{ .free_bytes = 58_522_308_635, .free_inodes = 3_362 });
    try std.testing.expectError(
        error.InsufficientFreeBytes,
        accepted.validate(.{ .free_bytes = 58_522_308_634, .free_inodes = 3_362 }),
    );
    try std.testing.expectError(
        error.InsufficientFreeInodes,
        accepted.validate(.{ .free_bytes = 58_522_308_635, .free_inodes = 3_361 }),
    );
    const overflow: CapacityRequirement = .{
        .validation_reserve = std.math.maxInt(u64),
        .primary_bytes = 1,
        .snapshot_bound = 0,
        .manifest_bound = 0,
        .required_inodes = 0,
    };
    try std.testing.expectError(error.Overflow, overflow.requiredBytes());
    try std.testing.expectEqual(
        CapacityObservation{ .free_bytes = 4096, .free_inodes = 7 },
        try capacityFromFields(2, 2048, 7),
    );
    try std.testing.expectError(
        error.Overflow,
        capacityFromFields(std.math.maxInt(u64), 2, 0),
    );
    try std.testing.expectError(error.InvalidCapacityObservation, capacityFromFields(1, 0, 0));
}
