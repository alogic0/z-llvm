const std = @import("std");

pub const schema_version: u32 = 2;
pub const post_run_free_floor_bytes: u64 = 34_359_738_368;
// Focused INBOX-69 concurrency-three peak: 539,158,368 bytes. The accepted
// additive-margin branch is max(measured * 1.25, measured + 4 GiB).
pub const projected_disk_peak_bytes: u64 = 4_834_125_664;
pub const required_start_bytes: u64 = 39_193_864_032;
pub const minimum_available_memory_bytes: u64 = 8 * 1024 * 1024 * 1024;
pub const worker_count: usize = 3;

pub const Policy = struct {
    filesystem_total_bytes: u64,
    post_run_free_floor_bytes: u64,
    projected_peak_bytes: u64,
    required_start_bytes: u64,
    minimum_available_memory_bytes: u64,
};

fn checkedRequiredStart(post_run_floor: u64, projected_peak: u64) !u64 {
    return std.math.add(u64, post_run_floor, projected_peak) catch
        return error.RealRowsParallelPolicyOverflow;
}

pub fn forFilesystem(filesystem_total_bytes: u64) !Policy {
    const computed_required_start = try checkedRequiredStart(post_run_free_floor_bytes, projected_disk_peak_bytes);
    if (computed_required_start != required_start_bytes) return error.RealRowsParallelPolicyConstantMismatch;
    if (filesystem_total_bytes < computed_required_start) return error.RealRowsParallelFilesystemTooSmall;
    return .{
        .filesystem_total_bytes = filesystem_total_bytes,
        .post_run_free_floor_bytes = post_run_free_floor_bytes,
        .projected_peak_bytes = projected_disk_peak_bytes,
        .required_start_bytes = computed_required_start,
        .minimum_available_memory_bytes = minimum_available_memory_bytes,
    };
}

test "real-row parallel policy uses exact fixed floor projected peak and checked start" {
    const policy = try forFilesystem(982_240_026_624);
    try std.testing.expectEqual(@as(u32, 2), schema_version);
    try std.testing.expectEqual(@as(u64, 34_359_738_368), policy.post_run_free_floor_bytes);
    try std.testing.expectEqual(@as(u64, 4_834_125_664), policy.projected_peak_bytes);
    try std.testing.expectEqual(@as(u64, 39_193_864_032), policy.required_start_bytes);
    try std.testing.expectEqual(@as(u64, 8_589_934_592), policy.minimum_available_memory_bytes);
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
