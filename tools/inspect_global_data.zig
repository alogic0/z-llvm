//! Inventory the actual global decoder without selecting function bodies.
const std = @import("std");
const u = @import("validation/common.zig");
const probe = @import("global_probe");

fn preview(text: []const u8) []const u8 {
    var end = @min(text.len, 512);
    while (end != 0 and !std.unicode.utf8ValidateSlice(text[0..end])) end -= 1;
    return text[0..end];
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    if (u.contains(argv[1..], "--help")) return c.print("usage: inspect-global-data --input FILE --output-root DIR [--symbol NAME] [--max-errors N] [--placement]\n", .{});
    const args = try u.Args.parse(c.a, argv[1..], &.{ "input", "output-root", "symbol", "max-errors" }, &.{"placement"});
    if (args.flag("placement") and args.get("symbol") != null) return error.PlacementRequiresWholeModule;
    const limit = try std.fmt.parseUnsigned(usize, args.get("max-errors") orelse "64", 10);
    if (limit == 0 or limit > 4096) return error.InvalidErrorLimit;
    const out = try c.newOutput(try args.require("output-root"));
    const input = try c.join(&.{try args.require("input")});
    const source = try c.read(input);
    var module = try probe.ir.Module.parse(c.gpa, source);
    defer module.deinit();
    try module.verify();
    const context: probe.Context = .{
        .globals = module.globals.items,
        .aliases = module.aliases.items,
        .named_types = module.named_types.items,
        .functions = module.functions.items,
        .declarations = module.declarations.items,
        .target_datalayout = module.target_datalayout,
        .emit_all_globals = true,
        .require_resolved_aliases = true,
    };
    var records = u.array(c.a);
    var rejected = u.array(c.a);
    var examined: usize = 0;
    var declarations: usize = 0;
    var failures: usize = 0;
    var zero_sized: usize = 0;
    var data_bytes: u64 = 0;
    var tls_bytes: u64 = 0;
    for (module.globals.items) |global| {
        if (args.get("symbol")) |name| if (!probe.ir.identifiers.eql(global.name, name)) continue;
        examined += 1;
        if (global.initializer == .none) {
            declarations += 1;
            continue;
        }
        const ty = try c.fmt("{f}", .{global.ty});
        var diagnostic: probe.data.Diagnostic = .{};
        var decoded = probe.data.decodeObserved(c.gpa, context, global, &diagnostic) catch |err| {
            if (err == error.OutOfMemory) return err;
            failures += 1;
            if (rejected.array.items.len < limit) try u.add(&rejected, try u.toValue(c.a, .{
                .ordinal = examined,
                .symbol = global.name,
                .type = preview(ty),
                .type_truncated = ty.len > 512,
                .initializer_kind = @tagName(global.initializer),
                .diagnostic = @errorName(err),
                .phase = diagnostic.phase,
                .reason = diagnostic.reason,
                .rejected_type = if (diagnostic.ty) |rejected_type| preview(try c.fmt("{f}", .{rejected_type})) else null,
                .value_kind = diagnostic.value_kind,
                .offset = diagnostic.offset,
                .requested = diagnostic.requested,
                .limit = diagnostic.limit,
                .linkage = global.linkage,
                .address_attrs = if (global.address_attrs) |attrs| preview(attrs) else null,
                .attrs = if (global.attrs) |attrs| preview(attrs) else null,
            }));
            continue;
        };
        defer decoded.deinit(c.gpa);
        if (decoded.bytes.len == 0) zero_sized += 1;
        if (decoded.tls) tls_bytes += decoded.bytes.len else data_bytes += decoded.bytes.len;
        try u.add(&records, try u.toValue(c.a, .{
            .ordinal = examined,
            .symbol = global.name,
            .type = preview(ty),
            .initializer_kind = @tagName(global.initializer),
            .bytes = decoded.bytes.len,
            .alignment = decoded.alignment,
            .relocations = decoded.relocations.len,
            .tls = decoded.tls,
        }));
    }
    if (examined == 0) return error.NoMatchingGlobal;
    try c.writeJson(try c.join(&.{ out, "decoded.json" }), records);
    try c.writeJson(try c.join(&.{ out, "rejections.json" }), rejected);
    if (args.flag("placement")) {
        if (failures != 0) return error.DecoderRejectionsBlockPlacement;
        const placement = try probe.elf.inspectGlobalPlacement(c.gpa, context);
        try c.writeJson(try c.join(&.{ out, "placement.json" }), .{
            .scope = "shared ELF global placement, all parsed global roots; no MIR, resolved function/block fixups or object credit",
            .placement = placement,
        });
    }
    const unchanged = std.mem.eql(u8, try u.digestBytes(c.a, source), try c.digest(input));
    if (!unchanged) return error.InputChangedDuringInventory;
    try c.writeJson(try c.join(&.{ out, "report.json" }), .{
        .schema = "global-data-inventory-v1",
        .scope = "all parsed global decoders; no function selection, emitted dependency closure or object credit",
        .input = input,
        .input_bytes = source.len,
        .input_sha256 = try u.digestBytes(c.a, source),
        .input_verified_unchanged = unchanged,
        .module_verified = true,
        .functions = module.functions.items.len,
        .globals = module.globals.items.len,
        .examined = examined,
        .declarations = declarations,
        .decoded = records.array.items.len,
        .rejected = failures,
        .retained_rejections = rejected.array.items.len,
        .zero_sized_decoded = zero_sized,
        .decoded_data_bytes = data_bytes,
        .decoded_tls_bytes = tls_bytes,
        .status = "complete",
    });
    try c.print("global inventory: examined={d} rejected={d} zero_sized={d}; {s}/report.json\n", .{ examined, failures, zero_sized, out });
}
