const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "vector-combine",
    .category = .vector,
    .target_status = "LLVM-shaped lane-identity subset",
    .upstream_owner = "llvm/lib/Transforms/Vectorize/VectorCombine.cpp and llvm/lib/Transforms/InstCombine/InstCombineVectorOps.cpp",
    .run = run,
};

const InsertRecord = struct {
    block_index: usize,
    instruction_index: usize,
    insert: ir.InsertElementInst,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        var inserted_vectors = std.StringHashMap(InsertRecord).init(module.allocator);
        defer inserted_vectors.deinit();

        for (function.blocks.items, 0..) |*block, block_index| {
            for (block.instructions.items, 0..) |*instruction, instruction_index| {
                if (instruction.removed) continue;
                switch (instruction.kind) {
                    .insertelement => |insert| if (instruction.result) |result| {
                        try inserted_vectors.put(result, .{
                            .block_index = block_index,
                            .instruction_index = instruction_index,
                            .insert = insert,
                        });
                    },
                    .extractelement => |*extract| {
                        if (try foldExtractAfterInsert(function, instruction, extract, inserted_vectors)) changed = true;
                    },
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
                }
            }
        }
    }
    return if (changed) .changed else .unchanged;
}

fn foldExtractAfterInsert(
    function: *ir.Function,
    instruction: *ir.Instruction,
    extract: *ir.ExtractElementInst,
    inserted_vectors: std.StringHashMap(InsertRecord),
) !bool {
    if (extract.vector != .named) return false;
    const record = inserted_vectors.get(extract.vector.named) orelse return false;
    const insert = record.insert;
    if (extract.index != .int or insert.index != .int) return false;
    if (!extract.vector_ty.eql(insert.vector_ty)) return false;
    const vector_ty = switch (extract.vector_ty) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return false,
    };
    if (!vector_ty.elem_ty.toType().eql(insert.value_ty)) return false;

    if (extract.index.int == insert.index.int) {
        instruction.removed = true;
        instruction.replacement = insert.value;
        const result = instruction.result orelse return error.InstructionWithoutResult;
        replaceValue(function, result, insert.value);
    } else {
        extract.vector = insert.vector;
        extract.index_ty = .{ .int = 64 };
    }

    removeInsertIfDead(function, record);
    return true;
}

fn removeInsertIfDead(function: *ir.Function, record: InsertRecord) void {
    const result = function.blocks.items[record.block_index].instructions.items[record.instruction_index].result orelse return;
    if (hasUse(function.*, result)) return;
    function.blocks.items[record.block_index].instructions.items[record.instruction_index].removed = true;
}

fn hasUse(function: ir.Function, name: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instructionUsesValue(instruction, name)) return true;
        }
        if (block.terminator) |terminator| {
            if (terminatorUsesValue(terminator, name)) return true;
        }
    }
    return false;
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
        .condbr => |*condbr| condbr.cond = replaceOperand(condbr.cond, name, replacement),
        .@"switch" => |*switch_term| {
            switch_term.cond = replaceOperand(switch_term.cond, name, replacement);
            for (switch_term.cases.items) |*case| {
                case.value = replaceOperand(case.value, name, replacement);
            }
        },
        .indirectbr => |*indirectbr| indirectbr.addr = replaceOperand(indirectbr.addr, name, replacement),
        .br, .@"unreachable" => {},
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .named => |candidate| if (std.mem.eql(u8, candidate, name)) replacement else value,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
    };
}

fn instructionUsesValue(instruction: ir.Instruction, name: []const u8) bool {
    return switch (instruction.kind) {
        .binary => |binary| valueIsName(binary.lhs, name) or valueIsName(binary.rhs, name),
        .cast => |cast| valueIsName(cast.value, name),
        .freeze => |freeze| valueIsName(freeze.value, name),
        .icmp => |icmp| valueIsName(icmp.lhs, name) or valueIsName(icmp.rhs, name),
        .fcmp => |fcmp| valueIsName(fcmp.lhs, name) or valueIsName(fcmp.rhs, name),
        .select => |select| valueIsName(select.cond, name) or valueIsName(select.true_value, name) or valueIsName(select.false_value, name),
        .phi => |phi| for (phi.incoming.items) |incoming| {
            if (valueIsName(incoming.value, name)) break true;
        } else false,
        .alloca, .fence => false,
        .load => |load| valueIsName(load.ptr, name),
        .store => |store| valueIsName(store.value, name) or valueIsName(store.ptr, name),
        .atomicrmw => |atomicrmw| valueIsName(atomicrmw.ptr, name) or valueIsName(atomicrmw.value, name),
        .cmpxchg => |cmpxchg| valueIsName(cmpxchg.ptr, name) or valueIsName(cmpxchg.expected, name) or valueIsName(cmpxchg.replacement, name),
        .extractelement => |extract| valueIsName(extract.vector, name) or valueIsName(extract.index, name),
        .insertelement => |insert| valueIsName(insert.vector, name) or valueIsName(insert.value, name) or valueIsName(insert.index, name),
        .shufflevector => |shuffle| valueIsName(shuffle.lhs, name) or valueIsName(shuffle.rhs, name) or valueIsName(shuffle.mask, name),
        .extractvalue => |extract| valueIsName(extract.aggregate, name),
        .insertvalue => |insert| valueIsName(insert.aggregate, name) or valueIsName(insert.value, name),
        .gep => |gep| blk: {
            if (valueIsName(gep.ptr, name)) break :blk true;
            for (gep.indices.items) |index| {
                if (valueIsName(index.value, name)) break :blk true;
            }
            break :blk false;
        },
        .call => |call| blk: {
            if (call.callee_value) |callee_value| {
                if (valueIsName(callee_value, name)) break :blk true;
            }
            for (call.args.items) |arg| {
                if (valueIsName(arg.value, name)) break :blk true;
            }
            break :blk false;
        },
    };
}

fn terminatorUsesValue(terminator: ir.Terminator, name: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| valueIsName(value, name) else false,
        .condbr => |condbr| valueIsName(condbr.cond, name),
        .@"switch" => |switch_term| blk: {
            if (valueIsName(switch_term.cond, name)) break :blk true;
            for (switch_term.cases.items) |case| {
                if (valueIsName(case.value, name)) break :blk true;
            }
            break :blk false;
        },
        .indirectbr => |indirectbr| valueIsName(indirectbr.addr, name),
        .br, .@"unreachable" => false,
    };
}

fn valueIsName(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |candidate| std.mem.eql(u8, candidate, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}
