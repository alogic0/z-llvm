//! Body projections diagnose verifier failures while keeping module context.
//! No projected program is emitted or executed. Requires an explicit ir module.
const std = @import("std");
const ir = @import("ir");
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);
    if (args.len != 2) return error.ExpectedInput;
    const input = try std.Io.Dir.cwd().readFileAlloc(init.io, args[1], a, .limited(2 * 1024 * 1024 * 1024));
    var module = try ir.Module.parse(init.gpa, input);
    defer module.deinit();
    var output_buffer: [65536]u8 = undefined;
    var output = std.Io.File.stdout().writerStreaming(init.io, &output_buffer);
    const w = &output.interface;
    const full_error: ?[]const u8 = if (module.verify()) |_| null else |err| blk: {
        if (err == error.OutOfMemory) return err;
        break :blk @errorName(err);
    };
    try std.json.Stringify.value(.{ .scope = "verification diagnostic only; other function bodies replaced with unreachable; full module declarations and data preserved", .definitions = module.functions.items.len, .full_module_error = full_error }, .{}, w);
    try w.writeByte('\n');
    try w.flush();
    var placeholder = [_]ir.BasicBlock{ir.BasicBlock.init("diagnostic_entry")};
    placeholder[0].terminator = .{ .@"unreachable" = {} };
    var blocks: std.ArrayList(ir.BasicBlock) = .empty;
    blocks.items = &placeholder;
    blocks.capacity = 1;
    const functions = try a.dupe(ir.Function, module.functions.items);
    for (functions) |*f| f.blocks = blocks;
    var view = module;
    view.functions = .empty;
    view.functions.items = functions;
    view.functions.capacity = functions.len;
    // Refuse a census if module/header context itself already fails.
    try view.verify();
    const diagnostics = try a.alloc(?[]const u8, functions.len);
    @memset(diagnostics, null);
    // Successful ranges certify every body in that range with the same module
    // context. Split only failing ranges, instead of rebuilding all module
    // lookups once per definition in a large compiler input.
    if (full_error != null) try diagnoseBodies(module, view, blocks, diagnostics, 0, functions.len);
    var failed: usize = 0;
    for (module.functions.items, 0..) |f, i| {
        const diagnostic = diagnostics[i];
        if (diagnostic != null) failed += 1;
        try std.json.Stringify.value(.{ .function = f.name, .error_name = diagnostic }, .{}, w);
        try w.writeByte('\n');
    }
    try std.json.Stringify.value(.{ .definitions = functions.len, .passed_verification_in_context = functions.len - failed, .rejected = failed, .codegen_attempted = false }, .{}, w);
    try w.writeByte('\n');
    try w.flush();
}

fn diagnoseBodies(original: ir.Module, view: ir.Module, placeholder: std.ArrayList(ir.BasicBlock), diagnostics: []?[]const u8, start: usize, end: usize) !void {
    if (start == end) return;
    for (start..end) |i| view.functions.items[i].blocks = original.functions.items[i].blocks;
    const failure: ?anyerror = if (view.verify()) |_| null else |err| err;
    for (start..end) |i| view.functions.items[i].blocks = placeholder;
    const err = failure orelse return;
    if (err == error.OutOfMemory) return err;
    if (end - start == 1) {
        diagnostics[start] = @errorName(err);
        return;
    }
    const mid = start + (end - start) / 2;
    try diagnoseBodies(original, view, placeholder, diagnostics, start, mid);
    try diagnoseBodies(original, view, placeholder, diagnostics, mid, end);
}

test "body census splits independent failures and preserves cross-function context" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare i32 @external(i32)
        \\define i32 @good(i32 %x) {
        \\entry:
        \\ %v = call i32 @external(i32 %x)
        \\ ret i32 %v
        \\}
        \\define i32 @bad_type(float %x) {
        \\entry:
        \\ ret i32 %x
        \\}
        \\define i32 @good_call(i32 %x) {
        \\entry:
        \\ %v = call i32 @good(i32 %x)
        \\ ret i32 %v
        \\}
        \\define i32 @bad_value() {
        \\entry:
        \\ ret i32 %unknown
        \\}
    );
    defer module.deinit();
    var entry = [_]ir.BasicBlock{ir.BasicBlock.init("diagnostic_entry")};
    entry[0].terminator = .{ .@"unreachable" = {} };
    var placeholder: std.ArrayList(ir.BasicBlock) = .empty;
    placeholder.items = &entry;
    placeholder.capacity = entry.len;
    const functions = try std.testing.allocator.dupe(ir.Function, module.functions.items);
    defer std.testing.allocator.free(functions);
    for (functions) |*f| f.blocks = placeholder;
    var view = module;
    view.functions = .empty;
    view.functions.items = functions;
    view.functions.capacity = functions.len;
    try view.verify();
    var diagnostics = [_]?[]const u8{ null, null, null, null };
    try diagnoseBodies(module, view, placeholder, &diagnostics, 0, 4);
    try std.testing.expect(diagnostics[0] == null and diagnostics[2] == null);
    try std.testing.expectEqualStrings("TypeMismatch", diagnostics[1].?);
    try std.testing.expectEqualStrings("UnknownValue", diagnostics[3].?);
    try view.verify();
    try std.testing.expectError(error.TypeMismatch, module.verify());
}
