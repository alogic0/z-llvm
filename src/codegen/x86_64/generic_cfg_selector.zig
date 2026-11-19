const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");
const inspection = @import("generic_cfg/inspection.zig");
const legacy_lowering = @import("generic_cfg/legacy_lowering.zig");
const stage2_planning = @import("generic_cfg/stage2_planning.zig");
const composed_selector = @import("generic_cfg/composed_selector.zig");
const address_dependencies = @import("generic_cfg/composed_selector_address_dependencies.zig");
const switch_phi_edges = @import("generic_cfg/switch_phi_edges.zig");
const semantic_normalization = @import("generic_cfg/semantic_normalization.zig");
const Observer = @import("generic_cfg/rejection_observer.zig").Observer;

pub const MachineFunction = x86_64_machine.MachineFunction;

pub const Diagnostic = inspection.Diagnostic;
pub const SelectionResult = inspection.SelectionResult;
pub const inspectFunction = inspection.inspectFunction;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;

pub const StageTwoSummary = stage2_planning.StageTwoSummary;
pub const analyzeStageTwoNoSpillEnvelope = stage2_planning.analyzeStageTwoNoSpillEnvelope;

pub fn tryLower(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    return tryLowerWithContext(allocator, machine, function, null);
}

pub fn tryLowerWithContext(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
) !SelectionResult {
    return tryLowerProfiled(allocator, machine, function, module_context, null);
}

pub fn tryLowerProfiled(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    source: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    profile: ?*@import("../../compilation_profile.zig").Profile,
) !SelectionResult {
    return tryLowerObserved(allocator, machine, source, module_context, profile, null);
}

pub fn tryLowerObserved(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    source: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    profile: ?*@import("../../compilation_profile.zig").Profile,
    observer: ?*Observer,
) !SelectionResult {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const function = try @import("debug_locations.zig").executableView(arena.allocator(), source);
    return tryLowerExecutableObserved(allocator, machine, function, module_context, profile, observer);
}

/// The caller has already removed debug-only records from its private view.
pub fn tryLowerExecutableObserved(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    source: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    profile: ?*@import("../../compilation_profile.zig").Profile,
    observer: ?*Observer,
) !SelectionResult {
    return tryLowerObservedInner(allocator, machine, source, module_context, profile, observer) catch |err| {
        if (err != error.ValueUseIdentityTooLong) return err;
        // Composed lowering has already rolled back its failed transaction.
        // Preserve every successful original stream and retry only this exact
        // bounded-identity error with a private alpha-renamed SSA view.
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const view = (try shortLocalNames(arena.allocator(), source)) orelse return err;
        return tryLowerObservedInner(allocator, machine, view, module_context, profile, observer);
    };
}

fn tryLowerObservedInner(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    source: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    profile: ?*@import("../../compilation_profile.zig").Profile,
    observer: ?*Observer,
) !SelectionResult {
    const profiling = @import("../../compilation_profile.zig");
    const optional = @import("generic_cfg/optional_legalization.zig");
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pending_labels: std.ArrayList([]const ir.BasicBlock) = .empty;
    var function = if (module_context) |ctx|
        (try @import("generic_cfg/narrow_abi.zig").resolveTailSymbols(arena.allocator(), source, ctx)) orelse source
    else
        source;
    var budget: optional.Budget = .{};
    var iterations: u64 = 0;
    while (true) {
        Observer.reset(observer);
        iterations += 1;
        if (profile) |p| p.iteration(iterations);
        const normalized = blk: {
            const scope = profiling.enter(profile, .normalize);
            defer scope.end();
            break :blk try semantic_normalization.normalizeProfiled(arena.allocator(), function, module_context, profile);
        };
        function = normalized.ir_function;
        const result: SelectionResult = blk: {
            for (function.blocks.items) |block| for (block.instructions.items) |inst| {
                if (!inst.removed and inst.kind == .alloca and !inst.kind.alloca.isSingleObject())
                    return .{ .unsupported = .{ .no_emitter = "alloca-count" } };
            };
            if (normalized.whole_function) |form| {
                try legacy_lowering.lower(allocator, machine, form);
                if (machine.selection_owner != .unassigned) return error.SelectionOwnerAlreadyAssigned;
                machine.selection_owner = .legacy_envelope;
                break :blk .selected;
            }
            try semantic_normalization.check(function);
            const inspected = inspection.inspectFunctionWithContext(function, module_context);
            if (try optional.next(arena.allocator(), function, module_context, profile)) |rewrite| {
                if (rewrite.retry_original) {
                    if (profile) |p| p.counters.original_form_retries += 1;
                    const retry_scope = profiling.retry(profile);
                    defer retry_scope.end();
                    if (try tryOriginalComposedForm(allocator, machine, function, module_context, inspected, observer)) {
                        if (profile) |p| {
                            p.counters.original_form_selected += 1;
                            p.discardCandidate(rewrite.profile_stage, rewrite.profile_allocation_bytes);
                        }
                        break :blk .selected;
                    }
                }
                try budget.consume();
                if (rewrite.retain_all_labels)
                    try pending_labels.append(arena.allocator(), rewrite.function.blocks.items)
                else if (rewrite.retain_labels)
                    try pending_labels.append(arena.allocator(), rewrite.function.blocks.items[function.blocks.items.len..]);
                function = rewrite.function;
                continue;
            }
            Observer.reset(observer);
            break :blk try selectReady(allocator, machine, function, module_context, inspected, observer);
        };
        if (result == .selected) {
            if (@import("generic_cfg/limb_integers.zig").privateReturnType(source.ret_ty)) |physical_return| {
                if (!function.ret_ty.eql(physical_return)) return error.UnprovenLimbReturnAbi;
                machine.ret_ty = physical_return;
            }
            if (@import("generic_cfg/integer_vectors.zig").privateAbiType(source.ret_ty)) |physical_return| {
                if (!function.ret_ty.eql(physical_return)) return error.UnprovenVectorReturnAbi;
                machine.ret_ty = physical_return;
            }
            // Match recursive unwind order; labels must outlive the private IR.
            var i = pending_labels.items.len;
            while (i != 0) {
                i -= 1;
                try switch_phi_edges.retainLabels(allocator, machine, pending_labels.items[i]);
            }
        }
        return result;
    }
}

const LocalAliases = std.HashMap([]const u8, []const u8, ir.identifiers.Context, std.hash_map.default_max_load_percentage);
const LocalRename = struct {
    pub const Error = error{ UnsupportedOpaqueNameSyntax, UnsafePrivateLocalIdentity };
    aliases: *const LocalAliases,

    fn text(rename: LocalRename, raw: ?[]const u8) Error!void {
        var tokens: @import("../../ir/opaque_names.zig").Iterator = .{ .raw = raw orelse return };
        while (try tokens.next()) |token| switch (token) {
            .local => |name| if (rename.aliases.contains(name)) return error.UnsafePrivateLocalIdentity,
            // Function and block identities are never changed by this view.
            .block_address => {},
        };
    }
    pub fn visit(rename: LocalRename, value: *ir.Value, _: ir.Type) Error!void {
        switch (value.*) {
            .named => |name| if (rename.aliases.get(name)) |replacement| {
                value.* = .{ .named = replacement };
            },
            .vector => |raw| try rename.text(raw),
            .constant_expr => |raw| try rename.text(raw),
            else => {},
        }
    }
};

fn shortLocalNames(a: std.mem.Allocator, source: ir.Function) !?ir.Function {
    return shortLocalNamesImpl(a, source) catch |err| switch (err) {
        error.UnsupportedOpaqueNameSyntax, error.UnsafePrivateLocalIdentity => null,
        else => return err,
    };
}
fn shortLocalNamesImpl(a: std.mem.Allocator, source: ir.Function) !?ir.Function {
    const limit = @import("generic_cfg/value_use/model.zig").max_identity_bytes;
    const forms = @import("generic_cfg/scalar_forms.zig");
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_short_local_" };
    defer names.deinit(a);
    var aliases = LocalAliases.init(a);
    defer aliases.deinit();
    // ABI parameters, CFG labels and external symbol names retain their full
    // Source identities. Only instruction-result locals are eligible.
    for (source.params.items) |param| if (param.name.len > limit) return null;
    for (source.blocks.items) |block| {
        if (block.name.len > limit) return null;
        for (block.instructions.items) |inst| if (inst.result) |name| {
            if (name.len <= limit) continue;
            if (!ir.identifiers.isValid(name)) return null;
            const entry = try aliases.getOrPut(name);
            if (entry.found_existing) return null;
            entry.value_ptr.* = try forms.temporary(a, source, &names);
        };
    }
    if (aliases.count() == 0) return null;
    const rename: LocalRename = .{ .aliases = &aliases };
    try rename.text(source.attrs);
    try rename.text(source.ret_attrs);
    for (source.params.items) |param| try rename.text(param.attrs);
    var result = source;
    result.blocks = .empty;
    for (source.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (copy.result) |name| if (aliases.get(name)) |replacement| {
                copy.result = replacement;
            };
            try rename.text(copy.metadata);
            switch (copy.kind) {
                .call => |call| {
                    copy.kind.call.args = try call.args.clone(a);
                    try rename.text(call.callee_function_ty);
                    try rename.text(call.raw_args);
                    try rename.text(call.operand_bundle);
                    try rename.text(call.attrs);
                    try rename.text(call.ret_attrs);
                    for (call.args.items) |arg| try rename.text(arg.attrs);
                    // Inline assembly templates bind typed arguments and do
                    // not refer to the surrounding LLVM SSA namespace.
                },
                .phi => |phi| copy.kind.phi.incoming = try phi.incoming.clone(a),
                .gep => |gep| copy.kind.gep.indices = try gep.indices.clone(a),
                .alloca => |alloca| try rename.text(alloca.attrs),
                else => {},
            }
            _ = try ir.operands.instruction(&copy, rename);
            if (copy.replacement) |*value| try rename.visit(value, inst.resultType() orelse .void);
            try block.instructions.append(a, copy);
        }
        if (block.terminator) |*term| {
            switch (term.*) {
                .@"switch" => |x| {
                    term.@"switch".cases = try x.cases.clone(a);
                    try rename.text(x.metadata);
                },
                .br => |x| try rename.text(x.metadata),
                .condbr => |x| try rename.text(x.metadata),
                .indirectbr => |x| try rename.text(x.metadata),
                else => {},
            }
            _ = try ir.operands.terminator(term, rename);
        }
        try result.blocks.append(a, block);
    }
    return result;
}

fn selectReady(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    inspected: SelectionResult,
    observer: ?*Observer,
) !SelectionResult {
    if (observer) |sink| if (inspected == .unsupported and inspected.unsupported == .unsupported_type) {
        if (inspection.firstRejectedInstruction(function, module_context)) |rejected| {
            if (std.mem.eql(u8, rejected.diagnostic.tagName(), inspected.unsupported.tagName()) and
                std.mem.eql(u8, rejected.diagnostic.detail(), inspected.unsupported.detail()))
            {
                try sink.reject(.{
                    .function = function,
                    .position = rejected.position,
                    .tag = rejected.diagnostic.tagName(),
                    .detail = rejected.diagnostic.detail(),
                    .definition = rejected.instruction,
                });
            }
        }
    };
    switch (inspected) {
        .selected => unreachable,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => {},
            .unsupported_instruction => |detail| {
                if (!std.mem.eql(u8, detail, "udiv") and
                    !std.mem.eql(u8, detail, "urem"))
                {
                    return inspected;
                }
            },
            .unsupported_control_flow => {
                if (function.blocks.items.len > 1) {
                    return tryLowerComposedCfgFailClosed(allocator, machine, function, module_context, observer);
                }
                return inspected;
            },
            else => return inspected,
        },
    }
    if (function.blocks.items.len > 1) {
        return tryLowerComposedCfgFailClosed(allocator, machine, function, module_context, observer);
    }
    switch (try tryLowerComposedBlockFailClosed(allocator, machine, function, module_context, observer)) {
        .selected => return .selected,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => {
                if (shouldReportComposedNoEmitter(inspected)) return .{ .unsupported = diagnostic };
            },
            else => {
                return .{ .unsupported = diagnostic };
            },
        },
    }
    return inspected;
}

fn shouldReportComposedNoEmitter(inspected: SelectionResult) bool {
    return switch (inspected) {
        .selected => false,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => |detail| std.mem.eql(u8, detail, "selector-skeleton-has-no-emitters"),
            .unsupported_control_flow, .unsupported_instruction, .unsupported_type, .unsupported_value, .no_spill_envelope => false,
        },
    };
}

const SelectionTransaction = struct {
    const State = enum {
        active,
        committed,
        rolled_back,
    };

    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    snapshot: MachineFunction,
    instruction_len: usize,
    owned_labels_len: usize,
    address_dependencies: AddressDependencyDomain,
    address_dependencies_snapshot: AddressDependencyDomain,
    state: State = .active,

    fn begin(allocator: std.mem.Allocator, machine: *MachineFunction) SelectionTransaction {
        return beginWithAddressDependencies(allocator, machine, .{});
    }

    fn beginWithAddressDependencies(
        allocator: std.mem.Allocator,
        machine: *MachineFunction,
        initial_address_dependencies: AddressDependencyDomain,
    ) SelectionTransaction {
        comptime assertMachineFunctionFieldsCovered();
        return .{
            .allocator = allocator,
            .machine = machine,
            .snapshot = machine.*,
            .instruction_len = machine.instructions.items.len,
            .owned_labels_len = machine.owned_labels.items.len,
            .address_dependencies = initial_address_dependencies,
            .address_dependencies_snapshot = initial_address_dependencies,
        };
    }

    fn commit(transaction: *SelectionTransaction, owner: x86_64_machine.SelectionOwner) !void {
        std.debug.assert(transaction.state == .active);
        if (transaction.machine.selection_owner != .unassigned) return error.SelectionOwnerAlreadyAssigned;
        std.debug.assert(owner == .composed_block or owner == .composed_cfg);
        transaction.machine.selection_owner = owner;
        transaction.state = .committed;
    }

    fn rollbackUnlessCommitted(transaction: *SelectionTransaction) void {
        if (transaction.state == .active) transaction.rollback();
    }

    fn rollback(transaction: *SelectionTransaction) void {
        if (transaction.state != .active) return;
        std.debug.assert(transaction.machine.instructions.items.len >= transaction.instruction_len);
        std.debug.assert(transaction.machine.owned_labels.items.len >= transaction.owned_labels_len);

        transaction.machine.instructions.items.len = transaction.instruction_len;
        for (transaction.machine.owned_labels.items[transaction.owned_labels_len..]) |label| {
            transaction.allocator.free(label);
        }
        transaction.machine.owned_labels.items.len = transaction.owned_labels_len;
        transaction.machine.name = transaction.snapshot.name;
        transaction.machine.symbol_linkage = transaction.snapshot.symbol_linkage;
        transaction.machine.symbol_visibility = transaction.snapshot.symbol_visibility;
        transaction.machine.symbol_alignment = transaction.snapshot.symbol_alignment;
        transaction.machine.ret_ty = transaction.snapshot.ret_ty;
        transaction.machine.codegen_path = transaction.snapshot.codegen_path;
        transaction.machine.entry_xmm_defined_bits = transaction.snapshot.entry_xmm_defined_bits;
        transaction.machine.selection_owner = transaction.snapshot.selection_owner;
        transaction.address_dependencies = transaction.address_dependencies_snapshot;
        transaction.state = .rolled_back;
    }

    fn assertMachineFunctionFieldsCovered() void {
        comptime {
            for (@typeInfo(MachineFunction).@"struct".field_names) |name| {
                if (!std.mem.eql(u8, name, "name") and
                    !std.mem.eql(u8, name, "symbol_linkage") and
                    !std.mem.eql(u8, name, "symbol_visibility") and
                    !std.mem.eql(u8, name, "symbol_alignment") and
                    !std.mem.eql(u8, name, "ret_ty") and
                    !std.mem.eql(u8, name, "instructions") and
                    !std.mem.eql(u8, name, "owned_labels") and
                    !std.mem.eql(u8, name, "codegen_path") and
                    !std.mem.eql(u8, name, "entry_xmm_defined_bits") and
                    !std.mem.eql(u8, name, "selection_owner"))
                {
                    @compileError("SelectionTransaction must cover new MachineFunction field: " ++ name);
                }
            }
        }
    }
};

// Existing composed forms retain their established machine stream. Private
// edge/operand normalization is a fallback after transactional lowering rejects
// the original form; failed attempts cannot publish instructions or ownership.
fn tryOriginalComposedForm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    inspected: SelectionResult,
    observer: ?*Observer,
) !bool {
    try semantic_normalization.check(function);
    switch (inspected) {
        .selected => return false,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter, .unsupported_control_flow => {},
            else => return false,
        },
    }
    if (function.blocks.items.len > 1) {
        return (try tryLowerComposedCfgFailClosed(allocator, machine, function, module_context, observer)) == .selected;
    }
    return (try tryLowerComposedBlockFailClosed(allocator, machine, function, module_context, observer)) == .selected;
}

fn tryLowerComposedBlockFailClosed(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    observer: ?*Observer,
) !SelectionResult {
    var transaction = SelectionTransaction.begin(allocator, machine);
    defer transaction.rollbackUnlessCommitted();
    errdefer transaction.rollback();
    const result = composed_selector.tryLowerComposedBlockObserved(allocator, machine, function, module_context, &transaction.address_dependencies, observer) catch |err| {
        return switch (err) {
            error.UnsupportedCodegenValue => unsupported(.{ .unsupported_value = "composed-block-unsupported-value" }),
            error.ValueUseForwardPlanMissing => unsupported(.{ .no_emitter = "value-use-forward-plan-missing" }),
            error.UnsupportedLongDoubleAbi => unsupported(.{ .no_emitter = "composed-block-long-double-abi" }),
            else => err,
        };
    };
    switch (result) {
        .selected => try transaction.commit(.composed_block),
        .unsupported => {},
    }
    return result;
}

fn tryLowerComposedCfgFailClosed(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    observer: ?*Observer,
) !SelectionResult {
    var transaction = SelectionTransaction.begin(allocator, machine);
    defer transaction.rollbackUnlessCommitted();
    errdefer transaction.rollback();
    const result = composed_selector.tryLowerComposedCfgObserved(allocator, machine, function, module_context, &transaction.address_dependencies, observer) catch |err| {
        return switch (err) {
            error.UnsupportedCodegenValue => unsupported(.{ .unsupported_value = "stage2-unsupported-value" }),
            error.ValueUseForwardPlanMissing => unsupported(.{ .no_emitter = "value-use-forward-plan-missing" }),
            error.UnsupportedLongDoubleAbi => unsupported(.{ .no_emitter = "stage2-long-double-abi" }),
            else => err,
        };
    };
    switch (result) {
        .selected => try transaction.commit(.composed_cfg),
        .unsupported => {},
    }
    return result;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}

test "generic cfg selector selection transaction rollback restores address dependency domain exactly" {
    var machine = MachineFunction.init("selection-address-dependency-rollback", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    machine.symbol_linkage = .internal;
    machine.symbol_visibility = .hidden;
    machine.symbol_alignment = 32;

    var initial: AddressDependencyDomain = .{};
    try initial.replaceAddress("original-owner", &.{
        .{ .name = "original-index", .identity_type = .integer, .role = .index },
    });
    var transaction = SelectionTransaction.beginWithAddressDependencies(std.testing.allocator, &machine, initial);
    const snapshot = transaction.address_dependencies_snapshot;
    machine.symbol_linkage = .external;
    machine.symbol_visibility = .default;
    machine.symbol_alignment = 128;
    try transaction.address_dependencies.replaceAddress("owner", &.{
        .{ .name = "index", .identity_type = .integer, .role = .index },
    });
    transaction.rollback();

    try std.testing.expect(transaction.address_dependencies.eql(&snapshot));
    try std.testing.expectEqual(@as(usize, 1), transaction.address_dependencies.count());
    try std.testing.expectEqual(ir.FunctionLinkage.internal, machine.symbol_linkage);
    try std.testing.expectEqual(ir.FunctionVisibility.hidden, machine.symbol_visibility);
    try std.testing.expectEqual(@as(u32, 32), machine.symbol_alignment);
}
