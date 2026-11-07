//! Authenticated additions to the fixed compiler-core execution cohort.
//! Fixtures are exact single-function extracts from the pinned three-mode AIR
//! cache, not replacement implementations. Harness references use independent
//! arithmetic/state models and call the original exported symbol locally.
const std = @import("std");
const air = @import("zig_air_export.zig");

const metadata = "hash_map.Custom(*Zcu.Namespace,void,hash_map.AutoContext(*Zcu.Namespace),80).Metadata";
const boundary_indexes = [_]usize{ 0, 1, 63, 64, 65, 127, 128, 129, 65535, 65536, std.math.maxInt(usize) / 2, std.math.maxInt(usize) };
const packed_patterns = [_]u64{ 0, 1, 2, 255, 256, 65535, 65536, 0x7fffffff, 0x80000000, 0xffffffff, 0x100000000, 0x100000001, 0x8000000000000000, 0xffffffffffffffff, 0x5555555555555555, 0xaaaaaaaaaaaaaaaa };

pub const source_paths = [_][]const u8{ "lib/std/bit_set.zig", "lib/std/atomic.zig", "lib/std/hash_map.zig", "lib/std/Io.zig", "src/InternPool.zig" };
const source_hashes = [_][]const u8{
    "ff5c6ac810343dcb1b80e91d31783df8adfdaa718776fdc23a3890a6cd6d44d9",
    "85b467837478ff64aba29bf52cf9eef9b973ddb3ec6b5472901500a8e4a925c5",
    "da14a2401ab5c12d6ca25bbf49e950596859ffc9e4b6d7726ade7ea8fd4a1b34",
    "382a4e343017183eff88e311f983066f88306e7bfcd85a890723b3697f4b2732",
    "8cd9ff53f96fbf9206c8f37fd1045b6a572617858fd0ba76bda28df44e0630a7",
};

pub fn validateSources(sources: [source_paths.len][]const u8) !void {
    for (sources, source_hashes) |source, expected| {
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(source, &digest, .{});
        if (!std.mem.eql(u8, &std.fmt.bytesToHex(digest, .lower), expected)) return error.CohortSourceBindingMismatch;
    }
}

pub const Member = enum {
    dynamic_mask_index,
    mutex_try_lock,
    metadata_is_free,
    metadata_is_tombstone,
    event_reset,
    packed_u64_get,
    packed_u64_init,

    pub fn functionName(member: Member) []const u8 {
        return switch (member) {
            .dynamic_mask_index => "bit_set.Dynamic.maskIndex",
            .mutex_try_lock => "atomic.Mutex.tryLock",
            .metadata_is_free => metadata ++ ".isFree",
            .metadata_is_tombstone => metadata ++ ".isTombstone",
            .event_reset => "Io.Event.reset",
            .packed_u64_get => "InternPool.PackedU64.get",
            .packed_u64_init => "InternPool.PackedU64.init",
        };
    }
    pub fn descriptorType(member: Member) []const u8 {
        return switch (member) {
            .dynamic_mask_index => "fn (usize) usize",
            .mutex_try_lock => "fn (*atomic.Mutex) bool",
            .metadata_is_free, .metadata_is_tombstone => "fn (" ++ metadata ++ ") bool",
            .event_reset => "fn (*Io.Event) void",
            .packed_u64_get => "fn (InternPool.PackedU64) u64",
            .packed_u64_init => "fn (u64) InternPool.PackedU64",
        };
    }
    pub fn descriptorReturnType(member: Member) []const u8 {
        return switch (member) {
            .dynamic_mask_index => "usize",
            .event_reset => "void",
            .packed_u64_get => "u64",
            .packed_u64_init => "InternPool.PackedU64",
            else => "bool",
        };
    }
    pub fn observations(member: Member) usize {
        return switch (member) {
            .dynamic_mask_index => 4096 + boundary_indexes.len,
            .mutex_try_lock => 384,
            .metadata_is_free, .metadata_is_tombstone => 256,
            .event_reset => 512,
            .packed_u64_get, .packed_u64_init => 1024 + packed_patterns.len,
        };
    }
    pub fn expectedResult(member: Member) usize {
        return switch (member) {
            .dynamic_mask_index => member.observations(),
            .mutex_try_lock => 256,
            .metadata_is_free, .metadata_is_tombstone => 1,
            .event_reset, .packed_u64_get, .packed_u64_init => member.observations(),
        };
    }
    pub fn expectedWitness(member: Member) usize {
        return switch (member) {
            .dynamic_mask_index => comptime maskWitness(),
            .mutex_try_lock => 512,
            .metadata_is_free => 1,
            .metadata_is_tombstone => 2,
            .event_reset => 98688,
            .packed_u64_get, .packed_u64_init => comptime packedWitness(),
        };
    }
    pub fn expectedStdout(member: Member) []const u8 {
        return switch (member) {
            inline else => |m| comptime std.fmt.comptimePrint("execution-oracle-v4 cases={d} result={d} witness={d}\n", .{ m.observations(), m.expectedResult(), m.expectedWitness() }),
        };
    }
    pub fn referenceHarness(member: Member) []const u8 {
        return switch (member) {
            inline else => |m| comptime makeHarness(m, false),
        };
    }
    pub fn linkedHarness(member: Member) []const u8 {
        return switch (member) {
            inline else => |m| comptime makeHarness(m, true),
        };
    }
    pub fn fixture(member: Member, comptime mode: []const u8) []const u8 {
        return switch (member) {
            .dynamic_mask_index => @embedFile("distribution_execution_breadth/fixtures/mask_index_" ++ mode ++ ".air"),
            .mutex_try_lock => @embedFile("distribution_execution_breadth/fixtures/mutex_" ++ mode ++ ".air"),
            .metadata_is_free => @embedFile("distribution_execution_breadth/fixtures/metadata_free_" ++ mode ++ ".air"),
            .metadata_is_tombstone => @embedFile("distribution_execution_breadth/fixtures/metadata_tombstone_" ++ mode ++ ".air"),
            .event_reset => @embedFile("distribution_execution_breadth/fixtures/event_reset_" ++ mode ++ ".air"),
            .packed_u64_get => @embedFile("distribution_execution_breadth/fixtures/packed_get_" ++ mode ++ ".air"),
            .packed_u64_init => @embedFile("distribution_execution_breadth/fixtures/packed_init_" ++ mode ++ ".air"),
        };
    }

    pub fn hasMemoryGuard(member: Member) bool {
        return member == .mutex_try_lock or member == .event_reset;
    }

    pub fn isPacked(member: Member) bool {
        return member == .packed_u64_get or member == .packed_u64_init;
    }
};

pub fn fromProgram(program: anytype) ?Member {
    return std.meta.stringToEnum(Member, @tagName(program));
}

fn maskWitness() usize {
    @setEvalBranchQuota(100_000);
    var witness: usize = 0;
    for (0..4096) |input| witness +%= (input / 64) ^ input;
    for (boundary_indexes) |input| witness +%= (input / 64) ^ input;
    return witness;
}

fn packedWitness() usize {
    @setEvalBranchQuota(100_000);
    var state: u64 = 0x6a09e667f3bcc909;
    var witness: u64 = 0;
    for (0..1040) |case| {
        state = state *% 6364136223846793005 +% 1442695040888963407;
        const input = if (case < packed_patterns.len) packed_patterns[case] else state;
        witness +%= input ^ case;
    }
    return witness;
}

fn makeHarness(comptime member: Member, comptime linked: bool) []const u8 {
    const signature = switch (member) {
        .dynamic_mask_index => "fn (usize) callconv(.{ .x86_64_sysv = .{} }) usize",
        .mutex_try_lock => "fn (*u8) callconv(.{ .x86_64_sysv = .{} }) bool",
        .metadata_is_free, .metadata_is_tombstone => "fn (u8) callconv(.{ .x86_64_sysv = .{} }) bool",
        .event_reset => "fn (*u32) callconv(.{ .x86_64_sysv = .{} }) void",
        .packed_u64_get, .packed_u64_init => "fn (u64) callconv(.{ .x86_64_sysv = .{} }) u64",
    };
    const prefix = "const std = @import(\"std\");\n" ++
        (if (linked) "const subject = @extern(*const " ++ signature ++ ", .{ .name = \"" ++ member.functionName() ++ "\" });\n" else "") ++
        "pub fn main(init: std.process.Init) !void {\n    var result: usize = 0;\n    var witness: usize = 0;\n";
    const body = switch (member) {
        .event_reset =>
        \\    for (0..256) |case| {
        \\        var guarded = [_]u32{ 0xa5a55a5a, 0x12345678, 0x87654321, 0x55aaaa55, 0x5a5aa5a5 };
        \\        const slot = 1 + case % 3;
        \\        guarded[slot] = if (case % 2 == 0) 2 else 0;
        \\        var expected = guarded;
        \\        expected[slot] = 0;
        \\        for (0..2) |attempt| {
        \\
        ++ (if (linked) "            subject(&guarded[slot]);\n" else "            guarded[slot] = 0;\n") ++
            \\            if (!std.mem.eql(u32, &guarded, &expected)) return error.EventOracleMismatch;
            \\            result += 1;
            \\            witness += (case + 1) * (attempt + 1);
            \\        }
            \\    }
            \\
        ,
        .packed_u64_get, .packed_u64_init =>
        \\    const patterns = [_]u64{ 0, 1, 2, 255, 256, 65535, 65536, 0x7fffffff, 0x80000000, 0xffffffff, 0x100000000, 0x100000001, 0x8000000000000000, 0xffffffffffffffff, 0x5555555555555555, 0xaaaaaaaaaaaaaaaa };
        \\    var state: u64 = 0x6a09e667f3bcc909;
        \\    for (0..1040) |case| {
        \\        state = state *% 6364136223846793005 +% 1442695040888963407;
        \\        const input = if (case < patterns.len) patterns[case] else state;
        \\        const low: u32 = @truncate(input);
        \\        const high: u32 = @truncate(input >> 32);
        \\
        ++ (if (linked) "        const actual = subject(input);\n" else "        const actual = @as(u64, high) * 0x100000000 + low;\n") ++
            \\        if (@as(u32, @truncate(actual)) != low or actual >> 32 != high) return error.PackedOracleMismatch;
            \\        result += 1;
            \\        witness +%= actual ^ case;
            \\    }
            \\
        ,
        .dynamic_mask_index =>
        \\    const boundaries = [_]usize{ 0, 1, 63, 64, 65, 127, 128, 129, 65535, 65536, std.math.maxInt(usize) / 2, std.math.maxInt(usize) };
        \\    for (0..4108) |case| {
        \\        const input = if (case < 4096) case else boundaries[case - 4096];
        \\
        ++ (if (linked) "        const actual = subject(input);\n" else "        const actual = input / 64;\n") ++
            \\        if (actual != input / 64) return error.IndexOracleMismatch;
            \\        result += 1;
            \\        witness +%= actual ^ input;
            \\    }
            \\
        ,
        .mutex_try_lock =>
        \\    for (0..128) |_| {
        \\        var guarded = [_]u8{ 0xa5, 0, 0x5a };
        \\        for (0..3) |attempt| {
        \\            if (attempt == 2) guarded[1] = 0;
        \\
        ++ (if (linked) "            const actual = subject(&guarded[1]);\n" else "            const actual = guarded[1] == 0;\n            if (actual) guarded[1] = 1;\n") ++
            \\            if (actual != (attempt != 1) or guarded[1] != 1 or guarded[0] != 0xa5 or guarded[2] != 0x5a) return error.MutexOracleMismatch;
            \\            result += @intFromBool(actual);
            \\            witness += if (actual) attempt + 1 else 0;
            \\        }
            \\    }
            \\
        ,
        .metadata_is_free, .metadata_is_tombstone =>
        \\    for (0..256) |input| {
        \\
        ++ (if (linked) "        const actual = subject(@intCast(input));\n" else std.fmt.comptimePrint("        const actual = input == {d};\n", .{@intFromBool(member == .metadata_is_tombstone)})) ++
            std.fmt.comptimePrint("        if (actual != (input == {d})) return error.MetadataOracleMismatch;\n", .{@intFromBool(member == .metadata_is_tombstone)}) ++
            \\        result += @intFromBool(actual);
            \\        witness += if (actual) input + 1 else 0;
            \\    }
            \\
        ,
    };
    return prefix ++ body ++
        "    var buffer: [256]u8 = undefined;\n    var writer = std.Io.File.stdout().writer(init.io, &buffer);\n" ++
        std.fmt.comptimePrint("    try writer.interface.print(\"execution-oracle-v4 cases={d} result={{}} witness={{}}\\n\", .{{ result, witness }});\n", .{member.observations()}) ++
        "    try writer.interface.flush();\n}\n";
}

pub fn validateHarnesses(member: Member) !void {
    const linked = member.linkedHarness();
    const reference = member.referenceHarness();
    if (std.mem.count(u8, linked, member.functionName()) != 1 or
        std.mem.count(u8, linked, "subject(") != 1 or
        std.mem.count(u8, reference, "subject(") != 0 or
        std.mem.count(u8, reference, "@extern") != 0) return error.HarnessBindingMismatch;
}

pub fn validateDescriptor(allocator: std.mem.Allocator, member: Member, function: air.Function) !void {
    if (!std.mem.eql(u8, function.name, member.functionName()) or
        !std.mem.eql(u8, function.type_text, member.descriptorType())) return error.CohortDescriptorBindingMismatch;
    // Bind both textual operands (including cmpxchg ordering/state) and the
    // typed/control-flow descriptors. All three pinned modes are explicit.
    inline for (.{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }) |mode| {
        var reference = try air.parse(allocator, member.fixture(mode));
        defer reference.deinit();
        const expected = reference.functions[0];
        if (function.instruction_count == expected.instruction_count and function.main_body_count == expected.main_body_count and function.has_liveness == expected.has_liveness and
            std.mem.eql(u8, function.air_text, expected.air_text) and
            std.mem.eql(u8, function.structured_air_text orelse "", expected.structured_air_text.?) and
            std.mem.eql(u8, function.structured_air_v2_text orelse "", expected.structured_air_v2_text.?)) return;
    }
    return error.CohortDescriptorBindingMismatch;
}

test "execution breadth authenticates all mode descriptors and rejects changed operands symbols and ABI" {
    for (std.enums.values(Member)) |member| {
        try validateHarnesses(member);
        inline for (.{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }) |mode| {
            var module = try air.parse(std.testing.allocator, member.fixture(mode));
            defer module.deinit();
            const original = module.functions[0];
            try validateDescriptor(std.testing.allocator, member, original);
            var changed = original;
            changed.name = "wrong-symbol";
            try std.testing.expectError(error.CohortDescriptorBindingMismatch, validateDescriptor(std.testing.allocator, member, changed));
            changed = original;
            changed.type_text = "fn () bool";
            try std.testing.expectError(error.CohortDescriptorBindingMismatch, validateDescriptor(std.testing.allocator, member, changed));
            changed = original;
            changed.air_text = "wrong result or memory effect";
            try std.testing.expectError(error.CohortDescriptorBindingMismatch, validateDescriptor(std.testing.allocator, member, changed));
            changed = original;
            changed.structured_air_v2_text = "missing operand authentication";
            try std.testing.expectError(error.CohortDescriptorBindingMismatch, validateDescriptor(std.testing.allocator, member, changed));
        }
    }
}
