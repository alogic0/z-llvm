const std = @import("std");

pub const section_name = "zllvm-aggregate-layout-facts-v1";

pub const Evidence = struct {
    construction: bool = false,
    store: bool = false,
    load: bool = false,
};

pub const Fact = struct {
    nominal_type_name: []const u8,
    aggregate_text: []const u8,
    evidence: Evidence = .{
        .construction = true,
        .store = true,
        .load = true,
    },
};

pub const Provider = struct {
    facts: []const Fact = &.{},

    pub fn lookup(provider: Provider, nominal: []const u8) ?Fact {
        const normalized = stripNominalSigil(std.mem.trim(u8, nominal, " "));
        for (provider.facts) |fact| {
            if (std.mem.eql(u8, normalized, stripNominalSigil(std.mem.trim(u8, fact.nominal_type_name, " ")))) return fact;
        }
        return null;
    }

    pub fn deinit(provider: Provider, allocator: std.mem.Allocator) void {
        for (provider.facts) |fact| {
            allocator.free(fact.nominal_type_name);
            allocator.free(fact.aggregate_text);
        }
        allocator.free(provider.facts);
    }
};

pub const empty_provider: Provider = .{};
pub var active_provider: Provider = empty_provider;

pub fn setActiveProvider(provider: Provider) void {
    active_provider = provider;
}

pub fn parseSidecar(allocator: std.mem.Allocator, contents: []const u8) !Provider {
    var facts: std.ArrayList(Fact) = .empty;
    errdefer {
        for (facts.items) |fact| {
            allocator.free(fact.nominal_type_name);
            allocator.free(fact.aggregate_text);
        }
        facts.deinit(allocator);
    }

    var saw_header = false;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        if (!saw_header) {
            if (!std.mem.eql(u8, line, section_name)) return error.InvalidAggregateLayoutFactSidecar;
            saw_header = true;
            continue;
        }
        if (!std.mem.startsWith(u8, line, "fact ")) return error.InvalidAggregateLayoutFactSidecar;
        const nominal = extractQuotedField(line, "nominal=") orelse return error.InvalidAggregateLayoutFactSidecar;
        const aggregate_text = extractQuotedField(line, "aggregate=") orelse return error.InvalidAggregateLayoutFactSidecar;
        const evidence: Evidence = .{
            .construction = (try parseBoolField(line, "construction=")) orelse true,
            .store = (try parseBoolField(line, "store=")) orelse true,
            .load = (try parseBoolField(line, "load=")) orelse true,
        };
        try facts.append(allocator, .{
            .nominal_type_name = try allocator.dupe(u8, nominal),
            .aggregate_text = try allocator.dupe(u8, aggregate_text),
            .evidence = evidence,
        });
    }
    if (!saw_header) return error.InvalidAggregateLayoutFactSidecar;
    return .{ .facts = try facts.toOwnedSlice(allocator) };
}

fn stripNominalSigil(text: []const u8) []const u8 {
    if (text.len != 0 and (text[0] == '%' or text[0] == '@')) return text[1..];
    return text;
}

fn extractQuotedField(line: []const u8, marker: []const u8) ?[]const u8 {
    const marker_index = std.mem.indexOf(u8, line, marker) orelse return null;
    const after_marker = line[marker_index + marker.len ..];
    if (after_marker.len == 0 or after_marker[0] != '"') return null;
    const after_quote = after_marker[1..];
    const quote_end = std.mem.indexOfScalar(u8, after_quote, '"') orelse return null;
    return after_quote[0..quote_end];
}

fn parseBoolField(line: []const u8, marker: []const u8) !?bool {
    const marker_index = std.mem.indexOf(u8, line, marker) orelse return null;
    const value = line[marker_index + marker.len ..];
    if (std.mem.startsWith(u8, value, "1") or std.mem.startsWith(u8, value, "true")) return true;
    if (std.mem.startsWith(u8, value, "0") or std.mem.startsWith(u8, value, "false")) return false;
    return error.InvalidAggregateLayoutFactSidecar;
}

test "exported aggregate layout provider matches exact nominal facts" {
    const facts = [_]Fact{
        .{ .nominal_type_name = "frontier.ExportedPair", .aggregate_text = "{ i32, i32 }" },
    };
    const provider: Provider = .{ .facts = facts[0..] };
    try std.testing.expect(provider.lookup("%frontier.ExportedPair") != null);
    try std.testing.expect(provider.lookup("other.ExportedPair") == null);
}

test "exported aggregate layout facts parse sidecar contract" {
    const contents =
        section_name ++ "\n" ++
        "fact nominal=\"frontier.ExportedPair\" aggregate=\"{ i32, i32 }\" construction=1 store=1 load=1\n";
    const provider = try parseSidecar(std.testing.allocator, contents);
    defer provider.deinit(std.testing.allocator);
    const fact = provider.lookup("%frontier.ExportedPair").?;
    try std.testing.expectEqualStrings("{ i32, i32 }", fact.aggregate_text);
    try std.testing.expect(fact.evidence.construction);
    try std.testing.expect(fact.evidence.store);
    try std.testing.expect(fact.evidence.load);
}

test "exported aggregate layout facts reject missing header" {
    try std.testing.expectError(
        error.InvalidAggregateLayoutFactSidecar,
        parseSidecar(std.testing.allocator, "fact nominal=\"x\" aggregate=\"{ i32 }\"\n"),
    );
}

test "exported aggregate layout facts reject malformed evidence bool" {
    try std.testing.expectError(
        error.InvalidAggregateLayoutFactSidecar,
        parseSidecar(
            std.testing.allocator,
            section_name ++ "\n" ++
                "fact nominal=\"x\" aggregate=\"{ i32 }\" construction=maybe\n",
        ),
    );
}
