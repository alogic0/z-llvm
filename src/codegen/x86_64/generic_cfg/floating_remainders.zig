//! Ordinary frem uses LLVM22's GNU libm names and exact half promotion.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const math = @import("extended_math_intrinsics.zig");
fn symbol(ty: ir.Type) ?[]const u8 {
    return switch (ty) {
        .half, .float => "fmodf",
        .double => "fmod",
        .x86_fp80 => "fmodl",
        .fp128 => "fmodf128",
        else => null,
    };
}
fn operand(value: ir.Value) bool {
    return switch (value) {
        .named => !std.mem.startsWith(u8, value.named, "@"),
        .fp, .undef, .poison, .zero_initializer => true,
        else => false,
    };
}
fn stable(value: ir.Value) ir.Value {
    return switch (value) {
        .undef, .poison, .zero_initializer => .{ .fp = "0.000000e+00" },
        else => value,
    };
}
pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .binary and inst.kind.binary.op == .frem) if (symbol(inst.kind.binary.ty)) |callee| {
                const binary = inst.kind.binary;
                if (operand(binary.lhs) and operand(binary.rhs) and !math.recursive(function, callee, context) and math.resultUsed(function, inst.result.?)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const half = binary.ty == .half;
                    const ty: ir.Type = if (half) .float else binary.ty;
                    var call: ir.CallInst = .{ .callee = callee, .ret_ty = ty, .args = .empty };
                    for ([_]ir.Value{ binary.lhs, binary.rhs }) |source| {
                        var value = stable(source);
                        if (half) {
                            value = try @import("binary128_arithmetic.zig").materializeHalfArgument(allocator, function, &block, &names, value);
                        }
                        try call.args.append(allocator, .{ .ty = ty, .value = value });
                    }
                    const name = if (half) try forms.temporary(allocator, function, &names) else inst.result.?;
                    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .call = call } });
                    if (half) try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .cast = .{ .op = .fptrunc, .from_ty = .float, .value = .{ .named = name }, .to_ty = .half } } });
                    continue;
                }
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}

test "floating remainders use exact GNU symbols and preserve immutable source" {
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }, [_][]const u8{ "fmodf", "fmodf", "fmod", "fmodl", "fmodf128" }) |ty, expected| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {s} @bridge({s} %a,{s} %b) {{\nentry:\n %r = frem {s} %a,%b\n ret {s} %r\n}}\n", .{ ty, ty, ty, ty, ty });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const source = module.functions.items[0];
        const rewritten = (try legalize(arena.allocator(), source, null)).?;
        var calls: usize = 0;
        for (rewritten.blocks.items[0].instructions.items) |inst| if (inst.kind == .call) {
            try std.testing.expectEqualStrings(expected, inst.kind.call.callee);
            try std.testing.expectEqual(@as(usize, 2), inst.kind.call.args.items.len);
            calls += 1;
        };
        try std.testing.expectEqual(@as(usize, 1), calls);
        try std.testing.expect(source.blocks.items[0].instructions.items[0].kind == .binary);
        try std.testing.expect((try legalize(arena.allocator(), rewritten, null)) == null);
    }
}

test "floating remainders reject direct and aliased recursive outlining" {
    for ([_][]const u8{ "fmodl", "\"\\66modl\"", "implementation" }) |name| {
        const aliases = if (std.mem.eql(u8, name, "implementation")) "@fmodl = alias x86_fp80(x86_fp80,x86_fp80),ptr @implementation\n" else "";
        const text = try std.fmt.allocPrint(std.testing.allocator, "{s}define x86_fp80 @{s}(x86_fp80 %a,x86_fp80 %b) {{\nentry:\n %r = frem x86_fp80 %a,%b\n ret x86_fp80 %r\n}}\n", .{ aliases, name });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .aliases = module.aliases.items, .target_datalayout = module.target_datalayout };
        try std.testing.expect((try legalize(arena.allocator(), module.functions.items[0], &context)) == null);
    }
}
