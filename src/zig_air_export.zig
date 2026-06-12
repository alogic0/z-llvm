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
    structured_air_text: ?[]const u8,
    structured_air: ?StructuredAir,
    structured_air_v2_text: ?[]const u8,
    structured_air_v2: ?StructuredAirV2,
    instructions: []Instruction,
};

pub const StructuredAir = struct {
    instructions: []StructuredInstruction,
    bodies: []StructuredBody,
    branches: []StructuredBranch,
    cond_branches: []StructuredCondBranch,
    repeats: []StructuredRepeat,

    fn deinit(self: StructuredAir, allocator: std.mem.Allocator) void {
        for (self.bodies) |structured_body| allocator.free(structured_body.instructions);
        allocator.free(self.instructions);
        allocator.free(self.bodies);
        allocator.free(self.branches);
        allocator.free(self.cond_branches);
        allocator.free(self.repeats);
    }

    pub fn body(self: StructuredAir, kind: StructuredBodyKind, owner: ?u32) ?StructuredBody {
        for (self.bodies) |candidate| {
            if (candidate.kind == kind and candidate.owner == owner) return candidate;
        }
        return null;
    }
};

pub const StructuredInstruction = struct {
    index: u32,
    opcode: []const u8,
    type_text: []const u8,
};

pub const StructuredBodyKind = enum { main, block, loop, then_body, else_body };

pub const StructuredBody = struct {
    kind: StructuredBodyKind,
    owner: ?u32,
    instructions: []u32,
};

pub const StructuredBranch = struct {
    index: u32,
    target: u32,
    operand_ref: u32,
};

pub const StructuredCondBranch = struct {
    index: u32,
    condition_ref: u32,
};

pub const StructuredRepeat = struct {
    index: u32,
    loop_index: u32,
};

pub const StructuredAirV2 = struct {
    instructions: []TypedInstruction,

    fn deinit(self: StructuredAirV2, allocator: std.mem.Allocator) void {
        for (self.instructions) |instruction| {
            allocator.free(instruction.operands);
            allocator.free(instruction.details);
        }
        allocator.free(self.instructions);
    }
};

pub const TypedInstruction = struct {
    index: u32,
    opcode: []const u8,
    result_type: []const u8,
    data_kind: []const u8,
    operands: []TypedOperand,
    details: []TypedDetail = &.{},
};

pub const TypedOperand = struct {
    kind: []const u8,
    value: []const u8,
    type_text: []const u8,
};

pub const TypedDetail = struct {
    key: []const u8,
    value: []const u8,
};

pub const Global = struct {
    name: []const u8,
    type_text: []const u8,
    thread_local: []const u8,
    is_constant: bool,
    initializer_text: ?[]const u8 = null,
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
        for (self.functions) |function| {
            if (function.structured_air) |structured_air| structured_air.deinit(self.allocator);
            if (function.structured_air_v2) |structured_air_v2| structured_air_v2.deinit(self.allocator);
            self.allocator.free(function.instructions);
        }
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
    var storage_owned_by_parse = true;
    errdefer if (storage_owned_by_parse) allocator.free(storage);

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
        const initializer_text = if (cursor.peekValueLine("initializer_bytes"))
            try cursor.readFramed("initializer_bytes")
        else
            null;
        try cursor.expectLine("global_end");
        globals.appendAssumeCapacity(.{
            .name = name,
            .type_text = type_text,
            .thread_local = thread_local,
            .is_constant = is_constant,
            .initializer_text = initializer_text,
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
        const structured_air_text: ?[]const u8 = if (cursor.peekValueLine("structured_air_bytes"))
            try cursor.readFramed("structured_air_bytes")
        else
            null;
        const structured_air_v2_text: ?[]const u8 = if (cursor.peekValueLine("structured_air_v2_bytes"))
            try cursor.readFramed("structured_air_v2_bytes")
        else
            null;
        try cursor.expectLine("function_end");
        const instructions = try parseInstructions(allocator, air_text, instruction_count);
        const structured_air = if (structured_air_text) |text| try parseStructuredAir(allocator, text) else null;
        const structured_air_v2 = if (structured_air_v2_text) |text| try parseStructuredAirV2(allocator, text) else null;
        functions.appendAssumeCapacity(.{
            .name = name,
            .type_text = type_text,
            .instruction_count = instruction_count,
            .main_body_count = main_body_count,
            .has_liveness = has_liveness,
            .air_text = air_text,
            .structured_air_text = structured_air_text,
            .structured_air = structured_air,
            .structured_air_v2_text = structured_air_v2_text,
            .structured_air_v2 = structured_air_v2,
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
    storage_owned_by_parse = false;
    errdefer module.deinit();
    try verify(module);
    return module;
}

fn parseStructuredAir(allocator: std.mem.Allocator, text: []const u8) !StructuredAir {
    var lines = std.mem.splitScalar(u8, text, '\n');
    const header = lines.next() orelse return error.InvalidStructuredAir;
    if (!std.mem.eql(u8, header, "structured_air-v1")) return error.InvalidStructuredAir;

    var instructions: std.ArrayList(StructuredInstruction) = .empty;
    errdefer instructions.deinit(allocator);
    var bodies: std.ArrayList(StructuredBody) = .empty;
    errdefer {
        for (bodies.items) |body| allocator.free(body.instructions);
        bodies.deinit(allocator);
    }
    var branches: std.ArrayList(StructuredBranch) = .empty;
    errdefer branches.deinit(allocator);
    var cond_branches: std.ArrayList(StructuredCondBranch) = .empty;
    errdefer cond_branches.deinit(allocator);
    var repeats: std.ArrayList(StructuredRepeat) = .empty;
    errdefer repeats.deinit(allocator);

    var saw_end = false;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line, "structured_air_end")) {
            saw_end = true;
            break;
        }
        var fields = std.mem.splitScalar(u8, line, '|');
        const kind = fields.next() orelse return error.InvalidStructuredAir;
        if (std.mem.eql(u8, kind, "inst")) {
            const index = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir);
            const opcode = fields.next() orelse return error.InvalidStructuredAir;
            const type_len = try parseUnsigned(usize, fields.next() orelse return error.InvalidStructuredAir);
            const type_text = fields.next() orelse return error.InvalidStructuredAir;
            if (type_text.len != type_len or fields.next() != null) return error.InvalidStructuredAir;
            try instructions.append(allocator, .{
                .index = index,
                .opcode = opcode,
                .type_text = type_text,
            });
        } else if (std.mem.eql(u8, kind, "body")) {
            const body_kind = parseStructuredBodyKind(fields.next() orelse return error.InvalidStructuredAir) orelse
                return error.InvalidStructuredAir;
            const owner_text = fields.next() orelse return error.InvalidStructuredAir;
            const owner = if (std.mem.eql(u8, owner_text, "-"))
                null
            else
                try parseUnsigned(u32, owner_text);
            const count = try parseUnsigned(usize, fields.next() orelse return error.InvalidStructuredAir);
            const body_instructions = try allocator.alloc(u32, count);
            errdefer allocator.free(body_instructions);
            for (body_instructions) |*instruction| {
                instruction.* = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir);
            }
            if (fields.next() != null) return error.InvalidStructuredAir;
            try bodies.append(allocator, .{
                .kind = body_kind,
                .owner = owner,
                .instructions = body_instructions,
            });
        } else if (std.mem.eql(u8, kind, "br")) {
            try branches.append(allocator, .{
                .index = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir),
                .target = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir),
                .operand_ref = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir),
            });
            if (fields.next() != null) return error.InvalidStructuredAir;
        } else if (std.mem.eql(u8, kind, "cond_br")) {
            try cond_branches.append(allocator, .{
                .index = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir),
                .condition_ref = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir),
            });
            if (fields.next() != null) return error.InvalidStructuredAir;
        } else if (std.mem.eql(u8, kind, "repeat")) {
            try repeats.append(allocator, .{
                .index = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir),
                .loop_index = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAir),
            });
            if (fields.next() != null) return error.InvalidStructuredAir;
        } else {
            return error.InvalidStructuredAir;
        }
    }
    if (!saw_end) return error.InvalidStructuredAir;

    return .{
        .instructions = try instructions.toOwnedSlice(allocator),
        .bodies = try bodies.toOwnedSlice(allocator),
        .branches = try branches.toOwnedSlice(allocator),
        .cond_branches = try cond_branches.toOwnedSlice(allocator),
        .repeats = try repeats.toOwnedSlice(allocator),
    };
}

fn parseStructuredAirV2(allocator: std.mem.Allocator, text: []const u8) !StructuredAirV2 {
    var lines = std.mem.splitScalar(u8, text, '\n');
    const header = lines.next() orelse return error.InvalidStructuredAirV2;
    if (!std.mem.eql(u8, header, "structured_air-v2")) return error.InvalidStructuredAirV2;

    var instructions: std.ArrayList(TypedInstruction) = .empty;
    errdefer {
        for (instructions.items) |instruction| {
            allocator.free(instruction.operands);
            allocator.free(instruction.details);
        }
        instructions.deinit(allocator);
    }

    var saw_end = false;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line, "structured_air_v2_end")) {
            saw_end = true;
            break;
        }
        var fields = std.mem.splitScalar(u8, line, '|');
        const kind = fields.next() orelse return error.InvalidStructuredAirV2;
        if (!std.mem.eql(u8, kind, "typed_inst")) return error.InvalidStructuredAirV2;
        const index = try parseUnsigned(u32, fields.next() orelse return error.InvalidStructuredAirV2);
        const opcode = fields.next() orelse return error.InvalidStructuredAirV2;
        const result_type_len = try parseUnsigned(usize, fields.next() orelse return error.InvalidStructuredAirV2);
        const result_type = fields.next() orelse return error.InvalidStructuredAirV2;
        if (result_type.len != result_type_len) return error.InvalidStructuredAirV2;
        const data_kind = fields.next() orelse return error.InvalidStructuredAirV2;
        const operand_count = try parseUnsigned(usize, fields.next() orelse return error.InvalidStructuredAirV2);
        const operands = try allocator.alloc(TypedOperand, operand_count);
        errdefer allocator.free(operands);
        for (operands) |*operand| {
            const operand_kind = fields.next() orelse return error.InvalidStructuredAirV2;
            const value_len = try parseUnsigned(usize, fields.next() orelse return error.InvalidStructuredAirV2);
            const value = fields.next() orelse return error.InvalidStructuredAirV2;
            if (value.len != value_len) return error.InvalidStructuredAirV2;
            const type_len = try parseUnsigned(usize, fields.next() orelse return error.InvalidStructuredAirV2);
            const type_text = fields.next() orelse return error.InvalidStructuredAirV2;
            if (type_text.len != type_len) return error.InvalidStructuredAirV2;
            operand.* = .{
                .kind = operand_kind,
                .value = value,
                .type_text = type_text,
            };
        }
        var details: []TypedDetail = &.{};
        if (fields.next()) |detail_count_text| {
            const detail_count = try parseUnsigned(usize, detail_count_text);
            details = try allocator.alloc(TypedDetail, detail_count);
            errdefer allocator.free(details);
            for (details) |*detail| {
                const key = fields.next() orelse return error.InvalidStructuredAirV2;
                const detail_value_len = try parseUnsigned(usize, fields.next() orelse return error.InvalidStructuredAirV2);
                const detail_value = fields.next() orelse return error.InvalidStructuredAirV2;
                if (detail_value.len != detail_value_len) return error.InvalidStructuredAirV2;
                detail.* = .{
                    .key = key,
                    .value = detail_value,
                };
            }
        }
        if (fields.next() != null) return error.InvalidStructuredAirV2;
        try instructions.append(allocator, .{
            .index = index,
            .opcode = opcode,
            .result_type = result_type,
            .data_kind = data_kind,
            .operands = operands,
            .details = details,
        });
    }
    if (!saw_end) return error.InvalidStructuredAirV2;
    return .{ .instructions = try instructions.toOwnedSlice(allocator) };
}

fn parseStructuredBodyKind(text: []const u8) ?StructuredBodyKind {
    if (std.mem.eql(u8, text, "main")) return .main;
    if (std.mem.eql(u8, text, "block")) return .block;
    if (std.mem.eql(u8, text, "loop")) return .loop;
    if (std.mem.eql(u8, text, "then")) return .then_body;
    if (std.mem.eql(u8, text, "else")) return .else_body;
    return null;
}

pub fn verify(module: Module) !void {
    if (module.producer.len == 0) return error.MissingProducer;
    if (module.root_source.len == 0) return error.MissingRootSource;
    if (module.wrapper.len == 0) return error.MissingWrapper;
    if (!isReleaseMode(module.mode)) return error.UnsupportedOptimizeMode;
    if (!std.mem.startsWith(u8, module.target, "x86_64-")) return error.UnsupportedTarget;

    for (module.globals) |global| {
        if (global.name.len == 0) {
            if (global.is_constant) continue;
            return error.MissingGlobalName;
        }
        if (global.type_text.len == 0) return error.MissingGlobalType;
        if (global.thread_local.len == 0) return error.MissingThreadLocalModel;
    }
    for (module.functions) |function| {
        if (function.name.len == 0) return error.MissingFunctionName;
        if (function.type_text.len == 0) return error.MissingFunctionType;
        if (!function.has_liveness) return error.MissingLiveness;
        if (function.instructions.len > function.instruction_count) return error.InstructionCountMismatch;
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
        if (function.structured_air_v2) |structured_air_v2| {
            if (structured_air_v2.instructions.len > function.instruction_count) return error.InvalidStructuredAirV2;
            const typed_seen = try module.allocator.alloc(bool, function.instruction_count);
            defer module.allocator.free(typed_seen);
            @memset(typed_seen, false);
            for (structured_air_v2.instructions) |instruction| {
                if (instruction.index >= typed_seen.len or typed_seen[instruction.index]) {
                    return error.InvalidStructuredAirV2;
                }
                if (instruction.opcode.len == 0 or instruction.result_type.len == 0 or instruction.data_kind.len == 0) {
                    return error.InvalidStructuredAirV2;
                }
                typed_seen[instruction.index] = true;
                for (instruction.operands) |operand| {
                    if (operand.kind.len == 0 or operand.value.len == 0 or operand.type_text.len == 0) {
                        return error.InvalidStructuredAirV2;
                    }
                }
                for (instruction.details) |detail| {
                    if (detail.key.len == 0) return error.InvalidStructuredAirV2;
                }
            }
        }
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
        std.mem.eql(u8, opcode, "fpext") or
        std.mem.eql(u8, opcode, "fptrunc") or
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

    fn peekValueLine(self: Cursor, key: []const u8) bool {
        if (self.offset >= self.contents.len) return false;
        const relative_end = std.mem.indexOfScalar(u8, self.contents[self.offset..], '\n') orelse
            return false;
        const line = self.contents[self.offset .. self.offset + relative_end];
        return line.len > key.len and std.mem.eql(u8, line[0..key.len], key) and line[key.len] == '=';
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

test "parse optional structured AIR records" {
    const air_text =
        \\  %0 = arg(i32, 0)
        \\  %1!= ret(%0!)
        \\
    ;
    const structured_air_text =
        \\structured_air-v1
        \\body|main|-|2|0|1
        \\inst|0|arg|3|i32
        \\inst|1|ret|8|noreturn
        \\structured_air_end
        \\
    ;
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=test
        \\root_source=structured.zig
        \\wrapper=structured.zig
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
        \\main_body_count=2
        \\liveness=present
        \\air_bytes={}
        \\{s}
        \\structured_air_bytes={}
        \\{s}
        \\function_end
        \\
    , .{ air_text.len, air_text, structured_air_text.len, structured_air_text });
    defer std.testing.allocator.free(input);

    var module = try parse(std.testing.allocator, input);
    defer module.deinit();

    const structured_air = module.functions[0].structured_air.?;
    try std.testing.expectEqual(@as(usize, 2), structured_air.instructions.len);
    try std.testing.expectEqualStrings("arg", structured_air.instructions[0].opcode);
    const main_body = structured_air.body(.main, null).?;
    try std.testing.expectEqualSlices(u32, &.{ 0, 1 }, main_body.instructions);
}

test "parse optional structured AIR v2 typed instruction records" {
    const air_text =
        \\  %0 = arg(i32, 0)
        \\  %1!= ret(%0!)
        \\
    ;
    const structured_air_text =
        \\structured_air-v1
        \\body|main|-|2|0|1
        \\inst|0|arg|3|i32
        \\inst|1|ret|8|noreturn
        \\structured_air_end
        \\
    ;
    const structured_air_v2_text =
        \\structured_air-v2
        \\typed_inst|0|arg|3|i32|arg|0
        \\typed_inst|1|ret|8|noreturn|un_op|1|inst|1|0|3|i32
        \\structured_air_v2_end
        \\
    ;
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=test
        \\root_source=typed.zig
        \\wrapper=typed.zig
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
        \\main_body_count=2
        \\liveness=present
        \\air_bytes={}
        \\{s}
        \\structured_air_bytes={}
        \\{s}
        \\structured_air_v2_bytes={}
        \\{s}
        \\function_end
        \\
    , .{ air_text.len, air_text, structured_air_text.len, structured_air_text, structured_air_v2_text.len, structured_air_v2_text });
    defer std.testing.allocator.free(input);

    var module = try parse(std.testing.allocator, input);
    defer module.deinit();

    const structured_air_v2 = module.functions[0].structured_air_v2.?;
    try std.testing.expectEqual(@as(usize, 2), structured_air_v2.instructions.len);
    try std.testing.expectEqualStrings("ret", structured_air_v2.instructions[1].opcode);
    try std.testing.expectEqualStrings("noreturn", structured_air_v2.instructions[1].result_type);
    try std.testing.expectEqual(@as(usize, 1), structured_air_v2.instructions[1].operands.len);
    try std.testing.expectEqualStrings("inst", structured_air_v2.instructions[1].operands[0].kind);
    try std.testing.expectEqualStrings("0", structured_air_v2.instructions[1].operands[0].value);
    try std.testing.expectEqualStrings("i32", structured_air_v2.instructions[1].operands[0].type_text);
}

test "parse structured AIR v2 typed instruction details" {
    const air_text =
        \\  %0!= ret(<i32, 0>)
        \\
    ;
    const structured_air_text =
        \\structured_air-v1
        \\body|main|-|1|0
        \\inst|0|ret|8|noreturn
        \\structured_air_end
        \\
    ;
    const structured_air_v2_text =
        \\structured_air-v2
        \\typed_inst|0|ret|8|noreturn|un_op|1|const|1|0|3|i32|1|literal|8|<i32, 0>
        \\structured_air_v2_end
        \\
    ;
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=test
        \\root_source=typed-details.zig
        \\wrapper=typed-details.zig
        \\mode=ReleaseFast
        \\target=x86_64-linux-gnu
        \\function_count=1
        \\global_count=0
        \\function_begin
        \\name_bytes=4
        \\main
        \\type_bytes=9
        \\fn () i32
        \\instruction_count=1
        \\main_body_count=1
        \\liveness=present
        \\air_bytes={}
        \\{s}
        \\structured_air_bytes={}
        \\{s}
        \\structured_air_v2_bytes={}
        \\{s}
        \\function_end
        \\
    , .{ air_text.len, air_text, structured_air_text.len, structured_air_text, structured_air_v2_text.len, structured_air_v2_text });
    defer std.testing.allocator.free(input);

    var module = try parse(std.testing.allocator, input);
    defer module.deinit();

    const instruction = module.functions[0].structured_air_v2.?.instructions[0];
    try std.testing.expectEqual(@as(usize, 1), instruction.details.len);
    try std.testing.expectEqualStrings("literal", instruction.details[0].key);
    try std.testing.expectEqualStrings("<i32, 0>", instruction.details[0].value);
}

test "reject AIR export instruction index outside storage count" {
    const air_text =
        \\  %2!= ret(<i32, 0>)
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

    try std.testing.expectError(error.InvalidInstructionIndex, parse(std.testing.allocator, input));
}
