const std = @import("std");
const core = @import("core.zig");

pub fn verify(module: core.Module) !void {
    for (module.functions.items) |function| {
        var defs = std.StringHashMap(core.Type).init(module.allocator);
        defer defs.deinit();

        for (function.params.items) |param| try defs.put(param.name, param.ty);

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                const result = instruction.result orelse continue;
                if (defs.contains(result)) return error.DuplicateDefinition;
                const result_ty = instruction.resultType() orelse return error.InstructionWithoutResultType;
                try defs.put(result, result_ty);
            }
        }

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                switch (instruction.kind) {
                    .binary => |binary| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyBinaryFlags(binary);
                        try verifyValue(defs, binary.ty, binary.lhs);
                        try verifyValue(defs, binary.ty, binary.rhs);
                    },
                    .cast => |cast| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyCast(cast);
                        try verifyValue(defs, cast.from_ty, cast.value);
                    },
                    .freeze => |freeze| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyValue(defs, freeze.ty, freeze.value);
                    },
                    .icmp => |icmp| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyValue(defs, icmp.operand_ty, icmp.lhs);
                        try verifyValue(defs, icmp.operand_ty, icmp.rhs);
                    },
                    .select => |select| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        if (!select.cond_ty.eql(.{ .int = 1 })) return error.SelectConditionTypeMismatch;
                        try verifyValue(defs, select.cond_ty, select.cond);
                        try verifyValue(defs, select.ty, select.true_value);
                        try verifyValue(defs, select.ty, select.false_value);
                    },
                    .phi => |phi| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        if (phi.incoming.items.len == 0) return error.EmptyPhi;
                        for (phi.incoming.items) |incoming| {
                            try verifyValue(defs, phi.ty, incoming.value);
                            try verifyBlockTarget(function, incoming.block);
                        }
                    },
                    .alloca => {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                    },
                    .load => |load| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyValue(defs, .ptr, load.ptr);
                        try verifyMemoryAttrs(load.attrs);
                    },
                    .store => |store| {
                        if (instruction.result != null) return error.StoreHasResult;
                        try verifyValue(defs, store.ty, store.value);
                        try verifyValue(defs, .ptr, store.ptr);
                        try verifyMemoryAttrs(store.attrs);
                    },
                    .gep => |gep| {
                        if (instruction.result == null) return error.InstructionNeedsResult;
                        try verifyValue(defs, .ptr, gep.ptr);
                        if (gep.indices.items.len == 0) return error.InvalidGetElementPtr;
                        for (gep.indices.items) |index| {
                            try verifyValue(defs, index.ty, index.value);
                        }
                    },
                }
            }

            const terminator = block.terminator orelse return error.BlockWithoutTerminator;
            switch (terminator) {
                .ret => |ret| {
                    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
                    if (ret.ty == .void) {
                        if (ret.value != null) return error.ReturnTypeMismatch;
                    } else {
                        try verifyValue(defs, ret.ty, ret.value orelse return error.InvalidRet);
                    }
                },
                .br => |br| try verifyBlockTarget(function, br.target),
                .condbr => |condbr| {
                    if (!condbr.cond_ty.eql(.{ .int = 1 })) return error.BranchConditionTypeMismatch;
                    try verifyValue(defs, condbr.cond_ty, condbr.cond);
                    try verifyBlockTarget(function, condbr.then_target);
                    try verifyBlockTarget(function, condbr.else_target);
                },
                .@"unreachable" => {},
            }
        }
    }
}

fn verifyBinaryFlags(binary: core.BinaryInst) !void {
    if (binary.flags.nsw or binary.flags.nuw) {
        switch (binary.op) {
            .add, .sub, .mul, .shl => {},
            .@"and", .@"or", .xor, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    if (binary.flags.exact) {
        switch (binary.op) {
            .udiv, .sdiv, .lshr, .ashr => {},
            .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .urem, .srem => return error.InvalidInstructionFlag,
        }
    }
    switch (binary.ty) {
        .int => {},
        .void, .ptr => return error.TypeMismatch,
    }
}

fn verifyCast(cast: core.CastInst) !void {
    const from_bits = switch (cast.from_ty) {
        .int => |bits| bits,
        .void, .ptr => return error.TypeMismatch,
    };
    const to_bits = switch (cast.to_ty) {
        .int => |bits| bits,
        .void, .ptr => return error.TypeMismatch,
    };
    switch (cast.op) {
        .trunc => if (from_bits <= to_bits) return error.InvalidCast,
        .zext, .sext => if (from_bits >= to_bits) return error.InvalidCast,
    }
}

fn verifyMemoryAttrs(attrs: core.MemoryAttrs) !void {
    if (attrs.@"align") |alignment| {
        if (alignment == 0) return error.InvalidAlignment;
    }
    if (attrs.atomic_ordering) |ordering| {
        if (ordering.len == 0) return error.InvalidAtomicMemory;
    }
}

fn verifyValue(defs: std.StringHashMap(core.Type), ty: core.Type, value: core.Value) !void {
    switch (value) {
        .int, .undef => {},
        .named => |name| {
            const def_ty = defs.get(name) orelse return error.UnknownValue;
            if (!def_ty.eql(ty)) return error.TypeMismatch;
        },
    }
}

fn verifyBlockTarget(function: core.Function, target: []const u8) !void {
    if (function.blockIndex(target) == null) return error.UnknownBlock;
}
