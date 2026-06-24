const std = @import("std");
const air_bridge = @import("../air_bridge.zig");
const alias = @import("../analysis/alias.zig");
const call_graph = @import("../analysis/call_graph.zig");
const cfg = @import("../analysis/cfg.zig");
const codegen = @import("../codegen.zig");
const dominator = @import("../analysis/dominator.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const fp_semantics = @import("../analysis/fp_semantics.zig");
const loop_info = @import("../analysis/loop_info.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const memory_location = @import("../analysis/memory_location.zig");
const memory_ssa = @import("../analysis/memory_ssa.zig");
const ir = @import("../ir.zig");
const normalize = @import("../normalize.zig");
const mc = @import("../mc.zig");
const pass_manager = @import("../pass_manager.zig");
const pipelines = @import("../pipelines.zig");
const postdominator = @import("../analysis/postdominator.zig");
const semantic_descriptor_v2 = @import("../semantic_descriptor_v2.zig");
const target = @import("../target.zig");
const target_library_info = @import("../analysis/target_library_info.zig");
const target_transform_info = @import("../analysis/target_transform_info.zig");
const instcombine = @import("../passes/instcombine.zig");
const zig_air_export = @import("../zig_air_export.zig");
const zig_air_lowering = @import("../zig_air_lowering.zig");
const dce = @import("../passes/dce.zig");
const dse = @import("../passes/dse.zig");
const early_cse = @import("../passes/early_cse.zig");
const gvn = @import("../passes/gvn.zig");
const licm = @import("../passes/licm.zig");
const mem2reg = @import("../passes/mem2reg.zig");
const sccp = @import("../passes/sccp.zig");
const simplifycfg = @import("../passes/simplifycfg.zig");
const slp_vectorizer = @import("../passes/slp_vectorizer.zig");
const sroa = @import("../passes/sroa.zig");

test {
    _ = zig_air_export;
    _ = zig_air_lowering;
}

test "AIR-like bridge lowers scalar binary function" {
    const params = [_]air_bridge.Param{
        .{ .name = "a", .ty = .{ .int = 32 } },
        .{ .name = "b", .ty = .{ .int = 32 } },
    };
    const binaries = [_]air_bridge.Binary{
        .{
            .result = "sum",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "a" },
            .rhs = .{ .named = "b" },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "add",
            .ret_ty = .{ .int = 32 },
            .params = &params,
            .binaries = &binaries,
            .ret = .{ .named = "sum" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .source_filename = "air-like",
        .target_triple = "x86_64-unknown-linux-gnu",
        .target_datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\source_filename = "air-like"
        \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers scalar arithmetic and casts" {
    const params = [_]air_bridge.Param{
        .{ .name = "a", .ty = .{ .int = 32 } },
        .{ .name = "b", .ty = .{ .int = 32 } },
    };
    const binaries = [_]air_bridge.Binary{
        .{
            .result = "sub",
            .op = .sub,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "a" },
            .rhs = .{ .named = "b" },
        },
        .{
            .result = "masked",
            .op = .@"and",
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sub" },
            .rhs = .{ .int = 255 },
        },
        .{
            .result = "shifted",
            .op = .shl,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "masked" },
            .rhs = .{ .int = 1 },
        },
    };
    const casts = [_]air_bridge.Cast{
        .{
            .result = "wide",
            .op = .zext,
            .from_ty = .{ .int = 32 },
            .value = .{ .named = "shifted" },
            .to_ty = .{ .int = 64 },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "arith",
            .ret_ty = .{ .int = 64 },
            .params = &params,
            .binaries = &binaries,
            .casts = &casts,
            .ret = .{ .named = "wide" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @arith(i32 %a, i32 %b) {
        \\entry:
        \\  %sub = sub i32 %a, %b
        \\  %masked = and i32 %sub, 255
        \\  %shifted = shl i32 %masked, 1
        \\  %wide = zext i32 %shifted to i64
        \\  ret i64 %wide
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers explicit control flow blocks" {
    const params = [_]air_bridge.Param{
        .{ .name = "cond", .ty = .{ .int = 1 } },
        .{ .name = "a", .ty = .{ .int = 32 } },
        .{ .name = "b", .ty = .{ .int = 32 } },
    };
    const then_binaries = [_]air_bridge.Binary{
        .{
            .result = "sum",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "a" },
            .rhs = .{ .named = "b" },
        },
    };
    const blocks = [_]air_bridge.Block{
        .{
            .name = "entry",
            .terminator = .{ .condbr = .{
                .cond_ty = .{ .int = 1 },
                .cond = .{ .named = "cond" },
                .then_target = "then",
                .else_target = "trap",
            } },
        },
        .{
            .name = "then",
            .binaries = &then_binaries,
            .terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .named = "sum" },
            } },
        },
        .{
            .name = "trap",
            .terminator = .@"unreachable",
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "branch",
            .ret_ty = .{ .int = 32 },
            .params = &params,
            .blocks = &blocks,
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %trap
        \\then:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\trap:
        \\  unreachable
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers scalar stack memory" {
    const allocas = [_]air_bridge.Alloca{
        .{
            .result = "slot",
            .allocated_ty = .{ .int = 32 },
        },
    };
    const stores = [_]air_bridge.Store{
        .{
            .ty = .{ .int = 32 },
            .value = .{ .int = 7 },
            .ptr = .{ .named = "slot" },
            .attrs = .{ .@"align" = 4 },
        },
    };
    const loads = [_]air_bridge.Load{
        .{
            .result = "value",
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "slot" },
            .attrs = .{ .@"align" = 4 },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "stack",
            .ret_ty = .{ .int = 32 },
            .params = &.{},
            .allocas = &allocas,
            .stores = &stores,
            .loads = &loads,
            .ret = .{ .named = "value" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack() {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 7, ptr %slot, align 4
        \\  %value = load i32, ptr %slot, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers scalar GEP" {
    const indices = [_]ir.GepIndex{
        .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } },
    };
    const allocas = [_]air_bridge.Alloca{
        .{
            .result = "slot",
            .allocated_ty = .{ .int = 32 },
        },
    };
    const geps = [_]air_bridge.Gep{
        .{
            .result = "ptr",
            .source_ty = .{ .int = 32 },
            .ptr = .{ .named = "slot" },
            .indices = &indices,
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "gep",
            .ret_ty = .ptr,
            .params = &.{},
            .allocas = &allocas,
            .geps = &geps,
            .ret = .{ .named = "ptr" },
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @gep() {
        \\entry:
        \\  %slot = alloca i32
        \\  %ptr = getelementptr i32, ptr %slot, i32 0
        \\  ret ptr %ptr
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "AIR-like bridge lowers canonical loop shape" {
    const params = [_]air_bridge.Param{
        .{ .name = "limit", .ty = .{ .int = 32 } },
    };
    const phi_incoming = [_]ir.PhiIncoming{
        .{ .value = .{ .int = 0 }, .block = "entry" },
        .{ .value = .{ .named = "next" }, .block = "latch" },
    };
    const header_phis = [_]air_bridge.Phi{
        .{
            .result = "i",
            .ty = .{ .int = 32 },
            .incoming = &phi_incoming,
        },
    };
    const header_icmps = [_]air_bridge.Icmp{
        .{
            .result = "more",
            .predicate = .slt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "i" },
            .rhs = .{ .named = "limit" },
        },
    };
    const latch_binaries = [_]air_bridge.Binary{
        .{
            .result = "next",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "i" },
            .rhs = .{ .int = 1 },
        },
    };
    const blocks = [_]air_bridge.Block{
        .{
            .name = "entry",
            .terminator = .{ .br = .{ .target = "header" } },
        },
        .{
            .name = "header",
            .phis = &header_phis,
            .icmps = &header_icmps,
            .terminator = .{ .condbr = .{
                .cond_ty = .{ .int = 1 },
                .cond = .{ .named = "more" },
                .then_target = "body",
                .else_target = "exit",
            } },
        },
        .{
            .name = "body",
            .terminator = .{ .br = .{ .target = "latch" } },
        },
        .{
            .name = "latch",
            .binaries = &latch_binaries,
            .terminator = .{ .br = .{ .target = "header" } },
        },
        .{
            .name = "exit",
            .terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .named = "i" },
            } },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "loop",
            .ret_ty = .{ .int = 32 },
            .params = &params,
            .blocks = &blocks,
        },
    };

    var module = try air_bridge.lowerModule(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    });
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];

    var loops = try loop_info.LoopInfo.build(std.testing.allocator, function);
    defer loops.deinit();
    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    try std.testing.expectEqual(@as(usize, 1), loops.loops.items.len);
    const natural_loop = loops.loopForHeader(1) orelse return error.MissingLoop;
    try std.testing.expectEqual(@as(usize, 1), natural_loop.headerBlock());
    try std.testing.expectEqual(@as(usize, 3), natural_loop.latchBlock());
    try std.testing.expectEqual(@as(?usize, 0), natural_loop.preheader(function, graph));

    var exiting = try natural_loop.exitingBlocks(std.testing.allocator, graph);
    defer exiting.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{1}, exiting.items);

    var exits = try natural_loop.exitBlocks(std.testing.allocator, graph);
    defer exits.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{4}, exits.items);
}

test "AIR-like bridge driver prints pre and post optimization IR" {
    const allocas = [_]air_bridge.Alloca{
        .{
            .result = "slot",
            .allocated_ty = .{ .int = 32 },
        },
    };
    const stores = [_]air_bridge.Store{
        .{
            .ty = .{ .int = 32 },
            .value = .{ .int = 7 },
            .ptr = .{ .named = "slot" },
        },
    };
    const loads = [_]air_bridge.Load{
        .{
            .result = "value",
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "slot" },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "stack_pipeline",
            .ret_ty = .{ .int = 32 },
            .params = &.{},
            .allocas = &allocas,
            .stores = &stores,
            .loads = &loads,
            .ret = .{ .named = "value" },
        },
    };

    var pre: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer pre.deinit();
    var post: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer post.deinit();

    try air_bridge.lowerPrintAndRunPipeline(std.testing.allocator, .{
        .target_triple = "x86_64-unknown-linux-gnu",
        .functions = &functions,
    }, "memory-foundation", &pre.writer, &post.writer);

    const expected_pre =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_pipeline() {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 7, ptr %slot
        \\  %value = load i32, ptr %slot
        \\  ret i32 %value
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected_pre, pre.writer.buffered());

    const expected_post =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_pipeline() {
        \\entry:
        \\  ret i32 7
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected_post, post.writer.buffered());
}

test "AIR-like bridge fixture matches Zig-emitted scalar signatures" {
    const params = [_]air_bridge.Param{
        .{ .name = "0", .ty = .{ .int = 32 } },
        .{ .name = "1", .ty = .{ .int = 32 } },
    };
    const binaries = [_]air_bridge.Binary{
        .{
            .result = "2",
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "1" },
            .rhs = .{ .named = "0" },
        },
    };
    const side_effect_free_blocks = [_]air_bridge.Block{
        .{
            .name = "Entry",
            .terminator = .{ .ret = .{ .ty = .void } },
        },
    };
    const add_blocks = [_]air_bridge.Block{
        .{
            .name = "Entry",
            .binaries = &binaries,
            .terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .named = "2" },
            } },
        },
    };
    const functions = [_]air_bridge.Function{
        .{
            .name = "tiny_scalar.sideEffectFree",
            .ret_ty = .void,
            .linkage = .internal,
            .params = &.{},
            .blocks = &side_effect_free_blocks,
        },
        .{
            .name = "tiny_scalar.add",
            .ret_ty = .{ .int = 32 },
            .linkage = .internal,
            .params = &params,
            .blocks = &add_blocks,
        },
    };

    var pre: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer pre.deinit();
    var post: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer post.deinit();

    try air_bridge.lowerPrintAndRunPipeline(std.testing.allocator, .{
        .source_filename = "tiny_scalar",
        .target_datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
        .target_triple = "x86_64-unknown-linux5.10.0-gnu2.31.0",
        .functions = &functions,
    }, "zig-scalar-foundation", &pre.writer, &post.writer);

    const expected_lowered = @embedFile("../testdata/zig_tiny_scalar.project_lowered.ll");
    const expected_optimized = @embedFile("../testdata/zig_tiny_scalar.project_optimized.ll");
    try std.testing.expectEqualStrings(expected_lowered, pre.writer.buffered());
    try std.testing.expectEqualStrings(expected_optimized, post.writer.buffered());

    var zig_module = try ir.Module.parse(std.testing.allocator, @embedFile("../testdata/zig_tiny_scalar.normalized.ll"));
    defer zig_module.deinit();
    var project_module = try ir.Module.parse(std.testing.allocator, expected_lowered);
    defer project_module.deinit();

    try std.testing.expectEqualStrings(zig_module.source_filename.?, project_module.source_filename.?);
    try std.testing.expectEqualStrings(zig_module.target_datalayout.?, project_module.target_datalayout.?);
    try std.testing.expectEqualStrings(zig_module.target_triple.?, project_module.target_triple.?);
    try std.testing.expectEqual(zig_module.functions.items.len, project_module.functions.items.len);
    for (zig_module.functions.items, project_module.functions.items) |zig_function, project_function| {
        try std.testing.expectEqualStrings(zig_function.name, project_function.name);
        try std.testing.expectEqual(zig_function.linkage, project_function.linkage);
        try std.testing.expect(zig_function.ret_ty.eql(project_function.ret_ty));
        try std.testing.expectEqual(zig_function.params.items.len, project_function.params.items.len);
        for (zig_function.params.items, project_function.params.items) |zig_param, project_param| {
            try std.testing.expect(zig_param.ty.eql(project_param.ty));
        }
    }
}
