const std = @import("std");

pub const schema_version: u32 = 1;
pub const serial_reserve_floor_bytes: u64 = 32 * 1024 * 1024 * 1024;
pub const serial_reserve_fraction_denominator: u64 = 20;
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
    const fraction = filesystem_total_bytes / serial_reserve_fraction_denominator +
        @intFromBool(filesystem_total_bytes % serial_reserve_fraction_denominator != 0);
    const reserve = @max(serial_reserve_floor_bytes, fraction);
    return .{
        .filesystem_total_bytes = filesystem_total_bytes,
        .reserve_bytes = reserve,
        .projected_peak_bytes = serial_projected_peak_bytes,
        .required_start_bytes = reserve +| serial_projected_peak_bytes,
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

test "policy derives the accepted serial threshold from filesystem size" {
    const policy = forFilesystem(982_240_026_624);
    try std.testing.expectEqual(@as(u64, 49_112_001_332), policy.reserve_bytes);
    try std.testing.expectEqual(@as(u64, 8_589_934_592), policy.projected_peak_bytes);
    try std.testing.expectEqual(@as(u64, 57_701_935_924), policy.required_start_bytes);
    try std.testing.expect(serial_projected_peak_bytes >= measured_serial_peak_bytes + (measured_serial_peak_bytes + 3) / 4);
    try std.testing.expect(serial_projected_peak_bytes - 1024 * 1024 * 1024 < measured_serial_peak_bytes + (measured_serial_peak_bytes + 3) / 4);
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
