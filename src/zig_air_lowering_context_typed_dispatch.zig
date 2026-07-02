const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");

pub fn lowerTypedInstruction(self: anytype, instruction: air_export.TypedInstruction) !void {
    self.lowerTypedInstructionImpl(instruction) catch |err| switch (err) {
        air_model.LowerError.UnsupportedAir => {
            self.recordTypedV2Fallback(instruction);
            return err;
        },
        else => return err,
    };
}

pub fn lowerTypedInstructionImpl(self: anytype, instruction: air_export.TypedInstruction) !void {
    const capability = self.typedInstructionCapability(instruction);
    if (capability.status == .ignored_metadata) return;
    if (!air_capabilities.typedV2CanLower(capability)) return air_model.LowerError.UnsupportedAir;
    switch (capability.lowerer) {
        .typed_v2_cfg => try self.lowerTypedCfgInstruction(instruction),
        .typed_v2_semantic => try self.lowerTypedSemanticInstruction(instruction),
        .call_abi => try self.lowerTypedCall(instruction),
        .backend_runtime => try self.lowerTypedBackendRuntimeInstruction(instruction),
        .none, .ignore, .boundary => return air_model.LowerError.UnsupportedAir,
    }
}

pub fn lowerTypedSemanticInstruction(self: anytype, instruction: air_export.TypedInstruction) !void {
    const lowered = switch (air_capabilities.semanticDomainForOpcode(instruction.opcode)) {
        .scalar => try self.lowerTypedScalarSemanticInstruction(instruction),
        .memory => try self.lowerTypedMemorySemanticInstruction(instruction),
        .optional => try self.lowerTypedOptionalSemanticInstruction(instruction),
        .error_union => try self.lowerTypedErrorUnionSemanticInstruction(instruction),
        .union_tag => try self.lowerTypedUnionTagSemanticInstruction(instruction),
        .pointer_aggregate => try self.lowerTypedPointerAggregateSemanticInstruction(instruction),
        .aggregate => try self.lowerTypedAggregateSemanticInstruction(instruction),
        .vector => try self.lowerTypedVectorSemanticInstruction(instruction),
        .none => false,
    };
    if (!lowered) return air_model.LowerError.UnsupportedAir;
}

pub fn lowerTypedBackendRuntimeInstruction(self: anytype, instruction: air_export.TypedInstruction) !void {
    _ = self;
    _ = instruction;
    return air_model.LowerError.UnsupportedAir;
}

pub fn recordTypedV2Fallback(self: anytype, instruction: air_export.TypedInstruction) void {
    const slot = self.typed_v2_fallback orelse return;
    if (slot.* != null) return;
    const capability = self.typedInstructionCapability(instruction);
    slot.* = .{
        .function = self.air_function.name,
        .opcode = instruction.opcode,
        .data_kind = instruction.data_kind,
        .reason = if (air_capabilities.typedV2CanLower(capability))
            "lowering_validation"
        else
            air_capabilities.typedV2FallbackReason(capability),
    };
}

pub fn typedInstructionCapability(self: anytype, instruction: air_export.TypedInstruction) air_capabilities.OpcodeCapability {
    if (self.typed_view) |view| return view.capability(instruction);
    return air_capabilities.opcodeCapability(instruction.opcode);
}
