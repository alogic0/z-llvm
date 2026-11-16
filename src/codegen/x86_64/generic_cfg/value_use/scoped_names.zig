//! Byte-exact names owned once per selector/function rewrite attempt.
//! Entries are append-only, including across transaction rollback. An unpublished
//! insertion may remain cached, but its slot is never rebound to another name.
const std = @import("std");

var next_namespace: std.atomic.Value(u64) = .init(1);

/// Shared by name pools and instruction authorities. Never wraps or reuses a
/// namespace, even if a selector or transaction occupies a former stack address.
pub fn freshNamespace() !u64 {
    var current = next_namespace.load(.monotonic);
    while (true) {
        if (current == std.math.maxInt(u64)) return error.ValueUseNamespaceExhausted;
        current = next_namespace.cmpxchgWeak(current, current + 1, .monotonic, .monotonic) orelse return current;
    }
}

pub const Identity = struct {
    namespace: u64,
    slot: u32,

    pub fn init(pool: *Pool, allocator: std.mem.Allocator, name: []const u8) !Identity {
        return pool.intern(allocator, name);
    }

    pub fn slice(identity: Identity, pool: *const Pool) ![]const u8 {
        if (identity.namespace == 0 or identity.namespace != pool.namespace or identity.slot >= pool.names.count())
            return error.ValueUseIdentityStale;
        return pool.names.keys()[identity.slot];
    }

    pub fn eql(identity: Identity, other: *const Identity) bool {
        return identity.namespace == other.namespace and identity.slot == other.slot;
    }
};

pub const Pool = struct {
    namespace: u64 = 0,
    names: std.array_hash_map.String(void) = .empty,

    pub fn deinit(pool: *Pool, allocator: std.mem.Allocator) void {
        for (pool.names.keys()) |name| allocator.free(name);
        pool.names.deinit(allocator);
        pool.* = .{};
    }

    pub fn intern(pool: *Pool, allocator: std.mem.Allocator, name: []const u8) !Identity {
        if (name.len == 0) return error.ValueUseEmptyIdentity;
        if (pool.names.getIndex(name)) |slot|
            return .{ .namespace = pool.namespace, .slot = @intCast(slot) };
        if (pool.names.count() >= std.math.maxInt(u32)) return error.ValueUseIdentityCapacityExceeded;
        const owned = try allocator.dupe(u8, name);
        errdefer allocator.free(owned);
        try pool.names.ensureUnusedCapacity(allocator, 1);
        const namespace = if (pool.namespace == 0) try freshNamespace() else pool.namespace;
        const slot: u32 = @intCast(pool.names.count());
        // All fallible work precedes publication. Capacity changes on failure
        // do not publish a name, slot, or namespace.
        pool.names.putAssumeCapacityNoClobber(owned, {});
        pool.namespace = namespace;
        return .{ .namespace = namespace, .slot = slot };
    }
};

test "value-use scoped identities preserve exact long bytes and spelling contracts" {
    var pool: Pool = .{};
    defer pool.deinit(std.testing.allocator);
    var names: [2][4096]u8 = @splat(@splat('x'));
    names[0][4095] = 'a';
    names[1][4095] = 'b';
    const first = try pool.intern(std.testing.allocator, &names[0]);
    const second = try pool.intern(std.testing.allocator, &names[1]);
    try std.testing.expect(!first.eql(&second));
    try std.testing.expect(first.eql(&try pool.intern(std.testing.allocator, &names[0])));
    try std.testing.expectEqualStrings(&names[0], try first.slice(&pool));
    names[0][0] = 'y';
    try std.testing.expectEqual(@as(u8, 'x'), (try first.slice(&pool))[0]);
    const spellings = [_][]const u8{ "%name", "%\"name\"", "%\"na\\6De\"", "%7", "%\"7\"" };
    for (spellings, 0..) |spelling, index| {
        const identity = try pool.intern(std.testing.allocator, spelling);
        try std.testing.expectEqualStrings(spelling, try identity.slice(&pool));
        for (spellings[0..index]) |other| {
            const previous = try pool.intern(std.testing.allocator, other);
            try std.testing.expect(!identity.eql(&previous));
        }
    }
    try std.testing.expectError(error.ValueUseEmptyIdentity, pool.intern(std.testing.allocator, ""));
    try std.testing.expect(@sizeOf(Identity) <= 16);
}

test "value-use scoped identities reject other functions and reused generation slots" {
    var first: Pool = .{};
    defer first.deinit(std.testing.allocator);
    var second: Pool = .{};
    defer second.deinit(std.testing.allocator);
    const old = try first.intern(std.testing.allocator, "same");
    const other = try second.intern(std.testing.allocator, "same");
    try std.testing.expectEqual(old.slot, other.slot);
    try std.testing.expect(!old.eql(&other));
    try std.testing.expectError(error.ValueUseIdentityStale, old.slice(&second));
    first.deinit(std.testing.allocator);
    try std.testing.expectError(error.ValueUseIdentityStale, old.slice(&first));
    const replacement = try first.intern(std.testing.allocator, "different");
    try std.testing.expectEqual(old.slot, replacement.slot);
    try std.testing.expectError(error.ValueUseIdentityStale, old.slice(&first));
    try std.testing.expectEqualStrings("different", try replacement.slice(&first));
    var forged = replacement;
    forged.slot = std.math.maxInt(u32);
    try std.testing.expectError(error.ValueUseIdentityStale, forged.slice(&first));
}

fn allocationFailureCase(allocator: std.mem.Allocator) !void {
    var pool: Pool = .{};
    defer pool.deinit(allocator);
    const first = try pool.intern(allocator, "retained");
    const count = pool.names.count();
    const namespace = pool.namespace;
    const next = pool.intern(allocator, "next") catch |err| {
        try std.testing.expectEqual(count, pool.names.count());
        try std.testing.expectEqual(namespace, pool.namespace);
        try std.testing.expectEqualStrings("retained", try first.slice(&pool));
        try std.testing.expect(pool.names.getIndex("next") == null);
        return err;
    };
    try std.testing.expect(!first.eql(&next));
    try std.testing.expectEqualStrings("next", try next.slice(&pool));
}

test "value-use scoped identity insertion publishes atomically under allocation failure" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocationFailureCase, .{});
}
