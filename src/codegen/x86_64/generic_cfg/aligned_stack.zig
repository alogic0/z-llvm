//! Overaligned local objects use a bounded backing allocation and a rounded
//! interior pointer. The fixed stack frame keeps its native 16-byte alignment.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const storage = @import("storage_layout.zig");
const forms = @import("scalar_forms.zig");

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.kind == .alloca and inst.result != null) {
                const alloca = inst.kind.alloca;
                const text = std.mem.trim(u8, alloca.attrs orelse "", " \t");
                if (std.mem.startsWith(u8, text, "align ") and alloca.isSingleObject() and alloca.allocated_ty_addrspace == null) {
                    const alignment = std.fmt.parseUnsigned(u32, text[6..], 10) catch 0;
                    if (alignment > 16 and alignment <= 4096 and std.math.isPowerOfTwo(alignment)) if (storage.query(context, alloca.allocated_ty)) |layout| {
                        const bytes = std.math.add(u32, layout.bytes, alignment - 1) catch return null;
                        const backing_bytes = std.mem.alignForward(u32, bytes, 4);
                        if (backing_bytes > storage.max_bytes) return null;
                        try candidate.begin(&block, block_index, instruction_index);
                        const backing = try forms.temporary(allocator, function, &serial);
                        const pointer = try forms.temporary(allocator, function, &serial);
                        const address = try forms.temporary(allocator, function, &serial);
                        const bumped = try forms.temporary(allocator, function, &serial);
                        const aligned = try forms.temporary(allocator, function, &serial);
                        var indices: std.ArrayList(ir.GepIndex) = .empty;
                        try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
                        try block.instructions.appendSlice(allocator, &.{
                            .{ .result = backing, .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = try std.fmt.allocPrint(allocator, "[{d} x i32]", .{backing_bytes / 4}) }, .attrs = "align 16" } } },
                            .{ .result = pointer, .kind = .{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = backing }, .indices = indices } } },
                            .{ .result = address, .kind = .{ .cast = .{ .op = .ptrtoint, .from_ty = .ptr, .value = .{ .named = pointer }, .to_ty = .{ .int = 64 } } } },
                            .{ .result = bumped, .kind = .{ .binary = .{ .op = .add, .ty = .{ .int = 64 }, .lhs = .{ .named = address }, .rhs = .{ .int = alignment - 1 } } } },
                            .{ .result = aligned, .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 64 }, .lhs = .{ .named = bumped }, .rhs = .{ .int = -@as(i128, alignment) } } } },
                            .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .inttoptr, .from_ty = .{ .int = 64 }, .value = .{ .named = aligned }, .to_ty = .ptr } } },
                        });
                        continue;
                    };
                }
            }
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
