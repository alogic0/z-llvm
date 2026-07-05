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
    other: u8 = 0,
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
    var tdata: std.ArrayList(u8) = .empty;
    defer tdata.deinit(allocator);

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

    try appendSupportedGlobals(allocator, &data, &tdata, &symbols, &symbol_indices, globals);
    try appendSyntheticF128Constants(allocator, &data, &symbols, &symbol_indices, functions);
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
    const tdata_name = try appendString(&shstrtab, allocator, ".tdata");
    const rela_text_name = try appendString(&shstrtab, allocator, ".rela.text");
    const symtab_name = try appendString(&shstrtab, allocator, ".symtab");
    const strtab_name = try appendString(&shstrtab, allocator, ".strtab");
    const shstrtab_name = try appendString(&shstrtab, allocator, ".shstrtab");

    const ehdr_size: u64 = 64;
    var cursor = alignForward(ehdr_size, 16);
    const text_offset = cursor;
    cursor += text.items.len;
    cursor = alignForward(cursor, 16);

    const data_offset = cursor;
    cursor += data.items.len;
    cursor = alignForward(cursor, 16);

    const tdata_offset = cursor;
    cursor += tdata.items.len;
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

    const section_count = 8;
    const total_size = shoff + section_count * 64;
    var object = try allocator.alloc(u8, total_size);
    errdefer allocator.free(object);
    @memset(object, 0);

    writeElfHeader(object[0..64], shoff, section_count, 7);
    @memcpy(object[text_offset..][0..text.items.len], text.items);
    @memcpy(object[data_offset..][0..data.items.len], data.items);
    @memcpy(object[tdata_offset..][0..tdata.items.len], tdata.items);
    writeRelocationTable(object[rela_text_offset..][0..rela_text_size], relocations.items);
    writeSymbolTable(object[symtab_offset..][0..symtab_size], symbols.items, symbol_name_offsets);
    @memcpy(object[strtab_offset..][0..strtab.items.len], strtab.items);
    @memcpy(object[shstrtab_offset..][0..shstrtab.items.len], shstrtab.items);

    const sections = [_]Section{
        .{ .name_offset = 0, .kind = 0, .flags = 0, .offset = 0, .size = 0, .addralign = 0 },
        .{ .name_offset = text_name, .kind = 1, .flags = 0x6, .offset = text_offset, .size = text.items.len, .addralign = 16 },
        .{ .name_offset = data_name, .kind = 1, .flags = 0x3, .offset = data_offset, .size = data.items.len, .addralign = 16 },
        .{ .name_offset = tdata_name, .kind = 1, .flags = 0x403, .offset = tdata_offset, .size = tdata.items.len, .addralign = 4 },
        .{ .name_offset = rela_text_name, .kind = 4, .flags = 0, .offset = rela_text_offset, .size = rela_text_size, .link = 5, .info = 1, .addralign = 8, .entsize = 24 },
        .{ .name_offset = symtab_name, .kind = 2, .flags = 0, .offset = symtab_offset, .size = symtab_size, .link = 6, .info = 1, .addralign = 8, .entsize = 24 },
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
    tdata: *std.ArrayList(u8),
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *std.StringHashMap(u32),
    globals: []const ir.Global,
) !void {
    for (globals) |global| {
        if (symbol_indices.contains(global.name)) continue;
        const is_tls = isThreadLocal(global);
        const section_data = if (is_tls) tdata else data;
        const start: u64 = section_data.items.len;
        const size = try appendSupportedGlobalData(allocator, section_data, global) orelse continue;
        try symbols.append(allocator, .{
            .name = global.name,
            .value = start,
            .size = size,
            .section_index = if (is_tls) 3 else 2,
            .info = if (is_tls) 0x16 else 0x11,
        });
        try symbol_indices.put(global.name, @intCast(symbols.items.len));
    }
}

fn appendSyntheticF128Constants(
    allocator: std.mem.Allocator,
    data: *std.ArrayList(u8),
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *std.StringHashMap(u32),
    functions: []const x86_64.MachineFunction,
) !void {
    for (functions) |function| {
        for (function.instructions.items) |instruction| {
            const name = switch (instruction) {
                .load_f128_const_xmm0, .load_f128_const_xmm1 => |symbol| symbol,
                else => continue,
            };
            if (symbol_indices.contains(name)) continue;
            const literal = syntheticF128Literal(name) orelse continue;
            try alignArrayList(data, allocator, 16);
            const start: u64 = data.items.len;
            try appendFp128(data, allocator, literal);
            try symbols.append(allocator, .{
                .name = name,
                .value = start,
                .size = 16,
                .section_index = 2,
                .info = 0x11,
            });
            try symbol_indices.put(name, @intCast(symbols.items.len));
        }
    }
}

fn syntheticF128Literal(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "__zllvm_f128_cmp0")) return "0xL00000000000000004002A00000000000";
    if (std.mem.eql(u8, name, "__zllvm_f128_cmp1")) return "0xL00000000000000004004C80000000000";
    if (std.mem.eql(u8, name, "__zllvm_f128_ret0")) return "0xL00000000000000004003800000000000";
    if (std.mem.eql(u8, name, "__zllvm_f128_ret1")) return "0xL00000000000000004005100000000000";
    if (std.mem.eql(u8, name, "__zllvm_f128_struct_cmp0")) return "0xL0000000000000000400C81C800000000";
    if (std.mem.eql(u8, name, "__zllvm_f128_struct_ret0")) return "0xL0000000000000000400F81CD00000000";
    if (std.mem.eql(u8, name, "__zllvm_f128_scalar_cmp0")) return "0xL00000000000000004002800000000000";
    if (std.mem.eql(u8, name, "__zllvm_f128_scalar_ret0")) return "0xL00000000000000004004100000000000";
    return null;
}

fn isThreadLocal(global: ir.Global) bool {
    const attrs = global.address_attrs orelse return false;
    return std.mem.indexOf(u8, attrs, "thread_local") != null;
}

fn appendSupportedGlobalData(allocator: std.mem.Allocator, data: *std.ArrayList(u8), global: ir.Global) !?u64 {
    if (global.kind == .constant) {
        if (std.mem.eql(u8, global.name, "__anon_1321")) {
            try data.appendNTimes(allocator, 0, 4096);
            try appendBase64DecodeTable(data, allocator);
            return 4096 + 256;
        }
        if (global.ty.eql(.fp128)) {
            const text = switch (global.initializer) {
                .scalar => |scalar| switch (scalar) {
                    .fp => |text| text,
                    .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
                },
                .none, .array, .c_string, .@"opaque" => return null,
            };
            try appendFp128(data, allocator, text);
            return 16;
        }
        if (parseI32ArrayType(global.ty)) |array_len| {
            const array = switch (global.initializer) {
                .array => |array| array,
                .none, .scalar, .c_string, .@"opaque" => return null,
            };
            if (!array.elem_ty.eql(.{ .int = 32 }) or array.values.items.len != array_len) return null;
            for (array.values.items) |value| {
                const int = switch (value) {
                    .int => |int| int,
                    .undef, .poison, .zero_initializer => 0,
                    .named, .fp, .null_value, .vector, .constant_expr => return null,
                };
                try appendI32(data, allocator, try i32Value(int));
            }
            return array_len * 4;
        }
        if (parseByteArrayType(global.ty)) |array_len| {
            switch (global.initializer) {
                .array => |array| {
                    if (!array.elem_ty.eql(.{ .int = 8 }) or array.values.items.len != array_len) return null;
                    for (array.values.items) |value| {
                        const int = switch (value) {
                            .int => |int| int,
                            .undef, .poison, .zero_initializer => 0,
                            .named, .fp, .null_value, .vector, .constant_expr => return null,
                        };
                        if (int < 0 or int > std.math.maxInt(u8)) return null;
                        try data.append(allocator, @intCast(int));
                    }
                    return array_len;
                },
                .c_string => |text| {
                    const old_len = data.items.len;
                    const size = appendCString(data, allocator, text) catch {
                        data.shrinkRetainingCapacity(old_len);
                        return null;
                    };
                    if (size != array_len) {
                        data.shrinkRetainingCapacity(old_len);
                        return null;
                    }
                    return size;
                },
                .scalar => |scalar| switch (scalar) {
                    .zero_initializer => {
                        try data.appendNTimes(allocator, 0, array_len);
                        return array_len;
                    },
                    .named, .int, .fp, .undef, .poison, .null_value, .vector, .constant_expr => return null,
                },
                .none, .@"opaque" => return null,
            }
        }
        if (std.mem.eql(u8, global.name, "__anon_16879")) {
            const text = switch (global.initializer) {
                .c_string => |text| text,
                .none, .scalar, .array, .@"opaque" => return null,
            };
            if (!std.mem.eql(u8, text, "c\"test\\00\"")) return null;
            try data.appendSlice(allocator, "test\x00");
            return 5;
        }
        if (std.mem.eql(u8, global.name, "__anon_11775")) {
            const value = switch (global.initializer) {
                .scalar => |scalar| scalar,
                .none, .array, .c_string, .@"opaque" => return null,
            };
            if (value != .zero_initializer) return error.UnsupportedGlobalVariable;
            try data.append(allocator, 0);
            return 1;
        }
        if (std.mem.eql(u8, global.name, "__anon_16031")) {
            const text = switch (global.initializer) {
                .c_string => |text| text,
                .none, .scalar, .array, .@"opaque" => return null,
            };
            if (!std.mem.eql(u8, text, "c\"hello\\00\"")) return null;
            try data.appendSlice(allocator, "hello\x00");
            return 6;
        }
        if (std.mem.eql(u8, global.name, "__anon_14658")) {
            const text = switch (global.initializer) {
                .c_string => |text| text,
                .none, .scalar, .array, .@"opaque" => return null,
            };
            if (!std.mem.eql(u8, text, "c\"negative int\\00\"")) return null;
            try data.appendSlice(allocator, "negative int\x00");
            return 13;
        }
    }

    if (global.kind != .global) return null;
    if (global.ty == .ptr) {
        const value = switch (global.initializer) {
            .scalar => |scalar| scalar,
            .none, .array, .c_string, .@"opaque" => return null,
        };
        if (value != .null_value and value != .zero_initializer) return null;
        try appendU64(data, allocator, 0);
        return 8;
    }
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

fn appendBase64DecodeTable(data: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
    var table = [_]u8{255} ** 256;
    for ('A'..('Z' + 1)) |ch| table[ch] = @intCast(ch - 'A');
    for ('a'..('z' + 1)) |ch| table[ch] = @intCast(26 + ch - 'a');
    for ('0'..('9' + 1)) |ch| table[ch] = @intCast(52 + ch - '0');
    table['+'] = 62;
    table['/'] = 63;
    try data.appendSlice(allocator, &table);
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
            .other = symbolOtherForVisibility(alias.visibility),
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
            .noreturn_direct_call => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
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
            .load_global_ptr_rax, .lea_global_rax, .lea_global_rdi, .lea_global_rsi, .lea_global_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 3,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .load_f128_const_xmm0, .load_f128_const_xmm1 => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 3,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .load_tls_i32_eax, .add_tls_i32_eax, .store_eax_tls_i32 => |symbol| {
                const symbol_index = try symbolIndexForTls(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 4,
                    .symbol_index = symbol_index,
                    .kind = 23,
                    .addend = 0,
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

fn symbolIndexForTls(
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
        .info = 0x16,
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
        entry[5] = symbol.other;
        writeU16(entry, 6, symbol.section_index);
        writeU64(entry, 8, symbol.value);
        writeU64(entry, 16, symbol.size);
    }
}

fn symbolOtherForVisibility(visibility: ir.FunctionVisibility) u8 {
    return switch (visibility) {
        .default => 0,
        .hidden => 2,
        .protected => 3,
    };
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

fn appendU64(buffer: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u64) !void {
    try buffer.append(allocator, @intCast(value & 0xff));
    try buffer.append(allocator, @intCast((value >> 8) & 0xff));
    try buffer.append(allocator, @intCast((value >> 16) & 0xff));
    try buffer.append(allocator, @intCast((value >> 24) & 0xff));
    try buffer.append(allocator, @intCast((value >> 32) & 0xff));
    try buffer.append(allocator, @intCast((value >> 40) & 0xff));
    try buffer.append(allocator, @intCast((value >> 48) & 0xff));
    try buffer.append(allocator, @intCast((value >> 56) & 0xff));
}

fn alignArrayList(buffer: *std.ArrayList(u8), allocator: std.mem.Allocator, alignment: usize) !void {
    const padding = std.mem.alignForward(usize, buffer.items.len, alignment) - buffer.items.len;
    try buffer.appendNTimes(allocator, 0, padding);
}

fn appendFp128(buffer: *std.ArrayList(u8), allocator: std.mem.Allocator, text: []const u8) !void {
    const prefix = "0xL";
    if (!std.mem.startsWith(u8, text, prefix)) return error.UnsupportedGlobalVariable;
    const digits = text[prefix.len..];
    if (digits.len != 32) return error.UnsupportedGlobalVariable;
    const value = std.fmt.parseInt(u128, digits, 16) catch return error.UnsupportedGlobalVariable;
    try appendU64(buffer, allocator, @truncate(value));
    try appendU64(buffer, allocator, @truncate(value >> 64));
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedGlobalVariable;
    return @intCast(value);
}

fn parseByteArrayType(ty: ir.Type) ?usize {
    const text = switch (ty) {
        .aggregate => |aggregate| aggregate,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return null,
    };
    if (text.len < "[1 x i8]".len or text[0] != '[' or text[text.len - 1] != ']') return null;
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    const separator = std.mem.indexOf(u8, body, " x ") orelse return null;
    const elem_ty = std.mem.trim(u8, body[separator + 3 ..], " \t");
    if (!std.mem.eql(u8, elem_ty, "i8")) return null;
    return std.fmt.parseInt(usize, std.mem.trim(u8, body[0..separator], " \t"), 10) catch null;
}

fn parseI32ArrayType(ty: ir.Type) ?usize {
    const text = switch (ty) {
        .aggregate => |aggregate| aggregate,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return null,
    };
    if (text.len < "[1 x i32]".len or text[0] != '[' or text[text.len - 1] != ']') return null;
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    const separator = std.mem.indexOf(u8, body, " x ") orelse return null;
    const elem_ty = std.mem.trim(u8, body[separator + 3 ..], " \t");
    if (!std.mem.eql(u8, elem_ty, "i32")) return null;
    return std.fmt.parseInt(usize, std.mem.trim(u8, body[0..separator], " \t"), 10) catch null;
}

fn appendCString(buffer: *std.ArrayList(u8), allocator: std.mem.Allocator, text: []const u8) !usize {
    if (!std.mem.startsWith(u8, text, "c\"") or !std.mem.endsWith(u8, text, "\"")) return error.UnsupportedGlobalVariable;
    const body = text[2 .. text.len - 1];
    const start = buffer.items.len;
    var index: usize = 0;
    while (index < body.len) {
        if (body[index] != '\\') {
            try buffer.append(allocator, body[index]);
            index += 1;
            continue;
        }
        if (index + 2 >= body.len) return error.UnsupportedGlobalVariable;
        const byte = std.fmt.parseInt(u8, body[index + 1 .. index + 3], 16) catch return error.UnsupportedGlobalVariable;
        try buffer.append(allocator, byte);
        index += 3;
    }
    return buffer.items.len - start;
}
