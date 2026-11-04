const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const frames = @import("padded_frame.zig");
const pairs = @import("word_pair_memory.zig");
const support = @import("value_use/test_support.zig");

fn fixture() ![]u8 {
    return std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/bounded_frame.ll", std.testing.allocator, .limited(1024 * 1024));
}

fn context(module: ir.Module) machine.ReadOnlyModuleContext {
    return .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
}

test "bounded frame complete shapes reject packing padding tails unresolved and cyclic names" {
    const names = [_]ir.NamedTypeDefinition{
        .{ .name = "Words", .body = "{ i64, i64 }", .raw = "" },
        .{ .name = "\"Padded\"", .body = "{ %Words, i16, [6 x i8] }", .raw = "" },
        .{ .name = "Cycle", .body = "{ %Cycle }", .raw = "" },
        .{ .name = "Duplicate", .body = "{ i64, i64 }", .raw = "" },
        .{ .name = "\"Duplicate\"", .body = "{ i64, i64, i8 }", .raw = "" },
    };
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &names, .target_datalayout = null };
    try std.testing.expectEqual(@as(?u32, 16), frames.size(&ctx, .{ .aggregate = "{ { i64, i16, [6 x i8] } }" }, 0));
    try std.testing.expectEqual(@as(?u32, 24), frames.size(&ctx, .{ .aggregate = "%Padded" }, 0));
    try std.testing.expectEqual(@as(?u32, 24), frames.size(&ctx, .{ .aggregate = "{ { { i64, i64 } }, i16, [6 x i8] }" }, 0));
    for ([_][]const u8{
        "{ i64, i16, [6 x i8], %Missing }", "{ i64, i16, [6 x i8], }",             "{ i64, i16, [6 x i8] } junk",
        "{ i64, i16, [6 x i8]",             "<{ i64, i16, [6 x i8] }>",            "{ i64, i16, [7 x i8] }",
        "{ double, i16, [6 x i8] }",        "{ <2 x i64>, i16, [6 x i8] }",        "{ { ptr, i64 }, i16, [6 x i8] }",
        "{ %Missing, i16, [6 x i8] }",      "{ %Duplicate, i16, [6 x i8] }",       "%Cycle",
        "%Missing",                         "[3 x i64]",                           "{ i64, i16 }",
        "{ i64, i32, [4 x i8] }",           "{ ptr addrspace(1), i16, [6 x i8] }",
    }) |text| try std.testing.expect(frames.size(&ctx, .{ .aggregate = text }, 0) == null);
    try std.testing.expect(!pairs.isIntegerPair(&ctx, .{ .aggregate = "%Duplicate" }));
    try std.testing.expect(!pairs.isIntegerPair(&ctx, .{ .aggregate = "%Cycle" }));
}

test "bounded frame layouts reject incompatible integer aggregate and pointer allocation" {
    const bytes = try fixture();
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    var ctx = context(module);
    for ([_][]const u8{
        "",          "E-p:64:64-i64:64", "e-p:32:32",      "e-A1",            "e-G1",    "e-P1",    "e-ni:0",
        "e-i64:128", "e-i16:32",         "e-i8:16",        "e-i32:64",        "e-a:128", "e-a:256", "e-a:7",
        "e-a:64:32", "e-a:64:garbage",   "e-a:64:128:256", "e-p:64:64:64:32",
    }) |layout| {
        ctx.target_datalayout = layout;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try frames.legalize(arena.allocator(), module.functions.items[1], &ctx) == null);
    }
    for ([_]?[]const u8{ null, "e", "e-p:64:64-i64:64-a:0:64", "e-a:64:128" }) |layout| {
        ctx.target_datalayout = layout;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try frames.legalize(arena.allocator(), module.functions.items[1], &ctx) != null);
    }
}

test "bounded frame legalization preserves borrowed lists and is idempotent" {
    const bytes = try fixture();
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    const ctx = context(module);
    for (module.functions.items, 0..) |function, index| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const first_view = (if (index == 0)
            try pairs.legalize(arena.allocator(), function, &ctx)
        else
            try frames.legalize(arena.allocator(), function, &ctx)).?;
        const converted = if (index == 0) (try frames.legalize(arena.allocator(), first_view, &ctx)).? else first_view;
        try std.testing.expect(try frames.legalize(arena.allocator(), converted, &ctx) == null);
        try std.testing.expect(try pairs.legalize(arena.allocator(), converted, &ctx) == null);
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("bounded frame selection {s}: {s}\n", .{ function.name, diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        try verify.verifyFunction(lowered);
        try std.testing.expect(lowered.selection_owner == .composed_block or lowered.selection_owner == .composed_cfg);
        for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
            if (instruction.kind == .alloca and instruction.kind.alloca.allocated_ty == .aggregate)
                try std.testing.expect(!std.mem.startsWith(u8, instruction.kind.alloca.allocated_ty.aggregate, "["));
            if (instruction.kind == .call) {
                const args = instruction.kind.call.args.items;
                try std.testing.expectEqualStrings(if (index == 3) "slot" else if (index == 0 and std.mem.eql(u8, args[1].value.named, "source")) "bridge" else "destination", args[0].value.named);
                if (index != 3) try std.testing.expectEqualStrings(if (index == 0 and std.mem.eql(u8, args[0].value.named, "destination")) "bridge" else "source", args[1].value.named);
            }
        };
    }
    try module.verify();
}

test "bounded frame legalization rejects counts attributes barriers and oversized copies" {
    const bytes = try fixture();
    defer std.testing.allocator.free(bytes);
    for (0..12) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, bytes);
        defer module.deinit();
        const ctx = context(module);
        const function = &module.functions.items[1];
        for (function.blocks.items) |*block| for (block.instructions.items) |*instruction| {
            if (instruction.kind == .alloca and instruction.kind.alloca.allocated_ty == .aggregate) {
                if (boundary == 0) instruction.kind.alloca.count = .{ .ty = .{ .int = 64 }, .value = .{ .int = 2 } };
                if (boundary == 1) instruction.kind.alloca.count = .{ .ty = .{ .int = 64 }, .value = .{ .named = "a" } };
                if (boundary == 2) instruction.kind.alloca.attrs = "align 32";
                if (boundary == 3) instruction.kind.alloca.attrs = "align 3";
                if (boundary == 4) instruction.kind.alloca.attrs = "align 8, inalloca";
                if (boundary == 5) instruction.kind.alloca.allocated_ty_addrspace = "1";
            }
            if (instruction.kind == .store and instruction.kind.store.ptr == .named and std.mem.eql(u8, instruction.kind.store.ptr.named, "source")) {
                if (boundary == 6) instruction.kind.store.attrs.is_volatile = true;
                if (boundary == 7) instruction.kind.store.ptr_addrspace = "1";
                if (boundary == 8) instruction.kind.store.attrs.atomic_ordering = "unordered";
            }
            if (instruction.kind == .call) {
                if (boundary == 9) instruction.kind.call.args.items[2].value = .{ .int = 25 };
                if (boundary == 10) instruction.kind.call.args.items[2].value = .{ .int = -1 };
                if (boundary == 11) instruction.kind.call.args.items[2].value = .{ .named = "a" };
            }
        };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try frames.legalize(arena.allocator(), function.*, &ctx) == null);
    }
}

test "bounded frame temporary names avoid quoted local and parameter collisions" {
    const bytes =
        \\define i64 @collisions(i64 %"__zllvm_padded_frame_0") {
        \\entry:
        \\  %slot = alloca { i64, i16, [6 x i8] }, align 8
        \\  %"__zllvm_padded_frame_1" = add i64 %"__zllvm_padded_frame_0", 1
        \\  store i64 %"__zllvm_padded_frame_1", ptr %slot
        \\  %value = load i64, ptr %slot
        \\  ret i64 %value
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const converted = (try frames.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expectEqualStrings("__zllvm_padded_frame_2", converted.blocks.items[0].instructions.items[2].result.?);
    try std.testing.expectEqualStrings("__zllvm_padded_frame_3", converted.blocks.items[0].instructions.items[4].result.?);
}

test "bounded frame copy lengths accept only bounded literal integer extensions" {
    const cases = [_]struct { source: []const u8, accepted: bool }{
        .{ .source = "zext i32 16 to i64", .accepted = true },
        .{ .source = "zext i32 17 to i64", .accepted = false },
        .{ .source = "zext i32 -1 to i64", .accepted = false },
        .{ .source = "zext i32 %length to i64", .accepted = false },
        .{ .source = "sext i32 16 to i64", .accepted = false },
        .{ .source = "zext i16 16 to i64", .accepted = false },
    };
    for (cases) |case| {
        const bytes = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
            \\define void @copy(ptr %output, i32 %length) {{
            \\entry:
            \\  %slot = alloca {{ i64, i16, [6 x i8] }}, align 8
            \\  %size = {s}
            \\  call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %slot, i64 %size, i1 false)
            \\  ret void
            \\}}
        , .{case.source});
        defer std.testing.allocator.free(bytes);
        var module = try ir.Module.parse(std.testing.allocator, bytes);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expectEqual(case.accepted, try frames.legalize(arena.allocator(), module.functions.items[0], null) != null);
    }
}

test "bounded frame address authority checks actual extent before emission and rolls back" {
    const cases = [_]struct { location: support.ValueLoc, extent: i32 }{
        .{ .location = .{ .stack128 = 32 }, .extent = 16 },
        .{ .location = .{ .stack_i32_array = .{ .base_disp = 32, .len = 4 } }, .extent = 16 },
        .{ .location = .{ .stack_i32_array = .{ .base_disp = 32, .len = 6 } }, .extent = 24 },
        .{ .location = .{ .stack_i32_array = .{ .base_disp = 32, .len = 8 } }, .extent = 0 },
    };
    for (cases) |case| for (0..5) |boundary| {
        var output = machine.MachineFunction.init("frame-address", .ptr);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "offset", "result" }) |name| try support.addLive(&plan, name);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "base", case.location);
        try support.selector_state.bindValueLoc(&state, "offset", .{ .arg64 = .rdi });
        const original = state.values.get("base").?;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const offset = try transaction.register(support.preparedSourceRequest("offset", .{ .int = 64 }, .gpr64, .gpr64));
        const action = try transaction.register(support.preparedRequest("base", .ptr, .stack_object, .stack_object_address, .{ .form_byte_address = .{
            .result = try support.actionIdentity("result"),
            .offset = switch (boundary) {
                0 => .{ .constant = 0 },
                1 => .{ .constant = case.extent },
                2 => .{ .constant = -1 },
                3 => .{ .constant = case.extent + 1 },
                else => .{ .request = offset },
            },
        } }));
        if (boundary < 2 and case.extent != 0) {
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            try transaction.executePreparedAction(try transaction.preparedView(action));
            try std.testing.expect(state.values.contains("result"));
            try std.testing.expect(output.instructions.items.len != 0);
            try transaction.rollback();
        } else try std.testing.expectError(error.ValueUseUnsupportedAddressForm, transaction.seal());
        try std.testing.expectEqual(original, state.values.get("base").?);
        try std.testing.expect(!state.values.contains("result"));
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    };
}
