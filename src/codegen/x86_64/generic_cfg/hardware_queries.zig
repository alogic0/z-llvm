//! Exact CPU query assembly through private packed integer results.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const machine = @import("../machine.zig");
const QueryMap = std.HashMap([]const u8, ir.NativeQuery, ir.identifiers.Context, std.hash_map.default_max_load_percentage);
pub const cpuid_constraints = "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}";
pub const xgetbv_constraints = "={eax},~{ecx},~{edx},~{dirflag},~{fpsr},~{flags}";

fn tuple(ty: ir.Type) bool {
    if (ty != .aggregate) return false;
    var fields = @import("../../../ir/structure.zig").Fields.init(ty.aggregate) orelse return false;
    if (fields.packed_type) return false;
    var count: usize = 0;
    while (fields.next()) |field| {
        if (!std.mem.eql(u8, std.mem.trim(u8, field, " \t\n\r"), "i32")) return false;
        count += 1;
    }
    return count == 4;
}

pub fn sourceQuery(call: ir.CallInst) ?ir.NativeQuery {
    const assembly = call.inline_asm orelse return null;
    if (!assembly.sideeffect or assembly.has_memory_clobber or assembly.may_load or assembly.may_store or
        call.callee_value != null or call.callee_function_ty != null or call.calling_conv != null or
        call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) return null;
    if (call.tail_kind) |tail| if (!std.mem.eql(u8, tail, "tail") and !std.mem.eql(u8, tail, "notail")) return null;
    if (std.mem.eql(u8, assembly.template, "cpuid") and std.mem.eql(u8, assembly.constraints, cpuid_constraints) and tuple(call.ret_ty) and call.args.items.len == 2) {
        for (call.args.items) |arg| if (!arg.ty.eql(.{ .int = 32 }) or arg.attrs != null or
            (arg.value != .int and arg.value != .named)) return null;
        return .cpuid;
    }
    if (std.mem.eql(u8, assembly.template, " xor %ecx, %ecx\\0A xgetbv") and
        std.mem.eql(u8, assembly.constraints, xgetbv_constraints) and call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 0) return .xgetbv;
    return null;
}

pub fn validCarrier(call: ir.CallInst) bool {
    return call.nativeQuerySignatureSupported();
}

const QueryUse = struct {
    pub const Error = error{};
    queries: *const QueryMap,
    found: *bool,
    pub fn visit(self: QueryUse, value: *const ir.Value, _: ir.Type) Error!void {
        if (value.* == .named and self.queries.get(value.named) == .cpuid) self.found.* = true;
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!@import("../symbol_address.zig").supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var queries = QueryMap.init(allocator);
    defer queries.deinit();
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .call) if (sourceQuery(inst.kind.call)) |query| {
            try queries.put(inst.result orelse return null, query);
        };
    };
    if (queries.count() == 0) return null;
    // The four outputs may only be extracted individually in this envelope.
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            if (inst.kind == .extractvalue) {
                const extract = inst.kind.extractvalue;
                if (extract.aggregate == .named and queries.get(extract.aggregate.named) == .cpuid) {
                    const index = std.fmt.parseUnsigned(u8, std.mem.trim(u8, extract.indices, " \t"), 10) catch return null;
                    if (index >= 4 or !tuple(extract.aggregate_ty) or inst.result == null) return null;
                    continue;
                }
            }
            var found = false;
            _ = try ir.operands.instruction(&inst, QueryUse{ .queries = &queries, .found = &found });
            if (found) return null;
        }
        if (block.terminator) |term| if (term == .ret) if (term.ret.value) |value| {
            if (value == .named and queries.get(value.named) == .cpuid) return null;
        };
    }
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_query_" };
    defer names.deinit(allocator);
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and inst.kind == .call) if (sourceQuery(inst.kind.call)) |query| {
                copy.kind.call.native_query = query;
                copy.kind.call.ret_ty = .{ .int = if (query == .cpuid) 128 else 32 };
                copy.kind.call.callee = if (query == .cpuid) "__zllvm_native_cpuid" else "__zllvm_native_xgetbv";
                copy.kind.call.inline_asm = null;
                copy.kind.call.tail_kind = null;
                copy.kind.call.attrs = null;
                copy.metadata = null;
                copy.kind.call.args = try inst.kind.call.args.clone(allocator);
                for (copy.kind.call.args.items) |*arg| if (arg.value == .int) {
                    const named = try forms.temporary(allocator, function, &names);
                    const bits: u32 = @truncate(@as(u128, @bitCast(arg.value.int)));
                    try block.instructions.append(allocator, .{ .result = named, .kind = .{ .binary = .{
                        .op = .add,
                        .ty = .{ .int = 32 },
                        .lhs = .{ .int = @as(i32, @bitCast(bits)) },
                        .rhs = .{ .int = 0 },
                    } } });
                    arg.value = .{ .named = named };
                };
            };
            if (!inst.removed and inst.kind == .extractvalue) {
                const extract = inst.kind.extractvalue;
                if (extract.aggregate == .named and queries.get(extract.aggregate.named) == .cpuid) {
                    const index = try std.fmt.parseUnsigned(u8, std.mem.trim(u8, extract.indices, " \t"), 10);
                    var source = extract.aggregate;
                    if (index != 0) {
                        const shifted = try forms.temporary(allocator, function, &names);
                        try block.instructions.append(allocator, .{ .result = shifted, .kind = .{ .binary = .{
                            .op = .lshr,
                            .ty = .{ .int = 128 },
                            .lhs = source,
                            .rhs = .{ .int = @as(i128, index) * 32 },
                        } } });
                        source = .{ .named = shifted };
                    }
                    const low = try forms.temporary(allocator, function, &names);
                    try block.instructions.append(allocator, .{ .result = low, .kind = .{ .cast = .{ .op = .trunc, .from_ty = .{ .int = 128 }, .value = source, .to_ty = .{ .int = 32 } } } });
                    // The pair truncation may retain a wider physical home.
                    // An ordinary i32 definition gives later comparisons their
                    // canonical width without extending transfer capabilities.
                    copy.kind = .{ .binary = .{ .op = .add, .ty = .{ .int = 32 }, .lhs = .{ .named = low }, .rhs = .{ .int = 0 } } };
                    copy.metadata = null;
                }
            }
            try block.instructions.append(allocator, copy);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
