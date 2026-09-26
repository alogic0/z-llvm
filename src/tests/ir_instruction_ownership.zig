const std = @import("std");
const ir = @import("../ir.zig");
const always_inline = @import("../passes/always_inline.zig");
const sccp = @import("../passes/sccp.zig");
const pass_manager = @import("../pass_manager.zig");

const owned_storage_ir =
    \\declare i32 @callee(i32)
    \\define i32 @f(i32 %x, ptr %p) {
    \\entry:
    \\  br label %body
    \\body:
    \\  %ph = phi i32 [ %x, %entry ]
    \\  %gp = getelementptr i32, ptr %p, i32 %x
    \\  %c = call i32 @callee(i32 %x)
    \\  %cx = cmpxchg ptr %p, i32 %x, i32 7 seq_cst seq_cst
    \\  %sum = add i32 %x, 1
    \\  ret i32 %c
    \\}
;

fn cloneAndDestroy(allocator: std.mem.Allocator, source: ir.Instruction) !void {
    var clone = try source.clone(allocator);
    defer clone.deinit(allocator);
    try std.testing.expectEqualDeep(source, clone);
}

test "instruction ownership: clones isolate PHI GEP call operands and owned cmpxchg types" {
    var module = try ir.Module.parse(std.testing.allocator, owned_storage_ir);
    defer module.deinit();
    try module.verify();
    var aliases = std.StringHashMap(ir.Value).init(std.testing.allocator);
    defer aliases.deinit();
    try aliases.put("x", .{ .int = 42 });
    try aliases.put("p", .null_value);
    for (module.functions.items[0].blocks.items[1].instructions.items) |source| {
        var clone = try source.clone(std.testing.allocator);
        defer clone.deinit(std.testing.allocator);
        try std.testing.expectEqualDeep(source, clone);
        clone.mapOperands(aliases);
        switch (source.kind) {
            .phi => |phi| {
                try std.testing.expect(phi.incoming.items.ptr != clone.kind.phi.incoming.items.ptr);
                try std.testing.expect(phi.incoming.items[0].value.eql(.{ .named = "x" }));
                try std.testing.expect(clone.kind.phi.incoming.items[0].value.eql(.{ .int = 42 }));
                clone.kind.phi.incoming.items[0].block = "other";
                try std.testing.expectEqualStrings("entry", phi.incoming.items[0].block);
            },
            .gep => |gep| {
                try std.testing.expect(gep.indices.items.ptr != clone.kind.gep.indices.items.ptr);
                try std.testing.expect(gep.indices.items[0].value.eql(.{ .named = "x" }));
                try std.testing.expect(clone.kind.gep.indices.items[0].value.eql(.{ .int = 42 }));
                try std.testing.expect(gep.ptr.eql(.{ .named = "p" }));
                try std.testing.expect(clone.kind.gep.ptr == .null_value);
            },
            .call => |call| {
                try std.testing.expect(call.args.items.ptr != clone.kind.call.args.items.ptr);
                try std.testing.expect(call.args.items[0].value.eql(.{ .named = "x" }));
                try std.testing.expect(clone.kind.call.args.items[0].value.eql(.{ .int = 42 }));
                clone.kind.call.args.items[0].attrs = "noundef";
                try std.testing.expect(call.args.items[0].attrs == null);
            },
            .cmpxchg => |cx| {
                try std.testing.expect(cx.result_ty.aggregate.ptr != clone.kind.cmpxchg.result_ty.aggregate.ptr);
                try std.testing.expectEqualStrings(cx.result_ty.aggregate, clone.kind.cmpxchg.result_ty.aggregate);
                try std.testing.expect(cx.expected.eql(.{ .named = "x" }));
                try std.testing.expect(clone.kind.cmpxchg.expected.eql(.{ .int = 42 }));
            },
            .binary => |binary| {
                try std.testing.expect(binary.lhs.eql(.{ .named = "x" }));
                try std.testing.expect(clone.kind.binary.lhs.eql(.{ .int = 42 }));
            },
            else => return error.UnexpectedInstruction,
        }
        try std.testing.checkAllAllocationFailures(std.testing.allocator, cloneAndDestroy, .{source});
    }
    // Each speculative clone has been destroyed; the original is still valid.
    try module.verify();
}

test "instruction ownership: clone survives source instruction destruction" {
    var module = try ir.Module.parse(std.testing.allocator, owned_storage_ir);
    defer module.deinit();
    for (module.functions.items[0].blocks.items[1].instructions.items) |*source| {
        var clone = try source.clone(std.testing.allocator);
        defer clone.deinit(std.testing.allocator);
        source.deinit(std.testing.allocator);
        // Clear the moved-out source so Module.deinit cannot destroy it twice.
        source.* = .{ .result = null, .kind = .{ .fence = .{ .ordering = "seq_cst" } } };
        switch (clone.kind) {
            .phi => |phi| try std.testing.expect(phi.incoming.items[0].value.eql(.{ .named = "x" })),
            .gep => |gep| try std.testing.expect(gep.indices.items[0].value.eql(.{ .named = "x" })),
            .call => |call| try std.testing.expect(call.args.items[0].value.eql(.{ .named = "x" })),
            .cmpxchg => |cx| try std.testing.expectEqualStrings("{ i32, i1 }", cx.result_ty.aggregate),
            .binary => |binary| try std.testing.expect(binary.lhs.eql(.{ .named = "x" })),
            else => return error.UnexpectedInstruction,
        }
    }
}

test "instruction ownership: clone preserves borrowed call fields and bookkeeping" {
    const source: ir.Instruction = .{
        .result = "r",
        .removed = true,
        .replacement = .{ .named = "next" },
        .metadata = "!annotation !0",
        .kind = .{ .call = .{
            .ret_ty = .{ .int = 32 },
            .callee = "callee",
            .callee_value = .{ .named = "fn" },
            .callee_function_ty = "i32 ()",
            .calling_conv = "fastcc",
            .ret_attrs = "noundef",
            .tail_kind = "tail",
            .inline_asm = .{ .template = "", .constraints = "", .sideeffect = true },
            .attrs = "nounwind",
            .operand_bundle = "[opaque]",
            .raw_args = "metadata !0",
            .args = .empty,
        } },
    };
    var clone = try source.clone(std.testing.allocator);
    defer clone.deinit(std.testing.allocator);
    try std.testing.expectEqualDeep(source, clone);
    try std.testing.expect(source.metadata.?.ptr == clone.metadata.?.ptr);
    try std.testing.expect(source.kind.call.callee.ptr == clone.kind.call.callee.ptr);
    clone.kind.call.callee_value = .null_value;
    clone.removed = false;
    clone.replacement = null;
    try std.testing.expect(source.kind.call.callee_value.?.eql(.{ .named = "fn" }));
    try std.testing.expect(source.removed);
    try std.testing.expect(source.replacement.?.eql(.{ .named = "next" }));
}

const inline_ir =
    \\define internal ptr @helper(ptr %p, i64 %x) alwaysinline {
    \\entry:
    \\  %g0 = getelementptr i8, ptr %p, i64 %x
    \\  %g1 = getelementptr i8, ptr %g0, i64 %x
    \\  %g2 = getelementptr i8, ptr %g1, i64 %x
    \\  %g3 = getelementptr i8, ptr %g2, i64 %x
    \\  %g4 = getelementptr i8, ptr %g3, i64 %x
    \\  %g5 = getelementptr i8, ptr %g4, i64 %x
    \\  %g6 = getelementptr i8, ptr %g5, i64 %x
    \\  %g7 = getelementptr i8, ptr %g6, i64 %x
    \\  ret ptr %g7
    \\}
    \\define ptr @caller(ptr %p) {
    \\entry:
    \\  %r = call ptr @helper(ptr %p, i64 3)
    \\  ret ptr %r
    \\}
;

test "instruction ownership: inlining transfers clones without modifying the callee" {
    var module = try ir.Module.parse(std.testing.allocator, inline_ir);
    defer module.deinit();
    try module.verify();
    try always_inline.inlineCall(&module, 1, .{ .block_index = 0, .instruction_index = 0, .callee_index = 0 });
    try module.verify();
    const callee = module.functions.items[0].blocks.items[0].instructions.items;
    const caller = module.functions.items[1].blocks.items[0].instructions.items;
    try std.testing.expectEqual(@as(usize, 9), caller.len);
    for (callee, caller[0..8]) |original, copied| {
        try std.testing.expect(original.kind.gep.indices.items[0].value.eql(.{ .named = "x" }));
        try std.testing.expect(copied.kind.gep.indices.items[0].value.eql(.{ .int = 3 }));
        try std.testing.expect(original.kind.gep.indices.items.ptr != copied.kind.gep.indices.items.ptr);
    }
    try std.testing.expect(caller[8].removed);
}

// Inject failures only after parsing, keeping all allocations under the same
// tracking allocator. This covers clone/name/map/staging/caller-buffer growth
// without conflating the consumer's cleanup with parser failure handling.
fn checkConsumerFailures(comptime inlining: bool) !void {
    for (0..256) |failure_offset| {
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
        var module = try ir.Module.parse(failing.allocator(), if (inlining) inline_ir else owned_storage_ir);
        var succeeded = false;
        {
            defer module.deinit();
            failing.fail_index = failing.alloc_index + failure_offset;
            succeeded = true;
            runConsumer(inlining, &module) catch |err| {
                try std.testing.expectEqual(error.OutOfMemory, err);
                succeeded = false;
            };
            failing.fail_index = std.math.maxInt(usize);
            try module.verify();
        }
        try std.testing.expectEqual(failing.allocated_bytes, failing.freed_bytes);
        if (succeeded) return;
    }
    return error.FailureInjectionDidNotConverge;
}

fn runConsumer(comptime inlining: bool, module: *ir.Module) !void {
    if (inlining) {
        try always_inline.inlineCall(module, 1, .{ .block_index = 0, .instruction_index = 0, .callee_index = 0 });
    } else {
        var context: pass_manager.Context = .{ .allocator = module.allocator };
        _ = try sccp.pass.run(module, &context);
    }
}

test "instruction ownership: inliner cleans up every allocation failure" {
    try checkConsumerFailures(true);
}

test "instruction ownership: SCCP cleans up every allocation failure" {
    try checkConsumerFailures(false);
}
