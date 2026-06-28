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
};

pub const empty_provider: Provider = .{};

fn stripNominalSigil(text: []const u8) []const u8 {
    if (text.len != 0 and (text[0] == '%' or text[0] == '@')) return text[1..];
    return text;
}

test "exported aggregate layout provider matches exact nominal facts" {
    const facts = [_]Fact{
        .{ .nominal_type_name = "frontier.ExportedPair", .aggregate_text = "{ i32, i32 }" },
    };
    const provider: Provider = .{ .facts = facts[0..] };
    try std.testing.expect(provider.lookup("%frontier.ExportedPair") != null);
    try std.testing.expect(provider.lookup("other.ExportedPair") == null);
}
