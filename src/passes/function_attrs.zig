const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const memory_effect = @import("../analysis/memory_effect.zig");

const AttributeSet = function_attrs.AttributeSet;

pub const pass: pass_manager.ModulePass = .{
    .name = "function-attrs",
    .category = .ipo,
    .target_status = "LLVM-shaped direct-call algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/FunctionAttrs.cpp",
    .run = run,
};

const VisitState = enum {
    unvisited,
    visiting,
    done,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;

    const memory_effects_memo = try module.allocator.alloc(?InferredMemory, module.functions.items.len);
    defer module.allocator.free(memory_effects_memo);
    @memset(memory_effects_memo, null);

    const memory_effects_state = try module.allocator.alloc(VisitState, module.functions.items.len);
    defer module.allocator.free(memory_effects_state);
    @memset(memory_effects_state, .unvisited);

    for (module.functions.items, 0..) |*function, index| {
        const inferred_effects = computeFunctionMemoryEffects(module.*, index, memory_effects_memo, memory_effects_state);
        if (try applyMemoryEffectsAttribute(module, function, inferred_effects)) changed = true;

        const inferred = memoryEffectFromInferred(inferred_effects);
        if (try applyMemoryAttribute(module, function, inferred)) changed = true;
    }

    const norecurse_memo = try module.allocator.alloc(?bool, module.functions.items.len);
    defer module.allocator.free(norecurse_memo);
    @memset(norecurse_memo, null);

    const norecurse_state = try module.allocator.alloc(VisitState, module.functions.items.len);
    defer module.allocator.free(norecurse_state);
    @memset(norecurse_state, .unvisited);

    for (module.functions.items, 0..) |*function, index| {
        const attrs = function_attrs.resolvedFunctionAttributes(module.*, function.*);
        if (attrs.norecurse) continue;
        if (mayHaveRecursiveCallee(module.*, index, norecurse_memo, norecurse_state)) continue;
        if (try appendFunctionAttr(module, function, "norecurse")) changed = true;
    }

    const simple_attr_state = try module.allocator.alloc(VisitState, module.functions.items.len);
    defer module.allocator.free(simple_attr_state);

    for (module.functions.items, 0..) |*function, index| {
        @memset(simple_attr_state, .unvisited);
        if (canInferNoFree(module.*, index, simple_attr_state)) {
            if (try appendFunctionAttr(module, function, "nofree")) changed = true;
        }

        @memset(simple_attr_state, .unvisited);
        if (canInferNoSync(module.*, index, simple_attr_state)) {
            if (try appendFunctionAttr(module, function, "nosync")) changed = true;
        }

        @memset(simple_attr_state, .unvisited);
        if (canInferNoUnwind(module.*, index, simple_attr_state)) {
            if (try appendFunctionAttr(module, function, "nounwind")) changed = true;
        }

        if (canInferMustProgressWillReturn(function.*)) {
            if (try appendFunctionAttr(module, function, "mustprogress")) changed = true;
            if (try appendFunctionAttr(module, function, "willreturn")) changed = true;
        }

        @memset(simple_attr_state, .unvisited);
        if (canInferNoMemoryThroughLocalCycle(module.*, index, simple_attr_state)) {
            if (try appendMemoryNoneAttr(module, function)) changed = true;
        }

        if (try inferParameterAttributes(module, function)) changed = true;
    }

    if (try materializeAttributeGroups(module)) changed = true;

    return if (changed) .changed else .unchanged;
}

const InferredMemory = struct {
    known: bool = true,
    effects: AttributeSet.MemoryEffects = .none(),

    fn unknown() InferredMemory {
        return .{ .known = false };
    }

    fn none() InferredMemory {
        return .{};
    }

    fn all(value: AttributeSet.ModRef) InferredMemory {
        return .{ .effects = .all(value) };
    }

    fn argmem(value: AttributeSet.ModRef) InferredMemory {
        return .{ .effects = .argMemOnly(value) };
    }
};

fn computeFunctionMemoryEffects(
    module: ir.Module,
    function_index: usize,
    memo: []?InferredMemory,
    state: []VisitState,
) InferredMemory {
    if (memo[function_index]) |effect| return effect;
    if (state[function_index] == .visiting) return .unknown();
    if (state[function_index] == .done) return memo[function_index] orelse .unknown();

    state[function_index] = .visiting;
    var effect = InferredMemory.none();
    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const inst_effect = instructionMemoryEffects(module, function, instruction, memo, state);
            effect = mergeMemoryEffects(effect, inst_effect);
            if (!effect.known) {
                state[function_index] = .done;
                memo[function_index] = .unknown();
                return .unknown();
            }
        }
    }

    state[function_index] = .done;
    memo[function_index] = effect;
    return effect;
}

fn instructionMemoryEffects(
    module: ir.Module,
    function: ir.Function,
    instruction: ir.Instruction,
    memo: []?InferredMemory,
    state: []VisitState,
) InferredMemory {
    return switch (instruction.kind) {
        .load => |load| blk: {
            if (load.attrs.isBarrier()) break :blk .unknown();
            break :blk if (isPointerParam(function, load.ptr)) .argmem(.ref) else .all(.ref);
        },
        .store => |store| blk: {
            if (store.attrs.isBarrier()) break :blk .unknown();
            break :blk if (isPointerParam(function, store.ptr)) .argmem(.mod) else .all(.mod);
        },
        .call => |call| callMemoryEffects(module, call, memo, state),
        else => memoryEffectsFromLegacy(memory_effect.classify(instruction)),
    };
}

fn callMemoryEffects(
    module: ir.Module,
    call: ir.CallInst,
    memo: []?InferredMemory,
    state: []VisitState,
) InferredMemory {
    if (call.inline_asm != null or call.operand_bundle != null or call.callee_value != null) return .unknown();
    if (findFunctionIndex(module, call.callee)) |index| {
        return computeFunctionMemoryEffects(module, index, memo, state);
    }
    const attrs = function_attrs.resolvedCallAttributes(module, call) orelse return .unknown();
    if (attrs.memory_effects) |effects| return .{ .effects = effects };
    return memoryEffectsFromLegacy(function_attrs.callMemoryEffect(module, call));
}

fn memoryEffectsFromLegacy(effect: memory_effect.Effect) InferredMemory {
    return switch (effect) {
        .none => .none(),
        .readonly_load, .readonly_side_effect => .all(.ref),
        .memory_write => .all(.mod),
        .side_effect, .volatile_or_atomic_barrier, .unknown => .unknown(),
    };
}

fn memoryEffectFromInferred(inferred: InferredMemory) memory_effect.Effect {
    if (!inferred.known) return .unknown;
    return switch (inferred.effects.overall()) {
        .no_mod_ref => .none,
        .ref => .readonly_load,
        .mod => .memory_write,
        .mod_ref => .unknown,
    };
}

fn mergeMemoryEffects(a: InferredMemory, b: InferredMemory) InferredMemory {
    if (!a.known or !b.known) return .unknown();
    return .{ .effects = .{
        .argmem = a.effects.argmem.merge(b.effects.argmem),
        .inaccessiblemem = a.effects.inaccessiblemem.merge(b.effects.inaccessiblemem),
        .other = a.effects.other.merge(b.effects.other),
    } };
}

fn applyMemoryAttribute(module: *ir.Module, function: *ir.Function, effect: memory_effect.Effect) !bool {
    const attrs = function_attrs.resolvedFunctionAttributes(module.*, function.*);
    if (attrs.memory_effects != null or attrs.readnone or attrs.readonly or attrs.writeonly) return false;
    return switch (effect) {
        .none => appendFunctionAttr(module, function, "memory(none)"),
        .readonly_load => appendFunctionAttr(module, function, "memory(read)"),
        .side_effect, .readonly_side_effect, .memory_write, .volatile_or_atomic_barrier, .unknown => false,
    };
}

fn applyMemoryEffectsAttribute(module: *ir.Module, function: *ir.Function, inferred: InferredMemory) !bool {
    if (!inferred.known) return false;
    const attrs = function_attrs.resolvedFunctionAttributes(module.*, function.*);
    if (attrs.memory_effects != null or attrs.readnone or attrs.readonly or attrs.writeonly) return false;
    const attr = memoryEffectsAttributeText(inferred.effects) orelse return false;
    return appendFunctionAttr(module, function, attr);
}

fn memoryEffectsAttributeText(effects: AttributeSet.MemoryEffects) ?[]const u8 {
    if (effects.overall() == .no_mod_ref) return "memory(none)";
    if (effects.inaccessiblemem == .no_mod_ref and effects.other == .no_mod_ref) {
        return switch (effects.argmem) {
            .no_mod_ref => "memory(none)",
            .ref => "memory(argmem: read)",
            .mod => "memory(argmem: write)",
            .mod_ref => "memory(argmem: readwrite)",
        };
    }
    if (effects.argmem == effects.inaccessiblemem and effects.argmem == effects.other) {
        return switch (effects.other) {
            .no_mod_ref => "memory(none)",
            .ref => "memory(read)",
            .mod => "memory(write)",
            .mod_ref => "memory(readwrite)",
        };
    }
    return null;
}

fn mayHaveRecursiveCallee(
    module: ir.Module,
    function_index: usize,
    memo: []?bool,
    state: []VisitState,
) bool {
    if (memo[function_index]) |value| return value;
    if (state[function_index] == .visiting) return true;
    if (state[function_index] == .done) return memo[function_index] orelse true;

    state[function_index] = .visiting;
    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (callMayRecurse(module, call, memo, state)) {
                state[function_index] = .done;
                memo[function_index] = true;
                return true;
            }
        }
    }

    state[function_index] = .done;
    memo[function_index] = false;
    return false;
}

fn callMayRecurse(
    module: ir.Module,
    call: ir.CallInst,
    memo: []?bool,
    state: []VisitState,
) bool {
    if (call.inline_asm != null or call.operand_bundle != null or call.callee_value != null) return true;
    if (findFunctionIndex(module, call.callee)) |index| {
        return mayHaveRecursiveCallee(module, index, memo, state);
    }
    const attrs = function_attrs.resolvedCalleeAttributes(module, call.callee) orelse return true;
    return !attrs.norecurse;
}

fn canInferNoFree(module: ir.Module, function_index: usize, state: []VisitState) bool {
    if (state[function_index] == .visiting) return true;
    if (state[function_index] == .done) return true;
    state[function_index] = .visiting;
    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .call => |call| {
                    if (!callCanInferNoFree(module, call, state)) return false;
                },
                else => {},
            }
        }
    }
    state[function_index] = .done;
    return true;
}

fn callCanInferNoFree(module: ir.Module, call: ir.CallInst, state: []VisitState) bool {
    if (call.inline_asm != null or call.operand_bundle != null or call.callee_value != null) return false;
    if (findFunctionIndex(module, call.callee)) |index| return canInferNoFree(module, index, state);
    const attrs = function_attrs.resolvedCalleeAttributes(module, call.callee) orelse return false;
    if (attrs.nofree) return true;
    const effects = attrs.memory_effects orelse return false;
    return !effects.overall().hasMod();
}

fn canInferNoSync(module: ir.Module, function_index: usize, state: []VisitState) bool {
    if (state[function_index] == .visiting) return true;
    if (state[function_index] == .done) return true;
    state[function_index] = .visiting;
    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instructionHasSyncBoundary(instruction)) return false;
            switch (instruction.kind) {
                .call => |call| {
                    if (!callCanInferAttr(module, call, state, .nosync)) return false;
                },
                else => {},
            }
        }
    }
    state[function_index] = .done;
    return true;
}

fn canInferNoUnwind(module: ir.Module, function_index: usize, state: []VisitState) bool {
    if (state[function_index] == .visiting) return true;
    if (state[function_index] == .done) return true;
    state[function_index] = .visiting;
    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .call => |call| {
                    if (!callCanInferAttr(module, call, state, .nounwind)) return false;
                },
                else => {},
            }
        }
    }
    state[function_index] = .done;
    return true;
}

const SimpleCalleeAttr = enum {
    nosync,
    nounwind,
};

fn callCanInferAttr(module: ir.Module, call: ir.CallInst, state: []VisitState, attr: SimpleCalleeAttr) bool {
    if (call.inline_asm != null or call.operand_bundle != null or call.callee_value != null) return false;
    if (findFunctionIndex(module, call.callee)) |index| {
        return switch (attr) {
            .nosync => canInferNoSync(module, index, state),
            .nounwind => canInferNoUnwind(module, index, state),
        };
    }
    const attrs = function_attrs.resolvedCalleeAttributes(module, call.callee) orelse return false;
    return switch (attr) {
        .nosync => attrs.nosync,
        .nounwind => attrs.nounwind,
    };
}

fn instructionHasSyncBoundary(instruction: ir.Instruction) bool {
    return switch (instruction.kind) {
        .load => |load| load.attrs.isAtomic(),
        .store => |store| store.attrs.isAtomic(),
        .atomicrmw, .cmpxchg, .fence => true,
        else => false,
    };
}

fn canInferMustProgressWillReturn(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.kind == .call) return false;
            if (instruction.kind == .atomicrmw or instruction.kind == .cmpxchg or instruction.kind == .fence) return false;
        }
        const terminator = block.terminator orelse return false;
        if (terminator != .ret) return false;
    }
    return function.blocks.items.len != 0;
}

fn canInferNoMemoryThroughLocalCycle(module: ir.Module, function_index: usize, state: []VisitState) bool {
    if (state[function_index] == .visiting) return true;
    if (state[function_index] == .done) return true;
    state[function_index] = .visiting;

    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .call => |call| {
                    if (!callCanInferNoMemory(module, call, state)) return false;
                },
                else => if (memory_effect.classify(instruction) != .none) return false,
            }
        }
    }

    state[function_index] = .done;
    return true;
}

fn callCanInferNoMemory(module: ir.Module, call: ir.CallInst, state: []VisitState) bool {
    if (call.inline_asm != null or call.operand_bundle != null or call.callee_value != null) return false;
    if (findFunctionIndex(module, call.callee)) |index| return canInferNoMemoryThroughLocalCycle(module, index, state);
    const attrs = function_attrs.resolvedCalleeAttributes(module, call.callee) orelse return false;
    const effects = attrs.memory_effects orelse return attrs.readnone;
    return effects.overall() == .no_mod_ref;
}

fn inferParameterAttributes(module: *ir.Module, function: *ir.Function) !bool {
    var changed = false;
    for (function.params.items, 0..) |param, index| {
        if (param.ty == .ptr) {
            const access = pointerParamAccess(function.*, param.name);
            if (!access.captured and access.read and !access.written) {
                if (try appendParamAttr(module, function, index, "readonly captures(none)")) changed = true;
            } else if (!access.captured and access.written and !access.read) {
                const init_attr = if (access.write_size) |size|
                    try std.fmt.allocPrint(module.allocator, "writeonly captures(none) initializes((0, {}))", .{size})
                else
                    try std.fmt.allocPrint(module.allocator, "writeonly captures(none)", .{});
                defer module.allocator.free(init_attr);
                if (try appendParamAttr(module, function, index, init_attr)) changed = true;
            }
        }

        if (returnsParameter(function.*, param.name)) {
            if (try appendParamAttr(module, function, index, "returned")) changed = true;
        }
    }
    return changed;
}

const PointerParamAccess = struct {
    read: bool = false,
    written: bool = false,
    captured: bool = false,
    write_size: ?usize = null,
};

fn pointerParamAccess(function: ir.Function, param_name: []const u8) PointerParamAccess {
    var access: PointerParamAccess = .{};
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .load => |load| if (isNamedValue(load.ptr, param_name)) {
                    access.read = true;
                },
                .store => |store| {
                    if (isNamedValue(store.ptr, param_name)) {
                        access.written = true;
                        access.write_size = mergeWriteSize(access.write_size, typeStoreSize(store.ty));
                    }
                    if (isNamedValue(store.value, param_name)) access.captured = true;
                },
                .call => |call| {
                    for (call.args.items) |arg| {
                        if (isNamedValue(arg.value, param_name)) access.captured = true;
                    }
                },
                .gep => |gep| if (isNamedValue(gep.ptr, param_name)) {
                    access.captured = true;
                },
                else => if (instructionUsesNamedValue(instruction, param_name)) {
                    access.captured = true;
                },
            }
        }
        if (block.terminator) |terminator| {
            if (terminatorUsesNamedValue(terminator, param_name)) access.captured = true;
        }
    }
    return access;
}

fn mergeWriteSize(current: ?usize, next: ?usize) ?usize {
    const value = next orelse return null;
    if (current) |existing| {
        if (existing == value) return existing;
        return null;
    }
    return value;
}

fn typeStoreSize(ty: ir.Type) ?usize {
    return switch (ty) {
        .int => |bits| if (bits % 8 == 0) @as(usize, bits / 8) else null,
        .half => 2,
        .float => 4,
        .double => 8,
        .ptr => 8,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => null,
    };
}

fn returnsParameter(function: ir.Function, param_name: []const u8) bool {
    var saw_return = false;
    for (function.blocks.items) |block| {
        const terminator = block.terminator orelse return false;
        const ret = switch (terminator) {
            .ret => |ret| ret,
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
        };
        const value = ret.value orelse return false;
        if (!isNamedValue(value, param_name)) return false;
        saw_return = true;
    }
    return saw_return;
}

fn isPointerParam(function: ir.Function, value: ir.Value) bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    for (function.params.items) |param| {
        if (param.ty == .ptr and std.mem.eql(u8, param.name, name)) return true;
    }
    return false;
}

fn isNamedValue(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |candidate| std.mem.eql(u8, candidate, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn instructionUsesNamedValue(instruction: ir.Instruction, name: []const u8) bool {
    return switch (instruction.kind) {
        .binary => |binary| isNamedValue(binary.lhs, name) or isNamedValue(binary.rhs, name),
        .cast => |cast| isNamedValue(cast.value, name),
        .freeze => |freeze| isNamedValue(freeze.value, name),
        .icmp => |icmp| isNamedValue(icmp.lhs, name) or isNamedValue(icmp.rhs, name),
        .fcmp => |fcmp| isNamedValue(fcmp.lhs, name) or isNamedValue(fcmp.rhs, name),
        .select => |select| isNamedValue(select.cond, name) or isNamedValue(select.true_value, name) or isNamedValue(select.false_value, name),
        .phi => |phi| {
            for (phi.incoming.items) |incoming| {
                if (isNamedValue(incoming.value, name)) return true;
            }
            return false;
        },
        .extractelement => |extract| isNamedValue(extract.vector, name) or isNamedValue(extract.index, name),
        .insertelement => |insert| isNamedValue(insert.vector, name) or isNamedValue(insert.value, name) or isNamedValue(insert.index, name),
        .shufflevector => |shuffle| isNamedValue(shuffle.lhs, name) or isNamedValue(shuffle.rhs, name),
        .extractvalue => |extract| isNamedValue(extract.aggregate, name),
        .insertvalue => |insert| isNamedValue(insert.aggregate, name) or isNamedValue(insert.value, name),
        .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .gep, .call => false,
    };
}

fn terminatorUsesNamedValue(terminator: ir.Terminator, name: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| isNamedValue(value, name) else false,
        .condbr => |condbr| isNamedValue(condbr.cond, name),
        .@"switch" => |switch_term| isNamedValue(switch_term.cond, name),
        .indirectbr => |indirectbr| isNamedValue(indirectbr.addr, name),
        .br, .@"unreachable" => false,
    };
}

fn materializeAttributeGroups(module: *ir.Module) !bool {
    if (module.attribute_groups.items.len != 0) return false;

    var changed = false;
    var groups: std.ArrayList([]const u8) = .empty;
    defer groups.deinit(module.allocator);

    for (module.declarations.items) |*decl| {
        const attrs = decl.attrs orelse continue;
        const body = try canonicalFunctionAttrBody(module.allocator, attrs) orelse continue;
        defer module.allocator.free(body);
        const group_ref = try ensureAttributeGroup(module, &groups, body);
        decl.attrs = group_ref;
        changed = true;
    }

    for (module.functions.items) |*function| {
        const attrs = function.attrs orelse continue;
        const body = try canonicalFunctionAttrBody(module.allocator, attrs) orelse continue;
        defer module.allocator.free(body);
        const group_ref = try ensureAttributeGroup(module, &groups, body);
        function.attrs = group_ref;
        changed = true;
    }

    return changed;
}

fn ensureAttributeGroup(module: *ir.Module, groups: *std.ArrayList([]const u8), body: []const u8) ![]const u8 {
    for (groups.items, 0..) |existing, index| {
        if (std.mem.eql(u8, existing, body)) {
            return module.ownString(try std.fmt.allocPrint(module.allocator, "#{}", .{index}));
        }
    }

    const index = groups.items.len;
    const owned_body = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}", .{body}));
    try groups.append(module.allocator, owned_body);
    const group_line = try module.ownString(try std.fmt.allocPrint(module.allocator, "attributes #{} = {{ {s} }}", .{ index, body }));
    try module.attribute_groups.append(module.allocator, group_line);
    return module.ownString(try std.fmt.allocPrint(module.allocator, "#{}", .{index}));
}

fn canonicalFunctionAttrBody(allocator: std.mem.Allocator, attrs_text: []const u8) !?[]u8 {
    if (hasUnknownFunctionAttr(attrs_text)) return null;
    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();
    var first = true;

    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "mustprogress"), "mustprogress");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "nofree"), "nofree");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "norecurse"), "norecurse");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "nosync"), "nosync");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "nounwind"), "nounwind");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "willreturn"), "willreturn");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "readnone"), "readnone");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "readonly"), "readonly");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "writeonly"), "writeonly");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "argmemonly"), "argmemonly");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "inaccessiblememonly"), "inaccessiblememonly");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "alwaysinline"), "alwaysinline");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "noinline"), "noinline");
    try appendCanonicalAttr(&out.writer, &first, rawHasFunctionAttr(attrs_text, "cold"), "cold");
    if (memoryAttrText(attrs_text)) |memory_attr| try appendCanonicalAttr(&out.writer, &first, true, memory_attr);

    if (first) return null;
    return try out.toOwnedSlice();
}

fn appendCanonicalAttr(writer: *std.Io.Writer, first: *bool, enabled: bool, attr: []const u8) !void {
    if (!enabled) return;
    if (!first.*) try writer.writeByte(' ');
    try writer.writeAll(attr);
    first.* = false;
}

fn hasUnknownFunctionAttr(attrs_text: []const u8) bool {
    var index: usize = 0;
    while (nextFunctionAttr(attrs_text, &index)) |attr| {
        if (isKnownFunctionAttr(attr)) continue;
        return true;
    }
    return false;
}

fn rawHasFunctionAttr(attrs_text: []const u8, needle: []const u8) bool {
    var index: usize = 0;
    while (nextFunctionAttr(attrs_text, &index)) |attr| {
        if (std.mem.eql(u8, attr, needle)) return true;
    }
    return false;
}

fn memoryAttrText(attrs_text: []const u8) ?[]const u8 {
    var index: usize = 0;
    while (nextFunctionAttr(attrs_text, &index)) |attr| {
        if (std.mem.startsWith(u8, attr, "memory(")) return attr;
    }
    return null;
}

fn nextFunctionAttr(attrs_text: []const u8, index: *usize) ?[]const u8 {
    while (index.* < attrs_text.len and std.ascii.isWhitespace(attrs_text[index.*])) : (index.* += 1) {}
    if (index.* >= attrs_text.len) return null;
    const start = index.*;
    if (std.mem.startsWith(u8, attrs_text[start..], "memory(")) {
        const end = std.mem.indexOfScalarPos(u8, attrs_text, start, ')') orelse attrs_text.len - 1;
        index.* = @min(end + 1, attrs_text.len);
        return attrs_text[start..index.*];
    }
    while (index.* < attrs_text.len and !std.ascii.isWhitespace(attrs_text[index.*])) : (index.* += 1) {}
    return attrs_text[start..index.*];
}

fn isKnownFunctionAttr(attr: []const u8) bool {
    if (std.mem.startsWith(u8, attr, "memory(")) return true;
    inline for (.{
        "mustprogress",
        "nofree",
        "norecurse",
        "nosync",
        "nounwind",
        "willreturn",
        "readnone",
        "readonly",
        "writeonly",
        "argmemonly",
        "inaccessiblememonly",
        "alwaysinline",
        "noinline",
        "cold",
    }) |known| {
        if (std.mem.eql(u8, attr, known)) return true;
    }
    return false;
}

fn appendFunctionAttr(module: *ir.Module, function: *ir.Function, attr: []const u8) !bool {
    if (hasRawAttr(function.attrs, attr)) return false;
    const new_attrs = if (function.attrs) |existing|
        try std.fmt.allocPrint(module.allocator, "{s} {s}", .{ existing, attr })
    else
        try std.fmt.allocPrint(module.allocator, "{s}", .{attr});
    function.attrs = try module.ownString(new_attrs);
    return true;
}

fn appendMemoryNoneAttr(module: *ir.Module, function: *ir.Function) !bool {
    const attrs = function_attrs.resolvedFunctionAttributes(module.*, function.*);
    if (attrs.memory_effects != null or attrs.readnone or attrs.readonly or attrs.writeonly) return false;
    return appendFunctionAttr(module, function, "memory(none)");
}

fn appendParamAttr(module: *ir.Module, function: *ir.Function, param_index: usize, attr: []const u8) !bool {
    const param = &function.params.items[param_index];
    if (hasRawAttr(param.attrs, attr)) return false;
    const new_attrs = if (param.attrs) |existing|
        try std.fmt.allocPrint(module.allocator, "{s} {s}", .{ existing, attr })
    else
        try std.fmt.allocPrint(module.allocator, "{s}", .{attr});
    param.attrs = try module.ownString(new_attrs);
    return true;
}

fn hasRawAttr(attrs: ?[]const u8, attr: []const u8) bool {
    const text = attrs orelse return false;
    var it = std.mem.tokenizeAny(u8, text, " \t,{}");
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, attr)) return true;
    }
    return false;
}

fn findFunctionIndex(module: ir.Module, name: []const u8) ?usize {
    for (module.functions.items, 0..) |function, index| {
        if (std.mem.eql(u8, function.name, name)) return index;
    }
    return null;
}
