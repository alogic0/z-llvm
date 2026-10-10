const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");
const air_capabilities = @import("../../../zig_air_capabilities.zig");
const std = shared.std;
const ir = shared.ir;
const target = shared.target;
const MachineFunction = shared.MachineFunction;
const Instruction = shared.x86_64_machine.Instruction;
const ArgReg = shared.ArgReg;
const XmmReg = shared.XmmReg;

const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendLoadStackDispRax = cabi_aggregate_lowering.appendLoadStackDispRax;
const appendLoadStackDispXmm0 = cabi_aggregate_lowering.appendLoadStackDispXmm0;
const appendLoadStackDispXmm0F32 = cabi_aggregate_lowering.appendLoadStackDispXmm0F32;
const appendStoreArg64ArgPtrDisp = cabi_aggregate_lowering.appendStoreArg64ArgPtrDisp;
const appendStoreEaxArgPtrDisp = cabi_aggregate_lowering.appendStoreEaxArgPtrDisp;
const appendStoreRaxArgPtrDisp = cabi_aggregate_lowering.appendStoreRaxArgPtrDisp;
const appendStoreXmm0ArgPtrDisp = cabi_aggregate_lowering.appendStoreXmm0ArgPtrDisp;
const appendStoreXmm0F32ArgPtrDisp = cabi_aggregate_lowering.appendStoreXmm0F32ArgPtrDisp;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const fpParamIndex = cabi_abi_helpers.fpParamIndex;
const aggregateFieldCount = cabi_aggregate_lowering.aggregateFieldCount;
const aggregateFieldIndexAtOffset = cabi_aggregate_lowering.aggregateFieldIndexAtOffset;
const aggregateGepByteOffset = cabi_aggregate_lowering.aggregateGepByteOffset;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const x86_64SysVDataLayout = shared.x86_64SysVDataLayout;

const appendLoadStackDispU8Eax = cabi_aggregate_lowering.appendLoadStackDispU8Eax;
const appendLoadStackDispU16Eax = cabi_aggregate_lowering.appendLoadStackDispU16Eax;
const appendStoreAlArgPtrDisp = cabi_aggregate_lowering.appendStoreAlArgPtrDisp;
const appendStoreAxArgPtrDisp = cabi_aggregate_lowering.appendStoreAxArgPtrDisp;
const isI64Aggregate = cabi_aggregate_lowering.isI64Aggregate;
const isSupportedAggregateCopyLeafAggregate = cabi_aggregate_lowering.isSupportedAggregateCopyLeafAggregate;
const stackAggregateByteDisp = cabi_aggregate_lowering.stackAggregateByteDisp;
const supportedAggregateCopyLeaf = cabi_aggregate_lowering.supportedAggregateCopyLeaf;
const validateAggregateFieldGep = cabi_aggregate_lowering.validateAggregateFieldGep;

pub fn lowerGenericCfgSelectedSretStores(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (try lowerGenericCfgSretCopy(allocator, machine, function, block)) return true;
    if (try lowerGenericCfgScalarSretParamStores(allocator, machine, function, block)) return true;
    if (function.params.items.len < 4) return false;
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count < 3 or function.params.items.len != field_count + 1) return false;
    if (!isI64Aggregate(aggregate_ty)) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if ((try paramReg(function, function.params.items[0].name, .ptr)) != .rdi) return error.UnsupportedCodegenAbi;
    for (function.params.items[1..]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return false;
    }
    if (block.instructions.items.len != field_count * 2) return false;

    var pair_index: usize = 0;
    while (pair_index < field_count) : (pair_index += 1) {
        const gep_inst = block.instructions.items[pair_index * 2];
        const store_inst = block.instructions.items[pair_index * 2 + 1];
        if (gep_inst.removed or store_inst.removed) return false;
        const gep_name = gep_inst.result orelse return false;
        try validateAggregateFieldGep(gep_inst, aggregate_ty, function.params.items[0].name, @intCast(pair_index));

        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(.{ .int = 64 }) or store.attrs.isBarrier() or !isNamed(store.ptr, gep_name) or
            !isNamed(store.value, function.params.items[pair_index + 1].name)) return false;
        const offset = try aggregateFieldOffset(aggregate_ty, pair_index);
        const maybe_src_reg = paramReg(function, function.params.items[pair_index + 1].name, .{ .int = 64 }) catch |err| switch (err) {
            error.UnsupportedCodegenAbi => null,
            else => return err,
        };
        if (maybe_src_reg) |src_reg| {
            try appendStoreArg64ArgPtrDisp(allocator, machine, .rdi, src_reg, offset);
        } else {
            try appendLoadStackDispRax(allocator, machine, try scalarParamStackDisp8(function, function.params.items[pair_index + 1].name, .{ .int = 64 }));
            try appendStoreRaxArgPtrDisp(allocator, machine, .rdi, offset);
        }
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgScalarSretParamStores(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (function.params.items.len < 2) return false;
    if (block.instructions.items.len == 1) {
        switch (block.instructions.items[0].kind) {
            .call => return false,
            else => {},
        }
    }
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    if (!isSupportedAggregateCopyLeafAggregate(aggregate_ty)) return false;
    var leaves: [64]ScalarSretLeaf = undefined;
    var leaf_count: usize = 0;
    const layout = x86_64SysVDataLayout() catch return error.UnsupportedCodegenAbi;
    try collectScalarSretLeaves(layout, aggregate_ty, 0, &leaves, &leaf_count);
    if (leaf_count == 0 or function.params.items.len > leaf_count + 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (sret_reg != .rdi) return error.UnsupportedCodegenAbi;

    var instruction_index: usize = 0;
    var leaf_index: usize = 0;
    while (leaf_index < leaf_count) : (leaf_index += 1) {
        const leaf = leaves[leaf_index];
        const field_ty = leaf.ty;
        if (leaf.offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
        const offset: u32 = @intCast(leaf.offset);
        const store_ptr = if (offset == 0 and instruction_index < block.instructions.items.len) ptr: {
            const maybe_store = switch (block.instructions.items[instruction_index].kind) {
                .store => |store| store,
                else => break :ptr null,
            };
            if (maybe_store.ty.eql(field_ty) and !maybe_store.attrs.isBarrier() and
                isNamed(maybe_store.ptr, function.params.items[0].name))
            {
                break :ptr function.params.items[0].name;
            }
            break :ptr null;
        } else null;
        const ptr_name = store_ptr orelse ptr: {
            if (instruction_index >= block.instructions.items.len) return false;
            const gep_inst = block.instructions.items[instruction_index];
            if (gep_inst.removed) return false;
            const gep_name = gep_inst.result orelse return false;
            const gep = switch (gep_inst.kind) {
                .gep => |gep| gep,
                else => return false,
            };
            if (!isNamed(gep.ptr, function.params.items[0].name)) return false;
            const gep_offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
            if (gep_offset != offset) return false;
            instruction_index += 1;
            break :ptr gep_name;
        };

        if (instruction_index >= block.instructions.items.len) return false;
        const store_inst = block.instructions.items[instruction_index];
        if (store_inst.removed) return false;
        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(field_ty) or store.attrs.isBarrier()) return false;
        if (!isNamed(store.ptr, ptr_name)) return false;

        switch (store.value) {
            .named => |store_val_name| {
                var found_param = false;
                for (function.params.items[1..]) |param| {
                    if (std.mem.eql(u8, param.name, store_val_name) and param.ty.eql(field_ty)) {
                        found_param = true;
                        break;
                    }
                }
                if (!found_param) return false;
            },
            .int => {},
            else => return false,
        }
        instruction_index += 1;

        try emitGenericCfgScalarSretParamStore(allocator, machine, function, block, store.value, field_ty, sret_reg, offset);
    }
    if (instruction_index != block.instructions.items.len) return false;
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

const ScalarSretLeaf = air_capabilities.AggregateLeaf;

fn collectScalarSretLeaves(
    layout: target.DataLayout,
    aggregate_ty: ir.Type,
    base_offset: u64,
    leaves: *[64]ScalarSretLeaf,
    leaf_count: *usize,
) !void {
    try air_capabilities.collectSupportedScalarAggregateLeaves(layout, aggregate_ty, base_offset, leaves, leaf_count);
}

fn supportedSretParamStoreLeaf(ty: ir.Type) bool {
    return air_capabilities.isSupportedScalarAggregateLeaf(ty);
}

fn emitGenericCfgScalarSretParamStore(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    ty: ir.Type,
    sret_reg: ArgReg,
    offset: u32,
) !void {
    switch (value) {
        .int => |val| {
            if (ty.eql(.{ .int = 32 })) {
                try machine.instructions.append(allocator, .{ .mov_imm_eax = @truncate(val) });
                try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, offset);
            } else if (ty.eql(.{ .int = 64 }) or ty.eql(.ptr)) {
                if (offset <= 127 and val >= std.math.minInt(i32) and val <= std.math.maxInt(i32)) {
                    try machine.instructions.append(allocator, .{
                        .store_imm64_arg_ptr_disp8 = .{
                            .reg = sret_reg,
                            .offset = @intCast(offset),
                            .imm = @intCast(val),
                        },
                    });
                } else {
                    try machine.instructions.append(allocator, .{ .mov_imm_rax = @intCast(val) });
                    try appendStoreRaxArgPtrDisp(allocator, machine, sret_reg, offset);
                }
            } else if (ty.eql(.{ .int = 16 })) {
                try machine.instructions.append(allocator, .{ .mov_imm_eax = @intCast(val) });
                try appendStoreAxArgPtrDisp(allocator, machine, sret_reg, offset);
            } else if (ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 1 })) {
                if (offset <= 127) {
                    try machine.instructions.append(allocator, .{
                        .store_imm8_arg_ptr_disp8 = .{
                            .reg = sret_reg,
                            .offset = @intCast(offset),
                            .imm = @truncate(@as(u128, @bitCast(val))),
                        },
                    });
                } else {
                    try machine.instructions.append(allocator, .{ .mov_imm_eax = @intCast(val) });
                    try appendStoreAlArgPtrDisp(allocator, machine, sret_reg, offset);
                }
            } else {
                return error.UnsupportedCodegenType;
            }
        },
        .named => |name| {
            if (ty.eql(.{ .int = 32 })) {
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, offset);
            } else if (ty.eql(.{ .int = 64 }) or ty.eql(.ptr)) {
                const maybe_reg = paramRegOrNull(function, name, ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                };
                if (maybe_reg) |reg| {
                    try appendStoreArg64ArgPtrDisp(allocator, machine, sret_reg, reg, offset);
                } else {
                    try appendLoadStackDispRax(allocator, machine, try scalarParamStackDisp8(function, name, ty));
                    try appendStoreRaxArgPtrDisp(allocator, machine, sret_reg, offset);
                }
            } else if (ty.eql(.{ .int = 16 })) {
                const maybe_reg = paramRegOrNull(function, name, ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                };
                if (maybe_reg) |reg| {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                } else {
                    try appendLoadStackDispU16Eax(allocator, machine, try scalarParamStackDisp8(function, name, ty));
                }
                try appendStoreAxArgPtrDisp(allocator, machine, sret_reg, offset);
            } else if (ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 1 })) {
                const maybe_reg = paramRegOrNull(function, name, ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                };
                if (maybe_reg) |reg| {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                } else {
                    try appendLoadStackDispU8Eax(allocator, machine, try scalarParamStackDisp8(function, name, ty));
                }
                try appendStoreAlArgPtrDisp(allocator, machine, sret_reg, offset);
            } else if (ty.eql(.float) or ty.eql(.double)) {
                const source_index = fpParamIndex(function, name, ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                };
                if (source_index) |index| {
                    const source = try XmmReg.fromIndex(index);
                    if (source != .xmm0) {
                        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = source } });
                    }
                } else if (ty.eql(.float)) {
                    try appendLoadStackDispXmm0F32(allocator, machine, try scalarParamStackDisp8(function, name, ty));
                } else {
                    try appendLoadStackDispXmm0(allocator, machine, try scalarParamStackDisp8(function, name, ty));
                }
                if (ty.eql(.float)) {
                    try appendStoreXmm0F32ArgPtrDisp(allocator, machine, sret_reg, offset);
                } else {
                    try appendStoreXmm0ArgPtrDisp(allocator, machine, sret_reg, offset);
                }
            } else {
                return error.UnsupportedCodegenType;
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn lowerGenericCfgSretCopy(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (function.params.items.len != 2) return false;
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    const byval_ty = byvalAggregateType(function.params.items[1].attrs) orelse return false;
    if (!isSupportedAggregateCopyLeafAggregate(aggregate_ty)) return false;
    if (!isSupportedAggregateCopyLeafAggregate(byval_ty)) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (sret_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (block.instructions.items.len < 12 or block.instructions.items.len % 4 != 0) return false;

    const copy_count = block.instructions.items.len / 4;
    var dst_base_offset: ?u64 = null;
    var copy_index: usize = 0;
    while (copy_index < copy_count) : (copy_index += 1) {
        const src_gep_inst = block.instructions.items[copy_index * 4];
        const load_inst = block.instructions.items[copy_index * 4 + 1];
        const dst_gep_inst = block.instructions.items[copy_index * 4 + 2];
        const store_inst = block.instructions.items[copy_index * 4 + 3];
        if (src_gep_inst.removed or load_inst.removed or dst_gep_inst.removed or store_inst.removed) return false;
        const src_gep_name = src_gep_inst.result orelse return false;
        const load_name = load_inst.result orelse return false;
        const dst_gep_name = dst_gep_inst.result orelse return false;
        const src_offset = aggregateCopyGepOffset(src_gep_inst, byval_ty, function.params.items[1].name) orelse return false;
        const dst_offset = aggregateCopyGepOffset(dst_gep_inst, aggregate_ty, function.params.items[0].name) orelse return false;
        if (dst_offset < src_offset) return false;
        const current_dst_base = dst_offset - src_offset;
        if (dst_base_offset) |base| {
            if (base != current_dst_base) return false;
        } else {
            dst_base_offset = current_dst_base;
        }

        const load = switch (load_inst.kind) {
            .load => |load| load,
            else => return false,
        };
        if (!supportedAggregateCopyLeaf(load.ty) or load.attrs.isBarrier() or !isNamed(load.ptr, src_gep_name)) return false;
        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(load.ty) or store.attrs.isBarrier() or !isNamed(store.ptr, dst_gep_name) or
            !isNamed(store.value, load_name)) return false;

        const offset = try aggregateByteOffset(aggregate_ty, dst_offset, load.ty);
        if (load.ty.eql(.float)) {
            try appendLoadStackDispXmm0F32(allocator, machine, try stackAggregateByteDisp(byval_ty, src_offset, load.ty));
            try appendStoreXmm0F32ArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.double)) {
            try appendLoadStackDispXmm0(allocator, machine, try stackAggregateByteDisp(byval_ty, src_offset, load.ty));
            try appendStoreXmm0ArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 64 }) or load.ty.eql(.ptr)) {
            try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(byval_ty, src_offset, load.ty));
            try appendStoreRaxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 32 })) {
            try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(byval_ty, src_offset, load.ty));
            try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 16 })) {
            try appendLoadStackDispU16Eax(allocator, machine, try stackAggregateByteDisp(byval_ty, src_offset, load.ty));
            try appendStoreAxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 8 })) {
            try appendLoadStackDispU8Eax(allocator, machine, try stackAggregateByteDisp(byval_ty, src_offset, load.ty));
            try appendStoreAlArgPtrDisp(allocator, machine, sret_reg, offset);
        } else {
            return error.UnsupportedCodegenType;
        }
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn aggregateCopyGepOffset(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8) ?u64 {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!isNamed(gep.ptr, base_name)) return null;
    const layout = x86_64SysVDataLayout() catch return null;
    const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return null;
    const field_ty = aggregateLeafTypeAtOffset(layout, aggregate_ty, offset) orelse return null;
    if (!supportedAggregateCopyLeaf(field_ty)) return null;
    return offset;
}

pub fn aggregateLeafTypeAtOffset(layout: target.DataLayout, aggregate_ty: ir.Type, expected_offset: u64) ?ir.Type {
    return air_capabilities.aggregateLeafTypeAtOffset(layout, aggregate_ty, expected_offset);
}

pub fn sretAggregateType(attrs: ?[]const u8) ?ir.Type {
    return aggregateAbiAttrType(attrs, "sret");
}

pub fn byvalAggregateType(attrs: ?[]const u8) ?ir.Type {
    return aggregateAbiAttrType(attrs, "byval");
}

pub fn aggregateAbiAttrType(attrs: ?[]const u8, name: []const u8) ?ir.Type {
    const text = attrs orelse return null;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, text, start, name)) |name_index| {
        const open_index = name_index + name.len;
        start = open_index;
        if (open_index >= text.len or text[open_index] != '(') continue;
        const close_index = findMatchingParen(text, open_index) orelse return null;
        const payload = std.mem.trim(u8, text[open_index + 1 .. close_index], " \t");
        if (payload.len >= 2 and ((payload[0] == '{' and payload[payload.len - 1] == '}') or
            (payload[0] == '[' and payload[payload.len - 1] == ']') or
            (payload[0] == '%' and payload.len > 1)))
        {
            return .{ .aggregate = payload };
        }
        start = close_index + 1;
    }
    return null;
}

pub fn findMatchingParen(text: []const u8, open_index: usize) ?usize {
    if (open_index >= text.len or text[open_index] != '(') return null;
    var paren_depth: usize = 0;
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    for (text[open_index..], 0..) |byte, relative_index| {
        const index = open_index + relative_index;
        switch (byte) {
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth == 0) return null;
                paren_depth -= 1;
                if (paren_depth == 0 and brace_depth == 0 and bracket_depth == 0 and angle_depth == 0) return index;
            },
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
            else => {},
        }
    }
    return null;
}

pub fn aggregateFieldOffsetU8(aggregate_ty: ir.Type, field_index: usize) !u8 {
    const layout = try x86_64SysVDataLayout();
    const offset = air_capabilities.aggregateFieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn aggregateFieldOffset(aggregate_ty: ir.Type, field_index: usize) !u32 {
    const layout = try x86_64SysVDataLayout();
    const offset = air_capabilities.aggregateFieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn aggregateByteOffsetU8(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u8 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    if (field_offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(field_offset);
}

pub fn aggregateByteOffset(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u32 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    if (field_offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(field_offset);
}
