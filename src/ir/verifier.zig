const std = @import("std");
const core = @import("core.zig");
const target = @import("../target.zig");

const InstructionLocation = struct {
    block_index: usize,
    instruction_index: usize,
};

const Definition = struct {
    ty: core.Type,
    location: ?InstructionLocation = null,
};

const VerifyContext = struct {
    allocator: std.mem.Allocator,
    function: core.Function,
    defs: std.StringHashMap(Definition),
    predecessors: []bool,
    reachable: []bool,
    dominators: []bool,
    block_count: usize,

    fn init(allocator: std.mem.Allocator, function: core.Function) !VerifyContext {
        const block_count = function.blocks.items.len;
        if (block_count == 0) return error.FunctionWithoutBlocks;

        var ctx: VerifyContext = .{
            .allocator = allocator,
            .function = function,
            .defs = std.StringHashMap(Definition).init(allocator),
            .predecessors = try allocator.alloc(bool, block_count * block_count),
            .reachable = try allocator.alloc(bool, block_count),
            .dominators = try allocator.alloc(bool, block_count * block_count),
            .block_count = block_count,
        };
        errdefer ctx.deinit();

        @memset(ctx.predecessors, false);
        @memset(ctx.reachable, false);
        @memset(ctx.dominators, false);

        try ctx.verifyBlockNames();
        try ctx.buildPredecessors();
        try ctx.verifyEntryBlock();
        try ctx.buildReachability();
        ctx.buildDominators();
        try ctx.collectDefinitions();

        return ctx;
    }

    fn deinit(ctx: *VerifyContext) void {
        ctx.defs.deinit();
        ctx.allocator.free(ctx.predecessors);
        ctx.allocator.free(ctx.reachable);
        ctx.allocator.free(ctx.dominators);
    }

    fn verifyBlockNames(ctx: *VerifyContext) !void {
        var block_defs = std.StringHashMap(void).init(ctx.allocator);
        defer block_defs.deinit();

        for (ctx.function.blocks.items) |block| {
            if (block_defs.contains(block.name)) return error.DuplicateBlock;
            try block_defs.put(block.name, {});
        }
    }

    fn buildPredecessors(ctx: *VerifyContext) !void {
        for (ctx.function.blocks.items, 0..) |block, block_index| {
            const terminator = block.terminator orelse continue;
            switch (terminator) {
                .ret, .@"unreachable" => {},
                .br => |br| try ctx.addEdge(block_index, br.target),
                .condbr => |condbr| {
                    try ctx.addEdge(block_index, condbr.then_target);
                    try ctx.addEdge(block_index, condbr.else_target);
                },
            }
        }
    }

    fn addEdge(ctx: *VerifyContext, from: usize, target_name: []const u8) !void {
        const to = ctx.function.blockIndex(target_name) orelse return error.UnknownBlock;
        ctx.predecessors[ctx.edgeIndex(from, to)] = true;
    }

    fn verifyEntryBlock(ctx: *VerifyContext) !void {
        for (0..ctx.block_count) |predecessor| {
            if (ctx.hasEdge(predecessor, 0)) return error.EntryBlockHasPredecessors;
        }
    }

    fn buildReachability(ctx: *VerifyContext) !void {
        var worklist: std.ArrayList(usize) = .empty;
        defer worklist.deinit(ctx.allocator);

        ctx.reachable[0] = true;
        try worklist.append(ctx.allocator, 0);

        while (worklist.pop()) |block_index| {
            for (0..ctx.block_count) |successor| {
                if (!ctx.hasEdge(block_index, successor) or ctx.reachable[successor]) continue;
                ctx.reachable[successor] = true;
                try worklist.append(ctx.allocator, successor);
            }
        }
    }

    fn buildDominators(ctx: *VerifyContext) void {
        for (0..ctx.block_count) |block_index| {
            if (!ctx.reachable[block_index]) continue;
            if (block_index == 0) {
                ctx.setDominates(0, 0, true);
            } else {
                for (0..ctx.block_count) |candidate| {
                    ctx.setDominates(candidate, block_index, ctx.reachable[candidate]);
                }
            }
        }

        var changed = true;
        while (changed) {
            changed = false;
            for (1..ctx.block_count) |block_index| {
                if (!ctx.reachable[block_index]) continue;

                for (0..ctx.block_count) |candidate| {
                    var new_value = candidate == block_index;
                    if (!new_value) {
                        var all_preds = true;
                        var saw_reachable_pred = false;
                        for (0..ctx.block_count) |pred| {
                            if (!ctx.hasEdge(pred, block_index) or !ctx.reachable[pred]) continue;
                            saw_reachable_pred = true;
                            if (!ctx.dominates(candidate, pred)) {
                                all_preds = false;
                                break;
                            }
                        }
                        new_value = saw_reachable_pred and all_preds;
                    }

                    if (ctx.dominates(candidate, block_index) != new_value) {
                        ctx.setDominates(candidate, block_index, new_value);
                        changed = true;
                    }
                }
            }
        }
    }

    fn collectDefinitions(ctx: *VerifyContext) !void {
        for (ctx.function.params.items) |param| {
            if (ctx.defs.contains(param.name)) return error.DuplicateDefinition;
            try ctx.defs.put(param.name, .{ .ty = param.ty });
        }

        for (ctx.function.blocks.items, 0..) |block, block_index| {
            for (block.instructions.items, 0..) |instruction, instruction_index| {
                if (instruction.removed) continue;
                const result = instruction.result orelse continue;
                if (ctx.defs.contains(result)) return error.DuplicateDefinition;
                const result_ty = instruction.resultType() orelse return error.InstructionWithoutResultType;
                try ctx.defs.put(result, .{
                    .ty = result_ty,
                    .location = .{
                        .block_index = block_index,
                        .instruction_index = instruction_index,
                    },
                });
            }
        }
    }

    fn verifyValue(
        ctx: VerifyContext,
        ty: core.Type,
        value: core.Value,
        use_block_index: usize,
        use_instruction_index: ?usize,
    ) !void {
        if (value == .null_value) return if (ty == .ptr) {} else error.TypeMismatch;
        const name = switch (value) {
            .int => return if (ty.isVector()) error.TypeMismatch else {},
            .fp => return if (ty == .float or ty == .double) {} else error.TypeMismatch,
            .undef => return,
            .null_value => unreachable,
            .zero_initializer => return,
            .vector => |text| return verifyVectorLiteral(ty, text),
            .named => |name| name,
        };
        if (isGlobalValueName(name) and ty == .ptr) return;
        const def = ctx.defs.get(name) orelse return error.UnknownValue;
        if (!def.ty.eql(ty)) return error.TypeMismatch;
        try ctx.verifyDominatesUse(def, use_block_index, use_instruction_index);
    }

    fn verifyPhiIncomingValue(ctx: VerifyContext, ty: core.Type, value: core.Value, predecessor_index: usize) !void {
        if (value == .null_value) return if (ty == .ptr) {} else error.TypeMismatch;
        const name = switch (value) {
            .int => return if (ty.isVector()) error.TypeMismatch else {},
            .fp => return if (ty == .float or ty == .double) {} else error.TypeMismatch,
            .undef => return,
            .null_value => unreachable,
            .zero_initializer => return,
            .vector => |text| return verifyVectorLiteral(ty, text),
            .named => |name| name,
        };
        if (isGlobalValueName(name) and ty == .ptr) return;
        const def = ctx.defs.get(name) orelse return error.UnknownValue;
        if (!def.ty.eql(ty)) return error.TypeMismatch;
        if (!ctx.reachable[predecessor_index]) return;

        const location = def.location orelse return;
        const def_block = location.block_index;
        if (def_block == predecessor_index) return;
        if (!ctx.dominates(def_block, predecessor_index)) return error.ValueDoesNotDominateUse;
    }

    fn verifyDominatesUse(ctx: VerifyContext, def: Definition, use_block_index: usize, use_instruction_index: ?usize) !void {
        const location = def.location orelse return;
        const def_block = location.block_index;
        if (!ctx.reachable[use_block_index]) return;
        if (def_block == use_block_index) {
            const def_instruction = location.instruction_index;
            const use_instruction = use_instruction_index orelse return;
            if (def_instruction >= use_instruction) return error.ValueDoesNotDominateUse;
            return;
        }
        if (!ctx.dominates(def_block, use_block_index)) return error.ValueDoesNotDominateUse;
    }

    fn verifyPhiIncomingBlocks(ctx: VerifyContext, block_index: usize, phi: core.PhiInst) !void {
        var seen = try ctx.allocator.alloc(bool, ctx.block_count);
        defer ctx.allocator.free(seen);
        @memset(seen, false);

        for (phi.incoming.items) |incoming| {
            const predecessor_index = ctx.function.blockIndex(incoming.block) orelse return error.UnknownBlock;
            if (!ctx.hasEdge(predecessor_index, block_index)) return error.PhiIncomingNotPredecessor;
            if (seen[predecessor_index]) return error.DuplicatePhiIncoming;
            seen[predecessor_index] = true;
        }

        for (0..ctx.block_count) |predecessor_index| {
            if (!ctx.hasEdge(predecessor_index, block_index)) continue;
            if (!seen[predecessor_index]) return error.MissingPhiIncoming;
        }
    }

    fn hasEdge(ctx: VerifyContext, from: usize, to: usize) bool {
        return ctx.predecessors[ctx.edgeIndex(from, to)];
    }

    fn dominates(ctx: VerifyContext, dominator: usize, block: usize) bool {
        return ctx.dominators[ctx.edgeIndex(dominator, block)];
    }

    fn setDominates(ctx: *VerifyContext, dominator: usize, block: usize, value: bool) void {
        ctx.dominators[ctx.edgeIndex(dominator, block)] = value;
    }

    fn edgeIndex(ctx: VerifyContext, from: usize, to: usize) usize {
        return to * ctx.block_count + from;
    }
};

pub fn verify(module: core.Module) !void {
    try verifyTargetRecords(module);

    var global_defs = std.StringHashMap(void).init(module.allocator);
    defer global_defs.deinit();
    var decl_defs = std.StringHashMap(void).init(module.allocator);
    defer decl_defs.deinit();

    for (module.globals.items) |global| {
        if (global_defs.contains(global.name)) return error.DuplicateDefinition;
        try global_defs.put(global.name, {});
        switch (global.initializer) {
            .scalar => |value| switch (global.ty) {
                .int => switch (value) {
                    .int, .undef => {},
                    .named, .fp, .null_value, .zero_initializer, .vector => return error.UnsupportedGlobalVariable,
                },
                .ptr => switch (value) {
                    .undef, .null_value => {},
                    .int, .fp, .named, .zero_initializer, .vector => return error.UnsupportedGlobalVariable,
                },
                .void, .float, .double, .aggregate, .vector => return error.UnsupportedGlobalVariable,
            },
            .array => |array| {
                const array_ty = parseArrayType(global.ty) orelse return error.UnsupportedGlobalVariable;
                if (!array_ty.elem_ty.eql(array.elem_ty)) return error.UnsupportedGlobalVariable;
                if (array.values.items.len != array_ty.len) return error.UnsupportedGlobalVariable;
                for (array.values.items) |value| switch (value) {
                    .int, .undef, .null_value, .zero_initializer, .vector => {},
                    .fp, .named => return error.UnsupportedGlobalVariable,
                };
            },
        }
    }

    for (module.aliases.items) |alias| {
        if (global_defs.contains(alias.name)) return error.DuplicateDefinition;
        try global_defs.put(alias.name, {});
        if (alias.target_ty != .ptr) return error.UnsupportedGlobalAlias;
    }

    for (module.declarations.items) |decl| {
        if (global_defs.contains(decl.name)) return error.DuplicateDefinition;
        if (decl_defs.contains(decl.name)) return error.DuplicateDefinition;
        try decl_defs.put(decl.name, {});
    }

    for (module.functions.items) |function| {
        if (global_defs.contains(function.name)) return error.DuplicateDefinition;
        if (findDeclaration(module, function.name)) |decl| try verifyDeclMatchesFunction(decl, function);
        try global_defs.put(function.name, {});
    }

    for (module.aliases.items) |alias| {
        if (!hasGlobalValue(module, alias.target)) return error.UnknownGlobalAliasTarget;
    }

    for (module.functions.items) |function| {
        var ctx = try VerifyContext.init(module.allocator, function);
        defer ctx.deinit();

        for (function.blocks.items, 0..) |block, block_index| {
            var saw_non_phi = false;
            for (block.instructions.items, 0..) |instruction, instruction_index| {
                if (instruction.removed) continue;
                switch (instruction.kind) {
                    .binary => |binary| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyBinaryFlags(binary);
                        try ctx.verifyValue(binary.ty, binary.lhs, block_index, instruction_index);
                        try ctx.verifyValue(binary.ty, binary.rhs, block_index, instruction_index);
                    },
                    .cast => |cast| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyCast(cast);
                        try ctx.verifyValue(cast.from_ty, cast.value, block_index, instruction_index);
                    },
                    .freeze => |freeze| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(freeze.ty, freeze.value, block_index, instruction_index);
                    },
                    .icmp => |icmp| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(icmp.operand_ty, icmp.lhs, block_index, instruction_index);
                        try ctx.verifyValue(icmp.operand_ty, icmp.rhs, block_index, instruction_index);
                    },
                    .fcmp => |fcmp| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        switch (fcmp.operand_ty) {
                            .float, .double => {},
                            .void, .int, .ptr, .aggregate, .vector => return error.TypeMismatch,
                        }
                        try ctx.verifyValue(fcmp.operand_ty, fcmp.lhs, block_index, instruction_index);
                        try ctx.verifyValue(fcmp.operand_ty, fcmp.rhs, block_index, instruction_index);
                    },
                    .select => |select| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        if (!select.cond_ty.eql(.{ .int = 1 })) return error.SelectConditionTypeMismatch;
                        try ctx.verifyValue(select.cond_ty, select.cond, block_index, instruction_index);
                        try ctx.verifyValue(select.ty, select.true_value, block_index, instruction_index);
                        try ctx.verifyValue(select.ty, select.false_value, block_index, instruction_index);
                    },
                    .phi => |phi| {
                        if (saw_non_phi) return error.PhiAfterNonPhi;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        if (phi.incoming.items.len == 0) return error.EmptyPhi;
                        try ctx.verifyPhiIncomingBlocks(block_index, phi);
                        for (phi.incoming.items) |incoming| {
                            const predecessor_index = function.blockIndex(incoming.block) orelse return error.UnknownBlock;
                            try ctx.verifyPhiIncomingValue(phi.ty, incoming.value, predecessor_index);
                        }
                    },
                    .alloca => {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                    },
                    .load => |load| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(.ptr, load.ptr, block_index, instruction_index);
                        try verifyMemoryAttrs(load.attrs);
                    },
                    .store => |store| {
                        saw_non_phi = true;
                        if (instruction.result != null) return error.StoreHasResult;
                        try ctx.verifyValue(store.ty, store.value, block_index, instruction_index);
                        try ctx.verifyValue(.ptr, store.ptr, block_index, instruction_index);
                        try verifyMemoryAttrs(store.attrs);
                    },
                    .atomicrmw => |atomicrmw| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(.ptr, atomicrmw.ptr, block_index, instruction_index);
                        try ctx.verifyValue(atomicrmw.ty, atomicrmw.value, block_index, instruction_index);
                        try verifyAtomicOrdering(atomicrmw.ordering);
                        if (atomicrmw.@"align") |alignment| try verifyAlignment(alignment);
                    },
                    .cmpxchg => |cmpxchg| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(.ptr, cmpxchg.ptr, block_index, instruction_index);
                        try ctx.verifyValue(cmpxchg.ty, cmpxchg.expected, block_index, instruction_index);
                        try ctx.verifyValue(cmpxchg.ty, cmpxchg.replacement, block_index, instruction_index);
                        try verifyAtomicOrdering(cmpxchg.success_ordering);
                        try verifyAtomicOrdering(cmpxchg.failure_ordering);
                        if (cmpxchg.@"align") |alignment| try verifyAlignment(alignment);
                    },
                    .fence => |fence| {
                        saw_non_phi = true;
                        if (instruction.result != null) return error.StoreHasResult;
                        try verifyAtomicOrdering(fence.ordering);
                    },
                    .extractelement => |extract| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyVectorType(extract.vector_ty);
                        try ctx.verifyValue(extract.vector_ty, extract.vector, block_index, instruction_index);
                        try verifyLaneIndex(extract.vector_ty, extract.index_ty, extract.index);
                        try ctx.verifyValue(extract.index_ty, extract.index, block_index, instruction_index);
                    },
                    .insertelement => |insert| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyVectorType(insert.vector_ty);
                        const elem_ty = vectorElementType(insert.vector_ty);
                        if (!insert.value_ty.eql(elem_ty)) return error.TypeMismatch;
                        try ctx.verifyValue(insert.vector_ty, insert.vector, block_index, instruction_index);
                        try ctx.verifyValue(insert.value_ty, insert.value, block_index, instruction_index);
                        try verifyLaneIndex(insert.vector_ty, insert.index_ty, insert.index);
                        try ctx.verifyValue(insert.index_ty, insert.index, block_index, instruction_index);
                    },
                    .shufflevector => |shuffle| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyVectorType(shuffle.lhs_ty);
                        try verifyVectorType(shuffle.rhs_ty);
                        if (!shuffle.lhs_ty.eql(shuffle.rhs_ty)) return error.TypeMismatch;
                        try verifyShuffleMask(shuffle.lhs_ty, shuffle.mask_ty, shuffle.mask);
                        try ctx.verifyValue(shuffle.lhs_ty, shuffle.lhs, block_index, instruction_index);
                        try ctx.verifyValue(shuffle.rhs_ty, shuffle.rhs, block_index, instruction_index);
                        try ctx.verifyValue(shuffle.mask_ty, shuffle.mask, block_index, instruction_index);
                    },
                    .gep => |gep| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(.ptr, gep.ptr, block_index, instruction_index);
                        if (gep.indices.items.len == 0) return error.InvalidGetElementPtr;
                        for (gep.indices.items) |index| {
                            try ctx.verifyValue(index.ty, index.value, block_index, instruction_index);
                        }
                    },
                    .call => |call| {
                        saw_non_phi = true;
                        if (call.ret_ty == .void) {
                            if (instruction.result != null) return error.VoidCallHasResult;
                        } else if (instruction.result == null) {
                            return error.InstructionNeedsResult;
                        }
                        try verifyCall(module, ctx, call, block_index, instruction_index);
                    },
                }
            }

            const terminator = block.terminator orelse return error.BlockWithoutTerminator;
            switch (terminator) {
                .ret => |ret| {
                    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
                    if (ret.ty == .void) {
                        if (ret.value != null) return error.ReturnTypeMismatch;
                    } else {
                        try ctx.verifyValue(ret.ty, ret.value orelse return error.InvalidRet, block_index, block.instructions.items.len);
                    }
                },
                .br => |br| try verifyBlockTarget(function, br.target),
                .condbr => |condbr| {
                    if (!condbr.cond_ty.eql(.{ .int = 1 })) return error.BranchConditionTypeMismatch;
                    try ctx.verifyValue(condbr.cond_ty, condbr.cond, block_index, block.instructions.items.len);
                    try verifyBlockTarget(function, condbr.then_target);
                    try verifyBlockTarget(function, condbr.else_target);
                },
                .@"unreachable" => {},
            }
        }
    }
}

fn verifyDeclMatchesFunction(decl: core.FunctionDecl, function: core.Function) !void {
    if (!decl.ret_ty.eql(function.ret_ty)) return error.CallSignatureMismatch;
    if (!callingConventionsMatch(decl.calling_conv, function.calling_conv)) return error.CallSignatureMismatch;
    if (decl.params.items.len != function.params.items.len) return error.CallSignatureMismatch;
    for (decl.params.items, 0..) |param, index| {
        if (!param.ty.eql(function.params.items[index].ty)) return error.CallSignatureMismatch;
    }
}

fn isGlobalValueName(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "@");
}

fn verifyCall(module: core.Module, ctx: VerifyContext, call: core.CallInst, block_index: usize, instruction_index: usize) !void {
    if (call.calling_conv) |calling_conv| {
        if (!core.isSupportedCallingConvention(calling_conv)) return error.UnsupportedCallingConvention;
    }

    if (call.inline_asm) |inline_asm| {
        if (!inline_asm.sideeffect) return error.UnsupportedInlineAsm;
        for (call.args.items) |arg| try ctx.verifyValue(arg.ty, arg.value, block_index, instruction_index);
        return;
    }

    if (findDeclaration(module, call.callee)) |decl| {
        if (!call.ret_ty.eql(decl.ret_ty)) return error.CallSignatureMismatch;
        if (!callingConventionsMatch(call.calling_conv, decl.calling_conv)) return error.CallSignatureMismatch;
        if (call.args.items.len != decl.params.items.len) return error.CallSignatureMismatch;
        for (call.args.items, 0..) |arg, index| {
            if (!arg.ty.eql(decl.params.items[index].ty)) return error.CallSignatureMismatch;
            try ctx.verifyValue(arg.ty, arg.value, block_index, instruction_index);
        }
        return;
    }

    if (findFunction(module, call.callee)) |function| {
        if (!call.ret_ty.eql(function.ret_ty)) return error.CallSignatureMismatch;
        if (!callingConventionsMatch(call.calling_conv, function.calling_conv)) return error.CallSignatureMismatch;
        if (call.args.items.len != function.params.items.len) return error.CallSignatureMismatch;
        for (call.args.items, 0..) |arg, index| {
            if (!arg.ty.eql(function.params.items[index].ty)) return error.CallSignatureMismatch;
            try ctx.verifyValue(arg.ty, arg.value, block_index, instruction_index);
        }
        return;
    }

    return error.UnknownFunction;
}

fn verifyTargetRecords(module: core.Module) !void {
    if (module.target_triple) |triple_text| {
        _ = try target.Triple.parse(triple_text);
    }
    if (module.target_datalayout) |layout_text| {
        const layout = try target.DataLayout.parse(layout_text);
        if (try layout.pointerSizeBits() == 0) return error.InvalidDataLayout;
    }
}

fn findDeclaration(module: core.Module, name: []const u8) ?core.FunctionDecl {
    for (module.declarations.items) |decl| {
        if (std.mem.eql(u8, decl.name, name)) return decl;
    }
    return null;
}

fn findFunction(module: core.Module, name: []const u8) ?core.Function {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return function;
    }
    return null;
}

fn hasGlobalValue(module: core.Module, name: []const u8) bool {
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, name)) return true;
    }
    for (module.aliases.items) |alias| {
        if (std.mem.eql(u8, alias.name, name)) return true;
    }
    if (findDeclaration(module, name) != null) return true;
    if (findFunction(module, name) != null) return true;
    return false;
}

const ParsedArrayType = struct {
    len: usize,
    elem_ty: core.Type,
};

fn parseArrayType(ty: core.Type) ?ParsedArrayType {
    const text = switch (ty) {
        .aggregate => |aggregate| aggregate,
        .void, .int, .float, .double, .ptr, .vector => return null,
    };
    if (text.len < 5 or text[0] != '[' or text[text.len - 1] != ']') return null;
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    const x_index = std.mem.indexOf(u8, body, " x ") orelse return null;
    const len = std.fmt.parseInt(usize, std.mem.trim(u8, body[0..x_index], " \t"), 10) catch return null;
    const elem_ty = parseType(std.mem.trim(u8, body[x_index + 3 ..], " \t")) catch return null;
    return .{ .len = len, .elem_ty = elem_ty };
}

fn parseType(text: []const u8) !core.Type {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (std.mem.eql(u8, trimmed, "void")) return .void;
    if (std.mem.eql(u8, trimmed, "ptr")) return .ptr;
    if (std.mem.eql(u8, trimmed, "float")) return .float;
    if (std.mem.eql(u8, trimmed, "double")) return .double;
    if (trimmed.len >= 2 and trimmed[0] == '<' and trimmed[trimmed.len - 1] == '>') return .{ .vector = try parseVectorType(trimmed) };
    if (trimmed.len >= 2 and ((trimmed[0] == '{' and trimmed[trimmed.len - 1] == '}') or
        (trimmed[0] == '[' and trimmed[trimmed.len - 1] == ']'))) return .{ .aggregate = trimmed };
    if (trimmed.len < 2 or trimmed[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, trimmed[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
}

fn parseVectorType(text: []const u8) !core.VectorType {
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    if (std.mem.startsWith(u8, body, "vscale")) return error.UnsupportedType;
    const x_index = std.mem.indexOf(u8, body, " x ") orelse return error.UnsupportedType;
    const len = try std.fmt.parseInt(u32, std.mem.trim(u8, body[0..x_index], " \t"), 10);
    if (len == 0) return error.UnsupportedType;
    const elem_ty = try parseVectorElementType(std.mem.trim(u8, body[x_index + 3 ..], " \t"));
    return .{ .len = len, .elem_ty = elem_ty };
}

fn parseVectorElementType(text: []const u8) !core.VectorElementType {
    if (std.mem.eql(u8, text, "ptr")) return .ptr;
    if (std.mem.eql(u8, text, "float")) return .float;
    if (std.mem.eql(u8, text, "double")) return .double;
    if (text.len < 2 or text[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, text[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
}

fn verifyVectorLiteral(ty: core.Type, text: []const u8) !void {
    if (ty != .vector) return error.TypeMismatch;
    const vector = ty.vector;
    if (text.len < 2 or text[0] != '<' or text[text.len - 1] != '>') return error.InvalidValue;
    var rest = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    var lane_count: u32 = 0;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const raw_lane = if (comma) |index| rest[0..index] else rest;
        const lane = std.mem.trim(u8, raw_lane, " \t");
        const typed = try parseLeadingType(lane);
        if (!typed.ty.eql(vector.elem_ty.toType())) return error.TypeMismatch;
        _ = try parseValueForLiteral(std.mem.trim(u8, typed.after, " \t"));
        lane_count += 1;
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
    if (lane_count != vector.len) return error.TypeMismatch;
}

fn verifyVectorType(ty: core.Type) !void {
    if (ty != .vector) return error.TypeMismatch;
}

fn vectorElementType(ty: core.Type) core.Type {
    return ty.vector.elem_ty.toType();
}

fn verifyLaneIndex(vector_ty: core.Type, index_ty: core.Type, index: core.Value) !void {
    if (vector_ty != .vector) return error.TypeMismatch;
    if (index_ty != .int) return error.TypeMismatch;
    switch (index) {
        .int => |lane| if (lane < 0 or lane >= vector_ty.vector.len) return error.TypeMismatch,
        .named, .undef => {},
        .fp, .null_value, .zero_initializer, .vector => return error.TypeMismatch,
    }
}

fn verifyShuffleMask(vector_ty: core.Type, mask_ty: core.Type, mask: core.Value) !void {
    if (vector_ty != .vector or mask_ty != .vector) return error.TypeMismatch;
    switch (mask_ty.vector.elem_ty) {
        .int => {},
        .float, .double, .ptr => return error.TypeMismatch,
    }
    switch (mask) {
        .vector => |text| try verifyShuffleMaskLiteral(vector_ty.vector.len * 2, mask_ty, text),
        .undef, .zero_initializer => {},
        .named, .int, .fp, .null_value => return error.TypeMismatch,
    }
}

fn verifyShuffleMaskLiteral(max_lane: u32, mask_ty: core.Type, text: []const u8) !void {
    const mask_vector = mask_ty.vector;
    if (text.len < 2 or text[0] != '<' or text[text.len - 1] != '>') return error.InvalidValue;
    var rest = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    var lane_count: u32 = 0;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const raw_lane = if (comma) |index| rest[0..index] else rest;
        const lane = std.mem.trim(u8, raw_lane, " \t");
        const typed = try parseLeadingType(lane);
        if (!typed.ty.eql(mask_vector.elem_ty.toType())) return error.TypeMismatch;
        const value_text = std.mem.trim(u8, typed.after, " \t");
        if (!std.mem.eql(u8, value_text, "undef")) {
            const value = try std.fmt.parseInt(i128, value_text, 10);
            if (value < 0 or value >= max_lane) return error.TypeMismatch;
        }
        lane_count += 1;
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
    if (lane_count != mask_vector.len) return error.TypeMismatch;
}

const ParsedLeadingType = struct {
    ty: core.Type,
    after: []const u8,
};

fn parseLeadingType(text: []const u8) !ParsedLeadingType {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return error.UnsupportedType;
    if (trimmed[0] == '<') {
        const close = findMatchingAngle(trimmed, 0) orelse return error.UnsupportedType;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .after = std.mem.trim(u8, trimmed[close + 1 ..], " \t"),
        };
    }
    const end = std.mem.indexOfAny(u8, trimmed, " \t") orelse trimmed.len;
    return .{
        .ty = try parseType(trimmed[0..end]),
        .after = std.mem.trim(u8, trimmed[end..], " \t"),
    };
}

fn parseValueForLiteral(text: []const u8) !void {
    if (text.len == 0) return error.InvalidValue;
    if (std.mem.eql(u8, text, "undef") or std.mem.eql(u8, text, "zeroinitializer")) return;
    if (std.mem.eql(u8, text, "true") or std.mem.eql(u8, text, "false")) return;
    _ = try std.fmt.parseInt(i128, text, 10);
}

fn findMatchingAngle(text: []const u8, open_index: usize) ?usize {
    if (text[open_index] != '<') return null;
    var depth: usize = 0;
    for (text[open_index..], open_index..) |byte, index| {
        if (byte == '<') depth += 1;
        if (byte == '>') {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

fn findTopLevelComma(text: []const u8) ?usize {
    var angle_depth: usize = 0;
    for (text, 0..) |byte, index| {
        switch (byte) {
            '<' => angle_depth += 1,
            '>' => {
                if (angle_depth == 0) return null;
                angle_depth -= 1;
            },
            ',' => if (angle_depth == 0) return index,
            else => {},
        }
    }
    return null;
}

fn verifyBinaryFlags(binary: core.BinaryInst) !void {
    if (binary.flags.nsw or binary.flags.nuw) {
        switch (binary.op) {
            .add, .sub, .mul, .shl => {},
            .fadd, .fmul, .@"and", .@"or", .xor, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    if (binary.flags.exact) {
        switch (binary.op) {
            .udiv, .sdiv, .lshr, .ashr => {},
            .fadd, .fmul, .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    if (binary.flags.disjoint) {
        switch (binary.op) {
            .@"or" => {},
            .fadd, .fmul, .add, .sub, .mul, .@"and", .xor, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    switch (binary.op) {
        .fadd, .fmul => switch (binary.ty) {
            .float, .double => {},
            .vector => |vector| switch (vector.elem_ty) {
                .float, .double => {},
                .int, .ptr => return error.TypeMismatch,
            },
            .void, .int, .ptr, .aggregate => return error.TypeMismatch,
        },
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => switch (binary.ty) {
            .int => {},
            .vector => |vector| switch (vector.elem_ty) {
                .int => {},
                .float, .double, .ptr => return error.TypeMismatch,
            },
            .void, .float, .double, .ptr, .aggregate => return error.TypeMismatch,
        },
    }
}

fn verifyCast(cast: core.CastInst) !void {
    const from_bits = switch (cast.from_ty) {
        .int => |bits| bits,
        .void, .float, .double, .ptr, .aggregate, .vector => return error.TypeMismatch,
    };
    const to_bits = switch (cast.to_ty) {
        .int => |bits| bits,
        .void, .float, .double, .ptr, .aggregate, .vector => return error.TypeMismatch,
    };
    switch (cast.op) {
        .trunc => if (from_bits <= to_bits) return error.InvalidCast,
        .zext, .sext => if (from_bits >= to_bits) return error.InvalidCast,
    }
}

fn verifyMemoryAttrs(attrs: core.MemoryAttrs) !void {
    if (attrs.@"align") |alignment| {
        try verifyAlignment(alignment);
    }
    if (attrs.atomic_ordering) |ordering| {
        try verifyAtomicOrdering(ordering);
    }
}

fn verifyAlignment(alignment: u32) !void {
    if (alignment == 0) return error.InvalidAlignment;
    if (!std.math.isPowerOfTwo(alignment)) return error.InvalidAlignment;
}

fn verifyAtomicOrdering(ordering: []const u8) !void {
    if (!isKnownAtomicOrdering(ordering)) return error.InvalidAtomicMemory;
}

fn verifyBlockTarget(function: core.Function, block_name: []const u8) !void {
    if (function.blockIndex(block_name) == null) return error.UnknownBlock;
}

fn callingConventionsMatch(lhs: ?[]const u8, rhs: ?[]const u8) bool {
    return std.mem.eql(u8, canonicalCallingConvention(lhs), canonicalCallingConvention(rhs));
}

fn canonicalCallingConvention(calling_conv: ?[]const u8) []const u8 {
    return calling_conv orelse "ccc";
}

fn isKnownAtomicOrdering(ordering: []const u8) bool {
    const known = [_][]const u8{
        "unordered",
        "monotonic",
        "acquire",
        "release",
        "acq_rel",
        "seq_cst",
    };
    for (known) |candidate| {
        if (std.mem.eql(u8, ordering, candidate)) return true;
    }
    return false;
}
