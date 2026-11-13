//! Closed symbolic byte addresses shared by scalar lowering and global data.
const std = @import("std");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");

pub const Address = struct { symbol: []const u8, addend: i32 = 0 };
pub const GlobalProperties = struct { alignment: ?u32 = null, local: bool = false, visibility: u8 = 0, tls: bool = false, read_only_section: bool = false };

pub fn globalProperties(global: ir.Global) !GlobalProperties {
    return checkedGlobalProperties(global) catch return error.UnsupportedSymbolicGlobal;
}

test "global standard sections must match owned storage and reject duplicates and TLS" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "@w = global i32 7, section \".data\", align 4\n@r = constant i32 9, section \".rodata\", align 4\n");
    defer module.deinit();
    try module.verify();
    for (module.globals.items) |global| {
        try std.testing.expectEqual(global.kind == .constant, (try globalProperties(global)).read_only_section);
        var copy = global;
        copy.attrs = "section \".data\", section \".data\"";
        try std.testing.expectError(error.UnsupportedSymbolicGlobal, globalProperties(copy));
        copy = global;
        copy.address_attrs = "thread_local";
        try std.testing.expectError(error.UnsupportedSymbolicGlobal, globalProperties(copy));
        copy = global;
        copy.attrs = if (global.kind == .constant) "section \".data\"" else "section \".rodata\"";
        try std.testing.expectError(error.UnsupportedSymbolicGlobal, globalProperties(copy));
    }
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
    var section_seen = false;
    var attributes = std.mem.splitScalar(u8, global.attrs orelse "", ',');
    while (attributes.next()) |raw| {
        const attr = trim(raw);
        if (attr.len == 0) continue;
        if (std.mem.startsWith(u8, attr, "align ")) {
            if (result.alignment != null) return error.DuplicateGlobalAlignment;
            const alignment = std.fmt.parseUnsigned(u32, trim(attr[6..]), 10) catch return error.InvalidGlobalAlignment;
            if (alignment == 0 or alignment > 4096 or !std.math.isPowerOfTwo(alignment)) return error.UnsupportedGlobalAlignment;
            result.alignment = alignment;
        } else if (std.mem.startsWith(u8, attr, "section ")) {
            if (section_seen or result.tls) return error.UnsupportedGlobalAttribute;
            // Admit only the two explicitly owned ordinary data sections.
            // The ELF emitter must honor read-only placement independently.
            const expected = if (global.kind == .constant) "section \".rodata\"" else "section \".data\"";
            if (!std.mem.eql(u8, attr, expected)) return error.UnsupportedGlobalAttribute;
            result.read_only_section = global.kind == .constant;
            section_seen = true;
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
    // Retain the complete LLVM spelling. Identity comparisons use the shared
    // identifier contract; the MC boundary owns decoding to object-file bytes.
    if (!ir.identifiers.isValid(text[1..])) return null;
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
    if (fromDirectValue(value)) |address| return address;
    if (value != .constant_expr) return null;
    const text = trim(value.constant_expr);
    const prefix = "inttoptr (i64 ";
    const suffix = " to ptr)";
    if (!std.mem.startsWith(u8, text, prefix) or !std.mem.endsWith(u8, text, suffix)) return null;
    const arithmetic = trim(text[prefix.len .. text.len - suffix.len]);
    const subtract = std.mem.startsWith(u8, arithmetic, "sub (");
    if (!subtract and !std.mem.startsWith(u8, arithmetic, "add (")) return null;
    if (arithmetic.len < 6 or arithmetic[arithmetic.len - 1] != ')') return null;
    var fields: @import("../../ir/structure.zig").Fields = .{ .rest = arithmetic[5 .. arithmetic.len - 1], .packed_type = false };
    const base_text = trim(fields.next() orelse return null);
    const offset_text = trim(fields.next() orelse return null);
    if (fields.next() != null or !std.mem.startsWith(u8, base_text, "i64 ") or !std.mem.startsWith(u8, offset_text, "i64 ")) return null;
    // A single same-width round trip over the existing symbol/GEP grammar.
    // The base decoder excludes nested arithmetic and other address spaces.
    const base = fromIntegerValue(.{ .int = 64 }, .{ .constant_expr = trim(base_text[4..]) }) orelse return null;
    const offset = i64Bits(std.fmt.parseInt(i128, trim(offset_text[4..]), 10) catch return null) orelse return null;
    const original: u64 = @bitCast(@as(i64, base.addend));
    const result: i64 = @bitCast(if (subtract) original -% offset else original +% offset);
    return .{ .symbol = base.symbol, .addend = std.math.cast(i32, result) orelse return null };
}

fn fromDirectValue(value: ir.Value) ?Address {
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
    var fields: @import("../../ir/structure.zig").Fields = .{ .rest = rest[1 .. rest.len - 1], .packed_type = false };
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

/// A same-width pointer cast keeps the admitted symbolic address intact. The
/// caller must also prove supportsLayout; other integer widths/spaces stay
/// outside this contract. Reuse the pointer grammar and checked addend once.
pub fn fromIntegerValue(ty: ir.Type, value: ir.Value) ?Address {
    if (!ty.eql(.{ .int = 64 }) or value != .constant_expr) return null;
    const text = trim(value.constant_expr);
    const prefix = "ptrtoint (ptr ";
    const suffix = " to i64)";
    if (text.len <= prefix.len + suffix.len or !std.mem.startsWith(u8, text, prefix) or !std.mem.endsWith(u8, text, suffix)) return null;
    const pointer = trim(text[prefix.len .. text.len - suffix.len]);
    return fromDirectValue(if (std.mem.startsWith(u8, pointer, "@")) .{ .named = pointer } else .{ .constant_expr = pointer });
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

test "quoted symbol addresses retain complete spelling through constant fields and integer casts" {
    for ([_][]const u8{ "\"plain\"", "\"pla\\69n\"", "\"array(ptr,i64).table [0]\"", "\"punctuation ,(){}[]<>; to i64)\"", "\"quote\\22-backslash\\5C31\"", "\"name\\0Aline\"" }) |name| {
        const reference = try std.fmt.allocPrint(std.testing.allocator, "@{s}", .{name});
        defer std.testing.allocator.free(reference);
        try std.testing.expectEqualStrings(name, fromValue(.{ .named = reference }).?.symbol);
        for ([_]i32{ -8, 0, 17, std.math.minInt(i32), std.math.maxInt(i32) }) |offset| {
            const expression = try std.fmt.allocPrint(std.testing.allocator, "getelementptr inbounds nuw (i8, ptr {s}, i64 {d})", .{ reference, offset });
            defer std.testing.allocator.free(expression);
            const address = fromValue(.{ .constant_expr = expression }).?;
            try std.testing.expectEqualStrings(name, address.symbol);
            try std.testing.expectEqual(offset, address.addend);
            const integer = try std.fmt.allocPrint(std.testing.allocator, "ptrtoint (ptr {s} to i64)", .{expression});
            defer std.testing.allocator.free(integer);
            const cast = fromIntegerValue(.{ .int = 64 }, .{ .constant_expr = integer }).?;
            try std.testing.expectEqualStrings(name, cast.symbol);
            try std.testing.expectEqual(offset, cast.addend);
        }
    }
    for ([_][]const u8{ "@\"\"", "@\"unfinished", "@\"bad\\00name\"", "@\"bad\\GG\"", "@\"bad\\1\"", "@\"bad\"tail", "@\"bad\"\"name\"", "@\"raw\nline\"", "@1suffix", "%\"local\"" }) |text|
        try std.testing.expect(fromValue(.{ .named = text }) == null);
    for ([_][]const u8{
        "getelementptr (i8, ptr @\"a,b\", i64 0,)",
        "getelementptr (i8, ptr @\"a,b\", i64 2147483648)",
        "getelementptr (i8, ptr @\"a,b\", i32 0)",
        "getelementptr (i8, ptr @\"a,b\", i64 0) trailing",
        "getelementptr (i8, ptr @\"a,b, i64 0)",
    }) |text| try std.testing.expect(fromValue(.{ .constant_expr = text }) == null);
}

test "integer symbolic addresses preserve pointer identity and reject other representations" {
    const cases = [_]struct { text: []const u8, symbol: []const u8, offset: i32 }{
        .{ .text = "ptrtoint (ptr @object to i64)", .symbol = "object", .offset = 0 },
        .{ .text = "ptrtoint (ptr getelementptr inbounds nuw (i8, ptr @Io.Threaded.global_single_threaded_instance, i64 1120) to i64)", .symbol = "Io.Threaded.global_single_threaded_instance", .offset = 1120 },
        .{ .text = "ptrtoint (ptr getelementptr (i8, ptr @alias, i64 -8) to i64)", .symbol = "alias", .offset = -8 },
        .{ .text = "ptrtoint (ptr getelementptr (i8, ptr @object, i64 18446744073709551615) to i64)", .symbol = "object", .offset = -1 },
    };
    for (cases) |case| {
        const value: ir.Value = .{ .constant_expr = case.text };
        const address = fromIntegerValue(.{ .int = 64 }, value).?;
        try std.testing.expectEqualStrings(case.symbol, address.symbol);
        try std.testing.expectEqual(case.offset, address.addend);
        try std.testing.expect(fromIntegerValue(.{ .int = 32 }, value) == null);
        try std.testing.expect(fromIntegerValue(.ptr, value) == null);
    }
    for ([_][]const u8{
        "ptrtoint (ptr @object to i32)",
        "ptrtoint (ptr @object to i128)",
        "ptrtoint (ptr addrspace(1) @object to i64)",
        "ptrtoint (ptr %local to i64)",
        "ptrtoint (ptr null to i64)",
        "ptrtoint (ptr getelementptr (i32, ptr @object, i64 1) to i64)",
        "ptrtoint (ptr getelementptr (i8, ptr @object, i64 2147483648) to i64)",
        "ptrtoint (ptr getelementptr (i8, ptr @object, i64 -2147483649) to i64)",
        "ptrtoint (ptr getelementptr (i8, ptr @object, i64 %index) to i64)",
        "ptrtoint (ptr @object to i64) trailing",
        "ptrtoint (ptr @object to i64) to i64)",
        "ptrtoint (ptr to i64)",
        "ptrtoint (ptr inttoptr (i64 1 to ptr) to i64)",
    }) |text| try std.testing.expect(fromIntegerValue(.{ .int = 64 }, .{ .constant_expr = text }) == null);
    for ([_]ir.Value{ .undef, .poison, .null_value, .{ .int = 1 }, .{ .named = "@object" } }) |value|
        try std.testing.expect(fromIntegerValue(.{ .int = 64 }, value) == null);
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
