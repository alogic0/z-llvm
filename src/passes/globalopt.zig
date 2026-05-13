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
                replaceValue(function, result, initializer);
                removed_loads += 1;
            }
        }
    }
    return removed_loads;
}

fn globalHasRemainingUses(module: ir.Module, global: ir.Global) bool {
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

fn replaceValue(function: *ir.Function, name: []const u8, replacement: ir.Value) void {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            replaceInstructionOperand(instruction, name, replacement);
        }
        if (block.terminator) |*terminator| replaceTerminatorOperand(terminator, name, replacement);
    }
}

fn replaceInstructionOperand(instruction: *ir.Instruction, name: []const u8, replacement: ir.Value) void {
    switch (instruction.kind) {
        .binary => |*binary| {
            binary.lhs = replaceOperand(binary.lhs, name, replacement);
            binary.rhs = replaceOperand(binary.rhs, name, replacement);
        },
        .cast => |*cast| cast.value = replaceOperand(cast.value, name, replacement),
        .freeze => |*freeze| freeze.value = replaceOperand(freeze.value, name, replacement),
        .icmp => |*icmp| {
            icmp.lhs = replaceOperand(icmp.lhs, name, replacement);
            icmp.rhs = replaceOperand(icmp.rhs, name, replacement);
        },
        .fcmp => |*fcmp| {
            fcmp.lhs = replaceOperand(fcmp.lhs, name, replacement);
            fcmp.rhs = replaceOperand(fcmp.rhs, name, replacement);
        },
        .select => |*select| {
            select.cond = replaceOperand(select.cond, name, replacement);
            select.true_value = replaceOperand(select.true_value, name, replacement);
            select.false_value = replaceOperand(select.false_value, name, replacement);
        },
        .phi => |*phi| for (phi.incoming.items) |*incoming| {
            incoming.value = replaceOperand(incoming.value, name, replacement);
        },
        .alloca => {},
        .load => |*load| load.ptr = replaceOperand(load.ptr, name, replacement),
        .store => |*store| {
            store.value = replaceOperand(store.value, name, replacement);
            store.ptr = replaceOperand(store.ptr, name, replacement);
        },
        .atomicrmw => |*atomicrmw| {
            atomicrmw.ptr = replaceOperand(atomicrmw.ptr, name, replacement);
            atomicrmw.value = replaceOperand(atomicrmw.value, name, replacement);
        },
        .cmpxchg => |*cmpxchg| {
            cmpxchg.ptr = replaceOperand(cmpxchg.ptr, name, replacement);
            cmpxchg.expected = replaceOperand(cmpxchg.expected, name, replacement);
            cmpxchg.replacement = replaceOperand(cmpxchg.replacement, name, replacement);
        },
        .fence => {},
        .extractelement => |*extract| {
            extract.vector = replaceOperand(extract.vector, name, replacement);
            extract.index = replaceOperand(extract.index, name, replacement);
        },
        .insertelement => |*insert| {
            insert.vector = replaceOperand(insert.vector, name, replacement);
            insert.value = replaceOperand(insert.value, name, replacement);
            insert.index = replaceOperand(insert.index, name, replacement);
        },
        .shufflevector => |*shuffle| {
            shuffle.lhs = replaceOperand(shuffle.lhs, name, replacement);
            shuffle.rhs = replaceOperand(shuffle.rhs, name, replacement);
            shuffle.mask = replaceOperand(shuffle.mask, name, replacement);
        },
        .extractvalue => |*extract| extract.aggregate = replaceOperand(extract.aggregate, name, replacement),
        .insertvalue => |*insert| {
            insert.aggregate = replaceOperand(insert.aggregate, name, replacement);
            insert.value = replaceOperand(insert.value, name, replacement);
        },
        .gep => |*gep| {
            gep.ptr = replaceOperand(gep.ptr, name, replacement);
            for (gep.indices.items) |*index| {
                index.value = replaceOperand(index.value, name, replacement);
            }
        },
        .call => |*call| {
            if (call.callee_value) |value| call.callee_value = replaceOperand(value, name, replacement);
            for (call.args.items) |*arg| {
                arg.value = replaceOperand(arg.value, name, replacement);
            }
        },
    }
}

fn replaceTerminatorOperand(terminator: *ir.Terminator, name: []const u8, replacement: ir.Value) void {
    switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = replaceOperand(value, name, replacement);
        },
        .br => {},
        .@"unreachable" => {},
        .condbr => |*condbr| condbr.cond = replaceOperand(condbr.cond, name, replacement),
        .indirectbr => |*indirectbr| indirectbr.addr = replaceOperand(indirectbr.addr, name, replacement),
        .@"switch" => |*switch_term| {
            switch_term.cond = replaceOperand(switch_term.cond, name, replacement);
            for (switch_term.cases.items) |*case| {
                case.value = replaceOperand(case.value, name, replacement);
            }
        },
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}

fn isLoadFoldableScalar(value: ir.Value) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => true,
        .named, .vector, .constant_expr => false,
    };
}

fn isGlobalValue(value: ir.Value, name: []const u8) bool {
    return valueIsGlobal(value, name);
}

fn valueIsGlobal(value: ir.Value, name: []const u8) bool {
    const value_name = switch (value) {
        .named => |value_name| value_name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
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
