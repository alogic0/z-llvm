const std = @import("std");
const ir = @import("ir.zig");
const compilation = @import("compilation.zig");
const profiling = @import("compilation_profile.zig");
const compilation_artifact = @import("compilation_artifact.zig");
const target = @import("target.zig");
const zae = @import("zig_air_export.zig");
const zal = @import("zig_air_lowering.zig");
const main_flow_writer = @import("main_flow_ir_writer.zig");

const IrWriterCase = main_flow_writer.IrWriterCase;
const writeIrWriterModuleFromEnv = main_flow_writer.writeIrWriterModuleFromEnv;
const writeSemanticDescriptorFromEnv = main_flow_writer.writeSemanticDescriptorFromEnv;
const resolveDirectIrWriterCase = main_flow_writer.resolveDirectIrWriterCase;
const resolveDirectSemanticDescriptor = main_flow_writer.resolveDirectSemanticDescriptor;
const buildStructuredDirectModule = main_flow_writer.buildStructuredDirectModule;
const buildStructuredDirectModuleFromDescriptor = main_flow_writer.buildStructuredDirectModuleFromDescriptor;
const runStructuredDirectAcceptedPipeline = main_flow_writer.runStructuredDirectAcceptedPipeline;
const runStructuredDirectAcceptedPipelineForSurface = main_flow_writer.runStructuredDirectAcceptedPipelineForSurface;
const emitCodegenModule = main_flow_writer.emitCodegenModule;
const fatal = main_flow_writer.fatal;
const Emit = main_flow_writer.Emit;

const usage =
    \\usage: z_llvm [--emit=ir|asm|obj|ir-writer|semantic-descriptor|selection-owner-manifest] [--target=triple] [--datalayout=layout] [--passes=list|pipeline] [--pipeline=name] [--trace] [--time] [--quiet] [--report-all-codegen-failures] [--generic-cfg-selector] [--codegen-reachable] [--pass-limit=N] [--input-limit=N] <input.ll>
    \\       z_llvm --emit=ir-writer
    \\       z_llvm --emit=semantic-descriptor
    \\
    \\Supported passes: instcombine,dce,adce,early-cse,gvn,licm,simplifycfg,mem2reg,sroa,function-attrs,inline,vector-combine,slp-vectorizer,verify plus inventory placeholders
    \\Supported pipelines: scalar-foundation,memory-foundation,zig-scalar-foundation,debug-o0,zig-debug-accepted,zig-release-safe-accepted,zig-release-fast-accepted,zig-release-small-accepted,aarch64-target-independent,release-o3,release-oz,lto-prelink-o3,lto-prelink-oz
    \\Default input limit: 1048576 bytes
    \\--codegen-reachable selects module dependencies for object/owner output; opaque references retain all definitions.
    \\Explicit --passes/--pipeline run before IR, object, assembly and owner output. Object emission defaults to no optimization. Codegen traces and timing go to stderr.
    \\Structured adapter envelopes carry explicit passes for execution when their typed module is built; --emit=ir preserves this deferred recipe.
    \\--profile=PATH writes exclusive phase timings and counters as JSON, independently of pass timing.
    \\--profile-events=PATH flushes function, phase and legalizer progress as JSONL, including incomplete runs.
    \\--selection-owner-output=PATH writes ownership from the same successful --emit=obj selection run.
    \\
;

const default_input_limit = 1024 * 1024;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var pass_list: []const u8 = "instcombine,dce";
    var explicit_optimization = false;
    var trace = false;
    var timing = false;
    var quiet = false;
    var report_all_codegen_failures = envFlag(init.environ_map, "ZLLVM_CODEGEN_REPORT_ALL");
    var generic_cfg_selector = envFlag(init.environ_map, "ZLLVM_GENERIC_CFG_SELECTOR");
    var codegen_reachable = envFlag(init.environ_map, "ZLLVM_CODEGEN_REACHABLE");
    var pass_limit: ?usize = null;
    var input_limit: usize = default_input_limit;
    var emit: Emit = .ir;
    var target_triple: ?[]const u8 = null;
    var target_datalayout: ?[]const u8 = null;
    var input_path: ?[]const u8 = null;
    var profile_path: ?[]const u8 = null;
    var profile_events_path: ?[]const u8 = null;
    var owner_path: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            return;
        } else if (std.mem.eql(u8, arg, "--trace")) {
            trace = true;
        } else if (std.mem.eql(u8, arg, "--time")) {
            timing = true;
        } else if (std.mem.eql(u8, arg, "--quiet")) {
            quiet = true;
        } else if (std.mem.eql(u8, arg, "--report-all-codegen-failures")) {
            report_all_codegen_failures = true;
        } else if (std.mem.eql(u8, arg, "--generic-cfg-selector")) {
            generic_cfg_selector = true;
        } else if (std.mem.eql(u8, arg, "--codegen-reachable")) {
            codegen_reachable = true;
        } else if (std.mem.startsWith(u8, arg, "--profile=")) {
            profile_path = arg["--profile=".len..];
            if (profile_path.?.len == 0) return error.EmptyProfilePath;
        } else if (std.mem.startsWith(u8, arg, "--profile-events=")) {
            profile_events_path = arg["--profile-events=".len..];
            if (profile_events_path.?.len == 0) return error.EmptyProfileEventsPath;
        } else if (std.mem.startsWith(u8, arg, "--selection-owner-output=")) {
            owner_path = arg["--selection-owner-output=".len..];
            if (owner_path.?.len == 0) return error.EmptyOwnerPath;
        } else if (std.mem.startsWith(u8, arg, "--pass-limit=")) {
            pass_limit = try std.fmt.parseInt(usize, arg["--pass-limit=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--input-limit=")) {
            input_limit = try parseInputLimit(arg["--input-limit=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--emit=")) {
            const emit_text = arg["--emit=".len..];
            if (std.mem.eql(u8, emit_text, "ir")) {
                emit = .ir;
            } else if (std.mem.eql(u8, emit_text, "asm")) {
                emit = .@"asm";
            } else if (std.mem.eql(u8, emit_text, "obj")) {
                emit = .obj;
            } else if (std.mem.eql(u8, emit_text, "ir-writer")) {
                emit = .ir_writer;
            } else if (std.mem.eql(u8, emit_text, "semantic-descriptor")) {
                emit = .semantic_descriptor;
            } else if (std.mem.eql(u8, emit_text, "selection-owner-manifest")) {
                emit = .selection_owner_manifest;
            } else {
                return error.UnsupportedEmitMode;
            }
        } else if (std.mem.startsWith(u8, arg, "--target=")) {
            target_triple = arg["--target=".len..];
        } else if (std.mem.startsWith(u8, arg, "--datalayout=")) {
            target_datalayout = arg["--datalayout=".len..];
        } else if (std.mem.startsWith(u8, arg, "--pipeline=")) {
            pass_list = arg["--pipeline=".len..];
            explicit_optimization = true;
        } else if (std.mem.startsWith(u8, arg, "--passes=")) {
            pass_list = arg["--passes=".len..];
            explicit_optimization = true;
        } else if (input_path == null) {
            input_path = arg;
        } else {
            var stderr_buffer: [4096]u8 = undefined;
            var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
            try stderr_writer.interface.print("unexpected argument: {s}\n{s}", .{ arg, usage });
            try stderr_writer.interface.flush();
            std.process.exit(2);
        }
    }

    if (owner_path != null and emit != .obj) return error.OwnerSidecarRequiresObject;
    if (profile_path) |p| {
        if (owner_path) |o| if (std.mem.eql(u8, p, o)) return error.ConflictingOutputPaths;
        if (input_path) |i| if (std.mem.eql(u8, p, i)) return error.ConflictingOutputPaths;
    }
    if (owner_path) |o| if (input_path) |i| if (std.mem.eql(u8, o, i)) return error.ConflictingOutputPaths;
    if (profile_events_path) |events| {
        for ([_]?[]const u8{ input_path, profile_path, owner_path }) |path|
            if (path) |other| if (try sameOutputPath(allocator, io, events, other)) return error.ConflictingOutputPaths;
    }
    var profile_state: ?profiling.Profile = if (profile_path != null or profile_events_path != null) .init(allocator, io) else null;
    const profile: ?*profiling.Profile = if (profile_state) |*p| p else null;
    defer if (profile) |p| p.deinit();
    if (profile_events_path) |path| try profile.?.startEvents(path);
    var succeeded = true;
    defer if (profile) |p| {
        if (profile_path) |path| p.write(path, succeeded and p.events_error == null) catch |err| {
            std.debug.print("profile write failed: {s}\n", .{@errorName(err)});
            std.process.exit(2);
        };
        p.finishEvents(succeeded) catch |err| {
            std.debug.print("profile events write failed: {s}\n", .{@errorName(err)});
            std.process.exit(2);
        };
    };
    errdefer succeeded = false;
    const optimization: compilation.Options = .{
        .profile = profile,
        .optimization = if (explicit_optimization) pass_list else null,
        .passes = .{ .trace = trace, .timing = timing, .pass_limit = pass_limit },
    };
    if ((emit == .ir_writer or emit == .semantic_descriptor) and explicit_optimization)
        return error.OptimizationNotApplicableToArtifact;
    if (emit != .ir and (trace or timing or pass_limit != null) and !explicit_optimization)
        return error.CodegenPassOptionsRequireExplicitOptimization;
    if (emit == .ir_writer) {
        try writeIrWriterModuleFromEnv(allocator, io, init.environ_map);
        return;
    }
    if (emit == .semantic_descriptor) {
        try writeSemanticDescriptorFromEnv(allocator, io, init.environ_map);
        return;
    }

    const path = input_path orelse {
        var stderr_buffer: [4096]u8 = undefined;
        var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
        try stderr_writer.interface.writeAll(usage);
        try stderr_writer.interface.flush();
        std.process.exit(2);
    };

    const input = blk: {
        const scope = profiling.enter(profile, .input);
        defer scope.end();
        break :blk try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(input_limit));
    };
    defer allocator.free(input);

    if (std.mem.startsWith(u8, input, zae.contract_name)) {
        var air_module = blk: {
            const scope = profiling.enter(profile, .parse);
            defer scope.end();
            break :blk zae.parse(allocator, input) catch |err| {
                try fatal(io, "AIR export parse failed for {s}: {any}\n", .{ path, err });
            };
        };
        defer air_module.deinit();
        var lowered = blk: {
            const scope = profiling.enter(profile, .air_lowering);
            defer scope.end();
            break :blk zal.lowerCompatible(allocator, air_module) catch |err| {
                try fatal(io, "AIR lowering failed for {s}: {any}\n", .{ path, err });
            };
        };
        defer lowered.deinit();
        try reportAirLowering(io, air_module, lowered);
        if (lowered.accepted_functions == 0) {
            try fatal(io, "AIR lowering accepted no functions for {s}\n", .{path});
        }
        if (target_triple) |triple| {
            _ = target.Triple.parse(triple) catch {
                try fatal(io, "invalid target triple: {s}\n", .{triple});
            };
            lowered.module.target_triple = triple;
        }
        try prepareForCodegen(allocator, io, &lowered.module, optimization);
        if (emit == .obj or emit == .@"asm" or emit == .selection_owner_manifest) {
            try emitCodegenModule(allocator, io, lowered.module, emit, target_triple, .{
                .quiet = quiet,
                .report_all_failures = report_all_codegen_failures,
                .generic_cfg_selector = generic_cfg_selector,
                .codegen_reachable = codegen_reachable,
                .profile = profile,
                .owner_output = owner_path,
            });
            return;
        }
        if (emit != .ir) return error.UnsupportedEmitMode;
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        if (!quiet) try lowered.module.print(&stdout_writer.interface);
        try stdout_writer.interface.flush();
        return;
    } else if (resolveDirectSemanticDescriptor(io, input)) |descriptor| {
        if (emit == .ir) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try compilation_artifact.write(allocator, &stdout_writer.interface, input, optimization);
            try stdout_writer.interface.flush();
            return;
        }
        if (emit == .obj or emit == .@"asm" or emit == .selection_owner_manifest) {
            var module = buildStructuredDirectModuleFromDescriptor(allocator, io, descriptor) catch |err| {
                try fatal(io, "direct semantic descriptor module build failed for {s}: {any}\n", .{ descriptor.id, err });
            };
            defer module.deinit();
            if (target_triple) |triple| {
                _ = target.Triple.parse(triple) catch {
                    try fatal(io, "invalid target triple: {s}\n", .{triple});
                };
                if (module.target_triple == null) module.target_triple = triple;
            }
            try runStructuredDirectAcceptedPipelineForSurface(allocator, io, &module, init.environ_map, descriptor.surface);
            try prepareArtifact(allocator, io, &module, input);
            try prepareForCodegen(allocator, io, &module, optimization);
            try emitCodegenModule(allocator, io, module, emit, target_triple, .{
                .quiet = quiet,
                .report_all_failures = report_all_codegen_failures,
                // Prepared typed adapters use mandatory normalization and
                // compositional selection, including optimized instruction forms.
                .generic_cfg_selector = true,
                .resolve_direct_definitions = true,
                .codegen_reachable = codegen_reachable,
                .profile = profile,
                .owner_output = owner_path,
            });
            return;
        }
    } else if (resolveDirectIrWriterCase(input)) |ir_writer_case| {
        if (emit == .ir) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try compilation_artifact.write(allocator, &stdout_writer.interface, input, optimization);
            try stdout_writer.interface.flush();
            return;
        }
        if (emit == .obj or emit == .@"asm" or emit == .selection_owner_manifest) {
            if (ir_writer_case.construction != .structured_builder) {
                try fatal(io, "direct IR writer artifact references non-direct case: {s}\n", .{ir_writer_case.id});
            }
            var module = buildStructuredDirectModule(allocator, io, ir_writer_case) catch |err| {
                try fatal(io, "direct IR writer module build failed for {s}: {any}\n", .{ ir_writer_case.id, err });
            };
            defer module.deinit();
            if (target_triple) |triple| {
                _ = target.Triple.parse(triple) catch {
                    try fatal(io, "invalid target triple: {s}\n", .{triple});
                };
                if (module.target_triple == null) module.target_triple = triple;
            }
            try runStructuredDirectAcceptedPipeline(allocator, io, &module, init.environ_map, ir_writer_case);
            try prepareArtifact(allocator, io, &module, input);
            try prepareForCodegen(allocator, io, &module, optimization);
            try emitCodegenModule(allocator, io, module, emit, target_triple, .{
                .quiet = quiet,
                .report_all_failures = report_all_codegen_failures,
                .generic_cfg_selector = true,
                .resolve_direct_definitions = true,
                .codegen_reachable = codegen_reachable,
                .profile = profile,
                .owner_output = owner_path,
            });
            return;
        }
    }

    var module = blk: {
        const scope = profiling.enter(profile, .parse);
        defer scope.end();
        break :blk try ir.Module.parse(allocator, input);
    };
    defer module.deinit();
    if (target_triple) |triple| {
        _ = target.Triple.parse(triple) catch {
            try fatal(io, "invalid target triple: {s}\n", .{triple});
        };
        if (module.target_triple == null) module.target_triple = triple;
    }
    if (target_datalayout) |datalayout| {
        _ = target.DataLayout.parse(datalayout) catch {
            try fatal(io, "invalid target datalayout: {s}\n", .{datalayout});
        };
        if (module.target_datalayout == null) module.target_datalayout = datalayout;
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    const stdout = if (quiet) &discard_writer.writer else &stdout_writer.interface;

    if (emit == .@"asm" or emit == .obj or emit == .selection_owner_manifest) {
        try prepareForCodegen(allocator, io, &module, optimization);
        try emitCodegenModule(allocator, io, module, emit, target_triple, .{
            .quiet = quiet,
            .report_all_failures = report_all_codegen_failures,
            .generic_cfg_selector = generic_cfg_selector,
            .codegen_reachable = codegen_reachable,
            .profile = profile,
            .owner_output = owner_path,
        });
        return;
    }

    var ir_options = optimization;
    ir_options.optimization = pass_list;
    try compilation.prepare(allocator, io, &module, stdout, ir_options);
    if (!trace and !quiet) try module.print(stdout);
    try stdout.flush();
}

fn canonicalOutputPath(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![:0]u8 {
    return std.Io.Dir.cwd().realPathFileAlloc(io, path, allocator) catch |err| switch (err) {
        error.FileNotFound => blk: {
            const parent = try std.Io.Dir.cwd().realPathFileAlloc(io, std.fs.path.dirname(path) orelse ".", allocator);
            defer allocator.free(parent);
            break :blk try std.fs.path.joinZ(allocator, &.{ parent, std.fs.path.basename(path) });
        },
        else => return err,
    };
}

fn sameOutputPath(allocator: std.mem.Allocator, io: std.Io, left: []const u8, right: []const u8) !bool {
    const a = try canonicalOutputPath(allocator, io, left);
    defer allocator.free(a);
    const b = try canonicalOutputPath(allocator, io, right);
    defer allocator.free(b);
    return std.mem.eql(u8, a, b);
}

fn prepareArtifact(allocator: std.mem.Allocator, io: std.Io, module: *ir.Module, input: []const u8) !void {
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.File.stderr().writerStreaming(io, &buffer);
    try compilation_artifact.prepare(allocator, io, module, &writer.interface, input);
    try writer.interface.flush();
}

fn prepareForCodegen(allocator: std.mem.Allocator, io: std.Io, module: *ir.Module, options: compilation.Options) !void {
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.File.stderr().writerStreaming(io, &buffer);
    try compilation.prepare(allocator, io, module, &writer.interface, options);
    try writer.interface.flush();
}

fn envFlag(environ: *const std.process.Environ.Map, name: []const u8) bool {
    const value = environ.get(name) orelse return false;
    return std.mem.eql(u8, value, "1") or
        std.mem.eql(u8, value, "true") or
        std.mem.eql(u8, value, "TRUE") or
        std.mem.eql(u8, value, "yes") or
        std.mem.eql(u8, value, "YES");
}

fn reportAirLowering(
    io: std.Io,
    air_module: zae.Module,
    lowered: zal.Result,
) !void {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    const first = if (lowered.unsupported.len == 0) null else lowered.unsupported[0];
    try stderr_writer.interface.print(
        "summary air-lowering contract={s} root={s} mode={s} target={s} discovered_functions={} accepted_functions={} unsupported_functions={} first_unsupported_function={s} first_unsupported_opcode={s} first_unsupported_reason={s}\n",
        .{
            zae.contract_name,
            air_module.root_source,
            air_module.mode,
            air_module.target,
            air_module.functions.len,
            lowered.accepted_functions,
            lowered.unsupported.len,
            if (first) |diagnostic| diagnostic.function else "-",
            if (first) |diagnostic| diagnostic.opcode else "-",
            if (first) |diagnostic| @tagName(diagnostic.reason) else "-",
        },
    );
    try stderr_writer.interface.flush();
}

fn parseInputLimit(text: []const u8) !usize {
    const limit = try std.fmt.parseInt(usize, text, 10);
    if (limit == 0) return error.InvalidInputLimit;
    return limit;
}
