const std = @import("std");
const dominator = @import("../analysis/dominator.zig");
const expression_key = @import("../analysis/expression_key.zig");
const fast_math = @import("../analysis/fast_math.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const memory_ssa = @import("../analysis/memory_ssa.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "gvn",
    .category = .scalar,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/GVN.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try eliminateFunction(module.allocator, module.*, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

const ValueNumber = usize;

const NumberedExpression = struct {
    number: ValueNumber,
    hash: u64,
    instruction: ir.Instruction,
};

const Leader = struct {
    number: ValueNumber,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
};

const ValueTable = struct {
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: ir.Function,
    next_number: ValueNumber = 1,
    entries: std.ArrayList(NumberedExpression) = .empty,

    fn init(allocator: std.mem.Allocator, module: ir.Module, function: ir.Function) ValueTable {
        return .{
            .allocator = allocator,
            .module = module,
            .function = function,
        };
    }

    fn deinit(table: *ValueTable) void {
        table.entries.deinit(table.allocator);
    }

    fn numberFor(table: *ValueTable, instruction: ir.Instruction) !ValueNumber {
        const hash = expression_key.hash(instruction);
        for (table.entries.items) |entry| {
            if (entry.hash != hash) continue;
            if (sameValueExpression(table.module, table.function, entry.instruction, instruction)) return entry.number;
        }

        const number = table.next_number;
        table.next_number += 1;
        try table.entries.append(table.allocator, .{
            .number = number,
            .hash = hash,
            .instruction = instruction,
        });
        return number;
    }
};

fn eliminateFunction(allocator: std.mem.Allocator, module: ir.Module, function: *ir.Function) !bool {
    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var aliases = std.StringHashMap(ir.Value).init(allocator);
    defer aliases.deinit();

    var table = ValueTable.init(allocator, module, function.*);
    defer table.deinit();

    var memory = try memory_ssa.MemorySSA.build(allocator, module, function.*);
    defer memory.deinit();

    var leaders: std.ArrayList(Leader) = .empty;
    defer leaders.deinit(allocator);

    return try visitBlock(allocator, function, dom, &aliases, &table, memory, &leaders, 0);
}

fn visitBlock(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    dom: dominator.Dominators,
    aliases: *std.StringHashMap(ir.Value),
    table: *ValueTable,
    memory: memory_ssa.MemorySSA,
    leaders: *std.ArrayList(Leader),
    block_index: usize,
) !bool {
    const old_leader_len = leaders.items.len;
    defer leaders.shrinkRetainingCapacity(old_leader_len);

    var changed = false;
    const block = &function.blocks.items[block_index];
    for (block.instructions.items, 0..) |*instruction, instruction_index| {
        instruction.mapOperands(aliases.*);
        if (instruction.removed or !isCandidate(table.module, instruction.*)) continue;

        const number = try table.numberFor(instruction.*);
        if (findLeader(table.module, function.*, memory, leaders.items, number, block_index, instruction_index, instruction.*)) |replacement| {
            instruction.removed = true;
            instruction.replacement = replacement;
            const result = instruction.result orelse return error.InstructionWithoutResult;
            try aliases.put(result, replacement);
            replaceValue(function, result, replacement);
            changed = true;
            continue;
        }

        try leaders.append(allocator, .{
            .number = number,
            .block_index = block_index,
            .instruction_index = instruction_index,
            .instruction = instruction.*,
        });
    }

    if (block.terminator) |*terminator| switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = resolveValue(aliases.*, value);
        },
        .br => {},
        .@"unreachable" => {},
        .condbr => |*condbr| condbr.cond = resolveValue(aliases.*, condbr.cond),
        .indirectbr => |*indirectbr| indirectbr.addr = resolveValue(aliases.*, indirectbr.addr),
        .@"switch" => |*switch_term| {
            switch_term.cond = resolveValue(aliases.*, switch_term.cond);
            for (switch_term.cases.items) |*case| {
                case.value = resolveValue(aliases.*, case.value);
            }
        },
    };

    for (0..function.blocks.items.len) |child_index| {
        if (dom.immediateDominator(child_index) != block_index) continue;
        changed = try visitBlock(allocator, function, dom, aliases, table, memory, leaders, child_index) or changed;
    }

    return changed;
}

fn findLeader(
    module: ir.Module,
    function: ir.Function,
    memory: memory_ssa.MemorySSA,
    leaders: []const Leader,
    number: ValueNumber,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) ?ir.Value {
    var index = leaders.len;
    while (index > 0) {
        index -= 1;
        const leader = leaders[index];
        if (leader.number != number) continue;
        if (!isMemoryAvailable(module, function, memory, leader, block_index, instruction_index, instruction)) continue;
        return .{ .named = leader.instruction.result orelse return null };
    }
    return null;
}

fn isCandidate(module: ir.Module, instruction: ir.Instruction) bool {
    const effect = memory_effect.classify(instruction);
    if (effect != .none and effect != .readonly_load) {
        const call = switch (instruction.kind) {
            .call => |call| call,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return false,
        };
        return call.ret_ty != .void and function_attrs.callMemoryEffect(module, call) == .none;
    }
    return switch (instruction.kind) {
        .binary => |binary| !isFpBinary(binary.op) or fast_math.allowFpValueNumbering(binary.fp_flags),
        .cast, .icmp, .select, .phi, .load => true,
        .fcmp => |fcmp| fast_math.allowFpValueNumbering(fcmp.fp_flags),
        .freeze, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => false,
    };
}

fn sameValueExpression(module: ir.Module, function: ir.Function, candidate: ir.Instruction, instruction: ir.Instruction) bool {
    return expression_key.sameValueExpression(module, function, candidate, instruction);
}

fn isMemoryAvailable(module: ir.Module, function: ir.Function, memory: memory_ssa.MemorySSA, leader: Leader, block_index: usize, instruction_index: usize, instruction: ir.Instruction) bool {
    if (instruction.kind != .load) return true;
    _ = module;
    _ = function;
    return !memory.hasClobberBetweenAccess(
        .{ .block_index = leader.block_index, .instruction_index = leader.instruction_index },
        .{ .block_index = block_index, .instruction_index = instruction_index },
        instruction.kind.load.ptr,
        instruction.kind.load.ty,
    );
}

fn replaceValue(function: *ir.Function, name: []const u8, replacement: ir.Value) void {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
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
                .fence, .extractelement, .insertelement, .shufflevector => {},
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
                .call => |*call| for (call.args.items) |*arg| {
                    arg.value = replaceOperand(arg.value, name, replacement);
                },
            }
        }
        if (block.terminator) |*terminator| switch (terminator.*) {
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
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn isFpBinary(op: ir.BinaryOp) bool {
    return op == .fadd or op == .fsub or op == .fmul or op == .fdiv or op == .frem;
}
