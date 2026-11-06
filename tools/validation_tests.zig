const std = @import("std");
const u = @import("validation/common.zig");
const Runner = @import("validation/runner.zig").Runner;
const elf = @import("validation/object_contract.zig");

const candidates = @import("validation/candidates.zig");
const facts = candidates.facts;
const baseline = @import("validation/baseline.zig");
const canaries = @import("validation/native_canaries.zig");
const freeze = @import("validation/freeze_facts.zig");
const provenance = @import("validation/provenance.zig");
const expect = std.testing.expect;
const equal = std.testing.expectEqualStrings;
const io = std.testing.io;
const zero_hash = &@as([64]u8, @splat('0'));
test "command logs preserve independent positional writers and final error trace" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const config = @import("test_options");
    var runner = Runner.init(&f.c, f.directory);
    const log_fixture = try f.c.join(&.{config.log_fixture});
    const direct = try runner.run(&.{log_fixture}, try f.path("direct"), &f.c.env, .{});
    try std.testing.expectEqual(@as(i64, 1), direct.code);
    try equal("before\x00out\nafter\n", try f.c.read(try f.path("direct.stdout")));
    const direct_err = try f.c.read(try f.path("direct.stderr"));
    try expect(std.mem.startsWith(u8, direct_err, "diagnostic\nerror: IntentionalLogFailure\n"));
    const merged = try runner.run(&.{ try f.c.join(&.{config.checked_runner}), "--output-root", f.directory, "merged", "--", log_fixture }, try f.path("checked"), &f.c.env, .{});
    try std.testing.expectEqual(@as(i64, 1), merged.code);
    const log = try f.c.read(try f.path("merged.log"));
    try expect(std.mem.startsWith(u8, log, "before\x00out\ndiagnostic\nafter\nerror: IntentionalLogFailure\n"));
}
test "real program JSON summary preserves the prior success and failure log contract" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const success = try u.toValue(f.c.a, .{ .local_executions = 3, .matched_program_modes = 3, .reference_executions = 3, .status = "passed" });
    try equal("{\"local_executions\": 3, \"matched_program_modes\": 3, \"reference_executions\": 3, \"status\": \"passed\"}", try @import("validation/program.zig").summaryJson(&f.c, success));
    const blocked = try u.toValue(f.c.a, .{ .local_executions = 0, .matched_program_modes = 0, .reference_executions = 1, .status = "blocked" });
    try equal("{\"local_executions\": 0, \"matched_program_modes\": 0, \"reference_executions\": 1, \"status\": \"blocked\"}", try @import("validation/program.zig").summaryJson(&f.c, blocked));
}
test "program runtime linking requires an explicit known manifest driver without a conflicting linker" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const program = @import("validation/program.zig");
    var args: u.Args = .{ .values = std.StringHashMap([]const u8).init(f.c.a) };
    var manifest = u.object(f.c.a);
    try expect(try program.linkDriver(args, manifest) == .system);
    try u.put(f.c.a, &manifest, "link_driver", u.s("zig-compiler-rt"));
    try expect(try program.linkDriver(args, manifest) == .zig_compiler_rt);
    try args.values.put("linker", "cc");
    try std.testing.expectError(error.ConflictingProgramLinker, program.linkDriver(args, manifest));
    try u.put(f.c.a, &manifest, "link_driver", u.s("system"));
    try expect(try program.linkDriver(args, manifest) == .system);
    try u.put(f.c.a, &manifest, "link_driver", u.s("unknown"));
    try std.testing.expectError(error.UnsupportedProgramLinkDriver, program.linkDriver(args, manifest));
}
test "command wrapper preserves binary log, durable failure, cancellation and owned child cleanup" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const config = @import("test_options");
    const probe = try f.c.join(&.{config.checked_runner});
    var runner = Runner.init(&f.c, f.directory);
    const result = try runner.run(&.{ probe, "--output-root", f.directory, "nonzero", "--", "/bin/sh", "-c", "printf 'a\\000b'; printf error >&2; exit 7" }, try f.path("probe"), &f.c.env, .{});
    try std.testing.expectEqual(@as(i64, 7), result.code);
    try equal("a\x00berror", try f.c.read(try f.path("nonzero.log")));
    try equal("finished", try u.str(try f.c.load(try f.path("nonzero.json")), "status"));
    var broken_env = try f.c.cleanEnvironment();
    try broken_env.put("PATH", f.directory);
    try std.testing.expectEqual(@as(i64, 2), (try runner.run(&.{ probe, "--output-root", f.directory, "telemetry-failed", "--", "/bin/true" }, try f.path("broken"), &broken_env, .{})).code);
    try equal("failed", try u.str(try f.c.load(try f.path("telemetry-failed.json")), "status"));
    var child = try u.process.Child.spawn(f.c.gpa, io, .{ .argv = &.{ probe, "--output-root", f.directory, "canceled", "--", "/bin/sh", "-c", "trap '' TERM; sleep 30" }, .cwd = .{ .path = f.c.root }, .environ_map = &f.c.env });
    defer child.deinit();
    const record_path = try f.path("canceled.json");
    const deadline = std.Io.Clock.awake.now(io).addDuration(.fromMilliseconds(5000));
    while (!u.exists(io, record_path)) {
        if (std.Io.Clock.awake.now(io).nanoseconds > deadline.nanoseconds) return error.CommandDidNotStart;
        try io.sleep(.fromMilliseconds(10), .awake);
    }
    const running = try f.c.load(record_path);
    const command_pid = try u.json.integer(try u.get(running, "pid"));
    try std.testing.expectEqual(std.os.linux.E.SUCCESS, std.os.linux.errno(std.os.linux.kill(child.pid.?, .TERM)));
    try std.testing.expectEqual(@as(i64, 143), u.returnCode(try child.waitUntil(std.Io.Clock.awake.now(io).addDuration(.fromMilliseconds(6000)), null)));
    const final = try f.c.load(record_path);
    try equal("canceled", try u.str(final, "outcome"));
    try std.testing.expectEqual(@as(i64, 143), try u.json.integer(try u.get(final, "returncode")));
    try std.testing.expectEqual(std.os.linux.E.SRCH, std.os.linux.errno(std.os.linux.kill(@intCast(command_pid), @fromBackingInt(@intCast(0)))));
}
test "AIR telemetry records raw and cache inode allocation without following unrelated directories" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const raw_root = try f.path("raw");
    const cache_root = try f.path("cache");
    try f.c.mkdir(try f.c.join(&.{ raw_root, "ReleaseFast/work-test" }));
    try f.c.mkdir(try f.c.join(&.{ cache_root, "ReleaseFast/export" }));
    try f.c.write(try f.c.join(&.{ raw_root, "ReleaseFast/work-test/compiler.air" }), "raw");
    try f.c.write(try f.c.join(&.{ cache_root, "ReleaseFast/export/probe.air" }), "cache");
    const sample = try @import("validation/telemetry.zig").airFiles(&f.c, raw_root, cache_root);
    try std.testing.expectEqual(@as(usize, 2), sample.array.items.len);
    try equal("raw", try u.str(sample.array.items[0], "role"));
    try std.testing.expectEqual(@as(i64, 3), try u.json.integer(try u.get(sample.array.items[0], "bytes")));
    try expect(try u.json.integer(try u.get(sample.array.items[0], "allocated_bytes")) > 0);
}
test "mode stability, defined results and effect maxima control deterministic rank" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const base: facts.Fact = .{ .signature = "fn () u32", .instructions = 2, .calls = 0, .global_refs = 0, .runtime_refs = 0, .undefined_result = false, .typed_sha256 = zero_hash };
    var modes: candidates.Modes = undefined;
    var classes = candidates.Inventory.init(f.c.a);
    for (&modes) |*mode| {
        mode.* = .{ .functions = std.StringHashMap(facts.Fact).init(f.c.a), .duplicates = &.{}, .descriptor_sha256 = zero_hash };
        for ([_][]const u8{ "defined", "undefined", "unstable", "global", "calls" }) |name| {
            try mode.functions.put(name, base);
            try classes.put(name, .{ .signature_class = "internal-callable", .harnessable_reason = "harnessable:leaf_no_refs_supported" });
        }
        mode.functions.getPtr("undefined").?.undefined_result = true;
        mode.functions.getPtr("undefined").?.instructions = 1;
    }
    modes[1].functions.getPtr("unstable").?.signature = "fn () u64";
    modes[2].functions.getPtr("global").?.global_refs = 3;
    modes[1].functions.getPtr("calls").?.calls = 1;
    const selection = try candidates.derive(f.c.a, modes, classes);
    try equal("unstable", selection.rejected[0]);
    for (selection.rows, [_][]const u8{ "defined", "calls", "global", "undefined" }) |row, name| try equal(name, row.function);
    try equal("proven_unharnessable:undefined-result", selection.rows[3].harnessable_reason);
    try std.testing.expectEqual(@as(i64, 3), selection.rows[2].global_refs);
    const first = try candidates.render(f.c.a, selection.rows);
    var reversed = std.StringHashMap(facts.Fact).init(f.c.a);
    for ([_][]const u8{ "calls", "global", "unstable", "undefined", "defined" }) |name| try reversed.put(name, modes[0].functions.get(name).?);
    modes[0].functions = reversed;
    try equal(first, try candidates.render(f.c.a, (try candidates.derive(f.c.a, modes, classes)).rows));
}
test "input authority, rejection digest and frozen manifest binding are checked" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    var args: u.Args = .{ .values = std.StringHashMap([]const u8).init(f.c.a) };
    try std.testing.expectError(error.CompleteInputAuthorityRequired, candidates.checkInputAuthority(args));
    try args.values.put("facts-manifest", "unused");
    try candidates.checkInputAuthority(args);
    try args.values.put("releasefast-air", "unused");
    try std.testing.expectError(error.ConflictingInputAuthorities, candidates.checkInputAuthority(args));
    const names = [_][]const u8{ "empty", "unstable" };
    try std.testing.expectEqual(@as(i64, 2), try facts.rejectionCount(try u.toValue(f.c.a, .{ .unstable_signatures_or_empty_bodies_count = 2 })));
    try std.testing.expectEqual(@as(i64, 2), try facts.rejectionCount(try u.toValue(f.c.a, .{ .unstable_signatures_or_empty_bodies = names })));
    try expect(!std.mem.eql(u8, try facts.rejectionDigest(f.c.a, &names), try facts.rejectionDigest(f.c.a, &.{ "other", "unstable" })));
    const authority_path = try f.c.join(&.{"docs/evidence/real_candidates_release_v3_migration.json"});
    const authority = try f.c.load(authority_path);
    var manifest = try f.c.load(try f.c.join(&.{"docs/evidence/real_candidates_release_v3_facts_manifest.json"}));
    const pin = try u.str(authority, "source_pin");
    const inventory_hash = try u.str(manifest, "releasefast_inventory_sha256");
    try candidates.validateAuthority(&f.c, manifest, authority, pin, inventory_hash, try f.c.digest(authority_path));
    try u.put(f.c.a, &manifest, "rows", u.n(1));
    try std.testing.expectError(error.FrozenAuditMismatch, candidates.validateAuthority(&f.c, manifest, authority, pin, inventory_hash, try f.c.digest(authority_path)));
}
test "output policy rejects existing paths and symlink escapes" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    try std.testing.expectError(error.PathAlreadyExists, f.c.newOutput(f.directory));
    try std.testing.expectError(error.ValidationFailed, f.c.ownedPath("/tmp/outside-project-validation"));
    _ = try f.c.capture(&.{ "ln", "-s", "/tmp", try f.path("escape") });
    try std.testing.expectError(error.ValidationFailed, f.c.ownedPath(try f.path("escape/new")));
    try equal(try f.path("new/evidence"), try f.c.ownedPath(try f.path("new/evidence")));
}
test "ownership rejects missing, duplicate, foreign and fallback functions" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    try canaries.owners(&f.c, "row_identity\tselection_owner\nf\tcomposed_cfg\n", &.{"f"});
    for ([_][]const u8{ "", "f\tcomposed_cfg\nf\tcomposed_cfg\n", "g\tcomposed_cfg\n", "f\tlegacy\n" }) |body| try std.testing.expectError(error.CanaryEscapedComposedLowering, canaries.owners(&f.c, try f.c.fmt("row_identity\tselection_owner\n{s}", .{body}), &.{"f"}));
    const names = try baseline.definedNames(f.c.a, "define i32 @plain() {\n}\ndefine i32 @\"quoted.name\"() {\n}\n");
    try expect(u.contains(names, "plain") and u.contains(names, "quoted.name"));
}
test "benchmark median and median absolute deviation" {
    const s = try baseline.stats(std.testing.allocator, &.{ 1, 5, 3, 100, 2 });
    try std.testing.expectEqual(@as(f64, 3), s.median);
    try std.testing.expectEqual(@as(f64, 2), s.mad);
    const even = try baseline.stats(std.testing.allocator, &.{ 1, 2, 4, 7 });
    try std.testing.expectEqual(@as(f64, 3), even.median);
    try std.testing.expectEqual(@as(f64, 1.5), even.mad);
    try std.testing.expectError(error.EmptySamples, baseline.stats(std.testing.allocator, &.{}));
}
test "freezer replays raw population and preserves original descriptors" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const pin = u.trim(try f.c.read(try f.c.join(&.{"docs/evidence/ziglang_pin.txt"})));
    var classes = candidates.Inventory.init(f.c.a);
    var bodies: std.ArrayList([]const u8) = .empty;
    var table: std.Io.Writer.Allocating = .init(f.c.a);
    try table.writer.writeAll("function\tsignature_class\tharnessable_reason\n");
    for (0..101) |i| {
        const name = if (i < 4) ([_][]const u8{ "link.MachO.CodeSignature.Requirements.size", "link.MachO.CodeSignature.Requirements.slotType", "link.MachO.CodeSignature.Signature.size", "link.MachO.CodeSignature.Signature.slotType" })[i] else try f.c.fmt("z-function-{d:0>3}", .{i});
        try bodies.append(f.c.a, try function(&f.c, name, 1));
        try classes.put(name, .{ .signature_class = "internal-callable", .harnessable_reason = "harnessable:leaf_no_refs_supported" });
        try table.writer.print("{s}\tinternal-callable\tharnessable:leaf_no_refs_supported\n", .{name});
    }
    const inventory_path = try f.write("inventory.tsv", table.written());
    var modes: candidates.Modes = undefined;
    var inputs = u.object(f.c.a);
    for (u.modes, 0..) |mode, i| {
        const path = try raw(&f, mode, pin, bodies.items);
        modes[i] = try facts.scan(&f.c, path, mode, pin);
        try u.put(f.c.a, &inputs, mode, try u.toValue(f.c.a, .{ .path = try provenance.relative(&f.c, path), .sha256 = modes[i].descriptor_sha256, .unambiguous_functions = modes[i].functions.count(), .ambiguous_symbols_excluded = modes[i].duplicates }));
    }
    const selection = try candidates.derive(f.c.a, modes, classes);
    const rendered = try candidates.render(f.c.a, selection.rows);
    const candidate_path = try f.write("candidates.tsv", rendered);
    const audit_path = try f.path("audit.json");
    try f.c.writeJson(audit_path, .{ .schema = "real-candidate-migration-v3", .source_pin = pin, .inputs = inputs, .releasefast_inventory = .{ .path = try provenance.relative(&f.c, inventory_path), .sha256 = try f.c.digest(inventory_path) }, .rows = selection.rows.len, .candidate_sha256 = try u.digestBytes(f.c.a, rendered), .selected = try candidates.selected(f.c.a, selection.rows, modes), .unstable_signatures_or_empty_bodies = selection.rejected });
    var args: u.Args = .{ .values = std.StringHashMap([]const u8).init(f.c.a) };
    for ([_][]const u8{ "audit", "candidates", "output-root", "manifest", "proof" }, [_][]const u8{ audit_path, candidate_path, try f.path("facts"), try f.path("manifest.json"), try f.path("proof.json") }) |key, val| try args.values.put(key, val);
    try freeze.freeze(&f.c, args);
    const proof = try f.c.load(try f.path("proof.json"));
    try expect((try u.get(proof, "all_function_facts_equal")).bool and (try u.get(proof, "every_selected_audit_field_equal")).bool);
    for (u.modes, modes) |mode, before| try equal(before.descriptor_sha256, try f.c.digest(try f.path(try f.c.fmt("{s}.air", .{mode}))));
    try std.testing.expectError(error.EvidenceAlreadyExists, freeze.freeze(&f.c, args));
}
const Fixture = struct {
    arena: std.heap.ArenaAllocator,
    temporary: std.testing.TmpDir,
    c: u.Context,
    directory: []const u8,
    fn init(f: *Fixture) !void {
        f.arena = .init(std.testing.allocator);
        const a = f.arena.allocator();
        f.temporary = std.testing.tmpDir(.{});
        f.directory = try f.temporary.dir.realPathFileAlloc(io, ".", a);
        f.c = .{ .a = a, .gpa = std.testing.allocator, .io = io, .root = try std.Io.Dir.cwd().realPathFileAlloc(io, ".", a), .env = try std.testing.environ.createMap(a), .quiet = true };
    }
    fn deinit(f: *Fixture) void {
        f.temporary.cleanup();
        f.arena.deinit();
    }
    fn path(f: *Fixture, name: []const u8) ![]const u8 {
        return f.c.join(&.{ f.directory, name });
    }
    fn write(f: *Fixture, name: []const u8, bytes: []const u8) ![]const u8 {
        const destination = try f.path(name);
        try f.c.write(destination, bytes);
        return destination;
    }
};
test "quoted TSV preserves tabs, quotes, Unicode and multiline fields" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const text = "name\treason\n\"a\tb\"\t\"say \"\"yes\"\"\nnext\"\nλ\tx\n";
    const table = try candidates.tsv.parse(f.c.a, text);
    try equal("a\tb", table.rows[0][0]);
    try equal("say \"yes\"\nnext", table.rows[0][1]);
    var out: std.Io.Writer.Allocating = .init(f.c.a);
    try candidates.tsv.row(&out.writer, table.header);
    for (table.rows) |row| try candidates.tsv.row(&out.writer, row);
    try equal(text, out.written());
    try std.testing.expectError(error.UnterminatedQuotedField, candidates.tsv.parse(f.c.a, "a\n\"broken"));
    try std.testing.expectError(error.InvalidTableWidth, candidates.tsv.parse(f.c.a, "a\tb\n1\n"));
}
test "runner retains binary output, exit status, signals, timeout and launch failure" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    var runner = Runner.init(&f.c, f.directory);
    const binary = try f.path("binary");
    try std.testing.expectEqual(@as(i64, 7), (try runner.run(&.{ "/bin/sh", "-c", "printf 'a\\000b'; printf diagnostic >&2; exit 7" }, binary, &f.c.env, .{})).code);
    try equal("a\x00b", try f.c.read(try f.c.fmt("{s}.stdout", .{binary})));
    try equal("diagnostic", try f.c.read(try f.c.fmt("{s}.stderr", .{binary})));
    try std.testing.expectEqual(@as(i64, -15), (try runner.run(&.{ "/bin/sh", "-c", "kill -TERM $$" }, try f.path("signal"), &f.c.env, .{})).code);
    try std.testing.expectEqual(@as(i64, 124), (try runner.run(&.{ "/bin/sh", "-c", "sleep 30" }, try f.path("timeout"), &f.c.env, .{ .timeout_ms = 20 })).code);
    try equal("timed_out", try u.str(runner.commands.array.items[2], "outcome"));
    try std.testing.expectEqual(@as(i64, 127), (try runner.run(&.{try f.path("absent-command")}, try f.path("missing"), &f.c.env, .{})).code);
    const persisted = try f.c.load(try f.path("commands.json"));
    try std.testing.expectEqual(@as(usize, 4), persisted.array.items.len);
    try equal("launch_failed", try u.str(persisted.array.items[3], "outcome"));
}
test "measurement runner keeps its deadline when stdout uses an explicit output file" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    var runner = Runner.init(&f.c, f.directory);
    const output = try f.path("measurement.out");
    const result = try runner.run(&.{ "/bin/sh", "-c", "exec sleep 30" }, try f.path("measurement"), &f.c.env, .{ .stdout_file = output, .timeout_ms = 100 });
    try std.testing.expectEqual(@as(i64, 124), result.code);
    const persisted = try f.c.load(try f.path("commands.json"));
    try equal("timed_out", try u.str(persisted.array.items[0], "outcome"));
    try equal(output, try u.str(persisted.array.items[0], "stdout"));
    try expect((try u.json.integer(try u.get(persisted.array.items[0], "actual_returncode"))) < 0);
}

test "observations reject wrong output, nonzero status and stderr" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    var runner = Runner.init(&f.c, f.directory);
    try runner.observe("/bin/sh", &.{ "-c", "printf 'val=123\\n'" }, 0, "val=123\n", try f.path("matching"), &f.c.env);
    for ([_][]const u8{ "printf 'val=456\\n'", "exit 1", "printf 'val=123\\n'; printf failure >&2" }, 0..) |command, i| try std.testing.expectError(error.ValidationFailed, runner.observe("/bin/sh", &.{ "-c", command }, 0, "val=123\n", try f.path(try f.c.fmt("wrong-{d}", .{i})), &f.c.env));
}
test "owned group cleans descendants after leader exits" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    var runner = Runner.init(&f.c, f.directory);
    _ = try runner.run(&.{ "/bin/sh", "-c", "sleep 30 & printf '%s\\n' \"$!\"" }, try f.path("descendant"), &f.c.env, .{});
    const pid = u.trim(try f.c.read(try f.path("descendant.stdout")));
    const status_path = try f.c.fmt("/proc/{s}/stat", .{pid});
    const deadline = std.Io.Clock.awake.now(io).addDuration(.fromSeconds(2));
    // The provider joins its leader and kills the group. Grandchildren still
    // need a kernel scheduling turn to observe SIGKILL; they are not our waitpid children.
    while (true) {
        const state = f.c.read(status_path) catch |err| switch (err) {
            error.FileNotFound => return,
            else => return err,
        };
        const end = std.mem.lastIndexOfScalar(u8, state, ')') orelse return error.InvalidProcStat;
        if (state[end + 2] == 'Z' or state[end + 2] == 'X') return;
        if (std.Io.Clock.awake.now(io).nanoseconds >= deadline.nanoseconds) return error.DescendantSurvivedGroupCleanup;
        try io.sleep(.fromMilliseconds(1), .awake);
    }
}
test "ELF repacking preserves contract while code and symbol mutations differ" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const source = try f.write("probe.s", ".text\n.globl probe\n.type probe,@function\nprobe:\n call external\n ret\n.size probe,.-probe\n.data\n.byte 7,8,9\n");
    const original = try f.path("probe.o");
    const repacked = try f.path("repacked.o");
    _ = try f.c.capture(&.{ "cc", "-c", source, "-o", original });
    _ = try f.c.capture(&.{ "ld", "-r", original, "-o", repacked });
    const bytes = try f.c.read(original);
    const contract = try elf.parse(f.c.a, bytes);
    try expect(u.json.eql(contract, try elf.parse(f.c.a, try f.c.read(repacked))));
    try expect((try u.get(contract, "relocations")).array.items.len > 0);
    const changed = try f.c.a.dupe(u8, bytes);
    const table = std.mem.readInt(u64, changed[40..48], .little);
    const count = std.mem.readInt(u16, changed[60..62], .little);
    for (0..count) |i| {
        const at = table + i * 64;
        if (std.mem.readInt(u64, changed[at + 8 ..][0..8], .little) & 4 != 0 and std.mem.readInt(u64, changed[at + 32 ..][0..8], .little) > 0) {
            changed[std.mem.readInt(u64, changed[at + 24 ..][0..8], .little)] ^= 1;
            break;
        }
    }
    try expect(!u.json.eql(contract, try elf.parse(f.c.a, changed)));
    try expect(!u.json.eql(contract, try elf.parse(f.c.a, try std.mem.replaceOwned(u8, f.c.a, bytes, "external\x00", "altered!\x00"))));
}
fn frame(c: *u.Context, key: []const u8, bytes: []const u8) ![]const u8 {
    return c.fmt("{s}={d}\n{s}\n", .{ key, bytes.len, bytes });
}
fn function(c: *u.Context, name: []const u8, count: usize) ![]const u8 {
    return c.fmt("function_begin\n{s}{s}instruction_count={d}\nmain_body_count=1\nliveness=present\n{s}{s}{s}function_end\n", .{
        try frame(c, "name_bytes", name),                                                                                           try frame(c, "type_bytes", "fn () u32"), count, try frame(c, "air_bytes", ""), try frame(c, "structured_air_bytes", ""),
        try frame(c, "structured_air_v2_bytes", "structured_air-v2\ntyped_inst|0|ret|8|noreturn|un_op|0\nstructured_air_v2_end\n"),
    });
}
fn descriptor(c: *u.Context, mode: []const u8, functions: []const []const u8) ![]const u8 {
    return c.fmt("zllvm-air-export-v1\ncontract_version=1\npayload=zig-air-print-v1\nproducer=test\nroot_source=main.zig\nwrapper=main.zig\nmode={s}\ntarget=x86_64-linux-gnu\nfunction_count={d}\nglobal_count=0\n{s}", .{ mode, functions.len, try std.mem.concat(c.a, u8, functions) });
}
fn raw(f: *Fixture, mode: []const u8, pin: []const u8, functions: []const []const u8) ![]const u8 {
    const data = try descriptor(&f.c, mode, functions);
    const path = try f.write(try f.c.fmt("{s}.air", .{mode}), data);
    _ = try f.write(try f.c.fmt("{s}.meta", .{mode}), try f.c.fmt("schema=3\nziglang_pin={s}\nmode={s}\ndescriptor_sha256={s}\n", .{ pin, mode, try u.digestBytes(f.c.a, data) }));
    return path;
}
test "raw scanner excludes ambiguities and rejects body, identity, hash and framing drift" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const path = try raw(&f, "ReleaseFast", "test", &.{ try function(&f.c, "overload", 1), try function(&f.c, "unique", 1), try function(&f.c, "overload", 1) });
    const scanned = try facts.scan(&f.c, path, "ReleaseFast", "test");
    try std.testing.expectEqual(@as(u32, 1), scanned.functions.count());
    try equal("overload", scanned.duplicates[0]);
    try expect(scanned.functions.contains("unique"));
    try std.testing.expectError(error.ValidationFailed, facts.scan(&f.c, path, "ReleaseSafe", "test"));
    const original = try f.c.read(path);
    try f.c.write(path, try f.c.fmt("{s}changed", .{original}));
    try std.testing.expectError(error.ValidationFailed, facts.scan(&f.c, path, "ReleaseFast", "test"));
    try std.testing.expectError(error.ValidationFailed, facts.scanBytes(&f.c, try descriptor(&f.c, "ReleaseFast", &.{try function(&f.c, "broken", 2)}), "ReleaseFast", zero_hash));
    try std.testing.expectError(error.ValidationFailed, facts.scanBytes(&f.c, try std.mem.replaceOwned(u8, f.c.a, original, "target=x86_64-linux-gnu", "target=aarch64-linux-gnu"), "ReleaseFast", zero_hash));
    try std.testing.expectError(error.UnexpectedExportTerminator, facts.scanBytes(&f.c, try f.c.fmt("{s}unexpected\n", .{original}), "ReleaseFast", zero_hash));
    var reader: facts.Descriptor = .{ .data = "abc\n" };
    try std.testing.expectError(error.InvalidDescriptorFrame, reader.frameSize(std.math.maxInt(usize)));
    reader = .{ .data = "truncated" };
    try std.testing.expectError(error.TruncatedDescriptorLine, reader.line());
}
test "compact facts roundtrip every field and reject tampering, duplicate keys and malformed counts" {
    var f: Fixture = undefined;
    try f.init();
    defer f.deinit();
    const path = try raw(&f, "ReleaseFast", "test", &.{ try function(&f.c, "unique", 1), try function(&f.c, "duplicate", 1), try function(&f.c, "duplicate", 1) });
    const original = try facts.scan(&f.c, path, "ReleaseFast", "test");
    const output = try f.path("facts.json");
    const digest = try facts.write(&f.c, output, "ReleaseFast", "test", original);
    const reloaded = try facts.load(&f.c, output, "ReleaseFast", "test", digest, original.descriptor_sha256);
    try expect(u.json.eql(try original.functions.get("unique").?.value(f.c.a), try reloaded.functions.get("unique").?.value(f.c.a)));
    try equal("duplicate", reloaded.duplicates[0]);
    try std.testing.expectError(error.PathAlreadyExists, facts.write(&f.c, output, "ReleaseFast", "test", original));
    const bytes = try f.c.read(output);
    try f.c.write(output, try f.c.fmt("{s}changed", .{bytes}));
    try std.testing.expectError(error.ValidationFailed, facts.load(&f.c, output, "ReleaseFast", "test", digest, original.descriptor_sha256));
    const duplicate = try std.mem.replaceOwned(u8, f.c.a, bytes, "\"functions\":{", "\"functions\":{},\"functions\":{");
    try f.c.write(output, duplicate);
    try std.testing.expectError(error.DuplicateField, facts.load(&f.c, output, "ReleaseFast", "test", try u.digestBytes(f.c.a, duplicate), original.descriptor_sha256));
    for ([_][]const u8{ "schema", "source_pin", "mode", "target", "descriptor_sha256" }) |key| {
        var payload = (try u.json.parse(f.c.a, bytes)).value;
        try u.put(f.c.a, &payload, key, u.s("other"));
        try std.testing.expectError(error.ValidationFailed, facts.validate(&f.c, payload, "ReleaseFast", "test", original.descriptor_sha256));
    }
    const changes = [_]struct { key: []const u8, val: u.Value }{
        .{ .key = "instructions", .val = u.b(true) },       .{ .key = "calls", .val = u.n(-1) },                 .{ .key = "calls", .val = u.n(2) },
        .{ .key = "runtime_refs", .val = u.n(1) },          .{ .key = "global_refs", .val = .{ .float = 0.5 } }, .{ .key = "undefined_result", .val = u.n(0) },
        .{ .key = "typed_sha256", .val = u.s("unproved") },
    };
    for (changes) |change| {
        var payload = (try u.json.parse(f.c.a, bytes)).value;
        try u.put(f.c.a, payload.object.getPtr("functions").?.object.getPtr("unique").?, change.key, change.val);
        if (facts.validate(&f.c, payload, "ReleaseFast", "test", original.descriptor_sha256)) |_| return error.AcceptedMalformedFact else |_| {}
    }
    for (0..3) |i| {
        var payload = (try u.json.parse(f.c.a, bytes)).value;
        if (i == 0) try u.put(f.c.a, &payload, "unambiguous_functions", u.n(2)) else try u.put(f.c.a, &payload, "ambiguous_symbols_excluded", try u.strings(f.c.a, if (i == 1) &.{"unique"} else &.{ "duplicate", "duplicate" }));
        try std.testing.expectError(error.InvalidCandidateFactPopulation, facts.validate(&f.c, payload, "ReleaseFast", "test", original.descriptor_sha256));
    }
}
