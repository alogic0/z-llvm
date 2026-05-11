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
        const name = switch (value) {
            .int, .undef => return,
            .named => |name| name,
        };
        const def = ctx.defs.get(name) orelse return error.UnknownValue;
        if (!def.ty.eql(ty)) return error.TypeMismatch;
        try ctx.verifyDominatesUse(def, use_block_index, use_instruction_index);
    }

    fn verifyPhiIncomingValue(ctx: VerifyContext, ty: core.Type, value: core.Value, predecessor_index: usize) !void {
        const name = switch (value) {
            .int, .undef => return,
            .named => |name| name,
        };
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
        switch (global.ty) {
            .int => switch (global.initializer) {
                .int, .undef => {},
                .named => return error.UnsupportedGlobalVariable,
            },
            .ptr => switch (global.initializer) {
                .undef => {},
                .int, .named => return error.UnsupportedGlobalVariable,
            },
            .void, .aggregate => return error.UnsupportedGlobalVariable,
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

fn verifyCall(module: core.Module, ctx: VerifyContext, call: core.CallInst, block_index: usize, instruction_index: usize) !void {
    if (call.calling_conv) |calling_conv| {
        if (!core.isSupportedCallingConvention(calling_conv)) return error.UnsupportedCallingConvention;
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

fn verifyBinaryFlags(binary: core.BinaryInst) !void {
    if (binary.flags.nsw or binary.flags.nuw) {
        switch (binary.op) {
            .add, .sub, .mul, .shl => {},
            .@"and", .@"or", .xor, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    if (binary.flags.exact) {
        switch (binary.op) {
            .udiv, .sdiv, .lshr, .ashr => {},
            .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    if (binary.flags.disjoint) {
        switch (binary.op) {
            .@"or" => {},
            .add, .sub, .mul, .@"and", .xor, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    switch (binary.ty) {
        .int => {},
        .void, .ptr, .aggregate => return error.TypeMismatch,
    }
}

fn verifyCast(cast: core.CastInst) !void {
    const from_bits = switch (cast.from_ty) {
        .int => |bits| bits,
        .void, .ptr, .aggregate => return error.TypeMismatch,
    };
    const to_bits = switch (cast.to_ty) {
        .int => |bits| bits,
        .void, .ptr, .aggregate => return error.TypeMismatch,
    };
    switch (cast.op) {
        .trunc => if (from_bits <= to_bits) return error.InvalidCast,
        .zext, .sext => if (from_bits >= to_bits) return error.InvalidCast,
    }
}

fn verifyMemoryAttrs(attrs: core.MemoryAttrs) !void {
    if (attrs.@"align") |alignment| {
        if (alignment == 0) return error.InvalidAlignment;
        if (!std.math.isPowerOfTwo(alignment)) return error.InvalidAlignment;
    }
    if (attrs.atomic_ordering) |ordering| {
        if (!isKnownAtomicOrdering(ordering)) return error.InvalidAtomicMemory;
    }
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
