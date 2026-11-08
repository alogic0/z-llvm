const std = @import("std");
const u = @import("common.zig");
const p = @import("program.zig");
const Runner = @import("runner.zig").Runner;
const elf = @import("object_contract.zig");

pub fn load(c: *u.Context) ![]u.Value {
    const manifest = try c.load(try c.join(&.{"test/real_programs/native_canaries.json"}));
    if (try u.json.integer(try u.get(manifest, "schema")) != 1) return error.InvalidNativeCanarySchema;
    const canaries = try u.json.array(try u.get(manifest, "canaries"));
    var names = std.StringHashMap(void).init(c.a);
    for (canaries) |canary| {
        const population = try u.str(canary, "population");
        if ((try names.getOrPut(population)).found_existing) return error.DuplicateNativePopulation;
        for ([_][]const u8{ population, try u.str(canary, "fixture"), try u.str(canary, "prefix") }) |name| {
            if (name.len == 0) return error.InvalidNativePopulation;
            for (name) |ch| if (!std.ascii.isAlphanumeric(ch) and ch != '_' and ch != '-') return error.InvalidNativePopulation;
        }
        if (try u.json.integer(try u.get(canary, "observations")) <= 0) return error.InvalidNativeObservations;
        _ = try u.str(canary, "stdout");
        if (canary.object.get("shared_object")) |shared| if (shared != .bool) return error.InvalidNativeSharedObject;
        var functions = std.StringHashMap(void).init(c.a);
        for (try u.stringSlice(c.a, try u.get(canary, "functions"))) |function| if (function.len == 0 or (try functions.getOrPut(function)).found_existing) return error.InvalidNativeFunctionSet;
        if (functions.count() == 0) return error.InvalidNativeFunctionSet;
    }
    return canaries;
}
pub fn llvmOpt(mode: []const u8) ![]const u8 {
    for (u.modes, [_][]const u8{ "-O3", "-O2", "-Oz" }) |m, opt| if (std.mem.eql(u8, m, mode)) return opt;
    return error.InvalidMode;
}
pub fn owners(c: *u.Context, text: []const u8, expected: []const []const u8) !void {
    var lines = std.mem.tokenizeScalar(u8, text, '\n');
    if (!std.mem.eql(u8, lines.next() orelse "", "row_identity\tselection_owner")) return error.InvalidOwnerHeader;
    var found = std.StringHashMap(void).init(c.a);
    while (lines.next()) |line| {
        var columns = std.mem.splitScalar(u8, line, '\t');
        const name = columns.next().?;
        const owner = columns.next() orelse return error.InvalidOwnerManifest;
        if (columns.next() != null or !u.contains(&.{ "composed_block", "composed_cfg" }, owner) or !u.contains(expected, name) or (try found.getOrPut(name)).found_existing) return error.CanaryEscapedComposedLowering;
    }
    if (found.count() != expected.len) return error.CanaryEscapedComposedLowering;
}
pub fn observation(runner: *Runner, exe: []const u8, case: u.Value, stem: []const u8, env: *const std.process.Environ.Map) !void {
    try runner.observe(exe, try u.stringSlice(runner.context.a, try u.get(case, "argv")), try u.json.integer(try u.get(case, "exit_status")), try u.str(case, "stdout"), stem, env);
}
pub fn variadic(runner: *Runner, directory: []const u8, zllvm: []const u8, env: *const std.process.Environ.Map) !void {
    const c = runner.context;
    const fixture = try c.join(&.{"test/real_programs/variadic_integer.ll"});
    const optimized = try c.join(&.{ directory, "varargs-optimized.ll" });
    try runner.require(&.{ zllvm, "--passes=verify,instcombine,dce,verify", fixture }, try c.join(&.{ directory, "varargs-optimize" }), env);
    try c.copy(try c.join(&.{ directory, "varargs-optimize.stdout" }), optimized);
    try runner.require(&.{ zllvm, "--generic-cfg-selector", "--emit=obj", "--target=x86_64-unknown-linux-gnu", optimized }, try c.join(&.{ directory, "varargs-object" }), env);
    const obj = try c.join(&.{ directory, "varargs.o" });
    try c.copy(try c.join(&.{ directory, "varargs-object.stdout" }), obj);
    const exe = try c.join(&.{ directory, "varargs-canary" });
    try runner.require(&.{ "cc", "-O2", "-no-pie", try c.join(&.{"test/real_programs/variadic_integer_driver.c"}), try c.join(&.{"test/real_programs/variadic_integer_shim.S"}), obj, "-o", exe }, try c.join(&.{ directory, "varargs-link" }), env);
    try runner.observe(exe, &.{}, 0, "integer-call-canary varargs_cases=16 heap_cases=6 al=0 pointers=preserved live=preserved\n", try c.join(&.{ directory, "varargs-run" }), env);
}
pub fn run(runner: *Runner, directory: []const u8, zllvm: []const u8, env: *const std.process.Environ.Map, mode: []const u8, report: *u.Value, canary: u.Value) !void {
    const c = runner.context;
    const population = try u.str(canary, "population");
    const prefix = try u.str(canary, "prefix");
    const shared = if (canary.object.get("shared_object")) |value| value.bool else false;
    const fixture = try c.join(&.{ "test/real_programs", try c.fmt("{s}.ll", .{try u.str(canary, "fixture")}) });
    const driver = try c.join(&.{ "test/real_programs", try c.fmt("{s}_driver.c", .{try u.str(canary, "fixture")}) });
    const reference = try c.join(&.{ directory, try c.fmt("{s}-reference.o", .{prefix}) });
    const reference_args = &.{ "clang-22", "-x", "ir", try llvmOpt(mode), "-c", fixture, "-o", reference };
    try runner.require(if (shared) try p.argv(c, reference_args, &.{"-fPIC"}) else reference_args, try c.join(&.{ directory, try c.fmt("{s}-reference-object", .{prefix}) }), env);
    const reference_exe = try c.join(&.{ directory, try c.fmt("{s}-reference", .{prefix}) });
    try link(runner, driver, reference, reference_exe, shared, env);
    try runner.observe(reference_exe, &.{}, 0, try u.str(canary, "stdout"), try c.join(&.{ directory, try c.fmt("{s}-reference-run", .{prefix}) }), env);
    const observations = try u.json.integer(try u.get(canary, "observations"));
    try u.increment(c.a, report, try c.fmt("{s}_reference_observations", .{population}), observations);
    for ([_][]const u8{ "direct", "release" }) |route| {
        var source = fixture;
        if (std.mem.eql(u8, route, "release")) {
            const stem = try c.join(&.{ directory, try c.fmt("{s}-optimize", .{prefix}) });
            try runner.require(&.{ zllvm, try c.fmt("--pipeline={s}", .{try u.pipeline(mode)}), fixture }, stem, env);
            source = try c.join(&.{ directory, try c.fmt("{s}-optimized.ll", .{prefix}) });
            try c.copy(try c.fmt("{s}.stdout", .{stem}), source);
        }
        const codegen_args = if (canary.object.get("codegen_args")) |value| try u.stringSlice(c.a, value) else &.{};
        const arguments = try p.argv(c, codegen_args, &.{ "--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", source });
        const object_stem = try c.join(&.{ directory, try c.fmt("{s}-{s}-object", .{ prefix, route }) });
        try runner.require(try p.argv(c, &.{ zllvm, "--emit=obj" }, arguments), object_stem, env);
        const obj = try c.join(&.{ directory, try c.fmt("{s}-{s}.o", .{ prefix, route }) });
        try c.copy(try c.fmt("{s}.stdout", .{object_stem}), obj);
        if (std.mem.eql(u8, population, "module_dependencies")) {
            if (std.mem.indexOf(u8, try c.read(try c.fmt("{s}.stderr", .{object_stem})), "coverage=complete") == null) return error.IncompleteModuleDependencyCoverage;
            try moduleObject(c, obj);
            if (std.mem.eql(u8, route, "direct")) {
                const env_stem = try c.join(&.{ directory, try c.fmt("{s}-environment-object", .{prefix}) });
                var env_args = std.array_list.Managed([]const u8).init(c.a);
                try env_args.appendSlice(&.{ zllvm, "--emit=obj" });
                for (arguments) |arg| if (!std.mem.eql(u8, arg, "--codegen-reachable")) try env_args.append(arg);
                var selected = try env.clone(c.a);
                try selected.put("ZLLVM_CODEGEN_REACHABLE", "1");
                try runner.require(env_args.items, env_stem, &selected);
                if (!std.mem.eql(u8, try c.read(try c.fmt("{s}.stdout", .{env_stem})), try c.read(obj))) return error.ModuleSelectionEnvironmentDiffers;
                try u.increment(c.a, report, "module_dependencies_environment_checks", 1);
            }
        }
        const owner_stem = try c.join(&.{ directory, try c.fmt("{s}-{s}-owners", .{ prefix, route }) });
        try runner.require(try p.argv(c, &.{ zllvm, "--emit=selection-owner-manifest" }, arguments), owner_stem, env);
        try owners(c, try c.read(try c.fmt("{s}.stdout", .{owner_stem})), try u.stringSlice(c.a, try u.get(canary, "functions")));
        const exe = try c.join(&.{ directory, try c.fmt("{s}-{s}", .{ prefix, route }) });
        try link(runner, driver, obj, exe, shared, env);
        try runner.observe(exe, &.{}, 0, try u.str(canary, "stdout"), try c.fmt("{s}-run", .{exe}), env);
        try u.increment(c.a, report, try c.fmt("{s}_local_observations", .{population}), observations);
        if (canary.object.get("guard_probe")) |guard| {
            if (guard != .bool) return error.InvalidGuardProbe;
            if (guard.bool) {
                try runner.observe(exe, &.{"--guard-probe"}, 0, "bounded-storage guard_checks=3 accessible=small-frame=guard-fault=verified\n", try c.fmt("{s}-guard-probe", .{exe}), env);
                try u.increment(c.a, report, try c.fmt("{s}_guard_checks", .{population}), 3);
            }
        }
    }
    if (std.mem.eql(u8, population, "module_dependencies")) try moduleControls(runner, directory, zllvm, env, report);
}

fn link(runner: *Runner, driver: []const u8, object: []const u8, exe: []const u8, shared: bool, env: *const std.process.Environ.Map) !void {
    const c = runner.context;
    const library = if (shared) try c.fmt("{s}.so", .{object}) else object;
    if (shared) try runner.require(&.{ "cc", "-shared", "-Wl,-z,noexecstack", object, "-o", library }, try c.fmt("{s}-shared-link", .{exe}), env);
    try runner.require(&.{ "cc", "-O2", "-no-pie", "-Wl,-z,noexecstack", driver, library, "-o", exe }, try c.fmt("{s}-link", .{exe}), env);
}

fn moduleObject(c: *u.Context, path: []const u8) !void {
    const contract = try elf.parse(c.a, try c.read(path));
    var symbols = std.StringHashMap([]u.Value).init(c.a);
    var imports = std.StringHashMap(void).init(c.a);
    for (try u.json.array(try u.get(contract, "symbols"))) |symbol| {
        const row = try u.json.array(symbol);
        const name = row[0].string;
        try symbols.put(name, row);
        if (u.json.is(row[3], "")) try imports.put(name, {});
        if (std.mem.startsWith(u8, name, "module_dead")) return error.ModuleDependencyDeadDefinition;
    }
    if (imports.count() != 1 or !imports.contains("module_external_word")) return error.ModuleDependencyImportsDiffer;
    const exported = [_][]const u8{ "module_entry", "module_fib", "module_callback", "module_callback_alias", "module_get_slot" };
    const local = [_][]const u8{ "module_entry_alias", "module_entry_impl", "module_middle", "module_leaf", "module_fib_impl", "debug.module_callback_impl", "module_callback_first", "module_callback_second", "module_slot_impl", "module_private_slot" };
    for ([_][]const []const u8{ &exported, &local }, [_]i64{ 1, 0 }) |names, binding| for (names) |name| {
        const row = symbols.get(name) orelse return error.ModuleDependencyMissingSymbol;
        if (row[1].integer >> 4 != binding or row[3] != .string or row[3].string.len == 0) return error.ModuleDependencyBindingDiffers;
    };
    for ([_][2][]const u8{ .{ "module_entry", "module_entry_impl" }, .{ "module_callback_alias", "module_callback" }, .{ "module_callback_first", "debug.module_callback_impl" } }) |pair| {
        const lhs = symbols.get(pair[0]).?;
        const rhs = symbols.get(pair[1]).?;
        for (3..6) |i| if (!u.json.eql(lhs[i], rhs[i])) return error.ModuleDependencyAliasDiffers;
    }
    for ([_][]const u8{ "module_callback_alias", "module_get_slot" }) |name| if (symbols.get(name).?[2].integer != 2) return error.ModuleDependencyVisibilityDiffers;
    const stem = path[0 .. path.len - std.fs.path.extension(path).len];
    try c.writeJson(try c.fmt("{s}.contract.json", .{stem}), contract);
}

fn moduleControls(runner: *Runner, directory: []const u8, zllvm: []const u8, env: *const std.process.Environ.Map, report: *u.Value) !void {
    const c = runner.context;
    const fixture = try c.read(try c.join(&.{"test/real_programs/module_dependencies.ll"}));
    const Case = struct { name: []const u8, source: []const u8, diagnostic: []const u8 };
    const cases = [_]Case{
        .{ .name = "reachable-unsupported", .source = try std.mem.replaceOwned(u8, c.a, fixture, "@module_dead_alias = internal alias", "@module_dead_alias = alias"), .diagnostic = "function=module_dead" },
        .{ .name = "opaque-coverage", .source = try c.fmt("{s}\n!vendor.helpers = !{{!0}}\n!0 = !{{!\"module_dead\"}}\n", .{fixture}), .diagnostic = "coverage=conservative" },
        .{ .name = "alias-cycle", .source = "@a = alias i64 (), ptr @b\n@b = internal alias i64 (), ptr @a\n", .diagnostic = "UnresolvedAliasTarget" },
        .{ .name = "alias-external", .source = "@a = alias i64 (), ptr @external\ndeclare i64 @external()\n", .diagnostic = "UnresolvedAliasTarget" },
        .{ .name = "unsupported-global", .source = "@value = global double 1.0\n", .diagnostic = "UnsupportedGlobalData" },
        .{ .name = "weak-alias", .source = try std.mem.replaceOwned(u8, c.a, fixture, "@module_entry = alias", "@module_entry = weak alias"), .diagnostic = "UnsupportedAliasLinkage" },
        .{ .name = "weak-function", .source = try std.mem.replaceOwned(u8, c.a, fixture, "define hidden ptr @module_get_slot", "define weak hidden ptr @module_get_slot"), .diagnostic = "UnsupportedFunctionLinkage" },
        .{ .name = "module-assembly", .source = "module asm \".quad missing\"\n", .diagnostic = "UnsupportedModuleAssembly" },
    };
    for (cases) |case| {
        const stem = try c.join(&.{ directory, try c.fmt("module-dependencies-{s}", .{case.name}) });
        const path = try c.fmt("{s}.ll", .{stem});
        try c.write(path, case.source);
        const result = try runner.run(&.{ zllvm, "--codegen-reachable", "--generic-cfg-selector", "--report-all-codegen-failures", "--target=x86_64-unknown-linux-gnu", "--emit=obj", path }, stem, env, .{});
        if (result.code == 0 or (try c.read(try c.fmt("{s}.stdout", .{stem}))).len != 0 or std.mem.indexOf(u8, try c.read(try c.fmt("{s}.stderr", .{stem})), case.diagnostic) == null) return c.fail("module dependency rejection did not fail before object publication: {s}", .{case.name});
        try u.increment(c.a, report, "module_dependencies_negative_controls", 1);
    }
    const path = try c.join(&.{ directory, "module-dependencies-reachable-unsupported.ll" });
    const immediate = try c.join(&.{ directory, "module-dependencies-immediate-failure" });
    const result = try runner.run(&.{ zllvm, "--codegen-reachable", "--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", "--emit=obj", path }, immediate, env, .{});
    const diagnostic = try c.read(try c.fmt("{s}.stderr", .{immediate}));
    if (result.code == 0 or (try c.read(try c.fmt("{s}.stdout", .{immediate}))).len != 0 or !std.mem.startsWith(u8, diagnostic, "summary zllvm-codegen-selection mode=reachable coverage=complete ") or std.mem.indexOf(u8, diagnostic, "codegen failed for function module_dead:") == null) return error.ModuleImmediateDiagnosticLost;
    try u.increment(c.a, report, "module_dependencies_negative_controls", 1);
    const assembly = try c.join(&.{ directory, "module-dependencies-assembly-boundary" });
    const asm_result = try runner.run(&.{ zllvm, "--codegen-reachable", "--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", "--emit=asm", path }, assembly, env, .{});
    if (asm_result.code == 0 or (try c.read(try c.fmt("{s}.stdout", .{assembly}))).len != 0 or std.mem.indexOf(u8, try c.read(try c.fmt("{s}.stderr", .{assembly})), "UnsupportedReachableAssembly") == null) return error.ReachableAssemblyDidNotReject;
    try u.increment(c.a, report, "module_dependencies_negative_controls", 1);
}
