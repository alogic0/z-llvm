const std = @import("std");

pub const schema_version: u32 = 1;
pub const serial_reserve_floor_bytes: u64 = 32 * 1024 * 1024 * 1024;
pub const serial_reserve_fraction_denominator: u64 = 20;
pub const serial_projected_peak_bytes: u64 = 4_419_112_960;

pub const Policy = struct {
    filesystem_total_bytes: u64,
    reserve_bytes: u64,
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

test "policy derives the accepted serial threshold from filesystem size" {
    const policy = forFilesystem(982_240_026_624);
    try std.testing.expectEqual(@as(u64, 49_112_001_332), policy.reserve_bytes);
    try std.testing.expectEqual(@as(u64, 4_419_112_960), policy.projected_peak_bytes);
    try std.testing.expectEqual(@as(u64, 53_531_114_292), policy.required_start_bytes);
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
