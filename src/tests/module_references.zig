const std = @import("std");
const ir = @import("../ir.zig");
const refs = @import("../analysis/module_references.zig");
const globalopt = @import("../passes/globalopt.zig");
const pass_manager = @import("../pass_manager.zig");

fn parse(text: []const u8) !ir.Module {
    return ir.Module.parse(std.testing.allocator, text);
}

fn optimize(module: *ir.Module) !void {
    try module.verify();
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    _ = try globalopt.pass.run(module, &context);
    try module.verify();
}

test "module references: distinguish direct symbols local names and known absence" {
    var module = try parse(
        \\@g = internal global i32 7
        \\@s = constant [2 x i8] c"@g"
        \\define i32 @f(ptr %g) local_unnamed_addr {
        \\entry:
        \\  %local = load i32, ptr %g
        \\  %global = load i32, ptr @g
        \\  %sum = add i32 %local, %global
        \\  ret i32 %sum
        \\}
    );
    defer module.deinit();
    const query = refs.query(&module, "g");
    try std.testing.expectEqual(@as(usize, 1), query.direct_uses);
    try std.testing.expect(!query.has_unknown);
    try std.testing.expect(!refs.hasUnknown(&module));
    try std.testing.expect(refs.query(&module, "").has_unknown);
    try std.testing.expect(!refs.query(&module, "missing").mayReference());
    try std.testing.expect(!refs.isDirectValue(.{ .named = "g" }, "g"));
    try std.testing.expect(!refs.isDirectValue(.{ .named = "@global" }, "g"));
    try std.testing.expect(refs.isDirectValue(.{ .named = "@g" }, "g"));
    try optimize(&module);
    const instructions = module.functions.items[0].blocks.items[0].instructions.items;
    try std.testing.expect(!instructions[0].removed);
    try std.testing.expect(instructions[1].removed);
    try std.testing.expect(instructions[2].kind.binary.rhs.eql(.{ .int = 7 }));
    try std.testing.expect(!refs.query(&module, "g").mayReference());
    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len); // only byte-string data
}

test "module references: alias chains arrays callees and terminators enumerate symbols" {
    var module = try parse(
        \\@g = global i32 7
        \\@p = global [2 x ptr] [ptr @g, ptr @first]
        \\@first = alias i32, ptr @g
        \\@second = alias i32, ptr @first
        \\declare void @sink(ptr)
        \\define ptr @f(ptr %g) {
        \\entry:
        \\  call void @sink(ptr @g)
        \\  call void %g(ptr @second)
        \\  ret ptr @g
        \\}
    );
    defer module.deinit();
    // The text parser retains pointer arrays as opaque today. The shared IR
    // also supports structured arrays, which must enumerate every value.
    try std.testing.expect(refs.query(&module, "g").has_unknown);
    module.globals.items[1].initializer = .{ .array = .{ .elem_ty = .ptr, .values = .empty } };
    try module.globals.items[1].initializer.array.values.appendSlice(std.testing.allocator, &.{ .{ .named = "@g" }, .{ .named = "@first" } });
    try std.testing.expectEqual(@as(usize, 4), refs.query(&module, "g").direct_uses);
    try std.testing.expectEqual(@as(usize, 2), refs.query(&module, "first").direct_uses);
    try std.testing.expectEqual(@as(usize, 1), refs.query(&module, "second").direct_uses);
    try std.testing.expectEqual(@as(usize, 1), refs.query(&module, "sink").direct_uses);
    try std.testing.expect(!refs.query(&module, "g").has_unknown);
}

test "module references: alternate global spellings retain stores and pointer escapes" {
    for ([_][]const u8{
        "@value = internal global i32 7\ndefine i32 @f(i32 %x) {\nentry:\n  store i32 %x, ptr @\"val\\75e\"\n  %v = load i32, ptr @value\n  ret i32 %v\n}\n",
        "@\"value\" = internal global i32 7\ndefine i32 @f(i32 %x) {\nentry:\n  store i32 %x, ptr @value\n  %v = load i32, ptr @\"val\\75e\"\n  ret i32 %v\n}\n",
        "@value = internal global i32 7\ndefine i32 @f() {\nentry:\n  %v = load i32, ptr @value\n  ret i32 %v\n}\ndefine ptr @address() {\nentry:\n  ret ptr @\"val\\75e\"\n}\n",
    }) |source| {
        var module = try parse(source);
        defer module.deinit();
        const query = refs.query(&module, "value");
        try std.testing.expectEqual(@as(usize, 2), query.direct_uses);
        try std.testing.expect(!query.has_unknown);
        try optimize(&module);
        try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
        for (module.functions.items[0].blocks.items[0].instructions.items) |instruction| {
            try std.testing.expect(!instruction.removed);
        }
    }
}

test "module references: equivalent direct loads fold and numeric global identities stay separate" {
    var module = try parse(
        \\@0 = internal global i32 11
        \\@"0" = internal global i32 19
        \\@value = internal global i32 7
        \\define i32 @f() {
        \\entry:
        \\  %a = load i32, ptr @0
        \\  %b = load i32, ptr @"\30"
        \\  %c = load i32, ptr @"val\75e"
        \\  %ab = add i32 %a, %b
        \\  %v = add i32 %ab, %c
        \\  ret i32 %v
        \\}
    );
    defer module.deinit();
    try std.testing.expectEqual(@as(usize, 1), refs.query(&module, "0").direct_uses);
    try std.testing.expectEqual(@as(usize, 1), refs.query(&module, "\"0\"").direct_uses);
    try std.testing.expect(refs.isDirectValue(.{ .named = "@\"val\\75e\"" }, "value"));
    try std.testing.expect(!refs.isDirectValue(.{ .named = "@\"0\"" }, "0"));
    try optimize(&module);
    try std.testing.expectEqual(@as(usize, 0), module.globals.items.len);
    const instructions = module.functions.items[0].blocks.items[0].instructions.items;
    try std.testing.expect(instructions[3].kind.binary.lhs.eql(.{ .int = 11 }));
    try std.testing.expect(instructions[3].kind.binary.rhs.eql(.{ .int = 19 }));
    try std.testing.expect(instructions[4].kind.binary.rhs.eql(.{ .int = 7 }));
}

test "module references: malformed symbol spellings remain unknown" {
    var module = try parse(
        \\@value = internal global i32 7
        \\define ptr @f() {
        \\entry:
        \\  ret ptr @"bad\+1"
        \\}
    );
    defer module.deinit();
    try std.testing.expect(refs.query(&module, "value").has_unknown);
    try std.testing.expect(refs.query(&module, "\"bad\\+1\"").has_unknown);
    try std.testing.expect(refs.hasUnknown(&module));
    module.functions.items[0].blocks.items[0].terminator.?.ret.value = .{ .named = "@" };
    try std.testing.expect(refs.hasUnknown(&module));
}

test "module references: nested expressions and vectors stay unknown without text matching" {
    for ([_][]const u8{
        "@p = global { ptr } { ptr @g }",
        "@p = global [1 x ptr] [ptr getelementptr (i32, ptr @g, i64 0)]",
        "@p = global ptr inttoptr (i64 ptrtoint (ptr @g to i64) to ptr)",
        "@p = global <2 x ptr> <ptr @g, ptr null>",
        // No partial text search may claim these opaque regions are complete.
        "@p = global { i32 } { i32 0 }",
        "@p = global ptr inttoptr (i64 0 to ptr)",
    }) |initializer| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\@g = internal global i32 1
            \\{s}
            \\define i32 @f() {{
            \\entry:
            \\  %v = load i32, ptr @g
            \\  ret i32 %v
            \\}}
        , .{initializer});
        defer std.testing.allocator.free(input);
        var module = try parse(input);
        defer module.deinit();
        const query = refs.query(&module, "g");
        try std.testing.expect(query.direct_uses != 0 and query.has_unknown);
        try std.testing.expect(refs.query(&module, "unrelated").has_unknown);
        try optimize(&module);
        try std.testing.expectEqualStrings("g", module.globals.items[0].name);
        try std.testing.expect(!module.functions.items[0].blocks.items[0].instructions.items[0].removed);
    }
}

const Recorder = struct {
    pub const Error = error{TestUnexpectedResult};
    unknown: *std.EnumSet(refs.OpaqueKind),
    symbols: *usize,
    pub fn visit(visitor: Recorder, _: refs.Site, event: refs.Event) Error!void {
        switch (event) {
            .symbol => visitor.symbols.* += 1,
            .block_address => visitor.symbols.* += 1,
            .unknown => |kind| visitor.unknown.insert(kind),
        }
    }
};

test "module references: raw call fields assembly attributes and metadata are explicit boundaries" {
    var inst: ir.Instruction = .{ .result = null, .kind = .{ .call = .{ .ret_ty = .void, .callee = "sink", .args = .empty } } };
    var unknown: std.EnumSet(refs.OpaqueKind) = .{};
    var symbols: usize = 0;
    const visitor: Recorder = .{ .unknown = &unknown, .symbols = &symbols };
    inst.kind.call.raw_args = "metadata !0";
    inst.kind.call.operand_bundle = "[ opaque ]";
    inst.kind.call.attrs = "unknown_attribute";
    inst.metadata = "!annotation !0";
    try refs.walkInstruction(&inst, visitor);
    try std.testing.expectEqual(@as(usize, 1), symbols);
    inline for (.{ .raw_arguments, .operand_bundle, .attributes, .metadata }) |kind| try std.testing.expect(unknown.contains(kind));
    inst.kind.call.inline_asm = .{ .template = "g", .constraints = "" };
    try refs.walkInstruction(&inst, visitor);
    try std.testing.expect(unknown.contains(.assembly));
    try std.testing.expectEqual(@as(usize, 1), symbols); // not a direct call to sink
    inst.removed = true;
    inst.replacement = .{ .named = "@g" };
    unknown = .{};
    try refs.walkInstruction(&inst, visitor);
    try std.testing.expectEqual(@as(usize, 0), unknown.count());
    try std.testing.expectEqual(@as(usize, 1), symbols);

    var module = try parse(
        \\module asm ".quad g"
        \\@g = internal global i32 7
        \\define i32 @f() #0 {
        \\entry:
        \\  %v = load i32, ptr @g
        \\  ret i32 %v
        \\}
        \\attributes #0 = { nounwind }
        \\!0 = !{ptr @g}
    );
    defer module.deinit();
    try refs.walkModule(&module, visitor);
    try std.testing.expect(unknown.contains(.assembly));
    try std.testing.expect(unknown.contains(.attributes));
    try std.testing.expect(unknown.contains(.metadata));
    try optimize(&module);
    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
}

test "module references: unescaped loads optimize but barriers and raw references retain globals" {
    for ([_][]const u8{ "", "call void asm sideeffect \"\", \"~{memory}\"()", "call void @sink() [ \"deopt\"() ]" }) |body| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\@g = internal global i32 7, align 4
            \\declare void @sink() nounwind
            \\define i32 @f() local_unnamed_addr {{
            \\entry:
            \\  {s}
            \\  %v = load i32, ptr @g, align 4
            \\  ret i32 %v
            \\}}
        , .{body});
        defer std.testing.allocator.free(input);
        var module = try parse(input);
        defer module.deinit();
        try optimize(&module);
        try std.testing.expectEqual(@as(usize, if (body.len == 0) 0 else 1), module.globals.items.len);
    }
    for ([_][]const u8{ "volatile ", "atomic " }) |modifier| {
        const ordering = if (std.mem.eql(u8, modifier, "atomic ")) " monotonic, align 4" else "";
        const input = try std.fmt.allocPrint(
            std.testing.allocator,
            "@g = internal global i32 7\ndefine i32 @f() {{\nentry:\n  %v = load {s}i32, ptr @g{s}\n  ret i32 %v\n}}\n",
            .{ modifier, ordering },
        );
        defer std.testing.allocator.free(input);
        var module = try parse(input);
        defer module.deinit();
        try optimize(&module);
        try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
    }
}

const Reject = struct {
    pub const Error = error{Stopped};
    pub fn visit(_: Reject, _: refs.Site, _: refs.Event) Error!void {
        return error.Stopped;
    }
};

test "module references: visitor errors propagate without allocation" {
    var module = try parse("@g = global i32 0\n@a = alias i32, ptr @g\n");
    defer module.deinit();
    try std.testing.expectError(error.Stopped, refs.walkModule(&module, Reject{}));
    try std.testing.expectEqual(@as(usize, 1), refs.query(&module, "g").direct_uses);
}
