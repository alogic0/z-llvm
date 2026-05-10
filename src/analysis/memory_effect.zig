const ir = @import("../ir.zig");

pub const Effect = enum {
    none,
    readonly_load,
    memory_write,
    volatile_or_atomic_barrier,
    unknown,

    pub fn mayReadMemory(effect: Effect) bool {
        return switch (effect) {
            .readonly_load, .volatile_or_atomic_barrier, .unknown => true,
            .none, .memory_write => false,
        };
    }

    pub fn mayWriteMemory(effect: Effect) bool {
        return switch (effect) {
            .memory_write, .volatile_or_atomic_barrier, .unknown => true,
            .none, .readonly_load => false,
        };
    }

    pub fn hasSideEffects(effect: Effect) bool {
        return switch (effect) {
            .none, .readonly_load => false,
            .memory_write, .volatile_or_atomic_barrier, .unknown => true,
        };
    }
};

pub fn classify(instruction: ir.Instruction) Effect {
    return switch (instruction.kind) {
        .load => |load| if (load.attrs.isBarrier()) .volatile_or_atomic_barrier else .readonly_load,
        .store => |store| if (store.attrs.isBarrier()) .volatile_or_atomic_barrier else .memory_write,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep => .none,
        .call => .unknown,
    };
}

pub fn hasSideEffects(instruction: ir.Instruction) bool {
    return classify(instruction).hasSideEffects();
}

pub fn mayReadMemory(instruction: ir.Instruction) bool {
    return classify(instruction).mayReadMemory();
}

pub fn mayWriteMemory(instruction: ir.Instruction) bool {
    return classify(instruction).mayWriteMemory();
}
