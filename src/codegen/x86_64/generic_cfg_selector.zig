const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");
const inspection = @import("generic_cfg/inspection.zig");
const legacy_lowering = @import("generic_cfg/legacy_lowering.zig");
const stage2_planning = @import("generic_cfg/stage2_planning.zig");
const composed_selector = @import("generic_cfg/composed_selector.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;

pub const Diagnostic = inspection.Diagnostic;
pub const SelectionResult = inspection.SelectionResult;
pub const inspectFunction = inspection.inspectFunction;

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
    const inspected = inspection.inspectFunctionWithContext(function, module_context);
    if (try legacy_lowering.tryLower(allocator, machine, function)) return .selected;
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
    const composed_start_len = machine.instructions.items.len;
    switch (try tryLowerComposedBlockFailClosed(allocator, machine, function, module_context)) {
        .selected => return .selected,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => {
                machine.instructions.items.len = composed_start_len;
                if (shouldReportComposedNoEmitter(inspected)) return .{ .unsupported = diagnostic };
            },
            else => {
                machine.instructions.items.len = composed_start_len;
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

fn tryLowerComposedBlockFailClosed(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
) !SelectionResult {
    const start_len = machine.instructions.items.len;
    const result = composed_selector.tryLowerComposedBlockWithContext(allocator, machine, function, module_context) catch |err| {
        machine.instructions.items.len = start_len;
        return switch (err) {
            error.UnsupportedCodegenValue => unsupported(.{ .unsupported_value = "composed-block-unsupported-value" }),
            else => err,
        };
    };
    switch (result) {
        .selected => {},
        .unsupported => machine.instructions.items.len = start_len,
    }
    return result;
}

fn tryLowerComposedCfgFailClosed(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    module_context: ?*const x86_64_machine.ReadOnlyModuleContext,
) !SelectionResult {
    const start_len = machine.instructions.items.len;
    const result = composed_selector.tryLowerComposedCfgWithContext(allocator, machine, function, module_context) catch |err| {
        machine.instructions.items.len = start_len;
        return switch (err) {
            error.UnsupportedCodegenValue => unsupported(.{ .unsupported_value = "stage2-unsupported-value" }),
            else => err,
        };
    };
    switch (result) {
        .selected => {},
        .unsupported => machine.instructions.items.len = start_len,
    }
    return result;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
