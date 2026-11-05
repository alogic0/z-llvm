//! Freeze authenticated semantic inputs without copying or deleting raw AIR.
const std = @import("std");
const u = @import("common.zig");
const candidates = @import("candidates.zig");
const facts = candidates.facts;
const provenance = @import("provenance.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    if (u.contains(argv[1..], "--help")) {
        try c.print("usage: zig run tools/freeze_real_candidate_facts.zig -- --output-root NEW_DIR --manifest NEW_FILE --proof NEW_FILE [--audit PATH] [--candidates PATH]\n", .{});
        return;
    }
    const args = try u.Args.parse(c.a, argv[1..], &.{ "audit", "candidates", "output-root", "manifest", "proof" }, &.{});
    freeze(&c, args) catch |err| {
        try c.print("fact freeze failed: {s}\n", .{c.diagnostic orelse @errorName(err)});
        std.process.exit(1);
    };
}
pub fn freeze(c: *u.Context, args: u.Args) !void {
    const output = try c.ownedPath(try args.require("output-root"));
    const manifest_path = try c.ownedPath(try args.require("manifest"));
    const proof_path = try c.ownedPath(try args.require("proof"));
    for ([_][]const u8{ output, manifest_path, proof_path }) |path| if (u.exists(c.io, path)) return error.EvidenceAlreadyExists;
    if (std.mem.eql(u8, manifest_path, proof_path) or std.mem.eql(u8, output, manifest_path) or std.mem.eql(u8, output, proof_path)) return error.ConflictingOutputPaths;
    const audit_path = try c.join(&.{args.get("audit") orelse "docs/evidence/real_candidates_release_v3_migration.json"});
    const candidate_path = try c.join(&.{args.get("candidates") orelse "docs/evidence/real_candidates_release_v3.tsv"});
    const audit = try c.load(audit_path);
    const pin = u.trim(try c.read(try c.join(&.{"docs/evidence/ziglang_pin.txt"})));
    if (!u.json.is(try u.get(audit, "source_pin"), pin) or !u.json.is(try u.get(audit, "schema"), "real-candidate-migration-v3")) return error.HistoricalAuditIdentityMismatch;
    const inventory_record = try u.get(audit, "releasefast_inventory");
    const inventory_path = try c.join(&.{try u.str(inventory_record, "path")});
    if (!u.json.is(try u.get(inventory_record, "sha256"), try c.digest(inventory_path))) return error.HistoricalInventoryChanged;
    const classes = try candidates.inventory(c, inventory_path);
    const tool_provenance = try provenance.tools(c);
    _ = try c.newOutput(output);
    var raw_modes: candidates.Modes = undefined;
    var compact_modes: candidates.Modes = undefined;
    var entries = u.object(c.a);
    var originals = u.array(c.a);
    var raw_bytes: u64 = 0;
    var fact_bytes: u64 = 0;
    for (u.modes, 0..) |mode, i| {
        const parent = try u.get(try u.get(audit, "inputs"), mode);
        const path = try c.join(&.{try u.str(parent, "path")});
        const before = try std.Io.Dir.cwd().statFile(c.io, path, .{});
        const raw = try facts.scan(c, path, mode, pin);
        if (!u.json.is(try u.get(parent, "sha256"), raw.descriptor_sha256) or try u.json.integer(try u.get(parent, "unambiguous_functions")) != raw.functions.count() or !u.json.eql(try u.get(parent, "ambiguous_symbols_excluded"), try u.strings(c.a, raw.duplicates))) return error.HistoricalRawFactsChanged;
        const after = try std.Io.Dir.cwd().statFile(c.io, path, .{});
        if (before.inode != after.inode or before.size != after.size or before.mtime.nanoseconds != after.mtime.nanoseconds) return error.DescriptorChangedDuringScan;
        const fact_path = try c.join(&.{ output, try c.fmt("{s}.facts.json", .{mode}) });
        const hash = try facts.write(c, fact_path, mode, pin, raw);
        const compact = try facts.load(c, fact_path, mode, pin, hash, raw.descriptor_sha256);
        if (compact.functions.count() != raw.functions.count() or !std.mem.eql(u8, try facts.rejectionDigest(c.a, compact.duplicates), try facts.rejectionDigest(c.a, raw.duplicates))) return error.FactRoundtripMismatch;
        var iterator = raw.functions.iterator();
        while (iterator.next()) |item| {
            const reloaded = compact.functions.get(item.key_ptr.*) orelse return error.FactRoundtripMismatch;
            if (!u.json.eql(try item.value_ptr.value(c.a), try reloaded.value(c.a))) return error.FactRoundtripMismatch;
        }
        raw_modes[i] = raw;
        compact_modes[i] = compact;
        const size = (try std.Io.Dir.cwd().statFile(c.io, fact_path, .{})).size;
        var entry = u.object(c.a);
        try u.put(c.a, &entry, "path", u.s(try provenance.relative(c, fact_path)));
        try u.put(c.a, &entry, "sha256", u.s(hash));
        try u.put(c.a, &entry, "bytes", u.n(size));
        try u.put(c.a, &entry, "descriptor_sha256", u.s(raw.descriptor_sha256));
        // Read only the bounded header; raw descriptors can be several GiB.
        const input = try std.Io.Dir.cwd().openFile(c.io, path, .{});
        defer input.close(c.io);
        var buffer: [4096]u8 = undefined;
        var reader = input.readerStreaming(c.io, &buffer);
        var descriptor_target: ?[]const u8 = null;
        for (0..10) |_| {
            const line = try reader.interface.takeDelimiterExclusive('\n');
            if (std.mem.startsWith(u8, line, "target=")) descriptor_target = try c.a.dupe(u8, line[7..]);
            reader.interface.toss(1);
        }
        try u.put(c.a, &entry, "descriptor_target", u.s(descriptor_target orelse return error.MissingDescriptorTarget));
        try u.put(c.a, &entry, "unambiguous_functions", u.n(raw.functions.count()));
        try u.put(c.a, &entry, "ambiguous_symbols_excluded", try u.strings(c.a, raw.duplicates));
        try u.put(c.a, &entries, mode, entry);
        const metadata_path = try c.fmt("{s}.meta", .{path[0 .. path.len - std.fs.path.extension(path).len]});
        var original = u.object(c.a);
        try u.put(c.a, &original, "path", try u.get(parent, "path"));
        try u.put(c.a, &original, "sha256", u.s(raw.descriptor_sha256));
        try u.put(c.a, &original, "inode", try u.big(c.a, before.inode));
        try u.put(c.a, &original, "links", u.n(before.nlink));
        try u.put(c.a, &original, "bytes", u.n(before.size));
        // stat(1) exposes allocation/device fields absent from the portable Zig stat.
        var stat_fields = std.mem.tokenizeAny(u8, try c.capture(&.{ "stat", "--format=%d %b", "--", path }), " \n");
        try u.put(c.a, &original, "device", u.n(try std.fmt.parseInt(i64, stat_fields.next() orelse return error.InvalidStat, 10)));
        try u.put(c.a, &original, "allocated_bytes", u.n(try std.fmt.parseInt(i64, stat_fields.next() orelse return error.InvalidStat, 10) * 512));
        try u.put(c.a, &original, "metadata_path", u.s(try provenance.relative(c, metadata_path)));
        try u.put(c.a, &original, "metadata_sha256", u.s(try c.digest(metadata_path)));
        try u.add(&originals, original);
        raw_bytes += before.size;
        fact_bytes += size;
        try c.print("{s}\n", .{try std.json.Stringify.valueAlloc(c.a, .{ .mode = mode, .functions = raw.functions.count(), .raw_bytes = before.size, .fact_bytes = size, .every_fact_equal = true }, .{})});
    }
    const raw_selection = try candidates.derive(c.a, raw_modes, classes);
    const compact_selection = try candidates.derive(c.a, compact_modes, classes);
    const rendered = try candidates.render(c.a, compact_selection.rows);
    if (!std.mem.eql(u8, rendered, try candidates.render(c.a, raw_selection.rows)) or !std.mem.eql(u8, try facts.rejectionDigest(c.a, raw_selection.rejected), try facts.rejectionDigest(c.a, compact_selection.rejected)) or !std.mem.eql(u8, rendered, try c.read(candidate_path)) or !u.json.is(try u.get(audit, "candidate_sha256"), try u.digestBytes(c.a, rendered)) or try u.json.integer(try u.get(audit, "rows")) != compact_selection.rows.len) return error.FactReplayPopulationChanged;
    if (!u.json.eql(try candidates.selected(c.a, compact_selection.rows, compact_modes), try u.get(audit, "selected")) or compact_selection.rejected.len != try facts.rejectionCount(audit)) return error.HistoricalAuditDecisionChanged;
    try candidates.checkSelected(c, compact_selection.rows);
    try provenance.verifyTools(c, tool_provenance);
    var proof = u.object(c.a);
    try u.put(c.a, &proof, "schema", u.n(1));
    try u.put(c.a, &proof, "created_utc", u.s(u.trim(try c.capture(&.{ "date", "-u", "+%Y-%m-%dT%H:%M:%SZ" }))));
    try u.put(c.a, &proof, "source_head", u.s(u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" }))));
    try u.put(c.a, &proof, "tool_sha256", try u.get(tool_provenance, "source_sha256"));
    try u.put(c.a, &proof, "tool_provenance", tool_provenance);
    try u.put(c.a, &proof, "historical_audit", u.s(try provenance.relative(c, audit_path)));
    try u.put(c.a, &proof, "historical_audit_sha256", u.s(try c.digest(audit_path)));
    try u.put(c.a, &proof, "static_inventory", inventory_record);
    try u.put(c.a, &proof, "originals", originals);
    try u.put(c.a, &proof, "facts", entries);
    try u.put(c.a, &proof, "candidate_sha256", try u.get(audit, "candidate_sha256"));
    try u.put(c.a, &proof, "rows", u.n(compact_selection.rows.len));
    try u.put(c.a, &proof, "selected_rows", u.n(100));
    for ([_][]const u8{ "all_function_facts_equal", "entire_candidate_table_byte_identical", "every_selected_audit_field_equal", "all_rejection_decisions_equal" }) |key| try u.put(c.a, &proof, key, u.b(true));
    try u.put(c.a, &proof, "historical_rejection_count", u.n(try facts.rejectionCount(audit)));
    try u.put(c.a, &proof, "raw_and_fact_rejected_names", try u.strings(c.a, compact_selection.rejected));
    const rejected_hash = try facts.rejectionDigest(c.a, compact_selection.rejected);
    try u.put(c.a, &proof, "rejected_names_sha256", u.s(rejected_hash));
    try u.put(c.a, &proof, "raw_bytes", u.n(raw_bytes));
    try u.put(c.a, &proof, "fact_bytes", u.n(fact_bytes));
    try u.put(c.a, &proof, "archives_created", u.n(0));
    try c.mkdir(std.fs.path.dirname(proof_path).?);
    try c.writeJson(proof_path, proof);
    var manifest = u.object(c.a);
    try u.put(c.a, &manifest, "schema", u.s(facts.manifest_schema));
    try u.put(c.a, &manifest, "source_pin", u.s(pin));
    try u.put(c.a, &manifest, "target", u.s(facts.target));
    for ([_][]const u8{ "candidate_sha256", "rows", "selected_rows", "rejected_names_sha256", "historical_audit_sha256", "archives_created" }) |key| try u.put(c.a, &manifest, key, try u.get(proof, key));
    try u.put(c.a, &manifest, "rejected_count", u.n(compact_selection.rejected.len));
    try u.put(c.a, &manifest, "releasefast_inventory_sha256", try u.get(inventory_record, "sha256"));
    try u.put(c.a, &manifest, "inputs", entries);
    var verification = u.object(c.a);
    try u.put(c.a, &verification, "path", u.s(try provenance.relative(c, proof_path)));
    try u.put(c.a, &verification, "sha256", u.s(try c.digest(proof_path)));
    try u.put(c.a, &manifest, "verification", verification);
    try u.put(c.a, &manifest, "scope", u.s("Exact semantic inputs to offline v3 membership derivation, including typed-body hashes; no raw bodies or executable data. Current production AIR remains separate."));
    try c.mkdir(std.fs.path.dirname(manifest_path).?);
    try c.writeJson(manifest_path, manifest);
    try c.print("fact freeze verified: rows={d} selected=100 raw_bytes={d} fact_bytes={d} raw_inputs_deleted=false\n", .{ compact_selection.rows.len, raw_bytes, fact_bytes });
}
