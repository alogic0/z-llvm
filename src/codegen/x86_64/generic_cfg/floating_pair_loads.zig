//! Split an ordinary two-double return snapshot at its original load position.
//! The existing SysV classifier, scalar memory actions and SSE return owner
//! retain the ABI. Effectful loads and other aggregate consumers stay closed.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const abi = @import("../sysv_abi.zig");
const uses = @import("stage2_planning.zig");
const forms = @import("scalar_forms.zig");
const pairs = @import("word_pair_memory.zig");

fn admitted(a: std.mem.Allocator, function: ir.Function, inst: ir.Instruction) !bool {
    if (inst.removed or inst.result == null or inst.kind != .load) return false;
    const load = inst.kind.load;
    if (load.ty != .aggregate or !pairs.spelling(load.ty.aggregate, "{double,double}") or
        !function.ret_ty.eql(load.ty) or load.attrs.isBarrier() or load.attrs.syncscope != null or
        load.ty_addrspace != null or load.ptr_addrspace != null or
        abi.sseAggregateReturnKind(load.ty) != .split_f64x2) return false;
    var returns: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |other| {
            if (!other.removed and try uses.instructionUsesName(a, other, inst.result.?)) return false;
        }
        if (block.terminator) |term| {
            if (!try uses.terminatorUsesName(a, term, inst.result.?)) continue;
            if (term != .ret or !term.ret.ty.eql(load.ty) or term.ret.value == null or
                term.ret.value.? != .named or !ir.identifiers.eql(term.ret.value.?.named, inst.result.?)) return false;
            returns += 1;
        }
    }
    return returns == 1;
}

pub fn legalize(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!pairs.supportsLayout(context)) return null;
    const layout = @import("storage_layout.zig").query(context, .{ .aggregate = "{ double, double }" }) orelse return null;
    if (layout.bytes != 16 or layout.alignment != 8) return null;
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_fp_pair_load_" };
    defer names.deinit(a);
    var result = function;
    result.blocks = .empty;
    var changed = false;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!try admitted(a, function, inst)) {
                try block.instructions.append(a, inst);
                continue;
            }
            const load = inst.kind.load;
            const lo = try forms.temporary(a, function, &names);
            const high_ptr = try forms.temporary(a, function, &names);
            const hi = try forms.temporary(a, function, &names);
            const first = try forms.temporary(a, function, &names);
            var attrs = load.attrs;
            // The second field is eight bytes from the aggregate base.
            if (attrs.@"align") |alignment| attrs.@"align" = @min(alignment, 8);
            try block.instructions.append(a, .{ .result = lo, .kind = .{ .load = .{ .ty = .double, .ptr = load.ptr, .attrs = attrs } } });
            var indices: std.ArrayList(ir.GepIndex) = .empty;
            try indices.append(a, .{ .ty = .{ .int = 64 }, .value = .{ .int = 8 } });
            try block.instructions.append(a, .{ .result = high_ptr, .kind = .{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = load.ptr, .indices = indices } } });
            try block.instructions.append(a, .{ .result = hi, .kind = .{ .load = .{ .ty = .double, .ptr = .{ .named = high_ptr }, .attrs = attrs } } });
            try block.instructions.append(a, .{ .result = first, .kind = .{ .insertvalue = .{ .aggregate_ty = load.ty, .aggregate = .poison, .value_ty = .double, .value = .{ .named = lo }, .indices = "0" } } });
            try block.instructions.append(a, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .insertvalue = .{ .aggregate_ty = load.ty, .aggregate = .{ .named = first }, .value_ty = .double, .value = .{ .named = hi }, .indices = "1" } } });
            changed = true;
        }
        try result.blocks.append(a, block);
    }
    return if (changed) result else null;
}

test "floating pair loads snapshot only complete ordinary return values" {
    for ([_]struct { access: []const u8 = "load", ty: []const u8 = "{ double, double }", extra: []const u8 = "", accepted: bool }{
        .{ .accepted = true },
        .{ .access = "load volatile", .accepted = false },
        .{ .ty = "<{ double, double }>", .accepted = false },
        .{ .ty = "{ float, float }", .accepted = false },
        .{ .extra = "%other = extractvalue { double, double } %pair,0", .accepted = false },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {s} @snapshot(ptr %p) {{\nentry:\n %pair = {s} {s},ptr %p,align 8\n {s}\n ret {s} %pair\n}}\n", .{ case.ty, case.access, case.ty, case.extra, case.ty });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const rewritten = try legalize(arena.allocator(), module.functions.items[0], null);
        try std.testing.expectEqual(case.accepted, rewritten != null);
        try std.testing.expectEqual(@as(usize, if (case.extra.len == 0) 1 else 2), module.functions.items[0].blocks.items[0].instructions.items.len);
        if (rewritten) |candidate| {
            try std.testing.expectEqual(@as(usize, 5), candidate.blocks.items[0].instructions.items.len);
            try std.testing.expectEqualStrings("pair", candidate.blocks.items[0].instructions.items[4].result.?);
            try std.testing.expect((try legalize(arena.allocator(), candidate, null)) == null);
        }
    }
}
