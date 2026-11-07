//! Enumerate rejected call contracts in an unchanged, verified module. These
//! are observations of all calls, not first-failure or capability counts.
const std = @import("std");
const ir = @import("ir.zig");
const sysv = @import("codegen/x86_64/sysv_abi.zig");

pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);
    if (args.len != 2) return error.ExpectedInput;
    const input = try std.Io.Dir.cwd().readFileAlloc(init.io, args[1], a, .limited(2 * 1024 * 1024 * 1024));
    var module = try ir.Module.parse(a, input);
    defer module.deinit();
    try module.verify();
    var buffer: [16384]u8 = undefined;
    var writer = std.Io.File.stdout().writerStreaming(init.io, &buffer);
    for (module.functions.items) |function| for (function.blocks.items) |block| for (block.instructions.items, 0..) |inst, index| {
        if (inst.removed or inst.kind != .call) continue;
        const call = inst.kind.call;
        sysv.rejectUnsupportedCallEnvelope(call) catch |err| {
            try std.json.Stringify.value(.{
                .function = function.name,
                .block = block.name,
                .instruction = index,
                .callee = call.callee,
                .contract = "envelope",
                .diagnostic = @errorName(err),
                .ret_attrs = call.ret_attrs,
                .call_attrs = call.attrs,
                .inline_asm = call.inline_asm != null,
                .operand_bundle = call.operand_bundle,
            }, .{}, &writer.interface);
            try writer.interface.writeByte('\n');
        };
        for (call.args.items, 0..) |arg, arg_index| sysv.rejectUnsupportedCallArgAttrs(arg) catch |err| {
            try std.json.Stringify.value(.{
                .function = function.name,
                .block = block.name,
                .instruction = index,
                .callee = call.callee,
                .contract = "argument",
                .diagnostic = @errorName(err),
                .argument = arg_index,
                .type = @tagName(arg.ty),
                .attrs = arg.attrs,
            }, .{}, &writer.interface);
            try writer.interface.writeByte('\n');
        };
    };
    try writer.interface.flush();
}
