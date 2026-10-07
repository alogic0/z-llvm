const std = @import("std");
const ir = @import("../ir.zig");
const UseCounts = @import("../analysis/def_use.zig").UseCounts;

const Record = struct {
    pub const Error = std.Io.Writer.Error;
    writer: *std.Io.Writer,

    pub fn visit(record: Record, value: anytype, ty: ir.Type) Error!void {
        comptime std.debug.assert(@TypeOf(value) == *const ir.Value);
        try value.format(record.writer);
        try record.writer.writeByte(':');
        try ty.format(record.writer);
        try record.writer.writeByte(';');
    }
};

const CheckPoison = struct {
    pub const Error = error{TestUnexpectedResult};

    pub fn visit(_: CheckPoison, value: *const ir.Value, _: ir.Type) Error!void {
        try std.testing.expect(value.* != .named);
    }
};

// One of every instruction kind, plus both representations of a call callee.
// Each named operand is a parameter, allowing replacement without removing defs.
const all_instructions =
    \\declare i32 @direct(i32)
    \\define void @all(i32 %x, i32 %y, i1 %c, ptr %p, ptr %fn, float %f, float %g, <2 x i32> %v, <2 x i32> %w, { i32, i32 } %agg) {
    \\entry:
    \\  br label %body
    \\body:
    \\  %ph = phi i32 [ %x, %entry ]
    \\  %a = add i32 %x, %y
    \\  %b = zext i32 %x to i64
    \\  %fr = freeze i32 %x
    \\  %ic = icmp eq i32 %x, %y
    \\  %fc = fcmp oeq float %f, %g
    \\  %sel = select i1 %c, i32 %x, i32 %y
    \\  %mem = alloca i32
    \\  %ld = load i32, ptr %p
    \\  store i32 %x, ptr %p
    \\  %rmw = atomicrmw add ptr %p, i32 %x seq_cst
    \\  %cx = cmpxchg ptr %p, i32 %x, i32 %y seq_cst seq_cst
    \\  fence seq_cst
    \\  %ex = extractelement <2 x i32> %v, i32 %x
    \\  %ins = insertelement <2 x i32> %v, i32 %y, i32 %x
    \\  %sh = shufflevector <2 x i32> %v, <2 x i32> %w, <2 x i32> <i32 0, i32 3>
    \\  %av = extractvalue { i32, i32 } %agg, 0
    \\  %iv = insertvalue { i32, i32 } %agg, i32 %x, 1
    \\  %gp = getelementptr i32, ptr %p, i32 %x
    \\  %ci = call i32 %fn(i32 %x)
    \\  %cd = call i32 @direct(i32 %y)
    \\  ret void
    \\}
;

test "operand traversal: every instruction kind has typed read and replacement coverage" {
    var module = try ir.Module.parse(std.testing.allocator, all_instructions);
    defer module.deinit();
    try module.verify();
    const function = &module.functions.items[0];
    const expected = [_][]const u8{
        "%x:i32;",            "%x:i32;%y:i32;",            "%x:i32;",                     "%x:i32;",
        "%x:i32;%y:i32;",     "%f:float;%g:float;",        "%c:i1;%x:i32;%y:i32;",        "",
        "%p:ptr;",            "%x:i32;%p:ptr;",            "%p:ptr;%x:i32;",              "%p:ptr;%x:i32;%y:i32;",
        "",                   "%v:<2 x i32>;%x:i32;",      "%v:<2 x i32>;%y:i32;%x:i32;", "%v:<2 x i32>;%w:<2 x i32>;<i32 0, i32 3>:<2 x i32>;",
        "%agg:{ i32, i32 };", "%agg:{ i32, i32 };%x:i32;", "%p:ptr;%x:i32;",              "%fn:ptr;%x:i32;",
        "%y:i32;",
    };
    const instructions = function.blocks.items[1].instructions.items;
    try std.testing.expectEqual(expected.len, instructions.len);
    const Kind = std.meta.Tag(@FieldType(ir.Instruction, "kind"));
    var seen: std.EnumSet(Kind) = .{};
    for (instructions, expected) |*inst, text| {
        seen.insert(std.meta.activeTag(inst.kind));
        var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer output.deinit();
        const coverage = try ir.operands.instruction(@as(*const ir.Instruction, inst), Record{ .writer = &output.writer });
        try std.testing.expectEqualStrings(text, output.written());
        try std.testing.expectEqual(inst.kind == .shufflevector, coverage.has_opaque_references);
    }
    // Adding a new instruction kind requires extending this fixture.
    try std.testing.expectEqual(@typeInfo(Kind).@"enum".field_names.len, seen.count());

    var counts = try UseCounts.collectFunction(std.testing.allocator, function.*);
    defer counts.deinit();
    var total: usize = 0;
    for (function.params.items) |param| {
        const result = ir.operands.replaceAllUses(function, param.name, .poison);
        try std.testing.expectEqual(counts.counts.get(param.name).?, result.replaced);
        total += result.replaced;
        try std.testing.expect(result.coverage.has_opaque_references);
    }
    try std.testing.expectEqual(@as(usize, 35), total);
    for (instructions) |*inst| _ = try ir.operands.instruction(@as(*const ir.Instruction, inst), CheckPoison{});
    try std.testing.expectEqualStrings("entry", instructions[0].kind.phi.incoming.items[0].block);
    try std.testing.expectEqualStrings("direct", instructions[instructions.len - 1].kind.call.callee);
    try module.verify();
}

test "operand traversal: all terminators exclude block labels and include switch cases" {
    var cases = [_]ir.SwitchCase{.{ .value_ty = .{ .int = 32 }, .value = .{ .int = 7 }, .target = "x" }};
    var targets = [_][]const u8{"x"};
    var terms = [_]ir.Terminator{
        .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "x" } } },
        .{ .br = .{ .target = "x" } },
        .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "x" }, .then_target = "x", .else_target = "x" } },
        .{ .@"switch" = .{ .cond_ty = .{ .int = 32 }, .cond = .{ .named = "x" }, .default_target = "x", .cases = .{ .items = &cases, .capacity = cases.len, .pointer_stability = .{} } } },
        .{ .indirectbr = .{ .addr_ty = .ptr, .addr = .{ .named = "x" }, .targets = .{ .items = &targets, .capacity = targets.len, .pointer_stability = .{} } } },
        .@"unreachable",
        .{ .ret = .{ .ty = .void } },
    };
    const expected = [_][]const u8{ "%x:i32;", "", "%x:i1;", "%x:i32;7:i32;", "%x:ptr;", "", "" };
    var seen: std.EnumSet(std.meta.Tag(ir.Terminator)) = .{};
    for (&terms, expected) |*term, text| {
        seen.insert(std.meta.activeTag(term.*));
        var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer output.deinit();
        const coverage = try ir.operands.terminator(@as(*const ir.Terminator, term), Record{ .writer = &output.writer });
        try std.testing.expect(!coverage.has_opaque_references);
        try std.testing.expectEqualStrings(text, output.written());
        // Mutate every operand, including a switch case literal, to test the
        // mutable list-backed path. Labels deliberately match the value name.
        _ = try ir.operands.terminator(term, Poison{});
        _ = try ir.operands.terminator(@as(*const ir.Terminator, term), CheckPoison{});
    }
    try std.testing.expectEqual(@typeInfo(ir.Terminator).@"union".field_names.len, seen.count());
    try std.testing.expectEqualStrings("x", terms[1].br.target);
    try std.testing.expectEqualStrings("x", terms[2].condbr.then_target);
    try std.testing.expectEqualStrings("x", terms[2].condbr.else_target);
    try std.testing.expectEqualStrings("x", terms[3].@"switch".default_target);
    try std.testing.expectEqualStrings("x", cases[0].target);
    try std.testing.expect(cases[0].value == .poison);
    try std.testing.expectEqualStrings("x", targets[0]);
}

const Poison = struct {
    pub const Error = error{};
    pub fn visit(_: Poison, value: *ir.Value, _: ir.Type) Error!void {
        value.* = .poison;
    }
};

test "operand traversal: mappings stay one-step and function replacement skips removed instructions" {
    const input =
        \\define i32 @f(i32 %x, i32 %y) {
        \\entry:
        \\  %dead = add i32 %x, %y
        \\  %live = add i32 %x, %y
        \\  br label %x
        \\x:
        \\  %ph = phi i32 [ %x, %entry ]
        \\  ret i32 %x
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = &module.functions.items[0];
    const insts = function.blocks.items[0].instructions.items;
    insts[0].removed = true;
    insts[0].replacement = .{ .named = "x" };
    const result = ir.operands.replaceAllUses(function, "x", .{ .named = "y" });
    try std.testing.expectEqual(@as(usize, 3), result.replaced);
    try std.testing.expect(!result.coverage.has_opaque_references);
    try std.testing.expect(insts[0].kind.binary.lhs.eql(.{ .named = "x" }));
    try std.testing.expect(insts[0].replacement.?.eql(.{ .named = "x" }));
    try std.testing.expectEqualStrings("x", function.blocks.items[0].terminator.?.br.target);
    try std.testing.expect(function.blocks.items[1].terminator.?.ret.value.?.eql(.{ .named = "y" }));
    try module.verify();

    var aliases = std.StringHashMap(ir.Value).init(std.testing.allocator);
    defer aliases.deinit();
    try aliases.put("x", .{ .named = "y" });
    try aliases.put("y", .{ .int = 42 });
    // The compatibility method still maps removed instructions when explicitly
    // asked; both original operands are looked up exactly once.
    insts[0].mapOperands(aliases);
    try std.testing.expect(insts[0].kind.binary.lhs.eql(.{ .named = "y" }));
    try std.testing.expect(insts[0].kind.binary.rhs.eql(.{ .int = 42 }));
    try aliases.put("y", .{ .named = "x" });
    insts[0].mapOperands(aliases);
    try std.testing.expect(insts[0].kind.binary.lhs.eql(.{ .named = "x" }));
    try std.testing.expect(insts[0].kind.binary.rhs.eql(.{ .int = 42 }));
}

test "operand traversal: opaque references are reported without textual rewriting" {
    const input =
        \\define ptr @f() {
        \\entry:
        \\  ret ptr getelementptr (i8, ptr @x, i64 1)
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const result = ir.operands.replaceAllUses(&module.functions.items[0], "@x", .null_value);
    try std.testing.expectEqual(@as(usize, 0), result.replaced);
    try std.testing.expect(result.coverage.has_opaque_references);
    const term = module.functions.items[0].blocks.items[0].terminator.?;
    try std.testing.expectEqualStrings("getelementptr (i8, ptr @x, i64 1)", term.ret.value.?.constant_expr);

    var inst: ir.Instruction = .{ .result = null, .kind = .{ .call = .{ .ret_ty = .void, .callee = "f", .args = .empty } } };
    try std.testing.expect(!(try ir.operands.instruction(&inst, Poison{})).has_opaque_references);
    const fields = .{ "raw_args", "operand_bundle", "attrs", "ret_attrs" };
    inline for (fields) |field| {
        @field(inst.kind.call, field) = "opaque";
        try std.testing.expect((try ir.operands.instruction(&inst, Poison{})).has_opaque_references);
        @field(inst.kind.call, field) = null;
    }
    inst.kind.call.inline_asm = .{ .template = "", .constraints = "" };
    try std.testing.expect((try ir.operands.instruction(&inst, Poison{})).has_opaque_references);
    inst.kind.call.inline_asm = null;
    inst.metadata = "!annotation !0";
    try std.testing.expect((try ir.operands.instruction(&inst, Poison{})).has_opaque_references);
    var branch: ir.Terminator = .{ .br = .{ .target = "exit", .metadata = "!annotation !0" } };
    try std.testing.expect((try ir.operands.terminator(&branch, Poison{})).has_opaque_references);
    inst = .{ .result = "x", .kind = .{ .alloca = .{ .allocated_ty = .{ .int = 8 }, .attrs = ", i32 %count" } } };
    try std.testing.expect((try ir.operands.instruction(&inst, Poison{})).has_opaque_references);
}

test "operand traversal: use count removal balances shared list-backed operands" {
    var module = try ir.Module.parse(std.testing.allocator, all_instructions);
    defer module.deinit();
    var uses = try UseCounts.collectFunction(std.testing.allocator, module.functions.items[0]);
    defer uses.deinit();
    for (module.functions.items[0].blocks.items) |block| {
        for (block.instructions.items) |inst| uses.removeInstructionOperands(inst);
    }
    try std.testing.expectEqual(@as(usize, 0), uses.counts.count());
}

fn collectWithAllocator(allocator: std.mem.Allocator, function: ir.Function) !void {
    var uses = try UseCounts.collectFunction(allocator, function);
    defer uses.deinit();
}

test "operand traversal: use counts propagate allocation failures without leaks" {
    var module = try ir.Module.parse(std.testing.allocator, all_instructions);
    defer module.deinit();
    try std.testing.checkAllAllocationFailures(std.testing.allocator, collectWithAllocator, .{module.functions.items[0]});
}
