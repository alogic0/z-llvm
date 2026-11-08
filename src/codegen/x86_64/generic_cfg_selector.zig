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
    const profiling = @import("../../compilation_profile.zig");
    const optional = @import("generic_cfg/optional_legalization.zig");
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pending_labels: std.ArrayList([]const ir.BasicBlock) = .empty;
    var function = source;
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
                if (rewrite.retain_labels)
                    try pending_labels.append(arena.allocator(), rewrite.function.blocks.items[function.blocks.items.len..]);
                function = rewrite.function;
                continue;
            }
            Observer.reset(observer);
            break :blk try selectReady(allocator, machine, function, module_context, inspected, observer);
        };
        if (result == .selected) {
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

fn selectReady(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
    inspected: SelectionResult,
    observer: ?*Observer,
) !SelectionResult {
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

    var initial: AddressDependencyDomain = .{};
    try initial.replaceAddress("original-owner", &.{
        .{ .name = "original-index", .identity_type = .integer, .role = .index },
    });
    var transaction = SelectionTransaction.beginWithAddressDependencies(std.testing.allocator, &machine, initial);
    const snapshot = transaction.address_dependencies_snapshot;
    machine.symbol_linkage = .external;
    machine.symbol_visibility = .default;
    try transaction.address_dependencies.replaceAddress("owner", &.{
        .{ .name = "index", .identity_type = .integer, .role = .index },
    });
    transaction.rollback();

    try std.testing.expect(transaction.address_dependencies.eql(&snapshot));
    try std.testing.expectEqual(@as(usize, 1), transaction.address_dependencies.count());
    try std.testing.expectEqual(ir.FunctionLinkage.internal, machine.symbol_linkage);
    try std.testing.expectEqual(ir.FunctionVisibility.hidden, machine.symbol_visibility);
}
