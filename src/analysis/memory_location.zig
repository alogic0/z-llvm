const std = @import("std");
const ir = @import("../ir.zig");
const datalayout = @import("../target/datalayout.zig");

pub const MemoryLocation = struct {
    pub const RootKind = enum {
        stack,
        global,
        parameter,
    };

    ptr: ir.Value,
    root: []const u8,
    root_kind: RootKind,
    offset: ?i128,
    size: ?u64,

    pub fn rangeEnd(location: MemoryLocation) ?i128 {
        const offset = location.offset orelse return null;
        const size = location.size orelse return null;
        return offset + @as(i128, @intCast(size));
    }
};

pub fn forPointer(function: ir.Function, ptr: ir.Value) ?MemoryLocation {
    return build(function, ptr, null);
}

pub fn forPointerInModule(module: ir.Module, function: ir.Function, ptr: ir.Value) ?MemoryLocation {
    return buildInModule(module, function, null, ptr, null);
}

pub fn forPointerWithLayout(function: ir.Function, layout: datalayout.DataLayout, ptr: ir.Value) ?MemoryLocation {
    return buildWithLayout(function, layout, ptr, null);
}

pub fn forPointerInModuleWithLayout(module: ir.Module, function: ir.Function, layout: datalayout.DataLayout, ptr: ir.Value) ?MemoryLocation {
    return buildInModule(module, function, layout, ptr, null);
}

pub fn forAccess(function: ir.Function, ptr: ir.Value, access_ty: ir.Type) ?MemoryLocation {
    return build(function, ptr, typeSize(access_ty));
}

pub fn forAccessInModule(module: ir.Module, function: ir.Function, ptr: ir.Value, access_ty: ir.Type) ?MemoryLocation {
    return buildInModule(module, function, null, ptr, typeSize(access_ty));
}

pub fn forAccessWithLayout(function: ir.Function, layout: datalayout.DataLayout, ptr: ir.Value, access_ty: ir.Type) ?MemoryLocation {
    return buildWithLayout(function, layout, ptr, typeSizeWithLayout(layout, access_ty));
}

pub fn forAccessInModuleWithLayout(module: ir.Module, function: ir.Function, layout: datalayout.DataLayout, ptr: ir.Value, access_ty: ir.Type) ?MemoryLocation {
    return buildInModule(module, function, layout, ptr, typeSizeWithLayout(layout, access_ty));
}

fn build(function: ir.Function, ptr: ir.Value, access_size: ?u64) ?MemoryLocation {
    return buildInternal(function, null, ptr, access_size);
}

fn buildWithLayout(function: ir.Function, layout: datalayout.DataLayout, ptr: ir.Value, access_size: ?u64) ?MemoryLocation {
    return buildInternal(function, layout, ptr, access_size);
}

fn buildInModule(module: ir.Module, function: ir.Function, layout: ?datalayout.DataLayout, ptr: ir.Value, access_size: ?u64) ?MemoryLocation {
    return buildInternal(function, layout, ptr, access_size) orelse buildGlobal(module, layout, ptr, access_size);
}

fn buildGlobal(module: ir.Module, layout: ?datalayout.DataLayout, ptr: ir.Value, access_size: ?u64) ?MemoryLocation {
    const raw_name = switch (ptr) {
        .int, .undef, .null_value, .zero_initializer, .vector => return null,
        .named => |name| name,
    };
    const name = stripGlobalSigil(raw_name);
    const root = resolveGlobalAlias(module, name);
    for (module.globals.items) |global| {
        if (!std.mem.eql(u8, global.name, root)) continue;
        return .{
            .ptr = ptr,
            .root = global.name,
            .root_kind = .global,
            .offset = 0,
            .size = access_size orelse typeSizeMaybeLayout(layout, global.ty),
        };
    }
    return null;
}

fn stripGlobalSigil(name: []const u8) []const u8 {
    if (name.len > 0 and name[0] == '@') return name[1..];
    return name;
}

fn resolveGlobalAlias(module: ir.Module, name: []const u8) []const u8 {
    for (module.aliases.items) |global_alias| {
        if (std.mem.eql(u8, global_alias.name, name)) return global_alias.target;
    }
    return name;
}

fn buildInternal(function: ir.Function, layout: ?datalayout.DataLayout, ptr: ir.Value, access_size: ?u64) ?MemoryLocation {
    const name = switch (ptr) {
        .int, .undef, .null_value, .zero_initializer, .vector => return null,
        .named => |name| name,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, name)) continue;

            switch (instruction.kind) {
                .alloca => |alloca| return .{
                    .ptr = ptr,
                    .root = result,
                    .root_kind = .stack,
                    .offset = 0,
                    .size = access_size orelse typeSizeMaybeLayout(layout, alloca.allocated_ty),
                },
                .gep => |gep| {
                    var base = buildInternal(function, layout, gep.ptr, null) orelse return null;
                    base.ptr = ptr;
                    base.offset = addOffsets(base.offset, gepOffsetMaybeLayout(layout, gep));
                    base.size = access_size orelse typeSizeMaybeLayout(layout, gep.source_ty);
                    return base;
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .call => return null,
            }
        }
    }
    for (function.params.items) |param| {
        if (!param.ty.eql(.ptr)) continue;
        if (!std.mem.eql(u8, param.name, name)) continue;
        return .{
            .ptr = ptr,
            .root = param.name,
            .root_kind = .parameter,
            .offset = 0,
            .size = access_size,
        };
    }
    return null;
}

fn addOffsets(a: ?i128, b: ?i128) ?i128 {
    return (a orelse return null) + (b orelse return null);
}

pub fn gepOffset(gep: ir.GepInst) ?i128 {
    return gepOffsetInternal(null, gep);
}

pub fn gepOffsetWithLayout(layout: datalayout.DataLayout, gep: ir.GepInst) ?i128 {
    return gepOffsetInternal(layout, gep);
}

fn gepOffsetMaybeLayout(layout: ?datalayout.DataLayout, gep: ir.GepInst) ?i128 {
    if (layout) |target_layout| return gepOffsetWithLayout(target_layout, gep);
    return gepOffset(gep);
}

fn gepOffsetInternal(layout: ?datalayout.DataLayout, gep: ir.GepInst) ?i128 {
    var current_ty = gep.source_ty;
    var offset: i128 = 0;
    for (gep.indices.items, 0..) |index, index_position| {
        const value = switch (index.value) {
            .int => |value| value,
            .named, .undef, .null_value, .zero_initializer, .vector => return null,
        };
        if (index_position == 0) {
            const element_size = typeSizeMaybeLayout(layout, current_ty) orelse return null;
            offset += value * @as(i128, @intCast(element_size));
            continue;
        }
        if (current_ty == .aggregate) {
            if (value < 0) return null;
            offset += aggregateFieldOffsetMaybeLayout(layout, current_ty, @intCast(value)) orelse return null;
            current_ty = aggregateFieldType(current_ty, @intCast(value)) orelse return null;
        } else {
            const element_size = typeSizeMaybeLayout(layout, current_ty) orelse return null;
            offset += value * @as(i128, @intCast(element_size));
        }
    }
    return offset;
}

pub fn typeSize(ty: ir.Type) ?u64 {
    return switch (ty) {
        .int => |bits| if (bits % 8 == 0) bits / 8 else null,
        .float => 4,
        .double => 8,
        .aggregate => aggregateSize(ty),
        .void, .ptr, .vector => null,
    };
}

pub fn typeSizeWithLayout(layout: datalayout.DataLayout, ty: ir.Type) ?u64 {
    return layout.typeStoreSizeBytes(ty) catch null;
}

fn typeSizeMaybeLayout(layout: ?datalayout.DataLayout, ty: ir.Type) ?u64 {
    if (layout) |target_layout| return typeSizeWithLayout(target_layout, ty);
    return typeSize(ty);
}

pub fn aggregateFieldType(ty: ir.Type, field_index: usize) ?ir.Type {
    const text = switch (ty) {
        .aggregate => |text| text,
        .void, .int, .float, .double, .ptr, .vector => return null,
    };
    var fields = aggregateFields(text) orelse return null;
    var index: usize = 0;
    while (nextAggregateField(&fields)) |field_text| : (index += 1) {
        if (index == field_index) return parseTypeLiteral(field_text);
    }
    return null;
}

pub fn aggregateFieldOffset(ty: ir.Type, field_index: usize) ?i128 {
    const text = switch (ty) {
        .aggregate => |text| text,
        .void, .int, .float, .double, .ptr, .vector => return null,
    };
    var fields = aggregateFields(text) orelse return null;
    var index: usize = 0;
    var offset: i128 = 0;
    while (nextAggregateField(&fields)) |field_text| : (index += 1) {
        if (index == field_index) return offset;
        const field_ty = parseTypeLiteral(field_text) orelse return null;
        const field_size = typeSize(field_ty) orelse return null;
        offset += @intCast(field_size);
    }
    return null;
}

pub fn aggregateFieldOffsetWithLayout(layout: datalayout.DataLayout, ty: ir.Type, field_index: usize) ?i128 {
    return layout.aggregateFieldOffsetBytes(ty, field_index) catch null;
}

fn aggregateFieldOffsetMaybeLayout(layout: ?datalayout.DataLayout, ty: ir.Type, field_index: usize) ?i128 {
    if (layout) |target_layout| return aggregateFieldOffsetWithLayout(target_layout, ty, field_index);
    return aggregateFieldOffset(ty, field_index);
}

fn aggregateSize(ty: ir.Type) ?u64 {
    const text = switch (ty) {
        .aggregate => |text| text,
        .void, .int, .float, .double, .ptr, .vector => return null,
    };
    if (arrayInfo(text)) |array| return array.count * (typeSize(array.element_ty) orelse return null);
    var fields = aggregateFields(text) orelse return null;
    var size: u64 = 0;
    while (nextAggregateField(&fields)) |field_text| {
        const field_ty = parseTypeLiteral(field_text) orelse return null;
        size += typeSize(field_ty) orelse return null;
    }
    return size;
}

const AggregateFields = struct {
    text: []const u8,
    cursor: usize = 0,
};

fn aggregateFields(text: []const u8) ?AggregateFields {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len < 2 or trimmed[0] != '{' or trimmed[trimmed.len - 1] != '}') return null;
    return .{ .text = std.mem.trim(u8, trimmed[1 .. trimmed.len - 1], " \t") };
}

const ArrayInfo = struct {
    count: u64,
    element_ty: ir.Type,
};

fn arrayInfo(text: []const u8) ?ArrayInfo {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len < 5 or trimmed[0] != '[' or trimmed[trimmed.len - 1] != ']') return null;
    const body = std.mem.trim(u8, trimmed[1 .. trimmed.len - 1], " \t");
    const x_index = std.mem.indexOf(u8, body, " x ") orelse return null;
    const count = std.fmt.parseInt(u64, std.mem.trim(u8, body[0..x_index], " \t"), 10) catch return null;
    const element_ty = parseTypeLiteral(std.mem.trim(u8, body[x_index + " x ".len ..], " \t")) orelse return null;
    return .{ .count = count, .element_ty = element_ty };
}

fn nextAggregateField(fields: *AggregateFields) ?[]const u8 {
    if (fields.cursor >= fields.text.len) return null;
    const rest = fields.text[fields.cursor..];
    const comma = findTopLevelComma(rest);
    const field = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
    fields.cursor = if (comma) |index| fields.cursor + index + 1 else fields.text.len;
    return field;
}

fn parseTypeLiteral(text: []const u8) ?ir.Type {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (std.mem.eql(u8, trimmed, "void")) return .void;
    if (std.mem.eql(u8, trimmed, "ptr")) return .ptr;
    if (std.mem.eql(u8, trimmed, "float")) return .float;
    if (std.mem.eql(u8, trimmed, "double")) return .double;
    if (trimmed.len >= 2 and ((trimmed[0] == '{' and trimmed[trimmed.len - 1] == '}') or
        (trimmed[0] == '[' and trimmed[trimmed.len - 1] == ']'))) return .{ .aggregate = trimmed };
    if (trimmed.len < 2 or trimmed[0] != 'i') return null;
    const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch return null;
    if (bits == 0) return null;
    return .{ .int = bits };
}

fn findTopLevelComma(text: []const u8) ?usize {
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    for (text, 0..) |byte, index| {
        switch (byte) {
            '{' => brace_depth += 1,
            '}' => {
                if (brace_depth == 0) return null;
                brace_depth -= 1;
            },
            '[' => bracket_depth += 1,
            ']' => {
                if (bracket_depth == 0) return null;
                bracket_depth -= 1;
            },
            '<' => angle_depth += 1,
            '>' => {
                if (angle_depth == 0) return null;
                angle_depth -= 1;
            },
            ',' => if (brace_depth == 0 and bracket_depth == 0 and angle_depth == 0) return index,
            else => {},
        }
    }
    return null;
}
