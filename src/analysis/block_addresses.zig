//! CFG transforms currently do not update blockaddress constants. Keep the
//! referenced functions intact while still optimizing unrelated functions.
const std = @import("std");
const ir = @import("../ir.zig");
const references = @import("module_references.zig");

pub const Guard = struct {
    allocator: std.mem.Allocator,
    functions: std.StringHashMapUnmanaged(void) = .empty,
    unknown: bool = false,

    pub fn build(allocator: std.mem.Allocator, module: ir.Module) !Guard {
        var guard: Guard = .{ .allocator = allocator };
        errdefer guard.deinit();
        try references.walkModule(&module, Collector{ .guard = &guard });
        var names = guard.functions.keyIterator();
        while (names.next()) |name| {
            const resolved = for (module.functions.items) |function| {
                if (std.mem.eql(u8, function.name, name.*)) break true;
            } else false;
            // Alternate quoted spellings and unresolved symbols must not turn
            // a positive address reference into permission to remove blocks.
            if (!resolved) guard.unknown = true;
        }
        return guard;
    }

    pub fn deinit(guard: *Guard) void {
        guard.functions.deinit(guard.allocator);
    }

    pub fn contains(guard: Guard, function_name: []const u8) bool {
        return guard.unknown or guard.functions.contains(function_name);
    }
};

const Collector = struct {
    pub const Error = std.mem.Allocator.Error;
    guard: *Guard,

    pub fn visit(collector: Collector, _: references.Site, event: references.Event) Error!void {
        switch (event) {
            .symbol => {},
            .unknown => |kind| if (kind == .block_address) {
                collector.guard.unknown = true;
            },
            .block_address => |address| try collector.guard.functions.put(collector.guard.allocator, address.function, {}),
        }
    }
};
