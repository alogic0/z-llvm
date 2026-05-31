const std = @import("std");
const encoding = @import("encoding.zig");
const ir = @import("../ir.zig");
const x86_64 = @import("../codegen/x86_64.zig");

const Section = struct {
    name_offset: u32,
    kind: u32,
    flags: u64,
    offset: u64,
    size: u64,
    link: u32 = 0,
    info: u32 = 0,
    addralign: u64 = 1,
    entsize: u64 = 0,
};

const Symbol = struct {
    name: []const u8,
    value: u64,
    size: u64,
    section_index: u16,
    info: u8,
};

const Relocation = struct {
    offset: u64,
    symbol_index: u32,
    kind: u32,
    addend: i64,
};

pub fn writeObject(allocator: std.mem.Allocator, functions: []const x86_64.MachineFunction, writer: anytype) !void {
    const object = try buildObject(allocator, functions);
    defer allocator.free(object);
    try writer.writeAll(object);
}

pub fn buildObject(allocator: std.mem.Allocator, functions: []const x86_64.MachineFunction) ![]u8 {
    return try buildObjectWithModuleData(allocator, functions, &.{}, &.{});
}

pub fn writeObjectWithAliases(
    allocator: std.mem.Allocator,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
    writer: anytype,
) !void {
    const object = try buildObjectWithAliases(allocator, functions, aliases);
    defer allocator.free(object);
    try writer.writeAll(object);
}

pub fn writeObjectWithModuleData(
    allocator: std.mem.Allocator,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
    globals: []const ir.Global,
    writer: anytype,
) !void {
    const object = try buildObjectWithModuleData(allocator, functions, aliases, globals);
    defer allocator.free(object);
    try writer.writeAll(object);
}

pub fn buildObjectWithAliases(
    allocator: std.mem.Allocator,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
) ![]u8 {
    return try buildObjectWithModuleData(allocator, functions, aliases, &.{});
}

pub fn buildObjectWithModuleData(
    allocator: std.mem.Allocator,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
    globals: []const ir.Global,
) ![]u8 {
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(allocator);
    var data: std.ArrayList(u8) = .empty;
    defer data.deinit(allocator);

    var symbols: std.ArrayList(Symbol) = .empty;
    defer symbols.deinit(allocator);
    var symbol_indices = std.StringHashMap(u32).init(allocator);
    defer symbol_indices.deinit();

    const function_offsets = try allocator.alloc(u64, functions.len);
    defer allocator.free(function_offsets);

    for (functions, 0..) |function, function_index| {
        const start: u64 = text.items.len;
        function_offsets[function_index] = start;
        const bytes = try encoding.encodeFunction(allocator, function);
        defer allocator.free(bytes);
        try text.appendSlice(allocator, bytes);
        try symbols.append(allocator, .{
            .name = function.name,
            .value = start,
            .size = bytes.len,
            .section_index = 1,
            .info = 0x12,
        });
        try symbol_indices.put(function.name, @intCast(symbols.items.len));
    }

    try appendSupportedGlobals(allocator, &data, &symbols, &symbol_indices, globals);
    try appendLocalFunctionAliases(allocator, &symbols, &symbol_indices, aliases);

    var relocations: std.ArrayList(Relocation) = .empty;
    defer relocations.deinit(allocator);
    for (functions, 0..) |function, function_index| {
        try collectCallRelocations(allocator, &relocations, &symbols, &symbol_indices, function_offsets[function_index], function);
    }

    var strtab: std.ArrayList(u8) = .empty;
    defer strtab.deinit(allocator);
    try strtab.append(allocator, 0);
    const symbol_name_offsets = try allocator.alloc(u32, symbols.items.len);
    defer allocator.free(symbol_name_offsets);
    for (symbols.items, 0..) |symbol, index| {
        symbol_name_offsets[index] = @intCast(strtab.items.len);
        try strtab.appendSlice(allocator, symbol.name);
        try strtab.append(allocator, 0);
    }

    var shstrtab: std.ArrayList(u8) = .empty;
    defer shstrtab.deinit(allocator);
    try shstrtab.append(allocator, 0);
    const text_name = try appendString(&shstrtab, allocator, ".text");
    const data_name = try appendString(&shstrtab, allocator, ".data");
    const rela_text_name = try appendString(&shstrtab, allocator, ".rela.text");
    const symtab_name = try appendString(&shstrtab, allocator, ".symtab");
    const strtab_name = try appendString(&shstrtab, allocator, ".strtab");
    const shstrtab_name = try appendString(&shstrtab, allocator, ".shstrtab");

    const ehdr_size: u64 = 64;
    var cursor = alignForward(ehdr_size, 16);
    const text_offset = cursor;
    cursor += text.items.len;
    cursor = alignForward(cursor, 4);

    const data_offset = cursor;
    cursor += data.items.len;
    cursor = alignForward(cursor, 8);

    const rela_text_offset = cursor;
    const rela_text_size = relocations.items.len * 24;
    cursor += rela_text_size;
    cursor = alignForward(cursor, 8);

    const symtab_offset = cursor;
    const symtab_entry_count = symbols.items.len + 1;
    const symtab_size = symtab_entry_count * 24;
    cursor += symtab_size;

    const strtab_offset = cursor;
    cursor += strtab.items.len;

    const shstrtab_offset = cursor;
    cursor += shstrtab.items.len;
    cursor = alignForward(cursor, 8);
    const shoff = cursor;

    const section_count = 7;
    const total_size = shoff + section_count * 64;
    var object = try allocator.alloc(u8, total_size);
    errdefer allocator.free(object);
    @memset(object, 0);

    writeElfHeader(object[0..64], shoff, section_count, 6);
    @memcpy(object[text_offset..][0..text.items.len], text.items);
    @memcpy(object[data_offset..][0..data.items.len], data.items);
    writeRelocationTable(object[rela_text_offset..][0..rela_text_size], relocations.items);
    writeSymbolTable(object[symtab_offset..][0..symtab_size], symbols.items, symbol_name_offsets);
    @memcpy(object[strtab_offset..][0..strtab.items.len], strtab.items);
    @memcpy(object[shstrtab_offset..][0..shstrtab.items.len], shstrtab.items);

    const sections = [_]Section{
        .{ .name_offset = 0, .kind = 0, .flags = 0, .offset = 0, .size = 0, .addralign = 0 },
        .{ .name_offset = text_name, .kind = 1, .flags = 0x6, .offset = text_offset, .size = text.items.len, .addralign = 16 },
        .{ .name_offset = data_name, .kind = 1, .flags = 0x3, .offset = data_offset, .size = data.items.len, .addralign = 4 },
        .{ .name_offset = rela_text_name, .kind = 4, .flags = 0, .offset = rela_text_offset, .size = rela_text_size, .link = 4, .info = 1, .addralign = 8, .entsize = 24 },
        .{ .name_offset = symtab_name, .kind = 2, .flags = 0, .offset = symtab_offset, .size = symtab_size, .link = 5, .info = 1, .addralign = 8, .entsize = 24 },
        .{ .name_offset = strtab_name, .kind = 3, .flags = 0, .offset = strtab_offset, .size = strtab.items.len },
        .{ .name_offset = shstrtab_name, .kind = 3, .flags = 0, .offset = shstrtab_offset, .size = shstrtab.items.len },
    };
    for (sections, 0..) |section, index| {
        writeSectionHeader(object[shoff + index * 64 ..][0..64], section);
    }

    return object;
}

fn appendSupportedGlobals(
    allocator: std.mem.Allocator,
    data: *std.ArrayList(u8),
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *std.StringHashMap(u32),
    globals: []const ir.Global,
) !void {
    for (globals) |global| {
        if (symbol_indices.contains(global.name)) continue;
        const start: u64 = data.items.len;
        const size = try appendSupportedGlobalData(allocator, data, global) orelse continue;
        try symbols.append(allocator, .{
            .name = global.name,
            .value = start,
            .size = size,
            .section_index = 2,
            .info = 0x11,
        });
        try symbol_indices.put(global.name, @intCast(symbols.items.len));
    }
}

fn appendSupportedGlobalData(allocator: std.mem.Allocator, data: *std.ArrayList(u8), global: ir.Global) !?u64 {
    if (global.kind != .global) return null;
    if (!global.ty.eql(.{ .int = 32 })) return null;

    const value: i32 = switch (global.initializer) {
        .scalar => |scalar| switch (scalar) {
            .int => |int| try i32Value(int),
            .zero_initializer => 0,
            .named, .fp, .undef, .poison, .null_value, .vector, .constant_expr => return null,
        },
        .none, .array, .c_string, .@"opaque" => return null,
    };
    try appendI32(data, allocator, value);
    return 4;
}

fn appendLocalFunctionAliases(
    allocator: std.mem.Allocator,
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *std.StringHashMap(u32),
    aliases: []const ir.GlobalAlias,
) !void {
    for (aliases) |alias| {
        if (symbol_indices.contains(alias.name)) continue;
        const target_index = symbol_indices.get(alias.target) orelse continue;
        const target_symbol = symbols.items[target_index - 1];
        if (target_symbol.section_index == 0) continue;
        try symbols.append(allocator, .{
            .name = alias.name,
            .value = target_symbol.value,
            .size = target_symbol.size,
            .section_index = target_symbol.section_index,
            .info = target_symbol.info,
        });
        try symbol_indices.put(alias.name, @intCast(symbols.items.len));
    }
}

fn collectCallRelocations(
    allocator: std.mem.Allocator,
    relocations: *std.ArrayList(Relocation),
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *std.StringHashMap(u32),
    function_offset: u64,
    function: x86_64.MachineFunction,
) !void {
    var offset: u64 = 0;
    for (function.instructions.items) |instruction| {
        switch (instruction) {
            .direct_call => |call| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, call.symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 1,
                    .symbol_index = symbol_index,
                    .kind = 4,
                    .addend = -4,
                });
            },
            .atomic_xadd_global_eax => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 4,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .load_global_i32_eax, .store_eax_global_i32 => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 2,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            else => {},
        }
        offset += encoding.instructionSize(instruction);
    }
}

fn symbolIndexForCall(
    allocator: std.mem.Allocator,
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *std.StringHashMap(u32),
    name: []const u8,
) !u32 {
    if (symbol_indices.get(name)) |index| return index;
    try symbols.append(allocator, .{
        .name = name,
        .value = 0,
        .size = 0,
        .section_index = 0,
        .info = 0x10,
    });
    const index: u32 = @intCast(symbols.items.len);
    try symbol_indices.put(name, index);
    return index;
}

fn appendString(buffer: *std.ArrayList(u8), allocator: std.mem.Allocator, text: []const u8) !u32 {
    const offset: u32 = @intCast(buffer.items.len);
    try buffer.appendSlice(allocator, text);
    try buffer.append(allocator, 0);
    return offset;
}

fn writeElfHeader(header: []u8, shoff: u64, section_count: u16, shstr_index: u16) void {
    header[0] = 0x7f;
    header[1] = 'E';
    header[2] = 'L';
    header[3] = 'F';
    header[4] = 2;
    header[5] = 1;
    header[6] = 1;
    writeU16(header, 16, 1);
    writeU16(header, 18, 62);
    writeU32(header, 20, 1);
    writeU64(header, 40, shoff);
    writeU16(header, 52, 64);
    writeU16(header, 58, 64);
    writeU16(header, 60, section_count);
    writeU16(header, 62, shstr_index);
}

fn writeRelocationTable(buffer: []u8, relocations: []const Relocation) void {
    for (relocations, 0..) |relocation, index| {
        const entry = buffer[index * 24 ..][0..24];
        writeU64(entry, 0, relocation.offset);
        writeU64(entry, 8, (@as(u64, relocation.symbol_index) << 32) | relocation.kind);
        writeU64(entry, 16, @bitCast(relocation.addend));
    }
}

fn writeSymbolTable(buffer: []u8, symbols: []const Symbol, name_offsets: []const u32) void {
    for (symbols, 0..) |symbol, index| {
        const entry = buffer[(index + 1) * 24 ..][0..24];
        writeU32(entry, 0, name_offsets[index]);
        entry[4] = symbol.info;
        writeU16(entry, 6, symbol.section_index);
        writeU64(entry, 8, symbol.value);
        writeU64(entry, 16, symbol.size);
    }
}

fn writeSectionHeader(header: []u8, section: Section) void {
    writeU32(header, 0, section.name_offset);
    writeU32(header, 4, section.kind);
    writeU64(header, 8, section.flags);
    writeU64(header, 24, section.offset);
    writeU64(header, 32, section.size);
    writeU32(header, 40, section.link);
    writeU32(header, 44, section.info);
    writeU64(header, 48, section.addralign);
    writeU64(header, 56, section.entsize);
}

fn alignForward(value: u64, alignment: u64) u64 {
    return (value + alignment - 1) & ~(alignment - 1);
}

fn writeU16(buffer: []u8, offset: usize, value: u16) void {
    buffer[offset] = @intCast(value & 0xff);
    buffer[offset + 1] = @intCast((value >> 8) & 0xff);
}

fn writeU32(buffer: []u8, offset: usize, value: u32) void {
    buffer[offset] = @intCast(value & 0xff);
    buffer[offset + 1] = @intCast((value >> 8) & 0xff);
    buffer[offset + 2] = @intCast((value >> 16) & 0xff);
    buffer[offset + 3] = @intCast((value >> 24) & 0xff);
}

fn writeU64(buffer: []u8, offset: usize, value: u64) void {
    writeU32(buffer, offset, @intCast(value & 0xffff_ffff));
    writeU32(buffer, offset + 4, @intCast(value >> 32));
}

fn appendI32(buffer: *std.ArrayList(u8), allocator: std.mem.Allocator, value: i32) !void {
    const raw: u32 = @bitCast(value);
    try buffer.append(allocator, @intCast(raw & 0xff));
    try buffer.append(allocator, @intCast((raw >> 8) & 0xff));
    try buffer.append(allocator, @intCast((raw >> 16) & 0xff));
    try buffer.append(allocator, @intCast((raw >> 24) & 0xff));
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedGlobalVariable;
    return @intCast(value);
}
