//! Freeze or verify tracked and untracked source membership and SHA-256 values.
const std = @import("std");
const u = @import("validation/common.zig");
const provenance = @import("validation/provenance.zig");
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    if (u.contains(argv[1..], "--help")) {
        try c.print("usage: zig run tools/validation_snapshot.zig -- --output NEW_FILE | --verify FILE\n", .{});
        return;
    }
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output", "verify" }, &.{});
    if ((args.get("output") != null) == (args.get("verify") != null)) return error.ChooseOneOperation;
    const snapshot = try provenance.snapshot(&c);
    if (args.get("verify")) |path| {
        if (!u.json.eql(try c.load(try c.join(&.{path})), snapshot)) return error.SourceSnapshotChanged;
        try c.print("source snapshot verified: {s}\n", .{path});
    } else {
        const path = try c.ownedPath(try args.require("output"));
        if (u.exists(c.io, path)) return error.EvidenceAlreadyExists;
        try c.mkdir(std.fs.path.dirname(path).?);
        try c.writeJson(path, snapshot);
        try c.print("source snapshot: {s} files={d}\n", .{ path, (try u.get(snapshot, "files")).object.count() });
    }
}
