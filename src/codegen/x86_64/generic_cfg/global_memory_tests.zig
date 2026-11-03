const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const elf = @import("../../../mc/elf.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const global_memory = @import("global_memory.zig");
const support = @import("value_use/test_support.zig");

test "symbolic address definition preserves live accumulator values and flags" {
    var output = support.MachineFunction.init("global-address-definition", .ptr);
    defer output.deinit(std.testing.allocator);
    var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try support.addLive(&plan, "witness");
    try support.addLive(&plan, "address");
    var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
    defer state.deinit();
    state.allocation_plan = &plan;
    state.current_position = 1;
    state.stack_frame_bytes = 128;
    try support.selector_state.bindValueLoc(&state, "witness", .rax);
    try support.selector_state.emitEflagsInstruction(&state, .{ .cmp_eax_imm32 = 7 }, .definition);
    const flags = state.eflags.snapshot();
    const witness = state.values.get("witness").?;
    try std.testing.expect(try support.selector_state.defineGlobalAddress(&state, "address", .{ .symbol = "object", .addend = -8 }) == null);
    try state.eflags.validateSnapshot(flags);
    try std.testing.expectEqual(witness.vreg, state.values.get("witness").?.vreg);
    try std.testing.expect(state.values.get("witness").?.loc != .rax);
    try std.testing.expect(state.values.get("address").?.loc == .rax);
}

test "symbolic address encoding uses a single flag-preserving RIP-relative LEA" {
    var output = machine.MachineFunction.init("address-encoding", .ptr);
    defer output.deinit(std.testing.allocator);
    try output.instructions.append(std.testing.allocator, .{ .lea_global_offset_rax = .{ .symbol = "object", .addend = std.math.minInt(i32) } });
    try output.instructions.append(std.testing.allocator, .ret);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0x48, 0x8d, 0x05, 0, 0, 0, 0, 0xc3 }, bytes);
    const object = try elf.buildObject(std.testing.allocator, &.{output});
    defer std.testing.allocator.free(object);
    const shoff = std.mem.readInt(u64, object[40..48], .little);
    const rela_offset = std.mem.readInt(u64, object[shoff + 4 * 64 + 24 ..][0..8], .little);
    try std.testing.expectEqual(@as(u64, 3), std.mem.readInt(u64, object[rela_offset..][0..8], .little));
    try std.testing.expectEqual(@as(i64, std.math.minInt(i32)) - 4, std.mem.readInt(i64, object[rela_offset + 16 ..][0..8], .little));
}

test "global address fixture keeps composed ownership and emits data relocations" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/global_addresses.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var functions: std.ArrayList(machine.MachineFunction) = .empty;
    defer {
        for (functions.items) |*function| function.deinit(std.testing.allocator);
        functions.deinit(std.testing.allocator);
    }
    for (module.functions.items) |function| {
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        errdefer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("global address selection {s}: {s}\n", .{ function.name, diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        try verify.verifyFunction(lowered);
        try std.testing.expect(lowered.selection_owner == .composed_block or lowered.selection_owner == .composed_cfg);
        try functions.append(std.testing.allocator, lowered);
    }
    const object = try elf.buildObjectWithModuleContext(std.testing.allocator, functions.items, &.{}, ctx);
    defer std.testing.allocator.free(object);
    const shoff = std.mem.readInt(u64, object[40..48], .little);
    try std.testing.expectEqual(@as(u16, 9), std.mem.readInt(u16, object[60..62], .little));
    const data_header = object[shoff + 2 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u64, 64), std.mem.readInt(u64, data_header[48..56], .little));
    const sym_header = object[shoff + 5 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u32, 4), std.mem.readInt(u32, sym_header[44..48], .little));
    const rela_header = object[shoff + 8 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u32, 2), std.mem.readInt(u32, rela_header[44..48], .little));
    try std.testing.expectEqual(@as(u64, 48), std.mem.readInt(u64, rela_header[32..40], .little));
    try std.testing.expect(std.mem.indexOf(u8, object, "must_not_be_imported") == null);
}

test "referenced unsupported globals fail instead of becoming external imports" {
    const source = "@bad = internal global double 0.0\n@ignored = global { ptr } { ptr @missing }";
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var output = machine.MachineFunction.init("bad-address", .ptr);
    defer output.deinit(std.testing.allocator);
    try output.instructions.append(std.testing.allocator, .{ .lea_global_offset_rax = .{ .symbol = "bad" } });
    try output.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.UnsupportedGlobalData, elf.buildObjectWithModuleContext(std.testing.allocator, &.{output}, &.{}, ctx));
    module.globals.items[0].ty = .{ .aggregate = "[0 x i8]" };
    module.globals.items[0].initializer = .{ .scalar = .zero_initializer };
    try std.testing.expectError(error.UnsupportedGlobalData, elf.buildObjectWithModuleContext(std.testing.allocator, &.{output}, &.{}, ctx));
}

test "global memory legalization is private idempotent and avoids SSA name collisions" {
    const source =
        \\@object = internal global [16 x i8] zeroinitializer, align 1
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define ptr @copy(ptr %__zllvm_global_0) {
        \\entry:
        \\ %__zllvm_global_1 = getelementptr i8, ptr %__zllvm_global_0, i64 1
        \\ call void @llvm.memcpy.p0.p0.i64(ptr @object, ptr %__zllvm_global_1, i64 12, i1 false)
        \\ ret ptr @object
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const original = module.functions.items[0];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const normalized = (try global_memory.legalize(arena.allocator(), original, &ctx)).?;
    try std.testing.expectEqual(@as(usize, 2), original.blocks.items[0].instructions.items.len);
    try std.testing.expectEqualStrings("@object", original.blocks.items[0].instructions.items[1].kind.call.args.items[0].value.named);
    try std.testing.expectEqualStrings("@object", original.blocks.items[0].terminator.?.ret.value.?.named);
    try std.testing.expectEqualStrings("__zllvm_global_2", normalized.blocks.items[0].instructions.items[1].result.?);
    try std.testing.expectEqualStrings("__zllvm_global_3", normalized.blocks.items[0].terminator.?.ret.value.?.named);
    try std.testing.expect(try global_memory.legalize(arena.allocator(), normalized, &ctx) == null);
    var lowered = machine.MachineFunction.init(original.name, original.ret_ty);
    defer lowered.deinit(std.testing.allocator);
    try std.testing.expect(try selector.tryLowerWithContext(std.testing.allocator, &lowered, original, &ctx) == .selected);
    // The temporary legalization arena is already gone at this point. ELF
    // must still read a module-owned symbol, including normalized returns.
    const object = try elf.buildObjectWithModuleContext(std.testing.allocator, &.{lowered}, &.{}, ctx);
    defer std.testing.allocator.free(object);
    try std.testing.expect(std.mem.indexOf(u8, object, "object") != null);
}

test "immediate memcpy lengths execute zero and bounded copies with dying ABI operands" {
    const counts = [_]usize{ 0, 1, 2, 12, 16, 80 };
    const lives = [_]u64{ 0, 1, 4294967295, 4294967296, 0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff };
    for (counts) |count| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i64 @copy(ptr %destination, ptr %source, i64 %live) {{\nentry:\n call void @llvm.memcpy.p0.p0.i64(ptr %destination, ptr %source, i64 {d}, i1 false)\n ret i64 %live\n}}\n", .{count});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var lowered = machine.MachineFunction.init("copy", .{ .int = 64 });
        defer lowered.deinit(std.testing.allocator);
        try std.testing.expect(try selector.tryLower(std.testing.allocator, &lowered, module.functions.items[0]) == .selected);
        try verify.verifyFunction(lowered);
        const code = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(code);
        const executable = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..code.len], code);
        const run: *const fn (?*anyopaque, ?*const anyopaque, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        var input: [96]u8 = undefined;
        for (&input, 0..) |*byte, index| byte.* = @truncate(index * 37 + 129);
        for (lives) |live| {
            var output: [112]u8 = @splat(165);
            try std.testing.expectEqual(live, if (count == 0) run(null, null, live) else run(&output[8], &input, live));
            for (output, 0..) |byte, index| try std.testing.expectEqual(if (index >= 8 and index < 8 + count) input[index - 8] else @as(u8, 165), byte);
        }
    }
}

test "immediate memcpy rollback restores dying source preservation at all failure boundaries" {
    inline for (std.meta.tags(support.Transaction.MemcpyTestFailure)) |failure| {
        var output = machine.MachineFunction.init("copy-rollback", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addAtCurrent(&plan, "destination");
        try support.addAtCurrent(&plan, "source");
        try support.addLive(&plan, "witness");
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "destination", .{ .arg64 = .r8 });
        try support.selector_state.bindValueLoc(&state, "source", .{ .arg64 = .rdi });
        try support.selector_state.bindValueLoc(&state, "witness", .{ .arg64 = .rcx });
        const destination = state.values.get("destination").?;
        const source = state.values.get("source").?;
        const witness = state.values.get("witness").?;
        const next_virtual_reg = state.next_virtual_reg;
        const next_spill_slot = state.next_spill_slot;
        const flags = state.eflags.snapshot();
        const dependencies = state.address_dependencies;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const source_request = try transaction.register(.{ .source = .{ .named = "source" }, .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 }, .form = .memcpy_pointer, .destination = .prepared_source });
        const destination_request = try transaction.register(.{ .source = .{ .named = "destination" }, .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 }, .form = .memcpy_pointer, .destination = .prepared_view, .prepared_action = .{ .inline_memcpy = .{ .source = source_request, .length_immediate = 80 } } });
        try transaction.setMemcpyTestFailure(failure);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(error.ValueUseMemcpyTestFailure, transaction.executePreparedAction(try transaction.preparedView(destination_request)));
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(destination, state.values.get("destination").?);
        try std.testing.expectEqual(source, state.values.get("source").?);
        try std.testing.expectEqual(witness, state.values.get("witness").?);
        try std.testing.expectEqual(next_virtual_reg, state.next_virtual_reg);
        try std.testing.expectEqual(next_spill_slot, state.next_spill_slot);
        try std.testing.expectEqual(@as(usize, 0), state.spill_slots.count());
        try std.testing.expect(state.address_dependencies.eql(&dependencies));
        try state.eflags.validateSnapshot(flags);
    }
}

test "global ELF emission releases partial objects after allocation failures" {
    const Test = struct {
        fn run(allocator: std.mem.Allocator) !void {
            var module = try ir.Module.parse(allocator, "@object = internal global { ptr, i64 } { ptr @leaf, i64 4294967295 }, align 64\n@leaf = private constant [4 x i8] c\"A\\00BC\", align 1");
            defer module.deinit();
            var output = machine.MachineFunction.init("get-object", .ptr);
            defer output.deinit(allocator);
            try output.instructions.append(allocator, .{ .lea_global_offset_rax = .{ .symbol = "object" } });
            try output.instructions.append(allocator, .ret);
            const object = try elf.buildObjectWithModuleContext(allocator, &.{output}, &.{}, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout });
            defer allocator.free(object);
        }
    };
    try std.testing.checkAllAllocationFailures(std.testing.allocator, Test.run, .{});
}

test "global scalar stores use the address authority for narrow constants and runtime bytes" {
    const source =
        \\@object = internal global [32 x i8] zeroinitializer, align 8
        \\define void @store(i8 zeroext %byte) {
        \\entry:
        \\ store i16 0, ptr getelementptr inbounds (i8, ptr @object, i64 8), align 2
        \\ store i8 %byte, ptr getelementptr inbounds (i8, ptr @object, i64 17), align 1
        \\ ret void
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var output = machine.MachineFunction.init("store", .void);
    defer output.deinit(std.testing.allocator);
    switch (try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &ctx)) {
        .selected => try verify.verifyFunction(output),
        .unsupported => |diagnostic| {
            std.debug.print("global scalar store: {s}\n", .{diagnostic.detail()});
            return error.TestUnexpectedResult;
        },
    }
}

test "global ELF placement honors explicit low alignment and symbol visibility" {
    const source =
        \\@lead = internal global i8 123, align 1
        \\@low = private global i64 4294967295, align 1
        \\@hidden = hidden global i64 1, align 32
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var function = machine.MachineFunction.init("addresses", .ptr);
    defer function.deinit(std.testing.allocator);
    for ([_][]const u8{ "lead", "low", "hidden" }) |name|
        try function.instructions.append(std.testing.allocator, .{ .lea_global_offset_rax = .{ .symbol = name } });
    try function.instructions.append(std.testing.allocator, .ret);
    const object = try elf.buildObjectWithModuleContext(std.testing.allocator, &.{function}, &.{}, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout });
    defer std.testing.allocator.free(object);
    const shoff = std.mem.readInt(u64, object[40..48], .little);
    const data_header = object[shoff + 2 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u64, 32), std.mem.readInt(u64, data_header[48..56], .little));
    const sym_header = object[shoff + 5 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u32, 3), std.mem.readInt(u32, sym_header[44..48], .little));
    const symbols = std.mem.readInt(u64, sym_header[24..32], .little);
    try std.testing.expectEqual(@as(u8, 0x01), object[symbols + 1 * 24 + 4]);
    try std.testing.expectEqual(@as(u8, 0x01), object[symbols + 2 * 24 + 4]);
    try std.testing.expectEqual(@as(u64, 1), std.mem.readInt(u64, object[symbols + 2 * 24 + 8 ..][0..8], .little));
    try std.testing.expectEqual(@as(u8, 0x11), object[symbols + 4 * 24 + 4]);
    try std.testing.expectEqual(@as(u8, 2), object[symbols + 4 * 24 + 5]);
    try std.testing.expectEqual(@as(u64, 32), std.mem.readInt(u64, object[symbols + 4 * 24 + 8 ..][0..8], .little));
    const rela_header = object[shoff + 4 * 64 ..][0..64];
    const relocations = std.mem.readInt(u64, rela_header[24..32], .little);
    for ([_]u32{ 1, 2, 4 }, 0..) |index, position| {
        const info = std.mem.readInt(u64, object[relocations + position * 24 + 8 ..][0..8], .little);
        try std.testing.expectEqual(index, @as(u32, @intCast(info >> 32)));
    }
}

test "global pointer reference cycles emit one definition per symbol" {
    var module = try ir.Module.parse(std.testing.allocator, "@left = internal global ptr @right, align 8\n@right = private constant ptr @left, align 8");
    defer module.deinit();
    var function = machine.MachineFunction.init("cycle", .ptr);
    defer function.deinit(std.testing.allocator);
    try function.instructions.append(std.testing.allocator, .{ .lea_global_offset_rax = .{ .symbol = "left" } });
    try function.instructions.append(std.testing.allocator, .ret);
    const object = try elf.buildObjectWithModuleContext(std.testing.allocator, &.{function}, &.{}, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout });
    defer std.testing.allocator.free(object);
    const shoff = std.mem.readInt(u64, object[40..48], .little);
    const data_header = object[shoff + 2 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u64, 16), std.mem.readInt(u64, data_header[32..40], .little));
    const rela_header = object[shoff + 8 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u64, 48), std.mem.readInt(u64, rela_header[32..40], .little));
    const relocations = std.mem.readInt(u64, rela_header[24..32], .little);
    for ([_]u32{ 2, 1 }, 0..) |symbol, index| {
        try std.testing.expectEqual(@as(u64, @intCast(index * 8)), std.mem.readInt(u64, object[relocations + index * 24 ..][0..8], .little));
        const info = std.mem.readInt(u64, object[relocations + index * 24 + 8 ..][0..8], .little);
        try std.testing.expectEqual(@as(u64, symbol) << 32 | 1, info);
    }
}

test "global return legalization preserves existing floating and empty object paths" {
    for ([_][]const u8{
        "@object = private constant fp128 0xL00000000000000000000000000000000, align 16",
        "@object = private constant [0 x i8] zeroinitializer, align 1",
        "@object = private constant [16 x double] [double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0, double 0.0], align 8",
    }) |definition| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-p:64:64-i64:64\"\n{s}\ndefine ptr @get() {{\nentry:\n ret ptr @object\n}}\n", .{definition});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        try std.testing.expect(try global_memory.legalize(arena.allocator(), module.functions.items[0], &context) == null);
    }
}

test "named memcpy staging preserves a dying length in RSI before source writes" {
    const source =
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define i64 @copy(i64 %a, i64 %length, i64 %b, ptr %destination, ptr %source, i64 %live) {
        \\entry:
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %destination, ptr %source, i64 %length, i1 false)
        \\ %first = xor i64 %a, %live
        \\ %result = xor i64 %first, %b
        \\ ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("copy", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    try std.testing.expect(try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]) == .selected);
    try verify.verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const executable = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(executable);
    @memcpy(executable[0..code.len], code);
    const run: *const fn (u64, u64, u64, ?*anyopaque, ?*const anyopaque, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
    var input: [96]u8 = undefined;
    for (&input, 0..) |*byte, index| byte.* = @truncate(index * 37 + 129);
    for ([_]usize{ 0, 1, 2, 12, 16, 80 }) |count| {
        for ([_]u64{ 0, 1, 4294967295, 4294967296, 0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff }) |live| {
            var destination: [112]u8 = @splat(165);
            const a: u64 = live +% 127;
            const b: u64 = live ^ 0xdead_beef_0123_4567;
            try std.testing.expectEqual(a ^ live ^ b, if (count == 0) run(a, 0, b, null, null, live) else run(a, count, b, &destination[8], &input, live));
            for (destination, 0..) |byte, index| try std.testing.expectEqual(if (index >= 8 and index < 8 + count) input[index - 8] else @as(u8, 165), byte);
            for (input, 0..) |byte, index| try std.testing.expectEqual(@as(u8, @truncate(index * 37 + 129)), byte);
        }
    }
}
