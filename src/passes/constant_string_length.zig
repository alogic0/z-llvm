const std = @import("std");
const ir = @import("../ir.zig");

// A bounded SimplifyLibCalls fold: direct strlen of a complete private byte
// string. Dynamic pointers, mutable/interposable data and nobuiltin retain calls.
pub fn fold(module: ir.Module, instruction: ir.Instruction) ?ir.Value {
    if (instruction.kind != .call or instruction.result == null) return null;
    const call = instruction.kind.call;
    if (!std.mem.eql(u8, call.callee, "strlen") or call.callee_value != null or call.inline_asm != null or
        call.callee_function_ty != null or call.attrs != null or call.ret_attrs != null or
        call.operand_bundle != null or call.raw_args != null or call.args.items.len != 1 or
        !call.ret_ty.eql(.{ .int = 64 }) or call.args.items[0].ty != .ptr) return null;
    if (call.calling_conv) |cc| if (!std.mem.eql(u8, cc, "ccc")) return null;
    if (call.tail_kind) |tail| if (std.mem.eql(u8, tail, "musttail")) return null;
    const triple = module.target_triple orelse return null;
    if (!std.mem.startsWith(u8, triple, "x86_64-") or std.mem.indexOf(u8, triple, "linux") == null) return null;
    for (module.attribute_groups.items) |group| {
        if (std.mem.indexOf(u8, group, "nobuiltin") != null or std.mem.indexOf(u8, group, "no-builtins") != null) return null;
    }
    for (module.functions.items) |function| if (std.mem.eql(u8, std.mem.trim(u8, function.name, "@\""), "strlen")) return null;
    var declaration_found = false;
    for (module.declarations.items) |declaration| {
        if (!std.mem.eql(u8, declaration.name, "strlen")) continue;
        if (declaration.attrs != null or declaration.is_varargs or declaration.params.items.len != 1 or
            declaration.ret_attrs != null or declaration.params.items[0].ty != .ptr or !declaration.ret_ty.eql(call.ret_ty)) return null;
        if (declaration.calling_conv) |cc| if (!std.mem.eql(u8, cc, "ccc")) return null;
        declaration_found = true;
    }
    if (!declaration_found) return null;
    const argument = call.args.items[0];
    if (argument.attrs) |attrs| {
        inline for (.{ "byval", "sret", "inalloca", "preallocated" }) |attr| if (std.mem.indexOf(u8, attrs, attr) != null) return null;
    }
    if (argument.value != .named or !std.mem.startsWith(u8, argument.value.named, "@")) return null;
    for (module.globals.items) |global| {
        if (!std.mem.eql(u8, global.name, argument.value.named[1..])) continue;
        if (global.kind != .constant or (global.linkage != .internal and global.linkage != .private) or
            global.initializer != .c_string or global.ty != .aggregate) return null;
        if (global.address_attrs) |attrs| if (std.mem.indexOf(u8, attrs, "addrspace") != null or std.mem.indexOf(u8, attrs, "thread_local") != null) return null;
        const ty = std.mem.trim(u8, global.ty.aggregate, " \t");
        if (!std.mem.startsWith(u8, ty, "[") or !std.mem.endsWith(u8, ty, " x i8]")) return null;
        const declared = std.fmt.parseUnsigned(usize, ty[1 .. ty.len - " x i8]".len], 10) catch return null;
        const text = global.initializer.c_string;
        if (!std.mem.startsWith(u8, text, "c\"") or !std.mem.endsWith(u8, text, "\"")) return null;
        var offset: usize = 2;
        var length: usize = 0;
        var nul: ?usize = null;
        while (offset < text.len - 1) : (length += 1) {
            var byte = text[offset];
            offset += 1;
            if (byte == '\\') {
                if (offset + 2 > text.len - 1) return null;
                byte = std.fmt.parseUnsigned(u8, text[offset .. offset + 2], 16) catch return null;
                offset += 2;
            }
            if (byte == 0 and nul == null) nul = length;
        }
        if (length != declared) return null;
        return .{ .int = @intCast(nul orelse return null) };
    }
    return null;
}
