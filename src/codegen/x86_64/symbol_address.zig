//! Closed symbolic byte addresses shared by scalar lowering and global data.
const std = @import("std");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");

pub const Address = struct { symbol: []const u8, addend: i32 = 0 };
pub const GlobalProperties = struct { alignment: ?u32 = null, local: bool = false, visibility: u8 = 0, tls: bool = false };

pub fn globalProperties(global: ir.Global) !GlobalProperties {
    return checkedGlobalProperties(global) catch return error.UnsupportedSymbolicGlobal;
}

/// Read-only diagnostic detail from the same property contract used by emission.
pub fn globalPropertyFailure(global: ir.Global) ?[]const u8 {
    _ = checkedGlobalProperties(global) catch |err| return @errorName(err);
    return null;
}

fn checkedGlobalProperties(global: ir.Global) !GlobalProperties {
    var result: GlobalProperties = .{ .local = global.linkage == .internal or global.linkage == .private };
    switch (global.linkage) {
        .default, .external, .internal, .private => {},
        else => return error.UnsupportedGlobalLinkage,
    }
    var address_attrs = std.mem.tokenizeAny(u8, global.address_attrs orelse "", " \t");
    while (address_attrs.next()) |attr| {
        if (std.mem.eql(u8, attr, "thread_local") or std.mem.eql(u8, attr, "thread_local(generaldynamic)")) {
            if (result.tls) return error.DuplicateGlobalTlsModel;
            result.tls = true;
        } else if (std.mem.eql(u8, attr, "hidden")) {
            result.visibility = 2;
        } else if (std.mem.eql(u8, attr, "protected")) {
            result.visibility = 3;
        } else if (!std.mem.eql(u8, attr, "unnamed_addr") and !std.mem.eql(u8, attr, "local_unnamed_addr") and
            !std.mem.eql(u8, attr, "dso_local") and !std.mem.eql(u8, attr, "dso_preemptable"))
            return error.UnsupportedGlobalAddressAttribute;
    }
    var attributes = std.mem.splitScalar(u8, global.attrs orelse "", ',');
    while (attributes.next()) |raw| {
        const attr = trim(raw);
        if (attr.len == 0) continue;
        if (std.mem.startsWith(u8, attr, "align ")) {
            if (result.alignment != null) return error.DuplicateGlobalAlignment;
            const alignment = std.fmt.parseUnsigned(u32, trim(attr[6..]), 10) catch return error.InvalidGlobalAlignment;
            if (alignment == 0 or alignment > 4096 or !std.math.isPowerOfTwo(alignment)) return error.UnsupportedGlobalAlignment;
            result.alignment = alignment;
        } else if (std.mem.startsWith(u8, attr, "!dbg !")) {
            _ = std.fmt.parseUnsigned(u32, attr[6..], 10) catch return error.InvalidGlobalDebugAttachment;
        } else return error.UnsupportedGlobalAttribute;
    }
    return result;
}

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t");
}

fn symbolName(value: []const u8) ?[]const u8 {
    const text = trim(value);
    if (text.len < 2 or text[0] != '@') return null;
    for (text[1..]) |byte| switch (byte) {
        'a'...'z', 'A'...'Z', '0'...'9', '.', '_', '-', '$' => {},
        else => return null,
    };
    return text[1..];
}

fn i64Bits(value: i128) ?u64 {
    if (value < 0) return @bitCast(std.math.cast(i64, value) orelse return null);
    return std.math.cast(u64, value);
}

pub fn fromGep(gep: ir.GepInst) ?Address {
    if (!gep.source_ty.eql(.{ .int = 8 }) or gep.ptr_addrspace != null or
        gep.ptr != .named or gep.indices.items.len != 1) return null;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or index.value != .int) return null;
    return .{ .symbol = symbolName(gep.ptr.named) orelse return null, .addend = std.math.cast(i32, @as(i64, @bitCast(i64Bits(index.value.int) orelse return null))) orelse return null };
}

pub fn fromValue(value: ir.Value) ?Address {
    if (value == .named) return .{ .symbol = symbolName(value.named) orelse return null };
    if (value != .constant_expr) return null;
    const text = trim(value.constant_expr);
    if (!std.mem.startsWith(u8, text, "getelementptr ")) return null;
    var rest = trim(text["getelementptr ".len..]);
    // These flags constrain when the source expression is non-poison; they
    // do not change the address on any defined execution. Recognize only the
    // supported vocabulary, retaining the same checked pointer/index form.
    var flags: u3 = 0;
    while (rest.len != 0 and rest[0] != '(') {
        const end = std.mem.indexOfAny(u8, rest, " \t") orelse return null;
        const token = rest[0..end];
        const flag: u3 = if (std.mem.eql(u8, token, "inbounds")) 1 else if (std.mem.eql(u8, token, "nuw")) 2 else if (std.mem.eql(u8, token, "nusw")) 4 else return null;
        if (flags & flag != 0) return null;
        flags |= flag;
        rest = trim(rest[end..]);
    }
    if (rest.len < 2 or rest[0] != '(' or rest[rest.len - 1] != ')') return null;
    var fields = std.mem.splitScalar(u8, rest[1 .. rest.len - 1], ',');
    if (!std.mem.eql(u8, trim(fields.next() orelse return null), "i8")) return null;
    const pointer = trim(fields.next() orelse return null);
    const index = trim(fields.next() orelse return null);
    if (fields.next() != null or !std.mem.startsWith(u8, pointer, "ptr ") or !std.mem.startsWith(u8, index, "i64 ")) return null;
    const bits = i64Bits(std.fmt.parseInt(i128, trim(index[4..]), 10) catch return null) orelse return null;
    return .{ .symbol = symbolName(pointer[4..]) orelse return null, .addend = std.math.cast(i32, @as(i64, @bitCast(bits))) orelse return null };
}

pub fn pointerBits(value: ir.Value) ?u64 {
    if (value == .null_value or value == .zero_initializer or value == .undef) return 0;
    if (value != .constant_expr) return null;
    const text = trim(value.constant_expr);
    if (!std.mem.startsWith(u8, text, "inttoptr (") or !std.mem.endsWith(u8, text, " to ptr)")) return null;
    const inner = trim(text["inttoptr (".len .. text.len - " to ptr)".len]);
    if (!std.mem.startsWith(u8, inner, "i64 ")) return null;
    return i64Bits(std.fmt.parseInt(i128, trim(inner[4..]), 10) catch return null);
}

pub fn supportsLayout(text: ?[]const u8) bool {
    const raw = text orelse "";
    const layout = target.DataLayout.parse(raw) catch return false;
    if ((layout.pointerSizeBits() catch return false) != 64 or
        (layout.pointerAbiAlignmentBits() catch return false) != 64) return false;
    var parts = std.mem.splitScalar(u8, raw, '-');
    while (parts.next()) |part| {
        if (std.mem.eql(u8, part, "E")) return false;
        if (part.len > 1 and (part[0] == 'A' or part[0] == 'G' or part[0] == 'P')) {
            if ((std.fmt.parseUnsigned(u32, part[1..], 10) catch return false) != 0) return false;
        }
        if (std.mem.startsWith(u8, part, "ni:")) {
            var spaces = std.mem.splitScalar(u8, part[3..], ':');
            while (spaces.next()) |space| if ((std.fmt.parseUnsigned(u32, space, 10) catch return false) == 0) return false;
        }
        const offset: usize = if (std.mem.startsWith(u8, part, "p:")) 2 else if (std.mem.startsWith(u8, part, "p0:")) 3 else continue;
        var fields = std.mem.splitScalar(u8, part[offset..], ':');
        if ((std.fmt.parseUnsigned(u16, fields.next() orelse return false, 10) catch return false) != 64 or
            (std.fmt.parseUnsigned(u16, fields.next() orelse return false, 10) catch return false) != 64) return false;
        if (fields.next()) |preferred| {
            const alignment = std.fmt.parseUnsigned(u16, preferred, 10) catch return false;
            if (alignment < 64 or !std.math.isPowerOfTwo(alignment)) return false;
        }
        if (fields.next()) |index| if ((std.fmt.parseUnsigned(u16, index, 10) catch return false) != 64) return false;
        if (fields.next() != null) return false;
    }
    return true;
}

test "symbol byte addresses retain signed offsets and integer bit patterns" {
    const cases = [_]struct { text: []const u8, offset: i32 }{
        .{ .text = "getelementptr inbounds (i8, ptr @object, i64 888)", .offset = 888 },
        .{ .text = "getelementptr inbounds nuw (i8, ptr @object, i64 9)", .offset = 9 },
        .{ .text = "getelementptr nuw (i8, ptr @object, i64 1)", .offset = 1 },
        .{ .text = "getelementptr nusw (i8, ptr @object, i64 -8)", .offset = -8 },
        .{ .text = "getelementptr inbounds nusw nuw (i8, ptr @object, i64 0)", .offset = 0 },
        .{ .text = "getelementptr (i8, ptr @object, i64 -8)", .offset = -8 },
        .{ .text = "getelementptr (i8, ptr @object, i64 2147483647)", .offset = std.math.maxInt(i32) },
        .{ .text = "getelementptr (i8, ptr @object, i64 -2147483648)", .offset = std.math.minInt(i32) },
        .{ .text = "getelementptr (i8, ptr @object, i64 18446744073709551615)", .offset = -1 },
    };
    for (cases) |case| {
        const address = fromValue(.{ .constant_expr = case.text }).?;
        try std.testing.expectEqualStrings("object", address.symbol);
        try std.testing.expectEqual(case.offset, address.addend);
    }
    try std.testing.expectEqualStrings("named.object", fromValue(.{ .named = "@named.object" }).?.symbol);
}

test "symbol byte addresses reject unproved sources spaces indexes and ranges" {
    for ([_][]const u8{
        "getelementptr (i32, ptr @object, i64 1)",
        "getelementptr (i8, ptr @object, i32 1)",
        "getelementptr (i8, ptr addrspace(1) @object, i64 1)",
        "getelementptr (i8, ptr @object, i64 %index)",
        "getelementptr (i8, ptr @object, i64 0, i64 1)",
        "getelementptr (i8, ptr @object, i64 2147483648)",
        "getelementptr (i8, ptr @object, i64 -2147483649)",
        "getelementptr (i8, ptr @object, i64 18446744073709551616)",
        "getelementptr nsw (i8, ptr @object, i64 1)",
        "getelementptr inrange(0, 4) (i8, ptr @object, i64 1)",
        "getelementptr nuw nuw (i8, ptr @object, i64 1)",
        "getelementptr inbounds nuw (i8, ptr addrspace(1) @object, i64 1)",
        "getelementptr inbounds nuw (i8, ptr @object, i64 2147483648)",
        "getelementptr inbounds nuw (i8, ptr @object, i64 1) trailing",
    }) |text| try std.testing.expect(fromValue(.{ .constant_expr = text }) == null);
    try std.testing.expect(fromValue(.{ .named = "local" }) == null);
    try std.testing.expect(fromValue(.null_value) == null);
}

test "symbol layout contract proves default pointer representation and index width" {
    for ([_]?[]const u8{ null, "", "e-p:64:64-i64:64", "e-p0:64:64:64:64", "e-p270:32:32-p271:32:32-p272:64:64-i64:64" }) |text|
        try std.testing.expect(supportsLayout(text));
    for ([_][]const u8{ "E-p:64:64", "e-p:32:32", "e-p0:32:32", "e-p:64:128", "e-p:64:64:64:32", "e-p0:64:64:64:32", "e-p:64:64:64:64:64", "e-G1", "e-P1", "e-ni:0" }) |text|
        try std.testing.expect(!supportsLayout(text));
}

test "symbolic data pointer constants preserve exactly admitted 64-bit patterns" {
    const cases = [_]struct { text: []const u8, bits: u64 }{
        .{ .text = "inttoptr (i64 1 to ptr)", .bits = 1 },
        .{ .text = "inttoptr (i64 4294967295 to ptr)", .bits = std.math.maxInt(u32) },
        .{ .text = "inttoptr (i64 -1 to ptr)", .bits = std.math.maxInt(u64) },
        .{ .text = "inttoptr (i64 18446744073709551615 to ptr)", .bits = std.math.maxInt(u64) },
    };
    for (cases) |case| try std.testing.expectEqual(case.bits, pointerBits(.{ .constant_expr = case.text }).?);
    for ([_][]const u8{ "inttoptr (i32 1 to ptr)", "inttoptr (i128 1 to ptr)", "inttoptr (i64 %value to ptr)", "inttoptr (i64 1 to ptr addrspace(1))", "inttoptr (i64 18446744073709551616 to ptr)" }) |text|
        try std.testing.expect(pointerBits(.{ .constant_expr = text }) == null);
    try std.testing.expectEqual(@as(?u64, 0), pointerBits(.null_value));
}

test "symbolic global properties preserve explicit alignment linkage and visibility" {
    var global: ir.Global = .{ .name = "data", .kind = .global, .ty = .{ .int = 64 }, .initializer = .{ .scalar = .{ .int = 0 } }, .linkage = .internal, .address_attrs = "dso_local hidden unnamed_addr", .attrs = "align 1, !dbg !42" };
    const properties = try globalProperties(global);
    try std.testing.expectEqual(@as(?u32, 1), properties.alignment);
    try std.testing.expect(properties.local);
    try std.testing.expectEqual(@as(u8, 2), properties.visibility);
    for ([_][]const u8{ "align 3", "align 8192", "align 8, align 16", "section \"custom\"", "!dbg !name" }) |attr| {
        global.attrs = attr;
        try std.testing.expectError(error.UnsupportedSymbolicGlobal, globalProperties(global));
    }
    global.attrs = null;
    global.address_attrs = "thread_local(initialexec)";
    try std.testing.expectError(error.UnsupportedSymbolicGlobal, globalProperties(global));
    global.address_attrs = null;
    global.linkage = .weak;
    try std.testing.expectError(error.UnsupportedSymbolicGlobal, globalProperties(global));
}
