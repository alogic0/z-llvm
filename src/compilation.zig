//! Shared preparation and selection contracts for textual IR and frontend
//! adapters. Callers choose optimization explicitly; diagnostics have their own
//! writer so object bytes never contain pass traces or timing reports.
const std = @import("std");
const ir = @import("ir.zig");
const pm = @import("pass_manager.zig");
const pipelines = @import("pipelines.zig");
const codegen = @import("codegen.zig");
const profiling = @import("compilation_profile.zig");

pub const Options = struct {
    optimization: ?[]const u8 = null,
    passes: pm.RunOptions = .{},
    profile: ?*profiling.Profile = null,
};
pub const SelectionOptions = codegen.x86_64.CodegenOptions;

/// Validate a deferred request without constructing or optimizing a module.
pub fn validate(allocator: std.mem.Allocator, options: Options) !void {
    const sequence = options.optimization orelse return;
    var manager = pm.ModulePassManager.init(allocator);
    defer manager.deinit();
    try pipelines.addPasses(&manager, sequence);
}

pub fn prepare(allocator: std.mem.Allocator, io: ?std.Io, module: *ir.Module, diagnostics: *std.Io.Writer, options: Options) !void {
    {
        const scope = profiling.enter(options.profile, .verify);
        defer scope.end();
        try module.verify();
    }
    const sequence = options.optimization orelse return;
    const scope = profiling.enter(options.profile, .optimize);
    defer scope.end();
    var manager = pm.ModulePassManager.init(allocator);
    defer manager.deinit();
    try pipelines.addPasses(&manager, sequence);
    var context: pm.Context = .{ .allocator = allocator, .io = io };
    _ = try manager.runWithOptions(module, &context, diagnostics, options.passes);
}

pub fn select(allocator: std.mem.Allocator, triple: []const u8, function: ir.Function, options: SelectionOptions) !codegen.x86_64.MachineFunction {
    return codegen.x86_64.lowerFunctionWithOptions(allocator, triple, function, options);
}
