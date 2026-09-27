const std = @import("std");
const ir = @import("../../../ir.zig");

// Alias scopes constrain optimization, not machine execution. Only the exact
// metadata-only declaration form can be discarded during instruction selection.
pub fn isNoAliasScopeDecl(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.experimental.noalias.scope.decl") or
        call.ret_ty != .void or call.args.items.len != 1 or call.inline_asm != null or
        call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or
        call.operand_bundle != null) return false;
    if (call.tail_kind) |tail| if (!std.mem.eql(u8, tail, "tail") and !std.mem.eql(u8, tail, "notail")) return false;
    const arg = call.args.items[0];
    if (arg.ty != .metadata or arg.attrs != null or arg.value != .named) return false;
    const name = arg.value.named;
    if (name.len < 2 or name[0] != '!') return false;
    for (name[1..]) |ch| if (!std.ascii.isDigit(ch)) return false;
    return true;
}

pub const IntegerRange = struct {
    bits: u16,
    lower: u128,
    upper: u128,
};

pub fn parseIntegerRange(attrs: ?[]const u8) ?IntegerRange {
    const text = std.mem.trim(u8, attrs orelse return null, " \t");
    if (!std.mem.startsWith(u8, text, "range(") or !std.mem.endsWith(u8, text, ")")) return null;

    const body = std.mem.trim(u8, text["range(".len .. text.len - 1], " \t");
    if (body.len < 2 or body[0] != 'i') return null;
    var type_end: usize = 1;
    while (type_end < body.len and std.ascii.isDigit(body[type_end])) : (type_end += 1) {}
    if (type_end == 1 or type_end == body.len or !std.ascii.isWhitespace(body[type_end])) return null;

    const bits = std.fmt.parseUnsigned(u16, body[1..type_end], 10) catch return null;
    const bounds = std.mem.trim(u8, body[type_end..], " \t");
    const comma = std.mem.indexOfScalar(u8, bounds, ',') orelse return null;
    if (std.mem.indexOfScalar(u8, bounds[comma + 1 ..], ',') != null) return null;
    const lower_text = std.mem.trim(u8, bounds[0..comma], " \t");
    const upper_text = std.mem.trim(u8, bounds[comma + 1 ..], " \t");
    if (lower_text.len == 0 or upper_text.len == 0) return null;

    return .{
        .bits = bits,
        .lower = std.fmt.parseUnsigned(u128, lower_text, 10) catch return null,
        .upper = std.fmt.parseUnsigned(u128, upper_text, 10) catch return null,
    };
}

pub fn matchesIntegerRange(attrs: ?[]const u8, bits: u16, lower: u128, upper: u128) bool {
    const parsed = parseIntegerRange(attrs) orelse return false;
    return parsed.bits == bits and parsed.lower == lower and parsed.upper == upper;
}

test "intrinsic integer range decoder is typed and exact" {
    try std.testing.expect(matchesIntegerRange("range(i64 0, 65)", 64, 0, 65));
    try std.testing.expect(matchesIntegerRange(" range(i128\t0, 129) ", 128, 0, 129));
    inline for (.{
        @as(?[]const u8, null),
        "range(i64 0, 64)",
        "range(i32 0, 65)",
        "range(i64 -1, 65)",
        "range(i64 0, 65), zeroext",
        "range(i64 0, 65, 66)",
        "zeroext",
    }) |attrs| try std.testing.expect(!matchesIntegerRange(attrs, 64, 0, 65));
}
