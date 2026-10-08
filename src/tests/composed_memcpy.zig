const std = @import("std");
const ir = @import("../ir.zig");
const impl = @import("../codegen/x86_64/generic_cfg/composed_selector_impl.zig");
const verify = @import("../codegen/x86_64/verify.zig");
const encoding = @import("../mc/encoding.zig");
const assembly = @import("../mc/assembly.zig");

fn check(source: []const u8, expected: ?[]const u8) !void {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const function = module.functions.items[0];
    var machine = impl.MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    const result = impl.tryLowerComposedCfg(std.testing.allocator, &machine, function) catch |err| {
        if (expected) |detail| if (std.mem.eql(u8, detail, @errorName(err))) return;
        return err;
    };
    if (expected) |detail| {
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqualStrings(detail, result.unsupported.detail());
    } else {
        if (result == .unsupported) std.debug.print("unexpected memcpy rejection: {s}\n", .{result.unsupported.detail()});
        try std.testing.expect(result == .selected);
        try verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        try std.testing.expect(bytes.len > 0);
    }
}

test "composed memcpy accepts ordinary intrinsic with retained pointer attributes" {
    try check(
        \\define ptr @copy(ptr %d, ptr %s, i64 %n) {
        \\entry:
        \\ tail call void @llvm.experimental.noalias.scope.decl(metadata !0)
        \\ tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %d, ptr readonly align 16 %s, i64 %n, i1 false)
        \\ ret ptr %d
        \\}
    , null);
}

test "composed memcpy rejects malformed markers and unsupported intrinsic neighbors" {
    const variants = [_]struct { call: []const u8, detail: []const u8 }{
        .{ .call = "call void @llvm.experimental.noalias.scope.decl(i64 %n)", .detail = "composed-block-noalias-scope-decl" },
        .{ .call = "call void @llvm.experimental.noalias.scope.decl(metadata %s)", .detail = "composed-block-noalias-scope-decl" },
        .{ .call = "musttail call void @llvm.experimental.noalias.scope.decl(metadata !0)", .detail = "composed-block-noalias-scope-decl" },
        .{ .call = "call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 %n, i1 true)", .detail = "composed-block-memcpy-args" },
        .{ .call = "call void @llvm.memcpy.p0.p0.i64(ptr addrspace(1) %d, ptr %s, i64 %n, i1 false)", .detail = "composed-block-memcpy-attrs" },
        .{ .call = "call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr byval(i64) %s, i64 %n, i1 false)", .detail = "composed-block-memcpy-attrs" },
        .{ .call = "call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 0, i1 false)", .detail = "composed-block-memcpy-len" },
        .{ .call = "call void @llvm.memcpy.p0.p0.i32(ptr %d, ptr %s, i32 1, i1 false)", .detail = "composed-block-llvm-intrinsic" },
        .{ .call = "call void @llvm.memcpy.p1.p0.i64(ptr %d, ptr %s, i64 %n, i1 false)", .detail = "composed-block-llvm-intrinsic" },
        .{ .call = "call void @llvm.memmove.p1.p0.i64(ptr %d, ptr %s, i64 %n, i1 false)", .detail = "composed-block-llvm-intrinsic" },
    };
    for (variants) |v| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define ptr @copy(ptr %d, ptr %s, i64 %n) {{\nentry:\n {s}\n ret ptr %d\n}}\n", .{v.call});
        defer std.testing.allocator.free(text);
        try check(text, v.detail);
    }
}

test "composed memcpy byte and vector transfers preserve values across copies" {
    try check(
        \\define i64 @copy(ptr %d, ptr %s, i64 %n) {
        \\entry:
        \\ %v = load <16 x i8>, ptr %s, align 1
        \\ %byte = load i8, ptr %s, align 1
        \\ %addr = ptrtoint ptr %s to i64
        \\ %low = and i64 %addr, 15
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 %n, i1 false)
        \\ store <16 x i8> %v, ptr %d, align 1
        \\ store i8 %byte, ptr %d, align 1
        \\ ret i64 %low
        \\}
    , null);
}

test "composed memcpy reserves staging for dying pointer arithmetic" {
    try check(
        \\define void @copy(ptr %d, ptr %s, i64 %n) {
        \\entry:
        \\ %offset = add i64 %n, 1
        \\ %from = getelementptr i8, ptr %s, i64 %offset
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %from, i64 %n, i1 false)
        \\ ret void
        \\}
    , null);
}

test "composed memcpy memory transfers reject barriers address spaces and vector neighbors" {
    const variants = [_]struct { body: []const u8, detail: []const u8 }{
        .{ .body = "%v = load volatile <16 x i8>, ptr %s, align 1", .detail = "composed-block-load-barrier" },
        .{ .body = "%v = load <16 x i8>, ptr addrspace(1) %s, align 1", .detail = "composed-block-byte-vector-addrspace" },
        .{ .body = "%v = load i8, ptr addrspace(1) %s, align 1", .detail = "composed-block-byte-load-addrspace" },
        .{ .body = "store volatile i8 42, ptr %d, align 1", .detail = "composed-block-store-barrier" },
        .{ .body = "store i8 42, ptr addrspace(1) %d, align 1", .detail = "composed-block-byte-store-addrspace" },
        .{ .body = "%v = load <32 x i8>, ptr %s, align 1", .detail = "UnsupportedCodegenValue" },
        .{ .body = "%v = load <16 x i8>, ptr %s, align 1\n store volatile <16 x i8> %v, ptr %d, align 1", .detail = "composed-block-store-barrier" },
        .{ .body = "%v = load <16 x i8>, ptr %s, align 1\n store <16 x i8> %v, ptr addrspace(1) %d, align 1", .detail = "composed-block-byte-vector-addrspace" },
    };
    for (variants) |v| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define void @copy(ptr %d, ptr %s) {{\nentry:\n {s}\n ret void\n}}\n", .{v.body});
        defer std.testing.allocator.free(text);
        try check(text, v.detail);
    }
}

test "composed memcpy ptrtoint stays limited to named default-space 64-bit pointers" {
    try check("define i32 @bad(ptr %p) {\nentry:\n %v = ptrtoint ptr %p to i32\n ret i32 %v\n}\n", "composed-block-ptrtoint-form");
    try check("define i64 @bad(ptr %p) {\nentry:\n %v = ptrtoint ptr addrspace(1) %p to i64\n ret i64 %v\n}\n", "composed-block-ptrtoint-form");
}

test "composed memcpy unaligned vector encoding and assembly preserve aligned default" {
    var machine = impl.MachineFunction.init("move_bytes", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.appendSlice(std.testing.allocator, &.{
        .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 0, .unaligned = true } },
        .{ .store_f128_xmm0_arg_ptr = .{ .reg = .r8, .offset = 3, .unaligned = true } },
        .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 0 } },
        .ret,
    });
    try verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0x0f, 0x10, 0x06, 0x41, 0x0f, 0x11, 0x40, 0x03, 0x0f, 0x28, 0x06, 0xc3 }, bytes);
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try assembly.printFunction(machine, &output.writer);
    try std.testing.expect(std.mem.indexOf(u8, output.written(), "movups 0(%rsi), %xmm0") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.written(), "movups %xmm0, 3(%r8)") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.written(), "movaps 0(%rsi), %xmm0") != null);
}

test "composed memcpy leaves cyclic byte vector transfers outside the admitted scope" {
    // 1. Load without store in cyclic block
    for ([_][]const u8{
        "%v = load <16 x i8>, ptr %s, align 1",
    }) |body| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define void @copy(ptr %d, ptr %s, i32 %flag) {{\nentry:\n %again = icmp ne i32 %flag, 0\n br label %loop\nloop:\n {s}\n br i1 %again, label %loop, label %done\ndone:\n ret void\n}}\n", .{body});
        defer std.testing.allocator.free(text);
        try check(text, "composed-block-byte-transfer-cyclic-cfg");
    }

    // 2. Intervening load before store in cyclic block (overlapping XMM usage)
    {
        const text =
            \\define void @overlapping_loads(ptr %d1, ptr %d2, ptr %s1, ptr %s2, i32 %flag) {
            \\entry:
            \\ %again = icmp ne i32 %flag, 0
            \\ br label %loop
            \\loop:
            \\ %v1 = load <16 x i8>, ptr %s1, align 1
            \\ %v2 = load <16 x i8>, ptr %s2, align 1
            \\ store <16 x i8> %v1, ptr %d1, align 1
            \\ store <16 x i8> %v2, ptr %d2, align 1
            \\ br i1 %again, label %loop, label %done
            \\done:
            \\ ret void
            \\}
        ;
        try check(text, "composed-block-byte-transfer-cyclic-cfg");
    }

    // 3. Escaping vector use outside the cyclic block
    {
        const text =
            \\define void @escaping_vector(ptr %d, ptr %s, i32 %flag) {
            \\entry:
            \\ %again = icmp ne i32 %flag, 0
            \\ br label %loop
            \\loop:
            \\ %v = load <16 x i8>, ptr %s, align 1
            \\ br i1 %again, label %loop, label %done
            \\done:
            \\ store <16 x i8> %v, ptr %d, align 1
            \\ ret void
            \\}
        ;
        try check(text, "composed-block-byte-transfer-cyclic-cfg");
    }

    // 4. Store of vector defined outside the cyclic block
    {
        const text =
            \\define void @vector_defined_outside(ptr %d, ptr %s, i32 %flag) {
            \\entry:
            \\ %again = icmp ne i32 %flag, 0
            \\ %v = load <16 x i8>, ptr %s, align 1
            \\ br label %loop
            \\loop:
            \\ store <16 x i8> %v, ptr %d, align 1
            \\ br i1 %again, label %loop, label %done
            \\done:
            \\ ret void
            \\}
        ;
        try check(text, "composed-block-byte-transfer-cyclic-cfg");
    }

    // 5. Conflicting loop-carried XMM phi in cyclic CFG
    {
        const text =
            \\define void @conflicting_fp_phi(ptr %d, ptr %s, i32 %flag) {
            \\entry:
            \\ %again = icmp ne i32 %flag, 0
            \\ br label %loop
            \\loop:
            \\ %acc = phi double [ 0.0, %entry ], [ %acc.next, %loop ]
            \\ %v = load <16 x i8>, ptr %s, align 1
            \\ store <16 x i8> %v, ptr %d, align 1
            \\ %acc.next = fadd double %acc, 1.0
            \\ br i1 %again, label %loop, label %done
            \\done:
            \\ ret void
            \\}
        ;
        try check(text, "composed-block-byte-transfer-cyclic-cfg");
    }
}

test "composed memcpy admits cyclic byte vector transfers with verified loop-carried XMM safety" {
    const text =
        \\define void @vector_copy_loop(ptr %d, ptr %s, i64 %n) {
        \\entry:
        \\  %empty = icmp eq i64 %n, 0
        \\  br i1 %empty, label %done, label %loop
        \\loop:
        \\  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %sp = getelementptr i8, ptr %s, i64 %i
        \\  %v = load <16 x i8>, ptr %sp, align 1
        \\  %dp = getelementptr i8, ptr %d, i64 %i
        \\  store <16 x i8> %v, ptr %dp, align 1
        \\  %next = add i64 %i, 16
        \\  %end = icmp eq i64 %next, %n
        \\  br i1 %end, label %done, label %loop
        \\done:
        \\  ret void
        \\}
    ;
    try check(text, null);

    // Verify machine structure and assembly
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    const function = module.functions.items[0];
    var machine = impl.MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    const result = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function);
    try std.testing.expect(result == .selected);
    try verify.verifyFunction(machine);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try assembly.printFunction(machine, &output.writer);
    const asm_text = output.written();
    try std.testing.expect(std.mem.indexOf(u8, asm_text, "movups 0(%rcx), %xmm0") != null);
    try std.testing.expect(std.mem.indexOf(u8, asm_text, "movups %xmm0, 0(%rcx)") != null);

    // Verify bit-exact runtime execution
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const copy_fn: *const fn ([*]u8, [*]const u8, u64) callconv(.c) void = @ptrCast(mapping.ptr);

    var src: [64]u8 = undefined;
    for (&src, 0..) |*b, i| b.* = @intCast(i + 1);
    var dst: [64]u8 = @splat(0);

    // Test copy 64 bytes (4 vector iterations)
    copy_fn(&dst, &src, 64);
    try std.testing.expectEqualSlices(u8, &src, &dst);

    // Test copy 32 bytes (2 vector iterations)
    @memset(&dst, 0);
    copy_fn(&dst, &src, 32);
    try std.testing.expectEqualSlices(u8, src[0..32], dst[0..32]);
    try std.testing.expectEqual(@as(u8, 0), dst[32]);

    // Test copy 0 bytes (0 iterations)
    @memset(&dst, 0);
    copy_fn(&dst, &src, 0);
    try std.testing.expectEqual(@as(u8, 0), dst[0]);
}

test "composed memcpy admits sequential cyclic byte vector transfers in same loop block" {
    const text =
        \\define void @multi_vector_copy_loop(ptr %d1, ptr %d2, ptr %s1, ptr %s2, i64 %n) {
        \\entry:
        \\  %empty = icmp eq i64 %n, 0
        \\  br i1 %empty, label %done, label %loop
        \\loop:
        \\  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %sp1 = getelementptr i8, ptr %s1, i64 %i
        \\  %v1 = load <16 x i8>, ptr %sp1, align 1
        \\  %dp1 = getelementptr i8, ptr %d1, i64 %i
        \\  store <16 x i8> %v1, ptr %dp1, align 1
        \\  %sp2 = getelementptr i8, ptr %s2, i64 %i
        \\  %v2 = load <16 x i8>, ptr %sp2, align 1
        \\  %dp2 = getelementptr i8, ptr %d2, i64 %i
        \\  store <16 x i8> %v2, ptr %dp2, align 1
        \\  %next = add i64 %i, 16
        \\  %end = icmp eq i64 %next, %n
        \\  br i1 %end, label %done, label %loop
        \\done:
        \\  ret void
        \\}
    ;
    try check(text, null);
}

test "composed generic cfg lowers inline memmove intrinsic" {
    const text =
        \\define void @move(ptr %d, ptr %s, i64 %n) {
        \\entry:
        \\  call void @llvm.memmove.p0.p0.i64(ptr %d, ptr %s, i64 %n, i1 false)
        \\  ret void
        \\}
    ;
    try check(text, null);
}

test "composed generic cfg lowers inline strlen call" {
    const text =
        \\define i64 @len(ptr %s) {
        \\entry:
        \\  %res = call i64 @strlen(ptr %s)
        \\  ret i64 %res
        \\}
    ;
    try check(text, null);
}

test "composed generic cfg lowers inline strnlen call" {
    const text =
        \\define i64 @nlen(ptr %s, i64 %maxlen) {
        \\entry:
        \\  %res = call i64 @strnlen(ptr %s, i64 %maxlen)
        \\  ret i64 %res
        \\}
    ;
    try check(text, null);
}

