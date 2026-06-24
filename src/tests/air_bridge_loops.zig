const air_lowering_common = @import("air_lowering_common.zig");

const std = air_lowering_common.std;
const air_bridge = air_lowering_common.air_bridge;
const alias = air_lowering_common.alias;
const call_graph = air_lowering_common.call_graph;
const cfg = air_lowering_common.cfg;
const codegen = air_lowering_common.codegen;
const dominator = air_lowering_common.dominator;
const function_attrs = air_lowering_common.function_attrs;
const fp_semantics = air_lowering_common.fp_semantics;
const loop_info = air_lowering_common.loop_info;
const memory_effect = air_lowering_common.memory_effect;
const memory_location = air_lowering_common.memory_location;
const memory_ssa = air_lowering_common.memory_ssa;
const ir = air_lowering_common.ir;
const normalize = air_lowering_common.normalize;
const mc = air_lowering_common.mc;
const pass_manager = air_lowering_common.pass_manager;
const pipelines = air_lowering_common.pipelines;
const postdominator = air_lowering_common.postdominator;
const semantic_descriptor_v2 = air_lowering_common.semantic_descriptor_v2;
const target = air_lowering_common.target;
const target_library_info = air_lowering_common.target_library_info;
const target_transform_info = air_lowering_common.target_transform_info;
const instcombine = air_lowering_common.instcombine;
const zig_air_export = air_lowering_common.zig_air_export;
const zig_air_lowering = air_lowering_common.zig_air_lowering;
const dce = air_lowering_common.dce;
const dse = air_lowering_common.dse;
const early_cse = air_lowering_common.early_cse;
const gvn = air_lowering_common.gvn;
const licm = air_lowering_common.licm;
const mem2reg = air_lowering_common.mem2reg;
const sccp = air_lowering_common.sccp;
const simplifycfg = air_lowering_common.simplifycfg;
const slp_vectorizer = air_lowering_common.slp_vectorizer;
const sroa = air_lowering_common.sroa;
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
