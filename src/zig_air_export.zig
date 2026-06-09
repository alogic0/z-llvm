const std = @import("std");

pub const contract_name = "zllvm-air-export-v1";
pub const contract_version: u16 = 1;
pub const payload_name = "zig-air-print-v1";

pub const InstructionCategory = enum {
    argument,
    arithmetic,
    comparison,
    cast,
    control_flow,
    memory,
    aggregate,
    call,
    return_op,
    debug,
    other,
};

pub const Instruction = struct {
    index: u32,
    indent: u16,
    unused: bool,
    opcode: []const u8,
    payload: []const u8,
    category: InstructionCategory,
};

pub const Function = struct {
    name: []const u8,
    type_text: []const u8,
    instruction_count: usize,
    main_body_count: usize,
    has_liveness: bool,
    air_text: []const u8,
    instructions: []Instruction,
};

pub const Global = struct {
    name: []const u8,
    type_text: []const u8,
    thread_local: []const u8,
    is_constant: bool,
};

pub const Module = struct {
    allocator: std.mem.Allocator,
    storage: []u8,
    producer: []const u8,
    root_source: []const u8,
    wrapper: []const u8,
    mode: []const u8,
    target: []const u8,
    globals: []Global,
    functions: []Function,

    pub fn deinit(self: *Module) void {
        for (self.functions) |function| self.allocator.free(function.instructions);
        self.allocator.free(self.functions);
        self.allocator.free(self.globals);
        self.allocator.free(self.storage);
        self.* = undefined;
    }

    pub fn instructionCount(self: Module) usize {
        var count: usize = 0;
        for (self.functions) |function| count += function.instructions.len;
        return count;
    }
};

pub fn parse(allocator: std.mem.Allocator, contents: []const u8) !Module {
    const storage = try allocator.dupe(u8, contents);
    errdefer allocator.free(storage);

    var cursor: Cursor = .{ .contents = storage };
    try cursor.expectLine(contract_name);
    const version = try parseUnsigned(u16, try cursor.readValueLine("contract_version"));
    if (version != contract_version) return error.UnsupportedContractVersion;
    if (!std.mem.eql(u8, try cursor.readValueLine("payload"), payload_name)) {
        return error.UnsupportedPayload;
    }

    const producer = try cursor.readValueLine("producer");
    const root_source = try cursor.readValueLine("root_source");
    const wrapper = try cursor.readValueLine("wrapper");
    const mode = try cursor.readValueLine("mode");
    const target = try cursor.readValueLine("target");
    const function_count = try parseUnsigned(usize, try cursor.readValueLine("function_count"));
    const global_count = try parseUnsigned(usize, try cursor.readValueLine("global_count"));

    var globals: std.ArrayList(Global) = .empty;
    errdefer globals.deinit(allocator);
    try globals.ensureTotalCapacity(allocator, global_count);
    for (0..global_count) |_| {
        try cursor.expectLine("global_begin");
        const name = try cursor.readFramed("name_bytes");
        const type_text = try cursor.readFramed("type_bytes");
        const thread_local = try cursor.readValueLine("thread_local");
        const is_constant = try parseBool(try cursor.readValueLine("constant"));
        try cursor.expectLine("global_end");
        globals.appendAssumeCapacity(.{
            .name = name,
            .type_text = type_text,
            .thread_local = thread_local,
            .is_constant = is_constant,
        });
    }

    var functions: std.ArrayList(Function) = .empty;
    errdefer {
        for (functions.items) |function| allocator.free(function.instructions);
        functions.deinit(allocator);
    }
    try functions.ensureTotalCapacity(allocator, function_count);
    for (0..function_count) |_| {
        try cursor.expectLine("function_begin");
        const name = try cursor.readFramed("name_bytes");
        const type_text = try cursor.readFramed("type_bytes");
        const instruction_count = try parseUnsigned(usize, try cursor.readValueLine("instruction_count"));
        const main_body_count = try parseUnsigned(usize, try cursor.readValueLine("main_body_count"));
        const liveness = try cursor.readValueLine("liveness");
        const has_liveness = if (std.mem.eql(u8, liveness, "present"))
            true
        else if (std.mem.eql(u8, liveness, "absent"))
            false
        else
            return error.InvalidLiveness;
        const air_text = try cursor.readFramed("air_bytes");
        try cursor.expectLine("function_end");
        const instructions = try parseInstructions(allocator, air_text, instruction_count);
        functions.appendAssumeCapacity(.{
            .name = name,
            .type_text = type_text,
            .instruction_count = instruction_count,
            .main_body_count = main_body_count,
            .has_liveness = has_liveness,
            .air_text = air_text,
            .instructions = instructions,
        });
    }

    if (!cursor.onlyWhitespaceRemaining()) return error.TrailingData;

    var module: Module = .{
        .allocator = allocator,
        .storage = storage,
        .producer = producer,
        .root_source = root_source,
        .wrapper = wrapper,
        .mode = mode,
        .target = target,
        .globals = try globals.toOwnedSlice(allocator),
        .functions = try functions.toOwnedSlice(allocator),
    };
    errdefer module.deinit();
    try verify(module);
    return module;
}

pub fn verify(module: Module) !void {
    if (module.producer.len == 0) return error.MissingProducer;
    if (module.root_source.len == 0) return error.MissingRootSource;
    if (module.wrapper.len == 0) return error.MissingWrapper;
    if (!isReleaseMode(module.mode)) return error.UnsupportedOptimizeMode;
    if (!std.mem.startsWith(u8, module.target, "x86_64-")) return error.UnsupportedTarget;

    for (module.globals) |global| {
        if (global.name.len == 0) return error.MissingGlobalName;
        if (global.type_text.len == 0) return error.MissingGlobalType;
        if (global.thread_local.len == 0) return error.MissingThreadLocalModel;
    }
    for (module.functions) |function| {
        if (function.name.len == 0) return error.MissingFunctionName;
        if (function.type_text.len == 0) return error.MissingFunctionType;
        if (!function.has_liveness) return error.MissingLiveness;
        if (function.instructions.len != function.instruction_count) return error.InstructionCountMismatch;
        if (function.main_body_count > function.instruction_count) return error.InvalidMainBodyCount;
        const seen = try module.allocator.alloc(bool, function.instruction_count);
        defer module.allocator.free(seen);
        @memset(seen, false);
        for (function.instructions) |instruction| {
            if (instruction.index >= seen.len or seen[instruction.index]) {
                return error.InvalidInstructionIndex;
            }
            seen[instruction.index] = true;
            if (instruction.opcode.len == 0) return error.MissingOpcode;
        }
        for (seen) |present| if (!present) return error.NonDenseInstructionIndex;
    }
}

pub fn categoryForOpcode(opcode: []const u8) InstructionCategory {
    if (std.mem.eql(u8, opcode, "arg")) return .argument;
    if (std.mem.startsWith(u8, opcode, "cmp_") or
        std.mem.eql(u8, opcode, "is_null") or
        std.mem.eql(u8, opcode, "is_non_null") or
        std.mem.eql(u8, opcode, "is_err") or
        std.mem.eql(u8, opcode, "is_non_err"))
    {
        return .comparison;
    }
    if (std.mem.eql(u8, opcode, "block") or
        std.mem.eql(u8, opcode, "loop") or
        std.mem.eql(u8, opcode, "br") or
        std.mem.eql(u8, opcode, "cond_br") or
        std.mem.eql(u8, opcode, "switch_br") or
        std.mem.eql(u8, opcode, "repeat"))
    {
        return .control_flow;
    }
    if (std.mem.eql(u8, opcode, "ret") or
        std.mem.eql(u8, opcode, "ret_safe") or
        std.mem.eql(u8, opcode, "unreach"))
    {
        return .return_op;
    }
    if (std.mem.eql(u8, opcode, "call") or
        std.mem.eql(u8, opcode, "call_always_tail") or
        std.mem.eql(u8, opcode, "call_never_tail") or
        std.mem.eql(u8, opcode, "call_never_inline"))
    {
        return .call;
    }
    if (std.mem.eql(u8, opcode, "alloc") or
        std.mem.eql(u8, opcode, "load") or
        std.mem.eql(u8, opcode, "store") or
        std.mem.eql(u8, opcode, "store_safe") or
        std.mem.eql(u8, opcode, "memcpy") or
        std.mem.eql(u8, opcode, "memmove") or
        std.mem.eql(u8, opcode, "memset") or
        std.mem.eql(u8, opcode, "memset_safe"))
    {
        return .memory;
    }
    if (std.mem.eql(u8, opcode, "intcast") or
        std.mem.eql(u8, opcode, "bitcast") or
        std.mem.eql(u8, opcode, "trunc") or
        std.mem.eql(u8, opcode, "float_from_int") or
        std.mem.eql(u8, opcode, "int_from_float") or
        std.mem.eql(u8, opcode, "ptrtoint") or
        std.mem.eql(u8, opcode, "inttoptr"))
    {
        return .cast;
    }
    if (std.mem.indexOf(u8, opcode, "field") != null or
        std.mem.indexOf(u8, opcode, "elem") != null or
        std.mem.startsWith(u8, opcode, "aggregate_"))
    {
        return .aggregate;
    }
    if (std.mem.startsWith(u8, opcode, "dbg_")) return .debug;
    if (isArithmeticOpcode(opcode)) return .arithmetic;
    return .other;
}

fn parseInstructions(
    allocator: std.mem.Allocator,
    air_text: []const u8,
    expected_count: usize,
) ![]Instruction {
    var instructions: std.ArrayList(Instruction) = .empty;
    errdefer instructions.deinit(allocator);
    try instructions.ensureTotalCapacity(allocator, expected_count);
    const seen = try allocator.alloc(bool, expected_count);
    defer allocator.free(seen);
    @memset(seen, false);

    var lines = std.mem.splitScalar(u8, air_text, '\n');
    while (lines.next()) |line| {
        const parsed = parseInstructionLine(line) orelse continue;
        if (parsed.index >= expected_count or seen[parsed.index]) return error.InvalidInstructionIndex;
        seen[parsed.index] = true;
        instructions.appendAssumeCapacity(parsed);
    }
    if (instructions.items.len != expected_count) return error.InstructionCountMismatch;
    for (seen) |present| if (!present) return error.NonDenseInstructionIndex;
    return instructions.toOwnedSlice(allocator);
}

fn parseInstructionLine(line: []const u8) ?Instruction {
    const trimmed = std.mem.trimStart(u8, line, " ");
    if (trimmed.len == 0 or trimmed[0] != '%') return null;
    const equal_index = std.mem.indexOfScalar(u8, trimmed, '=') orelse return null;
    var result_text = std.mem.trim(u8, trimmed[1..equal_index], " ");
    const unused = std.mem.endsWith(u8, result_text, "!");
    if (unused) result_text = result_text[0 .. result_text.len - 1];
    const index = std.fmt.parseInt(u32, result_text, 10) catch return null;

    const expression = std.mem.trimStart(u8, trimmed[equal_index + 1 ..], " ");
    const open_paren = std.mem.indexOfScalar(u8, expression, '(') orelse return null;
    const opcode = expression[0..open_paren];
    if (opcode.len == 0) return null;
    const payload = if (std.mem.endsWith(u8, expression, ")"))
        expression[open_paren + 1 .. expression.len - 1]
    else
        expression[open_paren + 1 ..];

    return .{
        .index = index,
        .indent = @intCast(line.len - trimmed.len),
        .unused = unused,
        .opcode = opcode,
        .payload = payload,
        .category = categoryForOpcode(opcode),
    };
}

fn isReleaseMode(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or
        std.mem.eql(u8, mode, "ReleaseSafe") or
        std.mem.eql(u8, mode, "ReleaseSmall");
}

fn isArithmeticOpcode(opcode: []const u8) bool {
    const arithmetic = [_][]const u8{
        "add",
        "add_optimized",
        "add_safe",
        "add_wrap",
        "add_sat",
        "sub",
        "sub_optimized",
        "sub_safe",
        "sub_wrap",
        "sub_sat",
        "mul",
        "mul_optimized",
        "mul_safe",
        "mul_wrap",
        "mul_sat",
        "div_float",
        "div_float_optimized",
        "div_trunc",
        "div_floor",
        "div_exact",
        "rem",
        "mod",
        "bit_and",
        "bit_or",
        "xor",
        "shl",
        "shr",
    };
    for (arithmetic) |candidate| {
        if (std.mem.eql(u8, opcode, candidate)) return true;
    }
    return false;
}

fn parseBool(text: []const u8) !bool {
    if (std.mem.eql(u8, text, "true")) return true;
    if (std.mem.eql(u8, text, "false")) return false;
    return error.InvalidBoolean;
}

fn parseUnsigned(comptime T: type, text: []const u8) !T {
    return std.fmt.parseInt(T, text, 10) catch error.InvalidUnsignedInteger;
}

const Cursor = struct {
    contents: []const u8,
    offset: usize = 0,

    fn expectLine(self: *Cursor, expected: []const u8) !void {
        const actual = try self.readLine();
        if (!std.mem.eql(u8, actual, expected)) return error.UnexpectedRecord;
    }

    fn readValueLine(self: *Cursor, key: []const u8) ![]const u8 {
        const line = try self.readLine();
        if (line.len <= key.len or !std.mem.eql(u8, line[0..key.len], key) or line[key.len] != '=') {
            return error.UnexpectedRecord;
        }
        return line[key.len + 1 ..];
    }

    fn readFramed(self: *Cursor, length_key: []const u8) ![]const u8 {
        const len = try parseUnsigned(usize, try self.readValueLine(length_key));
        if (len > self.contents.len - self.offset) return error.TruncatedRecord;
        const value = self.contents[self.offset .. self.offset + len];
        self.offset += len;
        if (self.offset >= self.contents.len or self.contents[self.offset] != '\n') {
            return error.InvalidRecordDelimiter;
        }
        self.offset += 1;
        return value;
    }

    fn readLine(self: *Cursor) ![]const u8 {
        if (self.offset >= self.contents.len) return error.UnexpectedEndOfFile;
        const relative_end = std.mem.indexOfScalar(u8, self.contents[self.offset..], '\n') orelse
            return error.UnterminatedLine;
        const start = self.offset;
        const end = start + relative_end;
        self.offset = end + 1;
        return self.contents[start..end];
    }

    fn onlyWhitespaceRemaining(self: Cursor) bool {
        return std.mem.trim(u8, self.contents[self.offset..], " \t\r\n").len == 0;
    }
};

test "parse compiler-owned AIR export with control flow and calls" {
    const air_text =
        \\# AIR Instructions: 5
        \\  %0 = arg(u32, 0)
        \\  %1 = block(void, {
        \\    %4 = cmp_lt(%0, <u32, 4>)
        \\    %2!= cond_br(%4!, poi {
        \\    })
        \\  })
        \\  %3!= ret(<i32, 0>)
        \\
    ;
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=patched-zig-llvm-update-func
        \\root_source=uncurated.zig
        \\wrapper=uncurated.zig
        \\mode=ReleaseFast
        \\target=x86_64-unknown-linux-gnu
        \\function_count=1
        \\global_count=1
        \\global_begin
        \\name_bytes=1
        \\g
        \\type_bytes=3
        \\i32
        \\thread_local=default
        \\constant=false
        \\global_end
        \\function_begin
        \\name_bytes=4
        \\main
        \\type_bytes=9
        \\fn () i32
        \\instruction_count=5
        \\main_body_count=3
        \\liveness=present
        \\air_bytes={}
        \\{s}
        \\function_end
        \\
    , .{ air_text.len, air_text });
    defer std.testing.allocator.free(input);

    var module = try parse(std.testing.allocator, input);
    defer module.deinit();

    try std.testing.expectEqual(@as(usize, 1), module.globals.len);
    try std.testing.expectEqual(@as(usize, 1), module.functions.len);
    try std.testing.expectEqual(@as(usize, 5), module.instructionCount());
    try std.testing.expectEqualStrings("block", module.functions[0].instructions[1].opcode);
    try std.testing.expectEqual(InstructionCategory.control_flow, module.functions[0].instructions[3].category);
}

test "reject AIR export instruction count mismatch" {
    const air_text =
        \\  %0!= ret(<i32, 0>)
        \\
    ;
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=patched-zig-llvm-update-func
        \\root_source=bad.zig
        \\wrapper=bad.zig
        \\mode=ReleaseFast
        \\target=x86_64-linux-gnu
        \\function_count=1
        \\global_count=0
        \\function_begin
        \\name_bytes=4
        \\main
        \\type_bytes=9
        \\fn () i32
        \\instruction_count=2
        \\main_body_count=1
        \\liveness=present
        \\air_bytes={}
        \\{s}
        \\function_end
        \\
    , .{ air_text.len, air_text });
    defer std.testing.allocator.free(input);

    try std.testing.expectError(error.InstructionCountMismatch, parse(std.testing.allocator, input));
}
