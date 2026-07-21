const std = @import("std");

pub const Digest = [32]u8;

pub const Binding = struct {
    selected_functions: u64,
    actual_successful_functions: u16,
    failed_functions: u64,
    failure_order_sha256: Digest,
    successful_manifest_sha256: Digest,
};

pub fn validateBinding(binding: Binding) !void {
    if (binding.actual_successful_functions == 0 or
        binding.selected_functions !=
            @as(u64, binding.actual_successful_functions) + binding.failed_functions)
    {
        return error.SuccessfulFunctionCountMismatch;
    }
}

pub const Parsed = struct {
    binding: Binding,
    failures: []const []const u8,
    successful_functions: []const []const u8,

    pub fn deinit(parsed: Parsed, allocator: std.mem.Allocator) void {
        allocator.free(parsed.failures);
        allocator.free(parsed.successful_functions);
    }
};

fn parseUnsigned(bytes: []const u8) !u64 {
    if (bytes.len == 0) return error.ParseFailure;
    return std.fmt.parseUnsigned(u64, bytes, 10) catch error.ParseFailure;
}

fn hashU64(hasher: *std.crypto.hash.sha2.Sha256, value: u64) void {
    var encoded: [8]u8 = undefined;
    std.mem.writeInt(u64, &encoded, value, .little);
    hasher.update(&encoded);
}

fn hashBoundedBytes(hasher: *std.crypto.hash.sha2.Sha256, bytes: []const u8) void {
    hashU64(hasher, bytes.len);
    hasher.update(bytes);
}

fn digestFailureOrder(failures: []const []const u8) Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hashU64(&hasher, failures.len);
    for (failures) |failure| hashBoundedBytes(&hasher, failure);
    var digest: Digest = undefined;
    hasher.final(&digest);
    return digest;
}

fn sha256(bytes: []const u8) Digest {
    var digest: Digest = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return digest;
}

fn ownerIsAccepted(owner: []const u8) bool {
    return std.mem.eql(u8, owner, "composed_block") or
        std.mem.eql(u8, owner, "composed_cfg") or
        std.mem.eql(u8, owner, "legacy_envelope") or
        std.mem.eql(u8, owner, "structural_fallback");
}

fn parseSuccessfulManifest(
    allocator: std.mem.Allocator,
    stdout: []const u8,
) ![]const []const u8 {
    if (!std.mem.endsWith(u8, stdout, "\n") or std.mem.indexOf(u8, stdout, "\n\n") != null)
        return error.ParseFailure;
    var lines = std.mem.splitScalar(u8, stdout, '\n');
    const header = lines.next() orelse return error.ParseFailure;
    if (!std.mem.eql(u8, header, "row_identity\tselection_owner"))
        return error.ParseFailure;

    var functions = std.array_list.Managed([]const u8).init(allocator);
    errdefer functions.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const function = fields.next() orelse return error.ParseFailure;
        const owner = fields.next() orelse return error.ParseFailure;
        if (function.len == 0 or fields.next() != null or !ownerIsAccepted(owner))
            return error.ParseFailure;
        for (functions.items) |prior| {
            if (std.mem.eql(u8, prior, function)) return error.ParseFailure;
        }
        try functions.append(function);
    }
    if (functions.items.len == 0 or functions.items.len > std.math.maxInt(u16))
        return error.ParseFailure;
    return functions.toOwnedSlice();
}

fn parseFailuresInOrder(
    allocator: std.mem.Allocator,
    stderr: []const u8,
) ![]const []const u8 {
    var functions = std.array_list.Managed([]const u8).init(allocator);
    errdefer functions.deinit();
    var summary_count: usize = 0;
    var lines = std.mem.splitScalar(u8, stderr, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const first = tokens.next() orelse return error.ParseFailure;
        if (std.mem.eql(u8, first, "summary")) {
            const second = tokens.next() orelse return error.ParseFailure;
            if (std.mem.eql(u8, second, "zllvm-codegen-report-all")) summary_count += 1;
            continue;
        }
        if (!std.mem.eql(u8, first, "zllvm-codegen-failure")) continue;
        var function: ?[]const u8 = null;
        while (tokens.next()) |token| {
            if (!std.mem.startsWith(u8, token, "function=")) continue;
            if (function != null or token.len == "function=".len) return error.ParseFailure;
            function = token["function=".len..];
        }
        const admitted = function orelse return error.ParseFailure;
        for (functions.items) |prior| {
            if (std.mem.eql(u8, prior, admitted)) return error.ParseFailure;
        }
        try functions.append(admitted);
    }
    if (summary_count != 1 or functions.items.len == 0) return error.ParseFailure;
    return functions.toOwnedSlice();
}

fn parseBinding(
    stdout: []const u8,
    stderr: []const u8,
    failures: []const []const u8,
    successful_functions: []const []const u8,
) !Binding {
    var summary_seen: usize = 0;
    var binding: ?Binding = null;
    var lines = std.mem.splitScalar(u8, stderr, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "summary zllvm-codegen-report-all ")) continue;
        summary_seen += 1;
        var selected: ?u64 = null;
        var emitted: ?u64 = null;
        var failed: ?u64 = null;
        var local_fail: ?u64 = null;
        var first_failure: ?[]const u8 = null;
        var first_diagnostic: ?[]const u8 = null;
        var fields = std.mem.tokenizeScalar(u8, line, ' ');
        _ = fields.next();
        _ = fields.next();
        while (fields.next()) |field| {
            const separator = std.mem.indexOfScalar(u8, field, '=') orelse continue;
            const name = field[0..separator];
            const value = field[separator + 1 ..];
            if (std.mem.eql(u8, name, "selected_functions")) {
                selected = try parseUnsigned(value);
            } else if (std.mem.eql(u8, name, "emitted_functions")) {
                emitted = try parseUnsigned(value);
            } else if (std.mem.eql(u8, name, "failed_functions")) {
                failed = try parseUnsigned(value);
            } else if (std.mem.eql(u8, name, "local_fail")) {
                local_fail = try parseUnsigned(value);
            } else if (std.mem.eql(u8, name, "first_failing_function")) {
                first_failure = value;
            } else if (std.mem.eql(u8, name, "first_failing_diagnostic")) {
                first_diagnostic = value;
            }
        }
        if (selected == null or emitted == null or failed == null or local_fail == null or
            selected.? != emitted.? + failed.? or emitted.? == 0 or
            emitted.? != successful_functions.len or emitted.? > std.math.maxInt(u16) or
            failed.? != failures.len or local_fail.? != 1 or first_failure == null or
            first_diagnostic == null or first_failure.?.len == 0 or first_diagnostic.?.len == 0 or
            std.mem.eql(u8, first_failure.?, "-") or std.mem.eql(u8, first_diagnostic.?, "-") or
            failures.len == 0 or !std.mem.eql(u8, first_failure.?, failures[0]))
        {
            return error.ParseFailure;
        }
        binding = .{
            .selected_functions = selected.?,
            .actual_successful_functions = @intCast(emitted.?),
            .failed_functions = failed.?,
            .failure_order_sha256 = digestFailureOrder(failures),
            .successful_manifest_sha256 = sha256(stdout),
        };
    }
    if (summary_seen != 1) return error.ParseFailure;
    const result = binding orelse return error.ParseFailure;
    validateBinding(result) catch return error.ParseFailure;
    return result;
}

pub fn parse(
    allocator: std.mem.Allocator,
    stdout: []const u8,
    stderr: []const u8,
) !Parsed {
    const successful_functions = try parseSuccessfulManifest(allocator, stdout);
    errdefer allocator.free(successful_functions);
    const failures = try parseFailuresInOrder(allocator, stderr);
    errdefer allocator.free(failures);
    return .{
        .binding = try parseBinding(stdout, stderr, failures, successful_functions),
        .failures = failures,
        .successful_functions = successful_functions,
    };
}

pub fn requireSame(
    actual: Binding,
    expected: Binding,
) !void {
    if (!std.meta.eql(actual, expected)) return error.ResultDrift;
}

const test_stdout =
    "row_identity\tselection_owner\n" ++
    "good_a\tcomposed_cfg\n" ++
    "good_b\tlegacy_envelope\n";

const test_stderr =
    "zllvm-codegen-failure function=bad diagnostic=x selector_tag=y selector_detail=z\n" ++
    "zllvm-codegen-failure function=worse diagnostic=x selector_tag=y selector_detail=z\n" ++
    "summary zllvm-codegen-report-all selected_functions=4 emitted_functions=2 failed_functions=2 local_fail=1 first_failing_function=bad first_failing_diagnostic=x\n";

test "raw report derives successful count and binds ordered success and failure evidence" {
    const parsed = try parse(std.testing.allocator, test_stdout, test_stderr);
    defer parsed.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(u16, 2), parsed.binding.actual_successful_functions);
    try std.testing.expectEqualStrings("good_a", parsed.successful_functions[0]);
    try std.testing.expectEqualStrings("bad", parsed.failures[0]);
    try requireSame(parsed.binding, parsed.binding);
}

test "raw report rejects owner manifest and summary drift" {
    const reordered_stdout =
        "row_identity\tselection_owner\n" ++
        "good_b\tlegacy_envelope\n" ++
        "good_a\tcomposed_cfg\n";
    const reordered = try parse(std.testing.allocator, reordered_stdout, test_stderr);
    defer reordered.deinit(std.testing.allocator);
    const original = try parse(std.testing.allocator, test_stdout, test_stderr);
    defer original.deinit(std.testing.allocator);
    try std.testing.expectError(error.ResultDrift, requireSame(reordered.binding, original.binding));
    try std.testing.expectError(
        error.ParseFailure,
        parse(
            std.testing.allocator,
            "row_identity\tselection_owner\ngood_a\tunknown\n",
            test_stderr,
        ),
    );
    try std.testing.expectError(
        error.ParseFailure,
        parse(
            std.testing.allocator,
            "row_identity\tselection_owner\ngood_a\tcomposed_cfg\ngood_a\tlegacy_envelope\n",
            test_stderr,
        ),
    );
    try std.testing.expectError(
        error.ParseFailure,
        parse(
            std.testing.allocator,
            test_stdout,
            "zllvm-codegen-failure function=bad diagnostic=x selector_tag=y selector_detail=z\n" ++
                "summary zllvm-codegen-report-all selected_functions=3 emitted_functions=1 failed_functions=2 local_fail=1 first_failing_function=bad first_failing_diagnostic=x\n",
        ),
    );
}
