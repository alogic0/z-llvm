const std = @import("std");
const function_attrs = @import("../analysis/function_attrs.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "always-inline",
    .category = .ipo,
    .target_status = "LLVM-shaped subset for direct internal single-block calls",
    .upstream_owner = "llvm/lib/Transforms/IPO/AlwaysInliner.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    var function_index: usize = 0;
    while (function_index < module.functions.items.len) : (function_index += 1) {
        changed = try inlineInFunction(module, function_index) or changed;
    }
    changed = removeDeadAlwaysInlineFunctions(module) or changed;
    return if (changed) .changed else .unchanged;
}

const CallSite = struct {
    block_index: usize,
    instruction_index: usize,
    callee_index: usize,
};

fn inlineInFunction(module: *ir.Module, caller_index: usize) !bool {
    var changed = false;
    while (findInlineableCall(module.*, caller_index)) |site| {
        try inlineCall(module, caller_index, site);
        changed = true;
    }
    return changed;
}

fn findInlineableCall(module: ir.Module, caller_index: usize) ?CallSite {
    const caller = module.functions.items[caller_index];
    for (caller.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items, 0..) |instruction, instruction_index| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            const callee_index = inlineableCalleeIndex(module, caller.name, call) orelse continue;
            return .{
                .block_index = block_index,
                .instruction_index = instruction_index,
                .callee_index = callee_index,
            };
        }
    }
    return null;
}

fn inlineableCalleeIndex(module: ir.Module, caller_name: []const u8, call: ir.CallInst) ?usize {
    if (call.inline_asm != null or call.callee_value != null) return null;
    if (call.operand_bundle != null) return null;
    if (hasAttribute(module, call.attrs, "noinline")) return null;

    for (module.functions.items, 0..) |function, index| {
        if (!std.mem.eql(u8, function.name, call.callee)) continue;
        if (std.mem.eql(u8, caller_name, function.name)) return null;
        if (!isLocalLinkage(function.linkage)) return null;
        if (function.params.items.len != call.args.items.len) return null;
        if (function.calling_conv != null or call.calling_conv != null) {
            if (function.calling_conv == null or call.calling_conv == null) return null;
            if (!std.mem.eql(u8, function.calling_conv.?, call.calling_conv.?)) return null;
        }
        if (!call.ret_ty.eql(function.ret_ty)) return null;
        const attrs = function_attrs.resolvedFunctionAttributes(module, function);
        if (!attrs.alwaysinline or attrs.@"noinline") return null;
        if (!isSupportedCalleeBody(function)) return null;
        return index;
    }
    return null;
}

fn isLocalLinkage(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}

fn isSupportedCalleeBody(function: ir.Function) bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .call => return false,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .load, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => {},
        }
    }
    const terminator = block.terminator orelse return false;
    return terminator == .ret;
}

fn inlineCall(module: *ir.Module, caller_index: usize, site: CallSite) !void {
    var aliases = std.StringHashMap(ir.Value).init(module.allocator);
    defer aliases.deinit();

    const callee = module.functions.items[site.callee_index];
    const call_instruction = module.functions.items[caller_index].blocks.items[site.block_index].instructions.items[site.instruction_index];
    const call = call_instruction.kind.call;

    for (callee.params.items, 0..) |param, index| {
        try aliases.put(param.name, call.args.items[index].value);
    }

    var clones: std.ArrayList(ir.Instruction) = .empty;
    errdefer {
        for (clones.items) |*instruction| instruction.deinit(module.allocator);
        clones.deinit(module.allocator);
    }

    const callee_block = callee.blocks.items[0];
    for (callee_block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        var cloned = try cloneInstruction(module.allocator, instruction);
        var cloned_owned = true;
        errdefer if (cloned_owned) cloned.deinit(module.allocator);
        cloned.mapOperands(aliases);
        if (cloned.result) |result| {
            const mapped_result = try uniqueInlineResultName(module, module.functions.items[caller_index], result);
            cloned.result = mapped_result;
            try aliases.put(result, .{ .named = mapped_result });
        }
        try clones.append(module.allocator, cloned);
        cloned_owned = false;
    }

    if (call_instruction.result) |call_result| {
        const replacement = inlinedReturnValue(callee_block.terminator.?, aliases) orelse .undef;
        replaceValue(&module.functions.items[caller_index], call_result, replacement);
    }

    module.functions.items[caller_index].blocks.items[site.block_index].instructions.items[site.instruction_index].removed = true;
    var insert_at = site.instruction_index;
    for (clones.items) |cloned| {
        try module.functions.items[caller_index].blocks.items[site.block_index].instructions.insert(module.allocator, insert_at, cloned);
        insert_at += 1;
    }
    clones.deinit(module.allocator);
}

fn inlinedReturnValue(terminator: ir.Terminator, aliases: std.StringHashMap(ir.Value)) ?ir.Value {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| resolveValue(aliases, value) else null,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => null,
    };
}

fn cloneInstruction(allocator: std.mem.Allocator, instruction: ir.Instruction) !ir.Instruction {
    var cloned = instruction;
    cloned.removed = false;
    cloned.replacement = null;
    switch (instruction.kind) {
        .phi => |phi| {
            var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
            errdefer incoming.deinit(allocator);
            try incoming.appendSlice(allocator, phi.incoming.items);
            cloned.kind = .{ .phi = .{ .ty = phi.ty, .incoming = incoming } };
        },
        .gep => |gep| {
            var indices: std.ArrayList(ir.GepIndex) = .empty;
            errdefer indices.deinit(allocator);
            try indices.appendSlice(allocator, gep.indices.items);
            cloned.kind = .{ .gep = .{
                .source_ty = gep.source_ty,
                .ptr = gep.ptr,
                .ptr_addrspace = gep.ptr_addrspace,
                .indices = indices,
            } };
        },
        .call => |call| {
            var args: std.ArrayList(ir.CallArg) = .empty;
            errdefer args.deinit(allocator);
            try args.appendSlice(allocator, call.args.items);
            cloned.kind = .{ .call = .{
                .ret_ty = call.ret_ty,
                .callee = call.callee,
                .callee_value = call.callee_value,
                .callee_function_ty = call.callee_function_ty,
                .calling_conv = call.calling_conv,
                .ret_attrs = call.ret_attrs,
                .tail_kind = call.tail_kind,
                .inline_asm = call.inline_asm,
                .attrs = call.attrs,
                .operand_bundle = call.operand_bundle,
                .raw_args = call.raw_args,
                .args = args,
            } };
        },
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => {},
    }
    return cloned;
}

fn uniqueInlineResultName(module: *ir.Module, caller: ir.Function, base: []const u8) ![]const u8 {
    var suffix: usize = 0;
    while (true) : (suffix += 1) {
        const candidate = if (suffix == 0)
            try std.fmt.allocPrint(module.allocator, "{s}.i", .{base})
        else
            try std.fmt.allocPrint(module.allocator, "{s}.i{}", .{ base, suffix });
        errdefer module.allocator.free(candidate);
        if (!hasResultName(caller, candidate)) return try module.ownString(candidate);
        module.allocator.free(candidate);
    }
}

fn hasResultName(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return true;
    }
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, name)) return true;
            }
        }
    }
    return false;
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
        if (block.terminator) |*terminator| replaceTerminatorValue(terminator, name, replacement);
    }
}

fn replaceTerminatorValue(terminator: *ir.Terminator, name: []const u8, replacement: ir.Value) void {
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

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .named => |name| aliases.get(name) orelse value,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
    };
}

fn removeDeadAlwaysInlineFunctions(module: *ir.Module) bool {
    var changed = false;
    var index = module.functions.items.len;
    while (index > 0) {
        index -= 1;
        const function = module.functions.items[index];
        if (!isLocalLinkage(function.linkage)) continue;
        if (!function_attrs.resolvedFunctionAttributes(module.*, function).alwaysinline) continue;
        if (hasDirectCallUse(module.*, function.name)) continue;
        if (hasNonCallFunctionUse(module.*, function.name)) continue;
        var removed = module.functions.orderedRemove(index);
        removed.deinit(module.allocator);
        changed = true;
    }
    return changed;
}

fn hasDirectCallUse(module: ir.Module, function_name: []const u8) bool {
    for (module.functions.items) |function| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                const call = switch (instruction.kind) {
                    .call => |call| call,
                    else => continue,
                };
                if (call.inline_asm != null or call.callee_value != null) continue;
                if (std.mem.eql(u8, call.callee, function_name)) return true;
            }
        }
    }
    return false;
}

fn hasNonCallFunctionUse(module: ir.Module, function_name: []const u8) bool {
    for (module.aliases.items) |alias| {
        if (std.mem.eql(u8, alias.target, function_name)) return true;
    }
    for (module.globals.items) |global| {
        if (initializerReferencesFunction(global.initializer, function_name)) return true;
    }
    for (module.functions.items) |function| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instructionReferencesFunction(instruction, function_name)) return true;
            }
            if (block.terminator) |terminator| {
                if (terminatorReferencesFunction(terminator, function_name)) return true;
            }
        }
    }
    return false;
}

fn initializerReferencesFunction(initializer: ir.GlobalInitializer, function_name: []const u8) bool {
    return switch (initializer) {
        .none, .c_string => false,
        .scalar => |value| valueReferencesFunction(value, function_name),
        .array => |array| for (array.values.items) |value| {
            if (valueReferencesFunction(value, function_name)) break true;
        } else false,
        .@"opaque" => |text| textReferencesFunction(text, function_name),
    };
}

fn instructionReferencesFunction(instruction: ir.Instruction, function_name: []const u8) bool {
    return switch (instruction.kind) {
        .binary => |binary| valueReferencesFunction(binary.lhs, function_name) or valueReferencesFunction(binary.rhs, function_name),
        .cast => |cast| valueReferencesFunction(cast.value, function_name),
        .freeze => |freeze| valueReferencesFunction(freeze.value, function_name),
        .icmp => |icmp| valueReferencesFunction(icmp.lhs, function_name) or valueReferencesFunction(icmp.rhs, function_name),
        .fcmp => |fcmp| valueReferencesFunction(fcmp.lhs, function_name) or valueReferencesFunction(fcmp.rhs, function_name),
        .select => |select| valueReferencesFunction(select.cond, function_name) or
            valueReferencesFunction(select.true_value, function_name) or
            valueReferencesFunction(select.false_value, function_name),
        .phi => |phi| for (phi.incoming.items) |incoming| {
            if (valueReferencesFunction(incoming.value, function_name)) break true;
        } else false,
        .alloca, .fence => false,
        .load => |load| valueReferencesFunction(load.ptr, function_name),
        .store => |store| valueReferencesFunction(store.value, function_name) or valueReferencesFunction(store.ptr, function_name),
        .atomicrmw => |atomicrmw| valueReferencesFunction(atomicrmw.ptr, function_name) or valueReferencesFunction(atomicrmw.value, function_name),
        .cmpxchg => |cmpxchg| valueReferencesFunction(cmpxchg.ptr, function_name) or
            valueReferencesFunction(cmpxchg.expected, function_name) or
            valueReferencesFunction(cmpxchg.replacement, function_name),
        .extractelement => |extract| valueReferencesFunction(extract.vector, function_name) or valueReferencesFunction(extract.index, function_name),
        .insertelement => |insert| valueReferencesFunction(insert.vector, function_name) or
            valueReferencesFunction(insert.value, function_name) or
            valueReferencesFunction(insert.index, function_name),
        .shufflevector => |shuffle| valueReferencesFunction(shuffle.lhs, function_name) or
            valueReferencesFunction(shuffle.rhs, function_name) or
            valueReferencesFunction(shuffle.mask, function_name),
        .extractvalue => |extract| valueReferencesFunction(extract.aggregate, function_name),
        .insertvalue => |insert| valueReferencesFunction(insert.aggregate, function_name) or valueReferencesFunction(insert.value, function_name),
        .gep => |gep| blk: {
            if (valueReferencesFunction(gep.ptr, function_name)) break :blk true;
            for (gep.indices.items) |index| {
                if (valueReferencesFunction(index.value, function_name)) break :blk true;
            }
            break :blk false;
        },
        .call => |call| blk: {
            if (call.callee_value) |callee_value| {
                if (valueReferencesFunction(callee_value, function_name)) break :blk true;
            }
            for (call.args.items) |arg| {
                if (valueReferencesFunction(arg.value, function_name)) break :blk true;
            }
            break :blk false;
        },
    };
}

fn terminatorReferencesFunction(terminator: ir.Terminator, function_name: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| valueReferencesFunction(value, function_name) else false,
        .condbr => |condbr| valueReferencesFunction(condbr.cond, function_name),
        .@"switch" => |switch_term| blk: {
            if (valueReferencesFunction(switch_term.cond, function_name)) break :blk true;
            for (switch_term.cases.items) |case| {
                if (valueReferencesFunction(case.value, function_name)) break :blk true;
            }
            break :blk false;
        },
        .indirectbr => |indirectbr| valueReferencesFunction(indirectbr.addr, function_name),
        .br, .@"unreachable" => false,
    };
}

fn valueReferencesFunction(value: ir.Value, function_name: []const u8) bool {
    return switch (value) {
        .named => |name| std.mem.eql(u8, name, function_name) or textReferencesFunction(name, function_name),
        .constant_expr => |text| textReferencesFunction(text, function_name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => false,
    };
}

fn textReferencesFunction(text: []const u8, function_name: []const u8) bool {
    var search_start: usize = 0;
    while (std.mem.indexOfScalarPos(u8, text, search_start, '@')) |at_index| {
        const name_start = at_index + 1;
        if (text[name_start..].len >= function_name.len and
            std.mem.eql(u8, text[name_start .. name_start + function_name.len], function_name))
        {
            const end = name_start + function_name.len;
            if (end == text.len or !isIdentifierByte(text[end])) return true;
        }
        search_start = name_start;
    }
    return false;
}

fn isIdentifierByte(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '.' or byte == '$' or byte == '-';
}

fn hasAttribute(module: ir.Module, text: ?[]const u8, attr: []const u8) bool {
    const attr_text = text orelse return false;
    var it = std.mem.tokenizeAny(u8, attr_text, " \t,");
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, attr)) return true;
        if (!std.mem.startsWith(u8, token, "#")) continue;
        const group = findAttributeGroup(module, token[1..]) orelse continue;
        if (hasAttributeInText(group, attr)) return true;
    }
    return false;
}

fn hasAttributeInText(text: []const u8, attr: []const u8) bool {
    const body = attributeGroupBody(text) orelse text;
    var it = std.mem.tokenizeAny(u8, body, " \t,{}");
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, attr)) return true;
    }
    return false;
}

fn attributeGroupBody(text: []const u8) ?[]const u8 {
    const open = std.mem.indexOfScalar(u8, text, '{') orelse return null;
    const close = std.mem.lastIndexOfScalar(u8, text, '}') orelse return null;
    if (close <= open) return null;
    return text[open + 1 .. close];
}

fn findAttributeGroup(module: ir.Module, group_id: []const u8) ?[]const u8 {
    for (module.attribute_groups.items) |group| {
        var rest = std.mem.trim(u8, group["attributes ".len..], " \t");
        if (!std.mem.startsWith(u8, rest, "#")) continue;
        rest = rest[1..];
        const id_end = std.mem.indexOfAny(u8, rest, " \t") orelse continue;
        if (std.mem.eql(u8, rest[0..id_end], group_id)) return group;
    }
    return null;
}
