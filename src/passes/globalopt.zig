const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "globalopt",
    .category = .ipo,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/GlobalOpt.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    var index: usize = 0;
    while (index < module.globals.items.len) {
        const global = module.globals.items[index];
        const initializer = eligibleInitializer(global) orelse {
            index += 1;
            continue;
        };
        if (!allUsesAreDirectLoads(module.*, global)) {
            index += 1;
            continue;
        }

        const removed_loads = replaceDirectLoads(module, global, initializer);
        if (removed_loads == 0) {
            index += 1;
            continue;
        }

        if (!globalHasRemainingUses(module.*, global)) {
            var removed = module.globals.orderedRemove(index);
            removed.deinit(module.allocator);
        } else {
            index += 1;
        }
        changed = true;
    }

    return if (changed) .changed else .unchanged;
}

fn eligibleInitializer(global: ir.Global) ?ir.Value {
    if (!isLocal(global.linkage)) return null;
    if (global.kind != .global) return null;
    if (hasComdat(global.attrs) or isThreadLocal(global)) return null;
    const scalar = switch (global.initializer) {
        .scalar => |value| value,
        .none, .array, .c_string, .@"opaque" => return null,
    };
    if (!isLoadFoldableScalar(scalar)) return null;
    return scalar;
}

fn allUsesAreDirectLoads(module: ir.Module, global: ir.Global) bool {
    if (hasModuleReference(module, global.name)) return false;
    var uses: usize = 0;
    for (module.functions.items) |function| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (!instructionUsesGlobal(instruction, global.name)) continue;
                uses += 1;
                const load = switch (instruction.kind) {
                    .load => |load| load,
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
                };
                if (load.attrs.isBarrier()) return false;
                if (!load.ty.eql(global.ty)) return false;
                if (!isGlobalValue(load.ptr, global.name)) return false;
            }
            if (block.terminator) |terminator| {
                if (terminatorUsesGlobal(terminator, global.name)) return false;
            }
        }
    }
    return uses != 0;
}

fn replaceDirectLoads(module: *ir.Module, global: ir.Global, initializer: ir.Value) usize {
    var removed_loads: usize = 0;
    for (module.functions.items) |*function| {
        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.removed) continue;
                const load = switch (instruction.kind) {
                    .load => |load| load,
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => continue,
                };
                if (!isGlobalValue(load.ptr, global.name)) continue;
                const result = instruction.result orelse continue;
                instruction.removed = true;
                instruction.replacement = initializer;
                // Preserve the pass's structured-use replacement policy. Global
                // escape eligibility is still decided by the scans above.
                _ = ir.operands.replaceAllUses(function, result, initializer);
                removed_loads += 1;
            }
        }
    }
    return removed_loads;
}

fn globalHasRemainingUses(module: ir.Module, global: ir.Global) bool {
    if (hasModuleReference(module, global.name)) return true;
    for (module.functions.items) |function| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instructionUsesGlobal(instruction, global.name)) return true;
            }
            if (block.terminator) |terminator| {
                if (terminatorUsesGlobal(terminator, global.name)) return true;
            }
        }
    }
    return false;
}

fn hasModuleReference(module: ir.Module, name: []const u8) bool {
    // Assembly can reference symbols without the IR's @ spelling.
    if (module.module_asm.items.len != 0) return true;
    for (module.aliases.items) |alias| {
        if (std.mem.eql(u8, alias.target, name)) return true;
    }
    for (module.globals.items) |global| {
        switch (global.initializer) {
            .none, .c_string => {},
            .scalar => |value| if (valueIsGlobal(value, name)) return true,
            .array => |array| for (array.values.items) |value| {
                if (valueIsGlobal(value, name)) return true;
            },
            .@"opaque" => |text| if (opaqueMayReferenceGlobal(text)) return true,
        }
    }
    return false;
}

fn opaqueMayReferenceGlobal(text: []const u8) bool {
    // These expressions are retained as text. Without a parsed use graph,
    // conservatively retain globals whenever they may contain a symbol use.
    return std.mem.indexOfScalar(u8, text, '@') != null;
}

fn instructionUsesGlobal(instruction: ir.Instruction, name: []const u8) bool {
    return switch (instruction.kind) {
        .binary => |binary| valueIsGlobal(binary.lhs, name) or valueIsGlobal(binary.rhs, name),
        .cast => |cast| valueIsGlobal(cast.value, name),
        .freeze => |freeze| valueIsGlobal(freeze.value, name),
        .icmp => |icmp| valueIsGlobal(icmp.lhs, name) or valueIsGlobal(icmp.rhs, name),
        .fcmp => |fcmp| valueIsGlobal(fcmp.lhs, name) or valueIsGlobal(fcmp.rhs, name),
        .select => |select| valueIsGlobal(select.cond, name) or valueIsGlobal(select.true_value, name) or valueIsGlobal(select.false_value, name),
        .phi => |phi| for (phi.incoming.items) |incoming| {
            if (valueIsGlobal(incoming.value, name)) break true;
        } else false,
        .alloca => false,
        .load => |load| valueIsGlobal(load.ptr, name),
        .store => |store| valueIsGlobal(store.value, name) or valueIsGlobal(store.ptr, name),
        .atomicrmw => |atomicrmw| valueIsGlobal(atomicrmw.ptr, name) or valueIsGlobal(atomicrmw.value, name),
        .cmpxchg => |cmpxchg| valueIsGlobal(cmpxchg.ptr, name) or valueIsGlobal(cmpxchg.expected, name) or valueIsGlobal(cmpxchg.replacement, name),
        .fence => false,
        .extractelement => |extract| valueIsGlobal(extract.vector, name) or valueIsGlobal(extract.index, name),
        .insertelement => |insert| valueIsGlobal(insert.vector, name) or valueIsGlobal(insert.value, name) or valueIsGlobal(insert.index, name),
        .shufflevector => |shuffle| valueIsGlobal(shuffle.lhs, name) or valueIsGlobal(shuffle.rhs, name) or valueIsGlobal(shuffle.mask, name),
        .extractvalue => |extract| valueIsGlobal(extract.aggregate, name),
        .insertvalue => |insert| valueIsGlobal(insert.aggregate, name) or valueIsGlobal(insert.value, name),
        .gep => |gep| blk: {
            if (valueIsGlobal(gep.ptr, name)) break :blk true;
            for (gep.indices.items) |index| {
                if (valueIsGlobal(index.value, name)) break :blk true;
            }
            break :blk false;
        },
        .call => |call| blk: {
            if (call.callee_value) |callee| {
                if (valueIsGlobal(callee, name)) break :blk true;
            }
            for (call.args.items) |arg| {
                if (valueIsGlobal(arg.value, name)) break :blk true;
            }
            break :blk false;
        },
    };
}

fn terminatorUsesGlobal(terminator: ir.Terminator, name: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| valueIsGlobal(value, name) else false,
        .condbr => |condbr| valueIsGlobal(condbr.cond, name),
        .indirectbr => |indirectbr| valueIsGlobal(indirectbr.addr, name),
        .@"switch" => |switch_term| blk: {
            if (valueIsGlobal(switch_term.cond, name)) break :blk true;
            for (switch_term.cases.items) |case| {
                if (valueIsGlobal(case.value, name)) break :blk true;
            }
            break :blk false;
        },
        .br, .@"unreachable" => false,
    };
}

fn isLoadFoldableScalar(value: ir.Value) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => true,
        .named, .vector, .constant_expr => false,
    };
}

fn isGlobalValue(value: ir.Value, name: []const u8) bool {
    return value == .named and valueIsGlobal(value, name);
}

fn valueIsGlobal(value: ir.Value, name: []const u8) bool {
    const value_name = switch (value) {
        .named => |value_name| value_name,
        .vector, .constant_expr => |text| return opaqueMayReferenceGlobal(text),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => return false,
    };
    if (std.mem.eql(u8, value_name, name)) return true;
    return value_name.len == name.len + 1 and value_name[0] == '@' and std.mem.eql(u8, value_name[1..], name);
}

fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}

fn hasComdat(attrs: ?[]const u8) bool {
    return if (attrs) |text| std.mem.indexOf(u8, text, "comdat") != null else false;
}

fn isThreadLocal(global: ir.Global) bool {
    return if (global.address_attrs) |text| std.mem.indexOf(u8, text, "thread_local") != null else false;
}
