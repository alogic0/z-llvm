const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv = @import("../sysv_abi.zig");

/// Pointer promises do not change the representation of an intrinsic operand.
/// Keep ABI payloads excluded even where ordinary calls admit a private view.
pub fn pointerArgumentAdvisory(arg: ir.CallArg) bool {
    if (arg.ty != .ptr or arg.abi_x87_memory or arg.abi_split_integer) return false;
    return if (arg.attrs) |attrs| sysv.pointerCallAttrsAreAdvisory(attrs) else true;
}

test "pointer intrinsic facts reuse checked promises and exclude ABI payloads" {
    var arg: ir.CallArg = .{ .ty = .ptr, .value = .{ .named = "address" } };
    for ([_]?[]const u8{ null, "nonnull", "noundef nonnull align 8 dereferenceable(24)", "nonnull readonly captures(none)", "dereferenceable_or_null(8)" }) |attrs| {
        arg.attrs = attrs;
        try std.testing.expect(pointerArgumentAdvisory(arg));
    }
    for ([_][]const u8{ "sret(i64)", "byval(i64)", "inreg", "returned", "align 3", "nonnull nonnull", "dereferenceable(-1)", "elementtype(i32)", "unknown" }) |attrs| {
        arg.attrs = attrs;
        try std.testing.expect(!pointerArgumentAdvisory(arg));
    }
    arg.attrs = null;
    arg.ty = .{ .int = 64 };
    try std.testing.expect(!pointerArgumentAdvisory(arg));
    arg.ty = .ptr;
    arg.abi_split_integer = true;
    try std.testing.expect(!pointerArgumentAdvisory(arg));
}

/// Shared admission for scalar integer intrinsic facts. Each consumer still
/// proves its exact intrinsic signature and operand forms. The ordinary ABI
/// validators distinguish advisory facts from representation-changing promises.
pub fn scalarIntegerCallSupported(call: ir.CallInst) bool {
    if (call.ret_ty != .int or call.ret_ty.int == 0 or call.callee_value != null or
        call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or
        call.callee_function_ty != null or call.calling_conv != null) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| {
        if (arg.ty != .int or arg.ty.int == 0) return false;
        sysv.rejectUnsupportedCallArgAttrs(arg) catch return false;
    }
    return true;
}

// The existing native population-count path also accepts fastcc. Intrinsic
// expansion makes no ABI call, but still checks every other semantic promise.
pub fn scalarCtpopCallSupported(call: ir.CallInst) bool {
    if (call.calling_conv) |cc| if (!std.mem.eql(u8, cc, "fastcc")) return false;
    var normalized = call;
    normalized.calling_conv = null;
    return scalarIntegerCallSupported(normalized);
}

test "scalar integer intrinsic facts validate ranges without admitting ABI promises" {
    var args = [_]ir.CallArg{.{ .ty = .{ .int = 64 }, .value = .{ .named = "value" } }};
    var call: ir.CallInst = .{ .callee = "llvm.bitreverse.i64", .ret_ty = .{ .int = 64 }, .args = .fromOwnedSlice(&args) };
    for ([_]?[]const u8{ null, "noundef", "range(i64 32, 0)", "noundef range(i64 -32, 32)" }) |facts| {
        call.ret_attrs = facts;
        args[0].attrs = facts;
        try std.testing.expect(scalarIntegerCallSupported(call));
    }
    for ([_][]const u8{ "signext", "zeroext", "inreg", "noalias", "range(i32 0, 32)", "range(i64 1, 1)", "range(i64 0, 18446744073709551616)", "range(i64 0, 32) unknown" }) |facts| {
        call.ret_attrs = facts;
        args[0].attrs = null;
        try std.testing.expect(!scalarIntegerCallSupported(call));
        call.ret_attrs = null;
        args[0].attrs = facts;
        try std.testing.expect(!scalarIntegerCallSupported(call));
    }
    args[0].attrs = null;
    call.tail_kind = "musttail";
    try std.testing.expect(!scalarIntegerCallSupported(call));
    call.tail_kind = "tail";
    try std.testing.expect(scalarIntegerCallSupported(call));
    call.calling_conv = "fastcc";
    try std.testing.expect(!scalarIntegerCallSupported(call));
    call.calling_conv = null;
    call.operand_bundle = "[\"deopt\"(i64 1)]";
    try std.testing.expect(!scalarIntegerCallSupported(call));
    call.operand_bundle = null;
    call.callee_value = .{ .named = "indirect" };
    try std.testing.expect(!scalarIntegerCallSupported(call));
}

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
