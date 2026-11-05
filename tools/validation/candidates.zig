//! Fixed offline population selection: no lowering or execution result is an input.
const std = @import("std");
const u = @import("common.zig");
pub const facts = @import("candidate_facts.zig");
pub const tsv = @import("tsv.zig");
pub const fields = [_][]const u8{ "rank", "source", "function", "instruction_count", "signature_class", "call_class", "global_refs", "runtime_refs", "determinism", "harnessable_reason" };
pub const Classification = struct { signature_class: []const u8, harnessable_reason: []const u8 };
pub const Inventory = std.StringHashMap(Classification);
pub const Modes = [3]facts.Facts;
pub const Row = struct {
    rank: usize = 0,
    source: []const u8 = "../ziglang/src/main.zig",
    function: []const u8,
    instruction_count: i64,
    signature_class: []const u8,
    call_class: []const u8,
    global_refs: i64,
    runtime_refs: i64,
    determinism: []const u8 = "assumed_nondeterministic",
    harnessable_reason: []const u8,

    pub fn value(row: Row, a: std.mem.Allocator) !u.Value {
        var result = u.object(a);
        inline for (@typeInfo(Row).@"struct".field_names) |name| {
            const item = @field(row, name);
            try u.put(a, &result, name, if (@TypeOf(item) == []const u8) u.s(item) else u.n(item));
        }
        return result;
    }
    fn eligibility(row: Row) u16 {
        return if (std.mem.startsWith(u8, row.harnessable_reason, "proven_unharnessable:")) 500 else if (row.global_refs != 0) 200 else if (!std.mem.eql(u8, row.call_class, "leaf")) 100 else 0;
    }
    fn less(_: void, lhs: Row, rhs: Row) bool {
        if (lhs.eligibility() != rhs.eligibility()) return lhs.eligibility() < rhs.eligibility();
        if (lhs.instruction_count != rhs.instruction_count) return lhs.instruction_count < rhs.instruction_count;
        return std.mem.lessThan(u8, lhs.function, rhs.function);
    }
};
pub const Selection = struct { rows: []Row, rejected: []const []const u8 };

pub fn inventory(c: *u.Context, path: []const u8) !Inventory {
    const table = try tsv.parse(c.a, try c.read(path));
    const name = try tsv.column(table, "function");
    const signature = try tsv.column(table, "signature_class");
    const reason = try tsv.column(table, "harnessable_reason");
    var result = Inventory.init(c.a);
    for (table.rows) |row| try result.put(row[name], .{ .signature_class = row[signature], .harnessable_reason = row[reason] });
    return result;
}
pub fn derive(a: std.mem.Allocator, modes: Modes, classes: Inventory) !Selection {
    var rows: std.ArrayList(Row) = .empty;
    var rejected: std.ArrayList([]const u8) = .empty;
    var names = modes[0].functions.keyIterator();
    while (names.next()) |key| {
        const name = key.*;
        if (!modes[1].functions.contains(name) or !modes[2].functions.contains(name)) continue;
        const base = modes[0].functions.get(name).?;
        var stable = std.mem.startsWith(u8, base.signature, "fn (");
        var instructions: i64 = 0;
        var calls: i64 = 0;
        var globals: i64 = 0;
        var runtime: i64 = 0;
        var undefined_result = false;
        for (modes) |mode| {
            const fact = mode.functions.get(name).?;
            stable = stable and std.mem.eql(u8, base.signature, fact.signature) and fact.instructions > 0;
            instructions = @max(instructions, fact.instructions);
            calls = @max(calls, fact.calls);
            globals = @max(globals, fact.global_refs);
            runtime = @max(runtime, fact.runtime_refs);
            undefined_result = undefined_result or fact.undefined_result;
        }
        if (!stable) {
            try rejected.append(a, name);
            continue;
        }
        const classification = classes.get(name) orelse return error.MissingClassification;
        var reason = if (undefined_result) "proven_unharnessable:undefined-result" else classification.harnessable_reason;
        if (!std.mem.startsWith(u8, reason, "proven_unharnessable:")) {
            if (globals != 0) reason = "not_yet_analyzed:global_refs" else if (calls != 0) reason = "not_yet_analyzed:callee_closure";
        }
        try rows.append(a, .{ .function = name, .instruction_count = instructions, .signature_class = classification.signature_class, .call_class = if (calls != 0) "external" else "leaf", .global_refs = globals, .runtime_refs = runtime, .harnessable_reason = reason });
    }
    std.mem.sort(Row, rows.items, {}, Row.less);
    for (rows.items, 1..) |*row, rank| row.rank = rank;
    std.mem.sort([]const u8, rejected.items, {}, facts.lessString);
    return .{ .rows = try rows.toOwnedSlice(a), .rejected = try rejected.toOwnedSlice(a) };
}
pub fn render(a: std.mem.Allocator, rows: []const Row) ![]const u8 {
    var output: std.Io.Writer.Allocating = .init(a);
    try tsv.row(&output.writer, &fields);
    for (rows) |row| {
        var cells: [fields.len][]const u8 = undefined;
        inline for (fields, 0..) |field, i| {
            const value = @field(row, field);
            cells[i] = if (@TypeOf(value) == []const u8) value else try std.fmt.allocPrint(a, "{d}", .{value});
        }
        try tsv.row(&output.writer, &cells);
    }
    return output.toOwnedSlice();
}
pub fn selected(a: std.mem.Allocator, rows: []const Row, modes: Modes) !u.Value {
    var result = u.array(a);
    for (rows[0..@min(rows.len, 100)]) |row| {
        var item = try row.value(a);
        var variants = u.object(a);
        for (modes, u.modes) |mode, name| try u.put(a, &variants, name, try mode.functions.get(row.function).?.value(a));
        try u.put(a, &item, "modes", variants);
        try u.add(&result, item);
    }
    return result;
}
pub fn validateAuthority(c: *u.Context, manifest: u.Value, authority: u.Value, pin: []const u8, inventory_hash: []const u8, authority_hash: []const u8) !void {
    if (!u.json.is(try u.get(manifest, "schema"), facts.manifest_schema) or !u.json.is(try u.get(manifest, "source_pin"), pin) or !u.json.is(try u.get(manifest, "target"), facts.target) or !u.json.is(try u.get(manifest, "releasefast_inventory_sha256"), inventory_hash)) return c.fail("candidate fact manifest identity mismatch", .{});
    try u.json.exact(try u.get(manifest, "inputs"), &u.modes);
    if (!u.json.is(try u.get(manifest, "historical_audit_sha256"), authority_hash) or !u.json.is(try u.get(authority, "source_pin"), pin)) return error.FrozenAuditMismatch;
    for ([_][]const u8{ "candidate_sha256", "rows", "selected_rows" }) |key| if (!u.json.eql(try u.get(manifest, key), try u.get(authority, key))) return error.FrozenAuditMismatch;
    if (try u.json.integer(try u.get(manifest, "rejected_count")) != try facts.rejectionCount(authority)) return error.FrozenAuditMismatch;
}
pub fn checkSelected(c: *u.Context, rows: []const Row) !void {
    if (rows.len < 100) return error.IncompleteCandidatePopulation;
    for ([_][]const u8{ "link.MachO.CodeSignature.Requirements.size", "link.MachO.CodeSignature.Requirements.slotType", "link.MachO.CodeSignature.Signature.size", "link.MachO.CodeSignature.Signature.slotType" }) |required| {
        var found = false;
        for (rows[0..100]) |row| if (std.mem.eql(u8, row.function, required)) {
            found = true;
            break;
        };
        if (!found) return c.fail("fixed population omits an execution cohort member: {s}", .{required});
    }
}
pub fn checkInputAuthority(args: u.Args) !void {
    var count: usize = 0;
    for ([_][]const u8{ "releasefast-air", "releasesafe-air", "releasesmall-air" }) |key| if (args.get(key) != null) {
        count += 1;
    };
    if (args.get("facts-manifest") != null) {
        if (count != 0) return error.ConflictingInputAuthorities;
    } else if (count != 3) return error.CompleteInputAuthorityRequired;
}
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    if (u.contains(argv[1..], "--help")) {
        try c.print("usage: zig run tools/build_real_candidates_v3.zig -- --facts-manifest PATH | --releasefast-air PATH --releasesafe-air PATH --releasesmall-air PATH --releasefast-inventory PATH --out PATH --audit PATH [--previous PATH]\n", .{});
        return;
    }
    const args = u.Args.parse(c.a, argv[1..], &.{ "facts-manifest", "releasefast-air", "releasesafe-air", "releasesmall-air", "releasefast-inventory", "out", "audit", "previous" }, &.{}) catch |err| {
        try c.print("invalid arguments: {s}\n", .{@errorName(err)});
        std.process.exit(2);
    };
    checkInputAuthority(args) catch |err| {
        try c.print("{s}\n", .{if (err == error.ConflictingInputAuthorities) "choose either the fact manifest or all three raw AIR inputs" else "all three raw AIR inputs or a fact manifest are required"});
        std.process.exit(2);
    };
    build(&c, args) catch |err| {
        try c.print("candidate derivation failed: {s}\n", .{c.diagnostic orelse @errorName(err)});
        std.process.exit(1);
    };
}
pub fn build(c: *u.Context, args: u.Args) !void {
    const pin = u.trim(try c.read(try c.join(&.{"docs/evidence/ziglang_pin.txt"})));
    const inventory_name = try args.require("releasefast-inventory");
    const inventory_path = try c.join(&.{inventory_name});
    const inventory_hash = try c.digest(inventory_path);
    const authority_path = try c.join(&.{"docs/evidence/real_candidates_release_v3_migration.json"});
    const manifest = if (args.get("facts-manifest")) |path| try c.load(try c.join(&.{path})) else null;
    const authority = if (manifest != null) try c.load(authority_path) else null;
    if (manifest) |value| try validateAuthority(c, value, authority.?, pin, inventory_hash, try c.digest(authority_path));
    var modes: Modes = undefined;
    var inputs = u.object(c.a);
    for (u.modes, [_][]const u8{ "releasefast-air", "releasesafe-air", "releasesmall-air" }, 0..) |mode, key, i| {
        var input = u.object(c.a);
        if (manifest) |value| {
            const entry = try u.get(try u.get(value, "inputs"), mode);
            const parent = try u.str(entry, "descriptor_sha256");
            if (!u.json.is(try u.get(try u.get(try u.get(authority.?, "inputs"), mode), "sha256"), parent)) return error.RawParentMismatch;
            const path = try u.str(entry, "path");
            modes[i] = try facts.load(c, try c.join(&.{path}), mode, pin, try u.str(entry, "sha256"), parent);
            if (try u.json.integer(try u.get(entry, "unambiguous_functions")) != modes[i].functions.count() or !u.json.eql(try u.get(entry, "ambiguous_symbols_excluded"), try u.strings(c.a, modes[i].duplicates))) return error.ManifestPopulationMismatch;
            for ([_][]const u8{ "path", "sha256", "descriptor_sha256" }) |field| try u.put(c.a, &input, field, try u.get(entry, field));
            try u.put(c.a, &input, "format", u.s(facts.schema));
        } else {
            const path = try args.require(key);
            modes[i] = try facts.scan(c, try c.join(&.{path}), mode, pin);
            try u.put(c.a, &input, "path", u.s(path));
            try u.put(c.a, &input, "sha256", u.s(modes[i].descriptor_sha256));
        }
        try u.put(c.a, &input, "unambiguous_functions", u.n(modes[i].functions.count()));
        try u.put(c.a, &input, "ambiguous_symbols_excluded", try u.strings(c.a, modes[i].duplicates));
        try u.put(c.a, &inputs, mode, input);
    }
    const classes = try inventory(c, inventory_path);
    var names = modes[0].functions.keyIterator();
    while (names.next()) |name| if (!classes.contains(name.*)) return error.InventoryCoverageMismatch;
    const selection = try derive(c.a, modes, classes);
    try checkSelected(c, selection.rows);
    const selected_facts = try selected(c.a, selection.rows, modes);
    const rendered = try render(c.a, selection.rows);
    const digest = try u.digestBytes(c.a, rendered);
    if (manifest) |value| {
        if (!u.json.eql(selected_facts, try u.get(authority.?, "selected")) or selection.rejected.len != try facts.rejectionCount(authority.?) or !u.json.is(try u.get(value, "rejected_names_sha256"), try facts.rejectionDigest(c.a, selection.rejected))) return error.FrozenAuditDecisionChanged;
        if (!u.json.is(try u.get(value, "candidate_sha256"), digest)) return error.FrozenCandidateTableChanged;
    }
    const old = try tsv.parse(c.a, try c.read(try c.join(&.{args.get("previous") orelse "docs/evidence/real_candidates_release_v2.tsv"})));
    const name_col = try tsv.column(old, "function");
    const rank_col = try tsv.column(old, "rank");
    var old_names = std.StringHashMap(void).init(c.a);
    var new_names = std.StringHashMap(void).init(c.a);
    var retained: std.ArrayList([]const u8) = .empty;
    var retired = u.array(c.a);
    var replacements = u.array(c.a);
    for (selection.rows[0..100]) |row| try new_names.put(row.function, {});
    for (old.rows[0..@min(100, old.rows.len)]) |row| {
        const name = row[name_col];
        try old_names.put(name, {});
        if (new_names.contains(name)) {
            try retained.append(c.a, name);
            continue;
        }
        var missing = u.array(c.a);
        for (modes, u.modes) |mode, label| if (!mode.functions.contains(name)) {
            try u.add(&missing, u.s(label));
        };
        var item = u.object(c.a);
        try u.put(c.a, &item, "function", u.s(name));
        try u.put(c.a, &item, "old_rank", u.n(try std.fmt.parseInt(i64, row[rank_col], 10)));
        try u.put(c.a, &item, "reason", u.s(if (missing.array.items.len != 0) "absent from current runtime AIR" else "current signature/body facts changed deterministic rank"));
        try u.put(c.a, &item, "missing_modes", missing);
        try u.add(&retired, item);
    }
    std.mem.sort([]const u8, retained.items, {}, facts.lessString);
    for (selection.rows[0..100]) |row| if (!old_names.contains(row.function)) {
        try u.add(&replacements, try row.value(c.a));
    };
    var audit = u.object(c.a);
    try u.put(c.a, &audit, "schema", u.s("real-candidate-migration-v3"));
    try u.put(c.a, &audit, "source_pin", u.s(pin));
    try u.put(c.a, &audit, "selector_version", u.s("real-candidate-selector-v3"));
    try u.put(c.a, &audit, "criteria", u.s("Present unambiguously in all release modes with an identical signature and complete nonempty typed bodies. Preserve the fresh static typed-opcode/type inventory classification; undefined return results have no defined-result oracle and rank as unharnessable. Order by eligibility, maximum memory/call effects, maximum instruction count, then symbol. No lowering or codegen outcome is an input."));
    var inventory_record = u.object(c.a);
    try u.put(c.a, &inventory_record, "path", u.s(inventory_name));
    try u.put(c.a, &inventory_record, "sha256", u.s(inventory_hash));
    try u.put(c.a, &audit, "releasefast_inventory", inventory_record);
    try u.put(c.a, &audit, "inputs", inputs);
    try u.put(c.a, &audit, "candidate_sha256", u.s(digest));
    try u.put(c.a, &audit, "rows", u.n(selection.rows.len));
    try u.put(c.a, &audit, "selected_rows", u.n(100));
    try u.put(c.a, &audit, "retained_previous_prefix", try u.strings(c.a, retained.items));
    try u.put(c.a, &audit, "retired_previous_prefix", retired);
    try u.put(c.a, &audit, "replacement_prefix", replacements);
    try u.put(c.a, &audit, "unstable_signatures_or_empty_bodies", try u.strings(c.a, selection.rejected));
    try u.put(c.a, &audit, "selected", selected_facts);
    const out = try c.ownedPath(try args.require("out"));
    const audit_path = try c.ownedPath(try args.require("audit"));
    if (std.mem.eql(u8, out, audit_path)) return error.ConflictingOutputPaths;
    try c.mkdir(std.fs.path.dirname(out).?);
    try c.mkdir(std.fs.path.dirname(audit_path).?);
    try c.write(out, rendered);
    try c.writeJson(audit_path, audit);
    try c.print("{s}\n", .{try std.json.Stringify.valueAlloc(c.a, .{ .rows = selection.rows.len, .selected = @as(usize, 100), .retained = retained.items.len, .sha256 = digest }, .{})});
}
