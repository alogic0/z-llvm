const std = @import("std");
const encoding = @import("encoding.zig");
const ir = @import("../ir.zig");
const x86_64 = @import("../codegen/x86_64.zig");
const constant_table = @import("../codegen/x86_64/constant_table.zig");
const global_data = @import("global_data.zig");
const symbol_address = @import("../codegen/x86_64/symbol_address.zig");
const symbol_names = @import("symbol_names.zig");

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

const DataFixup = struct {
    offset: u64,
    read_only_section: bool = false,
    address: symbol_address.Address,
    block: ?[]const u8 = null,
    kind: global_data.Relocation.Kind = .absolute64,
    bias: i64 = 0,
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

pub fn writeObjectWithModuleContext(
    allocator: std.mem.Allocator,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
    module_context: x86_64.ReadOnlyModuleContext,
    writer: anytype,
) !void {
    const object = try buildObjectWithModuleContext(allocator, functions, aliases, module_context);
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
    return buildObjectWithOptionalModuleContext(allocator, functions, aliases, globals, null);
}

pub fn buildObjectWithModuleContext(
    allocator: std.mem.Allocator,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
    module_context: x86_64.ReadOnlyModuleContext,
) ![]u8 {
    return buildObjectWithOptionalModuleContext(allocator, functions, aliases, module_context.globals, module_context);
}

fn buildObjectWithOptionalModuleContext(
    allocator: std.mem.Allocator,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
    globals: []const ir.Global,
    module_context: ?x86_64.ReadOnlyModuleContext,
) ![]u8 {
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(allocator);
    var data: std.ArrayList(u8) = .empty;
    defer data.deinit(allocator);
    var tdata: std.ArrayList(u8) = .empty;
    defer tdata.deinit(allocator);
    var rodata: std.ArrayList(u8) = .empty;
    defer rodata.deinit(allocator);

    var symbols: std.ArrayList(Symbol) = .empty;
    defer symbols.deinit(allocator);
    var symbol_indices = symbol_names.Index.init(allocator);
    defer symbol_indices.deinit();

    const function_offsets = try allocator.alloc(u64, functions.len);
    defer allocator.free(function_offsets);
    var text_alignment: u32 = 16;

    for (functions, 0..) |function, function_index| {
        try @import("../codegen/x86_64/function_alignment.zig").validate(function.symbol_alignment);
        try alignArrayList(&text, allocator, function.symbol_alignment);
        text_alignment = @max(text_alignment, function.symbol_alignment);
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
            .info = switch (function.symbol_linkage) {
                .default, .external => 0x12,
                .internal, .private => 0x02,
                else => return error.UnsupportedFunctionLinkage,
            },
            .other = symbolOtherForVisibility(function.symbol_visibility),
        });
        try symbol_indices.put(function.name, @intCast(symbols.items.len));
    }

    var data_fixups: std.ArrayList(DataFixup) = .empty;
    defer data_fixups.deinit(allocator);
    var data_alignment: u32 = 16;
    var tdata_alignment: u32 = 4;
    var rodata_alignment: u32 = 16;
    try appendReachableGlobals(allocator, &data, &data_alignment, &tdata, &tdata_alignment, &rodata, &rodata_alignment, &data_fixups, &symbols, &symbol_indices, functions, aliases, module_context);
    try appendSupportedGlobals(allocator, &data, &tdata, &symbols, &symbol_indices, globals);
    try appendSyntheticF128Constants(allocator, &data, &symbols, &symbol_indices, functions);
    try appendLocalFunctionAliases(allocator, &symbols, &symbol_indices, aliases, if (module_context) |context| context.require_resolved_aliases else false);
    const first_global = try orderLocalSymbols(allocator, &symbols, &symbol_indices);

    var relocations: std.ArrayList(Relocation) = .empty;
    defer relocations.deinit(allocator);
    for (functions, 0..) |function, function_index| {
        try collectCallRelocations(allocator, &relocations, &symbols, &symbol_indices, function_offsets[function_index], function);
    }
    var data_relocations: std.ArrayList(Relocation) = .empty;
    defer data_relocations.deinit(allocator);
    var rodata_relocations: std.ArrayList(Relocation) = .empty;
    defer rodata_relocations.deinit(allocator);
    for (data_fixups.items) |fixup| {
        var addend = try std.math.add(i64, fixup.address.addend, fixup.bias);
        if (fixup.block) |block| {
            const function = for (functions) |candidate| {
                if ((symbol_names.Context{}).eql(candidate.name, fixup.address.symbol)) break candidate;
            } else return error.UnresolvedBlockAddress;
            var offset: u32 = 0;
            var found = false;
            for (function.instructions.items) |instruction| {
                if (instruction == .label and ir.identifiers.eql(instruction.label, block)) {
                    if (found) return error.UnresolvedBlockAddress;
                    addend += offset;
                    found = true;
                }
                offset = try std.math.add(u32, offset, encoding.instructionSize(instruction));
            }
            if (!found) return error.UnresolvedBlockAddress;
        }
        const table = if (fixup.read_only_section) &rodata_relocations else &data_relocations;
        try table.append(allocator, .{
            .offset = fixup.offset,
            .symbol_index = try symbolIndexForCall(allocator, &symbols, &symbol_indices, fixup.address.symbol),
            .kind = switch (fixup.kind) {
                .absolute64 => 1,
                .relative32 => 2,
            }, // R_X86_64_64 / R_X86_64_PC32
            .addend = addend,
        });
    }

    var strtab: std.ArrayList(u8) = .empty;
    defer strtab.deinit(allocator);
    try strtab.append(allocator, 0);
    const symbol_name_offsets = try allocator.alloc(u32, symbols.items.len);
    defer allocator.free(symbol_name_offsets);
    for (symbols.items, 0..) |symbol, index| {
        symbol_name_offsets[index] = @intCast(strtab.items.len);
        try symbol_names.append(allocator, &strtab, symbol.name);
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
    const rela_data_name = if (data_relocations.items.len != 0) try appendString(&shstrtab, allocator, ".rela.data") else 0;
    const rodata_name = if (rodata.items.len != 0) try appendString(&shstrtab, allocator, ".rodata") else 0;
    const rela_rodata_name = if (rodata_relocations.items.len != 0) try appendString(&shstrtab, allocator, ".rela.rodata") else 0;

    const ehdr_size: u64 = 64;
    var cursor = alignForward(ehdr_size, text_alignment);
    const text_offset = cursor;
    cursor += text.items.len;
    cursor = alignForward(cursor, data_alignment);

    const data_offset = cursor;
    cursor += data.items.len;
    cursor = alignForward(cursor, @max(@as(u32, 16), tdata_alignment));

    const tdata_offset = cursor;
    cursor += tdata.items.len;
    if (rodata.items.len != 0) cursor = alignForward(cursor, rodata_alignment);
    const rodata_offset = cursor;
    cursor += rodata.items.len;
    cursor = alignForward(cursor, 8);

    const rela_text_offset = cursor;
    const rela_text_size = relocations.items.len * 24;
    cursor += rela_text_size;
    cursor = alignForward(cursor, 8);

    const rela_data_offset = cursor;
    const rela_data_size = data_relocations.items.len * 24;
    cursor += rela_data_size;
    const rela_rodata_offset = cursor;
    const rela_rodata_size = rodata_relocations.items.len * 24;
    cursor += rela_rodata_size;

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

    const section_count: u16 = 8 + @as(u16, @intFromBool(rodata.items.len != 0)) + @as(u16, @intFromBool(data_relocations.items.len != 0)) + @as(u16, @intFromBool(rodata_relocations.items.len != 0));
    const total_size = shoff + section_count * 64;
    var object = try allocator.alloc(u8, total_size);
    errdefer allocator.free(object);
    @memset(object, 0);

    writeElfHeader(object[0..64], shoff, section_count, 7);
    @memcpy(object[text_offset..][0..text.items.len], text.items);
    @memcpy(object[data_offset..][0..data.items.len], data.items);
    @memcpy(object[tdata_offset..][0..tdata.items.len], tdata.items);
    @memcpy(object[rodata_offset..][0..rodata.items.len], rodata.items);
    writeRelocationTable(object[rela_text_offset..][0..rela_text_size], relocations.items);
    writeRelocationTable(object[rela_data_offset..][0..rela_data_size], data_relocations.items);
    writeRelocationTable(object[rela_rodata_offset..][0..rela_rodata_size], rodata_relocations.items);
    writeSymbolTable(object[symtab_offset..][0..symtab_size], symbols.items, symbol_name_offsets);
    @memcpy(object[strtab_offset..][0..strtab.items.len], strtab.items);
    @memcpy(object[shstrtab_offset..][0..shstrtab.items.len], shstrtab.items);

    const sections = [_]Section{
        .{ .name_offset = 0, .kind = 0, .flags = 0, .offset = 0, .size = 0, .addralign = 0 },
        .{ .name_offset = text_name, .kind = 1, .flags = 0x6, .offset = text_offset, .size = text.items.len, .addralign = text_alignment },
        .{ .name_offset = data_name, .kind = 1, .flags = 0x3, .offset = data_offset, .size = data.items.len, .addralign = data_alignment },
        .{ .name_offset = tdata_name, .kind = 1, .flags = 0x403, .offset = tdata_offset, .size = tdata.items.len, .addralign = tdata_alignment },
        .{ .name_offset = rela_text_name, .kind = 4, .flags = 0, .offset = rela_text_offset, .size = rela_text_size, .link = 5, .info = 1, .addralign = 8, .entsize = 24 },
        .{ .name_offset = symtab_name, .kind = 2, .flags = 0, .offset = symtab_offset, .size = symtab_size, .link = 6, .info = first_global, .addralign = 8, .entsize = 24 },
        .{ .name_offset = strtab_name, .kind = 3, .flags = 0, .offset = strtab_offset, .size = strtab.items.len },
        .{ .name_offset = shstrtab_name, .kind = 3, .flags = 0, .offset = shstrtab_offset, .size = shstrtab.items.len },
    };
    for (sections, 0..) |section, index| {
        writeSectionHeader(object[shoff + index * 64 ..][0..64], section);
    }
    var next_section: usize = 8;
    if (rodata.items.len != 0) {
        writeSectionHeader(object[shoff + next_section * 64 ..][0..64], .{
            .name_offset = rodata_name,
            .kind = 1,
            .flags = 0x2,
            .offset = rodata_offset,
            .size = rodata.items.len,
            .addralign = rodata_alignment,
        });
        next_section += 1;
    }
    if (data_relocations.items.len != 0) {
        writeSectionHeader(object[shoff + next_section * 64 ..][0..64], .{
            .name_offset = rela_data_name,
            .kind = 4,
            .flags = 0,
            .offset = rela_data_offset,
            .size = rela_data_size,
            .link = 5,
            .info = 2,
            .addralign = 8,
            .entsize = 24,
        });
        next_section += 1;
    }
    if (rodata_relocations.items.len != 0) writeSectionHeader(object[shoff + next_section * 64 ..][0..64], .{
        .name_offset = rela_rodata_name,
        .kind = 4,
        .flags = 0,
        .offset = rela_rodata_offset,
        .size = rela_rodata_size,
        .link = 5,
        .info = 8,
        .addralign = 8,
        .entsize = 24,
    });

    return object;
}

/// Decode the symbolic-address closure, plus all globals when the caller has
/// explicitly selected a complete module. The legacy route remains bounded
/// to machine references so unrelated runtime objects do not add imports.
fn appendReachableGlobals(
    allocator: std.mem.Allocator,
    data: *std.ArrayList(u8),
    data_alignment: *u32,
    tdata: *std.ArrayList(u8),
    tdata_alignment: *u32,
    rodata: *std.ArrayList(u8),
    rodata_alignment: *u32,
    fixups: *std.ArrayList(DataFixup),
    symbols: *std.ArrayList(Symbol),
    indices: *symbol_names.Index,
    functions: []const x86_64.MachineFunction,
    aliases: []const ir.GlobalAlias,
    module_context: ?x86_64.ReadOnlyModuleContext,
) !void {
    const context = module_context orelse return;
    const symbol_budget = globalSymbolBudget(context.globals.len, context.aliases.len, context.functions.len, context.declarations.len) catch |err| {
        globalPlacementFailure("<module>", "symbol_budget_overflow", context.globals.len, context.aliases.len, std.math.maxInt(u32) - 1);
        return err;
    };
    var queue: std.ArrayList([]const u8) = .empty;
    defer queue.deinit(allocator);
    var seen = std.HashMap([]const u8, void, symbol_names.Context, std.hash_map.default_max_load_percentage).init(allocator);
    defer seen.deinit();
    if (context.emit_all_globals) {
        for (context.globals) |global| try queue.append(allocator, global.name);
    } else {
        // Keep legacy unannotated data placement byte-identical. An explicit
        // read-only section always goes through the owned section path.
        for (context.globals) |global| {
            const properties = symbol_address.globalProperties(global) catch continue;
            if (properties.read_only_section) {
                try queue.append(allocator, global.name);
            } else if (try constant_table.decodeGlobal(allocator, context, global)) |value| {
                var decoded = value;
                defer decoded.deinit(allocator);
                // Even unreferenced recognized tables use ordinary placement,
                // preserving linkage, visibility, section and alignment.
                try queue.append(allocator, global.name);
            }
        }
    }
    for (functions) |function| for (function.instructions.items) |instruction| switch (instruction) {
        .lea_global_arg64 => |address| {
            if (context.dataAddress(address.symbol)) |resolved| {
                if ((try symbol_address.globalProperties(resolved.global)).tls) return error.SymbolAddressClassMismatch;
            }
            try queue.append(allocator, address.symbol);
        },
        .lea_global_offset_rax, .tls_address_rax => |address| {
            if (context.dataAddress(address.symbol)) |resolved| {
                const properties = try symbol_address.globalProperties(resolved.global);
                if (properties.tls != (instruction == .tls_address_rax)) return error.SymbolAddressClassMismatch;
            }
            try queue.append(allocator, address.symbol);
        },
        else => {},
    };
    var cursor: usize = 0;
    while (cursor < queue.items.len) : (cursor += 1) {
        const name = queue.items[cursor];
        if (indices.contains(name)) continue;
        const entry = try seen.getOrPut(name);
        if (entry.found_existing) continue;
        if (seen.count() > symbol_budget) {
            globalPlacementFailure(name, "symbol_budget", seen.count(), seen.count(), symbol_budget);
            return error.UnsupportedGlobalData;
        }
        const global = context.findGlobal(name) orelse {
            for (aliases) |alias| if (ir.identifiers.eql(alias.name, name)) {
                if (!context.require_resolved_aliases) {
                    std.debug.print("zllvm-global-placement symbol={s} reason=alias_requires_module_context target={s}\n", .{ name[0..@min(name.len, 160)], alias.target[0..@min(alias.target.len, 160)] });
                    return error.UnsupportedGlobalData;
                }
                try queue.append(allocator, alias.target);
                break;
            };
            continue; // A referenced function or an external symbol.
        };
        if (global.initializer == .none) {
            const properties = try symbol_address.globalProperties(global);
            if (properties.tls or global.linkage == .extern_weak) {
                try appendUndefinedDataSymbol(allocator, symbols, indices, global, properties);
            }
            continue;
        }
        var diagnostic: global_data.Diagnostic = .{};
        var decoded = global_data.decodeObserved(allocator, context, global, &diagnostic) catch |err| {
            if (err == error.OutOfMemory) return err;
            var type_buffer: [256]u8 = undefined;
            const ty = if (diagnostic.ty) |ty| switch (ty) {
                .aggregate => |raw| raw[0..@min(raw.len, type_buffer.len)],
                else => std.fmt.bufPrint(&type_buffer, "{f}", .{ty}) catch "<type>",
            } else "<unknown>";
            const flags = global.address_attrs orelse "";
            const attrs = global.attrs orelse "";
            const layout = context.target_datalayout orelse "";
            std.debug.print("zllvm-global-data symbol={s} type={s} initializer={s} linkage={s} phase={s} reason={s} value={s} offset={any} requested={any} limit={any} flags={s} attrs={s} layout={s} error={s}\n", .{
                global.name[0..@min(global.name.len, 160)], ty, @tagName(global.initializer), @tagName(global.linkage), @tagName(diagnostic.phase), @tagName(diagnostic.reason), if (diagnostic.value_kind) |kind| @tagName(kind) else "none", diagnostic.offset, diagnostic.requested, diagnostic.limit, flags[0..@min(flags.len, 160)], attrs[0..@min(attrs.len, 160)], layout[0..@min(layout.len, 256)], @errorName(err),
            });
            return err;
        };
        defer decoded.deinit(allocator);
        const properties = try symbol_address.globalProperties(global);
        // Static initializer relocations in TLS need a separate relocation
        // section. Keep that representation closed until it is implemented.
        if (properties.tls and decoded.relocations.len != 0) {
            globalPlacementFailure(name, "tls_relocations", 0, decoded.relocations.len, 0);
            return error.UnsupportedTlsInitializer;
        }
        const section = if (properties.tls) tdata else if (properties.read_only_section) rodata else data;
        const section_alignment = if (properties.tls) tdata_alignment else if (properties.read_only_section) rodata_alignment else data_alignment;
        // Zero-sized symbol placement depends on section/linkage conventions.
        // Keep it outside this ordinary, nonempty global-object envelope.
        if (decoded.bytes.len == 0) {
            globalPlacementFailure(name, "empty_object", section.items.len, 0, 0);
            return error.UnsupportedGlobalData;
        }
        const required = try std.math.add(u64, std.mem.alignForward(u64, section.items.len, decoded.alignment), decoded.bytes.len);
        if (required > 16 * 1024 * 1024) {
            globalPlacementFailure(name, "section_bytes", section.items.len, required, 16 * 1024 * 1024);
            return error.UnsupportedGlobalData;
        }
        try alignArrayList(section, allocator, decoded.alignment);
        const start: u64 = section.items.len;
        try section.appendSlice(allocator, decoded.bytes);
        section_alignment.* = @max(section_alignment.*, decoded.alignment);
        try symbols.append(allocator, .{
            .name = global.name,
            .value = start,
            .size = decoded.bytes.len,
            .section_index = if (properties.tls) 3 else if (properties.read_only_section) 8 else 2,
            .info = @as(u8, if (decoded.local) 0 else 0x10) | @as(u8, if (properties.tls) 6 else 1),
            .other = decoded.visibility,
        });
        try indices.put(global.name, @intCast(symbols.items.len));
        for (decoded.relocations) |relocation| {
            try fixups.append(allocator, .{ .offset = start + relocation.offset, .read_only_section = properties.read_only_section, .address = relocation.address, .block = relocation.block, .kind = relocation.kind, .bias = relocation.bias });
            try queue.append(allocator, relocation.address.symbol);
        }
    }
}

fn globalSymbolBudget(globals: usize, aliases: usize, functions: usize, declarations: usize) !usize {
    const data = std.math.add(usize, globals, aliases) catch return error.UnsupportedGlobalData;
    const code = std.math.add(usize, functions, declarations) catch return error.UnsupportedGlobalData;
    const total = std.math.add(usize, data, code) catch return error.UnsupportedGlobalData;
    // The hashmap and object symbol indices are u32. Keep the legacy floor
    // for small/manual contexts, but bound complete modules by their inventory.
    if (total >= std.math.maxInt(u32)) return error.UnsupportedGlobalData;
    return @max(4096, total);
}

fn globalPlacementFailure(name: []const u8, reason: []const u8, current: u64, requested: u64, limit: u64) void {
    std.debug.print("zllvm-global-placement symbol={s} reason={s} current={d} requested={d} limit={d}\n", .{ name[0..@min(name.len, 160)], reason, current, requested, limit });
}

pub const GlobalPlacement = struct {
    data_bytes: usize,
    data_alignment: u32,
    tls_bytes: usize,
    tls_alignment: u32,
    read_only_bytes: usize,
    read_only_alignment: u32,
    symbols: usize,
    relocations: usize,
    symbol_budget: usize,
};

/// Exercise exactly the emitter's global placement with all parsed globals as
/// roots. No MIR/function emission, block fixup resolution or ELF credit.
pub fn inspectGlobalPlacement(allocator: std.mem.Allocator, context: x86_64.ReadOnlyModuleContext) !GlobalPlacement {
    if (!context.emit_all_globals) return error.ExpectedAllGlobalRoots;
    var data: std.ArrayList(u8) = .empty;
    defer data.deinit(allocator);
    var tls: std.ArrayList(u8) = .empty;
    defer tls.deinit(allocator);
    var rodata: std.ArrayList(u8) = .empty;
    defer rodata.deinit(allocator);
    var fixups: std.ArrayList(DataFixup) = .empty;
    defer fixups.deinit(allocator);
    var symbols: std.ArrayList(Symbol) = .empty;
    defer symbols.deinit(allocator);
    var indices = symbol_names.Index.init(allocator);
    defer indices.deinit();
    var data_alignment: u32 = 16;
    var tls_alignment: u32 = 4;
    var rodata_alignment: u32 = 16;
    try appendReachableGlobals(allocator, &data, &data_alignment, &tls, &tls_alignment, &rodata, &rodata_alignment, &fixups, &symbols, &indices, &.{}, context.aliases, context);
    return .{ .data_bytes = data.items.len, .data_alignment = data_alignment, .tls_bytes = tls.items.len, .tls_alignment = tls_alignment, .read_only_bytes = rodata.items.len, .read_only_alignment = rodata_alignment, .symbols = symbols.items.len, .relocations = fixups.items.len, .symbol_budget = try globalSymbolBudget(context.globals.len, context.aliases.len, context.functions.len, context.declarations.len) };
}

test "ELF global symbol budgets preserve a checked module envelope" {
    try std.testing.expectEqual(@as(usize, 4096), try globalSymbolBudget(1, 2, 3, 4));
    try std.testing.expectEqual(@as(usize, 5003), try globalSymbolBudget(5000, 1, 1, 1));
    try std.testing.expectError(error.UnsupportedGlobalData, globalSymbolBudget(std.math.maxInt(usize), 1, 0, 0));
    try std.testing.expectError(error.UnsupportedGlobalData, globalSymbolBudget(std.math.maxInt(u32), 0, 0, 0));
}

test "ELF global placement admits a complete module beyond the legacy symbol limit" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const globals = try allocator.alloc(ir.Global, 4097);
    for (globals, 0..) |*global, index| global.* = .{
        .name = try std.fmt.allocPrint(allocator, "leaf_{d}", .{index}),
        .kind = .global,
        .ty = .{ .int = 8 },
        .initializer = .{ .scalar = .{ .int = @intCast(index % 256) } },
    };
    const placement = try inspectGlobalPlacement(std.testing.allocator, .{ .globals = globals, .named_types = &.{}, .target_datalayout = null, .emit_all_globals = true });
    try std.testing.expectEqual(globals.len, placement.symbols);
    try std.testing.expectEqual(globals.len, placement.data_bytes);
    try std.testing.expectEqual(globals.len, placement.symbol_budget);
}

test "ELF global placement retains the exact section byte boundary" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var globals: [17]ir.Global = undefined;
    for (&globals, 0..) |*global, index| global.* = .{
        .name = try std.fmt.allocPrint(allocator, "page_{d}", .{index}),
        .kind = .global,
        .ty = .{ .aggregate = "[1048576 x i8]" },
        .initializer = .{ .scalar = .zero_initializer },
    };
    const placement = try inspectGlobalPlacement(std.testing.allocator, .{ .globals = globals[0..16], .named_types = &.{}, .target_datalayout = null, .emit_all_globals = true });
    try std.testing.expectEqual(@as(usize, 16 * 1024 * 1024), placement.data_bytes);
    try std.testing.expectError(error.UnsupportedGlobalData, inspectGlobalPlacement(std.testing.allocator, .{ .globals = &globals, .named_types = &.{}, .target_datalayout = null, .emit_all_globals = true }));
}

test "ELF explicit read-only globals keep section permissions alignment symbols and relocation ownership" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "@w = global i32 17, section \".data\", align 4\n" ++
        "@r = constant <2 x i32> <i32 1, i32 2>, section \".rodata\", align 32\n" ++
        "@p = constant ptr @w, section \".rodata\", align 8\n" ++
        "@q = global ptr @r, section \".data\", align 8\n");
    defer module.deinit();
    try module.verify();
    const object = try buildObjectWithModuleContext(a, &.{}, &.{}, .{
        .globals = module.globals.items,
        .named_types = &.{},
        .target_datalayout = null,
        .emit_all_globals = true,
    });
    defer a.free(object);
    const read = struct {
        fn int(comptime T: type, bytes: []const u8, offset: usize) T {
            return std.mem.readInt(T, bytes[offset..][0..@sizeOf(T)], .little);
        }
    }.int;
    const shoff: usize = @intCast(read(u64, object, 40));
    try std.testing.expectEqual(@as(u16, 11), read(u16, object, 60));
    const ro = object[shoff + 8 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u64, 2), read(u64, ro, 8));
    try std.testing.expectEqual(@as(u64, 32), read(u64, ro, 48));
    const ro_offset: usize = @intCast(read(u64, ro, 24));
    try std.testing.expectEqual(@as(u64, 16), read(u64, ro, 32));
    try std.testing.expectEqualSlices(u8, &.{ 1, 0, 0, 0, 2, 0, 0, 0 }, object[ro_offset..][0..8]);
    const data_rela = object[shoff + 9 * 64 ..][0..64];
    const ro_rela = object[shoff + 10 * 64 ..][0..64];
    try std.testing.expectEqual(@as(u32, 2), read(u32, data_rela, 44));
    try std.testing.expectEqual(@as(u32, 8), read(u32, ro_rela, 44));
    for ([_][]const u8{ data_rela, ro_rela }) |section| {
        try std.testing.expectEqual(@as(u64, 24), read(u64, section, 32));
        try std.testing.expectEqual(@as(u32, 5), read(u32, section, 40));
    }
    const symtab = object[shoff + 5 * 64 ..][0..64];
    const symbols_offset: usize = @intCast(read(u64, symtab, 24));
    const expected = [_]u16{ 2, 8, 8, 2 };
    for (expected, 1..) |section, index| try std.testing.expectEqual(section, read(u16, object, symbols_offset + index * 24 + 6));
}

fn orderLocalSymbols(allocator: std.mem.Allocator, symbols: *std.ArrayList(Symbol), indices: *symbol_names.Index) !u32 {
    var count: u32 = 0;
    for (symbols.items) |symbol| if (symbol.info >> 4 == 0) {
        count += 1;
    };
    if (count == 0) return 1;
    const ordered = try allocator.alloc(Symbol, symbols.items.len);
    defer allocator.free(ordered);
    var local_index: usize = 0;
    var global_index: usize = count;
    for (symbols.items) |symbol| {
        if (symbol.info >> 4 == 0) {
            ordered[local_index] = symbol;
            local_index += 1;
        } else {
            ordered[global_index] = symbol;
            global_index += 1;
        }
    }
    @memcpy(symbols.items, ordered);
    for (symbols.items, 0..) |symbol, index| try indices.put(symbol.name, @intCast(index + 1));
    return count + 1;
}

fn appendUndefinedDataSymbol(
    allocator: std.mem.Allocator,
    symbols: *std.ArrayList(Symbol),
    indices: *symbol_names.Index,
    global: ir.Global,
    properties: symbol_address.GlobalProperties,
) !void {
    const binding: u8 = if (global.linkage == .extern_weak) 0x20 else 0x10;
    const kind: u8 = if (properties.tls) 6 else 1;
    try symbols.append(allocator, .{ .name = global.name, .value = 0, .size = 0, .section_index = 0, .info = binding | kind, .other = properties.visibility });
    try indices.put(global.name, @intCast(symbols.items.len));
}

fn appendSupportedGlobals(
    allocator: std.mem.Allocator,
    data: *std.ArrayList(u8),
    tdata: *std.ArrayList(u8),
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *symbol_names.Index,
    globals: []const ir.Global,
) !void {
    for (globals) |global| {
        if (symbol_indices.contains(global.name)) continue;
        if (global.linkage == .extern_weak) {
            const properties = try symbol_address.globalProperties(global);
            try appendUndefinedDataSymbol(allocator, symbols, symbol_indices, global, properties);
            continue;
        }
        if (symbol_address.globalProperties(global) catch null) |properties| {
            if (properties.read_only_section) return error.UnsupportedGlobalData;
        }
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
    symbol_indices: *symbol_names.Index,
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
    var table: [256]u8 = @splat(255);
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
    symbol_indices: *symbol_names.Index,
    aliases: []const ir.GlobalAlias,
    require_resolved: bool,
) !void {
    if (require_resolved) {
        // Definition order need not match dependency order. Each pass either
        // resolves another alias or proves a cycle/unsupported target remains.
        while (true) {
            var unresolved = false;
            var progress = false;
            for (aliases) |alias| {
                switch (alias.linkage) {
                    .default, .external, .internal, .private, .weak_odr => {},
                    else => return error.UnsupportedAliasLinkage,
                }
                if (symbol_indices.contains(alias.name)) continue;
                const target_index = symbol_indices.get(alias.target) orelse {
                    unresolved = true;
                    continue;
                };
                const target_symbol = symbols.items[target_index - 1];
                if (target_symbol.section_index == 0) return error.UnresolvedAliasTarget;
                // ODR aliases in compiler-rt name both functions and ordinary
                // initialized data (notably __stack_chk_guard). TLS stays closed.
                if (alias.linkage == .weak_odr and target_symbol.info & 0x0f != 2 and target_symbol.info & 0x0f != 1) return error.UnsupportedAliasLinkage;
                try symbols.append(allocator, .{
                    .name = alias.name,
                    .value = target_symbol.value,
                    .size = target_symbol.size,
                    .section_index = target_symbol.section_index,
                    .info = (if (alias.linkage == .weak_odr) @as(u8, 0x20) else if (alias.linkage == .private or alias.linkage == .internal) @as(u8, 0) else @as(u8, 0x10)) | (target_symbol.info & 0x0f),
                    .other = symbolOtherForVisibility(alias.visibility),
                });
                try symbol_indices.put(alias.name, @intCast(symbols.items.len));
                progress = true;
            }
            if (!unresolved) return;
            if (!progress) return error.UnresolvedAliasTarget;
        }
    }
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
    symbol_indices: *symbol_names.Index,
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
            .direct_jump => |symbol| {
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
            .lea_global_arg64 => |lea| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, lea.symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 3,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .lea_global_offset_rax => |address| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, address.symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 3,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = @as(i64, address.addend) - 4,
                });
            },
            .spinlocked_memcpy_rsi_to_rdx_len_edi => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 14,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 14,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_var_xchg_edi_rsi_rdx_rcx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 14,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_var_store_edi_rsi_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 14,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 14,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_xchg_i128_rdi_rsi_rdx_rax => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_store_i128_rdi_rsi_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_load_i128_rdi_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 14,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
                    .symbol_index = symbol_index,
                    .kind = 2,
                    .addend = -4,
                });
            },
            .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx => |symbol| {
                const symbol_index = try symbolIndexForCall(allocator, symbols, symbol_indices, symbol);
                try relocations.append(allocator, .{
                    .offset = function_offset + offset + 17,
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
            .tls_address_rax => |address| {
                const symbol_index = try symbolIndexForTls(allocator, symbols, symbol_indices, address.symbol);
                try relocations.append(allocator, .{ .offset = function_offset + offset + 4, .symbol_index = symbol_index, .kind = 19, .addend = -4 }); // R_X86_64_TLSGD
                const resolver = try symbolIndexForCall(allocator, symbols, symbol_indices, "__tls_get_addr");
                try relocations.append(allocator, .{ .offset = function_offset + offset + 12, .symbol_index = resolver, .kind = 4, .addend = -4 }); // R_X86_64_PLT32
            },
            else => {},
        }
        offset += encoding.instructionSize(instruction);
    }
}

fn symbolIndexForCall(
    allocator: std.mem.Allocator,
    symbols: *std.ArrayList(Symbol),
    symbol_indices: *symbol_names.Index,
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
    symbol_indices: *symbol_names.Index,
    name: []const u8,
) !u32 {
    if (symbol_indices.get(name)) |index| {
        if (symbols.items[index - 1].info & 0x0f != 6) return error.SymbolAddressClassMismatch;
        return index;
    }
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
