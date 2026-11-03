const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const legalization = @import("word_pair_memory.zig");

fn fixture() ![]u8 {
    return std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/word_pair_memory.ll", std.testing.allocator, .limited(1024 * 1024));
}

fn context(module: ir.Module) machine.ReadOnlyModuleContext {
    return .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
}

test "word-pair frame copies execute full-width fields and preserve the original IR" {
    const bytes = try fixture();
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    const ctx = context(module);
    const Pair = extern struct { pointer: ?*anyopaque, length: u64 };
    const Guarded = extern struct { before: u64, pair: Pair, after: u64 };
    var buffer: [64]u8 = @splat(0);
    const pointers = [_]?*anyopaque{ null, &buffer, &buffer[1], &buffer[63] };
    const lengths = [_]u64{ 0, 1, 127, 128, 0xffff_ffff, 0xffff_ffff_ffff_ffff, 0x8000_0000_0000_0000 };
    for (module.functions.items, 0..) |function, index| {
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        const selected = try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx);
        switch (selected) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("word-pair native selection: {any}\n", .{diagnostic});
                return error.TestUnexpectedResult;
            },
        }
        try verify.verifyFunction(lowered);
        try std.testing.expect(lowered.selection_owner == .composed_block or lowered.selection_owner == .composed_cfg);
        const code = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(code);
        const executable = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..code.len], code);
        for (pointers) |pointer| for (lengths) |length| {
            if (index == 0) {
                const run: *const fn (?*anyopaque, u64, *Pair) callconv(.c) u64 = @ptrCast(executable.ptr);
                var output: Guarded = .{ .before = 0xa5a5_a5a5_a5a5_a5a5, .pair = .{ .pointer = null, .length = 17 }, .after = 0xa5a5_a5a5_a5a5_a5a5 };
                try std.testing.expectEqual(length, run(pointer, length, &output.pair));
                try std.testing.expectEqual(pointer, output.pair.pointer);
                try std.testing.expectEqual(length, output.pair.length);
                try std.testing.expectEqual(@as(u64, 0xa5a5_a5a5_a5a5_a5a5), output.before);
                try std.testing.expectEqual(@as(u64, 0xa5a5_a5a5_a5a5_a5a5), output.after);
            } else {
                const run: *const fn (?*anyopaque, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
                try std.testing.expectEqual(length ^ @intFromPtr(pointer), run(pointer, length));
            }
        };
    }
    // The private codegen view must not rewrite borrowed caller records/lists.
    const original = module.functions.items[0];
    try std.testing.expectEqualStrings("%PairBox", original.blocks.items[0].instructions.items[0].kind.alloca.allocated_ty.aggregate);
    for (original.blocks.items[0].instructions.items) |instruction| {
        if (instruction.kind != .call) continue;
        const args = instruction.kind.call.args.items;
        try std.testing.expectEqualStrings("destination", args[0].value.named);
        try std.testing.expectEqualStrings("source", args[1].value.named);
        try std.testing.expectEqual(@as(i128, 16), args[2].value.int);
    }
    try module.verify();
}

test "word-pair legalization declines barriers address spaces counts and excessive alignment" {
    const bytes = try fixture();
    defer std.testing.allocator.free(bytes);
    for (0..5) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, bytes);
        defer module.deinit();
        const ctx = context(module);
        const function = &module.functions.items[0];
        for (function.blocks.items) |*block| for (block.instructions.items) |*instruction| {
            if (instruction.kind == .store and instruction.kind.store.ty == .aggregate) {
                if (boundary == 0) instruction.kind.store.attrs.is_volatile = true;
                if (boundary == 1) instruction.kind.store.attrs.atomic_ordering = "unordered";
            }
            if (instruction.kind == .alloca) {
                if (boundary == 2) instruction.kind.alloca.allocated_ty_addrspace = "1";
                if (boundary == 3) instruction.kind.alloca.count = .{ .ty = .{ .int = 64 }, .value = .{ .int = 2 } };
                if (boundary == 4) instruction.kind.alloca.attrs = "align 32";
            }
        };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try legalization.legalize(arena.allocator(), function.*, &ctx) == null);
    }
}

test "word-pair byte addresses reject negative out-of-range and dynamic offsets" {
    const bytes = try fixture();
    defer std.testing.allocator.free(bytes);
    for (0..3) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, bytes);
        defer module.deinit();
        const ctx = context(module);
        const function = &module.functions.items[0];
        for (function.blocks.items) |*block| for (block.instructions.items) |*instruction| {
            if (instruction.result == null or !std.mem.eql(u8, instruction.result.?, "destination8")) continue;
            instruction.kind.gep.indices.items[0].value = switch (boundary) {
                0 => .{ .int = -1 },
                1 => .{ .int = 17 },
                else => .{ .named = "length" },
            };
        };
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function.*, &ctx)) {
            .selected => return error.TestUnexpectedResult,
            .unsupported => |diagnostic| try std.testing.expectEqualStrings("composed-block-unknown-byte-gep-ptr", diagnostic.detail()),
        }
    }
}
