//! LLVM byval(x86_fp80) is a stack value, not a pointer in a GPR. A private
//! owned copy retains the original body's pointer uses and native alignment.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const sysv = @import("../sysv_abi.zig");
const machine = @import("../machine.zig");
const carrier: ir.Type = .{ .int = 128 };

pub fn hasParameters(function: ir.Function) bool {
    for (function.params.items) |param| {
        if (param.ty != .ptr) continue;
        const attrs = param.attrs orelse continue;
        const start = std.mem.indexOf(u8, attrs, "byval(") orelse continue;
        if (start != 0 and attrs[start - 1] != ' ') continue;
        const payload = attrs[start + "byval(".len ..];
        const end = std.mem.indexOfScalar(u8, payload, ')') orelse continue;
        if (std.mem.eql(u8, std.mem.trim(u8, payload[0..end], " \t"), "x86_fp80")) return true;
    }
    return false;
}

fn supported(a: std.mem.Allocator, ty: ir.Type, attrs: ?[]const u8) !bool {
    if (ty != .ptr or attrs == null) return false;
    const text = attrs.?;
    const marker = "byval(x86_fp80)";
    const index = std.mem.indexOf(u8, text, marker) orelse return false;
    if ((index != 0 and text[index - 1] != ' ') or (index + marker.len != text.len and text[index + marker.len] != ' ')) return false;
    const remainder = try std.mem.concat(a, u8, &.{ text[0..index], text[index + marker.len ..] });
    if (std.mem.trim(u8, remainder, " \t").len != 0 and !sysv.pointerCallAttrsAreAdvisory(remainder)) return false;
    var tokens = std.mem.tokenizeAny(u8, remainder, " \t");
    while (tokens.next()) |token| if (std.mem.eql(u8, token, "align")) {
        const alignment = std.fmt.parseInt(u32, tokens.next() orelse return false, 10) catch return false;
        if (alignment > 16) return false;
    };
    return true;
}

pub fn legalize(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    const text = if (context) |c| c.target_datalayout else null;
    if (!@import("../symbol_address.zig").supportsLayout(text)) return null;
    var specifications = std.mem.splitScalar(u8, text orelse "", '-');
    while (specifications.next()) |specification| if (std.mem.startsWith(u8, specification, "f80:")) {
        var fields = std.mem.splitScalar(u8, specification, ':');
        _ = fields.next();
        if (!std.mem.eql(u8, fields.next() orelse return null, "128")) return null;
    };
    const layout = @import("../../../target.zig").DataLayout.parse(text orelse "") catch return null;
    if ((layout.typeAllocSizeBytes(.x86_fp80) catch return null) != 16 or
        (layout.typeAbiAlignmentBits(.x86_fp80) catch return null) != 128 or
        (layout.typeAllocSizeBytes(carrier) catch return null) != 16 or
        (layout.typeAbiAlignmentBits(carrier) catch return null) != 128) return null;
    var needed = false;
    for (function.params.items) |param| needed = needed or try supported(a, param.ty, param.attrs);
    if (!needed) outer: for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .call) for (inst.kind.call.args.items) |arg| if (try supported(a, arg.ty, arg.attrs)) {
            needed = true;
            break :outer;
        };
    };
    if (!needed) return null;
    var names: forms.TemporaryNames = .{};
    defer names.deinit(a);
    var result = function;
    result.params = try function.params.clone(a);
    for (result.params.items) |*param| if (try supported(a, param.ty, param.attrs)) {
        param.name = try forms.temporary(a, function, &names);
        param.ty = carrier;
        param.attrs = null;
        param.abi_x87_memory = true;
    };
    result.blocks = .empty;
    for (function.blocks.items, 0..) |original, index| {
        var block = original;
        block.instructions = .empty;
        if (index == 0) for (function.params.items, result.params.items) |source, incoming| {
            if (source.name.ptr == incoming.name.ptr) continue;
            try block.instructions.append(a, .{ .result = source.name, .kind = .{ .alloca = .{ .allocated_ty = carrier, .attrs = "align 16" } } });
            try block.instructions.append(a, .{ .result = null, .kind = .{ .store = .{ .ty = carrier, .value = .{ .named = incoming.name }, .ptr = .{ .named = source.name }, .attrs = .{ .@"align" = 16 } } } });
        };
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and inst.kind == .call) {
                var call = inst.kind.call;
                var call_changed = false;
                for (call.args.items) |arg| call_changed = call_changed or try supported(a, arg.ty, arg.attrs);
                if (call_changed) {
                    if (call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null) return null;
                    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
                    call.args = try call.args.clone(a);
                    for (call.args.items) |*arg| if (try supported(a, arg.ty, arg.attrs)) {
                        const name = try forms.temporary(a, function, &names);
                        try block.instructions.append(a, .{ .result = name, .kind = .{ .load = .{ .ty = carrier, .ptr = arg.value, .attrs = .{ .@"align" = 1 } } } });
                        arg.* = .{ .ty = carrier, .value = .{ .named = name }, .abi_x87_memory = true };
                    };
                    copy.kind.call = call;
                }
            }
            try block.instructions.append(a, copy);
        }
        try result.blocks.append(a, block);
    }
    return result;
}

test "byval80 keeps the source ABI immutable and rejects unsupported alignment and attributes" {
    var source = try ir.Module.parse(std.testing.allocator,
        \\define i64 @read(ptr noundef readonly byval(x86_fp80) align 16 %p) {
        \\entry:
        \\ %v = load i64,ptr %p,align 1
        \\ ret i64 %v
        \\}
    );
    defer source.deinit();
    try source.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const original = source.functions.items[0];
    const copy = (try legalize(a, original, null)).?;
    try std.testing.expect(original.params.items[0].ty == .ptr);
    try std.testing.expectEqualStrings("noundef readonly byval(x86_fp80) align 16", original.params.items[0].attrs.?);
    try std.testing.expect(copy.params.items[0].ty.eql(carrier));
    try std.testing.expect(copy.params.items[0].abi_x87_memory);
    try std.testing.expect(copy.params.items[0].attrs == null);
    try std.testing.expect((try legalize(a, copy, null)) == null);
    for ([_][]const u8{ "byval(x86_fp80) align 32", "byval(x86_fp80) inreg", "byval(i128) align 16" }) |attrs| {
        var other = original;
        other.params = try original.params.clone(a);
        other.params.items[0].attrs = attrs;
        try std.testing.expect((try legalize(a, other, null)) == null);
    }
    const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = "e-f80:64" };
    try std.testing.expect((try legalize(a, original, &context)) == null);
}

test "byval80 simple loads use the incoming stack ABI and close unsupported source envelopes" {
    const compilation = @import("../../../compilation.zig");
    const encoding = @import("../../../mc/encoding.zig");
    for ([_][]const u8{ "byval(x86_fp80) align 16", "byval(x86_fp80) align 32", "byval(x86_fp80) inreg" }, 0..) |attrs, index| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @read(ptr {s} %p) {{\nentry:\n %v = load i64,ptr %p,align 1\n ret i64 %v\n}}\n", .{attrs});
        defer std.testing.allocator.free(text);
        var source = try ir.Module.parse(std.testing.allocator, text);
        defer source.deinit();
        if (index != 0) {
            if (compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", source.functions.items[0], .{ .generic_cfg_selector = true })) |selected| {
                var unexpected = selected;
                unexpected.deinit(std.testing.allocator);
                return error.UnsupportedByvalWasSelected;
            } else |err| try std.testing.expect(err != error.OutOfMemory);
            continue;
        }
        var selected = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", source.functions.items[0], .{ .generic_cfg_selector = true });
        defer selected.deinit(std.testing.allocator);
        const code = try encoding.encodeFunction(std.testing.allocator, selected);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (f80) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u80{ 0, 0x80000000000000000000, 0x3fff8000000000000000, 0x7fff8000000000000123 }) |bits|
            try std.testing.expectEqual(@as(u64, @truncate(bits)), run(@bitCast(bits)));
    }
}
