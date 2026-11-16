const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../ir.zig");
const codegen = @import("../codegen.zig");
const encoding = @import("../mc/encoding.zig");
const composed = @import("../codegen/x86_64/generic_cfg/composed_selector_impl.zig");
const planning = @import("../codegen/x86_64/generic_cfg/stage2_planning.zig");

test "optional-pointer family uses composed operations after renaming layout changes and live pressure" {
    if (builtin.cpu.arch != .x86_64 or builtin.os.tag != .linux) return error.SkipZigTest;
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/optional_composition.ll", std.testing.allocator, .limited(32768));
    defer std.testing.allocator.free(source);
    try std.testing.expect(std.mem.indexOf(u8, source, "xor i32 -1, %noise") != null);
    const commuted = try std.mem.replaceOwned(u8, std.testing.allocator, source, "xor i32 -1, %noise", "xor i32 %noise, -1");
    defer std.testing.allocator.free(commuted);
    for ([_][]const u8{ source, commuted }) |variant| {
        var module = try ir.Module.parse(std.testing.allocator, variant);
        defer module.deinit();
        try module.verify();
        try std.testing.expectEqual(@as(usize, 4), module.functions.items.len);
        var before: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer before.deinit();
        try @import("../ir/printer.zig").print(module, &before.writer);
        for (module.functions.items, 0..) |function, which| {
            var machine = try codegen.x86_64.lowerFunctionWithOptions(std.testing.allocator, module.target_triple.?, function, .{ .generic_cfg_selector = true });
            defer machine.deinit(std.testing.allocator);
            try std.testing.expectEqual(codegen.x86_64.SelectionOwner.composed_cfg, machine.selection_owner);
            try codegen.x86_64.verifyFunction(machine);
            if (which == 3) {
                var plan = try planning.buildSelectorAllocationPlan(std.testing.allocator, function);
                defer plan.deinit();
                try std.testing.expect(plan.spill_slots > 0);
            }
            const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
            defer std.testing.allocator.free(bytes);
            const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
            defer std.posix.munmap(mapping);
            @memcpy(mapping, bytes);
            for ([_]u32{ 0, 1, 7, 0x7fff_ffff, 0x8000_0000, 0xffff_ffff }) |word| {
                for ([_]bool{ false, true }) |present| {
                    const pointer: ?*const u32 = if (present) &word else null;
                    const a = ~word;
                    const b = word +% 17;
                    const c = word ^ 0x1234;
                    const d = word *% 3;
                    const e = word ^ 0xabcd;
                    var expected: u32 = if (present) word else std.math.maxInt(u32);
                    const actual = if (which < 2) result: {
                        if (which == 1 and present) expected +%= 8;
                        const run: *const fn (?*const u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
                        break :result run(pointer);
                    } else if (which == 2) result: {
                        expected = (if (present) word +% a +% 17 else std.math.maxInt(u32)) ^ (a ^ b);
                        const run: *const fn (?*const u32, u32, u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
                        break :result run(pointer, a, b);
                    } else result: {
                        expected +%= a +% 11;
                        expected ^= b +% 13;
                        expected +%= c ^ 22136;
                        expected ^= d +% 17;
                        expected +%= e ^ 39612;
                        expected ^= a *% 7;
                        expected +%= b ^ d;
                        expected ^= c +% e;
                        const run: *const fn (?*const u32, u32, u32, u32, u32, u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
                        break :result run(pointer, a, b, c, d, e);
                    };
                    try std.testing.expectEqual(expected, actual);
                }
            }
        }
        var after: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer after.deinit();
        try @import("../ir/printer.zig").print(module, &after.writer);
        try std.testing.expectEqualStrings(before.written(), after.written());
    }
}

test "optional-pointer composed boundary rejects an unsupported return ABI" {
    for ([_][]const u8{
        \\define <3 x double> @different_return(ptr %payload) {
        \\entry:
        \\ %nonnull = icmp ne ptr %payload, null
        \\ br i1 %nonnull, label %read, label %absent
        \\read:
        \\ ret <3 x double> zeroinitializer
        \\absent:
        \\ ret <3 x double> zeroinitializer
        \\}
        ,
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const function = module.functions.items[0];
        var machine = codegen.x86_64.MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        switch (try composed.tryLowerComposedCfg(std.testing.allocator, &machine, function)) {
            .unsupported => {},
            .selected => return error.TestUnexpectedResult,
        }
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(codegen.x86_64.SelectionOwner.unassigned, machine.selection_owner);
    }
}

test "optional-pointer fork preservation distinguishes computed scalars from ABI inputs and linear edges" {
    const source =
        \\define i32 @incoming_only(ptr %payload, i32 %x) {
        \\entry:
        \\ %nonnull = icmp ne ptr %payload, null
        \\ br i1 %nonnull, label %present, label %absent
        \\present:
        \\ ret i32 %x
        \\absent:
        \\ ret i32 %x
        \\}
        \\define i32 @computed_fork(ptr %payload, i32 %x) {
        \\entry:
        \\ %nonnull = icmp ne ptr %payload, null
        \\ %value = xor i32 %x, 17
        \\ br i1 %nonnull, label %present, label %absent
        \\present:
        \\ ret i32 %value
        \\absent:
        \\ ret i32 %value
        \\}
        \\define i32 @computed_linear(i32 %x) {
        \\entry:
        \\ %value = xor i32 %x, 17
        \\ br label %next
        \\next:
        \\ ret i32 %value
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    for (module.functions.items, [_]usize{ 0, 1, 0 }) |function, slots| {
        var plan = try planning.buildSelectorAllocationPlan(std.testing.allocator, function);
        defer plan.deinit();
        try std.testing.expectEqual(slots, plan.preservation_spill_slots);
        try std.testing.expectEqual(slots != 0, plan.preservation_values.contains("value"));
        try std.testing.expect(!plan.preservation_values.contains("x"));
    }
}
