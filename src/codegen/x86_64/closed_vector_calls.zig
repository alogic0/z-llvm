//! Owned, module-wide private views for direct-only internal fastcc vectors.
//! Caller snapshots and callee entry loads preserve by-value semantics while
//! leaving the parsed module, names, owners and ordinary ABI limits unchanged.
const std = @import("std");
const ir = @import("../../ir.zig");
const closure = @import("../../analysis/direct_symbol_closure.zig");
const forms = @import("generic_cfg/scalar_forms.zig");
const NameMap = std.HashMap([]const u8, usize, ir.identifiers.Context, 80);
pub const View = struct { functions: []ir.Function, changed_callees: usize };
fn needs(ty: ir.Type) bool {
    if (ty != .vector or ty.vector.len == 0 or ty.vector.len > 64 or ty.vector.elem_ty != .int) return false;
    const bits: usize = ty.vector.elem_ty.int;
    const total = bits * ty.vector.len;
    return bits > 0 and bits <= 128 and total > 128 and
        (total > 1024 or ((bits == 4 or bits == 5) and total > 128));
}
fn simple(attrs: ?[]const u8) bool {
    const text = std.mem.trim(u8, attrs orelse return true, " \t\r\n");
    return std.mem.eql(u8, text, "noundef");
}
fn eligible(function: ir.Function) bool {
    if ((function.linkage != .internal and function.linkage != .private) or function.is_varargs or function.blocks.items.len == 0 or function.params.items.len > 64 or function.ret_ty == .vector) return false;
    if (!std.mem.eql(u8, function.calling_conv orelse return false, "fastcc")) return false;
    var found = false;
    for (function.params.items) |param| {
        if (needs(param.ty)) {
            if (!simple(param.attrs) or param.abi_split_integer or param.abi_x87_memory or param.abi_incoming_address != null) return false;
            found = true;
        }
    }
    return found;
}
fn supportedCalls(module: ir.Module, target: ir.Function) bool {
    for (module.functions.items) |function| for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call or !ir.identifiers.eql(inst.kind.call.callee, target.name)) continue;
        if (inst.kind.call.args.items.len != target.params.items.len) return false;
        for (inst.kind.call.args.items, target.params.items) |arg, param| if (needs(param.ty) and !simple(arg.attrs)) return false;
    };
    return true;
}
fn byteCount(ty: ir.Type) usize {
    return (@as(usize, ty.vector.len) * ty.vector.elem_ty.int + 7) / 8;
}
pub fn prepare(a: std.mem.Allocator, module: ir.Module) !?View {
    var names: std.ArrayList([]const u8) = .empty;
    defer names.deinit(a);
    var indices: std.ArrayList(usize) = .empty;
    defer indices.deinit(a);
    for (module.functions.items, 0..) |function, index| if (eligible(function) and supportedCalls(module, function)) {
        try names.append(a, function.name);
        try indices.append(a, index);
    };
    if (names.items.len == 0) return null;
    const proved = try closure.prove(a, module, names.items);
    var callees = NameMap.init(a);
    defer callees.deinit();
    for (proved, 0..) |closed, index| if (closed) try callees.put(names.items[index], indices.items[index]);
    if (callees.count() == 0) return null;
    const functions = try a.dupe(ir.Function, module.functions.items);
    for (module.functions.items, 0..) |function, function_index| {
        var prefixes: std.ArrayList(ir.Instruction) = .empty;
        defer prefixes.deinit(a);
        var serial: forms.TemporaryNames = .{ .prefix = "__zllvm_closed_vector_" };
        defer serial.deinit(a);
        var result = function;
        var changed = false;
        if (callees.contains(function.name)) {
            result.params = try function.params.clone(a);
            for (result.params.items, function.params.items) |*param, original| if (needs(original.ty)) {
                param.ty = .ptr;
                param.attrs = null;
                param.name = try forms.temporary(a, function, &serial);
                try prefixes.append(a, .{ .result = original.name, .kind = .{ .load = .{ .ty = original.ty, .ptr = .{ .named = param.name }, .attrs = .{ .@"align" = 1 } } } });
                changed = true;
            };
        }
        result.blocks = .empty;
        for (function.blocks.items) |original_block| {
            var block = original_block;
            block.instructions = .empty;
            for (original_block.instructions.items) |inst| {
                if (!inst.removed and inst.kind == .call) if (callees.get(inst.kind.call.callee)) |callee_index| {
                    const call = inst.kind.call;
                    const target = module.functions.items[callee_index];
                    var copy = inst;
                    copy.kind.call.args = try call.args.clone(a);
                    for (copy.kind.call.args.items, target.params.items) |*arg, param| if (needs(param.ty)) {
                        if (!simple(arg.attrs)) return error.UnsupportedClosedVectorArgumentAttributes;
                        const buffer = try forms.temporary(a, function, &serial);
                        try prefixes.insert(a, 0, .{ .result = buffer, .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = try std.fmt.allocPrint(a, "[{d} x i8]", .{byteCount(param.ty)}) }, .attrs = "align 16" } } });
                        try block.instructions.append(a, .{ .result = null, .kind = .{ .store = .{ .ty = arg.ty, .value = arg.value, .ptr = .{ .named = buffer }, .attrs = .{ .@"align" = 1 } } } });
                        arg.ty = .ptr;
                        arg.value = .{ .named = buffer };
                        arg.attrs = null;
                    };
                    try block.instructions.append(a, copy);
                    changed = true;
                    continue;
                };
                try block.instructions.append(a, inst);
            }
            try result.blocks.append(a, block);
        }
        if (changed) {
            var entry = result.blocks.items[0];
            var instructions: std.ArrayList(ir.Instruction) = .empty;
            // Entry PHIs remain the leading instructions. Call snapshots belong
            // to this invocation and are reused only after their call returns.
            var leading: usize = 0;
            while (leading < entry.instructions.items.len and entry.instructions.items[leading].kind == .phi) : (leading += 1) {}
            try instructions.appendSlice(a, entry.instructions.items[0..leading]);
            try instructions.appendSlice(a, prefixes.items);
            try instructions.appendSlice(a, entry.instructions.items[leading..]);
            entry.instructions = instructions;
            result.blocks.items[0] = entry;
            functions[function_index] = result;
        }
    }
    return .{ .functions = functions, .changed_callees = callees.count() };
}
