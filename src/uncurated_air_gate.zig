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
                                "executable-failure source={s} function=module abi={s} expected={s} actual={s} exit_code={d} stderr={s}\n",
                                .{ source, executable_harness.abi_mode, executable_harness.expected, termName(run_result.term), termExitCode(run_result.term), firstLine(run_result.stderr) },
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
    \\extern float z_frontier_i32_to_f32_add(int, float) __asm__("frontier_mixed_numeric.frontier_i32_to_f32_add");
    \\extern float z_frontier_i32_to_f32_mul_add(int, float, float) __asm__("frontier_mixed_numeric.frontier_i32_to_f32_mul_add");
    \\extern double z_frontier_i32_to_f64_mul_add(int, double, double) __asm__("frontier_mixed_numeric.frontier_i32_to_f64_mul_add");
    \\int main(void) {
    \\    if (z_frontier_mixed_float(1.5f, 2.25f) != 3.75f) return 1;
    \\    if (z_frontier_double_roundtrip(9.0, 2.0) != 4.5) return 2;
    \\    if (z_frontier_i32_to_f32_add(4, 1.5f) != 5.5f) return 3;
    \\    if (z_frontier_i32_to_f32_mul_add(3, 2.0f, 1.25f) != 7.25f) return 4;
    \\    if (z_frontier_i32_to_f64_mul_add(4, 2.5, 0.5) != 10.5) return 5;
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
    \\extern int z_frontier_guard_return_else(const int *, unsigned long, unsigned long) __asm__("frontier_safety_edges.frontier_guard_return_else");
    \\int main(void) {
    \\    int value = 41;
    \\    int values[3] = { 11, 41, 77 };
    \\    if (z_frontier_checked_add(5) != 16) return 1;
    \\    if (z_frontier_bounds_guard(&value, 1, 0) != 41) return 2;
    \\    if (z_frontier_guard_return_else(values, 3, 1) != 41) return 3;
    \\    if (z_frontier_guard_return_else(values, 3, 3) != -1) return 4;
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
    \\extern int z_frontier_four_live_after_call(int, int, int, int) __asm__("frontier_sysv_abi.frontier_four_live_after_call");
    \\extern int z_frontier_five_live_after_call(int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_five_live_after_call");
    \\extern int z_frontier_six_live_after_call(int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_six_live_after_call");
    \\extern int z_frontier_two_void_calls_six_live(int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_two_void_calls_six_live");
    \\extern int z_frontier_two_indirect_void_calls_six_live(void (*)(void), int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_two_indirect_void_calls_six_live");
    \\extern int z_frontier_call_result_live_across_second_call(int) __asm__("frontier_sysv_abi.frontier_call_result_live_across_second_call");
    \\extern int z_frontier_two_i32_results_across_calls(int, int) __asm__("frontier_sysv_abi.frontier_two_i32_results_across_calls");
    \\extern int z_frontier_two_i32_results_across_indirect_call(int (*)(int), int, int) __asm__("frontier_sysv_abi.frontier_two_i32_results_across_indirect_call");
    \\extern int z_frontier_two_i32_results_live_across_void_call(int, int) __asm__("frontier_sysv_abi.frontier_two_i32_results_live_across_void_call");
    \\extern int z_frontier_two_i32_results_live_across_indirect_void_call(void (*)(void), int, int) __asm__("frontier_sysv_abi.frontier_two_i32_results_live_across_indirect_void_call");
    \\extern int z_frontier_indirect_first_i32_result_live_across_void_call(int (*)(int), int, int) __asm__("frontier_sysv_abi.frontier_indirect_first_i32_result_live_across_void_call");
    \\extern double z_frontier_f64_result_live_across_void_call(double, double) __asm__("frontier_sysv_abi.frontier_f64_result_live_across_void_call");
    \\extern double z_frontier_f64_result_live_across_indirect_void_call(void (*)(void), double, double) __asm__("frontier_sysv_abi.frontier_f64_result_live_across_indirect_void_call");
    \\extern double z_frontier_indirect_f64_result_live_across_void_call(double (*)(double), double, double) __asm__("frontier_sysv_abi.frontier_indirect_f64_result_live_across_void_call");
    \\extern double z_frontier_indirect_f64_result_live_across_indirect_void_call(double (*)(double), void (*)(void), double, double) __asm__("frontier_sysv_abi.frontier_indirect_f64_result_live_across_indirect_void_call");
    \\extern int z_frontier_six_stack_arg_call(void) __asm__("frontier_sysv_abi.frontier_six_stack_arg_call");
    \\extern int z_frontier_eight_stack_arg_call(void) __asm__("frontier_sysv_abi.frontier_eight_stack_arg_call");
    \\extern int z_frontier_twelve_stack_arg_call(void) __asm__("frontier_sysv_abi.frontier_twelve_stack_arg_call");
    \\extern int z_frontier_eighteen_stack_arg_call(void) __asm__("frontier_sysv_abi.frontier_eighteen_stack_arg_call");
    \\extern int z_frontier_stack_arg_forward(int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_stack_arg_forward");
    \\extern int z_frontier_stack_arg_to_registers(int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_stack_arg_to_registers");
    \\extern int z_frontier_indirect_stack_arg_to_registers(int (*)(int, int, int, int, int, int), int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_indirect_stack_arg_to_registers");
    \\extern int z_frontier_indirect_stack_arg_forward(int (*)(int, int, int, int, int, int, int, int, int, int, int, int), int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_indirect_stack_arg_forward");
    \\extern int z_frontier_indirect_eight_stack_arg_forward(int (*)(int, int, int, int, int, int, int, int, int, int, int, int, int, int), int, int, int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_indirect_eight_stack_arg_forward");
    \\extern int z_frontier_indirect_eighteen_stack_arg_forward(int (*)(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int), int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_indirect_eighteen_stack_arg_forward");
    \\extern int z_frontier_ptr_stack_arg_forward(const int *, const int *, const int *, const int *, const int *, const int *, const int *, const int *) __asm__("frontier_sysv_abi.frontier_ptr_stack_arg_forward");
    \\extern int z_frontier_indirect_ptr_stack_arg_forward(int (*)(const int *, const int *, const int *, const int *, const int *, const int *, const int *, const int *), const int *, const int *, const int *, const int *, const int *, const int *, const int *, const int *) __asm__("frontier_sysv_abi.frontier_indirect_ptr_stack_arg_forward");
    \\extern const int *z_frontier_ptr_return_param(const int *, const int *) __asm__("frontier_sysv_abi.frontier_ptr_return_param");
    \\extern const int *z_frontier_ptr_return_direct_call(const int *, const int *, int) __asm__("frontier_sysv_abi.frontier_ptr_return_direct_call");
    \\extern const int *z_frontier_ptr_return_indirect_call(const int *(*)(const int *, const int *, int), const int *, const int *, int) __asm__("frontier_sysv_abi.frontier_ptr_return_indirect_call");
    \\extern int z_frontier_i32_swapped_direct_call(int, int) __asm__("frontier_sysv_abi.frontier_i32_swapped_direct_call");
    \\extern long long z_frontier_i64_swapped_direct_call(long long, long long) __asm__("frontier_sysv_abi.frontier_i64_swapped_direct_call");
    \\extern const int *z_frontier_ptr_swapped_direct_call(const int *, const int *, int) __asm__("frontier_sysv_abi.frontier_ptr_swapped_direct_call");
    \\extern float z_frontier_f32_swapped_direct_call(float, float) __asm__("frontier_sysv_abi.frontier_f32_swapped_direct_call");
    \\extern double z_frontier_f64_swapped_direct_call(double, double) __asm__("frontier_sysv_abi.frontier_f64_swapped_direct_call");
    \\extern int z_frontier_i32_three_cycle_direct_call(int, int, int) __asm__("frontier_sysv_abi.frontier_i32_three_cycle_direct_call");
    \\extern long long z_frontier_i64_three_cycle_direct_call(long long, long long, long long) __asm__("frontier_sysv_abi.frontier_i64_three_cycle_direct_call");
    \\extern int z_frontier_i32_six_cycle_direct_call(int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_i32_six_cycle_direct_call");
    \\extern int z_frontier_i32_swapped_indirect_call(int, int, int (*)(int, int)) __asm__("frontier_sysv_abi.frontier_i32_swapped_indirect_call");
    \\extern long long z_frontier_i64_swapped_indirect_call(long long, long long, long long (*)(long long, long long)) __asm__("frontier_sysv_abi.frontier_i64_swapped_indirect_call");
    \\extern const int *z_frontier_ptr_swapped_indirect_call(const int *, const int *, int, const int *(*)(const int *, const int *, int)) __asm__("frontier_sysv_abi.frontier_ptr_swapped_indirect_call");
    \\extern float z_frontier_f32_swapped_indirect_call(float, float, float (*)(float, float)) __asm__("frontier_sysv_abi.frontier_f32_swapped_indirect_call");
    \\extern double z_frontier_f64_swapped_indirect_call(double, double, double (*)(double, double)) __asm__("frontier_sysv_abi.frontier_f64_swapped_indirect_call");
    \\extern int z_frontier_computed_stack_arg_call(int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_computed_stack_arg_call");
    \\extern long long z_frontier_i64_stack_arg_to_registers(long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_abi.frontier_i64_stack_arg_to_registers");
    \\extern long long z_frontier_indirect_i64_stack_arg_forward(long long (*)(long long, long long, long long, long long, long long, long long, long long, long long), long long, long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_abi.frontier_indirect_i64_stack_arg_forward");
    \\extern struct Pair64 z_frontier_indirect_pair64_make(struct Pair64 (*)(long long, long long), long long, long long) __asm__("frontier_sysv_abi.frontier_indirect_pair64_make");
    \\extern long long z_frontier_indirect_pair64_first(long long (*)(struct Pair64), struct Pair64) __asm__("frontier_sysv_abi.frontier_indirect_pair64_first");
    \\extern int z_frontier_indirect_two_live_after_call(int (*)(int), int, int, int) __asm__("frontier_sysv_abi.frontier_indirect_two_live_after_call");
    \\extern long long z_frontier_computed_i64_stack_arg_call(long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_abi.frontier_computed_i64_stack_arg_call");
    \\extern int z_frontier_seven_live_after_call(int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_seven_live_after_call");
    \\extern int z_frontier_eight_live_after_call(int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_eight_live_after_call");
    \\extern int z_frontier_nine_live_after_call(int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_nine_live_after_call");
    \\extern int z_frontier_ten_live_after_call(int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_ten_live_after_call");
    \\extern int z_frontier_eleven_live_after_call(int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_eleven_live_after_call");
    \\extern int z_frontier_twelve_live_after_call(int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_twelve_live_after_call");
    \\extern int z_frontier_thirteen_live_after_call(int, int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_thirteen_live_after_call");
    \\extern int z_frontier_fourteen_live_after_call(int, int, int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_fourteen_live_after_call");
    \\extern int z_frontier_eighteen_live_after_call(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int) __asm__("frontier_sysv_abi.frontier_eighteen_live_after_call");
    \\extern float z_frontier_f32_live_after_call(float, float) __asm__("frontier_sysv_abi.frontier_f32_live_after_call");
    \\extern double z_frontier_f64_live_after_call(double, double) __asm__("frontier_sysv_abi.frontier_f64_live_after_call");
    \\extern float z_frontier_two_f32_live_sum_after_call(float, float) __asm__("frontier_sysv_abi.frontier_two_f32_live_sum_after_call");
    \\extern double z_frontier_two_f64_live_sum_after_call(double, double) __asm__("frontier_sysv_abi.frontier_two_f64_live_sum_after_call");
    \\extern float z_frontier_indirect_two_f32_live_sum_after_call(void (*)(void), float, float) __asm__("frontier_sysv_abi.frontier_indirect_two_f32_live_sum_after_call");
    \\extern double z_frontier_indirect_two_f64_live_sum_after_call(void (*)(void), double, double) __asm__("frontier_sysv_abi.frontier_indirect_two_f64_live_sum_after_call");
    \\extern float z_frontier_two_void_calls_two_f32_live_sum(float, float) __asm__("frontier_sysv_abi.frontier_two_void_calls_two_f32_live_sum");
    \\extern double z_frontier_two_void_calls_two_f64_live_sum(double, double) __asm__("frontier_sysv_abi.frontier_two_void_calls_two_f64_live_sum");
    \\extern float z_frontier_two_indirect_void_calls_two_f32_live_sum(void (*)(void), float, float) __asm__("frontier_sysv_abi.frontier_two_indirect_void_calls_two_f32_live_sum");
    \\extern double z_frontier_two_indirect_void_calls_two_f64_live_sum(void (*)(void), double, double) __asm__("frontier_sysv_abi.frontier_two_indirect_void_calls_two_f64_live_sum");
    \\extern float z_frontier_mixed_i32_f32_live_sum_after_call(int, float) __asm__("frontier_sysv_abi.frontier_mixed_i32_f32_live_sum_after_call");
    \\extern double z_frontier_mixed_i32_f64_live_sum_after_call(int, double) __asm__("frontier_sysv_abi.frontier_mixed_i32_f64_live_sum_after_call");
    \\extern float z_frontier_indirect_mixed_i32_f32_live_sum_after_call(void (*)(void), int, float) __asm__("frontier_sysv_abi.frontier_indirect_mixed_i32_f32_live_sum_after_call");
    \\extern double z_frontier_indirect_mixed_i32_f64_live_sum_after_call(void (*)(void), int, double) __asm__("frontier_sysv_abi.frontier_indirect_mixed_i32_f64_live_sum_after_call");
    \\extern float z_frontier_two_void_calls_mixed_i32_f32_live_sum(int, float) __asm__("frontier_sysv_abi.frontier_two_void_calls_mixed_i32_f32_live_sum");
    \\extern double z_frontier_two_void_calls_mixed_i32_f64_live_sum(int, double) __asm__("frontier_sysv_abi.frontier_two_void_calls_mixed_i32_f64_live_sum");
    \\extern float z_frontier_two_indirect_void_calls_mixed_i32_f32_live_sum(void (*)(void), int, float) __asm__("frontier_sysv_abi.frontier_two_indirect_void_calls_mixed_i32_f32_live_sum");
    \\extern double z_frontier_two_indirect_void_calls_mixed_i32_f64_live_sum(void (*)(void), int, double) __asm__("frontier_sysv_abi.frontier_two_indirect_void_calls_mixed_i32_f64_live_sum");
    \\extern float z_frontier_two_f32_live_sum_after_arg_call(float, float) __asm__("frontier_sysv_abi.frontier_two_f32_live_sum_after_arg_call");
    \\extern double z_frontier_two_f64_live_sum_after_arg_call(double, double) __asm__("frontier_sysv_abi.frontier_two_f64_live_sum_after_arg_call");
    \\extern float z_frontier_three_f32_live_sum_after_two_arg_call(float, float, float) __asm__("frontier_sysv_abi.frontier_three_f32_live_sum_after_two_arg_call");
    \\extern double z_frontier_three_f64_live_sum_after_two_arg_call(double, double, double) __asm__("frontier_sysv_abi.frontier_three_f64_live_sum_after_two_arg_call");
    \\extern float z_frontier_four_f32_live_sum_after_three_arg_call(float, float, float, float) __asm__("frontier_sysv_abi.frontier_four_f32_live_sum_after_three_arg_call");
    \\extern double z_frontier_four_f64_live_sum_after_three_arg_call(double, double, double, double) __asm__("frontier_sysv_abi.frontier_four_f64_live_sum_after_three_arg_call");
    \\extern float z_frontier_six_f32_live_sum_after_five_arg_call(float, float, float, float, float, float) __asm__("frontier_sysv_abi.frontier_six_f32_live_sum_after_five_arg_call");
    \\extern double z_frontier_six_f64_live_sum_after_five_arg_call(double, double, double, double, double, double) __asm__("frontier_sysv_abi.frontier_six_f64_live_sum_after_five_arg_call");
    \\extern int z_frontier_i32_live_across_f64_arg_call(int, double, int) __asm__("frontier_sysv_abi.frontier_i32_live_across_f64_arg_call");
    \\extern float z_frontier_indirect_two_f32_live_sum_after_arg_call(void (*)(float), float, float) __asm__("frontier_sysv_abi.frontier_indirect_two_f32_live_sum_after_arg_call");
    \\extern double z_frontier_indirect_two_f64_live_sum_after_arg_call(void (*)(double), double, double) __asm__("frontier_sysv_abi.frontier_indirect_two_f64_live_sum_after_arg_call");
    \\extern int z_frontier_i32_live_across_indirect_f64_arg_call(void (*)(double), int, double, int) __asm__("frontier_sysv_abi.frontier_i32_live_across_indirect_f64_arg_call");
    \\extern float z_frontier_indirect_three_f32_live_sum_after_two_arg_call(void (*)(float, float), float, float, float) __asm__("frontier_sysv_abi.frontier_indirect_three_f32_live_sum_after_two_arg_call");
    \\extern double z_frontier_indirect_three_f64_live_sum_after_two_arg_call(void (*)(double, double), double, double, double) __asm__("frontier_sysv_abi.frontier_indirect_three_f64_live_sum_after_two_arg_call");
    \\extern float z_frontier_indirect_four_f32_live_sum_after_three_arg_call(void (*)(float, float, float), float, float, float, float) __asm__("frontier_sysv_abi.frontier_indirect_four_f32_live_sum_after_three_arg_call");
    \\extern double z_frontier_indirect_four_f64_live_sum_after_three_arg_call(void (*)(double, double, double), double, double, double, double) __asm__("frontier_sysv_abi.frontier_indirect_four_f64_live_sum_after_three_arg_call");
    \\extern float z_frontier_indirect_six_f32_live_sum_after_five_arg_call(void (*)(float, float, float, float, float), float, float, float, float, float, float) __asm__("frontier_sysv_abi.frontier_indirect_six_f32_live_sum_after_five_arg_call");
    \\extern double z_frontier_indirect_six_f64_live_sum_after_five_arg_call(void (*)(double, double, double, double, double), double, double, double, double, double, double) __asm__("frontier_sysv_abi.frontier_indirect_six_f64_live_sum_after_five_arg_call");
    \\extern float z_frontier_three_f32_live_sum_after_call(float, float, float) __asm__("frontier_sysv_abi.frontier_three_f32_live_sum_after_call");
    \\extern float z_frontier_four_f32_live_sum_after_call(float, float, float, float) __asm__("frontier_sysv_abi.frontier_four_f32_live_sum_after_call");
    \\extern float z_frontier_five_f32_live_sum_after_call(float, float, float, float, float) __asm__("frontier_sysv_abi.frontier_five_f32_live_sum_after_call");
    \\extern float z_frontier_six_f32_live_sum_after_call(float, float, float, float, float, float) __asm__("frontier_sysv_abi.frontier_six_f32_live_sum_after_call");
    \\extern double z_frontier_three_f64_live_sum_after_call(double, double, double) __asm__("frontier_sysv_abi.frontier_three_f64_live_sum_after_call");
    \\extern double z_frontier_four_f64_live_sum_after_call(double, double, double, double) __asm__("frontier_sysv_abi.frontier_four_f64_live_sum_after_call");
    \\extern double z_frontier_five_f64_live_sum_after_call(double, double, double, double, double) __asm__("frontier_sysv_abi.frontier_five_f64_live_sum_after_call");
    \\extern double z_frontier_six_f64_live_sum_after_call(double, double, double, double, double, double) __asm__("frontier_sysv_abi.frontier_six_f64_live_sum_after_call");
    \\extern float z_frontier_five_f32_external_call(float, float, float, float, float) __asm__("frontier_sysv_abi.frontier_five_f32_external_call");
    \\extern double z_frontier_five_f64_external_call(double, double, double, double, double) __asm__("frontier_sysv_abi.frontier_five_f64_external_call");
    \\extern float z_frontier_indirect_five_f32_external_call(float (*)(float, float, float, float, float), float, float, float, float, float) __asm__("frontier_sysv_abi.frontier_indirect_five_f32_external_call");
    \\extern double z_frontier_indirect_five_f64_external_call(double (*)(double, double, double, double, double), double, double, double, double, double) __asm__("frontier_sysv_abi.frontier_indirect_five_f64_external_call");
    \\volatile float frontier_seen_f32 = 0.0f;
    \\volatile double frontier_seen_f64 = 0.0;
    \\volatile int frontier_order_step = 0;
    \\void frontier_touch_f32(float value) { frontier_seen_f32 = value; }
    \\void frontier_touch_f64(double value) { frontier_seen_f64 = value; }
    \\void frontier_touch2_f32(float a, float b) { frontier_seen_f32 = a + b; }
    \\void frontier_touch2_f64(double a, double b) { frontier_seen_f64 = a + b; }
    \\void frontier_touch3_f32(float a, float b, float c) { frontier_seen_f32 = a + b + c; }
    \\void frontier_touch3_f64(double a, double b, double c) { frontier_seen_f64 = a + b + c; }
    \\void frontier_touch5_f32(float a, float b, float c, float d, float e) { frontier_seen_f32 = a + b + c + d + e; }
    \\void frontier_touch5_f64(double a, double b, double c, double d, double e) { frontier_seen_f64 = a + b + c + d + e; }
    \\void frontier_touch_none(void) {}
    \\void frontier_touch_ordered(void) { frontier_order_step = frontier_order_step == 1 ? 2 : -100; }
    \\void frontier_touch_ordered_after_two(void) { frontier_order_step = frontier_order_step == 2 ? 3 : -300; }
    \\int frontier_ordered_i32(int value) { if (frontier_order_step != 0) return -1000; frontier_order_step = 1; return value + 5; }
    \\int frontier_ordered2_i32(int value) { if (frontier_order_step != 1) return -2000; frontier_order_step = 2; return value + 7; }
    \\double frontier_ordered_f64(double value) { if (frontier_order_step != 0) return -1000.0; frontier_order_step = 1; return value + 1.5; }
    \\float frontier_sum5_f32(float a, float b, float c, float d, float e) { return a + b + c + d + e; }
    \\double frontier_sum5_f64(double a, double b, double c, double d, double e) { return a + b + c + d + e; }
    \\float frontier_sub_f32(float a, float b) { return a - b; }
    \\double frontier_sub_f64(double a, double b) { return a - b; }
    \\int frontier_sum6_i32(int a, int b, int c, int d, int e, int f) { return a + b + c + d + e + f; }
    \\int frontier_sum12_i32(int a, int b, int c, int d, int e, int f, int g, int h, int i, int j, int k, int l) { return a + b + c + d + e + f + g + h + i + j + k + l; }
    \\int frontier_sum14_i32(int a, int b, int c, int d, int e, int f, int g, int h, int i, int j, int k, int l, int m, int n) { return a + b + c + d + e + f + g + h + i + j + k + l + m + n; }
    \\int frontier_sum18_i32(int a, int b, int c, int d, int e, int f, int g, int h, int i, int j, int k, int l, int m, int n, int o, int p, int q, int r) { return a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p + q + r; }
    \\int frontier_sum24_i32(int a, int b, int c, int d, int e, int f, int g, int h, int i, int j, int k, int l, int m, int n, int o, int p, int q, int r, int s, int t, int u, int v, int w, int x) { return a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p + q + r + s + t + u + v + w + x; }
    \\int frontier_sub_i32(int a, int b) { return a - b; }
    \\int frontier_weighted3_i32(int a, int b, int c) { return 100 * a + 10 * b + c; }
    \\int frontier_weighted6_i32(int a, int b, int c, int d, int e, int f) { return 100000 * a + 10000 * b + 1000 * c + 100 * d + 10 * e + f; }
    \\long long frontier_sum6_i64(long long a, long long b, long long c, long long d, long long e, long long f) { return a + b + c + d + e + f; }
    \\long long frontier_sum8_i64(long long a, long long b, long long c, long long d, long long e, long long f, long long g, long long h) { return a + b + c + d + e + f + g + h; }
    \\long long frontier_sub_i64(long long a, long long b) { return a - b; }
    \\long long frontier_weighted3_i64(long long a, long long b, long long c) { return 100 * a + 10 * b + c; }
    \\int frontier_sum8_ptr(const int *a, const int *b, const int *c, const int *d, const int *e, const int *f, const int *g, const int *h) { return *a + *b + *c + *d + *e + *f + *g + *h; }
    \\const int *frontier_choose_ptr(const int *a, const int *b, int tag) { return tag == 0 ? a : b; }
    \\int frontier_id_c_i32(int value) { return value; }
    \\struct Pair64 frontier_make_pair64(long long a, long long b) { struct Pair64 result = { a, b }; return result; }
    \\long long frontier_pair64_first(struct Pair64 value) { return value.a; }
    \\int main(void) {
    \\    struct Pair64 pair = z_frontier_pair64_make(0x1122334455667788LL, 0x0102030405060708LL);
    \\    if (pair.a != 0x1122334455667788LL || pair.b != 0x0102030405060708LL) return 1;
    \\    if (z_frontier_pair64_first(pair) != 0x1122334455667788LL) return 2;
    \\    if (z_frontier_pair64_second(pair) != 0x0102030405060708LL) return 3;
    \\    if (z_frontier_two_live_after_call(7, 11, 13) != 31) return 4;
    \\    if (z_frontier_three_live_after_call(7, 11, 13, 17) != 48) return 5;
    \\    if (z_frontier_four_live_after_call(2, 3, 5, 7) != 24) return 6;
    \\    if (z_frontier_five_live_after_call(2, 3, 5, 7, 11) != 39) return 7;
    \\    if (z_frontier_six_live_after_call(2, 3, 5, 7, 11, 13) != 54) return 8;
    \\    if (z_frontier_two_void_calls_six_live(2, 3, 5, 7, 11, 13) != 41) return 34;
    \\    if (z_frontier_two_indirect_void_calls_six_live(frontier_touch_none, 2, 3, 5, 7, 11, 13) != 41) return 52;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_call_result_live_across_second_call(37) != 79 || frontier_order_step != 2) return 80;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_two_i32_results_across_calls(11, 13) != 47 || frontier_order_step != 2) return 81;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_two_i32_results_across_indirect_call(frontier_ordered2_i32, 17, 19) != 65 || frontier_order_step != 2) return 82;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_f64_result_live_across_void_call(2.25, 4.75) != 8.5 || frontier_order_step != 2) return 126;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_f64_result_live_across_indirect_void_call(frontier_touch_ordered, 3.5, 5.0) != 10.0 || frontier_order_step != 2) return 127;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_indirect_f64_result_live_across_void_call(frontier_ordered_f64, 4.25, 6.5) != 12.25 || frontier_order_step != 2) return 128;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_indirect_f64_result_live_across_indirect_void_call(frontier_ordered_f64, frontier_touch_ordered, 5.5, 7.25) != 14.25 || frontier_order_step != 2) return 129;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_two_i32_results_live_across_void_call(23, 29) != 87 || frontier_order_step != 3) return 83;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_two_i32_results_live_across_indirect_void_call(frontier_touch_ordered_after_two, 31, 37) != 111 || frontier_order_step != 3) return 84;
    \\    frontier_order_step = 0;
    \\    if (z_frontier_indirect_first_i32_result_live_across_void_call(frontier_ordered_i32, 41, 43) != 137 || frontier_order_step != 3) return 85;
    \\    if (z_frontier_six_stack_arg_call() != 78) return 35;
    \\    if (z_frontier_eight_stack_arg_call() != 105) return 46;
    \\    if (z_frontier_twelve_stack_arg_call() != 171) return 47;
    \\    if (z_frontier_eighteen_stack_arg_call() != 300) return 70;
    \\    if (z_frontier_stack_arg_forward(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) != 78) return 36;
    \\    if (z_frontier_stack_arg_to_registers(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) != 57) return 37;
    \\    if (z_frontier_indirect_stack_arg_to_registers(frontier_sum6_i32, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) != 57) return 38;
    \\    if (z_frontier_indirect_stack_arg_forward(frontier_sum12_i32, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) != 78) return 39;
    \\    if (z_frontier_indirect_eight_stack_arg_forward(frontier_sum14_i32, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14) != 105) return 48;
    \\    if (z_frontier_indirect_eighteen_stack_arg_forward(frontier_sum24_i32, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24) != 300) return 71;
    \\    int ptr_values[8] = { 3, 5, 7, 11, 13, 17, 19, 23 };
    \\    if (z_frontier_ptr_stack_arg_forward(&ptr_values[0], &ptr_values[1], &ptr_values[2], &ptr_values[3], &ptr_values[4], &ptr_values[5], &ptr_values[6], &ptr_values[7]) != 98) return 106;
    \\    if (z_frontier_indirect_ptr_stack_arg_forward(frontier_sum8_ptr, &ptr_values[0], &ptr_values[1], &ptr_values[2], &ptr_values[3], &ptr_values[4], &ptr_values[5], &ptr_values[6], &ptr_values[7]) != 98) return 107;
    \\    if (z_frontier_ptr_return_param(&ptr_values[0], &ptr_values[3]) != &ptr_values[3]) return 108;
    \\    if (*z_frontier_ptr_return_direct_call(&ptr_values[1], &ptr_values[4], 1) != 13) return 109;
    \\    if (z_frontier_ptr_return_indirect_call(frontier_choose_ptr, &ptr_values[2], &ptr_values[5], 0) != &ptr_values[2]) return 110;
    \\    if (z_frontier_i32_swapped_direct_call(11, 47) != 36) return 111;
    \\    if (z_frontier_i64_swapped_direct_call(11, 47) != 36) return 112;
    \\    if (z_frontier_ptr_swapped_direct_call(&ptr_values[1], &ptr_values[6], 0) != &ptr_values[6]) return 113;
    \\    if (z_frontier_ptr_swapped_direct_call(&ptr_values[1], &ptr_values[6], 1) != &ptr_values[1]) return 114;
    \\    if (z_frontier_f32_swapped_direct_call(11.0f, 47.0f) != 36.0f) return 122;
    \\    if (z_frontier_f64_swapped_direct_call(11.0, 47.0) != 36.0) return 123;
    \\    if (z_frontier_i32_three_cycle_direct_call(3, 5, 7) != 573) return 115;
    \\    if (z_frontier_i64_three_cycle_direct_call(3, 5, 7) != 573) return 116;
    \\    if (z_frontier_i32_six_cycle_direct_call(1, 2, 3, 4, 5, 6) != 234561) return 117;
    \\    if (z_frontier_i32_swapped_indirect_call(13, 53, frontier_sub_i32) != 40) return 118;
    \\    if (z_frontier_i64_swapped_indirect_call(13, 53, frontier_sub_i64) != 40) return 119;
    \\    if (z_frontier_ptr_swapped_indirect_call(&ptr_values[2], &ptr_values[7], 0, frontier_choose_ptr) != &ptr_values[7]) return 120;
    \\    if (z_frontier_ptr_swapped_indirect_call(&ptr_values[2], &ptr_values[7], 1, frontier_choose_ptr) != &ptr_values[2]) return 121;
    \\    if (z_frontier_f32_swapped_indirect_call(13.0f, 53.0f, frontier_sub_f32) != 40.0f) return 124;
    \\    if (z_frontier_f64_swapped_indirect_call(13.0, 53.0, frontier_sub_f64) != 40.0) return 125;
    \\    if (z_frontier_computed_stack_arg_call(1, 2, 3, 4, 5, 6, 7) != 79) return 44;
    \\    if (z_frontier_i64_stack_arg_to_registers(1, 2, 3, 4, 5, 6, 7000000000LL, 8000000000LL, 9000000000LL, 10000000000LL, 11000000000LL, 12000000000LL) != 57000000000LL) return 42;
    \\    if (z_frontier_indirect_i64_stack_arg_forward(frontier_sum8_i64, 1000000000LL, 2000000000LL, 3000000000LL, 4000000000LL, 5000000000LL, 6000000000LL, 7000000000LL, 8000000000LL) != 36000000000LL) return 43;
    \\    struct Pair64 indirect_pair = z_frontier_indirect_pair64_make(frontier_make_pair64, 1234, 5678);
    \\    if (indirect_pair.a != 1234 || indirect_pair.b != 5678) return 49;
    \\    if (z_frontier_indirect_pair64_first(frontier_pair64_first, indirect_pair) != 1234) return 50;
    \\    if (z_frontier_indirect_two_live_after_call(frontier_id_c_i32, 5, 7, 11) != 23) return 51;
    \\    if (z_frontier_computed_i64_stack_arg_call(1, 2, 3, 4, 5, 6, 7) != 37) return 45;
    \\    if (z_frontier_seven_live_after_call(2, 3, 5, 7, 11, 13, 17) != 71) return 23;
    \\    if (z_frontier_eight_live_after_call(2, 3, 5, 7, 11, 13, 17, 19) != 90) return 24;
    \\    if (z_frontier_nine_live_after_call(2, 3, 5, 7, 11, 13, 17, 19, 23) != 113) return 25;
    \\    if (z_frontier_ten_live_after_call(2, 3, 5, 7, 11, 13, 17, 19, 23, 29) != 142) return 26;
    \\    if (z_frontier_eleven_live_after_call(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31) != 173) return 27;
    \\    if (z_frontier_twelve_live_after_call(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37) != 210) return 28;
    \\    if (z_frontier_thirteen_live_after_call(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41) != 251) return 31;
    \\    if (z_frontier_fourteen_live_after_call(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43) != 294) return 32;
    \\    if (z_frontier_eighteen_live_after_call(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61) != 514) return 33;
    \\    if (z_frontier_f32_live_after_call(4.5f, 2.25f) != 4.5f || frontier_seen_f32 != 2.25f) return 9;
    \\    if (z_frontier_f64_live_after_call(9.5, 3.25) != 9.5 || frontier_seen_f64 != 3.25) return 10;
    \\    if (z_frontier_two_f32_live_sum_after_call(1.5f, 2.75f) != 4.25f) return 11;
    \\    if (z_frontier_two_f64_live_sum_after_call(1.25, 2.5) != 3.75) return 12;
    \\    if (z_frontier_indirect_two_f32_live_sum_after_call(frontier_touch_none, 1.5f, 2.75f) != 4.25f) return 56;
    \\    if (z_frontier_indirect_two_f64_live_sum_after_call(frontier_touch_none, 1.25, 2.5) != 3.75) return 57;
    \\    if (z_frontier_two_void_calls_two_f32_live_sum(1.5f, 2.75f) != 4.25f) return 94;
    \\    if (z_frontier_two_void_calls_two_f64_live_sum(1.25, 2.5) != 3.75) return 95;
    \\    if (z_frontier_two_indirect_void_calls_two_f32_live_sum(frontier_touch_none, 1.5f, 2.75f) != 4.25f) return 96;
    \\    if (z_frontier_two_indirect_void_calls_two_f64_live_sum(frontier_touch_none, 1.25, 2.5) != 3.75) return 97;
    \\    if (z_frontier_mixed_i32_f32_live_sum_after_call(7, 2.5f) != 9.5f) return 98;
    \\    if (z_frontier_mixed_i32_f64_live_sum_after_call(7, 2.5) != 9.5) return 99;
    \\    if (z_frontier_indirect_mixed_i32_f32_live_sum_after_call(frontier_touch_none, 7, 2.5f) != 9.5f) return 100;
    \\    if (z_frontier_indirect_mixed_i32_f64_live_sum_after_call(frontier_touch_none, 7, 2.5) != 9.5) return 101;
    \\    if (z_frontier_two_void_calls_mixed_i32_f32_live_sum(7, 2.5f) != 9.5f) return 102;
    \\    if (z_frontier_two_void_calls_mixed_i32_f64_live_sum(7, 2.5) != 9.5) return 103;
    \\    if (z_frontier_two_indirect_void_calls_mixed_i32_f32_live_sum(frontier_touch_none, 7, 2.5f) != 9.5f) return 104;
    \\    if (z_frontier_two_indirect_void_calls_mixed_i32_f64_live_sum(frontier_touch_none, 7, 2.5) != 9.5) return 105;
    \\    if (z_frontier_two_f32_live_sum_after_arg_call(1.5f, 2.75f) != 4.25f || frontier_seen_f32 != 2.75f) return 29;
    \\    if (z_frontier_two_f64_live_sum_after_arg_call(1.25, 2.5) != 3.75 || frontier_seen_f64 != 2.5) return 30;
    \\    if (z_frontier_three_f32_live_sum_after_two_arg_call(1.5f, 2.75f, 3.25f) != 7.5f || frontier_seen_f32 != 6.0f) return 88;
    \\    if (z_frontier_three_f64_live_sum_after_two_arg_call(1.25, 2.5, 3.75) != 7.5 || frontier_seen_f64 != 6.25) return 89;
    \\    if (z_frontier_four_f32_live_sum_after_three_arg_call(1.5f, 2.75f, 3.25f, 4.5f) != 12.0f || frontier_seen_f32 != 10.5f) return 90;
    \\    if (z_frontier_four_f64_live_sum_after_three_arg_call(1.25, 2.5, 3.75, 4.5) != 12.0 || frontier_seen_f64 != 10.75) return 91;
    \\    if (z_frontier_six_f32_live_sum_after_five_arg_call(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f) != 21.0f || frontier_seen_f32 != 20.0f) return 92;
    \\    if (z_frontier_six_f64_live_sum_after_five_arg_call(1.5, 2.25, 3.75, 4.5, 5.0, 6.0) != 23.0 || frontier_seen_f64 != 21.5) return 93;
    \\    if (z_frontier_i32_live_across_f64_arg_call(101, 13.5, 103) != 204 || frontier_seen_f64 != 13.5) return 86;
    \\    if (z_frontier_indirect_two_f32_live_sum_after_arg_call(frontier_touch_f32, 1.5f, 2.75f) != 4.25f || frontier_seen_f32 != 2.75f) return 72;
    \\    if (z_frontier_indirect_two_f64_live_sum_after_arg_call(frontier_touch_f64, 1.25, 2.5) != 3.75 || frontier_seen_f64 != 2.5) return 73;
    \\    if (z_frontier_i32_live_across_indirect_f64_arg_call(frontier_touch_f64, 107, 17.5, 109) != 216 || frontier_seen_f64 != 17.5) return 87;
    \\    if (z_frontier_indirect_three_f32_live_sum_after_two_arg_call(frontier_touch2_f32, 1.5f, 2.75f, 3.25f) != 7.5f || frontier_seen_f32 != 6.0f) return 74;
    \\    if (z_frontier_indirect_three_f64_live_sum_after_two_arg_call(frontier_touch2_f64, 1.25, 2.5, 3.75) != 7.5 || frontier_seen_f64 != 6.25) return 75;
    \\    if (z_frontier_indirect_four_f32_live_sum_after_three_arg_call(frontier_touch3_f32, 1.5f, 2.75f, 3.25f, 4.5f) != 12.0f || frontier_seen_f32 != 10.5f) return 76;
    \\    if (z_frontier_indirect_four_f64_live_sum_after_three_arg_call(frontier_touch3_f64, 1.25, 2.5, 3.75, 4.5) != 12.0 || frontier_seen_f64 != 10.75) return 77;
    \\    if (z_frontier_indirect_six_f32_live_sum_after_five_arg_call(frontier_touch5_f32, 1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f) != 21.0f || frontier_seen_f32 != 20.0f) return 78;
    \\    if (z_frontier_indirect_six_f64_live_sum_after_five_arg_call(frontier_touch5_f64, 1.5, 2.25, 3.75, 4.5, 5.0, 6.0) != 23.0 || frontier_seen_f64 != 21.5) return 79;
    \\    if (z_frontier_three_f32_live_sum_after_call(1.5f, 2.75f, 3.25f) != 7.5f) return 13;
    \\    if (z_frontier_three_f64_live_sum_after_call(1.25, 2.5, 3.75) != 7.5) return 14;
    \\    if (z_frontier_four_f32_live_sum_after_call(1.5f, 2.75f, 3.25f, 4.5f) != 12.0f) return 15;
    \\    if (z_frontier_four_f64_live_sum_after_call(1.25, 2.5, 3.75, 4.5) != 12.0) return 16;
    \\    if (z_frontier_five_f32_live_sum_after_call(1.0f, 2.0f, 3.0f, 4.0f, 5.0f) != 15.0f) return 17;
    \\    if (z_frontier_five_f64_live_sum_after_call(1.5, 2.25, 3.75, 4.5, 5.0) != 17.0) return 18;
    \\    if (z_frontier_six_f32_live_sum_after_call(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f) != 21.0f) return 19;
    \\    if (z_frontier_six_f64_live_sum_after_call(1.5, 2.25, 3.75, 4.5, 5.0, 6.0) != 23.0) return 20;
    \\    if (z_frontier_five_f32_external_call(1.0f, 2.0f, 3.0f, 4.0f, 5.0f) != 15.0f) return 21;
    \\    if (z_frontier_five_f64_external_call(1.5, 2.25, 3.75, 4.5, 5.0) != 17.0) return 22;
    \\    if (z_frontier_indirect_five_f32_external_call(frontier_sum5_f32, 1.0f, 2.0f, 3.0f, 4.0f, 5.0f) != 15.0f) return 40;
    \\    if (z_frontier_indirect_five_f64_external_call(frontier_sum5_f64, 1.5, 2.25, 3.75, 4.5, 5.0) != 17.0) return 41;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_sret_byval.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier SysV sret/byval ABI", .c_body =
    \\struct Big3 { long long a; long long b; long long c; };
    \\struct Big4 { long long a; long long b; long long c; long long d; };
    \\struct Big5 { long long a; long long b; long long c; long long d; long long e; };
    \\struct Big6 { long long a; long long b; long long c; long long d; long long e; long long f; };
    \\struct Big7 { long long a; long long b; long long c; long long d; long long e; long long f; long long g; };
    \\struct Big8 { long long a; long long b; long long c; long long d; long long e; long long f; long long g; long long h; };
    \\struct Big12 { long long a; long long b; long long c; long long d; long long e; long long f; long long g; long long h; long long i; long long j; long long k; long long l; };
    \\struct Big16 { long long a; long long b; long long c; long long d; long long e; long long f; long long g; long long h; long long i; long long j; long long k; long long l; long long m; long long n; long long o; long long p; };
    \\struct Big20 { long long a; long long b; long long c; long long d; long long e; long long f; long long g; long long h; long long i; long long j; long long k; long long l; long long m; long long n; long long o; long long p; long long q; long long r; long long s; long long t; };
    \\struct BigNested { struct Big3 left; struct Big3 right; };
    \\struct BigMixed { long long a; int b; long long c; int d; };
    \\struct NarrowInner { unsigned short b; int c; };
    \\struct BigNarrow { unsigned char a; struct NarrowInner inner; long long d; };
    \\struct BigArray { long long values[5]; };
    \\struct BigDouble { double a; double b; double c; };
    \\struct BigDoubleArray { double values[3]; };
    \\struct BigFloat { float a; float b; float c; float d; float e; };
    \\struct BigPtrDouble { const long long *ptr; double value; long long tag; };
    \\struct BigArrayMixed { int ints[2]; double doubles[2]; const long long *ptr; };
    \\struct ScalarMixed { unsigned char a; unsigned short b; int c; long long d; const long long *ptr; float f; double g; };
    \\struct ScalarNestedInner { unsigned char a; unsigned short b; };
    \\struct ScalarNested { struct ScalarNestedInner inner; int c; double d; const long long *ptr; };
    \\struct ScalarArray { int ints[3]; double doubles[2]; const long long *ptr; };
    \\extern struct Big3 z_frontier_big3_make(long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big3_make");
    \\extern long long z_frontier_big3_edges(struct Big3) __asm__("frontier_sysv_sret_byval.frontier_big3_edges");
    \\extern struct Big3 z_frontier_big3_copy(struct Big3) __asm__("frontier_sysv_sret_byval.frontier_big3_copy");
    \\extern struct Big3 z_frontier_direct_big3_copy(struct Big3) __asm__("frontier_sysv_sret_byval.frontier_direct_big3_copy");
    \\extern struct Big3 z_frontier_indirect_big3_copy(struct Big3 (*)(struct Big3), struct Big3) __asm__("frontier_sysv_sret_byval.frontier_indirect_big3_copy");
    \\extern struct Big4 z_frontier_big4_make(long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big4_make");
    \\extern long long z_frontier_big4_edges(struct Big4) __asm__("frontier_sysv_sret_byval.frontier_big4_edges");
    \\extern struct Big4 z_frontier_big4_copy(struct Big4) __asm__("frontier_sysv_sret_byval.frontier_big4_copy");
    \\extern struct Big4 z_frontier_direct_big4_copy(struct Big4) __asm__("frontier_sysv_sret_byval.frontier_direct_big4_copy");
    \\extern struct Big4 z_frontier_indirect_big4_copy(struct Big4 (*)(struct Big4), struct Big4) __asm__("frontier_sysv_sret_byval.frontier_indirect_big4_copy");
    \\extern struct Big5 z_frontier_big5_make(long long, long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big5_make");
    \\extern long long z_frontier_big5_edges(struct Big5) __asm__("frontier_sysv_sret_byval.frontier_big5_edges");
    \\extern long long z_frontier_big5_inner(struct Big5) __asm__("frontier_sysv_sret_byval.frontier_big5_inner");
    \\extern struct Big5 z_frontier_big5_copy(struct Big5) __asm__("frontier_sysv_sret_byval.frontier_big5_copy");
    \\extern struct Big5 z_frontier_direct_big5_copy(struct Big5) __asm__("frontier_sysv_sret_byval.frontier_direct_big5_copy");
    \\extern struct Big5 z_frontier_indirect_big5_copy(struct Big5 (*)(struct Big5), struct Big5) __asm__("frontier_sysv_sret_byval.frontier_indirect_big5_copy");
    \\extern struct Big6 z_frontier_big6_make(long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big6_make");
    \\extern long long z_frontier_big6_middle(struct Big6) __asm__("frontier_sysv_sret_byval.frontier_big6_middle");
    \\extern struct Big6 z_frontier_big6_copy(struct Big6) __asm__("frontier_sysv_sret_byval.frontier_big6_copy");
    \\extern struct Big7 z_frontier_big7_make(long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big7_make");
    \\extern long long z_frontier_big7_inner(struct Big7) __asm__("frontier_sysv_sret_byval.frontier_big7_inner");
    \\extern struct Big7 z_frontier_big7_copy(struct Big7) __asm__("frontier_sysv_sret_byval.frontier_big7_copy");
    \\extern struct Big8 z_frontier_big8_make(long long, long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big8_make");
    \\extern long long z_frontier_big8_inner(struct Big8) __asm__("frontier_sysv_sret_byval.frontier_big8_inner");
    \\extern struct Big8 z_frontier_big8_copy(struct Big8) __asm__("frontier_sysv_sret_byval.frontier_big8_copy");
    \\extern struct Big12 z_frontier_big12_make(long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big12_make");
    \\extern long long z_frontier_big12_inner(struct Big12) __asm__("frontier_sysv_sret_byval.frontier_big12_inner");
    \\extern struct Big12 z_frontier_big12_copy(struct Big12) __asm__("frontier_sysv_sret_byval.frontier_big12_copy");
    \\extern struct Big16 z_frontier_big16_make(long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big16_make");
    \\extern long long z_frontier_big16_inner(struct Big16) __asm__("frontier_sysv_sret_byval.frontier_big16_inner");
    \\extern struct Big16 z_frontier_big16_copy(struct Big16) __asm__("frontier_sysv_sret_byval.frontier_big16_copy");
    \\extern struct Big20 z_frontier_big20_make(long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long, long long) __asm__("frontier_sysv_sret_byval.frontier_big20_make");
    \\extern long long z_frontier_big20_inner(struct Big20) __asm__("frontier_sysv_sret_byval.frontier_big20_inner");
    \\extern struct Big20 z_frontier_big20_copy(struct Big20) __asm__("frontier_sysv_sret_byval.frontier_big20_copy");
    \\extern struct BigNested z_frontier_big_nested_copy(struct BigNested) __asm__("frontier_sysv_sret_byval.frontier_big_nested_copy");
    \\extern struct BigNested z_frontier_direct_big_nested_copy(struct BigNested) __asm__("frontier_sysv_sret_byval.frontier_direct_big_nested_copy");
    \\extern struct BigNested z_frontier_indirect_big_nested_copy(struct BigNested (*)(struct BigNested), struct BigNested) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_nested_copy");
    \\extern long long z_frontier_big_nested_sum_inner(struct BigNested) __asm__("frontier_sysv_sret_byval.frontier_big_nested_sum_inner");
    \\extern struct BigMixed z_frontier_big_mixed_copy(struct BigMixed) __asm__("frontier_sysv_sret_byval.frontier_big_mixed_copy");
    \\extern struct BigMixed z_frontier_direct_big_mixed_copy(struct BigMixed) __asm__("frontier_sysv_sret_byval.frontier_direct_big_mixed_copy");
    \\extern struct BigMixed z_frontier_indirect_big_mixed_copy(struct BigMixed (*)(struct BigMixed), struct BigMixed) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_mixed_copy");
    \\extern struct BigNarrow z_frontier_big_narrow_copy(struct BigNarrow) __asm__("frontier_sysv_sret_byval.frontier_big_narrow_copy");
    \\extern struct BigNarrow z_frontier_direct_big_narrow_copy(struct BigNarrow) __asm__("frontier_sysv_sret_byval.frontier_direct_big_narrow_copy");
    \\extern struct BigNarrow z_frontier_indirect_big_narrow_copy(struct BigNarrow (*)(struct BigNarrow), struct BigNarrow) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_narrow_copy");
    \\extern struct BigArray z_frontier_big_array_copy(struct BigArray) __asm__("frontier_sysv_sret_byval.frontier_big_array_copy");
    \\extern struct BigArray z_frontier_direct_big_array_copy(struct BigArray) __asm__("frontier_sysv_sret_byval.frontier_direct_big_array_copy");
    \\extern struct BigArray z_frontier_indirect_big_array_copy(struct BigArray (*)(struct BigArray), struct BigArray) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_array_copy");
    \\extern long long z_frontier_big_array_sum_edges(struct BigArray) __asm__("frontier_sysv_sret_byval.frontier_big_array_sum_edges");
    \\extern struct BigDouble z_frontier_big_double_copy(struct BigDouble) __asm__("frontier_sysv_sret_byval.frontier_big_double_copy");
    \\extern struct BigDouble z_frontier_direct_big_double_copy(struct BigDouble) __asm__("frontier_sysv_sret_byval.frontier_direct_big_double_copy");
    \\extern struct BigDouble z_frontier_indirect_big_double_copy(struct BigDouble (*)(struct BigDouble), struct BigDouble) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_double_copy");
    \\extern struct BigDoubleArray z_frontier_big_double_array_copy(struct BigDoubleArray) __asm__("frontier_sysv_sret_byval.frontier_big_double_array_copy");
    \\extern struct BigDoubleArray z_frontier_direct_big_double_array_copy(struct BigDoubleArray) __asm__("frontier_sysv_sret_byval.frontier_direct_big_double_array_copy");
    \\extern struct BigDoubleArray z_frontier_indirect_big_double_array_copy(struct BigDoubleArray (*)(struct BigDoubleArray), struct BigDoubleArray) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_double_array_copy");
    \\extern struct BigFloat z_frontier_big_float_copy(struct BigFloat) __asm__("frontier_sysv_sret_byval.frontier_big_float_copy");
    \\extern struct BigFloat z_frontier_direct_big_float_copy(struct BigFloat) __asm__("frontier_sysv_sret_byval.frontier_direct_big_float_copy");
    \\extern struct BigFloat z_frontier_indirect_big_float_copy(struct BigFloat (*)(struct BigFloat), struct BigFloat) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_float_copy");
    \\extern struct BigPtrDouble z_frontier_big_ptr_double_copy(struct BigPtrDouble) __asm__("frontier_sysv_sret_byval.frontier_big_ptr_double_copy");
    \\extern struct BigPtrDouble z_frontier_direct_big_ptr_double_copy(struct BigPtrDouble) __asm__("frontier_sysv_sret_byval.frontier_direct_big_ptr_double_copy");
    \\extern struct BigPtrDouble z_frontier_indirect_big_ptr_double_copy(struct BigPtrDouble (*)(struct BigPtrDouble), struct BigPtrDouble) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_ptr_double_copy");
    \\extern struct BigArrayMixed z_frontier_big_array_mixed_copy(struct BigArrayMixed) __asm__("frontier_sysv_sret_byval.frontier_big_array_mixed_copy");
    \\extern struct BigArrayMixed z_frontier_direct_big_array_mixed_copy(struct BigArrayMixed) __asm__("frontier_sysv_sret_byval.frontier_direct_big_array_mixed_copy");
    \\extern struct BigArrayMixed z_frontier_indirect_big_array_mixed_copy(struct BigArrayMixed (*)(struct BigArrayMixed), struct BigArrayMixed) __asm__("frontier_sysv_sret_byval.frontier_indirect_big_array_mixed_copy");
    \\extern struct ScalarMixed z_frontier_scalar_mixed_make(unsigned char, unsigned short, int, long long, const long long *, float, double) __asm__("frontier_sysv_sret_byval.frontier_scalar_mixed_make");
    \\extern struct ScalarNested z_frontier_scalar_nested_make(unsigned char, unsigned short, int, double, const long long *) __asm__("frontier_sysv_sret_byval.frontier_scalar_nested_make");
    \\extern struct ScalarArray z_frontier_scalar_array_make(int, int, int, double, double, const long long *) __asm__("frontier_sysv_sret_byval.frontier_scalar_array_make");
    \\int main(void) {
    \\    struct Big3 made = z_frontier_big3_make(5, 7, 11);
    \\    if (made.a != 5 || made.b != 7 || made.c != 11) return 1;
    \\    struct Big3 input = { .a = 13, .b = 17, .c = 19 };
    \\    if (z_frontier_big3_edges(input) != 32) return 2;
    \\    struct Big3 copied3 = z_frontier_big3_copy(input);
    \\    if (copied3.a != 13 || copied3.b != 17 || copied3.c != 19) return 3;
    \\    struct Big3 direct3 = z_frontier_direct_big3_copy(input);
    \\    if (direct3.a != 13 || direct3.b != 17 || direct3.c != 19) return 66;
    \\    struct Big3 indirect3 = z_frontier_indirect_big3_copy(z_frontier_big3_copy, input);
    \\    if (indirect3.a != 13 || indirect3.b != 17 || indirect3.c != 19) return 67;
    \\    struct Big4 made4 = z_frontier_big4_make(23, 29, 31, 37);
    \\    if (made4.a != 23 || made4.b != 29 || made4.c != 31 || made4.d != 37) return 4;
    \\    struct Big4 input4 = { .a = 41, .b = 43, .c = 47, .d = 53 };
    \\    if (z_frontier_big4_edges(input4) != 94) return 5;
    \\    struct Big4 copied4 = z_frontier_big4_copy(input4);
    \\    if (copied4.a != 41 || copied4.b != 43 || copied4.c != 47 || copied4.d != 53) return 6;
    \\    struct Big4 direct4 = z_frontier_direct_big4_copy(input4);
    \\    if (direct4.a != 41 || direct4.b != 43 || direct4.c != 47 || direct4.d != 53) return 68;
    \\    struct Big4 indirect4 = z_frontier_indirect_big4_copy(z_frontier_big4_copy, input4);
    \\    if (indirect4.a != 41 || indirect4.b != 43 || indirect4.c != 47 || indirect4.d != 53) return 69;
    \\    struct Big5 made5 = z_frontier_big5_make(2, 3, 5, 7, 11);
    \\    if (made5.a != 2 || made5.b != 3 || made5.c != 5 || made5.d != 7 || made5.e != 11) return 7;
    \\    struct Big5 input5 = { .a = 13, .b = 17, .c = 19, .d = 23, .e = 29 };
    \\    if (z_frontier_big5_edges(input5) != 42) return 8;
    \\    if (z_frontier_big5_inner(input5) != 40) return 9;
    \\    struct Big5 copied5 = z_frontier_big5_copy(input5);
    \\    if (copied5.a != 13 || copied5.b != 17 || copied5.c != 19 || copied5.d != 23 || copied5.e != 29) return 10;
    \\    struct Big5 direct5 = z_frontier_direct_big5_copy(input5);
    \\    if (direct5.a != 13 || direct5.b != 17 || direct5.c != 19 || direct5.d != 23 || direct5.e != 29) return 53;
    \\    struct Big5 indirect5 = z_frontier_indirect_big5_copy(z_frontier_big5_copy, input5);
    \\    if (indirect5.a != 13 || indirect5.b != 17 || indirect5.c != 19 || indirect5.d != 23 || indirect5.e != 29) return 39;
    \\    struct Big6 made6 = z_frontier_big6_make(31, 37, 41, 43, 47, 53);
    \\    if (made6.a != 31 || made6.b != 37 || made6.c != 41 || made6.d != 43 || made6.e != 47 || made6.f != 53) return 11;
    \\    struct Big6 input6 = { .a = 59, .b = 61, .c = 67, .d = 71, .e = 73, .f = 79 };
    \\    if (z_frontier_big6_middle(input6) != 134) return 12;
    \\    struct Big6 copied6 = z_frontier_big6_copy(input6);
    \\    if (copied6.a != 59 || copied6.b != 61 || copied6.c != 67 || copied6.d != 71 || copied6.e != 73 || copied6.f != 79) return 13;
    \\    struct Big7 made7 = z_frontier_big7_make(83, 89, 97, 101, 103, 107, 109);
    \\    if (made7.a != 83 || made7.b != 89 || made7.c != 97 || made7.d != 101 || made7.e != 103 || made7.f != 107 || made7.g != 109) return 14;
    \\    struct Big7 input7 = { .a = 113, .b = 127, .c = 131, .d = 137, .e = 139, .f = 149, .g = 151 };
    \\    if (z_frontier_big7_inner(input7) != 431) return 15;
    \\    struct Big7 copied7 = z_frontier_big7_copy(input7);
    \\    if (copied7.a != 113 || copied7.b != 127 || copied7.c != 131 || copied7.d != 137 || copied7.e != 139 || copied7.f != 149 || copied7.g != 151) return 16;
    \\    struct Big8 made8 = z_frontier_big8_make(157, 163, 167, 173, 179, 181, 191, 193);
    \\    if (made8.a != 157 || made8.b != 163 || made8.c != 167 || made8.d != 173 || made8.e != 179 || made8.f != 181 || made8.g != 191 || made8.h != 193) return 17;
    \\    struct Big8 input8 = { .a = 197, .b = 199, .c = 211, .d = 223, .e = 227, .f = 229, .g = 233, .h = 239 };
    \\    if (z_frontier_big8_inner(input8) != 665) return 18;
    \\    struct Big8 copied8 = z_frontier_big8_copy(input8);
    \\    if (copied8.a != 197 || copied8.b != 199 || copied8.c != 211 || copied8.d != 223 || copied8.e != 227 || copied8.f != 229 || copied8.g != 233 || copied8.h != 239) return 19;
    \\    struct Big12 made12 = z_frontier_big12_make(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37);
    \\    if (made12.a != 2 || made12.b != 3 || made12.c != 5 || made12.d != 7 || made12.e != 11 || made12.f != 13 || made12.g != 17 || made12.h != 19 || made12.i != 23 || made12.j != 29 || made12.k != 31 || made12.l != 37) return 25;
    \\    struct Big12 input12 = { .a = 41, .b = 43, .c = 47, .d = 53, .e = 59, .f = 61, .g = 67, .h = 71, .i = 73, .j = 79, .k = 83, .l = 89 };
    \\    if (z_frontier_big12_inner(input12) != 207) return 26;
    \\    struct Big12 copied12 = z_frontier_big12_copy(input12);
    \\    if (copied12.a != 41 || copied12.b != 43 || copied12.c != 47 || copied12.d != 53 || copied12.e != 59 || copied12.f != 61 || copied12.g != 67 || copied12.h != 71 || copied12.i != 73 || copied12.j != 79 || copied12.k != 83 || copied12.l != 89) return 27;
    \\    struct Big16 made16 = z_frontier_big16_make(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    \\    if (made16.a != 1 || made16.h != 8 || made16.p != 16) return 28;
    \\    if (z_frontier_big16_inner(made16) != 31) return 29;
    \\    struct Big16 copied16 = z_frontier_big16_copy(made16);
    \\    if (copied16.d != 4 || copied16.k != 11 || copied16.p != 16) return 30;
    \\    struct Big20 made20 = z_frontier_big20_make(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);
    \\    if (made20.a != 1 || made20.q != 17 || made20.t != 20) return 31;
    \\    if (z_frontier_big20_inner(made20) != 52) return 32;
    \\    struct Big20 copied20 = z_frontier_big20_copy(made20);
    \\    if (copied20.d != 4 || copied20.k != 11 || copied20.q != 17 || copied20.t != 20) return 33;
    \\    struct BigNested nested = { .left = { .a = 2, .b = 3, .c = 5 }, .right = { .a = 7, .b = 11, .c = 13 } };
    \\    if (z_frontier_big_nested_sum_inner(nested) != 16) return 20;
    \\    struct BigNested copied_nested = z_frontier_big_nested_copy(nested);
    \\    if (copied_nested.left.a != 2 || copied_nested.left.b != 3 || copied_nested.left.c != 5 || copied_nested.right.a != 7 || copied_nested.right.b != 11 || copied_nested.right.c != 13) return 21;
    \\    struct BigNested direct_nested = z_frontier_direct_big_nested_copy(nested);
    \\    if (direct_nested.left.a != 2 || direct_nested.left.b != 3 || direct_nested.left.c != 5 || direct_nested.right.a != 7 || direct_nested.right.b != 11 || direct_nested.right.c != 13) return 60;
    \\    struct BigNested indirect_nested = z_frontier_indirect_big_nested_copy(z_frontier_big_nested_copy, nested);
    \\    if (indirect_nested.left.a != 2 || indirect_nested.left.b != 3 || indirect_nested.left.c != 5 || indirect_nested.right.a != 7 || indirect_nested.right.b != 11 || indirect_nested.right.c != 13) return 61;
    \\    struct BigMixed mixed = { .a = 211, .b = 223, .c = 227, .d = 229 };
    \\    struct BigMixed copied_mixed = z_frontier_big_mixed_copy(mixed);
    \\    if (copied_mixed.a != 211 || copied_mixed.b != 223 || copied_mixed.c != 227 || copied_mixed.d != 229) return 22;
    \\    struct BigMixed direct_mixed = z_frontier_direct_big_mixed_copy(mixed);
    \\    if (direct_mixed.a != 211 || direct_mixed.b != 223 || direct_mixed.c != 227 || direct_mixed.d != 229) return 64;
    \\    struct BigMixed indirect_mixed = z_frontier_indirect_big_mixed_copy(z_frontier_big_mixed_copy, mixed);
    \\    if (indirect_mixed.a != 211 || indirect_mixed.b != 223 || indirect_mixed.c != 227 || indirect_mixed.d != 229) return 65;
    \\    struct BigNarrow narrow = { .a = 7, .inner = { .b = 4091, .c = 8191 }, .d = 922337203685477LL };
    \\    struct BigNarrow copied_narrow = z_frontier_big_narrow_copy(narrow);
    \\    if (copied_narrow.a != 7 || copied_narrow.inner.b != 4091 || copied_narrow.inner.c != 8191 || copied_narrow.d != 922337203685477LL) return 70;
    \\    struct BigNarrow direct_narrow = z_frontier_direct_big_narrow_copy(narrow);
    \\    if (direct_narrow.a != 7 || direct_narrow.inner.b != 4091 || direct_narrow.inner.c != 8191 || direct_narrow.d != 922337203685477LL) return 71;
    \\    struct BigNarrow indirect_narrow = z_frontier_indirect_big_narrow_copy(z_frontier_big_narrow_copy, narrow);
    \\    if (indirect_narrow.a != 7 || indirect_narrow.inner.b != 4091 || indirect_narrow.inner.c != 8191 || indirect_narrow.d != 922337203685477LL) return 72;
    \\    struct BigArray array = { .values = { 233, 239, 241, 251, 257 } };
    \\    struct BigArray copied_array = z_frontier_big_array_copy(array);
    \\    if (copied_array.values[0] != 233 || copied_array.values[1] != 239 || copied_array.values[2] != 241 || copied_array.values[3] != 251 || copied_array.values[4] != 257) return 23;
    \\    struct BigArray direct_array = z_frontier_direct_big_array_copy(array);
    \\    if (direct_array.values[0] != 233 || direct_array.values[1] != 239 || direct_array.values[2] != 241 || direct_array.values[3] != 251 || direct_array.values[4] != 257) return 62;
    \\    struct BigArray indirect_array = z_frontier_indirect_big_array_copy(z_frontier_big_array_copy, array);
    \\    if (indirect_array.values[0] != 233 || indirect_array.values[1] != 239 || indirect_array.values[2] != 241 || indirect_array.values[3] != 251 || indirect_array.values[4] != 257) return 63;
    \\    if (z_frontier_big_array_sum_edges(array) != 490) return 24;
    \\    struct BigDouble big_double = { .a = 1.5, .b = 2.25, .c = 3.75 };
    \\    struct BigDouble copied_big_double = z_frontier_big_double_copy(big_double);
    \\    if (copied_big_double.a != 1.5 || copied_big_double.b != 2.25 || copied_big_double.c != 3.75) return 34;
    \\    struct BigDouble direct_big_double = z_frontier_direct_big_double_copy(big_double);
    \\    if (direct_big_double.a != 1.5 || direct_big_double.b != 2.25 || direct_big_double.c != 3.75) return 56;
    \\    struct BigDouble indirect_big_double = z_frontier_indirect_big_double_copy(z_frontier_big_double_copy, big_double);
    \\    if (indirect_big_double.a != 1.5 || indirect_big_double.b != 2.25 || indirect_big_double.c != 3.75) return 57;
    \\    struct BigDoubleArray big_double_array = { .values = { 7.5, 8.25, 9.75 } };
    \\    struct BigDoubleArray copied_big_double_array = z_frontier_big_double_array_copy(big_double_array);
    \\    if (copied_big_double_array.values[0] != 7.5 || copied_big_double_array.values[1] != 8.25 || copied_big_double_array.values[2] != 9.75) return 73;
    \\    struct BigDoubleArray direct_big_double_array = z_frontier_direct_big_double_array_copy(big_double_array);
    \\    if (direct_big_double_array.values[0] != 7.5 || direct_big_double_array.values[1] != 8.25 || direct_big_double_array.values[2] != 9.75) return 74;
    \\    struct BigDoubleArray indirect_big_double_array = z_frontier_indirect_big_double_array_copy(z_frontier_big_double_array_copy, big_double_array);
    \\    if (indirect_big_double_array.values[0] != 7.5 || indirect_big_double_array.values[1] != 8.25 || indirect_big_double_array.values[2] != 9.75) return 75;
    \\    struct BigFloat big_float = { .a = 1.25f, .b = 2.5f, .c = 3.75f, .d = 4.5f, .e = 5.25f };
    \\    struct BigFloat copied_big_float = z_frontier_big_float_copy(big_float);
    \\    if (copied_big_float.a != 1.25f || copied_big_float.b != 2.5f || copied_big_float.c != 3.75f || copied_big_float.d != 4.5f || copied_big_float.e != 5.25f) return 36;
    \\    struct BigFloat direct_big_float = z_frontier_direct_big_float_copy(big_float);
    \\    if (direct_big_float.a != 1.25f || direct_big_float.b != 2.5f || direct_big_float.c != 3.75f || direct_big_float.d != 4.5f || direct_big_float.e != 5.25f) return 58;
    \\    struct BigFloat indirect_big_float = z_frontier_indirect_big_float_copy(z_frontier_big_float_copy, big_float);
    \\    if (indirect_big_float.a != 1.25f || indirect_big_float.b != 2.5f || indirect_big_float.c != 3.75f || indirect_big_float.d != 4.5f || indirect_big_float.e != 5.25f) return 59;
    \\    long long pointed = 987654321LL;
    \\    struct BigPtrDouble ptr_double = { .ptr = &pointed, .value = 6.5, .tag = 1234567LL };
    \\    struct BigPtrDouble copied_ptr_double = z_frontier_big_ptr_double_copy(ptr_double);
    \\    if (copied_ptr_double.ptr != &pointed || *copied_ptr_double.ptr != 987654321LL || copied_ptr_double.value != 6.5 || copied_ptr_double.tag != 1234567LL) return 35;
    \\    struct BigPtrDouble direct_ptr_double = z_frontier_direct_big_ptr_double_copy(ptr_double);
    \\    if (direct_ptr_double.ptr != &pointed || *direct_ptr_double.ptr != 987654321LL || direct_ptr_double.value != 6.5 || direct_ptr_double.tag != 1234567LL) return 54;
    \\    struct BigPtrDouble indirect_ptr_double = z_frontier_indirect_big_ptr_double_copy(z_frontier_big_ptr_double_copy, ptr_double);
    \\    if (indirect_ptr_double.ptr != &pointed || *indirect_ptr_double.ptr != 987654321LL || indirect_ptr_double.value != 6.5 || indirect_ptr_double.tag != 1234567LL) return 55;
    \\    struct BigArrayMixed array_mixed = { .ints = { 101, 103 }, .doubles = { 10.5, 11.25 }, .ptr = &pointed };
    \\    struct BigArrayMixed copied_array_mixed = z_frontier_big_array_mixed_copy(array_mixed);
    \\    if (copied_array_mixed.ints[0] != 101 || copied_array_mixed.ints[1] != 103 || copied_array_mixed.doubles[0] != 10.5 || copied_array_mixed.doubles[1] != 11.25 || copied_array_mixed.ptr != &pointed || *copied_array_mixed.ptr != 987654321LL) return 76;
    \\    struct BigArrayMixed direct_array_mixed = z_frontier_direct_big_array_mixed_copy(array_mixed);
    \\    if (direct_array_mixed.ints[0] != 101 || direct_array_mixed.ints[1] != 103 || direct_array_mixed.doubles[0] != 10.5 || direct_array_mixed.doubles[1] != 11.25 || direct_array_mixed.ptr != &pointed || *direct_array_mixed.ptr != 987654321LL) return 77;
    \\    struct BigArrayMixed indirect_array_mixed = z_frontier_indirect_big_array_mixed_copy(z_frontier_big_array_mixed_copy, array_mixed);
    \\    if (indirect_array_mixed.ints[0] != 101 || indirect_array_mixed.ints[1] != 103 || indirect_array_mixed.doubles[0] != 10.5 || indirect_array_mixed.doubles[1] != 11.25 || indirect_array_mixed.ptr != &pointed || *indirect_array_mixed.ptr != 987654321LL) return 78;
    \\    struct ScalarMixed scalar_mixed = z_frontier_scalar_mixed_make(7, 4091, -12345, 987654321LL, &pointed, 1.25f, 6.5);
    \\    if (scalar_mixed.a != 7 || scalar_mixed.b != 4091 || scalar_mixed.c != -12345 || scalar_mixed.d != 987654321LL || scalar_mixed.ptr != &pointed || *scalar_mixed.ptr != 987654321LL || scalar_mixed.f != 1.25f || scalar_mixed.g != 6.5) return 79;
    \\    struct ScalarNested scalar_nested = z_frontier_scalar_nested_make(9, 6551, -4567, 12.75, &pointed);
    \\    if (scalar_nested.inner.a != 9 || scalar_nested.inner.b != 6551 || scalar_nested.c != -4567 || scalar_nested.d != 12.75 || scalar_nested.ptr != &pointed || *scalar_nested.ptr != 987654321LL) return 80;
    \\    struct ScalarArray scalar_array = z_frontier_scalar_array_make(31, 37, 41, 17.5, 19.25, &pointed);
    \\    if (scalar_array.ints[0] != 31 || scalar_array.ints[1] != 37 || scalar_array.ints[2] != 41 || scalar_array.doubles[0] != 17.5 || scalar_array.doubles[1] != 19.25 || scalar_array.ptr != &pointed || *scalar_array.ptr != 987654321LL) return 81;
    \\    return 0;
    \\}
    \\
    };
    if (std.mem.eql(u8, source, "test/zig/frontier/frontier_sysv_aggregate_classes.zig")) return .{ .abi_mode = "c-stable-module", .expected = "frontier mixed integer/SSE and nested INTEGER aggregate ABI", .c_body =
    \\struct Mixed { long long a; double b; };
    \\struct DoublePair { double a; double b; };
    \\struct FloatPair { float a; float b; };
    \\struct ReverseMixed { double a; long long b; };
    \\struct Pair32 { int a; int b; };
    \\struct NestedPair { struct Pair32 left; struct Pair32 right; };
    \\struct ArrayPair { long long values[2]; };
    \\struct ArrayDouble { double values[2]; };
    \\struct DoubleBox { double value; };
    \\struct NestedDouble { struct DoubleBox left; struct DoubleBox right; };
    \\struct NestedMixed { struct Pair32 ints; double value; };
    \\struct SmallMixed { int a; double b; };
    \\struct SmallReverseMixed { double a; int b; };
    \\struct PackedMixed { int a; int b; double c; };
    \\struct PackedReverseMixed { double a; int b; int c; };
    \\extern long long z_frontier_mixed_int(struct Mixed) __asm__("frontier_sysv_aggregate_classes.frontier_mixed_int");
    \\extern double z_frontier_mixed_float(struct Mixed) __asm__("frontier_sysv_aggregate_classes.frontier_mixed_float");
    \\extern struct Mixed z_frontier_mixed_make(long long, double) __asm__("frontier_sysv_aggregate_classes.frontier_mixed_make");
    \\extern struct Mixed z_frontier_mixed_call_make(long long, double) __asm__("frontier_sysv_aggregate_classes.frontier_mixed_call_make");
    \\extern long long z_frontier_stack_mixed_call_int(long long, long long, long long, long long, long long, long long, struct Mixed) __asm__("frontier_sysv_aggregate_classes.frontier_stack_mixed_call_int");
    \\extern long long z_frontier_shifted_mixed_call_int(long long, struct Mixed) __asm__("frontier_sysv_aggregate_classes.frontier_shifted_mixed_call_int");
    \\extern double z_frontier_double_pair_first(struct DoublePair) __asm__("frontier_sysv_aggregate_classes.frontier_double_pair_first");
    \\extern double z_frontier_double_pair_second(struct DoublePair) __asm__("frontier_sysv_aggregate_classes.frontier_double_pair_second");
    \\extern struct DoublePair z_frontier_double_pair_make(double, double) __asm__("frontier_sysv_aggregate_classes.frontier_double_pair_make");
    \\extern float z_frontier_float_pair_first(struct FloatPair) __asm__("frontier_sysv_aggregate_classes.frontier_float_pair_first");
    \\extern float z_frontier_float_pair_second(struct FloatPair) __asm__("frontier_sysv_aggregate_classes.frontier_float_pair_second");
    \\extern struct FloatPair z_frontier_float_pair_make(float, float) __asm__("frontier_sysv_aggregate_classes.frontier_float_pair_make");
    \\extern float z_frontier_float_pair_call_sum(struct FloatPair) __asm__("frontier_sysv_aggregate_classes.frontier_float_pair_call_sum");
    \\extern float z_frontier_shifted_float_pair_call_sum(double, struct FloatPair) __asm__("frontier_sysv_aggregate_classes.frontier_shifted_float_pair_call_sum");
    \\extern float z_frontier_indirect_float_pair_sum(float (*)(struct FloatPair), struct FloatPair) __asm__("frontier_sysv_aggregate_classes.frontier_indirect_float_pair_sum");
    \\extern double z_frontier_reverse_mixed_float(struct ReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_reverse_mixed_float");
    \\extern long long z_frontier_reverse_mixed_int(struct ReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_reverse_mixed_int");
    \\extern struct ReverseMixed z_frontier_reverse_mixed_make(double, long long) __asm__("frontier_sysv_aggregate_classes.frontier_reverse_mixed_make");
    \\extern double z_frontier_shifted_reverse_mixed_call_float(double, struct ReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_shifted_reverse_mixed_call_float");
    \\extern double z_frontier_indirect_reverse_mixed_call_float(double (*)(struct ReverseMixed), struct ReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_indirect_reverse_mixed_call_float");
    \\extern struct ReverseMixed z_frontier_indirect_reverse_mixed_make(struct ReverseMixed (*)(double, long long), double, long long) __asm__("frontier_sysv_aggregate_classes.frontier_indirect_reverse_mixed_make");
    \\extern int z_frontier_nested_pair_sum(struct NestedPair) __asm__("frontier_sysv_aggregate_classes.frontier_nested_pair_sum");
    \\extern int z_frontier_nested_pair_call_sum(struct NestedPair) __asm__("frontier_sysv_aggregate_classes.frontier_nested_pair_call_sum");
    \\extern int z_frontier_indirect_nested_pair_sum(int (*)(struct NestedPair), struct NestedPair) __asm__("frontier_sysv_aggregate_classes.frontier_indirect_nested_pair_sum");
    \\extern struct NestedPair z_frontier_nested_pair_make(int, int, int, int) __asm__("frontier_sysv_aggregate_classes.frontier_nested_pair_make");
    \\extern long long z_frontier_array_pair_sum(struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_array_pair_sum");
    \\extern long long z_frontier_indirect_array_pair_sum(long long (*)(struct ArrayPair), struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_indirect_array_pair_sum");
    \\extern struct ArrayPair z_frontier_array_pair_make(long long, long long) __asm__("frontier_sysv_aggregate_classes.frontier_array_pair_make");
    \\extern long long z_frontier_stack_array_pair_first(long long, long long, long long, long long, long long, long long, struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_stack_array_pair_first");
    \\extern long long z_frontier_stack_array_pair_second(long long, long long, long long, long long, long long, long long, struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_stack_array_pair_second");
    \\extern long long z_frontier_stack_array_pair_call_sum(long long, long long, long long, long long, long long, long long, struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_stack_array_pair_call_sum");
    \\extern long long z_frontier_stack_array_pair_call_sum_after_six(long long, long long, long long, long long, long long, long long, struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_stack_array_pair_call_sum_after_six");
    \\extern long long z_frontier_register_array_pair_call_sum_after_six(struct ArrayPair) __asm__("frontier_sysv_aggregate_classes.frontier_register_array_pair_call_sum_after_six");
    \\extern double z_frontier_array_double_first(struct ArrayDouble) __asm__("frontier_sysv_aggregate_classes.frontier_array_double_first");
    \\extern double z_frontier_array_double_second(struct ArrayDouble) __asm__("frontier_sysv_aggregate_classes.frontier_array_double_second");
    \\extern struct ArrayDouble z_frontier_array_double_make(double, double) __asm__("frontier_sysv_aggregate_classes.frontier_array_double_make");
    \\extern double z_frontier_stack_array_double_call_sum(double, double, double, double, double, double, double, double, struct ArrayDouble) __asm__("frontier_sysv_aggregate_classes.frontier_stack_array_double_call_sum");
    \\extern double z_frontier_register_array_double_call_sum_after_eight(struct ArrayDouble, double, double, double, double, double, double, double, double) __asm__("frontier_sysv_aggregate_classes.frontier_register_array_double_call_sum_after_eight");
    \\extern struct ArrayDouble z_frontier_indirect_array_double_make(struct ArrayDouble (*)(double, double), double, double) __asm__("frontier_sysv_aggregate_classes.frontier_indirect_array_double_make");
    \\extern double z_frontier_indirect_array_double_sum(double (*)(struct ArrayDouble), struct ArrayDouble) __asm__("frontier_sysv_aggregate_classes.frontier_indirect_array_double_sum");
    \\extern double z_frontier_nested_double_left(struct NestedDouble) __asm__("frontier_sysv_aggregate_classes.frontier_nested_double_left");
    \\extern double z_frontier_nested_double_right(struct NestedDouble) __asm__("frontier_sysv_aggregate_classes.frontier_nested_double_right");
    \\extern struct NestedDouble z_frontier_nested_double_make(double, double) __asm__("frontier_sysv_aggregate_classes.frontier_nested_double_make");
    \\extern int z_frontier_nested_mixed_int_sum(struct NestedMixed) __asm__("frontier_sysv_aggregate_classes.frontier_nested_mixed_int_sum");
    \\extern double z_frontier_nested_mixed_float(struct NestedMixed) __asm__("frontier_sysv_aggregate_classes.frontier_nested_mixed_float");
    \\extern struct NestedMixed z_frontier_nested_mixed_make(int, int, double) __asm__("frontier_sysv_aggregate_classes.frontier_nested_mixed_make");
    \\extern int z_frontier_shifted_nested_mixed_call_int(long long, double, struct NestedMixed) __asm__("frontier_sysv_aggregate_classes.frontier_shifted_nested_mixed_call_int");
    \\extern int z_frontier_small_mixed_int(struct SmallMixed) __asm__("frontier_sysv_aggregate_classes.frontier_small_mixed_int");
    \\extern double z_frontier_small_mixed_float(struct SmallMixed) __asm__("frontier_sysv_aggregate_classes.frontier_small_mixed_float");
    \\extern double z_frontier_small_reverse_mixed_float(struct SmallReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_small_reverse_mixed_float");
    \\extern int z_frontier_small_reverse_mixed_int(struct SmallReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_small_reverse_mixed_int");
    \\extern int z_frontier_packed_mixed_low_int(struct PackedMixed) __asm__("frontier_sysv_aggregate_classes.frontier_packed_mixed_low_int");
    \\extern int z_frontier_packed_mixed_high_int(struct PackedMixed) __asm__("frontier_sysv_aggregate_classes.frontier_packed_mixed_high_int");
    \\extern double z_frontier_packed_mixed_float(struct PackedMixed) __asm__("frontier_sysv_aggregate_classes.frontier_packed_mixed_float");
    \\extern struct PackedMixed z_frontier_packed_mixed_make(int, int, double) __asm__("frontier_sysv_aggregate_classes.frontier_packed_mixed_make");
    \\extern double z_frontier_packed_reverse_mixed_float(struct PackedReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_packed_reverse_mixed_float");
    \\extern int z_frontier_packed_reverse_mixed_low_int(struct PackedReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_packed_reverse_mixed_low_int");
    \\extern int z_frontier_packed_reverse_mixed_high_int(struct PackedReverseMixed) __asm__("frontier_sysv_aggregate_classes.frontier_packed_reverse_mixed_high_int");
    \\extern struct PackedReverseMixed z_frontier_packed_reverse_mixed_make(double, int, int) __asm__("frontier_sysv_aggregate_classes.frontier_packed_reverse_mixed_make");
    \\float frontier_sum_float_pair(struct FloatPair value) { return value.a + value.b; }
    \\struct ArrayDouble frontier_make_array_double(double a, double b) { struct ArrayDouble result = { { a, b } }; return result; }
    \\double frontier_sum_array_double(struct ArrayDouble value) { return value.values[0] + value.values[1]; }
    \\double frontier_reverse_mixed_float_c(struct ReverseMixed value) { return value.a; }
    \\struct ReverseMixed frontier_make_reverse_mixed(double a, long long b) { struct ReverseMixed result = { a, b }; return result; }
    \\int frontier_sum_nested_pair(struct NestedPair value) { return value.left.a + value.left.b + value.right.a + value.right.b; }
    \\long long frontier_sum_array_pair(struct ArrayPair value) { return value.values[0] + value.values[1]; }
    \\int main(void) {
    \\    struct Mixed value = { 123456789LL, 6.25 };
    \\    if (z_frontier_mixed_int(value) != 123456789LL) return 1;
    \\    if (z_frontier_mixed_float(value) != 6.25) return 2;
    \\    struct Mixed made = z_frontier_mixed_make(77, 9.5);
    \\    if (made.a != 77 || made.b != 9.5) return 3;
    \\    struct Mixed call_made = z_frontier_mixed_call_make(81, 10.5);
    \\    if (call_made.a != 81 || call_made.b != 10.5) return 14;
    \\    if (z_frontier_stack_mixed_call_int(1, 2, 3, 4, 5, 6, value) != 123456789LL) return 48;
    \\    if (z_frontier_shifted_mixed_call_int(99, value) != 123456789LL) return 49;
    \\    struct DoublePair doubles = { 1.25, 7.5 };
    \\    if (z_frontier_double_pair_first(doubles) != 1.25) return 4;
    \\    if (z_frontier_double_pair_second(doubles) != 7.5) return 5;
    \\    struct DoublePair made_doubles = z_frontier_double_pair_make(3.5, 11.25);
    \\    if (made_doubles.a != 3.5 || made_doubles.b != 11.25) return 6;
    \\    struct FloatPair floats = { 12.5f, 14.75f };
    \\    if (z_frontier_float_pair_first(floats) != 12.5f) return 56;
    \\    if (z_frontier_float_pair_second(floats) != 14.75f) return 57;
    \\    struct FloatPair made_floats = z_frontier_float_pair_make(16.5f, 18.25f);
    \\    if (made_floats.a != 16.5f || made_floats.b != 18.25f) return 58;
    \\    if (z_frontier_float_pair_call_sum(floats) != 27.25f) return 59;
    \\    if (z_frontier_shifted_float_pair_call_sum(1.0, floats) != 27.25f) return 60;
    \\    if (z_frontier_indirect_float_pair_sum(frontier_sum_float_pair, floats) != 27.25f) return 61;
    \\    struct ReverseMixed reverse = { 2.75, 987654321LL };
    \\    if (z_frontier_reverse_mixed_float(reverse) != 2.75) return 7;
    \\    if (z_frontier_reverse_mixed_int(reverse) != 987654321LL) return 8;
    \\    struct ReverseMixed made_reverse = z_frontier_reverse_mixed_make(13.5, 444);
    \\    if (made_reverse.a != 13.5) return 9;
    \\    if (made_reverse.b != 444) return 12;
    \\    if (z_frontier_shifted_reverse_mixed_call_float(1.0, reverse) != 2.75) return 50;
    \\    if (z_frontier_indirect_reverse_mixed_call_float(frontier_reverse_mixed_float_c, reverse) != 2.75) return 62;
    \\    struct ReverseMixed indirect_reverse = z_frontier_indirect_reverse_mixed_make(frontier_make_reverse_mixed, 15.25, 987);
    \\    if (indirect_reverse.a != 15.25 || indirect_reverse.b != 987) return 63;
    \\    struct NestedPair nested = { { 1, 2 }, { 3, 4 } };
    \\    if (z_frontier_nested_pair_sum(nested) != 10) return 10;
    \\    if (z_frontier_nested_pair_call_sum(nested) != 10) return 15;
    \\    if (z_frontier_indirect_nested_pair_sum(frontier_sum_nested_pair, nested) != 10) return 65;
    \\    struct NestedPair made_nested = z_frontier_nested_pair_make(5, 7, 11, 13);
    \\    if (made_nested.left.a != 5 || made_nested.left.b != 7 || made_nested.right.a != 11 || made_nested.right.b != 13) return 28;
    \\    struct ArrayPair array = { { 11, 31 } };
    \\    if (z_frontier_array_pair_sum(array) != 42) return 11;
    \\    if (z_frontier_indirect_array_pair_sum(frontier_sum_array_pair, array) != 42) return 66;
    \\    struct ArrayPair made_array = z_frontier_array_pair_make(17, 19);
    \\    if (made_array.values[0] != 17 || made_array.values[1] != 19) return 29;
    \\    struct ArrayPair stack_array = { { 101, 103 } };
    \\    if (z_frontier_stack_array_pair_first(1, 2, 3, 4, 5, 6, stack_array) != 101) return 38;
    \\    if (z_frontier_stack_array_pair_second(1, 2, 3, 4, 5, 6, stack_array) != 103) return 39;
    \\    if (z_frontier_stack_array_pair_call_sum(1, 2, 3, 4, 5, 6, stack_array) != 204) return 40;
    \\    if (z_frontier_stack_array_pair_call_sum_after_six(1, 2, 3, 4, 5, 6, stack_array) != 204) return 51;
    \\    if (z_frontier_register_array_pair_call_sum_after_six(stack_array) != 204) return 52;
    \\    struct ArrayDouble array_double = { { 2.5, 4.75 } };
    \\    if (z_frontier_array_double_first(array_double) != 2.5) return 30;
    \\    if (z_frontier_array_double_second(array_double) != 4.75) return 31;
    \\    struct ArrayDouble made_array_double = z_frontier_array_double_make(6.5, 8.25);
    \\    if (made_array_double.values[0] != 6.5 || made_array_double.values[1] != 8.25) return 32;
    \\    if (z_frontier_stack_array_double_call_sum(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, array_double) != 7.25) return 41;
    \\    if (z_frontier_register_array_double_call_sum_after_eight(array_double, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0) != 7.25) return 53;
    \\    struct ArrayDouble indirect_array_double = z_frontier_indirect_array_double_make(frontier_make_array_double, 9.25, 10.5);
    \\    if (indirect_array_double.values[0] != 9.25 || indirect_array_double.values[1] != 10.5) return 54;
    \\    if (z_frontier_indirect_array_double_sum(frontier_sum_array_double, indirect_array_double) != 19.75) return 55;
    \\    struct NestedDouble nested_double = { { 12.5 }, { 14.75 } };
    \\    if (z_frontier_nested_double_left(nested_double) != 12.5) return 33;
    \\    if (z_frontier_nested_double_right(nested_double) != 14.75) return 34;
    \\    struct NestedDouble made_nested_double = z_frontier_nested_double_make(16.5, 18.25);
    \\    if (made_nested_double.left.value != 16.5 || made_nested_double.right.value != 18.25) return 35;
    \\    struct NestedMixed nested_mixed = { { 47, 53 }, 59.0 };
    \\    if (z_frontier_nested_mixed_int_sum(nested_mixed) != 100) return 13;
    \\    if (z_frontier_nested_mixed_float(nested_mixed) != 59.0) return 36;
    \\    struct NestedMixed made_nested_mixed = z_frontier_nested_mixed_make(89, 97, 101.5);
    \\    if (made_nested_mixed.ints.a != 89 || made_nested_mixed.ints.b != 97 || made_nested_mixed.value != 101.5) return 37;
    \\    if (z_frontier_shifted_nested_mixed_call_int(123, 456.5, nested_mixed) != 100) return 64;
    \\    struct SmallMixed small_mixed = { 17, 23.5 };
    \\    if (z_frontier_small_mixed_int(small_mixed) != 17) return 16;
    \\    if (z_frontier_small_mixed_float(small_mixed) != 23.5) return 17;
    \\    struct SmallReverseMixed small_reverse = { 29.5, 31 };
    \\    if (z_frontier_small_reverse_mixed_float(small_reverse) != 29.5) return 18;
    \\    if (z_frontier_small_reverse_mixed_int(small_reverse) != 31) return 19;
    \\    struct PackedMixed packed_mixed = { 37, 41, 43.5 };
    \\    if (z_frontier_packed_mixed_low_int(packed_mixed) != 37) return 20;
    \\    if (z_frontier_packed_mixed_high_int(packed_mixed) != 41) return 21;
    \\    if (z_frontier_packed_mixed_float(packed_mixed) != 43.5) return 22;
    \\    struct PackedMixed made_packed_mixed = z_frontier_packed_mixed_make(61, 67, 71.5);
    \\    if (made_packed_mixed.a != 61 || made_packed_mixed.b != 67 || made_packed_mixed.c != 71.5) return 26;
    \\    struct PackedReverseMixed packed_reverse = { 47.5, 53, 59 };
    \\    if (z_frontier_packed_reverse_mixed_float(packed_reverse) != 47.5) return 23;
    \\    if (z_frontier_packed_reverse_mixed_low_int(packed_reverse) != 53) return 24;
    \\    if (z_frontier_packed_reverse_mixed_high_int(packed_reverse) != 59) return 25;
    \\    struct PackedReverseMixed made_packed_reverse = z_frontier_packed_reverse_mixed_make(73.5, 79, 83);
    \\    if (made_packed_reverse.a != 73.5 || made_packed_reverse.b != 79 || made_packed_reverse.c != 83) return 27;
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

fn termExitCode(term: std.process.Child.Term) i32 {
    return switch (term) {
        .exited => |code| @intCast(code),
        .signal, .stopped, .unknown => -1,
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
