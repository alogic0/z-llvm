const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_lowering = @import("zig_air_lowering.zig");
const codegen = @import("codegen.zig");
const mc = @import("mc.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseOptions(init.minimal.args);
    const mode = options.mode;

    const debug_dump_ir_source = init.minimal.environ.getAlloc(allocator, "ZLLVM_DEBUG_DUMP_IR_SOURCE") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (debug_dump_ir_source) |value| allocator.free(value);
    const debug_codegen_paths_value = init.minimal.environ.getAlloc(allocator, "ZLLVM_DEBUG_CODEGEN_PATHS") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (debug_codegen_paths_value) |value| allocator.free(value);
    const debug_codegen_paths = debug_codegen_paths_value != null;

    const zig_emitter_env = init.minimal.environ.getAlloc(allocator, "ZIG_EMITTER") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (zig_emitter_env) |value| allocator.free(value);
    const zig_emitter = zig_emitter_env orelse "../ziglang/build/stage4/bin/zig";
    std.Io.Dir.cwd().access(io, zig_emitter, .{ .execute = true }) catch {
        return error.MissingZigAirEmitter;
    };

    const sources = try collectSources(allocator, io, options.corpus);
    defer {
        for (sources) |source| allocator.free(source);
        allocator.free(sources);
    }
    const temp_path = try std.fmt.allocPrint(allocator, "tmp/uncurated_zig_air_{s}_{}", .{ mode.lowerName(), std.os.linux.getpid() });
    defer allocator.free(temp_path);
    try std.Io.Dir.cwd().createDirPath(io, temp_path);
    defer std.Io.Dir.cwd().deleteTree(io, temp_path) catch {};

    var unsupported_counts = std.StringHashMap(usize).init(allocator);
    defer {
        var key_iterator = unsupported_counts.keyIterator();
        while (key_iterator.next()) |key| allocator.free(key.*);
        unsupported_counts.deinit();
    }
    var typed_v2_fallback_counts = std.StringHashMap(usize).init(allocator);
    defer {
        var key_iterator = typed_v2_fallback_counts.keyIterator();
        while (key_iterator.next()) |key| allocator.free(key.*);
        typed_v2_fallback_counts.deinit();
    }

    var source_rows: usize = 0;
    var discovered_functions: usize = 0;
    var structured_functions: usize = 0;
    var generic_codegen_functions: usize = 0;
    var structured_air_v1_functions: usize = 0;
    var legacy_air_text_lowering_functions: usize = 0;
    var generic_lowering_functions: usize = 0;
    var shape_recognizer_functions: usize = 0;
    var generic_cfg_functions: usize = 0;
    var structural_matcher_functions: usize = 0;
    var object_emitted_functions: usize = 0;
    var inspected_objects: usize = 0;
    var relocation_rows: usize = 0;
    var tls_rows: usize = 0;
    var undefined_import_rows: usize = 0;
    var native_link_accepted_rows: usize = 0;
    var executable_ok_rows: usize = 0;
    var link_only_rows: usize = 0;
    var runtime_boundary_rows: usize = 0;
    var unsupported_zig_linker_feature_rows: usize = 0;
    var unsupported_functions: usize = 0;
    var codegen_failures: usize = 0;
    var structured_air_v2_functions: usize = 0;
    var typed_air_type_functions: usize = 0;
    var typed_air_operand_functions: usize = 0;
    var typed_v2_fallback_functions: usize = 0;
    var object_failures: usize = 0;
    var native_link_failures: usize = 0;
    var first_unsupported_source: ?[]const u8 = null;
    defer if (first_unsupported_source) |value| allocator.free(value);
    var first_unsupported_function: ?[]const u8 = null;
    defer if (first_unsupported_function) |value| allocator.free(value);
    var first_unsupported_opcode: ?[]const u8 = null;
    defer if (first_unsupported_opcode) |value| allocator.free(value);
    var first_typed_v2_fallback_function: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_function) |value| allocator.free(value);
    var first_typed_v2_fallback_opcode: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_opcode) |value| allocator.free(value);
    var first_typed_v2_fallback_data_kind: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_data_kind) |value| allocator.free(value);
    var first_typed_v2_fallback_reason: ?[]const u8 = null;
    defer if (first_typed_v2_fallback_reason) |value| allocator.free(value);

    for (sources) |source| {
        const stem = std.fs.path.stem(source);
        const descriptor_name = try std.fmt.allocPrint(allocator, "{s}.air", .{stem});
        defer allocator.free(descriptor_name);
        const descriptor_path = try std.fs.path.join(allocator, &.{ temp_path, descriptor_name });
        defer allocator.free(descriptor_path);

        var env_map = try cloneEnvironment(allocator, init.environ_map);
        defer env_map.deinit();
        try env_map.put("ZLLVM_AIR_EXPORT_PATH", descriptor_path);
        const argv = [_][]const u8{
            zig_emitter,
            "build-obj",
            "-fllvm",
            "-flibllvm",
            "-fno-emit-bin",
            mode.zigOptimizeArg(),
            "-target",
            "x86_64-linux-gnu",
            source,
        };
        const emit_result = try std.process.run(allocator, io, .{
            .argv = &argv,
            .environ_map = &env_map,
            .stdout_limit = .limited(16 * 1024 * 1024),
            .stderr_limit = .limited(16 * 1024 * 1024),
        });
        defer {
            allocator.free(emit_result.stdout);
            allocator.free(emit_result.stderr);
        }
        switch (emit_result.term) {
            .exited => |code| if (code != 0) {
                std.debug.print(
                    "air-export-failure source={s} exit_code={} stdout={s} stderr={s}\n",
                    .{ source, code, firstLine(emit_result.stdout), firstLine(emit_result.stderr) },
                );
                return error.ZigAirExportFailed;
            },
            else => {
                std.debug.print(
                    "air-export-failure source={s} term={s} stdout={s} stderr={s}\n",
                    .{ source, termName(emit_result.term), firstLine(emit_result.stdout), firstLine(emit_result.stderr) },
                );
                return error.ZigAirExportFailed;
            },
        }

        const descriptor = try std.Io.Dir.cwd().readFileAlloc(
            io,
            descriptor_path,
            allocator,
            .limited(32 * 1024 * 1024),
        );
        defer allocator.free(descriptor);
        source_rows += 1;
        var parsed = air_export.parse(allocator, descriptor) catch |err| {
            unsupported_functions += 1;
            try incrementCount(allocator, &unsupported_counts, "parse");
            std.debug.print(
                "unsupported-air source={s} function=- opcode=parse reason={s}\n",
                .{ source, @errorName(err) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, "-");
                first_unsupported_opcode = try allocator.dupe(u8, "parse");
            }
            continue;
        };
        defer parsed.deinit();
        var lowered = air_lowering.lowerCompatible(allocator, parsed) catch |err| {
            unsupported_functions += 1;
            try incrementCount(allocator, &unsupported_counts, "lowering");
            std.debug.print(
                "unsupported-air source={s} function=- opcode=lowering reason={s}\n",
                .{ source, @errorName(err) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, "-");
                first_unsupported_opcode = try allocator.dupe(u8, "lowering");
            }
            continue;
        };
        defer lowered.deinit();

        if (debug_dump_ir_source) |dump_source| {
            if (std.mem.indexOf(u8, source, dump_source) != null) {
                var aw: std.Io.Writer.Allocating = .init(allocator);
                defer aw.deinit();
                lowered.module.print(&aw.writer) catch {};
                std.debug.print("debug-dump-ir source={s}\n{s}\n", .{ source, aw.written() });
            }
        }

        discovered_functions += rootFunctionCount(parsed);
        structured_functions += lowered.accepted_functions;
        structured_air_v1_functions += lowered.structured_air_v1_functions;
        structured_air_v2_functions += lowered.structured_air_v2_functions;
        typed_air_type_functions += lowered.typed_air_type_functions;
        typed_air_operand_functions += lowered.typed_air_operand_functions;
        legacy_air_text_lowering_functions += lowered.legacy_air_text_lowering_functions;
        generic_lowering_functions += lowered.generic_lowering_functions;
        shape_recognizer_functions += lowered.shape_recognizer_functions;
        typed_v2_fallback_functions += lowered.typed_v2_fallbacks.len;
        for (lowered.typed_v2_fallbacks) |fallback| {
            const fallback_key = try std.fmt.allocPrint(allocator, "{s}:{s}:{s}", .{
                fallback.reason,
                fallback.opcode,
                fallback.data_kind,
            });
            defer allocator.free(fallback_key);
            try incrementCount(allocator, &typed_v2_fallback_counts, fallback_key);
            std.debug.print(
                "typed-v2-fallback source={s} function={s} opcode={s} data_kind={s} reason={s}\n",
                .{ source, fallback.function, fallback.opcode, fallback.data_kind, fallback.reason },
            );
            if (first_typed_v2_fallback_function == null) {
                first_typed_v2_fallback_function = try allocator.dupe(u8, fallback.function);
                first_typed_v2_fallback_opcode = try allocator.dupe(u8, fallback.opcode);
                first_typed_v2_fallback_data_kind = try allocator.dupe(u8, fallback.data_kind);
                first_typed_v2_fallback_reason = try allocator.dupe(u8, fallback.reason);
            }
        }
        unsupported_functions += lowered.unsupported.len;
        for (lowered.unsupported) |diagnostic| {
            if (diagnostic.reason == .opcode or diagnostic.reason == .control_flow_shape) {
                try incrementCount(allocator, &unsupported_counts, diagnostic.opcode);
            }
            std.debug.print(
                "unsupported-air source={s} function={s} opcode={s} reason={s}\n",
                .{ source, diagnostic.function, diagnostic.opcode, @tagName(diagnostic.reason) },
            );
            if (first_unsupported_source == null) {
                first_unsupported_source = try allocator.dupe(u8, source);
                first_unsupported_function = try allocator.dupe(u8, diagnostic.function);
                first_unsupported_opcode = try allocator.dupe(u8, diagnostic.opcode);
            }
        }
        var machines: std.ArrayList(codegen.x86_64.MachineFunction) = .empty;
        defer {
            for (machines.items) |*machine| machine.deinit(allocator);
            machines.deinit(allocator);
        }
        for (lowered.module.functions.items) |function| {
            const machine = codegen.x86_64.lowerFunction(
                allocator,
                "x86_64-unknown-linux-gnu",
                function,
            ) catch |err| {
                codegen_failures += 1;
                std.debug.print(
                    "unsupported-codegen source={s} function={s} error={s}\n",
                    .{ source, function.name, @errorName(err) },
                );
                continue;
            };
            try machines.append(allocator, machine);
            generic_codegen_functions += 1;
            const codegen_path = machines.items[machines.items.len - 1].codegen_path;
            if (debug_codegen_paths) {
                std.debug.print(
                    "codegen-path source={s} function={s} path={s}\n",
                    .{ source, function.name, @tagName(codegen_path) },
                );
            }
            switch (codegen_path) {
                .generic_cfg => generic_cfg_functions += 1,
                .structural_matcher => structural_matcher_functions += 1,
            }
        }
        if ((options.object_progress or options.object_inspection or options.native_link_progress or options.executable_progress) and machines.items.len != 0) {
            const object = mc.elf.buildObjectWithModuleData(
                allocator,
                machines.items,
                lowered.module.aliases.items,
                lowered.module.globals.items,
            ) catch |err| {
                object_failures += 1;
                std.debug.print(
                    "unsupported-object source={s} error={s}\n",
                    .{ source, @errorName(err) },
                );
                continue;
            };
            defer allocator.free(object);
            object_emitted_functions += machines.items.len;

            if (options.object_inspection or options.native_link_progress or options.executable_progress) {
                const object_name = try std.fmt.allocPrint(allocator, "{s}.o", .{stem});
                defer allocator.free(object_name);
                const object_path = try std.fs.path.join(allocator, &.{ temp_path, object_name });
                defer allocator.free(object_path);
                try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = object });

                if (options.object_inspection) {
                    const inspection = try inspectObject(allocator, io, object_path, mode, source);
                    inspected_objects += 1;
                    if (inspection.has_relocations) relocation_rows += 1;
                    if (inspection.has_tls) tls_rows += 1;
                    if (inspection.has_undefined_imports) undefined_import_rows += 1;
                }

                if (!(options.native_link_progress or options.executable_progress)) continue;

                const exe_name = try std.fmt.allocPrint(allocator, "{s}.link", .{stem});
                defer allocator.free(exe_name);
                const exe_path = try std.fs.path.join(allocator, &.{ temp_path, exe_name });
                defer allocator.free(exe_path);

                const harness = if (options.executable_progress) executableHarnessForSource(source) else null;
                const link_result = if (harness) |executable_harness| link_result: {
                    const harness_body = try executableHarnessBody(allocator, executable_harness);
                    defer if (executable_harness.c_body == null) allocator.free(harness_body);
                    break :link_result try linkObjectWithHarness(allocator, io, zig_emitter, mode, object_path, exe_path, harness_body);
                } else try nativeLinkObject(allocator, io, zig_emitter, mode, object_path, exe_path);
                defer {
                    allocator.free(link_result.stdout);
                    allocator.free(link_result.stderr);
                }
                if (termOk(link_result.term)) {
                    if (harness) |executable_harness| {
                        const run_result = try runExecutable(allocator, io, exe_path);
                        defer {
                            allocator.free(run_result.stdout);
                            allocator.free(run_result.stderr);
                        }
                        if (termOk(run_result.term)) {
                            native_link_accepted_rows += 1;
                            executable_ok_rows += 1;
                            std.debug.print(
                                "executable-ok source={s} function=module abi={s} expected={s} actual=exit0\n",
                                .{ source, executable_harness.abi_mode, executable_harness.expected },
                            );
                        } else {
                            native_link_failures += 1;
                            std.debug.print(
                                "executable-failure source={s} function=module abi={s} expected={s} actual={s} stderr={s}\n",
                                .{ source, executable_harness.abi_mode, executable_harness.expected, termName(run_result.term), firstLine(run_result.stderr) },
                            );
                        }
                    } else {
                        native_link_accepted_rows += 1;
                        link_only_rows += 1;
                        if (options.executable_progress) {
                            std.debug.print(
                                "link-only source={s} function=module abi=unstable expected=- actual=linked category=no-stable-executable-harness\n",
                                .{source},
                            );
                        }
                    }
                } else switch (classifyNativeLinkFailure(link_result.stderr)) {
                    .runtime_boundary => |symbol| {
                        runtime_boundary_rows += 1;
                        std.debug.print(
                            "native-link-boundary source={s} function=module category=runtime/compiler-rt/libc symbol={s}\n",
                            .{ source, symbol },
                        );
                    },
                    .unsupported_zig_linker_feature => |category| {
                        unsupported_zig_linker_feature_rows += 1;
                        std.debug.print(
                            "native-link-boundary source={s} function=module category={s} stderr={s}\n",
                            .{ source, category, firstLine(link_result.stderr) },
                        );
                    },
                    .local_failure => |category| {
                        native_link_failures += 1;
                        std.debug.print(
                            "native-link-failure source={s} function=module category={s} stderr={s}\n",
                            .{ source, category, firstLine(link_result.stderr) },
                        );
                    },
                }
            }
        }
    }

    var top_construct: []const u8 = "-";
    var top_count: usize = 0;
    var iterator = unsupported_counts.iterator();
    while (iterator.next()) |entry| {
        if (entry.value_ptr.* > top_count or
            (entry.value_ptr.* == top_count and std.mem.lessThan(u8, entry.key_ptr.*, top_construct)))
        {
            top_construct = entry.key_ptr.*;
            top_count = entry.value_ptr.*;
        }
    }
    var top_typed_v2_fallback_reason: []const u8 = "-";
    var top_typed_v2_fallback_count: usize = 0;
    var typed_fallback_iterator = typed_v2_fallback_counts.iterator();
    while (typed_fallback_iterator.next()) |entry| {
        if (entry.value_ptr.* > top_typed_v2_fallback_count or
            (entry.value_ptr.* == top_typed_v2_fallback_count and std.mem.lessThan(u8, entry.key_ptr.*, top_typed_v2_fallback_reason)))
        {
            top_typed_v2_fallback_reason = entry.key_ptr.*;
            top_typed_v2_fallback_count = entry.value_ptr.*;
        }
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const air_local_fail: usize = if ((options.corpus == .expanded or options.corpus == .scale or options.corpus == .frontier) and
        (unsupported_functions != 0 or codegen_failures != 0 or typed_v2_fallback_functions != 0 or legacy_air_text_lowering_functions != 0 or shape_recognizer_functions != 0 or
            (options.corpus == .frontier and structural_matcher_functions != 0)))
        1
    else
        0;
    try stdout_writer.interface.print(
        "summary uncurated-zig-air mode={s} corpus={s} target=x86_64-linux-gnu source_rows={} discovered_functions={} structured_functions={} generic_codegen_functions={} generic_cfg_functions={} structural_matcher_functions={} structured_air_v1_functions={} structured_air_v2_functions={} typed_air_type_functions={} typed_air_operand_functions={} legacy_air_text_lowering_functions={} typed_v2_fallback_functions={} generic_lowering_functions={} shape_recognizer_functions={} unsupported_functions={} codegen_failures={} case_id_rows=0 source_fact_classification_rows=0 first_unsupported_source={s} first_unsupported_function={s} first_unsupported_opcode={s} top_unsupported_construct={s} top_unsupported_count={} first_typed_v2_fallback_function={s} first_typed_v2_fallback_opcode={s} first_typed_v2_fallback_data_kind={s} first_typed_v2_fallback_reason={s} top_typed_v2_fallback_reason={s} top_typed_v2_fallback_count={} local_fail={}\n",
        .{
            mode.name(),
            options.corpus.name(),
            source_rows,
            discovered_functions,
            structured_functions,
            generic_codegen_functions,
            generic_cfg_functions,
            structural_matcher_functions,
            structured_air_v1_functions,
            structured_air_v2_functions,
            typed_air_type_functions,
            typed_air_operand_functions,
            legacy_air_text_lowering_functions,
            typed_v2_fallback_functions,
            generic_lowering_functions,
            shape_recognizer_functions,
            unsupported_functions,
            codegen_failures,
            first_unsupported_source orelse "-",
            first_unsupported_function orelse "-",
            first_unsupported_opcode orelse "-",
            top_construct,
            top_count,
            first_typed_v2_fallback_function orelse "-",
            first_typed_v2_fallback_opcode orelse "-",
            first_typed_v2_fallback_data_kind orelse "-",
            first_typed_v2_fallback_reason orelse "-",
            top_typed_v2_fallback_reason,
            top_typed_v2_fallback_count,
            air_local_fail,
        },
    );
    if (options.object_progress) {
        try stdout_writer.interface.print(
            "summary uncurated-zig-air-object mode={s} target=x86_64-linux-gnu object_emitted_functions={} object_failures={} llvm_targetmachine_rows=0 local_fail=0\n",
            .{ mode.name(), object_emitted_functions, object_failures },
        );
    }
    if (options.object_inspection) {
        try stdout_writer.interface.print(
            "summary uncurated-zig-air-object-inspection mode={s} target=x86_64-linux-gnu inspected={} elf64_rel={} relocation_rows={} tls_rows={} undefined_import_rows={} comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0\n",
            .{ mode.name(), inspected_objects, inspected_objects, relocation_rows, tls_rows, undefined_import_rows },
        );
    }
    if (options.native_link_progress) {
        const local_fail: usize = if (native_link_failures == 0 and unsupported_zig_linker_feature_rows == 0) 0 else 1;
        try stdout_writer.interface.print(
            "summary uncurated-zig-air-native-link mode={s} target=x86_64-linux-gnu native_link_accepted_rows={} executable_ok_rows={} link_only_rows={} runtime_boundary_rows={} unsupported_zig_linker_feature_rows={} native_link_failures={} llvm_targetmachine_rows=0 lld_rows=0 local_fail={}\n",
            .{
                mode.name(),
                native_link_accepted_rows,
                executable_ok_rows,
                link_only_rows,
                runtime_boundary_rows,
                unsupported_zig_linker_feature_rows,
                native_link_failures,
                local_fail,
            },
        );
    }
    if (options.executable_progress) {
        const local_fail: usize = if (native_link_failures == 0 and unsupported_zig_linker_feature_rows == 0) 0 else 1;
        try stdout_writer.interface.print(
            "summary uncurated-zig-air-executable mode={s} target=x86_64-linux-gnu native_link_accepted_rows={} executable_ok_rows={} link_only_rows={} runtime_boundary_rows={} unsupported_zig_linker_feature_rows={} native_link_failures={} llvm_targetmachine_rows=0 lld_rows=0 local_fail={}\n",
            .{
                mode.name(),
                native_link_accepted_rows,
                executable_ok_rows,
                link_only_rows,
                runtime_boundary_rows,
                unsupported_zig_linker_feature_rows,
                native_link_failures,
                local_fail,
            },
        );
    }
    try stdout_writer.interface.flush();

    if (air_local_fail != 0) return error.ExpandedCorpusLocalFailure;
    if ((options.native_link_progress or options.executable_progress) and
        (native_link_failures != 0 or unsupported_zig_linker_feature_rows != 0))
    {
        return error.NativeLinkLocalFailure;
    }

    if (options.strict_finish) {
        try validateStrictFinish(.{
            .mode = mode,
            .corpus = options.corpus,
            .object_progress = options.object_progress,
            .source_rows = source_rows,
            .discovered_functions = discovered_functions,
            .structured_functions = structured_functions,
            .generic_codegen_functions = generic_codegen_functions,
            .generic_cfg_functions = generic_cfg_functions,
            .structured_air_v2_functions = structured_air_v2_functions,
            .typed_air_operand_functions = typed_air_operand_functions,
            .legacy_air_text_lowering_functions = legacy_air_text_lowering_functions,
            .typed_v2_fallback_functions = typed_v2_fallback_functions,
            .generic_lowering_functions = generic_lowering_functions,
            .shape_recognizer_functions = shape_recognizer_functions,
            .unsupported_functions = unsupported_functions,
            .codegen_failures = codegen_failures,
            .object_emitted_functions = object_emitted_functions,
            .object_failures = object_failures,
        });
    }
}

fn rootFunctionCount(module: air_export.Module) usize {
    const root_stem = std.fs.path.stem(module.root_source);
    var count: usize = 0;
    for (module.functions) |function| {
        if (air_lowering.isRootSourceFunction(root_stem, function.name)) count += 1;
    }
    return count;
}

const Options = struct {
    mode: Mode = .ReleaseFast,
    corpus: Corpus = .inputs,
    object_progress: bool = false,
    object_inspection: bool = false,
    native_link_progress: bool = false,
    executable_progress: bool = false,
    strict_finish: bool = false,
};

const Mode = enum {
    ReleaseFast,
    ReleaseSafe,
    ReleaseSmall,

    fn name(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "ReleaseFast",
            .ReleaseSafe => "ReleaseSafe",
            .ReleaseSmall => "ReleaseSmall",
        };
    }

    fn lowerName(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "releasefast",
            .ReleaseSafe => "releasesafe",
            .ReleaseSmall => "releasesmall",
        };
    }

    fn zigOptimizeArg(self: Mode) []const u8 {
        return switch (self) {
            .ReleaseFast => "-OReleaseFast",
            .ReleaseSafe => "-OReleaseSafe",
            .ReleaseSmall => "-OReleaseSmall",
        };
    }
};

const Corpus = enum {
    inputs,
    broad,
    expanded,
    scale,
    frontier,

    fn name(self: Corpus) []const u8 {
        return switch (self) {
            .inputs => "inputs",
            .broad => "broad",
            .expanded => "expanded",
            .scale => "scale",
            .frontier => "frontier",
        };
    }
};

fn parseOptions(args: std.process.Args) !Options {
    var options: Options = .{};
    var iterator = std.process.Args.Iterator.init(args);
    _ = iterator.skip();
    while (iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "--mode=ReleaseFast")) {
            options.mode = .ReleaseFast;
        } else if (std.mem.eql(u8, arg, "--mode=ReleaseSafe")) {
            options.mode = .ReleaseSafe;
        } else if (std.mem.eql(u8, arg, "--mode=ReleaseSmall")) {
            options.mode = .ReleaseSmall;
        } else if (std.mem.eql(u8, arg, "--corpus=inputs")) {
            options.corpus = .inputs;
        } else if (std.mem.eql(u8, arg, "--corpus=broad")) {
            options.corpus = .broad;
        } else if (std.mem.eql(u8, arg, "--corpus=expanded")) {
            options.corpus = .expanded;
        } else if (std.mem.eql(u8, arg, "--corpus=scale")) {
            options.corpus = .scale;
        } else if (std.mem.eql(u8, arg, "--corpus=frontier")) {
            options.corpus = .frontier;
        } else if (std.mem.eql(u8, arg, "--object-progress")) {
            options.object_progress = true;
        } else if (std.mem.eql(u8, arg, "--object-inspection")) {
            options.object_inspection = true;
        } else if (std.mem.eql(u8, arg, "--native-link-progress")) {
            options.native_link_progress = true;
        } else if (std.mem.eql(u8, arg, "--executable-progress")) {
            options.executable_progress = true;
        } else if (std.mem.eql(u8, arg, "--strict-finish")) {
            options.strict_finish = true;
        } else {
            return error.UnsupportedUncuratedAirArgument;
        }
    }
    return options;
}

const StrictFinishCounters = struct {
    mode: Mode,
    corpus: Corpus,
    object_progress: bool,
    source_rows: usize,
    discovered_functions: usize,
    structured_functions: usize,
    generic_codegen_functions: usize,
    generic_cfg_functions: usize,
    structured_air_v2_functions: usize,
    typed_air_operand_functions: usize,
    legacy_air_text_lowering_functions: usize,
    typed_v2_fallback_functions: usize,
    generic_lowering_functions: usize,
    shape_recognizer_functions: usize,
    unsupported_functions: usize,
    codegen_failures: usize,
    object_emitted_functions: usize,
    object_failures: usize,
};

fn validateStrictFinish(counters: StrictFinishCounters) !void {
    const expected_source_rows: usize, const expected_functions: usize = switch (counters.corpus) {
        .broad => .{ 101, 152 },
        .expanded => .{ 109, 199 },
        .inputs, .scale, .frontier => {
            std.debug.print(
                "strict-finish-failure mode={s} field=corpus expected=broad-or-expanded actual={s}\n",
                .{ counters.mode.name(), counters.corpus.name() },
            );
            return error.StrictFinishFailed;
        },
    };
    try expectStrict(counters.mode, "source_rows", counters.source_rows, expected_source_rows);
    try expectStrict(counters.mode, "discovered_functions", counters.discovered_functions, expected_functions);
    try expectStrict(counters.mode, "structured_functions", counters.structured_functions, expected_functions);
    try expectStrict(counters.mode, "generic_codegen_functions", counters.generic_codegen_functions, expected_functions);
    if (counters.generic_cfg_functions == 0) {
        std.debug.print(
            "strict-finish-failure mode={s} field=generic_cfg_functions expected=>0 actual=0\n",
            .{counters.mode.name()},
        );
        return error.StrictFinishFailed;
    }
    try expectStrict(counters.mode, "structured_air_v2_functions", counters.structured_air_v2_functions, expected_functions);
    try expectStrict(counters.mode, "typed_air_operand_functions", counters.typed_air_operand_functions, expected_functions);
    try expectStrict(counters.mode, "legacy_air_text_lowering_functions", counters.legacy_air_text_lowering_functions, 0);
    try expectStrict(counters.mode, "typed_v2_fallback_functions", counters.typed_v2_fallback_functions, 0);
    try expectStrict(counters.mode, "generic_lowering_functions", counters.generic_lowering_functions, expected_functions);
    try expectStrict(counters.mode, "shape_recognizer_functions", counters.shape_recognizer_functions, 0);
    try expectStrict(counters.mode, "unsupported_functions", counters.unsupported_functions, 0);
    try expectStrict(counters.mode, "codegen_failures", counters.codegen_failures, 0);
    if (counters.object_progress) {
        try expectStrict(counters.mode, "object_emitted_functions", counters.object_emitted_functions, expected_functions);
        try expectStrict(counters.mode, "object_failures", counters.object_failures, 0);
    }
}

fn expectStrict(mode: Mode, field: []const u8, actual: usize, expected: usize) !void {
    if (actual == expected) return;
    std.debug.print(
        "strict-finish-failure mode={s} field={s} expected={} actual={}\n",
        .{ mode.name(), field, expected, actual },
    );
    return error.StrictFinishFailed;
}

const ObjectInspection = struct {
    has_relocations: bool,
    has_tls: bool,
    has_undefined_imports: bool,
};

fn inspectObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    object_path: []const u8,
    mode: Mode,
    source: []const u8,
) !ObjectInspection {
    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", object_path };
    const readelf_result = try std.process.run(allocator, io, .{
        .argv = &readelf_argv,
        .stdout_limit = .limited(32 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer {
        allocator.free(readelf_result.stdout);
        allocator.free(readelf_result.stderr);
    }
    if (!termOk(readelf_result.term)) {
        std.debug.print(
            "object-inspection-failure source={s} mode={s} category=readelf stderr={s}\n",
            .{ source, mode.name(), firstLine(readelf_result.stderr) },
        );
        return error.ObjectInspectionFailed;
    }

    const objdump_argv = [_][]const u8{ "objdump", "-dr", object_path };
    const objdump_result = try std.process.run(allocator, io, .{
        .argv = &objdump_argv,
        .stdout_limit = .limited(32 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer {
        allocator.free(objdump_result.stdout);
        allocator.free(objdump_result.stderr);
    }
    if (!termOk(objdump_result.term)) {
        std.debug.print(
            "object-inspection-failure source={s} mode={s} category=objdump stderr={s}\n",
            .{ source, mode.name(), firstLine(objdump_result.stderr) },
        );
        return error.ObjectInspectionFailed;
    }

    try validateObjectHeader(mode, source, readelf_result.stdout);
    try validateObjectSections(mode, source, readelf_result.stdout);
    try validateObjectSymbols(mode, source, readelf_result.stdout);
    try validateObjectRelocations(mode, source, readelf_result.stdout);
    try validateObjectDisassembly(mode, source, objdump_result.stdout);

    return .{
        .has_relocations = std.mem.indexOf(u8, readelf_result.stdout, "R_X86_64_") != null,
        .has_tls = std.mem.indexOf(u8, readelf_result.stdout, " TLS     GLOBAL DEFAULT") != null or
            std.mem.indexOf(u8, readelf_result.stdout, "R_X86_64_TPOFF32") != null,
        .has_undefined_imports = hasUndefinedImports(readelf_result.stdout),
    };
}

fn validateObjectHeader(mode: Mode, source: []const u8, readelf: []const u8) !void {
    if (std.mem.indexOf(u8, readelf, "Class:                             ELF64") == null)
        return objectInspectionFailure(mode, source, "object-format", "missing ELF64 header class");
    if (std.mem.indexOf(u8, readelf, "Data:                              2's complement, little endian") == null)
        return objectInspectionFailure(mode, source, "object-format", "missing little-endian ELF data marker");
    if (std.mem.indexOf(u8, readelf, "Type:                              REL (Relocatable file)") == null)
        return objectInspectionFailure(mode, source, "object-format", "object is not ELF REL relocatable");
    if (std.mem.indexOf(u8, readelf, "Machine:                           Advanced Micro Devices X86-64") == null)
        return objectInspectionFailure(mode, source, "object-format", "object machine is not x86-64");
    if (std.mem.indexOf(u8, readelf, "Number of program headers:         0") == null)
        return objectInspectionFailure(mode, source, "section-layout", "relocatable handoff object must not contain program headers");
}

fn validateObjectSections(mode: Mode, source: []const u8, readelf: []const u8) !void {
    if (!sectionLineHas(readelf, ".text", "PROGBITS", "AX", "16"))
        return objectInspectionFailure(mode, source, "section-flag-alignment", "missing .text PROGBITS AX align=16 section");
    if (!sectionLineHas(readelf, ".data", "PROGBITS", "WA", "16"))
        return objectInspectionFailure(mode, source, "section-flag-alignment", "missing .data PROGBITS WA align=16 section");
    if (!sectionLineHas(readelf, ".tdata", "PROGBITS", "WAT", "4"))
        return objectInspectionFailure(mode, source, "tls-model", "missing .tdata PROGBITS WAT align=4 section");
    if (!sectionLineHas(readelf, ".rela.text", "RELA", "", "8"))
        return objectInspectionFailure(mode, source, "relocation", "missing .rela.text RELA align=8 section");
    if (!sectionLineHas(readelf, ".symtab", "SYMTAB", "", "8"))
        return objectInspectionFailure(mode, source, "symbol", "missing .symtab SYMTAB align=8 section");
    if (!sectionLineHas(readelf, ".strtab", "STRTAB", "", "1"))
        return objectInspectionFailure(mode, source, "section-layout", "missing .strtab STRTAB align=1 section");
    if (!sectionLineHas(readelf, ".shstrtab", "STRTAB", "", "1"))
        return objectInspectionFailure(mode, source, "section-layout", "missing .shstrtab STRTAB align=1 section");
    if (std.mem.indexOf(u8, readelf, ".group") != null or std.mem.indexOf(u8, readelf, "COMDAT") != null)
        return objectInspectionFailure(mode, source, "comdat", "COMDAT/group sections are outside the current broad AIR handoff contract");
    if (std.mem.indexOf(u8, readelf, ".eh_frame") != null)
        return objectInspectionFailure(mode, source, "unwind-boundary", ".eh_frame is outside the current broad AIR handoff contract");
}

fn sectionLineHas(readelf: []const u8, name: []const u8, kind: []const u8, flags: []const u8, alignment: []const u8) bool {
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, name) == null) continue;
        if (std.mem.indexOf(u8, line, kind) == null) continue;
        if (flags.len != 0 and std.mem.indexOf(u8, line, flags) == null) continue;
        if (!std.mem.endsWith(u8, std.mem.trim(u8, line, " \t\r"), alignment)) continue;
        return true;
    }
    return false;
}

fn validateObjectSymbols(mode: Mode, source: []const u8, readelf: []const u8) !void {
    if (std.mem.indexOf(u8, readelf, "Symbol table '.symtab' contains") == null)
        return objectInspectionFailure(mode, source, "symbol", "missing symbol table dump");
    var has_global_function = false;
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " FUNC    GLOBAL DEFAULT") != null) has_global_function = true;
        if (std.mem.indexOf(u8, line, " UND ") != null and std.mem.indexOf(u8, line, "NOTYPE  LOCAL  DEFAULT  UND") == null) {
            if (std.mem.indexOf(u8, line, "GLOBAL DEFAULT  UND") == null)
                return objectInspectionFailure(mode, source, "bad-symbol-binding-type", "undefined import is not GLOBAL DEFAULT UND");
        }
    }
    if (!has_global_function)
        return objectInspectionFailure(mode, source, "symbol", "missing global function symbol");
    if (std.mem.indexOf(u8, readelf, "R_X86_64_TPOFF32") != null and std.mem.indexOf(u8, readelf, " TLS     GLOBAL DEFAULT") == null)
        return objectInspectionFailure(mode, source, "tls-model", "TLS relocation exists without a TLS GLOBAL symbol");
}

fn validateObjectRelocations(mode: Mode, source: []const u8, readelf: []const u8) !void {
    var rest = readelf;
    while (std.mem.indexOf(u8, rest, "R_X86_64_")) |index| {
        const start = index;
        var end = start;
        while (end < rest.len and (std.ascii.isAlphanumeric(rest[end]) or rest[end] == '_')) : (end += 1) {}
        const relocation = rest[start..end];
        if (!isAllowedRelocation(relocation)) {
            std.debug.print(
                "object-inspection-failure source={s} mode={s} category=missing-relocation-support relocation={s}\n",
                .{ source, mode.name(), relocation },
            );
            return error.ObjectInspectionFailed;
        }
        rest = rest[end..];
    }
}

fn isAllowedRelocation(relocation: []const u8) bool {
    return std.mem.eql(u8, relocation, "R_X86_64_PC32") or
        std.mem.eql(u8, relocation, "R_X86_64_PLT32") or
        std.mem.eql(u8, relocation, "R_X86_64_TPOFF32");
}

fn validateObjectDisassembly(mode: Mode, source: []const u8, objdump: []const u8) !void {
    if (std.mem.indexOf(u8, objdump, "file format elf64-x86-64") == null)
        return objectInspectionFailure(mode, source, "object-format", "objdump did not recognize elf64-x86-64");
    if (std.mem.indexOf(u8, objdump, "Disassembly of section .text:") == null)
        return objectInspectionFailure(mode, source, "section-layout", "objdump missing .text disassembly");
}

fn hasUndefinedImports(readelf: []const u8) bool {
    var lines = std.mem.splitScalar(u8, readelf, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " UND ") != null and std.mem.indexOf(u8, line, "NOTYPE  LOCAL  DEFAULT  UND") == null) return true;
    }
    return false;
}

fn objectInspectionFailure(mode: Mode, source: []const u8, category: []const u8, message: []const u8) error{ObjectInspectionFailed} {
    std.debug.print(
        "object-inspection-failure source={s} mode={s} category={s}: {s}\n",
        .{ source, mode.name(), category, message },
    );
    return error.ObjectInspectionFailed;
}

const ExecutableHarness = struct {
    abi_mode: []const u8,
    expected: []const u8,
    c_body: ?[]const u8 = null,
    module_main: ?ModuleMainHarness = null,
};

const ModuleMainHarness = struct {
    source: []const u8,
    return_type: ModuleMainReturnType = .c_int,
    expected_exit: i64 = 0,
};

const ModuleMainReturnType = enum {
    c_int,
    c_long,

    fn cType(self: ModuleMainReturnType) []const u8 {
        return switch (self) {
            .c_int => "int",
            .c_long => "long",
        };
    }
};

fn executableHarnessForSource(source: []const u8) ?ExecutableHarness {
    if (std.mem.eql(u8, source, "test/zig/inputs/aggregate_abi.zig")) return .{ .abi_mode = "c-stable-module", .expected = "aggregate ABI pair", .c_body =
    \\struct Pair { int a; int b; };
    \\extern struct Pair z_make_pair(int, int) __asm__("aggregate_abi.make_pair");
    \\extern int z_pair_first(struct Pair) __asm__("aggregate_abi.pair_first");
    \\int main(void) {
    \\    struct Pair pair = z_make_pair(11, 31);
    \\    if (pair.a != 11) return 1;
    \\    if (pair.b != 31) return 2;
    \\    if (z_pair_first(pair) != 11) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/aggregates.zig")) return .{ .abi_mode = "c-stable-module", .expected = "array/struct/slice/optional/error-union checks", .c_body =
    \\struct Pair { int a; int b; };
    \\extern int z_array_sum(int, int, int) __asm__("aggregates.array_sum");
    \\extern int z_struct_sum(const struct Pair *) __asm__("aggregates.struct_sum");
    \\extern int z_slice_sum(const int *, unsigned long) __asm__("aggregates.slice_sum");
    \\extern int z_optional_payload(int, int) __asm__("aggregates.optional_payload");
    \\extern int z_error_union_payload(int) __asm__("aggregates.error_union_payload");
    \\int main(void) {
    \\    int values[4] = { 1, 2, 3, 4 };
    \\    struct Pair pair = { 8, 13 };
    \\    if (z_array_sum(2, 3, 4) != 9) return 1;
    \\    if (z_struct_sum(&pair) != 21) return 2;
    \\    if (z_slice_sum(values, 4) != 10) return 3;
    \\    if (z_optional_payload(1, 99) != 99) return 4;
    \\    if (z_optional_payload(0, 99) != -1) return 5;
    \\    if (z_error_union_payload(0) != 7) return 6;
    \\    if (z_error_union_payload(1) != -1) return 7;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/atomics_inline_asm_debug.zig")) return .{ .abi_mode = "c-stable-module", .expected = "atomic add, inline asm barrier, debug location", .c_body =
    \\extern unsigned z_atomic_add(unsigned) __asm__("atomics_inline_asm_debug.atomic_add");
    \\extern int z_inline_asm_barrier(int) __asm__("atomics_inline_asm_debug.inline_asm_barrier");
    \\extern int z_debug_location(int) __asm__("atomics_inline_asm_debug.debug_location");
    \\int main(void) {
    \\    if (z_atomic_add(5) != 0) return 1;
    \\    if (z_atomic_add(7) != 5) return 2;
    \\    if (z_inline_asm_barrier(19) != 19) return 3;
    \\    if (z_debug_location(41) != 42) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/base64_table_lookup.zig")) return .{ .abi_mode = "c-stable-module", .expected = "base64 table lookup", .c_body =
    \\extern int z_base64_table_lookup(unsigned char) __asm__("base64_table_lookup.base64_table_lookup");
    \\void z_base64_table_lookup_oob(unsigned long, unsigned long) __asm__("base64_table_lookup.outOfBounds");
    \\void z_base64_table_lookup_oob(unsigned long index, unsigned long len) { (void)index; (void)len; __builtin_trap(); }
    \\int main(void) {
    \\    if (z_base64_table_lookup(0) != 0) return 1;
    \\    if (z_base64_table_lookup(1) != 4) return 2;
    \\    if (z_base64_table_lookup(2) != 8) return 3;
    \\    if (z_base64_table_lookup(7) != 12) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/control_flow_calls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "call chain and loop sum", .c_body =
    \\extern int z_call_chain(int) __asm__("control_flow_calls.call_chain");
    \\extern int z_loop_sum(int) __asm__("control_flow_calls.loop_sum");
    \\int main(void) {
    \\    if (z_call_chain(10) != 21) return 1;
    \\    if (z_loop_sum(5) != 10) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/error_switch.zig")) return .{ .abi_mode = "c-stable-module", .expected = "error switch payload", .c_body =
    \\extern int z_error_switch(unsigned char) __asm__("error_switch.error_switch");
    \\int main(void) {
    \\    if (z_error_switch(0) != 0) return 1;
    \\    if (z_error_switch(1) != -1) return 2;
    \\    if (z_error_switch(2) != -2) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/float_compare.zig")) return .{ .abi_mode = "c-stable-module", .expected = "float compare and f64 multiply", .c_body =
    \\#include <stdbool.h>
    \\extern bool z_float_less(float, float) __asm__("float_compare.float_less");
    \\extern double z_float_mul(double, double) __asm__("float_compare.float_mul");
    \\int main(void) {
    \\    if (!z_float_less(1.0f, 2.0f)) return 1;
    \\    if (z_float_less(2.0f, 1.0f)) return 2;
    \\    if (z_float_mul(3.0, 4.0) != 12.0) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/floats_math.zig")) return .{ .abi_mode = "c-stable-module", .expected = "float add/select", .c_body =
    \\#include <stdbool.h>
    \\extern float z_float_add(float, float) __asm__("floats_math.float_add");
    \\extern float z_float_select(float, float, bool) __asm__("floats_math.float_select");
    \\int main(void) {
    \\    if (z_float_add(1.5f, 2.25f) != 3.75f) return 1;
    \\    if (z_float_select(8.0f, 4.0f, true) != 8.0f) return 2;
    \\    if (z_float_select(8.0f, 4.0f, false) != 4.0f) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/fp_constants.zig")) return .{ .abi_mode = "c-stable-module", .expected = "fp constants", .c_body =
    \\extern float z_float_literal(void) __asm__("fp_constants.float_literal");
    \\extern double z_double_literal(void) __asm__("fp_constants.double_literal");
    \\int main(void) {
    \\    if (z_float_literal() != 1.5f) return 1;
    \\    if (z_double_literal() != 2.25) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/fp_extended_ops.zig")) return .{ .abi_mode = "c-stable-module", .expected = "fp sub/div/rem", .c_body =
    \\extern float z_float_sub(float, float) __asm__("fp_extended_ops.float_sub");
    \\extern double z_double_div(double, double) __asm__("fp_extended_ops.double_div");
    \\extern float z_float_rem(float, float) __asm__("fp_extended_ops.float_rem");
    \\int main(void) {
    \\    if (z_float_sub(9.0f, 2.5f) != 6.5f) return 1;
    \\    if (z_double_div(9.0, 2.0) != 4.5) return 2;
    \\    if (z_float_rem(7.0f, 2.0f) != 1.0f) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/globals_comptime.zig")) return .{ .abi_mode = "c-stable-module", .expected = "global initializer/update and comptime constant", .c_body =
    \\extern int z_read_global(void) __asm__("globals_comptime.read_global");
    \\extern int z_update_global(int) __asm__("globals_comptime.update_global");
    \\extern int z_comptime_const(int) __asm__("globals_comptime.comptime_const");
    \\int main(void) {
    \\    if (z_read_global() != 3) return 1;
    \\    if (z_update_global(4) != 7) return 2;
    \\    if (z_read_global() != 7) return 3;
    \\    if (z_comptime_const(7) != 35) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/i64_arithmetic.zig")) return .{ .abi_mode = "c-stable-module", .expected = "i64 return", .c_body =
    \\extern long long z_i64_value(void) __asm__("i64_arithmetic.i64_value");
    \\int main(void) {
    \\    return z_i64_value() == 4 ? 0 : 1;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/integers.zig")) return .{ .abi_mode = "c-stable-module", .expected = "integer arithmetic", .c_body =
    \\extern int z_add_wrap(int, int) __asm__("integers.add_wrap");
    \\extern unsigned z_shift_mix(unsigned, unsigned) __asm__("integers.shift_mix");
    \\extern int z_cmp_select(int, int) __asm__("integers.cmp_select");
    \\int main(void) {
    \\    if (z_add_wrap(2147483647, 1) != (-2147483647 - 1)) return 1;
    \\    if (z_shift_mix(8u, 1u) != 20u) return 2;
    \\    if (z_cmp_select(7, 3) != 3) return 3;
    \\    if (z_cmp_select(-4, 9) != -4) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/optional_pointer.zig")) return .{ .abi_mode = "c-stable-module", .expected = "optional pointer", .c_body =
    \\extern int z_optional_ptr_value(const int *) __asm__("optional_pointer.optional_ptr_value");
    \\int main(void) {
    \\    int value = 41;
    \\    if (z_optional_ptr_value(&value) != 41) return 1;
    \\    if (z_optional_ptr_value((const int *)0) != -1) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/packed_bits.zig")) return .{ .abi_mode = "c-stable-module", .expected = "packed bit values", .c_body =
    \\#include <stdbool.h>
    \\extern bool z_read_flag(unsigned char) __asm__("packed_bits.read_flag");
    \\extern unsigned char z_replace_low(unsigned char, unsigned char) __asm__("packed_bits.replace_low");
    \\int main(void) {
    \\    if (!z_read_flag(128)) return 1;
    \\    if (z_read_flag(0)) return 2;
    \\    if (z_replace_low(0xf0u, 0x0bu) != 0xf3u) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/pointers_memory.zig")) return .{ .abi_mode = "c-stable-module", .expected = "pointer load/store", .c_body =
    \\extern int z_load_store(int *, int *) __asm__("pointers_memory.load_store");
    \\extern int z_volatile_roundtrip(int *, int) __asm__("pointers_memory.volatile_roundtrip");
    \\int main(void) {
    \\    int input = 5;
    \\    int output = 0;
    \\    if (z_load_store(&input, &output) != 6) return 1;
    \\    if (output != 6) return 2;
    \\    if (z_volatile_roundtrip(&output, 9) != 9) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/switch_control.zig")) return .{ .abi_mode = "c-stable-module", .expected = "switch and branch", .c_body =
    \\#include <stdbool.h>
    \\extern int z_dense_switch(int) __asm__("switch_control.dense_switch");
    \\extern int z_branch_mix(int, int, bool) __asm__("switch_control.branch_mix");
    \\int main(void) {
    \\    if (z_dense_switch(0) != 11) return 1;
    \\    if (z_dense_switch(2) != 17) return 2;
    \\    if (z_dense_switch(99) != 23) return 3;
    \\    if (z_branch_mix(10, 3, true) != 13) return 4;
    \\    if (z_branch_mix(10, 3, false) != 7) return 5;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/tls_concurrency.zig")) return .{ .abi_mode = "c-stable-module", .expected = "TLS initializer/read/bump", .c_body =
    \\extern int z_read_tls(void) __asm__("tls_concurrency.read_tls");
    \\extern int z_bump_tls(int) __asm__("tls_concurrency.bump_tls");
    \\int main(void) {
    \\    if (z_read_tls() != 1) return 1;
    \\    if (z_bump_tls(5) != 6) return 2;
    \\    if (z_read_tls() != 6) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/inputs/tiny_scalar.zig")) return .{ .abi_mode = "c-stable-module", .expected = "tiny scalar add", .c_body =
    \\extern int z_add(int, int) __asm__("tiny_scalar.add");
    \\extern void z_sideEffectFree(void) __asm__("tiny_scalar.sideEffectFree");
    \\int main(void) {
    \\    z_sideEffectFree();
    \\    if (z_add(40, 2) != 42) return 1;
    \\    if (z_add(-7, 9) != 2) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_error_optional.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded optional/error values", .c_body =
    \\extern int z_expanded_error_optional(int, int) __asm__("expanded_error_optional.expanded_error_optional");
    \\extern int z_expanded_optional_pointer(const int *) __asm__("expanded_error_optional.expanded_optional_pointer");
    \\int main(void) {
    \\    int value = 34;
    \\    if (z_expanded_error_optional(1, 17) != 17) return 1;
    \\    if (z_expanded_error_optional(0, 17) != -9) return 2;
    \\    if (z_expanded_optional_pointer(&value) != 42) return 3;
    \\    if (z_expanded_optional_pointer((const int *)0) != -1) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_branch_arrays.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded optional branch value", .c_body =
    \\extern int z_expanded_optional_branch(int, int) __asm__("expanded_branch_arrays.expanded_optional_branch");
    \\int main(void) {
    \\    if (z_expanded_optional_branch(1, 11) != 11) return 1;
    \\    if (z_expanded_optional_branch(0, 11) != -5) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_abi_frontier.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded stack/mixed SysV ABI frontier", .c_body =
    \\struct Pair { int a; int b; };
    \\extern int z_expanded_stack_param_sum(int, int, int, int, int, int, int) __asm__("expanded_abi_frontier.expanded_stack_param_sum");
    \\extern int z_expanded_stack_param_sum9(int, int, int, int, int, int, int, int, int) __asm__("expanded_abi_frontier.expanded_stack_param_sum9");
    \\extern int z_expanded_stack_arg_call(void) __asm__("expanded_abi_frontier.expanded_stack_arg_call");
    \\extern int z_expanded_multi_stack_arg_call(void) __asm__("expanded_abi_frontier.expanded_multi_stack_arg_call");
    \\extern float z_expanded_float_call(void) __asm__("expanded_abi_frontier.expanded_float_call");
    \\extern double z_expanded_double_call(void) __asm__("expanded_abi_frontier.expanded_double_call");
    \\extern double z_expanded_mixed_int_float_call(void) __asm__("expanded_abi_frontier.expanded_mixed_int_float_call");
    \\extern double z_expanded_mixed_int_float_stack_call(void) __asm__("expanded_abi_frontier.expanded_mixed_int_float_stack_call");
    \\extern long long z_expanded_i64_call(void) __asm__("expanded_abi_frontier.expanded_i64_call");
    \\extern struct Pair z_expanded_make_pair(int, int) __asm__("expanded_abi_frontier.expanded_make_pair");
    \\extern int z_expanded_pair_first(struct Pair) __asm__("expanded_abi_frontier.expanded_pair_first");
    \\int main(void) {
    \\    struct Pair pair = z_expanded_make_pair(17, 29);
    \\    if (z_expanded_stack_param_sum(1, 2, 3, 4, 5, 6, 7) != 28) return 1;
    \\    if (z_expanded_stack_param_sum(-4, 2, 3, 4, 5, 6, 7) != 23) return 2;
    \\    if (z_expanded_stack_param_sum9(1, 2, 3, 4, 5, 6, 7, 8, 9) != 24) return 3;
    \\    if (z_expanded_stack_arg_call() != 28) return 4;
    \\    if (z_expanded_multi_stack_arg_call() != 24) return 5;
    \\    if (z_expanded_float_call() != 3.5f) return 6;
    \\    if (z_expanded_double_call() != 3.0) return 7;
    \\    if (z_expanded_mixed_int_float_call() != 6.0) return 8;
    \\    if (z_expanded_mixed_int_float_stack_call() != 4.0) return 9;
    \\    if (z_expanded_i64_call() != 123456789LL) return 10;
    \\    if (pair.a != 17 || pair.b != 29) return 11;
    \\    if (z_expanded_pair_first(pair) != 17) return 12;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_cfg_memory_aggregates.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded CFG memory/call values", .c_body =
    \\extern int z_expanded_branch_pointer_load(int, const int *, const int *) __asm__("expanded_cfg_memory_aggregates.expanded_branch_pointer_load");
    \\extern int z_expanded_branch_pointer_phi_load(int, const int *, const int *) __asm__("expanded_cfg_memory_aggregates.expanded_branch_pointer_phi_load");
    \\extern int z_expanded_branch_store(int, int *, int, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_store");
    \\extern int z_expanded_branch_store_computed(int, int *, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_store_computed");
    \\extern int z_expanded_slice_conditional_sum(const int *, unsigned long, int) __asm__("expanded_cfg_memory_aggregates.expanded_slice_conditional_sum");
    \\extern int z_expanded_branch_call(int, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_call");
    \\extern int z_expanded_branch_call_two(int, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_call_two");
    \\extern int z_expanded_optional_pointer_branch(int, const int *) __asm__("expanded_cfg_memory_aggregates.expanded_optional_pointer_branch");
    \\void z_expanded_cfg_unwrap_null(void) __asm__("expanded_cfg_memory_aggregates.unwrapNull");
    \\void z_expanded_cfg_unwrap_null(void) { __builtin_trap(); }
    \\struct pair_i32 { int a; int b; };
    \\extern int z_expanded_struct_branch_update(int, struct pair_i32 *) __asm__("expanded_cfg_memory_aggregates.expanded_struct_branch_update");
    \\extern int z_expanded_struct_field_b(const struct pair_i32 *) __asm__("expanded_cfg_memory_aggregates.expanded_struct_field_b");
    \\extern int z_expanded_struct_field_a(const struct pair_i32 *) __asm__("expanded_cfg_memory_aggregates.expanded_struct_field_a");
    \\int main(void) {
    \\    int left = 10;
    \\    int right = 20;
    \\    int out = 0;
    \\    struct pair_i32 pair = { 20, 44 };
    \\    const int mixed_values[4] = { 1, 9, 4, 12 };
    \\    const int below_values[3] = { 1, 2, 3 };
    \\    const int above_values[3] = { 6, 7, 8 };
    \\    if (z_expanded_branch_pointer_load(1, &left, &right) != 10) return 1;
    \\    if (z_expanded_branch_pointer_load(0, &left, &right) != 20) return 2;
    \\    if (z_expanded_branch_pointer_phi_load(1, &left, &right) != 10) return 3;
    \\    if (z_expanded_branch_pointer_phi_load(0, &left, &right) != 20) return 4;
    \\    if (z_expanded_branch_store(1, &out, 31, 41) != 31 || out != 31) return 5;
    \\    if (z_expanded_branch_store(0, &out, 31, 41) != 41 || out != 41) return 6;
    \\    if (z_expanded_branch_store_computed(1, &out, 50) != 54 || out != 54) return 7;
    \\    if (z_expanded_branch_store_computed(0, &out, 50) != 46 || out != 46) return 8;
    \\    if (z_expanded_slice_conditional_sum(mixed_values, 4, 5) != 21) return 9;
    \\    if (z_expanded_slice_conditional_sum(below_values, 3, 5) != 0) return 10;
    \\    if (z_expanded_slice_conditional_sum(above_values, 3, 5) != 21) return 21;
    \\    if (z_expanded_slice_conditional_sum(mixed_values, 0, 5) != 0) return 22;
    \\    if (z_expanded_branch_call(1, 39) != 42) return 11;
    \\    if (z_expanded_branch_call(0, 39) != 36) return 12;
    \\    if (z_expanded_branch_call_two(1, 39) != 42) return 13;
    \\    if (z_expanded_branch_call_two(0, 39) != 36) return 14;
    \\    if (z_expanded_optional_pointer_branch(1, &left) != 11) return 19;
    \\    if (z_expanded_optional_pointer_branch(0, (const int *)0) != -11) return 20;
    \\    if (z_expanded_struct_field_b(&pair) != 44) return 15;
    \\    if (z_expanded_struct_field_a(&pair) != 20) return 16;
    \\    if (z_expanded_struct_branch_update(1, &pair) != 25 || pair.a != 25) return 17;
    \\    if (z_expanded_struct_branch_update(0, &pair) != 32 || pair.a != 32) return 18;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_float_calls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded FP pipeline", .c_body =
    \\#include <stdbool.h>
    \\extern float z_expanded_float_pipeline(float, float, bool) __asm__("expanded_float_calls.expanded_float_pipeline");
    \\extern double z_expanded_double_pipeline(double, double) __asm__("expanded_float_calls.expanded_double_pipeline");
    \\int main(void) {
    \\    if (z_expanded_float_pipeline(1.25f, 2.5f, true) != 3.75f) return 1;
    \\    if (z_expanded_double_pipeline(9.0, 2.0) != 4.5) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_numeric_casts.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded int/float conversion family with checked panic-edge death proof", .c_body =
    \\#include <sys/wait.h>
    \\#include <unistd.h>
    \\extern float z_expanded_float_from_int(int) __asm__("expanded_numeric_casts.expanded_float_from_int");
    \\extern double z_expanded_double_from_unsigned(unsigned) __asm__("expanded_numeric_casts.expanded_double_from_unsigned");
    \\extern int z_expanded_int_from_float(float) __asm__("expanded_numeric_casts.expanded_int_from_float");
    \\extern float z_expanded_float_narrow(double) __asm__("expanded_numeric_casts.expanded_float_narrow");
    \\extern double z_expanded_double_widen(float) __asm__("expanded_numeric_casts.expanded_double_widen");
    \\void z_expanded_int_from_float_oob(void) __asm__("expanded_numeric_casts.integerPartOutOfBounds");
    \\void z_expanded_int_from_float_oob(void) { __builtin_trap(); }
    \\#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
    \\static int expect_out_of_range_trap(float value) {
    \\    pid_t child = fork();
    \\    if (child < 0) return -1;
    \\    if (child == 0) {
    \\        (void)z_expanded_int_from_float(value);
    \\        _exit(0);
    \\    }
    \\    int status = 0;
    \\    if (waitpid(child, &status, 0) != child) return -1;
    \\    if (!WIFSIGNALED(status)) return -1;
    \\    return 0;
    \\}
    \\#endif
    \\int main(void) {
    \\    if (z_expanded_float_from_int(-7) != -7.0f) return 1;
    \\    if (z_expanded_double_from_unsigned(3000000000u) != 3000000000.0) return 2;
    \\    if (z_expanded_int_from_float(41.75f) != 41) return 3;
    \\    if (z_expanded_int_from_float(-2.5f) != -2) return 4;
    \\    if (z_expanded_float_narrow(1.5) != 1.5f) return 5;
    \\    if (z_expanded_double_widen(2.25f) != 2.25) return 6;
    \\#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
    \\    if (expect_out_of_range_trap(3000000000.0f) != 0) return 7;
    \\    if (expect_out_of_range_trap(-3000000000.0f) != 0) return 8;
    \\#endif
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_pointer_slices.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded pointer and slice operations", .c_body =
    \\extern int z_expanded_slice_sum(const int *, unsigned long) __asm__("expanded_pointer_slices.expanded_slice_sum");
    \\extern int z_expanded_load_store(int *, int *) __asm__("expanded_pointer_slices.expanded_load_store");
    \\int main(void) {
    \\    int values[4] = { 2, 4, 6, 8 };
    \\    int input = 39;
    \\    int output = 0;
    \\    if (z_expanded_slice_sum(values, 4) != 20) return 1;
    \\    if (z_expanded_load_store(&input, &output) != 42) return 2;
    \\    if (output != 42) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/expanded/expanded_records_memory.zig")) return .{ .abi_mode = "c-stable-module", .expected = "expanded aggregate/global/TLS operations", .c_body =
    \\struct Pair { int a; int b; };
    \\extern struct Pair z_expanded_make_pair(int, int) __asm__("expanded_records_memory.expanded_make_pair");
    \\extern int z_expanded_pair_first(struct Pair) __asm__("expanded_records_memory.expanded_pair_first");
    \\extern int z_expanded_global_update(int) __asm__("expanded_records_memory.expanded_global_update");
    \\extern int z_expanded_tls_bump(int) __asm__("expanded_records_memory.expanded_tls_bump");
    \\int main(void) {
    \\    struct Pair pair = z_expanded_make_pair(12, 30);
    \\    if (pair.a != 12) return 1;
    \\    if (pair.b != 30) return 2;
    \\    if (z_expanded_pair_first(pair) != 12) return 3;
    \\    if (z_expanded_global_update(5) != 16) return 4;
    \\    if (z_expanded_tls_bump(7) != 9) return 5;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/scale/scale_abi_calls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "scale stack/mixed ABI calls", .c_body =
    \\extern int z_scale_stack_wide_call(void) __asm__("scale_abi_calls.scale_stack_wide_call");
    \\extern double z_scale_mixed_wide_call(void) __asm__("scale_abi_calls.scale_mixed_wide_call");
    \\extern long long z_scale_i64_echo_call(void) __asm__("scale_abi_calls.scale_i64_echo_call");
    \\int main(void) {
    \\    if (z_scale_stack_wide_call() != 24) return 1;
    \\    if (z_scale_mixed_wide_call() != 4.0) return 2;
    \\    if (z_scale_i64_echo_call() != 987654321LL) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/scale/scale_memory_loops.zig")) return .{ .abi_mode = "c-stable-module", .expected = "scale memory loops and branch pointer operations", .c_body =
    \\extern int z_scale_slice_sum(const int *, unsigned long) __asm__("scale_memory_loops.scale_slice_sum");
    \\extern int z_scale_slice_threshold_sum(const int *, unsigned long, int) __asm__("scale_memory_loops.scale_slice_threshold_sum");
    \\extern int z_scale_branch_pointer_load(int, const int *, const int *) __asm__("scale_memory_loops.scale_branch_pointer_load");
    \\extern int z_scale_branch_store(int, int *, int) __asm__("scale_memory_loops.scale_branch_store");
    \\int main(void) {
    \\    const int values[5] = { 1, 2, 3, 4, 5 };
    \\    const int mixed[5] = { 1, 8, 4, 11, 2 };
    \\    int left = 13;
    \\    int right = 29;
    \\    int out = 0;
    \\    if (z_scale_slice_sum(values, 5) != 15) return 1;
    \\    if (z_scale_slice_sum(values, 0) != 0) return 2;
    \\    if (z_scale_slice_threshold_sum(mixed, 5, 5) != 19) return 3;
    \\    if (z_scale_slice_threshold_sum(values, 5, 9) != 0) return 4;
    \\    if (z_scale_branch_pointer_load(1, &left, &right) != 13) return 5;
    \\    if (z_scale_branch_pointer_load(0, &left, &right) != 29) return 6;
    \\    if (z_scale_branch_store(1, &out, 40) != 45 || out != 45) return 7;
    \\    if (z_scale_branch_store(0, &out, 40) != 35 || out != 35) return 8;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/scale/scale_records_globals.zig")) return .{ .abi_mode = "c-stable-module", .expected = "scale records globals TLS and branch calls", .c_body =
    \\struct Pair { int a; int b; };
    \\extern int z_scale_pair_update(int, struct Pair *) __asm__("scale_records_globals.scale_pair_update");
    \\extern int z_scale_pair_read_b(const struct Pair *) __asm__("scale_records_globals.scale_pair_read_b");
    \\extern int z_scale_branch_call(int, int) __asm__("scale_records_globals.scale_branch_call");
    \\extern int z_scale_global_update(int) __asm__("scale_records_globals.scale_global_update");
    \\extern int z_scale_tls_bump(int) __asm__("scale_records_globals.scale_tls_bump");
    \\int main(void) {
    \\    struct Pair pair = { 10, 33 };
    \\    if (z_scale_pair_read_b(&pair) != 33) return 1;
    \\    if (z_scale_pair_update(1, &pair) != 12 || pair.a != 12) return 2;
    \\    if (z_scale_pair_update(0, &pair) != 16 || pair.a != 16) return 3;
    \\    if (z_scale_branch_call(1, 20) != 24) return 4;
    \\    if (z_scale_branch_call(0, 20) != 16) return 5;
    \\    if (z_scale_global_update(4) != 17) return 6;
    \\    if (z_scale_global_update(3) != 20) return 7;
    \\    if (z_scale_tls_bump(2) != 7) return 8;
    \\    if (z_scale_tls_bump(5) != 12) return 9;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_nested_loops.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier scalarized loop frontier values", .c_body =
    \\extern int z_frontier_flat_window_sum(int, int) __asm__("frontier_nested_loops.frontier_flat_window_sum");
    \\extern int z_frontier_window_threshold(int, int) __asm__("frontier_nested_loops.frontier_window_threshold");
    \\extern int z_frontier_nested_memory_sum(const int *, unsigned long, int) __asm__("frontier_nested_loops.frontier_nested_memory_sum");
    \\int main(void) {
    \\    const int values[] = { 1, 9, 4, 12, 7 };
    \\    if (z_frontier_flat_window_sum(7, 8) != 15) return 1;
    \\    if (z_frontier_window_threshold(1, 9) != 9) return 2;
    \\    if (z_frontier_window_threshold(0, 9) != 0) return 3;
    \\    if (z_frontier_nested_memory_sum(values, 5, 6) != 28) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_nested_records.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier record scalar values", .c_body =
    \\struct Inner { int a; int b; };
    \\struct Outer { struct Inner left; struct Inner right; };
    \\extern int z_frontier_record_sum(int, int) __asm__("frontier_nested_records.frontier_record_sum");
    \\extern int z_frontier_record_update(int, int) __asm__("frontier_nested_records.frontier_record_update");
    \\extern int z_frontier_nested_field_left_b(const struct Outer *) __asm__("frontier_nested_records.frontier_nested_field_left_b");
    \\extern int z_frontier_nested_field_right_a(const struct Outer *) __asm__("frontier_nested_records.frontier_nested_field_right_a");
    \\int main(void) {
    \\    const struct Outer record = { { 10, 20 }, { 30, 40 } };
    \\    if (z_frontier_record_sum(11, 31) != 42) return 1;
    \\    if (z_frontier_record_update(1, 10) != 11) return 2;
    \\    if (z_frontier_record_update(0, 10) != 12) return 3;
    \\    if (z_frontier_nested_field_left_b(&record) != 20) return 4;
    \\    if (z_frontier_nested_field_right_a(&record) != 30) return 5;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_optionals_errors.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier optional/error control flow", .c_body =
    \\extern int z_frontier_optional_merge(int, int) __asm__("frontier_optionals_errors.frontier_optional_merge");
    \\extern int z_frontier_error_payload(int, int) __asm__("frontier_optionals_errors.frontier_error_payload");
    \\int main(void) {
    \\    if (z_frontier_optional_merge(1, 30) != 30) return 1;
    \\    if (z_frontier_optional_merge(0, 30) != -17) return 2;
    \\    if (z_frontier_error_payload(0, 40) != 42) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_slice_pointer_arith.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier pointer load forms", .c_body =
    \\extern int z_frontier_slice_stride_sum(const int *) __asm__("frontier_slice_pointer_arith.frontier_slice_stride_sum");
    \\extern int z_frontier_pointer_offset_load(const int *) __asm__("frontier_slice_pointer_arith.frontier_pointer_offset_load");
    \\extern int z_frontier_dynamic_ptr_add(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_dynamic_ptr_add");
    \\extern int z_frontier_dynamic_ptr_pair_sum(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_dynamic_ptr_pair_sum");
    \\int main(void) {
    \\    const int value = 37;
    \\    const int values[] = { 3, 5, 8, 13, 21 };
    \\    if (z_frontier_slice_stride_sum(&value) != 37) return 1;
    \\    if (z_frontier_pointer_offset_load(&value) != 37) return 2;
    \\    if (z_frontier_dynamic_ptr_add(values, 3) != 13) return 3;
    \\    if (z_frontier_dynamic_ptr_pair_sum(values, 1) != 13) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_comptime_constants.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier comptime constants", .c_body =
    \\extern int z_frontier_comptime_mix(int) __asm__("frontier_comptime_constants.frontier_comptime_mix");
    \\extern int z_frontier_static_choice(int) __asm__("frontier_comptime_constants.frontier_static_choice");
    \\int main(void) {
    \\    if (z_frontier_comptime_mix(5) != 26) return 1;
    \\    if (z_frontier_static_choice(0) != 8) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_helper_graph.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier private helper graph", .c_body =
    \\extern int z_frontier_helper_chain(int, int) __asm__("frontier_helper_graph.frontier_helper_chain");
    \\extern int z_frontier_helper_branch(int, int) __asm__("frontier_helper_graph.frontier_helper_branch");
    \\int main(void) {
    \\    if (z_frontier_helper_chain(9, 99) != 10) return 1;
    \\    if (z_frontier_helper_branch(1, 10) != 14) return 2;
    \\    if (z_frontier_helper_branch(0, 10) != 23) return 3;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_mixed_numeric.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier mixed numeric FP", .c_body =
    \\extern float z_frontier_mixed_float(float, float) __asm__("frontier_mixed_numeric.frontier_mixed_float");
    \\extern double z_frontier_double_roundtrip(double, double) __asm__("frontier_mixed_numeric.frontier_double_roundtrip");
    \\int main(void) {
    \\    if (z_frontier_mixed_float(1.5f, 2.25f) != 3.75f) return 1;
    \\    if (z_frontier_double_roundtrip(9.0, 2.0) != 4.5) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_globals_tls.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier global TLS updates", .c_body =
    \\extern int z_frontier_global_branch(int, int) __asm__("frontier_globals_tls.frontier_global_branch");
    \\extern int z_frontier_tls_branch(int, int) __asm__("frontier_globals_tls.frontier_tls_branch");
    \\int main(void) {
    \\    if (z_frontier_global_branch(1, 5) != 26) return 1;
    \\    if (z_frontier_global_branch(0, 3) != 23) return 2;
    \\    if (z_frontier_tls_branch(1, 2) != 6) return 3;
    \\    if (z_frontier_tls_branch(0, 5) != 1) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_branch_memory.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier branch-local memory", .c_body =
    \\extern int z_frontier_branch_store_reload(int, int *, int, int) __asm__("frontier_branch_memory.frontier_branch_store_reload");
    \\extern int z_frontier_branch_local_mix(int, int *, int) __asm__("frontier_branch_memory.frontier_branch_local_mix");
    \\int main(void) {
    \\    int out = 0;
    \\    if (z_frontier_branch_store_reload(1, &out, 20, 40) != 29 || out != 29) return 1;
    \\    if (z_frontier_branch_store_reload(0, &out, 20, 40) != 31 || out != 31) return 2;
    \\    if (z_frontier_branch_local_mix(1, &out, 30) != 36 || out != 36) return 3;
    \\    if (z_frontier_branch_local_mix(0, &out, 30) != 24 || out != 24) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_safety_edges.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier safety-edge-adjacent values", .c_body =
    \\extern int z_frontier_checked_add(int) __asm__("frontier_safety_edges.frontier_checked_add");
    \\extern int z_frontier_bounds_guard(const int *, unsigned long, unsigned long) __asm__("frontier_safety_edges.frontier_bounds_guard");
    \\int main(void) {
    \\    int value = 41;
    \\    if (z_frontier_checked_add(5) != 16) return 1;
    \\    if (z_frontier_bounds_guard(&value, 1, 0) != 41) return 2;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_abi.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier SysV aggregate and multi-spill ABI", .c_body =
    \\struct Pair64 { long long a; long long b; };
    \\extern struct Pair64 z_frontier_pair64_make(long long, long long) __asm__("frontier_sysv_abi.frontier_pair64_make");
    \\extern long long z_frontier_pair64_first(struct Pair64) __asm__("frontier_sysv_abi.frontier_pair64_first");
    \\extern long long z_frontier_pair64_second(struct Pair64) __asm__("frontier_sysv_abi.frontier_pair64_second");
    \\extern int z_frontier_two_live_after_call(int, int, int) __asm__("frontier_sysv_abi.frontier_two_live_after_call");
    \\extern int z_frontier_three_live_after_call(int, int, int, int) __asm__("frontier_sysv_abi.frontier_three_live_after_call");
    \\int main(void) {
    \\    struct Pair64 pair = z_frontier_pair64_make(0x1122334455667788LL, 0x0102030405060708LL);
    \\    if (pair.a != 0x1122334455667788LL || pair.b != 0x0102030405060708LL) return 1;
    \\    if (z_frontier_pair64_first(pair) != 0x1122334455667788LL) return 2;
    \\    if (z_frontier_pair64_second(pair) != 0x0102030405060708LL) return 3;
    \\    if (z_frontier_two_live_after_call(7, 11, 13) != 31) return 4;
    \\    if (z_frontier_three_live_after_call(7, 11, 13, 17) != 48) return 5;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_sret_byval.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier SysV sret/byval ABI", .c_body =
    \\struct Big3 { long long a; long long b; long long c; };
    \\struct Big4 { long long a; long long b; long long c; long long d; };
    \\extern struct Big3 z_frontier_big3_make(long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big3_make");
    \\extern long long z_frontier_big3_edges(struct Big3) __asm__("frontier_sysv_sret_byval.frontier_big3_edges");
    \\extern struct Big4 z_frontier_big4_make(long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big4_make");
    \\extern long long z_frontier_big4_edges(struct Big4) __asm__("frontier_sysv_sret_byval.frontier_big4_edges");
    \\int main(void) {
    \\    struct Big3 made = z_frontier_big3_make(5, 7, 11);
    \\    if (made.a != 5 || made.b != 7 || made.c != 11) return 1;
    \\    struct Big3 input = { .a = 13, .b = 17, .c = 19 };
    \\    if (z_frontier_big3_edges(input) != 32) return 2;
    \\    struct Big4 made4 = z_frontier_big4_make(23, 29, 31, 37);
    \\    if (made4.a != 23 || made4.b != 29 || made4.c != 31 || made4.d != 37) return 3;
    \\    struct Big4 input4 = { .a = 41, .b = 43, .c = 47, .d = 53 };
    \\    if (z_frontier_big4_edges(input4) != 94) return 4;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_aggregate_classes.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier mixed integer/SSE and nested INTEGER aggregate ABI", .c_body =
    \\struct Mixed { long long a; double b; };
    \\struct DoublePair { double a; double b; };
    \\struct Pair32 { int a; int b; };
    \\struct NestedPair { struct Pair32 left; struct Pair32 right; };
    \\struct ArrayPair { long long values[2]; };
    \\extern long long z_frontier_mixed_int(struct Mixed) __asm__("frontier_sysv_aggregate_classes.frontier_mixed_int");
    \\extern double z_frontier_mixed_float(struct Mixed) __asm__("frontier_sysv_aggregate_classes.frontier_mixed_float");
    \\extern struct Mixed z_frontier_mixed_make(long long, double) __asm__("frontier_sysv_aggregate_classes.frontier_mixed_make");
    \\extern double z_frontier_double_pair_first(struct DoublePair) __asm__("frontier_sysv_aggregate_classes.frontier_double_pair_first");
    \\extern double z_frontier_double_pair_second(struct DoublePair) __asm__("frontier_sysv_aggregate_classes.frontier_double_pair_second");
    \\extern struct DoublePair z_frontier_double_pair_make(double, double) __asm__("frontier_sysv_aggregate_classes.frontier_double_pair_make");
    \\extern int z_frontier_nested_pair_sum(struct NestedPair) __asm__("frontier_sysv_aggregate_classes.frontier_nested_pair_sum");
    \\extern long long z_frontier_array_pair_sum(struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_array_pair_sum");
    \\int main(void) {
    \\    struct Mixed value = { 123456789LL, 6.25 };
    \\    if (z_frontier_mixed_int(value) != 123456789LL) return 1;
    \\    if (z_frontier_mixed_float(value) != 6.25) return 2;
    \\    struct Mixed made = z_frontier_mixed_make(77, 9.5);
    \\    if (made.a != 77 || made.b != 9.5) return 3;
    \\    struct DoublePair doubles = { 1.25, 7.5 };
    \\    if (z_frontier_double_pair_first(doubles) != 1.25) return 4;
    \\    if (z_frontier_double_pair_second(doubles) != 7.5) return 5;
    \\    struct DoublePair made_doubles = z_frontier_double_pair_make(3.5, 11.25);
    \\    if (made_doubles.a != 3.5 || made_doubles.b != 11.25) return 6;
    \\    struct NestedPair nested = { { 1, 2 }, { 3, 4 } };
    \\    if (z_frontier_nested_pair_sum(nested) != 10) return 7;
    \\    struct ArrayPair array = { { 11, 31 } };
    \\    if (z_frontier_array_pair_sum(array) != 42) return 8;
    \\    return 0;
    \\}
    \\
    };
    if (integratedModuleMainHarness(source)) |module_main| return .{
        .abi_mode = "c-stable-integrated-main",
        .expected = "module main expected return",
        .module_main = module_main,
    };
    return null;
}

fn integratedModuleMainHarness(source: []const u8) ?ModuleMainHarness {
    if (!std.mem.startsWith(u8, source, "test/zig/integrated/")) return null;
    const basename = std.fs.path.basename(source);
    if (std.mem.eql(u8, basename, "runtime_mix_c_add_may_panic_main.zig")) return null;

    if (std.mem.eql(u8, basename, "runtime_aggregate_pair_main.zig")) return .{ .source = source, .expected_exit = 1 };
    if (std.mem.eql(u8, basename, "runtime_hidden_access_main.zig")) return .{ .source = source, .expected_exit = 7 };
    if (std.mem.eql(u8, basename, "runtime_inherit_want_safety_i64_main.zig")) return .{ .source = source, .return_type = .c_long, .expected_exit = 4 };
    if (std.mem.eql(u8, basename, "runtime_mix_c_add_zig_main.zig")) return .{ .source = source, .expected_exit = 7 };
    if (std.mem.eql(u8, basename, "runtime_tls_bump_main.zig")) return .{ .source = source, .expected_exit = 2 };
    if (std.mem.eql(u8, basename, "runtime_umul_fix_sat_i64_main.zig")) return .{ .source = source, .return_type = .c_long };

    return .{ .source = source };
}

fn executableHarnessBody(allocator: std.mem.Allocator, harness: ExecutableHarness) ![]const u8 {
    if (harness.c_body) |body| return body;
    const module_main = harness.module_main orelse return error.MissingExecutableHarnessBody;
    const stem = std.fs.path.stem(module_main.source);
    const symbol = try std.fmt.allocPrint(allocator, "{s}.main", .{stem});
    defer allocator.free(symbol);
    return std.fmt.allocPrint(
        allocator,
        \\extern {s} z_module_main(void) __asm__("{s}");
        \\int main(void) {{
        \\    return z_module_main() == {d} ? 0 : 1;
        \\}}
        \\
    ,
        .{ module_main.return_type.cType(), symbol, module_main.expected_exit },
    );
}

fn nativeLinkObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_exe: []const u8,
    mode: Mode,
    object_path: []const u8,
    exe_path: []const u8,
) !std.process.RunResult {
    return linkObjectWithHarness(
        allocator,
        io,
        zig_exe,
        mode,
        object_path,
        exe_path,
        "int main(void) { return 0; }\n",
    );
}

fn linkObjectWithHarness(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_exe: []const u8,
    mode: Mode,
    object_path: []const u8,
    exe_path: []const u8,
    harness_body: []const u8,
) !std.process.RunResult {
    const harness_c = try std.fmt.allocPrint(allocator, "{s}.c", .{exe_path});
    defer allocator.free(harness_c);
    const harness_o = try std.fmt.allocPrint(allocator, "{s}.harness.o", .{exe_path});
    defer allocator.free(harness_o);
    const mode_define = try std.fmt.allocPrint(allocator, "-DZLLVM_HARNESS_MODE_{s}", .{mode.name()});
    defer allocator.free(mode_define);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness_c, .data = harness_body });
    const cc_argv = [_][]const u8{
        zig_exe,
        "cc",
        "-target",
        "x86_64-linux-gnu",
        mode_define,
        "-c",
        harness_c,
        "-o",
        harness_o,
    };
    const cc_result = try std.process.run(allocator, io, .{
        .argv = &cc_argv,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
    if (!termOk(cc_result.term)) return cc_result;
    allocator.free(cc_result.stdout);
    allocator.free(cc_result.stderr);

    const emit_bin_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe_path});
    defer allocator.free(emit_bin_arg);
    const argv = [_][]const u8{
        zig_exe,
        "build-exe",
        "-target",
        "x86_64-linux-gnu",
        "-fno-lld",
        harness_o,
        object_path,
        "-lc",
        emit_bin_arg,
    };
    return std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
}

fn runExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    exe_path: []const u8,
) !std.process.RunResult {
    const argv = [_][]const u8{exe_path};
    return std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
}

fn termOk(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

fn termName(term: std.process.Child.Term) []const u8 {
    return switch (term) {
        .exited => "nonzero-exit",
        .signal => "signal",
        .stopped => "stopped",
        .unknown => "unknown",
    };
}

const NativeLinkFailure = union(enum) {
    runtime_boundary: []const u8,
    unsupported_zig_linker_feature: []const u8,
    local_failure: []const u8,
};

fn classifyNativeLinkFailure(stderr: []const u8) NativeLinkFailure {
    if (firstUndefinedSymbol(stderr)) |symbol| {
        if (isRuntimeBoundarySymbol(symbol)) return .{ .runtime_boundary = symbol };
        return .{ .local_failure = "unresolved-symbol" };
    }
    const line = firstLine(stderr);
    if (std.mem.indexOf(u8, line, "relocation") != null) return .{ .unsupported_zig_linker_feature = "unsupported-relocation" };
    if (std.mem.indexOf(u8, line, "TLS") != null or std.mem.indexOf(u8, line, "thread-local") != null) return .{ .unsupported_zig_linker_feature = "tls-model" };
    if (std.mem.indexOf(u8, line, "COMDAT") != null or std.mem.indexOf(u8, line, "group") != null) return .{ .unsupported_zig_linker_feature = "comdat-group" };
    return .{ .local_failure = "unclassified-link-failed" };
}

fn firstUndefinedSymbol(stderr: []const u8) ?[]const u8 {
    const needle = "undefined symbol: ";
    const start = std.mem.indexOf(u8, stderr, needle) orelse return null;
    var rest = stderr[start + needle.len ..];
    rest = std.mem.trim(u8, rest, " \t'`\"");
    const end = std.mem.indexOfAny(u8, rest, "\r\n'`\" ") orelse rest.len;
    return rest[0..end];
}

fn isRuntimeBoundarySymbol(symbol: []const u8) bool {
    return std.mem.startsWith(u8, symbol, "debug.") or
        std.mem.endsWith(u8, symbol, ".outOfBounds") or
        std.mem.endsWith(u8, symbol, ".integerPartOutOfBounds") or
        std.mem.endsWith(u8, symbol, ".unwrapNull") or
        std.mem.startsWith(u8, symbol, "panic") or
        std.mem.startsWith(u8, symbol, "__") or
        std.mem.startsWith(u8, symbol, "compiler_rt.") or
        std.mem.startsWith(u8, symbol, "memcpy") or
        std.mem.startsWith(u8, symbol, "memset") or
        std.mem.startsWith(u8, symbol, "memcmp") or
        std.mem.startsWith(u8, symbol, "malloc") or
        std.mem.startsWith(u8, symbol, "free") or
        std.mem.startsWith(u8, symbol, "abort") or
        std.mem.startsWith(u8, symbol, "exit") or
        std.mem.startsWith(u8, symbol, "posix.") or
        std.mem.startsWith(u8, symbol, "os.") or
        std.mem.startsWith(u8, symbol, "Io.") or
        std.mem.startsWith(u8, symbol, "Thread.") or
        std.mem.startsWith(u8, symbol, "start.");
}

fn firstLine(text: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    const end = std.mem.indexOfAny(u8, trimmed, "\r\n") orelse trimmed.len;
    return trimmed[0..end];
}

fn collectSources(allocator: std.mem.Allocator, io: std.Io, corpus: Corpus) ![][]const u8 {
    var sources: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (sources.items) |source| allocator.free(source);
        sources.deinit(allocator);
    }
    if (corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/frontier");
        std.mem.sort([]const u8, sources.items, {}, struct {
            fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
                return std.mem.lessThan(u8, lhs, rhs);
            }
        }.lessThan);
        return sources.toOwnedSlice(allocator);
    }
    try collectSourcesFromRoot(allocator, io, &sources, "test/zig/inputs");
    if (corpus == .broad or corpus == .expanded or corpus == .scale or corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/integrated");
    }
    if (corpus == .expanded or corpus == .scale or corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/expanded");
    }
    if (corpus == .scale or corpus == .frontier) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/scale");
    }
    std.mem.sort([]const u8, sources.items, {}, struct {
        fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lessThan);
    return sources.toOwnedSlice(allocator);
}

fn collectSourcesFromRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    sources: *std.ArrayList([]const u8),
    root: []const u8,
) !void {
    var dir = try std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true });
    defer dir.close(io);
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".zig")) continue;
        try sources.append(allocator, try std.fs.path.join(allocator, &.{ root, entry.name }));
    }
}

fn incrementCount(
    allocator: std.mem.Allocator,
    counts: *std.StringHashMap(usize),
    key: []const u8,
) !void {
    const entry = try counts.getOrPut(key);
    if (entry.found_existing) {
        entry.value_ptr.* += 1;
    } else {
        entry.key_ptr.* = try allocator.dupe(u8, key);
        entry.value_ptr.* = 1;
    }
}

fn cloneEnvironment(
    allocator: std.mem.Allocator,
    source: *const std.process.Environ.Map,
) !std.process.Environ.Map {
    var result = std.process.Environ.Map.init(allocator);
    errdefer result.deinit();
    for (source.keys(), source.values()) |key, value| try result.put(key, value);
    return result;
}
