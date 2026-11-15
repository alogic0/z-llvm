//! Scalar views of local four-float values. No vector ABI or access envelope
//! changes: constant insertion views are pure, and memory snapshots retain all
//! sixteen bytes at the original ordinary load position.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const pairs = @import("word_pair_memory.zig");
const forms = @import("scalar_forms.zig");
const uses = @import("stage2_planning.zig");

const Fold = struct { name: []const u8, value: ir.Value };
const Load = struct { name: []const u8, results: [4][]const u8 };

fn fourFloats(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 4 and ty.vector.elem_ty == .float;
}
fn lane(ty: ir.Type, value: ir.Value) ?usize {
    if ((!ty.eql(.{ .int = 32 }) and !ty.eql(.{ .int = 64 })) or value != .int or
        value.int < 0 or value.int >= 4) return null;
    return @intCast(value.int);
}
fn definition(function: ir.Function, name: []const u8) ?*const ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |*inst| {
        if (!inst.removed and inst.result != null and ir.identifiers.eql(inst.result.?, name)) return inst;
    };
    return null;
}
fn knownLane(function: ir.Function, vector: ir.Value, wanted: usize, depth: u8) ?ir.Value {
    if (depth >= 16 or vector != .named) return null;
    const inst = definition(function, vector.named) orelse return null;
    if (inst.kind != .insertelement) return null;
    const insert = inst.kind.insertelement;
    if (!fourFloats(insert.vector_ty) or insert.value_ty != .float) return null;
    const index = lane(insert.index_ty, insert.index) orelse return null;
    if (index != wanted) return knownLane(function, insert.vector, wanted, depth + 1);
    return switch (insert.value) {
        .named, .fp => insert.value,
        else => null,
    };
}
fn instructionUses(a: std.mem.Allocator, inst: ir.Instruction, name: []const u8) !bool {
    return uses.instructionUsesName(a, inst, name) catch |err| {
        if (err == error.OutOfMemory) return err;
        return true;
    };
}
fn functionUses(a: std.mem.Allocator, function: ir.Function, name: []const u8) !bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (!inst.removed and try instructionUses(a, inst, name)) return true;
        }
        if (block.terminator) |term| {
            if (uses.terminatorUsesName(a, term, name) catch |err| {
                if (err == error.OutOfMemory) return err;
                return true;
            }) return true;
        }
    }
    return false;
}
fn loadPlan(a: std.mem.Allocator, function: ir.Function, inst: ir.Instruction) !?Load {
    if (inst.removed or inst.result == null or inst.kind != .load) return null;
    const load = inst.kind.load;
    if (!fourFloats(load.ty) or load.ptr != .named or load.attrs.isBarrier() or
        load.attrs.syncscope != null or load.ty_addrspace != null or load.ptr_addrspace != null) return null;
    var results: [4]?[]const u8 = @splat(null);
    var count: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |other| {
            if (other.removed or !try instructionUses(a, other, inst.result.?)) continue;
            if (other.result == null or other.kind != .extractelement) return null;
            const extract = other.kind.extractelement;
            if (!fourFloats(extract.vector_ty) or extract.vector != .named or
                !ir.identifiers.eql(extract.vector.named, inst.result.?)) return null;
            const index = lane(extract.index_ty, extract.index) orelse return null;
            if (results[index] != null) return null;
            results[index] = other.result.?;
            count += 1;
        }
        if (block.terminator) |term| {
            if (uses.terminatorUsesName(a, term, inst.result.?) catch |err| {
                if (err == error.OutOfMemory) return err;
                return null;
            }) return null;
        }
    }
    if (count != 4) return null;
    return .{ .name = inst.result.?, .results = .{ results[0].?, results[1].?, results[2].?, results[3].? } };
}
fn findLoad(loads: []const Load, name: []const u8) ?Load {
    for (loads) |plan| if (ir.identifiers.eql(plan.name, name)) return plan;
    return null;
}
fn findFold(folds: []const Fold, name: []const u8) ?ir.Value {
    for (folds) |fold| if (ir.identifiers.eql(fold.name, name)) return fold.value;
    return null;
}
fn replacement(folds: []const Fold, initial: ir.Value) ?ir.Value {
    var value = initial;
    for (0..folds.len + 1) |_| {
        if (value != .named) return value;
        value = findFold(folds, value.named) orelse return value;
    }
    return null;
}

pub fn legalize(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var loads: std.ArrayList(Load) = .empty;
    defer loads.deinit(a);
    var folds: std.ArrayList(Fold) = .empty;
    defer folds.deinit(a);
    const layout = @import("storage_layout.zig").query(context, .{ .vector = .{ .len = 4, .elem_ty = .float } });
    const snapshot_layout = pairs.supportsLayout(context) and layout != null and layout.?.bytes == 16;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (snapshot_layout) if (try loadPlan(a, function, inst)) |plan| try loads.append(a, plan);
    };
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or inst.kind != .extractelement) continue;
        const extract = inst.kind.extractelement;
        if (!fourFloats(extract.vector_ty)) continue;
        const index = lane(extract.index_ty, extract.index) orelse continue;
        if (knownLane(function, extract.vector, index, 0)) |value| try folds.append(a, .{ .name = inst.result.?, .value = value });
    };
    if (loads.items.len == 0 and folds.items.len == 0) return null;
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_fp_vector_load_" };
    defer names.deinit(a);
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        if (block.terminator) |term| if (term == .@"switch") {
            var copied = term.@"switch";
            copied.cases = try copied.cases.clone(a);
            block.terminator = .{ .@"switch" = copied };
        };
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.result != null) {
                if (inst.kind == .load) if (findLoad(loads.items, inst.result.?)) |plan| {
                    var attrs = inst.kind.load.attrs;
                    if (attrs.@"align") |alignment| attrs.@"align" = @min(alignment, 4);
                    for (plan.results, 0..) |name, index| {
                        var pointer = inst.kind.load.ptr;
                        if (index != 0) {
                            const address = try forms.temporary(a, function, &names);
                            var indices: std.ArrayList(ir.GepIndex) = .empty;
                            try indices.append(a, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(index * 4) } });
                            try block.instructions.append(a, .{ .result = address, .kind = .{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = pointer, .indices = indices } } });
                            pointer = .{ .named = address };
                        }
                        try block.instructions.append(a, .{ .result = name, .kind = .{ .load = .{ .ty = .float, .ptr = pointer, .attrs = attrs } } });
                    }
                    continue;
                };
                if (inst.kind == .extractelement) {
                    const vector = inst.kind.extractelement.vector;
                    if ((vector == .named and findLoad(loads.items, vector.named) != null) or
                        findFold(folds.items, inst.result.?) != null) continue;
                }
            }
            try block.instructions.append(a, try inst.clone(a));
        }
        try result.blocks.append(a, block);
    }
    for (folds.items) |fold| {
        const value = replacement(folds.items, fold.value) orelse return null;
        _ = ir.operands.replaceAllUses(&result, fold.name, value);
        // Structured replacement never rewrites opaque slots. Decline rather
        // than leave an unbound name in metadata, bundles or raw arguments.
        if (try functionUses(a, result, fold.name)) return null;
    }
    for (0..17) |_| {
        var changed = false;
        for (result.blocks.items) |*block| {
            var index = block.instructions.items.len;
            while (index != 0) {
                index -= 1;
                const inst = &block.instructions.items[index];
                if (inst.removed or inst.result == null or
                    (inst.kind != .cast and !(inst.kind == .insertelement and fourFloats(inst.kind.insertelement.vector_ty)))) continue;
                if (!try functionUses(a, result, inst.result.?)) {
                    inst.removed = true;
                    changed = true;
                }
            }
        }
        if (!changed) break;
    }
    return result;
}

test "floating vector views fold only a proven constant inserted lane and preserve source operands" {
    for ([_]struct { insert: []const u8 = "i32 1", extract: []const u8 = "i64 0", accepted: bool }{
        .{ .accepted = true },
        .{ .insert = "i32 %index", .accepted = false },
        .{ .extract = "i64 2", .accepted = false },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare float @observe(float)\ndefine float @view(float %a,float %b,i32 %index) {{\nentry:\n %first = insertelement <4 x float> poison,float %a,i32 0\n %second = insertelement <4 x float> %first,float %b,{s}\n %lane = extractelement <4 x float> %second,{s}\n %out = call float @observe(float %lane)\n ret float %out\n}}\n", .{ case.insert, case.extract });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const rewritten = try legalize(arena.allocator(), module.functions.items[0], null);
        try std.testing.expectEqual(case.accepted, rewritten != null);
        try std.testing.expectEqualStrings("lane", module.functions.items[0].blocks.items[0].instructions.items[3].kind.call.args.items[0].value.named);
        if (rewritten) |candidate| {
            try std.testing.expectEqualStrings("a", candidate.blocks.items[0].instructions.items[2].kind.call.args.items[0].value.named);
            var verified = module;
            verified.functions = try module.functions.clone(arena.allocator());
            verified.functions.items[0] = candidate;
            try verified.verify();
            try std.testing.expect((try legalize(arena.allocator(), candidate, null)) == null);
        }
    }
}

test "floating vector views snapshot all four ordinary lanes and reject other consumers" {
    for ([_]struct { access: []const u8 = "load", extra: []const u8 = "", accepted: bool }{
        .{ .accepted = true },
        .{ .access = "load volatile", .accepted = false },
        .{ .extra = "%other = bitcast <4 x float> %vector to i128", .accepted = false },
        .{ .extra = "%other = extractelement <4 x float> %vector,i32 0", .accepted = false },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define float @snapshot(ptr %p) {{\nentry:\n %vector = {s} <4 x float>,ptr %p,align 4\n %a = extractelement <4 x float> %vector,i64 0\n %b = extractelement <4 x float> %vector,i64 1\n %c = extractelement <4 x float> %vector,i64 2\n %d = extractelement <4 x float> %vector,i64 3\n {s}\n %sum = fadd float %a,%d\n ret float %sum\n}}\n", .{ case.access, case.extra });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const rewritten = try legalize(arena.allocator(), module.functions.items[0], null);
        try std.testing.expectEqual(case.accepted, rewritten != null);
        try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind.load.ty == .vector);
        if (rewritten) |candidate| {
            try std.testing.expect(candidate.blocks.items[0].instructions.items[0].kind.load.ty == .float);
            try std.testing.expectEqualStrings("a", candidate.blocks.items[0].instructions.items[0].result.?);
            var verified = module;
            verified.functions = try module.functions.clone(arena.allocator());
            verified.functions.items[0] = candidate;
            try verified.verify();
            try std.testing.expect((try legalize(arena.allocator(), candidate, null)) == null);
        }
    }
}
