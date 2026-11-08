const std = @import("std");

pub const schema_version: u32 = 3;
// User-directed 2026-11-08: require exactly 20 decimal GB at admission.
// Keep the working allowance separate; derive the execution reserve from it.
pub const serial_required_start_bytes: u64 = 20_000_000_000;
pub const serial_reserve_floor_bytes: u64 = serial_required_start_bytes - serial_projected_peak_bytes;
// The 2026-11-02 full fresh run sampled a 6,048,505,856-byte global
// decrease. Round its 25% margin upward to a whole GiB. The observation
// includes worker caches and filesystem activity, not just published AIR.
pub const measured_serial_peak_bytes: u64 = 6_048_505_856;
pub const serial_projected_peak_bytes: u64 = 8 * 1024 * 1024 * 1024;
pub const sharding_floor_fraction_denominator: u64 = 10;
pub const sharding_projected_peak_bytes: u64 = 16 * 1024 * 1024 * 1024;

pub const Policy = struct {
    filesystem_total_bytes: u64,
    reserve_bytes: u64,
    projected_peak_bytes: u64,
    required_start_bytes: u64,
};

/// A caller already admitted the entire serial run. Its descendants consume
/// that allowance while continuing to enforce the reserve at every sample.
pub const Admission = struct {
    filesystem_total_bytes: u64,
    starting_free_bytes: u64,
    reserve_bytes: u64,
    projected_peak_bytes: u64,

    pub fn validate(admission: Admission, total_bytes: u64, floor_bytes: u64, forecast_bytes: u64) !void {
        if (admission.filesystem_total_bytes != total_bytes or admission.reserve_bytes < floor_bytes or
            admission.projected_peak_bytes < forecast_bytes) return error.InvalidInheritedHeadroomAdmission;
        const required = std.math.add(u64, admission.reserve_bytes, admission.projected_peak_bytes) catch
            return error.InvalidInheritedHeadroomAdmission;
        if (admission.starting_free_bytes < required) return error.InvalidInheritedHeadroomAdmission;
    }
};

test "inherited admission binds the filesystem reserve forecast and original free space" {
    const admission: Admission = .{ .filesystem_total_bytes = 1000, .starting_free_bytes = 300, .reserve_bytes = 100, .projected_peak_bytes = 200 };
    try admission.validate(1000, 100, 200);
    try std.testing.expectError(error.InvalidInheritedHeadroomAdmission, admission.validate(1001, 100, 200));
    try std.testing.expectError(error.InvalidInheritedHeadroomAdmission, admission.validate(1000, 101, 200));
    try std.testing.expectError(error.InvalidInheritedHeadroomAdmission, admission.validate(1000, 100, 201));
    var invalid = admission;
    invalid.starting_free_bytes = 299;
    try std.testing.expectError(error.InvalidInheritedHeadroomAdmission, invalid.validate(1000, 100, 200));
    invalid = .{ .filesystem_total_bytes = 1000, .starting_free_bytes = std.math.maxInt(u64), .reserve_bytes = std.math.maxInt(u64), .projected_peak_bytes = 1 };
    try std.testing.expectError(error.InvalidInheritedHeadroomAdmission, invalid.validate(1000, 100, 1));
}

pub const ShardingPolicy = struct {
    filesystem_total_bytes: u64,
    floor_bytes: u64,
    projected_peak_bytes: u64,
    required_start_bytes: u64,
};

pub const Tracker = struct {
    starting_free_bytes: u64,
    minimum_free_bytes: u64,

    pub fn init(first_free_bytes: u64) Tracker {
        return .{
            .starting_free_bytes = first_free_bytes,
            .minimum_free_bytes = first_free_bytes,
        };
    }

    pub fn observe(tracker: *Tracker, free_bytes: u64) void {
        if (free_bytes < tracker.minimum_free_bytes) {
            tracker.minimum_free_bytes = free_bytes;
        }
    }

    pub fn observedPeakBytes(tracker: Tracker) u64 {
        return tracker.starting_free_bytes - tracker.minimum_free_bytes;
    }
};

pub fn forFilesystem(filesystem_total_bytes: u64) Policy {
    return .{
        .filesystem_total_bytes = filesystem_total_bytes,
        .reserve_bytes = serial_reserve_floor_bytes,
        .projected_peak_bytes = serial_projected_peak_bytes,
        .required_start_bytes = serial_required_start_bytes,
    };
}

pub fn shardingForFilesystem(filesystem_total_bytes: u64) ShardingPolicy {
    const floor = filesystem_total_bytes / sharding_floor_fraction_denominator +
        @intFromBool(filesystem_total_bytes % sharding_floor_fraction_denominator != 0);
    return .{
        .filesystem_total_bytes = filesystem_total_bytes,
        .floor_bytes = floor,
        .projected_peak_bytes = sharding_projected_peak_bytes,
        .required_start_bytes = floor +| sharding_projected_peak_bytes,
    };
}

test "serial policy keeps the approved fixed reserve across filesystem capacities" {
    try std.testing.expectEqual(@as(u32, 3), schema_version);
    for ([_]u64{ 20_000_000_000, 982_240_026_624, 4 * 1024 * 1024 * 1024 * 1024, std.math.maxInt(u64) }) |total| {
        const policy = forFilesystem(total);
        try std.testing.expectEqual(total, policy.filesystem_total_bytes);
        try std.testing.expectEqual(@as(u64, 11_410_065_408), policy.reserve_bytes);
        try std.testing.expectEqual(@as(u64, 8_589_934_592), policy.projected_peak_bytes);
        try std.testing.expectEqual(@as(u64, 20_000_000_000), policy.required_start_bytes);
    }
    try std.testing.expect(serial_projected_peak_bytes >= measured_serial_peak_bytes + (measured_serial_peak_bytes + 3) / 4);
    try std.testing.expect(serial_projected_peak_bytes - 1024 * 1024 * 1024 < measured_serial_peak_bytes + (measured_serial_peak_bytes + 3) / 4);
}

test "fixed serial budget admits its exact boundary and rejects one byte less" {
    const policy = forFilesystem(982_240_026_624);
    var admission: Admission = .{
        .filesystem_total_bytes = policy.filesystem_total_bytes,
        .starting_free_bytes = policy.required_start_bytes,
        .reserve_bytes = policy.reserve_bytes,
        .projected_peak_bytes = policy.projected_peak_bytes,
    };
    try admission.validate(policy.filesystem_total_bytes, policy.reserve_bytes, policy.projected_peak_bytes);
    admission.starting_free_bytes -= 1;
    try std.testing.expectError(error.InvalidInheritedHeadroomAdmission, admission.validate(policy.filesystem_total_bytes, policy.reserve_bytes, policy.projected_peak_bytes));
}

test "tracker initializes minimum from the first sample without a sentinel" {
    var tracker = Tracker.init(115_000);
    try std.testing.expectEqual(@as(u64, 115_000), tracker.minimum_free_bytes);
    tracker.observe(116_000);
    try std.testing.expectEqual(@as(u64, 115_000), tracker.minimum_free_bytes);
    tracker.observe(111_500);
    try std.testing.expectEqual(@as(u64, 111_500), tracker.minimum_free_bytes);
    try std.testing.expectEqual(@as(u64, 3_500), tracker.observedPeakBytes());
}

test "sharding policy derives the ten-percent floor plus projected peak" {
    const policy = shardingForFilesystem(982_240_026_624);
    try std.testing.expectEqual(@as(u64, 98_224_002_663), policy.floor_bytes);
    try std.testing.expectEqual(@as(u64, 17_179_869_184), policy.projected_peak_bytes);
    try std.testing.expectEqual(@as(u64, 115_403_871_847), policy.required_start_bytes);
}
