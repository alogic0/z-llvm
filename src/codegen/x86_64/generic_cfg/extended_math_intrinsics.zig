//! Linux GNU libm calls matching LLVM22's ordinary extended math lowering.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const sysv = @import("../sysv_abi.zig");
pub const operations = [_][]const u8{ "trunc", "round", "ceil", "floor", "log10", "log2", "log", "exp2", "exp", "tan", "cos", "sin", "sqrt", "fma" };
const widths = [_]usize{ 80, 128, 32, 64 };
const library_names: [4][operations.len][]const u8 = names: {
    @setEvalBranchQuota(30000);
    var result: [4][operations.len][]const u8 = undefined;
    for ([_][]const u8{ "l", "f128", "f", "" }, 0..) |suffix, format_index| for (operations, 0..) |name, index| {
        result[format_index][index] = std.fmt.comptimePrint("{s}{s}", .{ name, suffix });
    };
    break :names result;
};
fn format(ty: ir.Type) ?usize {
    return switch (ty) {
        .x86_fp80 => 0,
        .fp128 => 1,
        .float => 2,
        .double => 3,
        else => null,
    };
}

fn advisory(attrs: ?[]const u8) bool {
    return attrs == null or std.mem.eql(u8, std.mem.trim(u8, attrs.?, " \t"), "noundef");
}
fn operation(call: ir.CallInst) ?usize {
    const format_index = format(call.ret_ty) orelse return null;
    if (call.callee_value != null or
        call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.calling_conv != null or !advisory(call.ret_attrs)) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    var spelling: [64]u8 = undefined;
    for (operations, 0..) |name, index| {
        if (format_index != 1 and std.mem.eql(u8, name, "sqrt")) continue;
        const intrinsic = std.fmt.bufPrint(&spelling, "llvm.{s}.f{d}", .{ name, widths[format_index] }) catch unreachable;
        if (!ir.identifiers.eql(call.callee, intrinsic)) continue;
        if (call.args.items.len != (if (std.mem.eql(u8, name, "fma")) @as(usize, 3) else 1)) return null;
        for (call.args.items) |arg| {
            if (!arg.ty.eql(call.ret_ty) or !advisory(arg.attrs)) return null;
            switch (arg.value) {
                .named => if (std.mem.startsWith(u8, arg.value.named, "@")) return null,
                .fp, .undef, .poison, .zero_initializer => {},
                else => return null,
            }
        }
        return index;
    }
    return null;
}

fn recursive(function: ir.Function, symbol: []const u8, context: ?*const machine.ReadOnlyModuleContext) bool {
    var current = symbol;
    const aliases = if (context) |ctx| ctx.aliases else &.{};
    for (0..aliases.len + 1) |_| {
        if (ir.identifiers.eql(current, function.name)) return true;
        var next: ?[]const u8 = null;
        for (aliases) |alias| if (ir.identifiers.eql(alias.name, current)) {
            if (next != null) return true;
            next = alias.target;
        };
        current = next orelse return false;
    }
    return true;
}

const Use = struct {
    pub const Error = error{};
    name: []const u8,
    found: *bool,
    pub fn visit(self: Use, value: *const ir.Value, _: ir.Type) Error!void {
        if (value.* == .named and ir.identifiers.eql(value.named, self.name)) self.found.* = true;
    }
};
fn used(function: ir.Function, name: []const u8) bool {
    var found = false;
    const visitor: Use = .{ .name = name, .found = &found };
    for (function.blocks.items) |block| {
        for (block.instructions.items) |*inst| if (!inst.removed) {
            _ = ir.operands.instruction(inst, visitor) catch unreachable;
        };
        if (block.terminator) |term| _ = ir.operands.terminator(&term, visitor) catch unreachable;
    }
    return found;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .call) if (operation(inst.kind.call)) |index| {
                // Machine relocations outlive the selector's private arena.
                const callee = library_names[format(inst.kind.call.ret_ty).?][index];
                if (!recursive(function, callee, context) and used(function, inst.result.?)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind.call.callee = callee;
                    copy.kind.call.ret_attrs = null;
                    copy.kind.call.tail_kind = null;
                    copy.kind.call.attrs = null;
                    copy.kind.call.args = try inst.kind.call.args.clone(allocator);
                    for (copy.kind.call.args.items) |*arg| arg.attrs = null;
                    copy.metadata = null;
                    try block.instructions.append(allocator, copy);
                    continue;
                }
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}

test "extended math mappings retain source signatures and use LLVM GNU library names" {
    for ([_][]const u8{ "x86_fp80", "fp128", "float", "double" }, widths, [_][]const u8{ "l", "f128", "f", "" }) |ty, bits, suffix| for (operations) |name| {
        if (bits != 128 and std.mem.eql(u8, name, "sqrt")) continue;
        const args = if (std.mem.eql(u8, name, "fma")) try std.fmt.allocPrint(std.testing.allocator, "{s} noundef %a,{s} noundef %b,{s} noundef %c", .{ ty, ty, ty }) else try std.fmt.allocPrint(std.testing.allocator, "{s} noundef %a", .{ty});
        defer std.testing.allocator.free(args);
        const declaration = if (std.mem.eql(u8, name, "fma")) try std.fmt.allocPrint(std.testing.allocator, "{s},{s},{s}", .{ ty, ty, ty }) else try std.testing.allocator.dupe(u8, ty);
        defer std.testing.allocator.free(declaration);
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare {s} @llvm.{s}.f{d}({s})\ndefine {s} @bridge({s} %a,{s} %b,{s} %c) {{\nentry:\n %r = tail call noundef {s} @llvm.{s}.f{d}({s})\n ret {s} %r\n}}\n", .{ ty, name, bits, declaration, ty, ty, ty, ty, ty, name, bits, args, ty });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const private = (try legalize(arena.allocator(), original, null)).?;
        const call = private.blocks.items[0].instructions.items[0].kind.call;
        const expected = try std.fmt.allocPrint(std.testing.allocator, "{s}{s}", .{ name, suffix });
        defer std.testing.allocator.free(expected);
        try std.testing.expectEqualStrings(expected, call.callee);
        try std.testing.expect(call.tail_kind == null and call.ret_attrs == null and call.args.items[0].attrs == null);
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.call.tail_kind != null);
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.call.args.items[0].attrs != null);
        try std.testing.expect((try legalize(arena.allocator(), private, null)) == null);
    };
}

test "extended math relocation names outlive private selector storage" {
    const text = "target datalayout = \"e-i128:128-f80:128\"\ndeclare x86_fp80 @llvm.sin.f80(x86_fp80)\ndefine void @bridge(ptr %input,ptr %output) {\nentry:\n %a = load x86_fp80,ptr %input,align 1\n %r = call x86_fp80 @llvm.sin.f80(x86_fp80 %a)\n store x86_fp80 %r,ptr %output,align 1\n ret void\n}\n";
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var output = machine.MachineFunction.init("bridge", .void);
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(@import("../generic_cfg_selector.zig").SelectionResult.selected, try @import("../generic_cfg_selector.zig").tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context));
    for (output.instructions.items) |instruction| if (instruction == .direct_call) try std.testing.expectEqualStrings("sinl", instruction.direct_call.symbol);
    const object = try @import("../../../mc/elf.zig").buildObject(std.testing.allocator, &.{output});
    defer std.testing.allocator.free(object);
    try std.testing.expect(std.mem.indexOf(u8, object, "sinl\x00") != null);
}

test "extended math library mapping rejects wrong signatures effects and unused results" {
    for ([_][]const u8{
        "musttail call x86_fp80 @llvm.sin.f80(x86_fp80 %a)",
        "call fastcc x86_fp80 @llvm.sin.f80(x86_fp80 %a)",
        "call x86_fp80 @llvm.sin.f80(float 0.0)",
        "call x86_fp80 @llvm.sin.f80(x86_fp80 inreg %a)",
        "call x86_fp80 @llvm.fma.f80(x86_fp80 %a)",
        "call x86_fp80 @llvm.sqrt.f80(x86_fp80 %a)",
        "call x86_fp80 @llvm.experimental.constrained.sin.f80(x86_fp80 %a)",
    }) |expression| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define x86_fp80 @closed(x86_fp80 %a) {{\nentry:\n %r = {s}\n ret x86_fp80 %r\n}}\n", .{expression});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, "define x86_fp80 @unused(x86_fp80 %a) {\nentry:\n %r = call x86_fp80 @llvm.sin.f80(x86_fp80 %a)\n ret x86_fp80 %a\n}\n");
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect((try legalize(arena.allocator(), module.functions.items[0], null)) == null);
}

test "extended math library mapping closes direct and aliased recursive helper bodies" {
    const cases = [_]struct { name: []const u8, aliases: []const u8 }{
        .{ .name = "sinl", .aliases = "" },
        .{ .name = "\"\\73inl\"", .aliases = "" },
        .{ .name = "impl", .aliases = "@sinl = alias x86_fp80(x86_fp80),ptr @impl\n" },
        .{ .name = "impl", .aliases = "@sinl = alias x86_fp80(x86_fp80),ptr @middle\n@middle = alias x86_fp80(x86_fp80),ptr @impl\n" },
        .{ .name = "impl", .aliases = "@sinl = alias x86_fp80(x86_fp80),ptr @middle\n@middle = alias x86_fp80(x86_fp80),ptr @sinl\n" },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "{s}define x86_fp80 @{s}(x86_fp80 %a) {{\nentry:\n %r = call x86_fp80 @llvm.sin.f80(x86_fp80 %a)\n ret x86_fp80 %r\n}}\n", .{ case.aliases, case.name });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout, .aliases = module.aliases.items };
        try std.testing.expect((try legalize(arena.allocator(), module.functions.items[0], &context)) == null);
    }
}
