const ir = @import("../ir.zig");

pub const Effect = enum {
    none,
    side_effect,
    readonly_load,
    readonly_side_effect,
    memory_write,
    volatile_or_atomic_barrier,
    unknown,

    pub fn mayReadMemory(effect: Effect) bool {
        return switch (effect) {
            .readonly_load, .readonly_side_effect, .volatile_or_atomic_barrier, .unknown => true,
            .none, .side_effect, .memory_write => false,
        };
    }

    pub fn mayWriteMemory(effect: Effect) bool {
        return switch (effect) {
            .memory_write, .volatile_or_atomic_barrier, .unknown => true,
            .none, .side_effect, .readonly_load, .readonly_side_effect => false,
        };
    }

    pub fn hasSideEffects(effect: Effect) bool {
        return switch (effect) {
            .none, .readonly_load => false,
            .side_effect, .readonly_side_effect, .memory_write, .volatile_or_atomic_barrier, .unknown => true,
        };
    }
};

pub const BarrierKind = enum {
    none,
    @"volatile",
    atomic,
    inline_asm,
};

pub fn classify(instruction: ir.Instruction) Effect {
    return switch (instruction.kind) {
        .load => |load| if (load.attrs.isBarrier()) .volatile_or_atomic_barrier else .readonly_load,
        .store => |store| if (store.attrs.isBarrier()) .volatile_or_atomic_barrier else .memory_write,
        .atomicrmw, .cmpxchg, .fence => .volatile_or_atomic_barrier,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => .none,
        .call => |call| if (call.inline_asm) |inline_asm| classifyInlineAsm(inline_asm) else .unknown,
    };
}

pub fn barrierKind(instruction: ir.Instruction) BarrierKind {
    return switch (instruction.kind) {
        .load => |load| memoryBarrierKind(load.attrs),
        .store => |store| memoryBarrierKind(store.attrs),
        .atomicrmw, .cmpxchg, .fence => .atomic,
        .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => .none,
        .call => |call| if (call.inline_asm) |inline_asm|
            if (inline_asm.may_load or inline_asm.may_store) .inline_asm else .none
        else
            .none,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep => .none,
    };
}

fn classifyInlineAsm(inline_asm: ir.InlineAsm) Effect {
    if (inline_asm.may_load and inline_asm.may_store) return .volatile_or_atomic_barrier;
    if (inline_asm.may_store) return .memory_write;
    if (inline_asm.may_load) return .readonly_side_effect;
    if (inline_asm.sideeffect) return .side_effect;
    return .unknown;
}

fn memoryBarrierKind(attrs: ir.MemoryAttrs) BarrierKind {
    if (attrs.is_volatile) return .@"volatile";
    if (attrs.isAtomic()) return .atomic;
    return .none;
}

pub fn hasSideEffects(instruction: ir.Instruction) bool {
    return classify(instruction).hasSideEffects();
}

pub fn mayReadOrWriteMemory(instruction: ir.Instruction) bool {
    const effect = classify(instruction);
    return effect.mayReadMemory() or effect.mayWriteMemory();
}

pub fn mayReadMemory(instruction: ir.Instruction) bool {
    return classify(instruction).mayReadMemory();
}

pub fn mayWriteMemory(instruction: ir.Instruction) bool {
    return classify(instruction).mayWriteMemory();
}

pub fn mayThrow(instruction: ir.Instruction) bool {
    return switch (instruction.kind) {
        .call => |call| call.inline_asm == null,
        else => false,
    };
}

pub fn mayTrap(instruction: ir.Instruction) bool {
    return switch (instruction.kind) {
        .binary => |binary| binaryMayTrap(binary),
        .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .call => false,
        .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep => false,
    };
}

pub fn isSafeToDelete(instruction: ir.Instruction) bool {
    return !hasSideEffects(instruction) and !mayThrow(instruction);
}

pub fn isSafeToSpeculativelyExecute(instruction: ir.Instruction) bool {
    return !mayReadOrWriteMemory(instruction) and
        !hasSideEffects(instruction) and
        !mayThrow(instruction) and
        !mayTrap(instruction);
}

fn binaryMayTrap(binary: ir.BinaryInst) bool {
    return switch (binary.op) {
        .udiv, .urem => switch (binary.rhs) {
            .int => |rhs| rhs == 0,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => true,
        },
        .sdiv, .srem => switch (binary.rhs) {
            .int => |rhs| rhs == 0 or rhs == -1,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => true,
        },
        .fadd, .fsub, .fmul, .fdiv, .frem, .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr => false,
    };
}
