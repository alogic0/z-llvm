const std = @import("std");
const core = @import("core.zig");
const fp_semantics = @import("../analysis/fp_semantics.zig");
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
                .@"switch" => |switch_term| {
                    try ctx.addEdge(block_index, switch_term.default_target);
                    for (switch_term.cases.items) |case| try ctx.addEdge(block_index, case.target);
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
            .fp => |text| {
                _ = fp_semantics.classify(ty, text) catch return error.UnsupportedFloatingPointLiteral;
                return;
            },
            .undef => return,
            .null_value => unreachable,
            .zero_initializer => return,
            .vector => |text| return verifyVectorLiteral(ty, text),
            .constant_expr => |text| return verifyConstantExprValue(ty, text),
            .named => |name| name,
        };
        if (isGlobalValueName(name) and ty == .ptr) return;
        if (std.mem.startsWith(u8, name, "!")) return if (ty == .metadata) {} else error.TypeMismatch;
        const def = ctx.defs.get(name) orelse return error.UnknownValue;
        if (!def.ty.eql(ty)) return error.TypeMismatch;
        try ctx.verifyDominatesUse(def, use_block_index, use_instruction_index);
    }

    fn verifyPhiIncomingValue(ctx: VerifyContext, ty: core.Type, value: core.Value, predecessor_index: usize) !void {
        if (value == .null_value) return if (ty == .ptr) {} else error.TypeMismatch;
        const name = switch (value) {
            .int => return if (ty.isVector()) error.TypeMismatch else {},
            .fp => |text| {
                _ = fp_semantics.classify(ty, text) catch return error.UnsupportedFloatingPointLiteral;
                return;
            },
            .undef => return,
            .null_value => unreachable,
            .zero_initializer => return,
            .vector => |text| return verifyVectorLiteral(ty, text),
            .constant_expr => |text| return verifyConstantExprValue(ty, text),
            .named => |name| name,
        };
        if (isGlobalValueName(name) and ty == .ptr) return;
        if (std.mem.startsWith(u8, name, "!")) return if (ty == .metadata) {} else error.TypeMismatch;
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
        var incoming_counts = try ctx.allocator.alloc(usize, ctx.block_count);
        defer ctx.allocator.free(incoming_counts);
        @memset(incoming_counts, 0);

        for (phi.incoming.items) |incoming| {
            const predecessor_index = ctx.function.blockIndex(incoming.block) orelse return error.UnknownBlock;
            const edge_count = ctx.edgeCount(predecessor_index, block_index);
            if (edge_count == 0) return error.PhiIncomingNotPredecessor;
            incoming_counts[predecessor_index] += 1;
            if (incoming_counts[predecessor_index] > edge_count) return error.DuplicatePhiIncoming;
        }

        for (0..ctx.block_count) |predecessor_index| {
            const edge_count = ctx.edgeCount(predecessor_index, block_index);
            if (edge_count == 0) continue;
            if (incoming_counts[predecessor_index] != edge_count) return error.MissingPhiIncoming;
        }
    }

    fn hasEdge(ctx: VerifyContext, from: usize, to: usize) bool {
        return ctx.predecessors[ctx.edgeIndex(from, to)];
    }

    fn edgeCount(ctx: VerifyContext, from: usize, to: usize) usize {
        const target_name = ctx.function.blocks.items[to].name;
        const terminator = ctx.function.blocks.items[from].terminator orelse return 0;
        var count: usize = 0;
        switch (terminator) {
            .ret, .@"unreachable" => {},
            .br => |br| {
                if (std.mem.eql(u8, br.target, target_name)) count += 1;
            },
            .condbr => |condbr| {
                if (std.mem.eql(u8, condbr.then_target, target_name)) count += 1;
                if (std.mem.eql(u8, condbr.else_target, target_name)) count += 1;
            },
            .@"switch" => |switch_term| {
                if (std.mem.eql(u8, switch_term.default_target, target_name)) count += 1;
                for (switch_term.cases.items) |case| {
                    if (std.mem.eql(u8, case.target, target_name)) count += 1;
                }
            },
        }
        return count;
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
    try verifyNamedTypes(module);
    try verifyMetadataGraph(module);

    var global_defs = std.StringHashMap(void).init(module.allocator);
    defer global_defs.deinit();
    var decl_defs = std.StringHashMap(void).init(module.allocator);
    defer decl_defs.deinit();
    var comdat_defs = std.StringHashMap(void).init(module.allocator);
    defer comdat_defs.deinit();

    for (module.comdats.items) |comdat| {
        const name = parseComdatRecordName(comdat) orelse return error.InvalidComdat;
        if (comdat_defs.contains(name)) return error.InvalidComdat;
        try comdat_defs.put(name, {});
    }

    for (module.globals.items) |global| {
        if (global_defs.contains(global.name)) return error.DuplicateDefinition;
        try global_defs.put(global.name, {});
        try verifyGlobalAddressAttrs(global.address_attrs);
        try verifyComdatReference(global.attrs, comdat_defs);
        switch (global.initializer) {
            .none => switch (global.linkage) {
                .external, .extern_weak => {},
                .default, .internal, .private, .weak, .weak_odr => return error.UnsupportedGlobalVariable,
            },
            .scalar => |value| switch (global.ty) {
                .int => switch (value) {
                    .int, .undef => {},
                    .named, .fp, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedGlobalVariable,
                },
                .ptr => switch (value) {
                    .undef, .null_value, .named => {},
                    .int, .fp, .zero_initializer, .vector, .constant_expr => return error.UnsupportedGlobalVariable,
                },
                .aggregate => switch (value) {
                    .undef, .zero_initializer => {},
                    .int, .fp, .named, .null_value, .vector, .constant_expr => return error.UnsupportedGlobalVariable,
                },
                .void, .float, .double, .metadata, .vector => return error.UnsupportedGlobalVariable,
            },
            .array => |array| {
                const array_ty = parseArrayType(global.ty) orelse return error.UnsupportedGlobalVariable;
                if (!array_ty.elem_ty.eql(array.elem_ty)) return error.UnsupportedGlobalVariable;
                if (array.values.items.len != array_ty.len) return error.UnsupportedGlobalVariable;
                for (array.values.items) |value| switch (value) {
                    .int, .undef, .null_value, .zero_initializer, .vector, .constant_expr => {},
                    .fp, .named => return error.UnsupportedGlobalVariable,
                };
            },
            .c_string => |text| {
                const array_ty = parseArrayType(global.ty) orelse return error.UnsupportedGlobalVariable;
                if (!array_ty.elem_ty.eql(.{ .int = 8 })) return error.UnsupportedGlobalVariable;
                if (!std.mem.startsWith(u8, text, "c\"") or !std.mem.endsWith(u8, text, "\"")) return error.UnsupportedGlobalVariable;
            },
            .@"opaque" => |text| {
                if (text.len == 0) return error.UnsupportedGlobalVariable;
                switch (global.ty) {
                    .aggregate => {},
                    .void, .int, .float, .double, .metadata, .ptr, .vector => return error.UnsupportedGlobalVariable,
                }
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
        try verifyDeclAbiAttrs(decl);
        try decl_defs.put(decl.name, {});
    }

    for (module.functions.items) |function| {
        if (global_defs.contains(function.name)) return error.DuplicateDefinition;
        if (findDeclaration(module, function.name)) |decl| try verifyDeclMatchesFunction(decl, function);
        try verifyFunctionAbiAttrs(function);
        try verifyComdatReference(function.attrs, comdat_defs);
        try global_defs.put(function.name, {});
    }

    for (module.aliases.items) |alias| {
        if (!hasGlobalValue(module, alias.target)) return error.UnknownGlobalAliasTarget;
    }
    for (module.globals.items) |global| {
        if (global.initializer == .scalar and global.ty == .ptr) {
            switch (global.initializer.scalar) {
                .named => |name| if (isGlobalValueName(name) and !hasGlobalValue(module, name[1..])) return error.UnknownGlobalAliasTarget,
                .int, .fp, .undef, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
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
                        try verifyBinaryFastMathFlags(binary);
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
                        if (fcmp.fp_flags.any()) {
                            switch (fcmp.operand_ty) {
                                .float, .double => {},
                                .void, .int, .metadata, .ptr, .aggregate, .vector => return error.InvalidInstructionFlag,
                            }
                        }
                        switch (fcmp.operand_ty) {
                            .float, .double => {},
                            .void, .int, .metadata, .ptr, .aggregate, .vector => return error.TypeMismatch,
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
                        try verifyLoadMemoryAttrs(load.attrs);
                    },
                    .store => |store| {
                        saw_non_phi = true;
                        if (instruction.result != null) return error.StoreHasResult;
                        try ctx.verifyValue(store.ty, store.value, block_index, instruction_index);
                        try ctx.verifyValue(.ptr, store.ptr, block_index, instruction_index);
                        try verifyStoreMemoryAttrs(store.attrs);
                    },
                    .atomicrmw => |atomicrmw| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(.ptr, atomicrmw.ptr, block_index, instruction_index);
                        try ctx.verifyValue(atomicrmw.ty, atomicrmw.value, block_index, instruction_index);
                        try verifySyncScope(atomicrmw.syncscope);
                        try verifyAtomicRmwOrdering(atomicrmw.ordering);
                        if (atomicrmw.@"align") |alignment| try verifyAlignment(alignment);
                    },
                    .cmpxchg => |cmpxchg| {
                        saw_non_phi = true;
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try ctx.verifyValue(.ptr, cmpxchg.ptr, block_index, instruction_index);
                        try ctx.verifyValue(cmpxchg.ty, cmpxchg.expected, block_index, instruction_index);
                        try ctx.verifyValue(cmpxchg.ty, cmpxchg.replacement, block_index, instruction_index);
                        try verifySyncScope(cmpxchg.syncscope);
                        try verifyCmpxchgOrderings(cmpxchg.success_ordering, cmpxchg.failure_ordering);
                        if (cmpxchg.@"align") |alignment| try verifyAlignment(alignment);
                    },
                    .fence => |fence| {
                        saw_non_phi = true;
                        if (instruction.result != null) return error.StoreHasResult;
                        try verifySyncScope(fence.syncscope);
                        try verifyFenceOrdering(fence.ordering);
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
                .@"switch" => |switch_term| {
                    switch (switch_term.cond_ty) {
                        .int => {},
                        else => return error.SwitchConditionTypeMismatch,
                    }
                    try ctx.verifyValue(switch_term.cond_ty, switch_term.cond, block_index, block.instructions.items.len);
                    try verifyBlockTarget(function, switch_term.default_target);
                    for (switch_term.cases.items) |case| {
                        if (!case.value_ty.eql(switch_term.cond_ty)) return error.SwitchCaseTypeMismatch;
                        switch (case.value) {
                            .int => {},
                            else => return error.InvalidSwitch,
                        }
                        try verifyBlockTarget(function, case.target);
                    }
                },
                .@"unreachable" => {},
            }
        }
    }
}

fn verifyMetadataGraph(module: core.Module) !void {
    var ids = std.AutoHashMap(u32, []const u8).init(module.allocator);
    defer ids.deinit();

    for (module.metadata.items) |line| {
        if (parseNumberedMetadata(line)) |record| {
            if (ids.contains(record.id)) return error.DuplicateMetadata;
            try ids.put(record.id, record.body);
        }
    }

    for (module.metadata.items) |line| {
        if (std.mem.startsWith(u8, line, "!llvm.dbg.cu")) {
            try verifyDebugCuRoot(line, ids);
        }
        const body = if (parseNumberedMetadata(line)) |record| record.body else metadataBody(line) orelse continue;
        try verifyMetadataReferences(body, ids);
        try verifyKnownMetadataNode(body, ids);
    }

    for (module.functions.items) |function| {
        if (function.attrs) |attrs| try verifyMetadataAttachmentRefs(attrs, ids);
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.metadata) |metadata| try verifyMetadataAttachmentRefs(metadata, ids);
            }
            if (block.terminator) |terminator| switch (terminator) {
                .br => |br| if (br.metadata) |metadata| try verifyMetadataAttachmentRefs(metadata, ids),
                .condbr => |condbr| if (condbr.metadata) |metadata| try verifyMetadataAttachmentRefs(metadata, ids),
                .@"switch" => |switch_term| if (switch_term.metadata) |metadata| try verifyMetadataAttachmentRefs(metadata, ids),
                .ret, .@"unreachable" => {},
            };
        }
    }
}

const NumberedMetadata = struct {
    id: u32,
    body: []const u8,
};

fn parseNumberedMetadata(line: []const u8) ?NumberedMetadata {
    const trimmed = std.mem.trim(u8, line, " \t");
    if (trimmed.len < 4 or trimmed[0] != '!') return null;
    var index: usize = 1;
    while (index < trimmed.len and std.ascii.isDigit(trimmed[index])) : (index += 1) {}
    if (index == 1) return null;
    const id = std.fmt.parseInt(u32, trimmed[1..index], 10) catch return null;
    var rest = std.mem.trim(u8, trimmed[index..], " \t");
    if (!std.mem.startsWith(u8, rest, "=")) return null;
    rest = std.mem.trim(u8, rest[1..], " \t");
    return .{ .id = id, .body = rest };
}

fn metadataBody(line: []const u8) ?[]const u8 {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return null;
    return std.mem.trim(u8, line[eq + 1 ..], " \t");
}

fn verifyDebugCuRoot(line: []const u8, ids: std.AutoHashMap(u32, []const u8)) !void {
    const body = metadataBody(line) orelse return error.InvalidDebugMetadata;
    if (!std.mem.startsWith(u8, body, "!{") or !std.mem.endsWith(u8, body, "}")) return error.InvalidDebugMetadata;
    var found = false;
    var scanner = MetadataRefScanner.init(body);
    while (scanner.next()) |id| {
        found = true;
        const metadata_target = ids.get(id) orelse return error.UnknownMetadata;
        if (!knownNodeBody(metadata_target, "!DICompileUnit(")) return error.InvalidDebugMetadata;
    }
    if (!found) return error.InvalidDebugMetadata;
}

fn verifyMetadataReferences(body: []const u8, ids: std.AutoHashMap(u32, []const u8)) !void {
    var scanner = MetadataRefScanner.init(body);
    while (scanner.next()) |id| {
        if (!ids.contains(id)) return error.UnknownMetadata;
    }
}

fn verifyMetadataAttachmentRefs(text: []const u8, ids: std.AutoHashMap(u32, []const u8)) !void {
    var scanner = MetadataRefScanner.init(text);
    while (scanner.next()) |id| {
        if (!ids.contains(id)) return error.UnknownMetadata;
    }
}

fn verifyKnownMetadataNode(body: []const u8, ids: std.AutoHashMap(u32, []const u8)) !void {
    if (knownNodeBody(body, "!DICompileUnit(")) {
        if (!hasMetadataField(body, "language") or !hasMetadataField(body, "file")) return error.InvalidDebugMetadata;
        try verifyFieldTargetKind(body, "file", ids, "!DIFile(");
    } else if (knownNodeBody(body, "!DIFile(")) {
        if (!hasMetadataField(body, "filename") or !hasMetadataField(body, "directory")) return error.InvalidDebugMetadata;
    } else if (knownNodeBody(body, "!DISubprogram(")) {
        if (!hasMetadataField(body, "name") or !hasMetadataField(body, "file") or !hasMetadataField(body, "type")) return error.InvalidDebugMetadata;
        try verifyFieldTargetKind(body, "file", ids, "!DIFile(");
        try verifyFieldTargetKind(body, "type", ids, "!DISubroutineType(");
    } else if (knownNodeBody(body, "!DILexicalBlock(")) {
        if (!hasMetadataField(body, "scope") or !hasMetadataField(body, "file")) return error.InvalidDebugMetadata;
        try verifyFieldTargetAnyDebugNode(body, "scope", ids);
        try verifyFieldTargetKind(body, "file", ids, "!DIFile(");
    } else if (knownNodeBody(body, "!DILocalVariable(")) {
        if (!hasMetadataField(body, "name") or !hasMetadataField(body, "scope") or !hasMetadataField(body, "type")) return error.InvalidDebugMetadata;
        try verifyFieldTargetAnyDebugNode(body, "scope", ids);
        try verifyFieldTargetAnyDebugNode(body, "type", ids);
    } else if (knownNodeBody(body, "!DIExpression(")) {
        if (!std.mem.endsWith(u8, std.mem.trim(u8, body, " \t"), ")")) return error.InvalidDebugMetadata;
    } else if (knownNodeBody(body, "!DILocation(")) {
        if (!hasMetadataField(body, "line") or !hasMetadataField(body, "column") or !hasMetadataField(body, "scope")) return error.InvalidDebugMetadata;
        try verifyFieldTargetAnyDebugNode(body, "scope", ids);
    } else if (knownNodeBody(body, "!DISubroutineType(")) {
        if (!hasMetadataField(body, "types")) return error.InvalidDebugMetadata;
    } else if (knownNodeBody(body, "!DIBasicType(")) {
        if (!hasMetadataField(body, "name") or !hasMetadataField(body, "size")) return error.InvalidDebugMetadata;
    } else if (knownNodeBody(body, "!DIDerivedType(")) {
        if (!hasMetadataField(body, "tag")) return error.InvalidDebugMetadata;
        if (metadataFieldRef(body, "baseType")) |id| try verifyMetadataIdExists(id, ids);
    }
}

fn knownNodeBody(body: []const u8, prefix: []const u8) bool {
    var trimmed = std.mem.trim(u8, body, " \t");
    if (std.mem.startsWith(u8, trimmed, "distinct ")) trimmed = std.mem.trim(u8, trimmed["distinct ".len..], " \t");
    return std.mem.startsWith(u8, trimmed, prefix);
}

fn hasMetadataField(body: []const u8, field: []const u8) bool {
    return metadataFieldOffset(body, field) != null;
}

fn metadataFieldOffset(body: []const u8, field: []const u8) ?usize {
    if (field.len == 0) return null;
    var index: usize = 0;
    while (std.mem.indexOfPos(u8, body, index, field)) |pos| {
        const after = pos + field.len;
        if (after < body.len and body[after] == ':' and (pos == 0 or !isMetadataIdentByte(body[pos - 1]))) {
            return pos;
        }
        index = after;
    }
    return null;
}

fn isMetadataIdentByte(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-';
}

fn metadataFieldRef(body: []const u8, field: []const u8) ?u32 {
    const pos = metadataFieldOffset(body, field) orelse return null;
    var rest = std.mem.trim(u8, body[pos + field.len + 1 ..], " \t");
    if (rest.len == 0 or rest[0] != '!') return null;
    rest = rest[1..];
    var end: usize = 0;
    while (end < rest.len and std.ascii.isDigit(rest[end])) : (end += 1) {}
    if (end == 0) return null;
    return std.fmt.parseInt(u32, rest[0..end], 10) catch null;
}

fn verifyFieldTargetKind(body: []const u8, field: []const u8, ids: std.AutoHashMap(u32, []const u8), prefix: []const u8) !void {
    const id = metadataFieldRef(body, field) orelse return error.InvalidDebugMetadata;
    const metadata_target = ids.get(id) orelse return error.UnknownMetadata;
    if (!knownNodeBody(metadata_target, prefix)) return error.InvalidDebugMetadata;
}

fn verifyFieldTargetAnyDebugNode(body: []const u8, field: []const u8, ids: std.AutoHashMap(u32, []const u8)) !void {
    const id = metadataFieldRef(body, field) orelse return error.InvalidDebugMetadata;
    try verifyMetadataIdExists(id, ids);
}

fn verifyMetadataIdExists(id: u32, ids: std.AutoHashMap(u32, []const u8)) !void {
    if (!ids.contains(id)) return error.UnknownMetadata;
}

const MetadataRefScanner = struct {
    text: []const u8,
    index: usize = 0,

    fn init(text: []const u8) MetadataRefScanner {
        return .{ .text = text };
    }

    fn next(scanner: *MetadataRefScanner) ?u32 {
        while (scanner.index < scanner.text.len) : (scanner.index += 1) {
            if (scanner.text[scanner.index] != '!') continue;
            const digit_start = scanner.index + 1;
            if (digit_start >= scanner.text.len or !std.ascii.isDigit(scanner.text[digit_start])) continue;
            var digit_end = digit_start;
            while (digit_end < scanner.text.len and std.ascii.isDigit(scanner.text[digit_end])) : (digit_end += 1) {}
            scanner.index = digit_end;
            return std.fmt.parseInt(u32, scanner.text[digit_start..digit_end], 10) catch continue;
        }
        return null;
    }
};

fn verifyDeclMatchesFunction(decl: core.FunctionDecl, function: core.Function) !void {
    if (!decl.ret_ty.eql(function.ret_ty)) return error.CallSignatureMismatch;
    if (!callingConventionsMatch(decl.calling_conv, function.calling_conv)) return error.CallSignatureMismatch;
    if (decl.params.items.len != function.params.items.len) return error.CallSignatureMismatch;
    for (decl.params.items, 0..) |param, index| {
        if (!param.ty.eql(function.params.items[index].ty)) return error.CallSignatureMismatch;
    }
}

fn verifyDeclAbiAttrs(decl: core.FunctionDecl) !void {
    for (decl.params.items) |param| try verifyParamAbiAttrs(param.ty, param.attrs);
}

fn verifyFunctionAbiAttrs(function: core.Function) !void {
    for (function.params.items) |param| try verifyParamAbiAttrs(param.ty, param.attrs);
}

fn verifyParamAbiAttrs(ty: core.Type, attrs: ?[]const u8) !void {
    try verifyParameterAttrs(ty, attrs);
}

fn hasAbiAttr(attrs: []const u8, name: []const u8) bool {
    var rest = std.mem.trim(u8, attrs, " \t");
    while (rest.len != 0) {
        const token = firstAttrToken(rest);
        if (std.mem.eql(u8, token, name)) return true;
        if (std.mem.startsWith(u8, token, name) and token.len > name.len and token[name.len] == '(') return true;
        rest = std.mem.trim(u8, rest[token.len..], " \t");
    }
    return false;
}

fn firstAttrToken(attrs: []const u8) []const u8 {
    var paren_depth: usize = 0;
    for (attrs, 0..) |byte, index| {
        switch (byte) {
            '(' => paren_depth += 1,
            ')' => if (paren_depth > 0) {
                paren_depth -= 1;
            },
            ' ', '\t' => if (paren_depth == 0) return attrs[0..index],
            else => {},
        }
    }
    return attrs;
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
        for (call.args.items) |arg| try verifyCallArg(ctx, arg, block_index, instruction_index);
        return;
    }

    if (call.callee_value) |callee_value| {
        try ctx.verifyValue(.ptr, callee_value, block_index, instruction_index);
        for (call.args.items) |arg| try verifyCallArg(ctx, arg, block_index, instruction_index);
        return;
    }

    if (call.isDebugVariableLocation()) {
        try verifyDebugVariableLocationCall(module, call);
        return;
    }

    if (findDeclaration(module, call.callee)) |decl| {
        if (!call.ret_ty.eql(decl.ret_ty)) return error.CallSignatureMismatch;
        if (!callingConventionsMatch(call.calling_conv, decl.calling_conv)) return error.CallSignatureMismatch;
        if (decl.is_varargs) {
            if (call.args.items.len < decl.params.items.len) return error.CallSignatureMismatch;
        } else if (call.args.items.len != decl.params.items.len) return error.CallSignatureMismatch;
        for (call.args.items[0..decl.params.items.len], 0..) |arg, index| {
            if (!arg.ty.eql(decl.params.items[index].ty)) return error.CallSignatureMismatch;
            try verifyCallArg(ctx, arg, block_index, instruction_index);
        }
        for (call.args.items[decl.params.items.len..]) |arg| try verifyCallArg(ctx, arg, block_index, instruction_index);
        return;
    }

    if (findFunction(module, call.callee)) |function| {
        if (!call.ret_ty.eql(function.ret_ty)) return error.CallSignatureMismatch;
        if (!callingConventionsMatch(call.calling_conv, function.calling_conv)) return error.CallSignatureMismatch;
        if (call.args.items.len != function.params.items.len) return error.CallSignatureMismatch;
        for (call.args.items, 0..) |arg, index| {
            if (!arg.ty.eql(function.params.items[index].ty)) return error.CallSignatureMismatch;
            try verifyCallArg(ctx, arg, block_index, instruction_index);
        }
        return;
    }

    return error.UnknownFunction;
}

fn verifyCallArg(ctx: VerifyContext, arg: core.CallArg, block_index: usize, instruction_index: usize) !void {
    try verifyCallArgAttrs(arg.ty, arg.attrs);
    try ctx.verifyValue(arg.ty, arg.value, block_index, instruction_index);
}

fn verifyCallArgAttrs(ty: core.Type, attrs: ?[]const u8) !void {
    try verifyParameterAttrs(ty, attrs);
}

fn verifyParameterAttrs(ty: core.Type, attrs: ?[]const u8) !void {
    var rest = std.mem.trim(u8, attrs orelse return, " \t");
    if (rest.len == 0) return error.UnsupportedCallAttribute;

    var saw_nonnull = false;
    var saw_noundef = false;
    var saw_noalias = false;
    var saw_readonly = false;
    var saw_writeonly = false;
    var saw_readnone = false;
    var saw_captures = false;
    var saw_align = false;
    var saw_dereferenceable = false;
    var saw_immarg = false;
    var saw_range = false;
    var saw_sret = false;
    var saw_byval = false;

    while (rest.len != 0) {
        const token = firstAttrToken(rest);
        if (token.len == 0) return error.UnsupportedCallAttribute;
        rest = std.mem.trim(u8, rest[token.len..], " \t");

        if (std.mem.eql(u8, token, "nonnull")) {
            if (saw_nonnull) return error.UnsupportedCallAttribute;
            saw_nonnull = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            continue;
        }
        if (std.mem.eql(u8, token, "noundef")) {
            if (saw_noundef) return error.UnsupportedCallAttribute;
            saw_noundef = true;
            continue;
        }
        if (std.mem.eql(u8, token, "noalias")) {
            if (saw_noalias) return error.UnsupportedCallAttribute;
            saw_noalias = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            continue;
        }
        if (std.mem.eql(u8, token, "readonly")) {
            if (saw_readonly) return error.UnsupportedCallAttribute;
            saw_readonly = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            continue;
        }
        if (std.mem.eql(u8, token, "writeonly")) {
            if (saw_writeonly) return error.UnsupportedCallAttribute;
            saw_writeonly = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            continue;
        }
        if (std.mem.eql(u8, token, "readnone")) {
            if (saw_readnone) return error.UnsupportedCallAttribute;
            saw_readnone = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            continue;
        }
        if (std.mem.eql(u8, token, "returned")) {
            continue;
        }
        if (std.mem.eql(u8, token, "zeroext") or std.mem.eql(u8, token, "signext")) {
            switch (ty) {
                .int => {},
                else => return error.UnsupportedCallAttribute,
            }
            continue;
        }
        if (std.mem.eql(u8, token, "captures(none)") or std.mem.eql(u8, token, "captures(address_is_null)")) {
            if (saw_captures) return error.UnsupportedCallAttribute;
            saw_captures = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            continue;
        }
        if (std.mem.eql(u8, token, "align")) {
            if (saw_align) return error.UnsupportedCallAttribute;
            saw_align = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            const align_token = firstAttrToken(rest);
            if (align_token.len == 0) return error.InvalidAlignment;
            rest = std.mem.trim(u8, rest[align_token.len..], " \t");
            const alignment = try std.fmt.parseInt(u64, align_token, 10);
            try verifyAlignment(alignment);
            continue;
        }
        if (dereferenceablePayload(token)) |payload| {
            if (saw_dereferenceable) return error.UnsupportedCallAttribute;
            saw_dereferenceable = true;
            if (ty != .ptr) return error.UnsupportedCallAttribute;
            if (payload.len == 0) return error.UnsupportedCallAttribute;
            _ = try std.fmt.parseInt(u64, payload, 10);
            continue;
        }
        if (abiPayload(token, "sret")) |payload| {
            if (saw_sret) return error.UnsupportedCallAttribute;
            saw_sret = true;
            if (ty != .ptr) return error.UnsupportedAbiType;
            if (payload.len == 0) return error.UnsupportedCallAttribute;
            continue;
        }
        if (abiPayload(token, "byval")) |payload| {
            if (saw_byval) return error.UnsupportedCallAttribute;
            saw_byval = true;
            if (ty != .ptr) return error.UnsupportedAbiType;
            if (payload.len == 0) return error.UnsupportedCallAttribute;
            continue;
        }
        if (abiPayload(token, "initializes")) |payload| {
            if (ty != .ptr or payload.len == 0) return error.UnsupportedCallAttribute;
            continue;
        }
        if (std.mem.eql(u8, token, "immarg")) {
            if (saw_immarg) return error.UnsupportedCallAttribute;
            saw_immarg = true;
            switch (ty) {
                .int => {},
                else => return error.UnsupportedCallAttribute,
            }
            continue;
        }
        if (rangePayload(token)) |payload| {
            if (saw_range) return error.UnsupportedCallAttribute;
            saw_range = true;
            try verifyRangeAttrPayload(ty, payload);
            continue;
        }
        return error.UnsupportedCallAttribute;
    }
}

fn dereferenceablePayload(token: []const u8) ?[]const u8 {
    const prefix = "dereferenceable(";
    if (!std.mem.startsWith(u8, token, prefix)) return null;
    if (!std.mem.endsWith(u8, token, ")")) return null;
    return token[prefix.len .. token.len - 1];
}

fn abiPayload(token: []const u8, name: []const u8) ?[]const u8 {
    if (!std.mem.startsWith(u8, token, name)) return null;
    if (token.len <= name.len or token[name.len] != '(' or !std.mem.endsWith(u8, token, ")")) return null;
    return token[name.len + 1 .. token.len - 1];
}

fn rangePayload(token: []const u8) ?[]const u8 {
    const prefix = "range(";
    if (!std.mem.startsWith(u8, token, prefix) or !std.mem.endsWith(u8, token, ")")) return null;
    return token[prefix.len .. token.len - 1];
}

fn verifyRangeAttrPayload(ty: core.Type, payload: []const u8) !void {
    switch (ty) {
        .int => {},
        else => return error.UnsupportedCallAttribute,
    }
    var parts = std.mem.tokenizeAny(u8, payload, " \t,");
    const range_ty = parseType(parts.next() orelse return error.UnsupportedCallAttribute) catch return error.UnsupportedCallAttribute;
    if (!range_ty.eql(ty)) return error.UnsupportedCallAttribute;
    _ = try std.fmt.parseInt(i128, parts.next() orelse return error.UnsupportedCallAttribute, 10);
    _ = try std.fmt.parseInt(i128, parts.next() orelse return error.UnsupportedCallAttribute, 10);
    if (parts.next() != null) return error.UnsupportedCallAttribute;
}

fn verifyNamedTypes(module: core.Module) !void {
    var defs = std.StringHashMap(void).init(module.allocator);
    defer defs.deinit();

    for (module.named_types.items) |named_type| {
        if (named_type.name.len == 0) return error.InvalidNamedTypeDefinition;
        if (named_type.body.len == 0) return error.InvalidNamedTypeDefinition;
        if (defs.contains(named_type.name)) return error.DuplicateNamedTypeDefinition;
        try defs.put(named_type.name, {});
    }
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

fn verifyDebugVariableLocationCall(module: core.Module, call: core.CallInst) !void {
    if (call.raw_args == null) return error.UnsupportedDebugIntrinsic;
    if (call.args.items.len != 0) return error.UnsupportedDebugIntrinsic;
    if (call.ret_ty != .void) return error.UnsupportedDebugIntrinsic;
    const decl = findDeclaration(module, call.callee) orelse return error.UnknownFunction;
    if (decl.ret_ty != .void) return error.CallSignatureMismatch;
    if (decl.params.items.len != 3) return error.CallSignatureMismatch;
    for (decl.params.items) |param| {
        if (param.ty != .metadata) return error.CallSignatureMismatch;
    }
}

fn verifyConstantExprValue(ty: core.Type, text: []const u8) anyerror!void {
    if (std.mem.startsWith(u8, text, "sub (")) {
        switch (ty) {
            .int => {},
            else => return error.TypeMismatch,
        }
        const body = text["sub (".len .. text.len - 1];
        const comma = findConstantExprTopLevelComma(body) orelse return error.UnsupportedConstantExpr;
        const lhs = try parseConstantExprTypedValue(std.mem.trim(u8, body[0..comma], " \t"));
        const rhs = try parseConstantExprTypedValue(std.mem.trim(u8, body[comma + 1 ..], " \t"));
        if (!lhs.ty.eql(ty) or !rhs.ty.eql(ty)) return error.TypeMismatch;
        try verifyConstantExprOperand(lhs.ty, lhs.value_text);
        try verifyConstantExprOperand(rhs.ty, rhs.value_text);
        return;
    }
    if (std.mem.startsWith(u8, text, "inttoptr (")) {
        if (ty != .ptr) return error.TypeMismatch;
        const body = text["inttoptr (".len .. text.len - 1];
        const cast = try parseConstantExprCastBody(body);
        switch (cast.from_ty) {
            .int => {},
            else => return error.InvalidCast,
        }
        if (cast.to_ty != .ptr) return error.InvalidCast;
        return;
    }
    if (std.mem.startsWith(u8, text, "ptrtoint (")) {
        switch (ty) {
            .int => {},
            else => return error.TypeMismatch,
        }
        const body = text["ptrtoint (".len .. text.len - 1];
        const cast = try parseConstantExprCastBody(body);
        if (cast.from_ty != .ptr) return error.InvalidCast;
        if (!cast.to_ty.eql(ty)) return error.InvalidCast;
        return;
    }
    if (std.mem.startsWith(u8, text, "getelementptr ")) {
        if (ty != .ptr) return error.TypeMismatch;
        return;
    }
    return error.UnsupportedConstantExpr;
}

fn verifyConstantExprOperand(ty: core.Type, value_text: []const u8) anyerror!void {
    if (std.mem.startsWith(u8, value_text, "inttoptr (") or
        std.mem.startsWith(u8, value_text, "ptrtoint (") or
        std.mem.startsWith(u8, value_text, "sub (") or
        std.mem.startsWith(u8, value_text, "getelementptr "))
    {
        try verifyConstantExprValue(ty, value_text);
        return;
    }
    if (std.mem.eql(u8, value_text, "null")) return if (ty == .ptr) {} else error.TypeMismatch;
    if (std.mem.startsWith(u8, value_text, "@")) return if (ty == .ptr) {} else error.TypeMismatch;
    _ = std.fmt.parseInt(i128, value_text, 10) catch return error.UnsupportedConstantExpr;
}

const ConstantExprCastBody = struct {
    from_ty: core.Type,
    to_ty: core.Type,
};

const ConstantExprTypedValue = struct {
    ty: core.Type,
    value_text: []const u8,
};

fn parseConstantExprTypedValue(text: []const u8) !ConstantExprTypedValue {
    const ty_end = std.mem.indexOfAny(u8, text, " \t") orelse return error.UnsupportedConstantExpr;
    return .{
        .ty = try parseType(text[0..ty_end]),
        .value_text = std.mem.trim(u8, text[ty_end..], " \t"),
    };
}

fn parseConstantExprCastBody(body: []const u8) !ConstantExprCastBody {
    const to_index = std.mem.lastIndexOf(u8, body, " to ") orelse return error.InvalidCast;
    const source_text = std.mem.trim(u8, body[0..to_index], " \t");
    const to_ty = try parseType(std.mem.trim(u8, body[to_index + " to ".len ..], " \t"));
    const from_ty_end = std.mem.indexOfAny(u8, source_text, " \t") orelse return error.InvalidCast;
    return .{
        .from_ty = try parseType(source_text[0..from_ty_end]),
        .to_ty = to_ty,
    };
}

fn findConstantExprTopLevelComma(text: []const u8) ?usize {
    var paren_depth: usize = 0;
    for (text, 0..) |byte, index| {
        switch (byte) {
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth == 0) return null;
                paren_depth -= 1;
            },
            ',' => if (paren_depth == 0) return index,
            else => {},
        }
    }
    return null;
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
        .void, .int, .float, .double, .metadata, .ptr, .vector => return null,
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
    if (std.mem.eql(u8, trimmed, "metadata")) return .metadata;
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
        .fp, .null_value, .zero_initializer, .vector, .constant_expr => return error.TypeMismatch,
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
        .named, .int, .fp, .null_value, .constant_expr => return error.TypeMismatch,
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
        if (!std.mem.eql(u8, value_text, "undef") and !std.mem.eql(u8, value_text, "poison")) {
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
    if (std.mem.eql(u8, text, "undef") or std.mem.eql(u8, text, "poison") or std.mem.eql(u8, text, "zeroinitializer")) return;
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
            .fadd, .fsub, .fmul, .fdiv, .frem, .@"and", .@"or", .xor, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    if (binary.flags.exact) {
        switch (binary.op) {
            .udiv, .sdiv, .lshr, .ashr => {},
            .fadd, .fsub, .fmul, .fdiv, .frem, .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    if (binary.flags.disjoint) {
        switch (binary.op) {
            .@"or" => {},
            .fadd, .fsub, .fmul, .fdiv, .frem, .add, .sub, .mul, .@"and", .xor, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    switch (binary.op) {
        .fadd, .fsub, .fmul, .fdiv, .frem => switch (binary.ty) {
            .float, .double => {},
            .vector => return error.UnsupportedType,
            .void, .int, .metadata, .ptr, .aggregate => return error.TypeMismatch,
        },
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => switch (binary.ty) {
            .int => {},
            .vector => |vector| switch (vector.elem_ty) {
                .int => {},
                .float, .double, .ptr => return error.TypeMismatch,
            },
            .void, .float, .double, .metadata, .ptr, .aggregate => return error.TypeMismatch,
        },
    }
}

fn verifyBinaryFastMathFlags(binary: core.BinaryInst) !void {
    if (!binary.fp_flags.any()) return;
    switch (binary.op) {
        .fadd, .fsub, .fmul, .fdiv, .frem => switch (binary.ty) {
            .float, .double => {},
            .void, .int, .metadata, .ptr, .aggregate, .vector => return error.InvalidInstructionFlag,
        },
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
    }
}

fn verifyCast(cast: core.CastInst) !void {
    try verifyCastFlags(cast);
    switch (cast.op) {
        .ptrtoint => {
            if (cast.from_ty != .ptr) return error.InvalidCast;
            switch (cast.to_ty) {
                .int => {},
                else => return error.InvalidCast,
            }
            return;
        },
        .inttoptr => {
            switch (cast.from_ty) {
                .int => {},
                else => return error.InvalidCast,
            }
            if (cast.to_ty != .ptr) return error.InvalidCast;
            return;
        },
        .trunc, .zext, .sext => {},
    }

    const from_bits = switch (cast.from_ty) {
        .int => |bits| bits,
        .void, .float, .double, .metadata, .ptr, .aggregate, .vector => return error.TypeMismatch,
    };
    const to_bits = switch (cast.to_ty) {
        .int => |bits| bits,
        .void, .float, .double, .metadata, .ptr, .aggregate, .vector => return error.TypeMismatch,
    };
    switch (cast.op) {
        .trunc => if (from_bits <= to_bits) return error.InvalidCast,
        .zext, .sext => if (from_bits >= to_bits) return error.InvalidCast,
        .ptrtoint, .inttoptr => unreachable,
    }
}

fn verifyCastFlags(cast: core.CastInst) !void {
    switch (cast.op) {
        .trunc => {
            if (cast.flags.nneg) return error.InvalidInstructionFlag;
        },
        .zext => {
            if (cast.flags.nsw or cast.flags.nuw) return error.InvalidInstructionFlag;
        },
        .sext, .ptrtoint, .inttoptr => {
            if (cast.flags.any()) return error.InvalidInstructionFlag;
        },
    }
}

fn verifyMemoryAttrs(attrs: core.MemoryAttrs) !void {
    if (attrs.@"align") |alignment| {
        try verifyAlignment(alignment);
    }
    try verifySyncScope(attrs.syncscope);
    if (attrs.syncscope != null and attrs.atomic_ordering == null) return error.InvalidAtomicMemory;
}

fn verifyGlobalAddressAttrs(address_attrs: ?[]const u8) !void {
    var saw_thread_local = false;
    var saw_unnamed_addr = false;
    var saw_local_unnamed_addr = false;
    var parts = std.mem.tokenizeAny(u8, address_attrs orelse "", " \t");
    while (parts.next()) |token| {
        if (std.mem.eql(u8, token, "thread_local") or isKnownTlsModelToken(token)) {
            if (saw_thread_local) return error.UnsupportedGlobalVariable;
            saw_thread_local = true;
            continue;
        }
        if (std.mem.eql(u8, token, "unnamed_addr")) {
            if (saw_unnamed_addr or saw_local_unnamed_addr) return error.UnsupportedGlobalVariable;
            saw_unnamed_addr = true;
            continue;
        }
        if (std.mem.eql(u8, token, "local_unnamed_addr")) {
            if (saw_unnamed_addr or saw_local_unnamed_addr) return error.UnsupportedGlobalVariable;
            saw_local_unnamed_addr = true;
            continue;
        }
        return error.UnsupportedGlobalVariable;
    }
}

fn parseComdatRecordName(comdat: []const u8) ?[]const u8 {
    var parts = std.mem.tokenizeAny(u8, comdat, " \t");
    const name = parts.next() orelse return null;
    if (!std.mem.startsWith(u8, name, "$") or name.len == 1) return null;
    if (!std.mem.eql(u8, parts.next() orelse return null, "=")) return null;
    if (!std.mem.eql(u8, parts.next() orelse return null, "comdat")) return null;
    return name;
}

fn verifyComdatReference(attrs: ?[]const u8, comdat_defs: std.StringHashMap(void)) !void {
    const text = attrs orelse return;
    var rest = text;
    while (std.mem.indexOf(u8, rest, "comdat(")) |relative_start| {
        const start = relative_start + "comdat(".len;
        const after_start = rest[start..];
        const close = std.mem.indexOfScalar(u8, after_start, ')') orelse return error.InvalidComdat;
        const name = after_start[0..close];
        if (!std.mem.startsWith(u8, name, "$") or !comdat_defs.contains(name)) return error.InvalidComdat;
        rest = after_start[close + 1 ..];
    }
}

fn isKnownTlsModelToken(token: []const u8) bool {
    inline for (.{ "thread_local(localexec)", "thread_local(initialexec)", "thread_local(localdynamic)", "thread_local(generaldynamic)" }) |candidate| {
        if (std.mem.eql(u8, token, candidate)) return true;
    }
    return false;
}

fn verifyLoadMemoryAttrs(attrs: core.MemoryAttrs) !void {
    try verifyMemoryAttrs(attrs);
    if (attrs.atomic_ordering) |ordering| try verifyAtomicLoadOrdering(ordering);
}

fn verifyStoreMemoryAttrs(attrs: core.MemoryAttrs) !void {
    try verifyMemoryAttrs(attrs);
    if (attrs.atomic_ordering) |ordering| try verifyAtomicStoreOrdering(ordering);
}

fn verifyAlignment(alignment: u64) !void {
    if (alignment == 0) return error.InvalidAlignment;
    if (!std.math.isPowerOfTwo(alignment)) return error.InvalidAlignment;
}

fn verifyAtomicOrdering(ordering: []const u8) !void {
    if (!isKnownAtomicOrdering(ordering)) return error.InvalidAtomicMemory;
}

fn verifyAtomicLoadOrdering(ordering: []const u8) !void {
    try verifyAtomicOrdering(ordering);
    if (std.mem.eql(u8, ordering, "release") or std.mem.eql(u8, ordering, "acq_rel")) return error.InvalidAtomicMemory;
}

fn verifyAtomicStoreOrdering(ordering: []const u8) !void {
    try verifyAtomicOrdering(ordering);
    if (std.mem.eql(u8, ordering, "acquire") or std.mem.eql(u8, ordering, "acq_rel")) return error.InvalidAtomicMemory;
}

fn verifyAtomicRmwOrdering(ordering: []const u8) !void {
    try verifyAtomicOrdering(ordering);
    if (std.mem.eql(u8, ordering, "unordered")) return error.InvalidAtomicMemory;
}

fn verifyFenceOrdering(ordering: []const u8) !void {
    try verifyAtomicOrdering(ordering);
    if (std.mem.eql(u8, ordering, "unordered") or std.mem.eql(u8, ordering, "monotonic")) return error.InvalidAtomicMemory;
}

fn verifyCmpxchgOrderings(success: []const u8, failure: []const u8) !void {
    try verifyAtomicRmwOrdering(success);
    try verifyAtomicOrdering(failure);
    if (std.mem.eql(u8, failure, "release") or std.mem.eql(u8, failure, "acq_rel")) return error.InvalidAtomicMemory;
    if (atomicOrderingRank(failure) > atomicOrderingRank(success)) return error.InvalidAtomicMemory;
}

fn atomicOrderingRank(ordering: []const u8) u8 {
    if (std.mem.eql(u8, ordering, "unordered")) return 0;
    if (std.mem.eql(u8, ordering, "monotonic")) return 1;
    if (std.mem.eql(u8, ordering, "acquire") or std.mem.eql(u8, ordering, "release")) return 2;
    if (std.mem.eql(u8, ordering, "acq_rel")) return 3;
    if (std.mem.eql(u8, ordering, "seq_cst")) return 4;
    return 255;
}

fn verifySyncScope(syncscope: ?[]const u8) !void {
    const text = syncscope orelse return;
    if (!std.mem.startsWith(u8, text, "syncscope(\"") or !std.mem.endsWith(u8, text, "\")")) return error.InvalidAtomicMemory;
    if (text.len <= "syncscope(\"\")".len) return error.InvalidAtomicMemory;
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
