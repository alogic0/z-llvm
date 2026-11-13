//! Private descriptions of three exact assembly forms. Source IR is immutable.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
pub const Plan = union(enum) { constant: i128, add32, barriers };
const clobbers = "~{dirflag},~{fpsr},~{flags}";
const barrier = "m,~{memory}," ++ clobbers;
fn pointerAttrs(attrs: ?[]const u8) bool {
    if (attrs == null) return true;
    const element = ir.verifyInlineAsmParameterAttrs(.ptr, attrs) catch return false;
    return element != null or @import("../sysv_abi.zig").pointerCallAttrsAreAdvisory(attrs.?);
}
pub fn classify(inst: ir.Instruction) ?Plan {
    if (inst.kind != .call) return null;
    const call = inst.kind.call;
    const assembly = call.inline_asm orelse return null;
    if (call.callee_value != null or call.callee_function_ty != null or call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null or call.native_query != null or call.va_arg) return null;
    var envelope = call;
    envelope.inline_asm = null;
    @import("../sysv_abi.zig").rejectUnsupportedCallEnvelope(envelope) catch return null;
    for (call.args.items) |arg| if (arg.abi_x87_memory or arg.abi_split_integer) return null;
    if (inst.result != null and (call.ret_ty.eql(.{ .int = 32 }) or call.ret_ty.eql(.{ .int = 64 })) and call.args.items.len == 0 and !assembly.has_memory_clobber and !assembly.may_load and !assembly.may_store and std.mem.eql(u8, assembly.constraints, "=r," ++ clobbers) and std.mem.startsWith(u8, assembly.template, "mov $$") and std.mem.endsWith(u8, assembly.template, ", ${0}")) {
        const literal = std.mem.trim(u8, assembly.template["mov $$".len .. assembly.template.len - ", ${0}".len], " \t");
        const value = std.fmt.parseInt(i128, literal, 10) catch return null;
        const minimum = -(@as(i128, 1) << @as(u7, @intCast(call.ret_ty.int - 1)));
        const maximum = (@as(i128, 1) << @as(u7, @intCast(call.ret_ty.int))) - 1;
        if (value < minimum or value > maximum) return null;
        return .{ .constant = value };
    }
    if (inst.result != null and call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 2 and !assembly.has_memory_clobber and !assembly.may_load and !assembly.may_store and std.mem.eql(u8, assembly.template, "addl ${1}, ${0}") and std.mem.eql(u8, assembly.constraints, "=r,r,0,~{flags}," ++ clobbers)) {
        for (call.args.items) |arg| if (!arg.ty.eql(.{ .int = 32 }) or arg.attrs != null or (arg.value != .named and arg.value != .int)) return null;
        return .add32;
    }
    if (inst.result != null or call.ret_ty != .void or !assembly.sideeffect or assembly.template.len != 0 or call.args.items.len == 0) return null;
    if (call.args.items.len == 1 and call.args.items[0].ty == .ptr and call.args.items[0].attrs == null and std.mem.eql(u8, assembly.constraints, barrier)) return null;
    var constraints = std.mem.splitScalar(u8, assembly.constraints, ',');
    var pointers: usize = 0;
    for (call.args.items) |arg| {
        const operand = constraints.next() orelse return null;
        if (arg.ty == .ptr) {
            if (arg.value != .named or !pointerAttrs(arg.attrs)) return null;
            if (!std.mem.eql(u8, operand, "m") and !std.mem.eql(u8, operand, "*m") and !std.mem.eql(u8, operand, "=*m|r") and !std.mem.eql(u8, operand, "=*r|m") and !std.mem.eql(u8, operand, "r|m") and !std.mem.eql(u8, operand, "m|r")) return null;
            pointers += 1;
        } else {
            if ((!arg.ty.eql(.{ .int = 32 }) and !arg.ty.eql(.{ .int = 64 })) or arg.attrs != null or (arg.value != .named and arg.value != .int)) return null;
            if (!std.mem.eql(u8, operand, "r") and !std.mem.eql(u8, operand, "r|m") and !std.mem.eql(u8, operand, "m|r")) return null;
        }
    }
    if (pointers == 0) return null;
    while (constraints.next()) |constraint| if (!std.mem.eql(u8, constraint, "~{memory}") and !std.mem.eql(u8, constraint, "~{dirflag}") and !std.mem.eql(u8, constraint, "~{fpsr}") and !std.mem.eql(u8, constraint, "~{flags}")) return null;
    return .barriers;
}
pub fn lower(a: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, names: *forms.TemporaryNames, inst: ir.Instruction, plan: Plan) !void {
    const call = inst.kind.call;
    switch (plan) {
        .constant => |value| try block.instructions.append(a, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .binary = .{ .op = .add, .ty = call.ret_ty, .lhs = .{ .int = value }, .rhs = .{ .int = 0 } } } }),
        .add32 => try block.instructions.append(a, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .binary = .{ .op = .add, .ty = .{ .int = 32 }, .lhs = call.args.items[1].value, .rhs = call.args.items[0].value } } }),
        .barriers => for (call.args.items) |arg| {
            if (arg.ty != .ptr) continue;
            var value = arg.value;
            if (std.mem.startsWith(u8, value.named, "@")) {
                const name = try forms.temporary(a, function, names);
                var gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = value, .indices = .empty };
                try gep.indices.append(a, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
                try block.instructions.append(a, .{ .result = name, .kind = .{ .gep = gep } });
                value = .{ .named = name };
            }
            var copy = inst;
            copy.kind.call.tail_kind = null;
            copy.kind.call.args = .empty;
            copy.kind.call.inline_asm = .{ .template = "", .constraints = barrier, .sideeffect = true, .has_memory_clobber = true, .may_load = true, .may_store = true };
            try copy.kind.call.args.append(a, .{ .ty = .ptr, .value = value });
            try block.instructions.append(a, copy);
        },
    }
}

test "bounded assembly register forms preserve complete live scalar inputs" {
    const a = std.testing.allocator;
    for (0..2) |kind| {
        const operation = if (kind == 0) " %v = call i32 asm sideeffect \"mov $$123, ${0}\", \"=r,~{dirflag},~{fpsr},~{flags}\"()\n" else " %low = trunc i64 %p0 to i32\n %v = call i32 asm \"addl ${1}, ${0}\", \"=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}\"(i32 13,i32 %low)\n";
        var text: std.Io.Writer.Allocating = .init(a);
        defer text.deinit();
        try text.writer.writeAll("define i64 @bounded(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5) {\nentry:\n");
        try text.writer.writeAll(operation);
        try text.writer.writeAll(" %z = zext i32 %v to i64\n");
        for (0..6) |i| {
            const previous = if (i == 0) "%z" else try std.fmt.allocPrint(a, "%r{d}", .{i - 1});
            defer if (i != 0) a.free(previous);
            try text.writer.print(" %m{0d} = mul i64 {1s},1099511628211\n %r{0d} = xor i64 %m{0d},%p{0d}\n", .{ i, previous });
        }
        try text.writer.writeAll(" ret i64 %r5\n}\n");
        var module = try ir.Module.parse(a, text.written());
        defer module.deinit();
        try module.verify();
        var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
        defer selected.deinit(a);
        try @import("../verify.zig").verifyFunction(selected);
        const code = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
        defer a.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for (0..64) |seed| {
            const words = [_]u64{ seed *% 0x9182736455aaccdd, ~@as(u64, seed), 0x8000000000000000 | seed, seed *% 0x123456789abcdef1, seed ^ 0xfedcba9876543211, seed };
            var expected: u64 = if (kind == 0) 123 else @as(u32, @truncate(words[0])) +% 13;
            for (words) |word| expected = (expected *% 1099511628211) ^ word;
            try std.testing.expectEqual(expected, run(words[0], words[1], words[2], words[3], words[4], words[5]));
        }
        try module.verify();
        try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[kind].kind == .call);
    }
}
test "bounded empty assembly preserves memory and rejects other envelopes" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "define i64 @barrier(ptr %p,i64 %v) {\nentry:\n store i64 %v,ptr %p,align 1\n call void asm sideeffect \"\", \"=*r|m,~{dirflag},~{fpsr},~{flags}\"(ptr elementtype(i64) %p)\n %r = load i64,ptr %p,align 1\n ret i64 %r\n}\n");
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    const inst = original.blocks.items[0].instructions.items[1];
    try std.testing.expect(classify(inst) != null);
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const view = (try forms.legalize(arena.allocator(), original)).?;
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = view;
    try private.verify();
    try std.testing.expect((try forms.legalize(arena.allocator(), view)) == null);
    for (0..5) |variant| {
        var copy = inst;
        switch (variant) {
            0 => copy.kind.call.inline_asm.?.template = "nop",
            1 => copy.kind.call.inline_asm.?.constraints = "=*r|m,~{unknown}",
            2 => copy.kind.call.tail_kind = "musttail",
            3 => copy.kind.call.attrs = "unknown",
            4 => copy.kind.call.native_query = .cpuid,
            else => unreachable,
        }
        try std.testing.expect(classify(copy) == null);
    }
    var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", original, .{ .generic_cfg_selector = true });
    defer selected.deinit(a);
    try @import("../verify.zig").verifyFunction(selected);
    const code = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
    defer a.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..code.len], code);
    const run: *const fn (*u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    for (0..64) |seed| {
        var words = [_]u64{ 0xa5a5a5a5a5a5a5a5, 0, 0xa5a5a5a5a5a5a5a5 };
        const value = seed *% 0x9182736455aaccdd;
        try std.testing.expectEqual(value, run(&words[1], value));
        try std.testing.expectEqual(value, words[1]);
        try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), words[0]);
        try std.testing.expectEqual(words[0], words[2]);
    }
    try module.verify();
}
