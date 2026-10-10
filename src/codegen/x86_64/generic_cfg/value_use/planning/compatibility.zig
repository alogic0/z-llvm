const selector_types = @import("../../selector_types.zig");
const Types = @import("../model.zig");
const planning_model = @import("model.zig");

const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualRegClass = selector_types.VirtualRegClass;

pub fn validateStorePointerOperand(
    request: *const Types.StoredRequest,
    allow_stack_object: bool,
) !void {
    if (request.expected.ty != .ptr or request.expected.pointer_address_space != 0)
        return error.ValueUsePreparedActionFormMismatch;
    if (request.form == .pointer) {
        if (request.expected.register_class != .gpr64 and
            request.expected.register_class != .stack_pointer)
            return error.ValueUsePreparedActionFormMismatch;
        return;
    }
    if (allow_stack_object and request.form == .stack_object_address and
        request.expected.register_class == .stack_object) return;
    return error.ValueUsePreparedActionFormMismatch;
}
pub fn validateStoreI64ValueOperand(request: *const Types.StoredRequest) !void {
    const is_i64_width = switch (request.expected.ty) {
        .int => |bits| bits > 32 and bits <= 64,
        else => false,
    };
    if (request.form != .gpr64 or !is_i64_width or
        request.expected.register_class != .gpr64)
        return error.ValueUsePreparedActionFormMismatch;
}
pub fn validateStoreStackObjectOperand(request: *const Types.StoredRequest) !void {
    if (request.form != .stack_object_address or request.expected.ty != .ptr or
        request.expected.register_class != .stack_object or
        request.expected.pointer_address_space != 0)
        return error.ValueUsePreparedActionFormMismatch;
}
pub fn validateMemcpyPointerOperand(request: *const Types.StoredRequest) !void {
    if (request.form != .memcpy_pointer or request.expected.ty != .ptr or
        request.expected.register_class != .gpr64 or
        request.expected.pointer_address_space != 0)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
}
pub fn validateMemcpyLengthOperand(request: *const Types.StoredRequest) !void {
    if (request.form != .memcpy_length or !request.expected.ty.eql(.{ .int = 64 }) or
        request.expected.register_class != .gpr64 or request.expected.pointer_address_space != null)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
}
pub fn validateI64StorePointer(pointer: ValueLoc) !void {
    switch (pointer) {
        .arg64, .scratch64, .spill64 => {},
        else => return error.ValueUseStorePointerFormUnsupported,
    }
}
pub fn validateStackPointerStoreViews(source: ValueLoc, destination: ValueLoc) !void {
    const source_stack = switch (source) {
        .stack_scalar => |stack| stack,
        else => return error.ValueUseStorePointerFormUnsupported,
    };
    const destination_stack = switch (destination) {
        .stack_scalar => |stack| stack,
        else => return error.ValueUseStorePointerFormUnsupported,
    };
    _ = source_stack;
    if (destination_stack.kind != .integer or destination_stack.bits != 64) {
        return error.ValueUseStorePointerFormUnsupported;
    }
}
pub fn validateCopyActionForm(
    form: Types.UseForm,
    destination: Types.CopyDestination,
) !void {
    const valid = switch (form) {
        .gpr32 => destination == .gpr32 or destination == .eax,
        .gpr64, .pointer, .stack_object_address => destination == .gpr64 or destination == .rax,
        .stack_f32_pair_byte_address,
        .pair_low_high,
        .pair_high_low,
        .branch_condition,
        .switch_condition,
        .memcpy_pointer,
        .memcpy_length,
        .load_address,
        .scratch_compare_operand,
        .current_home_eq_zero_operand,
        .setcc_eax_compare_operand,
        .current_home_sign_bit_operand,
        .i128_icmp_pair_operand,
        .pair_low_scalar_cast_operand,
        .accumulator_scalar_cast_operand,
        .sign_extend_scratch_operand,
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        .named_scalar_operand,
        => false,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUsePreparedActionFormMismatch;
}
pub fn validateBindingCompatibility(
    binding: ValueBinding,
    request: *const Types.StoredRequest,
    current: ValueLoc,
) !void {
    if (request.form == .scratch_compare_operand) {
        try validateScratchCompareBinding(binding, request.expected, current);
        return;
    }
    if (request.form == .current_home_eq_zero_operand) {
        // The canonical post-preamble home is the authority. Resolution and
        // liveness happen now; width/location classification is intentionally
        // deferred until the action refreshes after accumulator preservation.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .setcc_eax_compare_operand) {
        // The action re-resolves after its live-accumulator preamble. Only
        // semantic typing is stable at seal; canonical width/home admission
        // is request-scoped and happens after that relocation.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .current_home_sign_bit_operand) {
        // Width and canonical-home admission occur after both action-owned
        // preservation phases. Seal validates only the stable semantic type.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .i128_icmp_pair_operand) {
        // The pair wrapper owns the strict post-preamble home fence. Seal
        // checks only the stable semantic i128 request and its binding width.
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
            return error.ValueUseI128PairWidthUnsupported;
        return;
    }
    if (request.form == .pair_low_scalar_cast_operand) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .accumulator_scalar_cast_operand) {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        const valid_class = if (bits <= 32)
            binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64
        else
            binding.vreg.class == .gpr64;
        if (!valid_class or binding.vreg.bits < bits)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .sign_extend_scratch_operand) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr32 or binding.vreg.bits < 32)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .immediate_rhs_scalar_operand or
        request.form == .immediate_lhs_scalar_operand or
        request.form == .named_scalar_operand)
    {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        const valid_class = if (bits <= 32)
            binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64
        else
            binding.vreg.class == .gpr64;
        if (!valid_class or binding.vreg.bits < bits)
            return if (request.form == .named_scalar_operand)
                error.ValueUseNamedScalarWidthUnsupported
            else
                error.ValueUseImmediateScalarWidthUnsupported;
        return;
    }
    if (request.form == .load_address) {
        try validateExpectedType(request.expected, request.form);
        const action = request.prepared_action orelse
            return error.ValueUsePreparedActionMissing;
        switch (action) {
            .load_scalar => |load| switch (load.kind) {
                .ordinary => try validateOrdinaryLoadHome(binding, current, load.bits, false, load.is_ptr),
                .readonly_pointer => try validateReadOnlyPointerLoadHome(binding, current),
            },
            .load_readonly_pair => try validateReadOnlyPointerLoadHome(binding, current),
            .load_stack_i128_alias => try validateOrdinaryLoadHome(binding, current, 128, true, false),
            .load_readonly_table_i16 => try validateReadOnlyTableLoadHome(binding, current),
            else => return error.ValueUsePreparedActionFormMismatch,
        }
        return;
    }
    if (request.form == .memcpy_pointer or request.form == .memcpy_length) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.bits < 64) return if (request.form == .memcpy_pointer)
            error.ValueUseMemcpyPointerWidthMismatch
        else
            error.ValueUseMemcpyLengthWidthMismatch;
        const accepted_class = binding.vreg.class == .gpr64 or binding.vreg.class == .gpr128;
        const accepted_home = switch (current) {
            .arg64, .scratch64, .rax, .spill64, .arg128, .scratch128 => true,
            else => false,
        };
        if (!accepted_class or !accepted_home)
            return if (request.form == .memcpy_pointer)
                error.ValueUseMemcpyPointerHomeUnsupported
            else
                error.ValueUseMemcpyLengthHomeUnsupported;
        return;
    }
    if (request.form == .branch_condition) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.bits < 1) return error.ValueUseBranchConditionWidthMismatch;
        const accepted = switch (current) {
            .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
            .spill64 => binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64,
            else => false,
        };
        if (!accepted) return error.ValueUseBranchConditionHomeUnsupported;
        return;
    }
    if (request.form == .switch_condition) {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        if (binding.vreg.bits < bits) return error.ValueUseSwitchConditionWidthMismatch;
        const accepted = switch (current) {
            .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
            .arg64, .scratch64, .rax, .spill64 => binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64,
            .arg128, .scratch128 => binding.vreg.class == .gpr128,
            else => false,
        };
        if (!accepted) return error.ValueUseSwitchConditionHomeUnsupported;
        return;
    }
    if (binding.vreg.class == request.expected.register_class) {
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form != .gpr32 or request.expected.register_class != .gpr32 or
        request.expected.ty != .int or request.expected.ty.int == 0 or
        request.expected.ty.int > 32 or binding.vreg.class != .gpr64 or
        binding.vreg.bits < request.expected.ty.int or !hasLow32View(current))
    {
        return error.ValueUseRegisterClassMismatch;
    }
    try validateExpectedType(request.expected, request.form);
}
fn validateScratchCompareBinding(
    binding: ValueBinding,
    expected: Types.Expected,
    current: ValueLoc,
) !void {
    try validateExpectedType(expected, .scratch_compare_operand);
    const bits: u16 = switch (expected.ty) {
        .int => |value| value,
        .ptr => 64,
        else => unreachable,
    };
    if (binding.vreg.bits < bits) return error.ValueUseScratchCompareWidthMismatch;
    const accepted = if (bits <= 32) switch (current) {
        .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr32 or
            binding.vreg.class == .gpr64,
        .arg128, .scratch128 => binding.vreg.class == .gpr128,
        else => false,
    } else switch (current) {
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr64,
        .arg128, .scratch128 => binding.vreg.class == .gpr128,
        else => false,
    };
    if (!accepted) return error.ValueUseScratchCompareHomeUnsupported;
}
fn validateOrdinaryLoadHome(
    binding: ValueBinding,
    current: ValueLoc,
    bits: u16,
    alias_i128: bool,
    is_ptr: bool,
) !void {
    switch (current) {
        .stack_scalar => |stack| {
            if (alias_i128 or binding.vreg.class != .stack_object or stack.kind != .integer or
                stack.bits != bits or (bits != 8 and bits != 64))
            {
                return error.ValueUseLoadOrdinaryStackWidth;
            }
        },
        .stack128 => {
            if (!alias_i128 or binding.vreg.class != .stack_object)
                return error.ValueUseLoadOrdinaryStackWidth;
        },
        .stack_i32_array => {
            if (alias_i128 or binding.vreg.class != .stack_object or bits != 32)
                return error.ValueUseLoadOrdinaryStackArrayWidth;
        },
        .stack_i32_ptr => {
            if (alias_i128 or binding.vreg.class != .stack_pointer or bits != 32)
                return error.ValueUseLoadOrdinaryStackArrayWidth;
        },
        .arg64, .scratch64, .spill64 => {
            if (alias_i128 or binding.vreg.class != .gpr64 or binding.vreg.bits < 64 or
                (!is_ptr and bits != 8 and bits != 32 and bits != 64) or (is_ptr and bits != 64))
            {
                return error.ValueUseLoadOrdinaryPointerWidth;
            }
        },
        else => return error.ValueUseLoadOrdinaryPointerRejected,
    }
}
fn validateReadOnlyPointerLoadHome(binding: ValueBinding, current: ValueLoc) !void {
    switch (current) {
        .arg64, .scratch64, .spill64 => if (binding.vreg.class != .gpr64 or binding.vreg.bits < 64)
            return error.ValueUseLoadReadonlyPointerProvenance,
        else => return error.ValueUseLoadReadonlyPointerProvenance,
    }
}
fn validateReadOnlyTableLoadHome(binding: ValueBinding, current: ValueLoc) !void {
    switch (current) {
        .readonly_table_ptr => |ptr| {
            if (binding.vreg.class != .stack_pointer)
                return error.ValueUseLoadReadonlyTableType;
            if (!ptr.shape.allowsOffset(ptr.offset))
                return error.ValueUseLoadReadonlyTableOffset;
        },
        else => return error.ValueUseLoadReadonlyTableType,
    }
}
fn hasLow32View(loc: ValueLoc) bool {
    return switch (loc) {
        .arg64, .scratch64, .rax, .spill64 => true,
        else => false,
    };
}
pub fn validateExpectedType(expected: Types.Expected, form: Types.UseForm) !void {
    switch (form) {
        .gpr32 => if (expected.ty != .int or expected.ty.int == 0 or expected.ty.int > 32 or expected.register_class != .gpr32)
            return error.ValueUseTypeMismatch,
        .gpr64 => if (expected.ty != .int or expected.ty.int <= 32 or expected.ty.int > 64 or expected.register_class != .gpr64)
            return error.ValueUseTypeMismatch,
        .pointer => {
            if (expected.ty != .ptr or
                (expected.register_class != .gpr64 and expected.register_class != .stack_pointer) or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .stack_f32_pair_byte_address => {
            if (expected.ty != .ptr or
                expected.register_class != .stack_pointer or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .stack_object_address => {
            if (expected.ty != .ptr or
                expected.register_class != .stack_object or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .pair_low_high, .pair_high_low => if (!expected.ty.eql(.{ .int = 128 }) or expected.register_class != .gpr128)
            return error.ValueUseTypeMismatch,
        .branch_condition => if (!expected.ty.eql(.{ .int = 1 }) or expected.register_class != .gpr32)
            return error.ValueUseTypeMismatch,
        .switch_condition => if (expected.ty != .int or expected.ty.int == 0 or
            expected.ty.int > 32 or expected.register_class != .gpr32)
        {
            return error.ValueUseTypeMismatch;
        },
        .memcpy_pointer => {
            if (expected.ty != .ptr or expected.register_class != .gpr64 or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .memcpy_length => if (!expected.ty.eql(.{ .int = 64 }) or expected.register_class != .gpr64)
            return error.ValueUseTypeMismatch,
        .load_address => if (expected.ty != .ptr or expected.register_class != .stack_pointer or
            expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
        {
            return error.ValueUseTypeMismatch;
        },
        .scratch_compare_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            .ptr => {
                if (expected.register_class != .gpr64 or
                    expected.pointer_address_space == null or
                    expected.pointer_address_space.? != 0)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .current_home_eq_zero_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .setcc_eax_compare_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .current_home_sign_bit_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .i128_icmp_pair_operand => if (!expected.ty.eql(.{ .int = 128 }) or
            expected.register_class != .gpr128 or
            expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .pair_low_scalar_cast_operand => if (!expected.ty.eql(.{ .int = 128 }) or
            expected.register_class != .gpr128 or expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .accumulator_scalar_cast_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .sign_extend_scratch_operand => if (!expected.ty.eql(.{ .int = 32 }) or
            expected.register_class != .gpr32 or expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .immediate_rhs_scalar_operand, .immediate_lhs_scalar_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .named_scalar_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                    return error.ValueUseTypeMismatch;
            },
            else => return error.ValueUseTypeMismatch,
        },
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}
pub fn validateSourceView(loc: ValueLoc, form: Types.UseForm) !void {
    switch (form) {
        .gpr32 => switch (loc) {
            .arg32, .scratch32, .arg64, .scratch64, .eax, .rax, .spill64 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .gpr64 => switch (loc) {
            .arg64, .scratch64, .rax, .spill64 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .pointer, .stack_object_address => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr => {},
            .stack_f32_pair_ptr, .stack128_value => return error.ValueUseUnsupportedAddressForm,
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .stack_f32_pair_byte_address => switch (loc) {
            .stack_f32_pair_ptr => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        .pair_low_high, .pair_high_low => switch (loc) {
            .arg128, .scratch128, .spill128 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .branch_condition => switch (loc) {
            .eax, .arg32, .scratch32, .spill64 => {},
            else => return error.ValueUseBranchConditionHomeUnsupported,
        },
        .switch_condition => switch (loc) {
            .eax,
            .rax,
            .arg32,
            .scratch32,
            .arg64,
            .scratch64,
            .arg128,
            .scratch128,
            .spill64,
            => {},
            else => return error.ValueUseSwitchConditionHomeUnsupported,
        },
        .memcpy_pointer, .memcpy_length => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .arg128, .scratch128 => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        .load_address => switch (loc) {
            .arg64,
            .scratch64,
            .spill64,
            .stack_scalar,
            .stack128,
            .stack_i32_array,
            .stack_i32_ptr,
            .readonly_table_ptr,
            => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseLoadAddressHomeUnsupported,
        },
        .scratch_compare_operand => switch (loc) {
            .eax,
            .rax,
            .arg32,
            .scratch32,
            .arg64,
            .scratch64,
            .arg128,
            .scratch128,
            .spill64,
            => {},
            else => return error.ValueUseScratchCompareHomeUnsupported,
        },
        // The action must inspect the canonical home only after the accepted
        // live-accumulator preamble. No home is admitted by this generic
        // validation layer.
        .current_home_eq_zero_operand => {},
        // Canonical admission occurs after the action-owned preamble. Pair
        // and spill128 homes are rejected there, preserving the O2-6 frontier.
        .setcc_eax_compare_operand => {},
        // The action owns both preservation phases and classifies the
        // canonical i32/i64 home only after re-resolution.
        .current_home_sign_bit_operand => {},
        // Strict pair-home admission follows the established preamble and
        // canonical refresh inside the two closed wrapper actions. Their
        // exact semantic classifiers fence the admitted spill128 view.
        .i128_icmp_pair_operand => {},
        .pair_low_scalar_cast_operand,
        .accumulator_scalar_cast_operand,
        .sign_extend_scratch_operand,
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        .named_scalar_operand,
        => {},
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}
