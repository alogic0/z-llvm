const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

const likely_weight: i64 = 2000;
const unlikely_weight: i64 = 1;

pub const pass: pass_manager.ModulePass = .{
    .name = "lower-expect",
    .category = .codegen_prep,
    .target_status = "LLVM-shaped subset for llvm.expect.i1 branch metadata",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try lowerFunction(module, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn lowerFunction(module: *ir.Module, function: *ir.Function) !bool {
    var changed = false;

    for (function.blocks.items) |*block| {
        if (block.terminator) |*terminator| switch (terminator.*) {
            .condbr => |*condbr| {
                const expect = findExpectI1ByResult(block.*, condbr.cond) orelse continue;
                const expected = expect.call.args.items[1].value.int;
                condbr.cond = expect.call.args.items[0].value;
                condbr.metadata = try branchWeightMetadata(module, expected);
                changed = true;
            },
            .ret, .br, .@"switch", .indirectbr, .@"unreachable" => {},
        };
    }

    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => continue,
            };
            if (!isSupportedExpectI1(call)) continue;
            replaceValue(function, result, call.args.items[0].value);
            instruction.removed = true;
            changed = true;
        }
    }

    return changed;
}

const ExpectCall = struct {
    call: ir.CallInst,
};

fn findExpectI1ByResult(block: ir.BasicBlock, cond: ir.Value) ?ExpectCall {
    const name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (!std.mem.eql(u8, result, name)) continue;
        const call = switch (instruction.kind) {
            .call => |call| call,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return null,
        };
        if (!isSupportedExpectI1(call)) return null;
        return .{ .call = call };
    }
    return null;
}

fn isSupportedExpectI1(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.expect.i1")) return false;
    if (!call.ret_ty.eql(.{ .int = 1 })) return false;
    if (call.callee_value != null or call.inline_asm != null or call.operand_bundle != null) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !call.args.items[1].ty.eql(.{ .int = 1 })) return false;
    return call.args.items[1].value == .int;
}

fn branchWeightMetadata(module: *ir.Module, expected: i128) ![]const u8 {
    const id = nextMetadataId(module.*);
    const first_weight: i64 = if (expected == 0) unlikely_weight else likely_weight;
    const second_weight: i64 = if (expected == 0) likely_weight else unlikely_weight;
    const record_text = try std.fmt.allocPrint(
        module.allocator,
        "!{} = !{{!\"branch_weights\", !\"expected\", i32 {}, i32 {}}}",
        .{ id, first_weight, second_weight },
    );
    const record = try module.ownString(record_text);
    try module.metadata.append(module.allocator, record);
    return try module.ownString(try std.fmt.allocPrint(module.allocator, "!prof !{}", .{id}));
}

fn nextMetadataId(module: ir.Module) usize {
    var max_id: ?usize = null;
    for (module.metadata.items) |record| {
        const id = metadataId(record) orelse continue;
        if (max_id == null or id > max_id.?) max_id = id;
    }
    return if (max_id) |id| id + 1 else 0;
}

fn metadataId(record: []const u8) ?usize {
    const trimmed = std.mem.trim(u8, record, " \t");
    if (trimmed.len < 2 or trimmed[0] != '!') return null;
    const end = std.mem.indexOfScalar(u8, trimmed, ' ') orelse return null;
    if (end <= 1) return null;
    return std.fmt.parseUnsigned(usize, trimmed[1..end], 10) catch null;
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
