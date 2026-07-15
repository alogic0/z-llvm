const std = @import("std");

pub const schema_version: u32 = 1;
pub const floor_fraction_denominator: u64 = 10;
// Conservative initial authority. INBOX-69 acceptance evidence records the
// focused concurrency-three measurement used to refine this bound.
pub const projected_disk_peak_bytes: u64 = 8 * 1024 * 1024 * 1024;
pub const minimum_available_memory_bytes: u64 = 8 * 1024 * 1024 * 1024;
pub const worker_count: usize = 3;

pub const Policy = struct {
    filesystem_total_bytes: u64,
    floor_bytes: u64,
    projected_peak_bytes: u64,
    required_start_bytes: u64,
    minimum_available_memory_bytes: u64,
};

pub fn forFilesystem(filesystem_total_bytes: u64) Policy {
    const floor = filesystem_total_bytes / floor_fraction_denominator +
        @intFromBool(filesystem_total_bytes % floor_fraction_denominator != 0);
    return .{
        .filesystem_total_bytes = filesystem_total_bytes,
        .floor_bytes = floor,
        .projected_peak_bytes = projected_disk_peak_bytes,
        .required_start_bytes = floor +| projected_disk_peak_bytes,
        .minimum_available_memory_bytes = minimum_available_memory_bytes,
    };
}

test "real-row parallel policy uses its own ten-percent floor and projected peak" {
    const policy = forFilesystem(982_240_026_624);
    try std.testing.expectEqual(@as(u64, 98_224_002_663), policy.floor_bytes);
    try std.testing.expectEqual(@as(u64, 8_589_934_592), policy.projected_peak_bytes);
    try std.testing.expectEqual(@as(u64, 106_813_937_255), policy.required_start_bytes);
    try std.testing.expectEqual(@as(u64, 8_589_934_592), policy.minimum_available_memory_bytes);
    try std.testing.expectEqual(@as(usize, 3), worker_count);
}
