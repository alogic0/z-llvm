//! The existing structural i32 comparison wrappers return the intrinsic result
//! plus one. Emit their comparison locally, retaining that structural owner.
const std = @import("std");
const ir = @import("../../ir.zig");
const machine = @import("machine.zig");
const attrs = @import("generic_cfg/intrinsic_attrs.zig");

pub fn lower(a: std.mem.Allocator, output: *machine.MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2 or function.blocks.items.len != 1 or function.calling_conv != null) return false;
    const block = function.blocks.items[0];
    var instructions: [2]ir.Instruction = undefined;
    var count: usize = 0;
    for (block.instructions.items) |inst| if (!inst.removed) {
        if (count == instructions.len) return false;
        instructions[count] = inst;
        count += 1;
    };
    if (count != 2 or instructions[0].kind != .call or instructions[1].kind != .binary or instructions[0].result == null or instructions[1].result == null) return false;
    const call = instructions[0].kind.call;
    const unsigned = std.mem.eql(u8, call.callee, "llvm.ucmp.i32.i32") or std.mem.eql(u8, call.callee, "llvm.ucmp.i32.i64");
    if (!unsigned and !std.mem.eql(u8, call.callee, "llvm.scmp.i32.i64")) return false;
    const bits: u16 = if (std.mem.endsWith(u8, call.callee, ".i32")) 32 else 64;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2 or !attrs.scalarIntegerCallSupported(call)) return false;
    for (function.params.items, call.args.items) |param, arg| {
        if (!param.ty.eql(.{ .int = bits }) or !arg.ty.eql(param.ty) or arg.value != .named or !ir.identifiers.eql(arg.value.named, param.name)) return false;
        @import("sysv_abi.zig").rejectUnsupportedCallArgAttrs(.{ .ty = param.ty, .attrs = param.attrs, .value = arg.value }) catch return false;
    }
    const add = instructions[1].kind.binary;
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.lhs != .named or !ir.identifiers.eql(add.lhs.named, instructions[0].result.?) or add.rhs != .int or add.rhs.int != 1) return false;
    const term = block.terminator orelse return false;
    if (term != .ret or !term.ret.ty.eql(.{ .int = 32 }) or term.ret.value == null or term.ret.value.? != .named or !ir.identifiers.eql(term.ret.value.?.named, instructions[1].result.?)) return false;
    try output.instructions.appendSlice(a, &.{
        if (bits == 32) .{ .mov_arg_eax = .rsi } else .{ .mov_arg_rax = .rsi },
        if (bits == 32) .{ .mov_eax_to_arg = .rcx } else .{ .mov_rax_to_arg = .rcx },
        if (bits == 32) .{ .cmp_ecx_arg32 = .rdi } else .{ .cmp_rcx_arg64 = .rdi },
        .{ .mov_imm_eax = 1 },
        .{ .je = "__zllvm_scalar_compare_end" },
        .{ .mov_imm_eax = 0 },
        if (unsigned) .{ .jc = "__zllvm_scalar_compare_end" } else .{ .jle = "__zllvm_scalar_compare_end" },
        .{ .mov_imm_eax = 2 },
        .{ .label = "__zllvm_scalar_compare_end" },
        .ret,
    });
    return true;
}

test "structural comparison wrappers preserve owners signedness and exact result range" {
    const compilation = @import("../../compilation.zig");
    const encoding = @import("../../mc/encoding.zig");
    inline for (.{ .{ "ucmp", @as(u16, 32) }, .{ "ucmp", @as(u16, 64) }, .{ "scmp", @as(u16, 64) } }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i32 @llvm.{s}.i32.i{d}(i{d},i{d})\ndefine i32 @compare(i{d} %a,i{d} %b) {{\nentry:\n %r = tail call i32 @llvm.{s}.i32.i{d}(i{d} %a,i{d} %b)\n %v = add i32 %r,1\n ret i32 %v\n}}\n", .{ case[0], case[1], case[1], case[1], case[1], case[1], case[0], case[1], case[1], case[1] });
        defer std.testing.allocator.free(text);
        var source = try ir.Module.parse(std.testing.allocator, text);
        defer source.deinit();
        try source.verify();
        var selected = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", source.functions.items[0], .{ .generic_cfg_selector = true });
        defer selected.deinit(std.testing.allocator);
        try std.testing.expectEqual(machine.SelectionOwner.structural_fallback, selected.selection_owner);
        const bytes = try encoding.encodeFunction(std.testing.allocator, selected);
        defer std.testing.allocator.free(bytes);
        const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..bytes.len], bytes);
        const T = if (case[1] == 32) u32 else u64;
        const S = if (case[1] == 32) i32 else i64;
        const run: *const fn (T, T) callconv(.c) i32 = @ptrCast(memory.ptr);
        for ([_]T{ 0, 1, 2, std.math.maxInt(T), @as(T, 1) << (case[1] - 1), std.math.maxInt(T) >> 1 }) |a| for ([_]T{ 0, 1, 2, std.math.maxInt(T), @as(T, 1) << (case[1] - 1), std.math.maxInt(T) >> 1 }) |b| {
            const expected: i32 = if (std.mem.eql(u8, case[0], "scmp")) blk: {
                const lhs: S = @bitCast(a);
                const rhs: S = @bitCast(b);
                break :blk if (lhs < rhs) 0 else if (lhs > rhs) 2 else 1;
            } else if (a < b) 0 else if (a > b) 2 else 1;
            try std.testing.expectEqual(expected, run(a, b));
        };
    }
}
