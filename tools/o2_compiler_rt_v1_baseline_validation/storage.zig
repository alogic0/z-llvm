const std = @import("std");
const builtin = @import("builtin");
const contract = @import("../o2_compiler_rt_v1_baseline_validation.zig");
const authenticated_inputs = @import("authenticated_inputs.zig");

const NativeStatfs = extern struct {
    f_type: c_long,
    f_bsize: c_long,
    f_blocks: c_ulong,
    f_bfree: c_ulong,
    f_bavail: c_ulong,
    f_files: c_ulong,
    f_ffree: c_ulong,
    f_fsid: extern struct { values: [2]c_int },
    f_namelen: c_long,
    f_frsize: c_long,
    f_flags: c_long,
    f_spare: [4]c_long,
};

pub const CapacityFields = struct {
    block_size: i128,
    fragment_size: i128,
    blocks: i128,
    free_blocks: i128,
    available_blocks: i128,
};

pub const CapacityRootIdentity = struct {
    inode: std.Io.File.INode,
    mode: u32,
    kind: std.Io.File.Kind,
    filesystem_id: [2]c_int,
};

pub const PathFact = struct {
    label: []const u8,
    supplied: []const u8,
    canonical: []const u8,
    kind: authenticated_inputs.PathKind,
    expected_kind: authenticated_inputs.PathKind,
    is_symlink: bool,
    identity: u128,
};

pub const FamilyUsage = struct {
    family_id: u8,
    retained_bytes: u64,
    largest_file_bytes: u64,
    root_bytes: u64,
    aggregate_exclusions: u32,
};

pub const FamilyTracker = struct {
    next: usize = 0,
    total_retained_bytes: u64 = 0,
    rows: [contract.storage_families.len]contract.EnforcedStorageFamily = undefined,

    pub fn close(self: *FamilyTracker, usage: FamilyUsage) !void {
        if (usage.family_id == 0 or usage.family_id > contract.storage_families.len)
            return error.FamilyUnknown;
        const index: usize = @intCast(usage.family_id - 1);
        if (index < self.next) return error.FamilyDuplicate;
        if (index != self.next) return error.FamilyOutOfOrder;
        const policies = contract.acceptedEnforcedStorageFamilies() catch return error.AggregateExclusionDrift;
        const policy = policies[index];
        if (usage.aggregate_exclusions != policy.aggregate_exclusions) return error.AggregateExclusionDrift;
        if (usage.largest_file_bytes > policy.maximum_bytes) return error.FileCapExceeded;
        if (usage.root_bytes > policy.maximum_bytes) return error.RootCapExceeded;
        if (usage.retained_bytes > policy.maximum_bytes) return error.FamilyCapExceeded;
        self.total_retained_bytes = std.math.add(u64, self.total_retained_bytes, usage.retained_bytes) catch
            return error.StorageOverflow;
        if (self.total_retained_bytes > contract.accepted_maximum_storage_bytes)
            return error.AggregateCapExceeded;
        self.rows[index] = policy;
        self.next += 1;
    }

    pub fn finish(self: *const FamilyTracker) !void {
        if (self.next != contract.storage_families.len) return error.FamilyMissing;
        if (self.total_retained_bytes > contract.accepted_maximum_storage_bytes)
            return error.AggregateCapExceeded;
    }
};

pub fn initializeFamilyUsage() [contract.storage_families.len]FamilyUsage {
    var usage: [contract.storage_families.len]FamilyUsage = undefined;
    for (&usage, contract.accepted_storage_policy, 0..) |*row, policy, index| {
        row.* = .{
            .family_id = @intCast(index + 1),
            .retained_bytes = 0,
            .largest_file_bytes = 0,
            .root_bytes = 0,
            .aggregate_exclusions = policy.aggregate_exclusions,
        };
    }
    return usage;
}

pub fn accountFamilyBytes(
    usage: *[contract.storage_families.len]FamilyUsage,
    family: contract.StorageFamily,
    bytes: u64,
) !void {
    const index: usize = @intCast(@intFromEnum(family) - 1);
    const policy = (contract.acceptedEnforcedStorageFamilies() catch
        return error.AggregateExclusionDrift)[index];
    if (bytes > policy.maximum_bytes) return error.FileCapExceeded;
    const total = std.math.add(u64, usage[index].retained_bytes, bytes) catch return error.StorageOverflow;
    if (total > policy.maximum_bytes) return error.FamilyCapExceeded;
    usage[index].retained_bytes = total;
    usage[index].root_bytes = total;
    usage[index].largest_file_bytes = @max(usage[index].largest_file_bytes, bytes);
}

fn isPathWithin(path: []const u8, prefix: []const u8) bool {
    if (std.mem.eql(u8, path, prefix)) return true;
    return path.len > prefix.len and std.mem.startsWith(u8, path, prefix) and path[prefix.len] == '/';
}

pub fn validatePathFacts(facts: []const PathFact, prefixes: []const []const u8) !void {
    for (prefixes) |prefix| try @import("process.zig").validateCanonicalAbsolute(prefix);
    for (facts, 0..) |fact, index| {
        try @import("process.zig").validateCanonicalAbsolute(fact.supplied);
        try @import("process.zig").validateCanonicalAbsolute(fact.canonical);
        if (!std.mem.eql(u8, fact.supplied, fact.canonical)) return error.NonCanonicalPath;
        if (fact.is_symlink) return error.SymlinkRejected;
        if (fact.kind != fact.expected_kind) return error.WrongPathKind;
        for (prefixes) |prefix| if (isPathWithin(fact.canonical, prefix)) return error.RegisteredWorktreeRejected;
        for (facts[0..index]) |prior| {
            if (std.mem.eql(u8, prior.canonical, fact.canonical) or prior.identity == fact.identity)
                return error.PathAlias;
        }
    }
}

fn fstatfs(root: std.Io.Dir) !NativeStatfs {
    var native: NativeStatfs = undefined;
    const raw = std.os.linux.syscall2(.fstatfs, @intCast(root.handle), @intFromPtr(&native));
    if (std.os.linux.errno(raw) != .SUCCESS) return error.CapacitySyscallFailed;
    return native;
}

pub fn observePathFact(
    io: std.Io,
    label: []const u8,
    absolute_path: []const u8,
    expected_kind: authenticated_inputs.PathKind,
    registered_worktrees: []const []const u8,
) !PathFact {
    _ = try authenticated_inputs.validateExplicitPath(io, absolute_path, expected_kind, registered_worktrees);
    var file = try std.Io.Dir.openFileAbsolute(io, absolute_path, .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = true,
        .follow_symlinks = false,
    });
    defer file.close(io);
    const stat = try file.stat(io);
    const native = try fstatfs(.{ .handle = file.handle });
    const fs0: u32 = @bitCast(native.f_fsid.values[0]);
    const fs1: u32 = @bitCast(native.f_fsid.values[1]);
    const identity = (@as(u128, fs0) << 96) | (@as(u128, fs1) << 64) | @as(u64, @intCast(stat.inode));
    return .{
        .label = label,
        .supplied = absolute_path,
        .canonical = absolute_path,
        .kind = expected_kind,
        .expected_kind = expected_kind,
        .is_symlink = false,
        .identity = identity,
    };
}

pub fn deriveAvailableBytes(fields: CapacityFields) !u64 {
    if (fields.block_size <= 0 or fields.fragment_size <= 0 or fields.blocks <= 0 or
        fields.free_blocks <= 0 or fields.available_blocks <= 0 or
        fields.free_blocks > fields.blocks or fields.available_blocks > fields.free_blocks)
        return error.CapacityFieldsInvalid;
    const unit_signed = @min(fields.block_size, fields.fragment_size);
    if (unit_signed > std.math.maxInt(u64) or fields.available_blocks > std.math.maxInt(u64))
        return error.CapacityOverflow;
    return std.math.mul(u64, @intCast(fields.available_blocks), @intCast(unit_signed)) catch
        return error.CapacityOverflow;
}

pub fn capacityRootIdentity(io: std.Io, root: std.Io.Dir, filesystem_id: [2]c_int) !CapacityRootIdentity {
    const metadata = try root.stat(io);
    if (metadata.kind != .directory) return error.WrongPathKind;
    return .{
        .inode = metadata.inode,
        .mode = @intCast(metadata.permissions.toMode() & 0o7777),
        .kind = metadata.kind,
        .filesystem_id = filesystem_id,
    };
}

pub fn requireCapacityRootStable(before: CapacityRootIdentity, after: CapacityRootIdentity) !void {
    if (!std.meta.eql(before, after)) return error.CapacityRootMismatch;
}

pub fn observeAvailableBytes(io: std.Io, validation_root: std.Io.Dir) !u64 {
    const before_native = try fstatfs(validation_root);
    const before = try capacityRootIdentity(io, validation_root, before_native.f_fsid.values);
    const available = try deriveAvailableBytes(.{
        .block_size = before_native.f_bsize,
        .fragment_size = before_native.f_frsize,
        .blocks = before_native.f_blocks,
        .free_blocks = before_native.f_bfree,
        .available_blocks = before_native.f_bavail,
    });
    const after_native = try fstatfs(validation_root);
    const after = try capacityRootIdentity(io, validation_root, after_native.f_fsid.values);
    try requireCapacityRootStable(before, after);
    return available;
}

pub fn requireSameOutputFilesystem(io: std.Io, validation_root: std.Io.Dir, absolute_directory: []const u8) !void {
    var directory = try std.Io.Dir.openDirAbsolute(io, absolute_directory, .{
        .access_sub_paths = false,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer directory.close(io);
    const validation = try fstatfs(validation_root);
    const candidate = try fstatfs(directory);
    if (!std.meta.eql(validation.f_fsid.values, candidate.f_fsid.values)) return error.CapacityRootMismatch;
}

pub const RootUsage = struct { bytes: u64, largest_file: u64 };

pub fn scanRootBounded(io: std.Io, absolute_root: []const u8, maximum_bytes: u64, registered: []const []const u8) !RootUsage {
    _ = try authenticated_inputs.validateExplicitPath(io, absolute_root, .directory, registered);
    var root = try std.Io.Dir.openDirAbsolute(io, absolute_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    defer root.close(io);
    const root_fs = try fstatfs(root);
    var walker = try root.walk(std.heap.page_allocator);
    defer walker.deinit();
    var usage = RootUsage{ .bytes = 0, .largest_file = 0 };
    var first_failure: ?anyerror = null;
    var entry_count: u64 = 0;
    while (true) {
        const maybe_entry = walker.next(io) catch {
            if (first_failure == null) first_failure = error.PathEscape;
            continue;
        };
        const entry = maybe_entry orelse break;
        entry_count = std.math.add(u64, entry_count, 1) catch {
            if (first_failure == null) first_failure = error.StorageOverflow;
            continue;
        };
        if (entry_count > 1_000_000 and first_failure == null) first_failure = error.RootCapExceeded;
        if (entry.kind == .sym_link) {
            if (first_failure == null) first_failure = error.SymlinkRejected;
            continue;
        }
        const containing_fs = fstatfs(entry.dir) catch {
            if (first_failure == null) first_failure = error.CapacitySyscallFailed;
            continue;
        };
        if (!std.meta.eql(root_fs.f_fsid.values, containing_fs.f_fsid.values)) {
            if (first_failure == null) first_failure = error.PathEscape;
            continue;
        }
        switch (entry.kind) {
            .directory => {},
            .file => {
                var file = entry.dir.openFile(io, entry.basename, .{
                    .mode = .read_only,
                    .follow_symlinks = false,
                    .resolve_beneath = true,
                }) catch {
                    if (first_failure == null) first_failure = error.PathEscape;
                    continue;
                };
                defer file.close(io);
                const stat = file.stat(io) catch {
                    if (first_failure == null) first_failure = error.PathEscape;
                    continue;
                };
                usage.bytes = std.math.add(u64, usage.bytes, stat.size) catch {
                    if (first_failure == null) first_failure = error.StorageOverflow;
                    continue;
                };
                usage.largest_file = @max(usage.largest_file, stat.size);
                if (usage.largest_file > maximum_bytes and first_failure == null) first_failure = error.FileCapExceeded;
                if (usage.bytes > maximum_bytes and first_failure == null) first_failure = error.RootCapExceeded;
            },
            else => if (first_failure == null) {
                first_failure = error.WrongPathKind;
            },
        }
    }
    if (first_failure) |failure| return failure;
    return usage;
}

pub fn setFamilyFromRoot(usage: *[contract.storage_families.len]FamilyUsage, family: contract.StorageFamily, root: RootUsage) !void {
    const index: usize = @intCast(@intFromEnum(family) - 1);
    const maximum = (try contract.acceptedEnforcedStorageFamilies())[index].maximum_bytes;
    if (root.largest_file > maximum) return error.FileCapExceeded;
    if (root.bytes > maximum) return error.RootCapExceeded;
    usage[index].retained_bytes = root.bytes;
    usage[index].root_bytes = root.bytes;
    usage[index].largest_file_bytes = root.largest_file;
}

pub fn combineRootUsage(a: RootUsage, b: RootUsage, excluded_bytes: u64) !RootUsage {
    const combined = std.math.add(u64, a.bytes, b.bytes) catch return error.StorageOverflow;
    return .{
        .bytes = std.math.sub(u64, combined, excluded_bytes) catch return error.StorageOverflow,
        .largest_file = @max(a.largest_file, b.largest_file),
    };
}

pub fn addRootUsage(a: RootUsage, b: RootUsage) !RootUsage {
    return .{
        .bytes = std.math.add(u64, a.bytes, b.bytes) catch return error.StorageOverflow,
        .largest_file = @max(a.largest_file, b.largest_file),
    };
}

pub fn scanRelativeRoots(
    allocator: std.mem.Allocator,
    io: std.Io,
    base: []const u8,
    relatives: []const []const u8,
    maximum_bytes: u64,
    registered: []const []const u8,
) !RootUsage {
    var total = RootUsage{ .bytes = 0, .largest_file = 0 };
    for (relatives) |relative| {
        const absolute = try authenticated_inputs.joinAbsolute(allocator, base, relative);
        defer allocator.free(absolute);
        total = try addRootUsage(total, try scanRootBounded(io, absolute, maximum_bytes, registered));
        if (total.bytes > maximum_bytes) return error.RootCapExceeded;
    }
    return total;
}

pub fn validateStorageRoot(entries: []const FamilyUsage, available_bytes: u64) !FamilyTracker {
    _ = try contract.acceptedStorageBudgetTotals(available_bytes);
    var tracker = FamilyTracker{};
    for (entries) |usage| try tracker.close(usage);
    try tracker.finish();
    return tracker;
}

comptime {
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64 or
        @sizeOf(usize) != 8 or @sizeOf(c_long) != 8 or @sizeOf(c_ulong) != 8)
        @compileError("baseline validation capacity requires native Linux x86_64 LP64");
    if (@intFromEnum(std.os.linux.SYS.fstatfs) != 138)
        @compileError("installed Zig Linux fstatfs syscall selection drifted");
    if (@sizeOf(NativeStatfs) != 120 or @alignOf(NativeStatfs) != 8)
        @compileError("native statfs size or alignment disagrees with Linux x86_64 ABI");
    if (@offsetOf(NativeStatfs, "f_type") != 0 or
        @offsetOf(NativeStatfs, "f_bsize") != 8 or
        @offsetOf(NativeStatfs, "f_blocks") != 16 or
        @offsetOf(NativeStatfs, "f_bfree") != 24 or
        @offsetOf(NativeStatfs, "f_bavail") != 32 or
        @offsetOf(NativeStatfs, "f_files") != 40 or
        @offsetOf(NativeStatfs, "f_ffree") != 48 or
        @offsetOf(NativeStatfs, "f_fsid") != 56 or
        @offsetOf(NativeStatfs, "f_namelen") != 64 or
        @offsetOf(NativeStatfs, "f_frsize") != 72 or
        @offsetOf(NativeStatfs, "f_flags") != 80 or
        @offsetOf(NativeStatfs, "f_spare") != 88)
    {
        @compileError("native statfs field offset disagrees with Linux x86_64 ABI");
    }
}

test "capacity arithmetic and root identity fail closed" {
    try std.testing.expectEqual(@as(u64, 409_600), try deriveAvailableBytes(.{
        .block_size = 4096,
        .fragment_size = 1024,
        .blocks = 1000,
        .free_blocks = 500,
        .available_blocks = 400,
    }));
    try std.testing.expectError(error.CapacityFieldsInvalid, deriveAvailableBytes(.{
        .block_size = 0,
        .fragment_size = 1024,
        .blocks = 1000,
        .free_blocks = 500,
        .available_blocks = 400,
    }));
    try std.testing.expectError(error.CapacityOverflow, deriveAvailableBytes(.{
        .block_size = std.math.maxInt(u64),
        .fragment_size = std.math.maxInt(u64),
        .blocks = std.math.maxInt(u64),
        .free_blocks = std.math.maxInt(u64),
        .available_blocks = 2,
    }));
    const identity = CapacityRootIdentity{ .inode = 11, .mode = 0o775, .kind = .directory, .filesystem_id = .{ 3, 7 } };
    try requireCapacityRootStable(identity, identity);
    var drifted = identity;
    drifted.inode += 1;
    try std.testing.expectError(error.CapacityRootMismatch, requireCapacityRootStable(identity, drifted));
}

test "accepted storage policies reject file root family aggregate and order drift" {
    var usage = initializeFamilyUsage();
    var tracker = try validateStorageRoot(&usage, contract.minimum_available_bytes);
    try std.testing.expectEqual(contract.storage_families.len, tracker.next);
    usage[0].largest_file_bytes = contract.accepted_maximum_storage_bytes + 1;
    try std.testing.expectError(error.FileCapExceeded, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = initializeFamilyUsage();
    usage[0].family_id = 2;
    try std.testing.expectError(error.FamilyOutOfOrder, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = initializeFamilyUsage();
    usage[0].aggregate_exclusions ^= 1;
    try std.testing.expectError(error.AggregateExclusionDrift, validateStorageRoot(&usage, contract.minimum_available_bytes));
    var overflowing = FamilyTracker{ .total_retained_bytes = std.math.maxInt(u64) };
    var overflow_usage = initializeFamilyUsage()[0];
    overflow_usage.retained_bytes = 1;
    try std.testing.expectError(error.StorageOverflow, overflowing.close(overflow_usage));
    tracker.total_retained_bytes = contract.accepted_maximum_storage_bytes + 1;
    try std.testing.expectError(error.AggregateCapExceeded, tracker.finish());
}
