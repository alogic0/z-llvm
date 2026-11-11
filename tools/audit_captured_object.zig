//! Audit a retained, completed backend command without rerunning it or changing
//! its receipt. Useful when runner postprocessing failed after object emission.
const std = @import("std");
const u = @import("validation/common.zig");
const reports = @import("validation/whole_compiler_report.zig");
const elf = @import("validation/object_contract.zig");

fn objectName(a: std.mem.Allocator, spelling: []const u8) ![]const u8 {
    const name = reports.ownershipName(spelling);
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

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "capture-root", "census", "output-root" }, &.{});
    const root = try c.join(&.{try args.require("capture-root")});
    const output = try c.newOutput(try args.require("output-root"));
    const original_report = try c.load(try c.join(&.{ root, "report.json" }));
    const directory = try c.join(&.{ root, "backend" });
    const invocation = try c.load(try c.join(&.{ directory, "invocation.json" }));
    const commands = try c.load(try c.join(&.{ directory, "commands.json" }));
    if (commands.array.items.len != 1) return error.ExpectedOneBackendCommand;
    const command = commands.array.items[0];
    if ((try u.get(command, "actual_returncode")).integer != 0 or (try u.get(command, "returncode")).integer != 0 or !u.json.is(try u.get(command, "outcome"), "completed")) return error.BackendDidNotComplete;
    const backend = try u.get(original_report, "backend");
    const backend_path = try u.str(backend, "path");
    if (!std.mem.eql(u8, try c.digest(backend_path), try u.str(backend, "sha256"))) return error.BackendIdentityChanged;
    const effective = try c.load(try c.join(&.{ directory, "effective-argv.json" }));
    if (!u.json.is(effective.array.items[0], backend_path)) return error.BackendCommandMismatch;
    const recorded_argv = (try u.get(command, "argv")).array.items;
    if (recorded_argv.len < effective.array.items.len) return error.BackendCommandMismatch;
    for (effective.array.items, recorded_argv[recorded_argv.len - effective.array.items.len ..]) |actual, recorded| if (!u.json.eql(actual, recorded)) return error.BackendCommandMismatch;
    const input = try u.get(invocation, "input");
    const input_path = try c.join(&.{ directory, "input.ll" });
    if (!std.mem.eql(u8, try c.digest(input_path), try u.str(input, "sha256")) or !std.mem.eql(u8, try c.digest(try u.str(invocation, "original_input")), try u.str(input, "sha256"))) return error.InputIdentityChanged;
    const profile = try c.load(try c.join(&.{ directory, "profile.json" }));
    const analysis = try reports.analyze(c.a, try c.read(try c.join(&.{ directory, "backend.stderr" })));
    try reports.validateSuccess(c.a, analysis, profile, try c.read(try c.join(&.{ directory, "owners.tsv" })));
    const object_path = try c.join(&.{ directory, "local.o" });
    const contract = try elf.parse(c.a, try c.read(object_path));
    var symbols = std.StringHashMap(u.Value).init(c.a);
    for ((try u.get(contract, "symbols")).array.items) |symbol| {
        if ((try symbols.getOrPut(symbol.array.items[0].string)).found_existing) return error.DuplicateElfSymbol;
        try symbols.put(symbol.array.items[0].string, symbol);
    }
    var functions = std.StringHashMap(void).init(c.a);
    for ((try u.get(profile, "functions")).array.items) |function| {
        const name = try objectName(c.a, try u.str(function, "name"));
        const symbol = symbols.get(name) orelse return error.MissingFunctionSymbol;
        if (symbol.array.items[1].integer & 15 != 2 or !u.json.is(symbol.array.items[3], ".text") or symbol.array.items[5].integer <= 0) return error.InvalidFunctionSymbol;
        if ((try functions.getOrPut(reports.ownershipName(try u.str(function, "name")))).found_existing) return error.DuplicateProfileFunction;
    }
    const census_path = try c.join(&.{try args.require("census")});
    var lines = std.mem.tokenizeScalar(u8, try c.read(census_path), '\n');
    var complete = false;
    var count: usize = 0;
    while (lines.next()) |line| {
        const row = (try u.json.parse(c.a, line)).value;
        if (u.json.is(try u.get(row, "event"), "function")) {
            if (complete or !(try u.get(row, "selected")).bool or !functions.remove(reports.ownershipName(try u.str(row, "function")))) return error.CensusMismatch;
            count += 1;
        } else if (u.json.is(try u.get(row, "event"), "complete")) {
            if (complete or (try u.get(row, "failed")).integer != 0 or (try u.get(row, "examined")).integer != count or (try u.get(row, "selected")).integer != count) return error.CensusMismatch;
            complete = true;
        }
    }
    if (!complete or count == 0 or functions.count() != 0) return error.CensusMismatch;
    try c.writeJson(try c.join(&.{ output, "object-contract.json" }), contract);
    try c.writeJson(try c.join(&.{ output, "report.json" }), .{
        .schema = "retained-object-audit-v1",
        .status = "passed",
        .object_complete = true,
        .scope = "Completed backend command, input, profile, ownership, census and ELF; no startup credit",
        .capture_root = root,
        .original_runner_status = try u.str(original_report, "status"),
        .backend_sha256 = try c.digest(backend_path),
        .input_sha256 = try c.digest(input_path),
        .object_sha256 = try c.digest(object_path),
        .census_sha256 = try c.digest(census_path),
        .actual_backend_returncode = 0,
        .definitions = count,
    });
    try c.print("retained object audit: passed; definitions={d}; report={s}/report.json\n", .{ count, output });
}

test "object audit decodes LLVM escapes exactly once" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectEqualStrings("type.\"union\"\\31", try objectName(arena.allocator(), "\"type.\\22union\\22\\5C31\""));
    try std.testing.expectError(error.InvalidSymbolName, objectName(arena.allocator(), "bad\\00"));
}
