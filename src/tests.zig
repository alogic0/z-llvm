const std = @import("std");
const alias = @import("analysis/alias.zig");
const cfg = @import("analysis/cfg.zig");
const dominator = @import("analysis/dominator.zig");
const ir = @import("ir.zig");
const normalize = @import("normalize.zig");
const pass_manager = @import("pass_manager.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");
const early_cse = @import("passes/early_cse.zig");
const mem2reg = @import("passes/mem2reg.zig");
const simplifycfg = @import("passes/simplifycfg.zig");

test "instcombine and dce remove identity arithmetic" {
    const input =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 0
        \\  %y = mul i32 %x, 1
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "constant folding rewrites return value" {
    const input =
        \\define i32 @constant() {
        \\entry:
        \\  %x = add i32 1, 2
        \\  %y = mul i32 %x, 4
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @constant() {
        \\entry:
        \\  ret i32 12
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "dce updates use counts while removing instruction chains" {
    const input =
        \\define i32 @chain(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %y = mul i32 %x, 2
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @chain(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "normalization preserves canonical LLVM-compatible fixture output" {
    const input = @embedFile("testdata/instcombine.ll");
    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "instcombine dce output matches golden file" {
    const input = @embedFile("testdata/instcombine.ll");
    const expected = @embedFile("testdata/instcombine_dce.ll");

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const normalized_actual = try normalize.llvmCompatibleIr(std.testing.allocator, output.writer.buffered());
    defer std.testing.allocator.free(normalized_actual);

    const normalized_expected = try normalize.llvmCompatibleIr(std.testing.allocator, expected);
    defer std.testing.allocator.free(normalized_expected);

    try std.testing.expectEqualStrings(normalized_expected, normalized_actual);
}

test "parser normalizes multiple functions and branch terminators" {
    const input =
        \\define i32 @branch(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %exit
        \\else:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @second(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes icmp instructions" {
    const input =
        \\define i1 @cmp(i32 %a) {
        \\entry:
        \\  %c = icmp eq i32 %a, 0
        \\  ret i1 %c
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "instcombine folds constant icmp" {
    const input =
        \\define i1 @cmp() {
        \\entry:
        \\  %c = icmp ne i32 1, 1
        \\  ret i1 %c
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i1 @cmp() {
        \\entry:
        \\  ret i1 0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser normalizes phi instructions" {
    const input =
        \\define i32 @select(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes memory instructions" {
    const input =
        \\define i32 @memory(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "dce removes unused loads but keeps stores" {
    const input =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %dead = load i32, ptr %slot
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @memory_dce(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "alias analysis classifies stack slots" {
    const input =
        \\define i32 @alias(ptr %arg) {
        \\entry:
        \\  %left = alloca i32
        \\  %right = alloca i32
        \\  store i32 1, ptr %left
        \\  store i32 2, ptr %right
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    try std.testing.expectEqual(
        alias.AliasResult.must_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "left" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.no_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "right" }),
    );
    try std.testing.expectEqual(
        alias.AliasResult.may_alias,
        alias.alias(function, .{ .named = "left" }, .{ .named = "arg" }),
    );
}

test "mem2reg promotes single-block stack slot" {
    const input =
        \\define i32 @promote(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(mem2reg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @promote(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg folds constant branch and removes unreachable blocks" {
    const input =
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  br i1 1, label %then, label %else
        \\then:
        \\  ret i32 %a
        \\else:
        \\  %dead = add i32 %a, 1
        \\  ret i32 %dead
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  br label %then
        \\then:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "simplifycfg prunes unreachable phi incoming and removes trivial phi" {
    const input =
        \\define i32 @phi_cleanup(i32 %a, i32 %b) {
        \\entry:
        \\  br i1 1, label %then, label %else
        \\then:
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(simplifycfg.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @phi_cleanup(i32 %a, i32 %b) {
        \\entry:
        \\  br label %then
        \\then:
        \\  br label %merge
        \\merge:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "cfg analysis reports successors predecessors and reachability" {
    const input =
        \\define i32 @cfg(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\dead:
        \\  ret i32 0
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var graph = try cfg.Graph.build(std.testing.allocator, function);
    defer graph.deinit();

    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, graph.successors(0));
    try std.testing.expectEqualSlices(usize, &.{0}, graph.predecessors(1));
    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, graph.predecessors(4));

    const reachable = try graph.reachableFromEntry(std.testing.allocator);
    defer std.testing.allocator.free(reachable);

    try std.testing.expectEqualSlices(bool, &.{ true, true, true, false, true }, reachable);
}

test "dominator analysis answers dominance queries" {
    const input =
        \\define i32 @dom(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %exit
        \\right:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = module.functions.items[0];

    var dom = try dominator.Dominators.build(std.testing.allocator, function);
    defer dom.deinit();

    try std.testing.expect(dom.dominates(0, 0));
    try std.testing.expect(dom.dominates(0, 1));
    try std.testing.expect(dom.dominates(0, 2));
    try std.testing.expect(dom.dominates(0, 3));
    try std.testing.expect(dom.dominates(1, 1));
    try std.testing.expect(!dom.dominates(1, 3));
    try std.testing.expect(!dom.dominates(2, 3));
}

test "early-cse removes repeated pure expressions in a block" {
    const input =
        \\define i32 @cse(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %y = add i32 %a, 1
        \\  %z = mul i32 %y, 2
        \\  ret i32 %z
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(early_cse.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @cse(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %z = mul i32 %x, 2
        \\  ret i32 %z
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}
