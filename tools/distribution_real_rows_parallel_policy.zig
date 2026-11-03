const std = @import("std");
const serial_policy = @import("distribution_headroom_policy.zig");

pub const schema_version: u32 = 3;
pub const post_run_free_floor_bytes: u64 = 34_359_738_368;
// Include work directories and published exports, which live outside the
// parent's temporary root. Use the full-run calibration as the conservative
// admission forecast; owned-byte telemetry is a separate measurement.
pub const projected_disk_peak_bytes: u64 = serial_policy.serial_projected_peak_bytes;
pub const required_start_bytes: u64 = 42_949_672_960;
pub const worker_count: usize = 3;

pub const Policy = struct {
    filesystem_total_bytes: u64,
    post_run_free_floor_bytes: u64,
    projected_peak_bytes: u64,
    required_start_bytes: u64,
};

fn checkedRequiredStart(post_run_floor: u64, projected_peak: u64) !u64 {
    return std.math.add(u64, post_run_floor, projected_peak) catch
        return error.RealRowsParallelPolicyOverflow;
}

pub fn forFilesystem(filesystem_total_bytes: u64) !Policy {
    return forFilesystemWithFloor(filesystem_total_bytes, 0);
}

pub fn forFilesystemWithFloor(filesystem_total_bytes: u64, caller_floor_bytes: u64) !Policy {
    const computed_required_start = try checkedRequiredStart(post_run_free_floor_bytes, projected_disk_peak_bytes);
    if (computed_required_start != required_start_bytes) return error.RealRowsParallelPolicyConstantMismatch;
    const floor = @max(post_run_free_floor_bytes, caller_floor_bytes);
    const required = try checkedRequiredStart(floor, projected_disk_peak_bytes);
    if (filesystem_total_bytes < required) return error.RealRowsParallelFilesystemTooSmall;
    return .{
        .filesystem_total_bytes = filesystem_total_bytes,
        .post_run_free_floor_bytes = floor,
        .projected_peak_bytes = projected_disk_peak_bytes,
        .required_start_bytes = required,
    };
}

test "real-row parallel policy uses exact fixed floor projected peak and checked start" {
    const policy = try forFilesystem(982_240_026_624);
    try std.testing.expectEqual(@as(u32, 3), schema_version);
    try std.testing.expectEqual(@as(u64, 34_359_738_368), policy.post_run_free_floor_bytes);
    try std.testing.expectEqual(@as(u64, 8_589_934_592), policy.projected_peak_bytes);
    try std.testing.expectEqual(@as(u64, 42_949_672_960), policy.required_start_bytes);
    try std.testing.expectEqual(@as(usize, 3), worker_count);
}

test "real-row parallel policy admits exact filesystem boundary and rejects smaller filesystems" {
    const policy = try forFilesystem(required_start_bytes);
    try std.testing.expectEqual(required_start_bytes, policy.filesystem_total_bytes);
    try std.testing.expectError(error.RealRowsParallelFilesystemTooSmall, forFilesystem(required_start_bytes - 1));
}

test "real-row parallel policy checked addition fails closed on overflow" {
    try std.testing.expectEqual(required_start_bytes, try checkedRequiredStart(post_run_free_floor_bytes, projected_disk_peak_bytes));
    try std.testing.expectError(error.RealRowsParallelPolicyOverflow, checkedRequiredStart(std.math.maxInt(u64), 1));
}

test "nested real rows preserve the caller reserve and never weaken their own floor" {
    const total = 982_240_026_624;
    const outer = serial_policy.forFilesystem(total);
    const nested = try forFilesystemWithFloor(total, outer.reserve_bytes);
    try std.testing.expectEqual(outer.reserve_bytes, nested.post_run_free_floor_bytes);
    try std.testing.expectEqual(outer.required_start_bytes, nested.required_start_bytes);
    try std.testing.expectEqual(post_run_free_floor_bytes, (try forFilesystemWithFloor(total, 1)).post_run_free_floor_bytes);
    try std.testing.expectError(error.RealRowsParallelPolicyOverflow, forFilesystemWithFloor(std.math.maxInt(u64), std.math.maxInt(u64)));
}
