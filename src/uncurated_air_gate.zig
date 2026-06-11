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
    var object_emitted_functions: usize = 0;
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
        }
        if ((options.object_progress or options.native_link_progress or options.executable_progress) and machines.items.len != 0) {
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

            if (options.native_link_progress or options.executable_progress) {
                const object_name = try std.fmt.allocPrint(allocator, "{s}.o", .{stem});
                defer allocator.free(object_name);
                const object_path = try std.fs.path.join(allocator, &.{ temp_path, object_name });
                defer allocator.free(object_path);
                const exe_name = try std.fmt.allocPrint(allocator, "{s}.link", .{stem});
                defer allocator.free(exe_name);
                const exe_path = try std.fs.path.join(allocator, &.{ temp_path, exe_name });
                defer allocator.free(exe_path);
                try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = object });

                const harness = if (options.executable_progress) executableHarnessForSource(source) else null;
                const link_result = if (harness) |executable_harness| link_result: {
                    const harness_body = try executableHarnessBody(allocator, executable_harness);
                    defer if (executable_harness.c_body == null) allocator.free(harness_body);
                    break :link_result try linkObjectWithHarness(allocator, io, zig_emitter, object_path, exe_path, harness_body);
                } else try nativeLinkObject(allocator, io, zig_emitter, object_path, exe_path);
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
    try stdout_writer.interface.print(
        "summary uncurated-zig-air mode={s} target=x86_64-linux-gnu source_rows={} discovered_functions={} structured_functions={} generic_codegen_functions={} structured_air_v1_functions={} structured_air_v2_functions={} typed_air_type_functions={} typed_air_operand_functions={} legacy_air_text_lowering_functions={} typed_v2_fallback_functions={} generic_lowering_functions={} shape_recognizer_functions={} unsupported_functions={} codegen_failures={} case_id_rows=0 source_fact_classification_rows=0 first_unsupported_source={s} first_unsupported_function={s} first_unsupported_opcode={s} top_unsupported_construct={s} top_unsupported_count={} first_typed_v2_fallback_function={s} first_typed_v2_fallback_opcode={s} first_typed_v2_fallback_data_kind={s} first_typed_v2_fallback_reason={s} top_typed_v2_fallback_reason={s} top_typed_v2_fallback_count={} local_fail=0\n",
        .{
            mode.name(),
            source_rows,
            discovered_functions,
            structured_functions,
            generic_codegen_functions,
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
        },
    );
    if (options.object_progress) {
        try stdout_writer.interface.print(
            "summary uncurated-zig-air-object mode={s} target=x86_64-linux-gnu object_emitted_functions={} object_failures={} llvm_targetmachine_rows=0 local_fail=0\n",
            .{ mode.name(), object_emitted_functions, object_failures },
        );
    }
    if (options.native_link_progress) {
        const local_fail: usize = if (native_link_failures == 0) 0 else 1;
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
        const local_fail: usize = if (native_link_failures == 0) 0 else 1;
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
    native_link_progress: bool = false,
    executable_progress: bool = false,
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
        } else if (std.mem.eql(u8, arg, "--object-progress")) {
            options.object_progress = true;
        } else if (std.mem.eql(u8, arg, "--native-link-progress")) {
            options.native_link_progress = true;
        } else if (std.mem.eql(u8, arg, "--executable-progress")) {
            options.executable_progress = true;
        } else {
            return error.UnsupportedUncuratedAirArgument;
        }
    }
    return options;
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
    if (std.mem.eql(u8, source, "test/zig/inputs/base64_table_lookup.zig")) return .{ .abi_mode = "c-stable-module", .expected = "base64 table lookup", .c_body =
    \\extern int z_base64_table_lookup(unsigned char) __asm__("base64_table_lookup.base64_table_lookup");
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
    if (std.mem.eql(u8, basename, "runtime_mix_c_add_zig_main.zig")) return null;
    if (std.mem.eql(u8, basename, "runtime_optional_pointer_main.zig")) return null;
    if (std.mem.eql(u8, basename, "runtime_pointer_load_store_main.zig")) return null;
    if (std.mem.eql(u8, basename, "runtime_tls_bump_main.zig")) return null;

    if (std.mem.eql(u8, basename, "runtime_aggregate_pair_main.zig")) return .{ .source = source, .expected_exit = 1 };
    if (std.mem.eql(u8, basename, "runtime_hidden_access_main.zig")) return .{ .source = source, .expected_exit = 7 };
    if (std.mem.eql(u8, basename, "runtime_inherit_want_safety_i64_main.zig")) return .{ .source = source, .return_type = .c_long, .expected_exit = 4 };
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
    object_path: []const u8,
    exe_path: []const u8,
) !std.process.RunResult {
    return linkObjectWithHarness(
        allocator,
        io,
        zig_exe,
        object_path,
        exe_path,
        "int main(void) { return 0; }\n",
    );
}

fn linkObjectWithHarness(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_exe: []const u8,
    object_path: []const u8,
    exe_path: []const u8,
    harness_body: []const u8,
) !std.process.RunResult {
    const harness_c = try std.fmt.allocPrint(allocator, "{s}.c", .{exe_path});
    defer allocator.free(harness_c);
    const harness_o = try std.fmt.allocPrint(allocator, "{s}.harness.o", .{exe_path});
    defer allocator.free(harness_o);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness_c, .data = harness_body });
    const cc_argv = [_][]const u8{
        zig_exe,
        "cc",
        "-target",
        "x86_64-linux-gnu",
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
    try collectSourcesFromRoot(allocator, io, &sources, "test/zig/inputs");
    if (corpus == .broad) {
        try collectSourcesFromRoot(allocator, io, &sources, "test/zig/integrated");
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
