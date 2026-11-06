const std = @import("std");
const ir = @import("../ir.zig");
const compilation = @import("../compilation.zig");
const artifact = @import("../compilation_artifact.zig");

test "compilation preparation makes optimization explicit and honors pass limits" {
    const source =
        \\define i32 @answer() {
        \\entry:
        \\ %v = add i32 40, 2
        \\ ret i32 %v
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var diagnostic = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer diagnostic.deinit();
    try compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{});
    try std.testing.expectEqual(@as(usize, 1), module.functions.items[0].blocks.items[0].instructions.items.len);
    try compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{
        .optimization = "instcombine,dce",
        .passes = .{ .pass_limit = 0 },
    });
    try std.testing.expectEqual(@as(usize, 1), module.functions.items[0].blocks.items[0].instructions.items.len);
    try compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{
        .optimization = "instcombine,dce",
        .passes = .{ .trace = true },
    });
    try std.testing.expectEqual(@as(i128, 42), module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.int);
    try std.testing.expect(std.mem.indexOf(u8, diagnostic.written(), "; before instcombine") != null);
    try std.testing.expectError(error.UnknownPass, compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{ .optimization = "not-a-pass" }));
}

test "structured preparation preserves transport and composes deferred stages" {
    const allocator = std.testing.allocator;
    const envelope = "; structured recipe\nnot LLVM IR";
    var first = std.Io.Writer.Allocating.init(allocator);
    defer first.deinit();
    try artifact.write(allocator, &first.writer, envelope, .{
        .optimization = "instcombine,dce",
        .passes = .{ .pass_limit = 0 },
    });
    var module = try ir.Module.parse(allocator,
        \\define i32 @answer() {
        \\entry:
        \\ %v = add i32 40, 2
        \\ ret i32 %v
        \\}
    );
    defer module.deinit();
    var diagnostic = std.Io.Writer.Allocating.init(allocator);
    defer diagnostic.deinit();
    try artifact.prepare(allocator, null, &module, &diagnostic.writer, first.written());
    try std.testing.expectEqual(@as(usize, 1), module.functions.items[0].blocks.items[0].instructions.items.len);
    var second = std.Io.Writer.Allocating.init(allocator);
    defer second.deinit();
    try artifact.write(allocator, &second.writer, first.written(), .{
        .optimization = "instcombine,dce",
        .passes = .{ .trace = true },
    });
    try std.testing.expect(std.mem.endsWith(u8, second.written(), envelope));
    try std.testing.expectEqual(@as(usize, 1), std.mem.count(u8, second.written(), artifact.prefix));
    try artifact.prepare(allocator, null, &module, &diagnostic.writer, second.written());
    try std.testing.expectEqual(@as(i128, 42), module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.int);
    try std.testing.expect(std.mem.indexOf(u8, diagnostic.written(), "; before instcombine") != null);
    var unchanged = std.Io.Writer.Allocating.init(allocator);
    defer unchanged.deinit();
    try artifact.write(allocator, &unchanged.writer, second.written(), .{});
    try std.testing.expectEqualStrings(second.written(), unchanged.written());
}

test "structured preparation rejects invalid requests before transport output" {
    const allocator = std.testing.allocator;
    var output = std.Io.Writer.Allocating.init(allocator);
    defer output.deinit();
    try std.testing.expectError(error.UnknownPass, artifact.write(allocator, &output.writer, "recipe", .{ .optimization = "not-a-pass" }));
    try std.testing.expectError(error.UnknownPass, artifact.write(allocator, &output.writer, artifact.prefix ++ "[{\"optimization\":\"not-a-pass\"}]\nrecipe", .{}));
    try std.testing.expectError(error.DuplicateDeferredPreparation, artifact.write(allocator, &output.writer, artifact.prefix ++ "[]\n" ++ artifact.prefix ++ "[]\nrecipe", .{}));
    try std.testing.expectError(error.SyntaxError, artifact.write(allocator, &output.writer, artifact.prefix ++ "invalid\nrecipe", .{}));
    try std.testing.expectError(error.ArtifactPassOptionsRequireExplicitOptimization, artifact.write(allocator, &output.writer, "recipe", .{ .passes = .{ .trace = true } }));
    try std.testing.expectEqual(@as(usize, 0), output.written().len);
}

test "compilation selection accepts a folded narrow comparison without text roundtrip" {
    const allocator = std.testing.allocator;
    var module = try ir.Module.parse(allocator,
        \\define i32 @main() {
        \\entry:
        \\ %flag = icmp slt i8 -128, 0
        \\ %ret = select i1 %flag, i32 0, i32 1
        \\ ret i32 %ret
        \\}
    );
    defer module.deinit();
    var diagnostics = std.Io.Writer.Allocating.init(allocator);
    defer diagnostics.deinit();
    try compilation.prepare(allocator, null, &module, &diagnostics.writer, .{ .optimization = "zig-release-fast-accepted" });
    for ([_]bool{ false, true }) |generic| {
        var machine = try compilation.select(allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = generic });
        defer machine.deinit(allocator);
        try std.testing.expect(machine.instructions.items.len > 0);
    }
}

test "structured TLS globals use the same verified attributes as textual IR" {
    const builder = @import("../structured_ir_builder.zig");
    const allocator = std.testing.allocator;
    var direct = try builder.DirectBuilder.init(allocator, null, "x86_64-unknown-linux-gnu");
    defer direct.deinit();
    direct.activate();
    defer direct.deactivate();
    var text = std.Io.Writer.Allocating.init(allocator);
    defer text.deinit();
    var output = builder.Module.init(&text.writer);
    try output.tlsGlobal("tls_counter", "internal", "localexec", .i32, "1", "4");
    var parsed = try ir.Module.parse(allocator, text.written());
    defer parsed.deinit();
    try parsed.verify();
    try direct.module.verify();
    try std.testing.expectEqualStrings(parsed.globals.items[0].address_attrs.?, direct.module.globals.items[0].address_attrs.?);
}

test "structured adapter cases verify before and after explicit preparation" {
    const adapter = @import("../main_flow_ir_writer.zig");
    const cases = @import("../main_flow_ir_writer_cases.zig");
    var diagnostics = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer diagnostics.deinit();
    var failures: usize = 0;
    for (cases.ir_writer_cases) |case| {
        if (case.construction != .structured_builder) continue;
        var module = try adapter.buildStructuredDirectModule(std.testing.allocator, std.testing.io, case);
        defer module.deinit();
        compilation.prepare(std.testing.allocator, std.testing.io, &module, &diagnostics.writer, .{ .optimization = "zig-release-fast-accepted" }) catch |err| {
            std.debug.print("structured preparation failed: {s}: {s}\n", .{ case.id, @errorName(err) });
            failures += 1;
        };
    }
    try std.testing.expectEqual(@as(usize, 0), failures);
}

test "direct descriptor programs verify under shared preparation" {
    const builder = @import("../structured_ir_builder.zig");
    const descriptor = @import("../semantic_descriptor_v2.zig");
    var diagnostics = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer diagnostics.deinit();
    var failures: usize = 0;
    for (std.enums.values(descriptor.Body)) |body| {
        const source: descriptor.Source = .{ .wrapper = "contract.zig", .fixture = "-", .mode = "ReleaseFast", .tag = "-" };
        const program = descriptor.programFromSourceFactProgramDirect(source, body, descriptor.bodyName(body)) orelse continue;
        var direct = try builder.DirectBuilder.init(std.testing.allocator, null, "x86_64-unknown-linux-gnu");
        defer direct.deinit();
        direct.activate();
        defer direct.deactivate();
        try descriptor.lowerToStructuredIr(program, &diagnostics.writer);
        compilation.prepare(std.testing.allocator, std.testing.io, &direct.module, &diagnostics.writer, .{ .optimization = "zig-release-fast-accepted" }) catch |err| {
            std.debug.print("descriptor preparation failed: {s}: {s}\n", .{ @tagName(body), @errorName(err) });
            failures += 1;
        };
    }
    try std.testing.expectEqual(@as(usize, 0), failures);
}

test "compilation selection admits a closed loop and rejects trailing fallthrough" {
    const verify = @import("../codegen/x86_64/verify.zig");
    var module = try ir.Module.parse(std.testing.allocator,
        \\define void @spin() {
        \\entry:
        \\ br label %loop
        \\loop:
        \\ br label %loop
        \\}
    );
    defer module.deinit();
    var machine = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer machine.deinit(std.testing.allocator);
    for (machine.instructions.items) |instruction| try std.testing.expect(instruction != .ret and instruction != .ud2);
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 0 });
    try std.testing.expectError(error.MissingMachineReturn, verify.verifyFunction(machine));
    machine.instructions.items[machine.instructions.items.len - 1] = .{ .jmp = "missing" };
    try std.testing.expectError(error.InvalidBranchTarget, verify.verifyFunction(machine));
}
