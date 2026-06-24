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
