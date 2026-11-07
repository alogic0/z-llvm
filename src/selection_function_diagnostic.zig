//! Focused selection with the complete original module context. This diagnostic
//! never emits an object and grants no whole-module selection/execution credit.
//! zig run -O ReleaseFast src/selection_function_diagnostic.zig -- input.ll name output-prefix
const std = @import("std");
const ir = @import("ir.zig");
const compilation = @import("compilation.zig");
const codegen = @import("codegen.zig");
const profiling = @import("compilation_profile.zig");

pub fn main(init: std.process.Init) !void {
    const a = init.gpa;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 4) return error.ExpectedInputFunctionAndOutputPrefix;
    var p = profiling.Profile.init(a, init.io);
    defer p.deinit();
    const events = try std.fmt.allocPrint(a, "{s}.events.jsonl", .{args[3]});
    defer a.free(events);
    const summary = try std.fmt.allocPrint(a, "{s}.profile.json", .{args[3]});
    defer a.free(summary);
    if (std.mem.eql(u8, args[1], events) or std.mem.eql(u8, args[1], summary)) return error.ConflictingOutputPaths;
    try p.startEvents(events);
    var selected = false;
    defer {
        p.write(summary, selected) catch @panic("profile write failed");
        p.finishEvents(selected) catch @panic("profile event write failed");
    }
    const input = blk: {
        const phase = profiling.enter(&p, .input);
        defer phase.end();
        break :blk try std.Io.Dir.cwd().readFileAlloc(init.io, args[1], a, .limited(2 * 1024 * 1024 * 1024));
    };
    defer a.free(input);
    var module = blk: {
        const phase = profiling.enter(&p, .parse);
        defer phase.end();
        break :blk try ir.Module.parse(a, input);
    };
    defer module.deinit();
    {
        const phase = profiling.enter(&p, .verify);
        defer phase.end();
        try module.verify();
    }
    const context: codegen.x86_64.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
        .emit_all_globals = true,
        .require_resolved_aliases = true,
        .functions = module.functions.items,
        .declarations = module.declarations.items,
    };
    const function = for (module.functions.items) |function| {
        if (ir.identifiers.eql(function.name, args[2])) break function;
    } else return error.UnknownFunction;
    var instructions: usize = 0;
    for (function.blocks.items) |block| instructions += block.instructions.items.len;
    const scope = try p.beginFunction(function.name, function.blocks.items.len, instructions);
    defer scope.end();
    const phase = profiling.enter(&p, .select);
    defer phase.end();
    var tag: ?[]const u8 = null;
    var detail: ?[]const u8 = null;
    var diagnostic: ?[]const u8 = null;
    // Match the explicit target override of run_whole_compiler; the retained
    // frontend target spelling need not be a local backend target identifier.
    const target_triple = "x86_64-unknown-linux-gnu";
    if (compilation.select(a, target_triple, function, .{
        .profile = &p,
        .generic_cfg_selector = true,
        .module_context = &context,
        .generic_cfg_selector_diagnostic_tag = &tag,
        .generic_cfg_selector_diagnostic_detail = &detail,
    })) |value| {
        var machine = value;
        defer machine.deinit(a);
        selected = true;
        p.counters.selected_functions += 1;
        p.counters.emitted_instructions += machine.instructions.items.len;
    } else |err| {
        if (err == error.OutOfMemory) return err;
        p.counters.failed_functions += 1;
        diagnostic = @errorName(err);
    }
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(input, &digest, .{});
    const input_hex = std.fmt.bytesToHex(digest, .lower);
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.File.stdout().writerStreaming(init.io, &buffer);
    try std.json.Stringify.value(.{
        .scope = "one function selected with original module context; no object or execution credit",
        .input_sha256 = input_hex[0..],
        .module_definitions = module.functions.items.len,
        .target = target_triple,
        .full_module_verified = true,
        .function = function.name,
        .selected = selected,
        .diagnostic = diagnostic,
        .selector_tag = tag,
        .selector_detail = detail,
    }, .{}, &writer.interface);
    try writer.interface.writeByte('\n');
    try writer.interface.flush();
}
