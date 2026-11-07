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
    var failed: usize = 0;
    for (module.functions.items, 0..) |f, i| {
        functions[i] = f;
        const diagnostic: ?[]const u8 = if (view.verify()) |_| null else |err| blk: {
            if (err == error.OutOfMemory) return err;
            failed += 1;
            break :blk @errorName(err);
        };
        try std.json.Stringify.value(.{ .function = f.name, .error_name = diagnostic }, .{}, w);
        try w.writeByte('\n');
        functions[i].blocks = blocks;
    }
    try std.json.Stringify.value(.{ .definitions = functions.len, .passed_verification_in_context = functions.len - failed, .rejected = failed, .codegen_attempted = false }, .{}, w);
    try w.writeByte('\n');
    try w.flush();
}
