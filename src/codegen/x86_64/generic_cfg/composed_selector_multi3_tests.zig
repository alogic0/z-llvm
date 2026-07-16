const std = @import("std");
const ir = @import("../../../ir.zig");
const assembly = @import("../../../mc/assembly.zig");
const encoding = @import("../../../mc/encoding.zig");
const impl = @import("composed_selector_impl.zig");

const frozen_multi3_ir = @embedFile("testdata/compiler_rt_multi3.ll");
const commit4_instruction_stream_sha256 = "8f962b4bda72349aac1464efd86f13daf18ae3595171d7f32548feb46ee82e61";
const commit4_symbol_bytes_sha256 = "f1c97aee4bb07d1ef27ebd12ec2236a2a390faaa95514436dfb282af5e2149ec";

test "frozen multi3 selector and exact machine identity" {
    var module = try ir.Module.parse(std.testing.allocator, frozen_multi3_ir);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(@as(usize, 1), module.functions.items.len);

    var machine = impl.MachineFunction.init("__multi3", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);
    const selection = try impl.tryLowerComposedBlock(std.testing.allocator, &machine, module.functions.items[0]);
    switch (selection) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("__multi3 selector diagnostic {s}/{s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestUnexpectedResult;
        },
    }

    var assembly_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer assembly_output.deinit();
    try assembly.printFunction(machine, &assembly_output.writer);
    try std.testing.expectEqualStrings(
        commit4_instruction_stream_sha256,
        &sha256Hex(assembly_output.writer.buffered()),
    );

    const symbol_bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(symbol_bytes);
    try std.testing.expectEqual(@as(usize, 536), symbol_bytes.len);
    try std.testing.expectEqualStrings(commit4_symbol_bytes_sha256, &sha256Hex(symbol_bytes));
}

fn sha256Hex(contents: []const u8) [64]u8 {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}
