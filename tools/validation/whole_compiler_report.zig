//! Interpret existing diagnostic records without treating missing stages as success.
const std = @import("std");
const u = @import("common.zig");

pub const Counts = struct { selected: u64, emitted: u64, failed: u64 };

/// A bounded tail provides progress after termination, never census credit.
/// Ignore a partial first/last line; a killed write need not end at a record.
pub fn eventTail(a: std.mem.Allocator, bytes: []const u8, partial_prefix: bool) !u.Value {
    var report = u.object(a);
    try u.put(a, &report, "whole_stream_verified", u.b(false));
    try u.put(a, &report, "last_record", .null);
    const begin = if (partial_prefix) (std.mem.indexOfScalar(u8, bytes, '\n') orelse return report) + 1 else 0;
    const end = std.mem.lastIndexOfScalar(u8, bytes, '\n') orelse return report;
    try u.put(a, &report, "unflushed_tail_bytes", u.n(bytes.len - end - 1));
    if (end < begin) return report;
    const start = if (std.mem.lastIndexOfScalar(u8, bytes[begin..end], '\n')) |i| begin + i + 1 else begin;
    const value = (try u.json.parse(a, bytes[start..end])).value;
    if (!u.json.is(try u.get(value, "schema"), "compilation-events-v1") or
        (try u.get(value, "sequence")) != .integer or (try u.get(value, "sequence")).integer < 0 or
        (try u.get(value, "event")) != .string) return error.InvalidProgressRecord;
    try u.put(a, &report, "last_record", value);
    return report;
}

test "whole compiler progress retains only complete tail records without census credit" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const record = "{\"schema\":\"compilation-events-v1\",\"sequence\":7,\"event\":\"activity_begin\",\"function\":\"large\"}\n";
    for ([_]bool{ false, true }) |partial| {
        const bytes = try std.mem.concat(a, u8, &.{ if (partial) "partial\n" else "", record, "{\"broken" });
        const result = try eventTail(a, bytes, partial);
        try std.testing.expectEqualStrings("large", try u.str(try u.get(result, "last_record"), "function"));
        try std.testing.expectEqual(@as(i64, 8), (try u.get(result, "unflushed_tail_bytes")).integer);
        try std.testing.expect(!(try u.get(result, "whole_stream_verified")).bool);
    }
    try std.testing.expect((try u.get(try eventTail(a, "partial", true), "last_record")) == .null);
    try std.testing.expectError(error.InvalidProgressRecord, eventTail(a, "{\"schema\":\"other\",\"event\":\"profile_end\",\"sequence\":0}\n", false));
}

fn field(line: []const u8, name: []const u8) ?[]const u8 {
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    while (tokens.next()) |token| {
        if (std.mem.startsWith(u8, token, name)) return token[name.len..];
    }
    return null;
}

pub fn counts(line: []const u8) !Counts {
    const result: Counts = .{
        .selected = try std.fmt.parseInt(u64, field(line, "selected_functions=") orelse return error.MissingSelectionCount, 10),
        .emitted = try std.fmt.parseInt(u64, field(line, "emitted_functions=") orelse return error.MissingSelectionCount, 10),
        .failed = try std.fmt.parseInt(u64, field(line, "failed_functions=") orelse return error.MissingSelectionCount, 10),
    };
    if (try std.math.add(u64, result.emitted, result.failed) != result.selected) return error.InconsistentSelectionCounts;
    const local_fail = field(line, "local_fail=") orelse return error.MissingSelectionCount;
    if (!std.mem.eql(u8, local_fail, if (result.failed == 0) "0" else "1")) return error.InconsistentSelectionCounts;
    return result;
}

pub const Failure = struct { function: []const u8, diagnostic: []const u8, tag: []const u8, detail: []const u8 };
pub fn failure(line: []const u8) !Failure {
    const prefix = "zllvm-codegen-failure function=";
    if (!std.mem.startsWith(u8, line, prefix)) return error.InvalidFailureRecord;
    const d = std.mem.indexOf(u8, line[prefix.len..], " diagnostic=") orelse return error.InvalidFailureRecord;
    const function_end = prefix.len + d;
    const diagnostic_start = function_end + " diagnostic=".len;
    const t = std.mem.indexOf(u8, line[diagnostic_start..], " selector_tag=") orelse return error.InvalidFailureRecord;
    const tag_start = diagnostic_start + t + " selector_tag=".len;
    const x = std.mem.indexOf(u8, line[tag_start..], " selector_detail=") orelse return error.InvalidFailureRecord;
    const result: Failure = .{
        .function = line[prefix.len..function_end],
        .diagnostic = line[diagnostic_start .. diagnostic_start + t],
        .tag = line[tag_start .. tag_start + x],
        .detail = line[tag_start + x + " selector_detail=".len ..],
    };
    if (result.function.len == 0 or result.diagnostic.len == 0 or result.tag.len == 0 or result.detail.len == 0) return error.InvalidFailureRecord;
    return result;
}

pub fn analyze(a: std.mem.Allocator, diagnostic: []const u8) !u.Value {
    var report = u.object(a);
    var rows = u.array(a);
    var groups = u.array(a);
    var names = std.StringHashMap(void).init(a);
    defer names.deinit();
    var summary: ?Counts = null;
    var selection: ?[]const u8 = null;
    var lines = std.mem.tokenizeScalar(u8, diagnostic, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "summary zllvm-codegen-selection ")) {
            if (selection != null) return error.DuplicateSelectionSummary;
            selection = field(line, "coverage=") orelse return error.MissingSelectionCoverage;
        } else if (std.mem.startsWith(u8, line, "summary zllvm-codegen-report-all ")) {
            if (summary != null) return error.DuplicateSelectionSummary;
            summary = try counts(line);
        } else if (std.mem.startsWith(u8, line, "zllvm-codegen-failure ")) {
            const f = try failure(line);
            const entry = try names.getOrPut(f.function);
            if (entry.found_existing) return error.DuplicateFunctionFailure;
            var row = u.object(a);
            try u.put(a, &row, "function", u.s(f.function));
            try u.put(a, &row, "diagnostic", u.s(f.diagnostic));
            try u.put(a, &row, "selector_tag", u.s(f.tag));
            try u.put(a, &row, "selector_detail", u.s(f.detail));
            try u.add(&rows, row);
            // Keep the reported detail intact. Equal diagnostics/tags form a
            // capability cluster; examples do not imply a single root cause.
            var found = false;
            for (groups.array.items) |*group| {
                if (!std.mem.eql(u8, try u.str(group.*, "diagnostic"), f.diagnostic) or
                    !std.mem.eql(u8, try u.str(group.*, "selector_tag"), f.tag)) continue;
                try u.increment(a, group, "functions", 1);
                found = true;
                break;
            }
            if (!found) {
                var group = u.object(a);
                try u.put(a, &group, "diagnostic", u.s(f.diagnostic));
                try u.put(a, &group, "selector_tag", u.s(f.tag));
                try u.put(a, &group, "functions", u.n(1));
                try u.put(a, &group, "example", u.s(f.function));
                try u.add(&groups, group);
            }
        }
    }
    if (summary) |s| if (s.failed != rows.array.items.len) return error.MissingFunctionFailures;
    try u.put(a, &report, "selection_completed", u.b(summary != null));
    try u.put(a, &report, "dependency_coverage", if (selection) |s| u.s(s) else .null);
    try u.put(a, &report, "counts", if (summary) |s| blk: {
        var value = u.object(a);
        try u.put(a, &value, "selected", u.n(s.selected));
        try u.put(a, &value, "selected_successfully", u.n(s.emitted));
        try u.put(a, &value, "failed", u.n(s.failed));
        break :blk value;
    } else .null);
    try u.put(a, &report, "failures", rows);
    try u.put(a, &report, "groups", groups);
    return report;
}

pub fn stage(profile: ?u.Value, analysis: u.Value, code: i64, completed: bool) ![]const u8 {
    if (!completed) return "process-interruption";
    if (code == 0) return "object-emission";
    if ((try u.get(analysis, "failures")).array.items.len != 0) return "selection";
    if (profile) |p| {
        const phases = try u.get(p, "phases");
        // No optimizations are requested in the postopt backend invocation.
        for ([_][]const u8{ "ownership_write", "object_write", "select", "normalize", "legalize", "reachability", "verify", "parse", "input" }) |name| {
            for (phases.array.items) |row| {
                if (std.mem.eql(u8, try u.str(row, "phase"), name) and (try u.get(row, "exclusive_ns")).integer > 0)
                    return if (std.mem.eql(u8, name, "select") or std.mem.eql(u8, name, "normalize") or std.mem.eql(u8, name, "legalize")) "selection" else name;
            }
        }
    }
    return "backend-unclassified";
}

// Legacy machine lowering removes the surrounding LLVM quotes. Both producers
// retain hexadecimal escapes, so compare their spellings after that same step.
pub fn ownershipName(name: []const u8) []const u8 {
    return if (name.len >= 2 and name[0] == '"' and name[name.len - 1] == '"') name[1 .. name.len - 1] else name;
}

pub fn objectSymbolName(a: std.mem.Allocator, spelling: []const u8) ![]const u8 {
    const name = ownershipName(spelling);
    var bytes: std.ArrayList(u8) = .empty;
    var i: usize = 0;
    while (i < name.len) : (i += 1) {
        if (name[i] == '\\') {
            if (name.len - i < 3 or !std.ascii.isHex(name[i + 1]) or !std.ascii.isHex(name[i + 2])) return error.InvalidSymbolName;
            const byte = try std.fmt.parseInt(u8, name[i + 1 ..][0..2], 16);
            if (byte == 0) return error.InvalidSymbolName;
            try bytes.append(a, byte);
            i += 2;
        } else try bytes.append(a, name[i]);
    }
    return bytes.toOwnedSlice(a);
}

/// A selected LLVM intrinsic cannot be delegated as an unresolved ELF call.
/// Every selected function must own nonempty text; all symbol and relocation
/// extents must fit their declared sections before object completion is claimed.
pub fn validateObject(a: std.mem.Allocator, contract: u.Value, profile: u.Value) !void {
    var sizes = std.StringHashMap(i64).init(a);
    defer sizes.deinit();
    for ((try u.get(contract, "allocated_sections")).array.items) |section| try sizes.put(section.array.items[0].string, section.array.items[3].integer);
    var symbols = std.StringHashMap(u.Value).init(a);
    defer symbols.deinit();
    for ((try u.get(contract, "symbols")).array.items) |symbol| {
        const fields = symbol.array.items;
        const name = fields[0].string;
        if ((try symbols.getOrPut(name)).found_existing) return error.DuplicateElfSymbol;
        try symbols.put(name, symbol);
        if (fields[3] == .string and fields[3].string.len == 0) {
            if (std.mem.startsWith(u8, name, "llvm.")) return error.UnresolvedLlvmIntrinsic;
        } else if (fields[3] == .string) {
            const size = sizes.get(fields[3].string) orelse return error.UnknownSymbolSection;
            if (fields[4].integer < 0 or fields[5].integer < 0 or fields[4].integer > size or fields[5].integer > size - fields[4].integer) return error.InvalidSymbolBounds;
        } else return error.UnsupportedSymbolSection;
    }
    for ((try u.get(profile, "functions")).array.items) |function| {
        const symbol = symbols.get(try objectSymbolName(a, try u.str(function, "name"))) orelse return error.MissingFunctionSymbol;
        const fields = symbol.array.items;
        if (fields[1].integer & 15 != 2 or !u.json.is(fields[3], ".text") or fields[5].integer <= 0) return error.InvalidFunctionSymbol;
    }
    for ((try u.get(contract, "relocations")).array.items) |relocation| {
        const fields = relocation.array.items;
        const size = sizes.get(fields[0].string) orelse return error.UnknownRelocationSection;
        const width: i64 = switch (fields[2].integer) {
            1 => 8,
            2, 4, 10, 11, 19, 23 => 4,
            else => return error.UnsupportedRelocationKind,
        };
        if (fields[1].integer < 0 or fields[1].integer > size or width > size - fields[1].integer) return error.InvalidRelocationBounds;
        if (!symbols.contains(fields[3].string)) return error.MissingRelocationSymbol;
    }
}

pub fn validateSuccess(a: std.mem.Allocator, analysis: u.Value, profile: u.Value, owners: []const u8) !void {
    if (!(try u.get(analysis, "selection_completed")).bool or (try u.get(analysis, "dependency_coverage")) == .null) return error.MissingCompleteSelection;
    const n = try u.get(analysis, "counts");
    const selected = (try u.get(n, "selected")).integer;
    if (selected == 0 or (try u.get(n, "failed")).integer != 0 or selected != (try u.get(n, "selected_successfully")).integer) return error.IncompleteObject;
    if (!(try u.get(profile, "succeeded")).bool) return error.UnsuccessfulProfile;
    if ((try u.get(try u.get(profile, "counters"), "selected_functions")).integer != selected) return error.ProfileCountMismatch;
    var names = std.StringHashMap(void).init(a);
    defer names.deinit();
    var lines = std.mem.tokenizeScalar(u8, owners, '\n');
    if (!std.mem.eql(u8, lines.next() orelse "", "row_identity\tselection_owner")) return error.InvalidOwnershipHeader;
    while (lines.next()) |line| {
        var columns = std.mem.splitScalar(u8, line, '\t');
        const name = columns.next() orelse return error.InvalidOwnership;
        const owner = columns.next() orelse return error.InvalidOwnership;
        if (name.len == 0 or columns.next() != null or !u.contains(&.{ "legacy_envelope", "composed_block", "composed_cfg", "structural_fallback" }, owner)) return error.InvalidOwnership;
        if ((try names.getOrPut(ownershipName(name))).found_existing) return error.DuplicateOwnership;
    }
    if (names.count() != selected) return error.IncompleteOwnership;
    // Match names as well as counts: a substituted manifest earns no success.
    const functions = (try u.get(profile, "functions")).array.items;
    if (functions.len != selected) return error.ProfileCountMismatch;
    var observed = std.StringHashMap(void).init(a);
    defer observed.deinit();
    for (functions) |function| {
        const name = ownershipName(try u.str(function, "name"));
        if (!names.contains(name)) return error.OwnershipNameMismatch;
        if ((try observed.getOrPut(name)).found_existing) return error.DuplicateProfileFunction;
    }
}

test "whole compiler records early failures without claiming a selection census" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const result = try analyze(arena.allocator(), "error: UnsupportedInstruction\n");
    try std.testing.expect(!(try u.get(result, "selection_completed")).bool);
    try std.testing.expect((try u.get(result, "counts")) == .null);
    try std.testing.expectEqualStrings("backend-unclassified", try stage(null, result, 1, true));
    try std.testing.expectEqualStrings("process-interruption", try stage(null, result, 124, false));
}

const two_failures =
    "summary zllvm-codegen-selection mode=reachable coverage=conservative selected_globals=1 selected_aliases=0\n" ++
    "zllvm-codegen-failure function=one(a, b) diagnostic=Unsupported tag=no selector_tag=alias selector_detail=cycle with widths\n" ++
    "zllvm-codegen-failure function=two diagnostic=Unsupported tag=no selector_tag=alias selector_detail=other\n" ++
    "summary zllvm-codegen-report-all selected_functions=3 emitted_functions=1 failed_functions=2 local_fail=1\n";

test "whole compiler groups full function failures and rejects incomplete or inconsistent census" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const result = try analyze(a, two_failures);
    try std.testing.expectEqual(@as(usize, 2), (try u.get(result, "failures")).array.items.len);
    try std.testing.expectEqual(@as(usize, 1), (try u.get(result, "groups")).array.items.len);
    try std.testing.expectEqualStrings("selection", try stage(null, result, 1, true));
    try std.testing.expectError(error.MissingFunctionFailures, analyze(a, "summary zllvm-codegen-report-all selected_functions=3 emitted_functions=1 failed_functions=2 local_fail=1\n"));
    try std.testing.expectError(error.InconsistentSelectionCounts, counts("selected_functions=3 emitted_functions=2 failed_functions=2 local_fail=1"));
    try std.testing.expectError(error.DuplicateSelectionSummary, analyze(a, two_failures ++ two_failures));
    try std.testing.expectError(error.InvalidFailureRecord, failure("zllvm-codegen-failure function=foo"));
}

test "whole compiler rejects substituted owners and apparent partial success" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const result = try analyze(a, "summary zllvm-codegen-selection coverage=complete\nsummary zllvm-codegen-report-all selected_functions=1 emitted_functions=1 failed_functions=0 local_fail=0\n");
    const profile = (try u.json.parse(a, "{\"succeeded\":true,\"counters\":{\"selected_functions\":1},\"functions\":[{\"name\":\"foo\"}]}")).value;
    try validateSuccess(a, result, profile, "row_identity\tselection_owner\nfoo\tcomposed_cfg\n");
    try std.testing.expectError(error.OwnershipNameMismatch, validateSuccess(a, result, profile, "row_identity\tselection_owner\nbar\tcomposed_cfg\n"));
    try std.testing.expectError(error.IncompleteOwnership, validateSuccess(a, result, profile, "row_identity\tselection_owner\n"));
    try std.testing.expectError(error.DuplicateOwnership, validateSuccess(a, result, profile, "row_identity\tselection_owner\nfoo\tcomposed_cfg\nfoo\tcomposed_cfg\n"));
    try std.testing.expectError(error.MissingCompleteSelection, validateSuccess(a, try analyze(a, ""), profile, ""));
}

test "whole compiler matches quoted profiles with legacy machine owners without dropping escapes" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const result = try analyze(a, "summary zllvm-codegen-selection coverage=conservative\nsummary zllvm-codegen-report-all selected_functions=2 emitted_functions=2 failed_functions=0 local_fail=0\n");
    const profile = (try u.json.parse(a, "{\"succeeded\":true,\"counters\":{\"selected_functions\":2},\"functions\":[{\"name\":\"\\\"helper(a, b)\\\"\"},{\"name\":\"\\\"type.\\\\22union\\\\22\\\"\"}]}")).value;
    try validateSuccess(a, result, profile, "row_identity\tselection_owner\nhelper(a, b)\tcomposed_cfg\ntype.\\22union\\22\tcomposed_block\n");
    try std.testing.expectError(error.OwnershipNameMismatch, validateSuccess(a, result, profile, "row_identity\tselection_owner\nhelper(a, b)\tcomposed_cfg\ntype.union\tcomposed_block\n"));
    (try u.get(profile, "functions")).array.items[1] = (try u.get(profile, "functions")).array.items[0];
    try std.testing.expectError(error.DuplicateProfileFunction, validateSuccess(a, result, profile, "row_identity\tselection_owner\nhelper(a, b)\tcomposed_cfg\ntype.\\22union\\22\tcomposed_block\n"));
}

test "whole compiler object audit rejects intrinsic providers missing definitions and invalid extents" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const contract = (try u.json.parse(a, "{\"allocated_sections\":[[\".text\",1,6,8,\"hash\"]],\"symbols\":[[\"helper\",18,0,\".text\",0,8],[\"provider\",16,0,\"\",0,0]],\"relocations\":[[\".text\",4,4,\"provider\",-4]]}")).value;
    const profile = (try u.json.parse(a, "{\"functions\":[{\"name\":\"\\\"hel\\\\70er\\\"\"}]}")).value;
    try validateObject(a, contract, profile);
    const symbols = (try u.get(contract, "symbols")).array.items;
    symbols[1].array.items[0] = u.s("llvm.ucmp.i32.i64");
    try std.testing.expectError(error.UnresolvedLlvmIntrinsic, validateObject(a, contract, profile));
    symbols[1].array.items[0] = u.s("provider");
    symbols[0].array.items[5] = u.n(9);
    try std.testing.expectError(error.InvalidSymbolBounds, validateObject(a, contract, profile));
    symbols[0].array.items[5] = u.n(0);
    try std.testing.expectError(error.InvalidFunctionSymbol, validateObject(a, contract, profile));
    symbols[0].array.items[5] = u.n(8);
    (try u.get(contract, "relocations")).array.items[0].array.items[1] = u.n(5);
    try std.testing.expectError(error.InvalidRelocationBounds, validateObject(a, contract, profile));
}
