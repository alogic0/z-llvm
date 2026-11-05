//! Stable ELF contents across relocatable linker repacking, with checked byte ranges.
const std = @import("std");
const u = @import("common.zig");
const Section = struct { name: u32, kind: u32, flags: u64, offset: u64, size: u64, link: u32, info: u32, entry: u64 };
const Elf = struct {
    data: []const u8,
    fn bytes(elf: Elf, offset: u64, size: u64) ![]const u8 {
        if (offset > elf.data.len or size > elf.data.len - offset) return error.InvalidElfBounds;
        return elf.data[@intCast(offset)..@intCast(offset + size)];
    }
    fn int(elf: Elf, comptime T: type, offset: u64) !T {
        return std.mem.readInt(T, (try elf.bytes(offset, @sizeOf(T)))[0..@sizeOf(T)], .little);
    }
    fn payload(elf: Elf, section: Section) ![]const u8 {
        return elf.bytes(section.offset, section.size);
    }
};
fn string(table: []const u8, offset: u32) ![]const u8 {
    if (offset >= table.len) return error.InvalidElfString;
    const rest = table[offset..];
    const end = std.mem.indexOfScalar(u8, rest, 0) orelse return error.InvalidElfString;
    if (!std.unicode.utf8ValidateSlice(rest[0..end])) return error.InvalidElfString;
    return rest[0..end];
}
fn sections(a: std.mem.Allocator, elf: Elf) ![]Section {
    if (elf.data.len < 64 or !std.mem.eql(u8, elf.data[0..6], "\x7fELF\x02\x01")) return error.ExpectedElf64LittleEndian;
    const offset = try elf.int(u64, 40);
    const count = try elf.int(u16, 60);
    if (try elf.int(u16, 58) != 64 or count == 0) return error.UnsupportedElfSectionTable;
    _ = try elf.bytes(offset, @as(u64, count) * 64);
    const result = try a.alloc(Section, count);
    for (result, 0..) |*section, i| {
        const at = offset + i * 64;
        section.* = .{ .name = try elf.int(u32, at), .kind = try elf.int(u32, at + 4), .flags = try elf.int(u64, at + 8), .offset = try elf.int(u64, at + 24), .size = try elf.int(u64, at + 32), .link = try elf.int(u32, at + 40), .info = try elf.int(u32, at + 44), .entry = try elf.int(u64, at + 56) };
        if (section.kind != 8) _ = try elf.payload(section.*);
    }
    return result;
}
fn tuple(a: std.mem.Allocator, values: []const u.Value) !u.Value {
    var result = u.array(a);
    for (values) |value| try u.add(&result, value);
    return result;
}
fn compare(lhs: u.Value, rhs: u.Value) std.math.Order {
    if (lhs == .string and rhs == .string) return std.mem.order(u8, lhs.string, rhs.string);
    if (lhs == .integer and rhs == .integer) return std.math.order(lhs.integer, rhs.integer);
    if (lhs == .array and rhs == .array) {
        for (0..@min(lhs.array.items.len, rhs.array.items.len)) |i| {
            const order = compare(lhs.array.items[i], rhs.array.items[i]);
            if (order != .eq) return order;
        }
        return std.math.order(lhs.array.items.len, rhs.array.items.len);
    }
    if (lhs == .number_string and rhs == .number_string) {
        const order = std.math.order(lhs.number_string.len, rhs.number_string.len);
        return if (order != .eq) order else std.mem.order(u8, lhs.number_string, rhs.number_string);
    }
    return std.math.order(@backingInt(lhs), @backingInt(rhs));
}
fn sort(value: *u.Value) void {
    std.mem.sort(u.Value, value.array.items, {}, struct {
        fn less(_: void, lhs: u.Value, rhs: u.Value) bool {
            return compare(lhs, rhs) == .lt;
        }
    }.less);
}
pub fn parse(a: std.mem.Allocator, data: []const u8) !u.Value {
    const elf: Elf = .{ .data = data };
    const table = try sections(a, elf);
    if (try elf.int(u16, 16) != 1 or try elf.int(u16, 18) != 62) return error.ExpectedX8664Relocatable;
    const strings_index = try elf.int(u16, 62);
    if (strings_index >= table.len) return error.InvalidElfStringTable;
    const names_table = try elf.payload(table[strings_index]);
    const names = try a.alloc([]const u8, table.len);
    for (table, names) |section, *name| name.* = try string(names_table, section.name);
    var allocated = u.array(a);
    var defined = u.array(a);
    var relocations = u.array(a);
    const symbols = try a.alloc(?[][]const u8, table.len);
    @memset(symbols, null);
    for (table, 0..) |section, index| {
        if (section.flags & 2 != 0) {
            const content = if (section.kind == 8) "" else try elf.payload(section);
            try u.add(&allocated, try tuple(a, &.{ u.s(names[index]), u.n(section.kind), try u.big(a, section.flags), try u.big(a, section.size), u.s(try u.digestBytes(a, content)) }));
        }
        if (section.kind != 2) continue;
        if (section.entry != 24 or section.size % 24 != 0 or section.link >= table.len) return error.InvalidElfSymbolTable;
        const strings = try elf.payload(table[section.link]);
        const entries = try a.alloc([]const u8, @intCast(section.size / 24));
        for (entries, 0..) |*entry, i| {
            const at = section.offset + i * 24;
            const info = try elf.int(u8, at + 4);
            const owner = try elf.int(u16, at + 6);
            if (info & 15 == 3 and owner >= table.len) return error.InvalidElfSectionSymbol;
            const name = if (info & 15 == 3) names[owner] else try string(strings, try elf.int(u32, at));
            entry.* = name;
            if (name.len != 0 and info & 15 != 3) try u.add(&defined, try tuple(a, &.{ u.s(name), u.n(info), u.n(try elf.int(u8, at + 5)), if (owner < table.len) u.s(names[owner]) else u.n(owner), try u.big(a, try elf.int(u64, at + 8)), try u.big(a, try elf.int(u64, at + 16)) }));
        }
        symbols[index] = entries;
    }
    for (table) |section| {
        if (section.kind == 9) return error.UnsupportedElfRelRelocation;
        if (section.kind != 4) continue;
        if (section.entry != 24 or section.size % 24 != 0 or section.link >= table.len or section.info >= table.len) return error.InvalidElfRelocationTable;
        const entries = symbols[section.link] orelse return error.InvalidElfRelocationSymbols;
        for (0..@intCast(section.size / 24)) |i| {
            const at = section.offset + i * 24;
            const info = try elf.int(u64, at + 8);
            if (info >> 32 >= entries.len) return error.InvalidElfRelocationSymbol;
            try u.add(&relocations, try tuple(a, &.{ u.s(names[section.info]), try u.big(a, try elf.int(u64, at)), u.n(info & 0xffffffff), u.s(entries[@intCast(info >> 32)]), u.n(try elf.int(i64, at + 16)) }));
        }
    }
    sort(&allocated);
    sort(&defined);
    sort(&relocations);
    var result = u.object(a);
    try u.put(a, &result, "allocated_sections", allocated);
    try u.put(a, &result, "symbols", defined);
    try u.put(a, &result, "relocations", relocations);
    return result;
}
pub fn executableBytes(a: std.mem.Allocator, data: []const u8) !u64 {
    var total: u64 = 0;
    for (try sections(a, .{ .data = data })) |section| if (section.flags & 4 != 0) {
        total = try std.math.add(u64, total, section.size);
    };
    return total;
}

test "object contracts reject malformed headers and overflowing section tables" {
    try std.testing.expectError(error.ExpectedElf64LittleEndian, parse(std.testing.allocator, "not ELF"));
    var bytes: [64]u8 = @splat(0);
    @memcpy(bytes[0..6], "\x7fELF\x02\x01");
    std.mem.writeInt(u64, bytes[40..48], std.math.maxInt(u64), .little);
    std.mem.writeInt(u16, bytes[58..60], 64, .little);
    std.mem.writeInt(u16, bytes[60..62], 1, .little);
    try std.testing.expectError(error.InvalidElfBounds, parse(std.testing.allocator, &bytes));
}
