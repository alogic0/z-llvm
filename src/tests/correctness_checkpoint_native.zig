const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../ir.zig");
const air = @import("../zig_air_export.zig");
const lowering = @import("../zig_air_lowering.zig");
const facts = @import("../zig_air_exported_aggregate_layout_facts.zig");
const codegen = @import("../codegen.zig");
const encoding = @import("../mc/encoding.zig");

const Native = struct {
    mapping: []align(std.heap.page_size_min) u8,

    fn init(module: ir.Module) !Native {
        if (builtin.cpu.arch != .x86_64 or builtin.os.tag != .linux) return error.SkipZigTest;
        var tag: ?[]const u8 = null;
        var detail: ?[]const u8 = null;
        var machine = codegen.x86_64.lowerFunctionWithOptions(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true, .generic_cfg_selector_diagnostic_tag = &tag, .generic_cfg_selector_diagnostic_detail = &detail }) catch |err| {
            var output = std.Io.Writer.Allocating.init(std.testing.allocator);
            defer output.deinit();
            try @import("../ir/printer.zig").print(module, &output.writer);
            std.debug.print("checkpoint selector={s}:{s} input:\n{s}\n", .{ tag orelse "-", detail orelse "-", output.written() });
            return err;
        };
        defer machine.deinit(std.testing.allocator);
        try codegen.x86_64.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mapping, bytes);
        return .{ .mapping = mapping };
    }

    fn deinit(self: Native) void {
        std.posix.munmap(self.mapping);
    }
};

fn lower(instructions: []air.TypedInstruction, signature: []const u8) !lowering.Result {
    var result = try lowerUnchecked(instructions, signature);
    errdefer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.accepted_functions);
    try std.testing.expectEqual(@as(usize, 0), result.unsupported.len);
    try result.module.verify();
    return result;
}

fn lowerUnchecked(instructions: []air.TypedInstruction, signature: []const u8) !lowering.Result {
    const allocator = std.testing.allocator;
    const indices = try allocator.alloc(u32, instructions.len);
    defer allocator.free(indices);
    for (indices, 0..) |*index, i| index.* = @intCast(i);
    var bodies = [_]air.StructuredBody{.{ .kind = .main, .owner = null, .instructions = indices }};
    var functions = [_]air.Function{.{
        .name = "checkpoint",
        .type_text = signature,
        .instruction_count = instructions.len,
        .main_body_count = instructions.len,
        .has_liveness = false,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = .{ .instructions = &.{}, .bodies = &bodies, .branches = &.{}, .cond_branches = &.{}, .repeats = &.{} },
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = instructions },
        .instructions = &.{},
    }};
    const aggregate_facts = [_]facts.Fact{.{ .nominal_type_name = "checkpoint.Range", .aggregate_text = "{ i64, i64 }" }};
    const module: air.Module = .{
        .allocator = allocator,
        .storage = "",
        .producer = "test",
        .root_source = "checkpoint.zig",
        .wrapper = "compiler-core-module",
        .mode = "ReleaseFast",
        .target = "x86_64-linux-gnu",
        .globals = &.{},
        .aggregate_layout_facts = .{ .facts = &aggregate_facts },
        .functions = &functions,
    };
    return lowering.lowerCompatible(allocator, module);
}

fn operand(comptime index: usize, comptime ty: []const u8) air.TypedOperand {
    return .{ .kind = "inst", .value = std.fmt.comptimePrint("{d}", .{index}), .type_text = ty };
}

test "correctness checkpoint executes aggregate snapshots across aliasing writes with a fixed seed" {
    const load_args = [_]air.TypedOperand{operand(0, "*checkpoint.Range")};
    const mutation = [_]air.TypedOperand{ operand(1, "*u64"), operand(2, "u64") };
    const copy = [_]air.TypedOperand{ operand(3, "*checkpoint.Range"), operand(4, "checkpoint.Range") };
    var instructions = [_]air.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "*checkpoint.Range", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "*u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "arg", .result_type = "u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 3, .opcode = "arg", .result_type = "*checkpoint.Range", .data_kind = "arg", .operands = &.{} },
        .{ .index = 4, .opcode = "load", .result_type = "checkpoint.Range", .data_kind = "ty_op", .operands = &load_args },
        .{ .index = 5, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = &mutation },
        .{ .index = 6, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = &copy },
        .{ .index = 7, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    var result = try lower(&instructions, "fn (*checkpoint.Range, *u64, u64, *checkpoint.Range) callconv(.c) void");
    defer result.deinit();
    const native = try Native.init(result.module);
    defer native.deinit();
    const Range = extern struct { begin: u64, end: u64 };
    const run: *const fn (*Range, *u64, u64, *Range) callconv(.c) void = @ptrCast(native.mapping.ptr);
    var seed: u64 = 0x5eed1234;
    for (0..64) |_| {
        seed = seed *% 6364136223846793005 +% 1;
        const original = Range{ .begin = seed, .end = ~seed };
        for (0..2) |field| {
            var input = original;
            var output: Range = undefined;
            const alias = if (field == 0) &input.begin else &input.end;
            run(&input, alias, seed ^ 0xa55a, &output);
            try std.testing.expectEqual(original.begin, output.begin);
            try std.testing.expectEqual(original.end, output.end);
            try std.testing.expectEqual(seed ^ 0xa55a, alias.*);
        }
    }
}

test "correctness checkpoint executes optional pointer null and non-null checks" {
    inline for (.{ "is_null_ptr", "is_non_null_ptr" }) |opcode| {
        const args = [_]air.TypedOperand{operand(0, "*?*const u8")};
        const ret = [_]air.TypedOperand{operand(1, "bool")};
        var instructions = [_]air.TypedInstruction{
            .{ .index = 0, .opcode = "arg", .result_type = "*?*const u8", .data_kind = "arg", .operands = &.{} },
            .{ .index = 1, .opcode = opcode, .result_type = "bool", .data_kind = "un_op", .operands = &args },
            .{ .index = 2, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &ret },
        };
        var result = try lower(&instructions, "fn (*?*const u8) callconv(.c) bool");
        defer result.deinit();
        const native = try Native.init(result.module);
        defer native.deinit();
        const run: *const fn (*?*const u8) callconv(.c) bool = @ptrCast(native.mapping.ptr);
        var byte: u8 = 17;
        var value: ?*const u8 = null;
        const is_null = std.mem.eql(u8, opcode, "is_null_ptr");
        try std.testing.expectEqual(is_null, run(&value));
        value = &byte;
        try std.testing.expectEqual(!is_null, run(&value));
    }
}

test "correctness checkpoint executes tagged optional snapshots across tag writes" {
    const args = [_]air.TypedOperand{operand(0, "*?u64")};
    const mutation = [_]air.TypedOperand{ operand(1, "*u8"), operand(2, "u8") };
    const check = [_]air.TypedOperand{operand(3, "?u64")};
    const ret = [_]air.TypedOperand{operand(5, "bool")};
    var instructions = [_]air.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "*?u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "*u8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "arg", .result_type = "u8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 3, .opcode = "load", .result_type = "?u64", .data_kind = "ty_op", .operands = &args },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = &mutation },
        .{ .index = 5, .opcode = "is_null", .result_type = "bool", .data_kind = "un_op", .operands = &check },
        .{ .index = 6, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &ret },
    };
    var result = try lower(&instructions, "fn (*?u64, *u8, u8) callconv(.c) bool");
    defer result.deinit();
    const native = try Native.init(result.module);
    defer native.deinit();
    const run: *const fn (*?u64, *u8, u8) callconv(.c) bool = @ptrCast(native.mapping.ptr);
    var value: ?u64 = 0;
    const tag: *u8 = @ptrFromInt(@intFromPtr(&value) + @sizeOf(u64));
    try std.testing.expect(!run(&value, tag, 0));
    try std.testing.expect(run(&value, tag, 1));

    const payload = [_]air.TypedOperand{operand(3, "?u64")};
    const mutation_payload = [_]air.TypedOperand{ operand(1, "*u64"), operand(2, "u64") };
    const payload_ret = [_]air.TypedOperand{operand(5, "u64")};
    var payload_instructions = [_]air.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "*?u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "*u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "arg", .result_type = "u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 3, .opcode = "load", .result_type = "?u64", .data_kind = "ty_op", .operands = &args },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = &mutation_payload },
        .{ .index = 5, .opcode = "optional_payload", .result_type = "u64", .data_kind = "ty_op", .operands = &payload },
        .{ .index = 6, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &payload_ret },
    };
    var payload_result = try lower(&payload_instructions, "fn (*?u64, *u64, u64) callconv(.c) u64");
    defer payload_result.deinit();
    const payload_native = try Native.init(payload_result.module);
    defer payload_native.deinit();
    const run_payload: *const fn (*?u64, *u64, u64) callconv(.c) u64 = @ptrCast(payload_native.mapping.ptr);
    for ([_]u64{ 0, 1, 0x123456789abcdef0, std.math.maxInt(u64) }) |original| {
        value = original;
        const alias: *u64 = @ptrCast(&value);
        try std.testing.expectEqual(original, run_payload(&value, alias, ~original));
        try std.testing.expectEqual(~original, value.?);
    }
}

test "correctness checkpoint executes tagged optional checks including a zero payload" {
    inline for (.{ "is_null_ptr", "is_non_null_ptr" }) |opcode| {
        const args = [_]air.TypedOperand{operand(0, "*?u64")};
        const ret = [_]air.TypedOperand{operand(1, "bool")};
        var instructions = [_]air.TypedInstruction{
            .{ .index = 0, .opcode = "arg", .result_type = "*?u64", .data_kind = "arg", .operands = &.{} },
            .{ .index = 1, .opcode = opcode, .result_type = "bool", .data_kind = "un_op", .operands = &args },
            .{ .index = 2, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &ret },
        };
        var result = try lower(&instructions, "fn (*?u64) callconv(.c) bool");
        defer result.deinit();
        const native = try Native.init(result.module);
        defer native.deinit();
        const run: *const fn (*?u64) callconv(.c) bool = @ptrCast(native.mapping.ptr);
        const is_null = std.mem.eql(u8, opcode, "is_null_ptr");
        var value: ?u64 = null;
        try std.testing.expectEqual(is_null, run(&value));
        value = 0;
        try std.testing.expectEqual(!is_null, run(&value));
        value = std.math.maxInt(u64);
        try std.testing.expectEqual(!is_null, run(&value));
    }
}

test "correctness checkpoint preserves a wrapped zero optional and volatile pointer reads" {
    const payload = [_]air.TypedOperand{operand(0, "u64")};
    const check = [_]air.TypedOperand{operand(1, "?u64")};
    const ret = [_]air.TypedOperand{operand(2, "bool")};
    var instructions = [_]air.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "wrap_optional", .result_type = "?u64", .data_kind = "ty_op", .operands = &payload },
        .{ .index = 2, .opcode = "is_non_null", .result_type = "bool", .data_kind = "un_op", .operands = &check },
        .{ .index = 3, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &ret },
    };
    var result = try lower(&instructions, "fn (u64) callconv(.c) bool");
    defer result.deinit();
    const native = try Native.init(result.module);
    defer native.deinit();
    const run: *const fn (u64) callconv(.c) bool = @ptrCast(native.mapping.ptr);
    try std.testing.expect(run(0));
    try std.testing.expect(run(std.math.maxInt(u64)));

    const args = [_]air.TypedOperand{operand(0, "*volatile ?*const u8")};
    const volatile_ret = [_]air.TypedOperand{operand(1, "bool")};
    var volatile_instructions = [_]air.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "*volatile ?*const u8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "is_null_ptr", .result_type = "bool", .data_kind = "un_op", .operands = &args },
        .{ .index = 2, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &volatile_ret },
    };
    var volatile_result = try lower(&volatile_instructions, "fn (*volatile ?*const u8) callconv(.c) bool");
    defer volatile_result.deinit();
    var volatile_reads: usize = 0;
    for (volatile_result.module.functions.items[0].blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.kind == .load and instruction.kind.load.attrs.is_volatile) volatile_reads += 1;
        }
    }
    try std.testing.expectEqual(@as(usize, 1), volatile_reads);
}

test "correctness checkpoint rejects optional ABI signatures without a tag contract" {
    const types = @import("../zig_air_types.zig");
    inline for (.{ "fn (?u64) bool", "fn () ?u64", "fn (?*allowzero u8) bool", "fn (?[]u8) bool" }) |signature| {
        try std.testing.expectError(error.UnsupportedAir, types.parseFunctionType(std.testing.allocator, signature));
    }
    var function_type = try types.parseFunctionType(std.testing.allocator, "fn (?*const u8) bool");
    defer function_type.deinit(std.testing.allocator);
    try std.testing.expectEqual(ir.Type.ptr, function_type.params[0].ir_type);

    const wrapped = [_]air.TypedOperand{operand(1, "u64")};
    const stored = [_]air.TypedOperand{ operand(0, "*?u64"), operand(2, "?u64") };
    var instructions = [_]air.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "*?u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "wrap_optional", .result_type = "?u64", .data_kind = "ty_op", .operands = &wrapped },
        .{ .index = 3, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = &stored },
        .{ .index = 4, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    var rejected = try lowerUnchecked(&instructions, "fn (*?u64, u64) callconv(.c) void");
    defer rejected.deinit();
    try std.testing.expectEqual(@as(usize, 0), rejected.accepted_functions);
    try std.testing.expectEqual(@as(usize, 1), rejected.unsupported.len);
}

test "correctness checkpoint executes aggregate returns at scaled and displacement boundaries" {
    const Pair = extern struct { lo: u64, hi: u64 };
    const cases = [_]struct { source: []const u8, index: usize, offset: usize }{
        .{ .source = "i64", .index = 1, .offset = 8 },
        .{ .source = "i32", .index = 2, .offset = 8 },
        .{ .source = "i24", .index = 2, .offset = 8 },
        .{ .source = "i64", .index = 16, .offset = 128 },
        .{ .source = "i8", .index = 1, .offset = 1 },
        .{ .source = "i8", .index = 127, .offset = 127 },
        .{ .source = "i8", .index = 128, .offset = 128 },
        .{ .source = "i8", .index = 255, .offset = 255 },
        .{ .source = "i8", .index = 256, .offset = 256 },
    };
    var bytes: [272]u8 = undefined;
    for (&bytes, 0..) |*byte, i| byte.* = @truncate(i *% 37 +% 11);
    for (cases) |case| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\target triple = "x86_64-linux-gnu"
            \\define {{ i64, i64 }} @checkpoint(ptr %p) {{
            \\entry:
            \\  %next = getelementptr {s}, ptr %p, i64 {d}
            \\  %v = load i64, ptr %next
            \\  %a = insertvalue {{ i64, i64 }} poison, i64 %v, 0
            \\  %b = insertvalue {{ i64, i64 }} %a, i64 42, 1
            \\  ret {{ i64, i64 }} %b
            \\}}
        , .{ case.source, case.index });
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        try module.verify();
        const native = try Native.init(module);
        defer native.deinit();
        const run: *const fn ([*]const u8) callconv(.c) Pair = @ptrCast(native.mapping.ptr);
        const actual = run(&bytes);
        try std.testing.expectEqual(std.mem.readInt(u64, bytes[case.offset..][0..8], .little), actual.lo);
        try std.testing.expectEqual(@as(u64, 42), actual.hi);
    }
}

test "correctness checkpoint executes scaled sret field loads" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\define void @checkpoint(ptr sret({ i64, i64, i64 }) %out, ptr %input) {
        \\entry:
        \\  %source = getelementptr i64, ptr %input, i64 16
        \\  %value = load i64, ptr %source
        \\  %first = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %value, ptr %first
        \\  %second = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 42, ptr %second
        \\  %third = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 99, ptr %third
        \\  ret void
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const native = try Native.init(module);
    defer native.deinit();
    const Output = extern struct { first: u64, second: u64, third: u64 };
    const run: *const fn (*Output, [*]const u64) callconv(.c) void = @ptrCast(native.mapping.ptr);
    var source: [17]u64 = @splat(0);
    source[16] = 0x123456789abcdef0;
    var output: Output = undefined;
    run(&output, &source);
    try std.testing.expectEqual(source[16], output.first);
    try std.testing.expectEqual(@as(u64, 42), output.second);
    try std.testing.expectEqual(@as(u64, 99), output.third);
}

test "current pin ABI executes unsigned i32 return bit patterns" {
    for ([_]u32{ 0, 0x7fffffff, 0x80000000, 0xffffffff }) |expected| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i32 @bits() {{\nentry:\n  ret i32 {}\n}}\n", .{expected});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        const code = try Native.init(module);
        defer code.deinit();
        const function: *const fn () callconv(.c) u32 = @ptrCast(code.mapping.ptr);
        try std.testing.expectEqual(expected, function());
    }
}

test "current pin ABI executes unsigned i64 immediate comparisons at boundaries" {
    const bounds = [_]u64{ 0, 1, 0x7fffffff, 0x80000000, 0x7fffffffffffffff, 0x8000000000000000, 0xffffffffffffffff };
    for (bounds) |bound| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i1 @compare(i64 %value) {{\nentry:\n  %ok = icmp ule i64 %value, {}\n  ret i1 %ok\n}}\n", .{bound});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        const code = try Native.init(module);
        defer code.deinit();
        const compare: *const fn (u64) callconv(.c) u32 = @ptrCast(code.mapping.ptr);
        for (bounds ++ [_]u64{ bound -% 1, bound +% 1 }) |value| {
            try std.testing.expectEqual(@as(u32, @intFromBool(value <= bound)), compare(value));
        }
    }
}

test "current pin ABI unreachable blocks preserve earlier stores and stop execution" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @checked(i32 %bad, ptr %output) {
        \\entry:
        \\  %ok = icmp eq i32 %bad, 0
        \\  br i1 %ok, label %good, label %invalid
        \\good:
        \\  ret i32 7
        \\invalid:
        \\  store i32 73, ptr %output, align 4
        \\  unreachable
        \\}
    );
    defer module.deinit();
    const code = try Native.init(module);
    defer code.deinit();
    const memory = try std.posix.mmap(null, 4096, .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    const output: *u32 = @ptrCast(@alignCast(memory.ptr));
    output.* = 0;
    const checked: *const fn (u32, *u32) callconv(.c) u32 = @ptrCast(code.mapping.ptr);
    try std.testing.expectEqual(@as(u32, 7), checked(0, output));
    try std.testing.expectEqual(@as(u32, 0), output.*);
    const pid = std.os.linux.fork();
    if (pid == 0) {
        const action: std.posix.Sigaction = .{ .handler = .{ .handler = std.posix.SIG.DFL }, .mask = std.posix.sigemptyset(), .flags = 0 };
        std.posix.sigaction(.ILL, &action, null);
        _ = checked(1, output);
        std.os.linux.exit_group(127);
    }
    try std.testing.expect(pid > 0 and pid < 0x80000000);
    var status: i32 = 0;
    _ = std.os.linux.waitpid(@intCast(pid), &status, 0);
    try std.testing.expectEqual(@as(i32, 4), status & 0x7f);
    try std.testing.expectEqual(@as(u32, 73), output.*);
}

test "current pin ABI executes integer pair returns and borrow propagation" {
    var module = try ir.Module.parse(std.testing.allocator, @embedFile("../testdata/current_pin_pair_returns.ll"));
    defer module.deinit();
    try module.verify();
    const Pair = extern struct { low: u64, high: u64 };
    const shift_code = try Native.init(module);
    defer shift_code.deinit();
    var neg_module = module;
    neg_module.functions.items = module.functions.items[1..2];
    const neg_code = try Native.init(neg_module);
    defer neg_code.deinit();
    const shift: *const fn (u64, u64, u32) callconv(.c) Pair = @ptrCast(shift_code.mapping.ptr);
    const negate: *const fn (u64, u64) callconv(.c) Pair = @ptrCast(neg_code.mapping.ptr);
    var seed: u64 = 0x5eed1234;
    for (0..64) |iteration| {
        seed = seed *% 6364136223846793005 +% 1;
        const low = if (iteration == 0) @as(u64, 0) else seed;
        const high = if (iteration == 0) @as(u64, 0) else ~seed;
        const value = (@as(u128, high) << 64) | low;
        const negative = negate(low, high);
        const expected_negative = 0 -% value;
        try std.testing.expectEqual(@as(u64, @truncate(expected_negative)), negative.low);
        try std.testing.expectEqual(@as(u64, @truncate(expected_negative >> 64)), negative.high);
        for ([_]u7{ 0, 1, 31, 63, 64, 65, 127 }) |amount| {
            const actual = shift(low, high, amount);
            const expected = value << amount;
            try std.testing.expectEqual(@as(u64, @truncate(expected)), actual.low);
            try std.testing.expectEqual(@as(u64, @truncate(expected >> 64)), actual.high);
        }
    }
}

test "current pin ABI half carriers preserve every payload bit" {
    var module = try ir.Module.parse(std.testing.allocator, @embedFile("../testdata/current_pin_half_carriers.ll"));
    defer module.deinit();
    try module.verify();
    const negate_code = try Native.init(module);
    defer negate_code.deinit();
    var abs_module = module;
    abs_module.functions.items = module.functions.items[1..2];
    const abs_code = try Native.init(abs_module);
    defer abs_code.deinit();
    const negate: *const fn (f64) callconv(.c) f64 = @ptrCast(negate_code.mapping.ptr);
    const absolute: *const fn (f64) callconv(.c) f64 = @ptrCast(abs_code.mapping.ptr);
    for (0..65536) |payload| {
        const input: f64 = @bitCast(@as(u64, payload) | 0x1234000000000000);
        const neg_bits: u64 = @bitCast(negate(input));
        const abs_bits: u64 = @bitCast(absolute(input));
        try std.testing.expectEqual(@as(u16, @intCast(payload)) ^ 0x8000, @as(u16, @truncate(neg_bits)));
        try std.testing.expectEqual(@as(u16, @intCast(payload)) & 0x7fff, @as(u16, @truncate(abs_bits)));
    }
}

test "current pin ABI carrier legalization rejects barriers and escaping pointers" {
    const legalize = @import("../codegen/x86_64/generic_cfg/abi_legalization.zig");
    inline for (.{ "volatile ", "" }) |qualifier| {
        const text = "define double @carrier(ptr %out) {\nentry:\n  %slot = alloca half, align 8\n" ++
            (if (qualifier.len == 0) "  store ptr %slot, ptr %out\n" else "") ++
            "  store i16 0, ptr %slot\n  %value = load " ++ qualifier ++ "double, ptr %slot\n  ret double %value\n}\n";
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expectEqual(@as(?ir.Function, null), try legalize.paddedHalf(arena.allocator(), module.functions.items[0]));
    }
}
