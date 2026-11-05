const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");
const inspection = @import("generic_cfg/inspection.zig");
const legacy_lowering = @import("generic_cfg/legacy_lowering.zig");
const stage2_planning = @import("generic_cfg/stage2_planning.zig");
const composed_selector = @import("generic_cfg/composed_selector.zig");
const address_dependencies = @import("generic_cfg/composed_selector_address_dependencies.zig");
const abi_legalization = @import("generic_cfg/abi_legalization.zig");
const narrow_abi = @import("generic_cfg/narrow_abi.zig");
const scalar_forms = @import("generic_cfg/scalar_forms.zig");
const switch_phi_edges = @import("generic_cfg/switch_phi_edges.zig");
const word_pair_values = @import("generic_cfg/word_pair_values.zig");
const word_pair_memory = @import("generic_cfg/word_pair_memory.zig");
const padded_frame = @import("generic_cfg/padded_frame.zig");
const global_memory = @import("generic_cfg/global_memory.zig");

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
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .alloca and !inst.kind.alloca.isSingleObject())
            return .{ .unsupported = .{ .no_emitter = "alloca-count" } };
    };
    const inspected = inspection.inspectFunctionWithContext(function, module_context);
    if (try legacy_lowering.tryLower(allocator, machine, function)) {
        if (machine.selection_owner != .unassigned) return error.SelectionOwnerAlreadyAssigned;
        machine.selection_owner = .legacy_envelope;
        return .selected;
    }
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    if (try scalar_forms.legalize(arena.allocator(), function)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try switch_phi_edges.legalize(arena.allocator(), function)) |legalized| {
        if (try tryOriginalComposedForm(allocator, machine, function, module_context, inspected)) return .selected;
        const selected = try tryLowerWithContext(allocator, machine, legalized, module_context);
        if (selected == .selected) try switch_phi_edges.retainLabels(allocator, machine, legalized.blocks.items[function.blocks.items.len..]);
        return selected;
    }
    if (try narrow_abi.legalize(arena.allocator(), function)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try abi_legalization.integerPair(arena.allocator(), function)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try abi_legalization.paddedHalf(arena.allocator(), function)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try word_pair_values.legalize(arena.allocator(), function, module_context)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try word_pair_memory.legalize(arena.allocator(), function, module_context)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try padded_frame.legalize(arena.allocator(), function, module_context)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try padded_frame.legalizeStorage(arena.allocator(), function, module_context)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
    if (try global_memory.legalize(arena.allocator(), function, module_context)) |legalized| {
        return tryLowerWithContext(allocator, machine, legalized, module_context);
    }
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
                    const stage_two = try analyzeStageTwoNoSpillEnvelope(allocator, function);
                    if (stage_two.exceedsSpillEnvelope()) return .{ .unsupported = .{ .no_spill_envelope = "stage2-register-pressure" } };
                    return tryLowerComposedCfgFailClosed(allocator, machine, function, module_context);
                }
                return inspected;
            },
            else => return inspected,
        },
    }
    if (function.blocks.items.len > 1) {
        const stage_two = try analyzeStageTwoNoSpillEnvelope(allocator, function);
        if (stage_two.exceedsSpillEnvelope()) return .{ .unsupported = .{ .no_spill_envelope = "stage2-register-pressure" } };
        return tryLowerComposedCfgFailClosed(allocator, machine, function, module_context);
    }
    switch (try tryLowerComposedBlockFailClosed(allocator, machine, function, module_context)) {
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
) !bool {
    switch (inspected) {
        .selected => return false,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter, .unsupported_control_flow => {},
            else => return false,
        },
    }
    if (function.blocks.items.len > 1) {
        const pressure = try analyzeStageTwoNoSpillEnvelope(allocator, function);
        if (pressure.exceedsSpillEnvelope()) return false;
        return (try tryLowerComposedCfgFailClosed(allocator, machine, function, module_context)) == .selected;
    }
    return (try tryLowerComposedBlockFailClosed(allocator, machine, function, module_context)) == .selected;
}

fn tryLowerComposedBlockFailClosed(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
) !SelectionResult {
    var transaction = SelectionTransaction.begin(allocator, machine);
    defer transaction.rollbackUnlessCommitted();
    errdefer transaction.rollback();
    const result = composed_selector.tryLowerComposedBlockWithContextAndAddressDependencies(allocator, machine, function, module_context, &transaction.address_dependencies) catch |err| {
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
) !SelectionResult {
    var transaction = SelectionTransaction.begin(allocator, machine);
    defer transaction.rollbackUnlessCommitted();
    errdefer transaction.rollback();
    const result = composed_selector.tryLowerComposedCfgWithContextAndAddressDependencies(allocator, machine, function, module_context, &transaction.address_dependencies) catch |err| {
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
