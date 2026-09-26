const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "constmerge",
    .category = .ipo,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/ConstantMerge.cpp",
    .run = run,
};

const Replacement = struct {
    old_name: []const u8,
    new_name: []const u8,
    new_value: ir.Value,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    var replacements: std.ArrayList(Replacement) = .empty;
    defer replacements.deinit(context.allocator);

    for (module.globals.items, 0..) |global, index| {
        if (!isMergeableConstant(global)) continue;

        var canonical_index: ?usize = null;
        var candidate_index = index + 1;
        while (candidate_index < module.globals.items.len) : (candidate_index += 1) {
            const candidate = module.globals.items[candidate_index];
            if (!sameMergeKey(global, candidate)) continue;
            canonical_index = candidate_index;
        }

        const chosen_index = canonical_index orelse continue;
        const canonical = module.globals.items[chosen_index];
        const replacement_name = try module.ownString(try std.fmt.allocPrint(context.allocator, "@{s}", .{canonical.name}));
        try replacements.append(context.allocator, .{
            .old_name = global.name,
            .new_name = canonical.name,
            .new_value = .{ .named = replacement_name },
        });
    }

    if (replacements.items.len == 0) return .unchanged;

    for (replacements.items) |replacement| {
        replaceGlobalUses(module, replacement);
    }
    removeMergedGlobals(module, replacements.items);
    return .changed;
}

fn isMergeableConstant(global: ir.Global) bool {
    if (global.kind != .constant) return false;
    if (!isLocal(global.linkage)) return false;
    if (!hasUnnamedAddr(global)) return false;
    if (hasComdat(global.attrs) or isThreadLocal(global)) return false;
    return switch (global.initializer) {
        .scalar => |value| isScalarConstant(value),
        .none, .array, .c_string, .@"opaque" => false,
    };
}

fn sameMergeKey(a: ir.Global, b: ir.Global) bool {
    if (!isMergeableConstant(b)) return false;
    if (!a.ty.eql(b.ty)) return false;
    if (!sameOptionalText(a.attrs, b.attrs)) return false;
    return switch (a.initializer) {
        .scalar => |a_value| switch (b.initializer) {
            .scalar => |b_value| a_value.eql(b_value),
            .none, .array, .c_string, .@"opaque" => false,
        },
        .none, .array, .c_string, .@"opaque" => false,
    };
}

fn replaceGlobalUses(module: *ir.Module, replacement: Replacement) void {
    for (module.globals.items) |*global| {
        replaceInitializer(&global.initializer, replacement);
    }
    for (module.aliases.items) |*alias| {
        if (std.mem.eql(u8, alias.target, replacement.old_name)) alias.target = replacement.new_name;
    }
    for (module.functions.items) |*function| {
        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.removed) continue;
                replaceInstructionOperand(instruction, replacement);
            }
            if (block.terminator) |*terminator| replaceTerminatorOperand(terminator, replacement);
        }
    }
}

fn replaceInitializer(initializer: *ir.GlobalInitializer, replacement: Replacement) void {
    switch (initializer.*) {
        .scalar => |*value| value.* = replaceValue(value.*, replacement),
        .array => |*array| for (array.values.items) |*value| {
            value.* = replaceValue(value.*, replacement);
        },
        .none, .c_string, .@"opaque" => {},
    }
}

fn removeMergedGlobals(module: *ir.Module, replacements: []const Replacement) void {
    var index: usize = 0;
    while (index < module.globals.items.len) {
        const global = module.globals.items[index];
        if (!isRemovedGlobal(global.name, replacements)) {
            index += 1;
            continue;
        }
        var removed = module.globals.orderedRemove(index);
        removed.deinit(module.allocator);
    }
}

fn isRemovedGlobal(name: []const u8, replacements: []const Replacement) bool {
    for (replacements) |replacement| {
        if (std.mem.eql(u8, name, replacement.old_name)) return true;
    }
    return false;
}

fn replaceInstructionOperand(instruction: *ir.Instruction, replacement: Replacement) void {
    switch (instruction.kind) {
        .binary => |*binary| {
            binary.lhs = replaceValue(binary.lhs, replacement);
            binary.rhs = replaceValue(binary.rhs, replacement);
        },
        .cast => |*cast| cast.value = replaceValue(cast.value, replacement),
        .freeze => |*freeze| freeze.value = replaceValue(freeze.value, replacement),
        .icmp => |*icmp| {
            icmp.lhs = replaceValue(icmp.lhs, replacement);
            icmp.rhs = replaceValue(icmp.rhs, replacement);
        },
        .fcmp => |*fcmp| {
            fcmp.lhs = replaceValue(fcmp.lhs, replacement);
            fcmp.rhs = replaceValue(fcmp.rhs, replacement);
        },
        .select => |*select| {
            select.cond = replaceValue(select.cond, replacement);
            select.true_value = replaceValue(select.true_value, replacement);
            select.false_value = replaceValue(select.false_value, replacement);
        },
        .phi => |*phi| for (phi.incoming.items) |*incoming| {
            incoming.value = replaceValue(incoming.value, replacement);
        },
        .alloca => |*alloca| if (alloca.count) |*count| {
            count.value = replaceValue(count.value, replacement);
        },
        .load => |*load| load.ptr = replaceValue(load.ptr, replacement),
        .store => |*store| {
            store.value = replaceValue(store.value, replacement);
            store.ptr = replaceValue(store.ptr, replacement);
        },
        .atomicrmw => |*atomicrmw| {
            atomicrmw.ptr = replaceValue(atomicrmw.ptr, replacement);
            atomicrmw.value = replaceValue(atomicrmw.value, replacement);
        },
        .cmpxchg => |*cmpxchg| {
            cmpxchg.ptr = replaceValue(cmpxchg.ptr, replacement);
            cmpxchg.expected = replaceValue(cmpxchg.expected, replacement);
            cmpxchg.replacement = replaceValue(cmpxchg.replacement, replacement);
        },
        .fence => {},
        .extractelement => |*extract| {
            extract.vector = replaceValue(extract.vector, replacement);
            extract.index = replaceValue(extract.index, replacement);
        },
        .insertelement => |*insert| {
            insert.vector = replaceValue(insert.vector, replacement);
            insert.value = replaceValue(insert.value, replacement);
            insert.index = replaceValue(insert.index, replacement);
        },
        .shufflevector => |*shuffle| {
            shuffle.lhs = replaceValue(shuffle.lhs, replacement);
            shuffle.rhs = replaceValue(shuffle.rhs, replacement);
            shuffle.mask = replaceValue(shuffle.mask, replacement);
        },
        .extractvalue => |*extract| extract.aggregate = replaceValue(extract.aggregate, replacement),
        .insertvalue => |*insert| {
            insert.aggregate = replaceValue(insert.aggregate, replacement);
            insert.value = replaceValue(insert.value, replacement);
        },
        .gep => |*gep| {
            gep.ptr = replaceValue(gep.ptr, replacement);
            for (gep.indices.items) |*index| {
                index.value = replaceValue(index.value, replacement);
            }
        },
        .call => |*call| {
            if (call.callee_value) |value| call.callee_value = replaceValue(value, replacement);
            for (call.args.items) |*arg| {
                arg.value = replaceValue(arg.value, replacement);
            }
        },
    }
}

fn replaceTerminatorOperand(terminator: *ir.Terminator, replacement: Replacement) void {
    switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = replaceValue(value, replacement);
        },
        .br => {},
        .@"unreachable" => {},
        .condbr => |*condbr| condbr.cond = replaceValue(condbr.cond, replacement),
        .indirectbr => |*indirectbr| indirectbr.addr = replaceValue(indirectbr.addr, replacement),
        .@"switch" => |*switch_term| {
            switch_term.cond = replaceValue(switch_term.cond, replacement);
            for (switch_term.cases.items) |*case| {
                case.value = replaceValue(case.value, replacement);
            }
        },
    }
}

fn replaceValue(value: ir.Value, replacement: Replacement) ir.Value {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return value,
    };
    if (name.len != replacement.old_name.len + 1 or name[0] != '@') return value;
    if (!std.mem.eql(u8, name[1..], replacement.old_name)) return value;
    return replacement.new_value;
}

fn isScalarConstant(value: ir.Value) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => true,
        .named, .vector, .constant_expr => false,
    };
}

fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}

fn hasUnnamedAddr(global: ir.Global) bool {
    return if (global.address_attrs) |text| std.mem.indexOf(u8, text, "unnamed_addr") != null else false;
}

fn hasComdat(attrs: ?[]const u8) bool {
    return if (attrs) |text| std.mem.indexOf(u8, text, "comdat") != null else false;
}

fn isThreadLocal(global: ir.Global) bool {
    return if (global.address_attrs) |text| std.mem.indexOf(u8, text, "thread_local") != null else false;
}

fn sameOptionalText(a: ?[]const u8, b: ?[]const u8) bool {
    if (a == null and b == null) return true;
    if (a == null or b == null) return false;
    return std.mem.eql(u8, a.?, b.?);
}
