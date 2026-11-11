const std = @import("std");
const ir = @import("../../../ir.zig");
const queries = @import("hardware_queries.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

const source =
    \\define i128 @query(i32 %leaf,i32 %subleaf,i128 %live) {
    \\entry:
    \\ %r = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}"(i32 %leaf,i32 %subleaf)
    \\ %a = extractvalue { i32, i32, i32, i32 } %r,0
    \\ %b = extractvalue { i32, i32, i32, i32 } %r,1
    \\ %c = extractvalue { i32, i32, i32, i32 } %r,2
    \\ %d = extractvalue { i32, i32, i32, i32 } %r,3
    \\ %aw = zext i32 %a to i128
    \\ %bw = zext i32 %b to i128
    \\ %cw = zext i32 %c to i128
    \\ %dw = zext i32 %d to i128
    \\ %bs = shl i128 %bw,32
    \\ %cs = shl i128 %cw,64
    \\ %ds = shl i128 %dw,96
    \\ %lo = or i128 %aw,%bs
    \\ %hi = or i128 %cs,%ds
    \\ %packed = or i128 %lo,%hi
    \\ %answer = xor i128 %packed,%live
    \\ ret i128 %answer
    \\}
;

fn oracle() u128 {
    var a: u32 = undefined;
    var b: u32 = undefined;
    var c: u32 = undefined;
    var d: u32 = undefined;
    asm volatile ("cpuid"
        : [_] "={eax}" (a),
          [_] "={ebx}" (b),
          [_] "={ecx}" (c),
          [_] "={edx}" (d),
        : [_] "{eax}" (@as(u32, 0)),
          [_] "{ecx}" (@as(u32, 0)),
    );
    return @as(u128, a) | (@as(u128, b) << 32) | (@as(u128, c) << 64) | (@as(u128, d) << 96);
}

test "native CPU queries reject mismatched constraints and malformed private results" {
    for ([_][2][]const u8{
        .{ "={ebx}", "={esi}" },
        .{ "~{flags}", "~{flags},~{memory}" },
        .{ "asm sideeffect", "asm" },
    }) |change| {
        const invalid = try std.mem.replaceOwned(u8, std.testing.allocator, source, change[0], change[1]);
        defer std.testing.allocator.free(invalid);
        var module = try ir.Module.parse(std.testing.allocator, invalid);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try queries.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const private = (try queries.legalize(arena.allocator(), module.functions.items[0], null)).?;
    var malformed = private.blocks.items[0].instructions.items[0].kind.call;
    malformed.ret_ty = .{ .int = 64 };
    try std.testing.expect(!queries.validCarrier(malformed));
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind.call.native_query == null);
}

test "native CPU queries preserve packed outputs live pairs and original IR" {
    for ([_]bool{ false, true }) |constant| {
        const input = if (constant) try std.mem.replaceOwned(u8, std.testing.allocator, source, "(i32 %leaf,i32 %subleaf)", "(i32 0,i32 0)") else try std.testing.allocator.dupe(u8, source);
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const expanded = (try queries.legalize(arena.allocator(), original, null)).?;
        if (!constant) try std.testing.expect(expanded.blocks.items[0].instructions.items[0].kind.call.native_query == .cpuid);
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.call.native_query == null);
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = expanded;
        try private.verify();
        var output = machine.MachineFunction.init(original.name, original.ret_ty);
        defer output.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, original));
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (u32, u32, u128) callconv(.c) u128 = @ptrCast(code.ptr);
        const expected = oracle();
        for ([_]u128{ 0, 1, std.math.maxInt(u128), @as(u128, 1) << 127, 0xdeadbeef0123456787654321fedcba98 }) |live|
            try std.testing.expectEqual(expected ^ live, run(0, 0, live));
        try module.verify();
    }
}

test "native CPU query macros have balanced encodings and clobber flags" {
    try std.testing.expectEqual(@as(u32, 18), encoding.instructionSize(.cpuid_packed));
    try std.testing.expectEqual(@as(u32, 5), encoding.instructionSize(.xgetbv_eax));
    const eflags = @import("composed_selector_eflags.zig");
    try std.testing.expectEqual(eflags.Effect.clobber, eflags.instructionEffect(.cpuid_packed));
    try std.testing.expectEqual(eflags.Effect.clobber, eflags.instructionEffect(.xgetbv_eax));
}
