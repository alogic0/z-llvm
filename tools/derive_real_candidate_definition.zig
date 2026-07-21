const std = @import("std");

const Sha256 = std.crypto.hash.sha2.Sha256;

const schema = "execution-oracle-definition-mapping-v1";
const mapping_method = "zig-ast-import-chain-v1";
const zig_root = "/home/oleg/prog/ziglang";
const historical_candidate_rank = "2";
const historical_revision = "141bfce0883017ff7ebe03e3af3db07fff0c5dc3";
const mapping_target_revision = "bdee02bc0c7f227c0f11bc9a449df673fe803540";
const historical_source = "../ziglang/src/main.zig";
const mapping_authority = "current_definition_only";
const fresh_cohort_status = "not_materialized";
const air_row_binding = "false";
const module_root_path = "src/main.zig";
const std_root_path = "lib/std/std.zig";
const io_module_path = "lib/std/Io.zig";
const definition_source_path = "lib/std/Io/Threaded.zig";
const fully_qualified_symbol = "Io.Threaded.doNothingSignalHandler";
const definition_identifier = "doNothingSignalHandler";
const output_path = "local-state/validations/inbox206cn-definition-mapper/rank2_definition_mapping_v1.tsv";
const git_executable = "/usr/bin/git";

const MappingError = error{
    AmbiguousAlias,
    AmbiguousDefinition,
    DefinitionMissing,
    IdentifierOccurrenceMismatch,
    ImportChainMismatch,
    InvalidArguments,
    InvalidGitOutput,
    InvalidPath,
    InvalidProvenance,
    InvalidRevision,
    NonCanonicalRecord,
    ParseFailure,
    RepositoryDirty,
    RepositoryQueryFailed,
    UntrackedMappingInput,
};

const SourceFile = struct {
    path: []const u8,
    bytes: []const u8,
};

const Mapping = struct {
    definition_path: []const u8,
    exact_identifier_tokens: usize,
    definitions: usize,
};

const FileDigests = struct {
    module_root: [Sha256.digest_length * 2]u8,
    std_root: [Sha256.digest_length * 2]u8,
    io_module: [Sha256.digest_length * 2]u8,
    definition_source: [Sha256.digest_length * 2]u8,
    mapping_input: [Sha256.digest_length * 2]u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    try rejectArguments(allocator, init);
    try verifyRepository(allocator, io);

    var root = try std.Io.Dir.openDirAbsolute(io, zig_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);

    const module_root = try readTrackedSource(allocator, io, root, module_root_path);
    defer allocator.free(module_root);
    const std_root = try readTrackedSource(allocator, io, root, std_root_path);
    defer allocator.free(std_root);
    const io_module = try readTrackedSource(allocator, io, root, io_module_path);
    defer allocator.free(io_module);
    const definition_source = try readTrackedSource(allocator, io, root, definition_source_path);
    defer allocator.free(definition_source);

    const sources = [_]SourceFile{
        .{ .path = module_root_path, .bytes = module_root },
        .{ .path = std_root_path, .bytes = std_root },
        .{ .path = io_module_path, .bytes = io_module },
        .{ .path = definition_source_path, .bytes = definition_source },
    };
    const mapping = try deriveMapping(allocator, &sources);
    try verifyTrackedIdentifierSet(allocator, io, mapping.definition_path);
    const digests = hashInputs(&sources);
    const record = try encodeRecord(allocator, mapping, digests);
    defer allocator.free(record);

    if (std.fs.path.dirname(output_path)) |dirname| {
        try std.Io.Dir.cwd().createDirPath(io, dirname);
    }
    var cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = output_path, .data = record });
    const output_file = try cwd.openFile(io, output_path, .{ .mode = .read_write });
    defer output_file.close(io);
    try output_file.setPermissions(io, std.Io.File.Permissions.fromMode(0o644));

    const record_hash = hashHex(record);
    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "rank2-definition-mapping-ok schema={s} path={s} bytes={} sha256={s}\n",
        .{ schema, output_path, record.len, &record_hash },
    );
    try stdout_writer.interface.flush();
}

fn rejectArguments(allocator: std.mem.Allocator, init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();
    if (args.next() != null) return MappingError.InvalidArguments;
}

fn verifyRepository(allocator: std.mem.Allocator, io: std.Io) !void {
    var environment = try createGitEnvironment(allocator);
    defer environment.deinit();

    const head_argv = [_][]const u8{
        git_executable,
        "--no-optional-locks",
        "-c",
        "core.fsmonitor=false",
        "-c",
        "core.untrackedCache=false",
        "-C",
        zig_root,
        "rev-parse",
        "HEAD",
    };
    const head = try runGit(allocator, io, &environment, &head_argv);
    defer allocator.free(head);
    try validateRevision(std.mem.trimEnd(u8, head, "\r\n"));

    const status_argv = [_][]const u8{
        git_executable,
        "--no-optional-locks",
        "-c",
        "core.fsmonitor=false",
        "-c",
        "core.untrackedCache=false",
        "-C",
        zig_root,
        "status",
        "--short",
    };
    const status = try runGit(allocator, io, &environment, &status_argv);
    defer allocator.free(status);
    if (status.len != 0) return MappingError.RepositoryDirty;

    const tracked_argv = [_][]const u8{
        git_executable,
        "--no-optional-locks",
        "-c",
        "core.fsmonitor=false",
        "-c",
        "core.untrackedCache=false",
        "-C",
        zig_root,
        "ls-files",
        "--error-unmatch",
        "--",
        module_root_path,
        std_root_path,
        io_module_path,
        definition_source_path,
    };
    const tracked = try runGit(allocator, io, &environment, &tracked_argv);
    defer allocator.free(tracked);
    const expected = [_][]const u8{ module_root_path, std_root_path, io_module_path, definition_source_path };
    var seen = [_]bool{false} ** expected.len;
    var lines = std.mem.tokenizeScalar(u8, tracked, '\n');
    var count: usize = 0;
    while (lines.next()) |raw_line| {
        const actual = std.mem.trimEnd(u8, raw_line, "\r");
        var matched = false;
        for (expected, 0..) |path, index| {
            if (!std.mem.eql(u8, actual, path)) continue;
            if (seen[index]) return MappingError.UntrackedMappingInput;
            seen[index] = true;
            matched = true;
            break;
        }
        if (!matched) return MappingError.UntrackedMappingInput;
        count += 1;
    }
    if (count != expected.len) return MappingError.UntrackedMappingInput;
    for (seen) |present| if (!present) return MappingError.UntrackedMappingInput;
}

fn verifyTrackedIdentifierSet(allocator: std.mem.Allocator, io: std.Io, expected_path: []const u8) !void {
    var environment = try createGitEnvironment(allocator);
    defer environment.deinit();
    const argv = [_][]const u8{
        git_executable,
        "--no-optional-locks",
        "-c",
        "core.fsmonitor=false",
        "-c",
        "core.untrackedCache=false",
        "-C",
        zig_root,
        "grep",
        "-n",
        "--fixed-strings",
        "--",
        definition_identifier,
        "--",
        "*.zig",
    };
    const output = try runGit(allocator, io, &environment, &argv);
    defer allocator.free(output);
    var lines = std.mem.tokenizeScalar(u8, output, '\n');
    var count: usize = 0;
    while (lines.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return MappingError.InvalidGitOutput;
        if (!std.mem.eql(u8, line[0..colon], expected_path)) return MappingError.AmbiguousDefinition;
        count += 1;
    }
    if (count != 2) return MappingError.IdentifierOccurrenceMismatch;
}

fn createGitEnvironment(allocator: std.mem.Allocator) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    try environment.put("LC_ALL", "C");
    try environment.put("LANG", "C");
    try environment.put("TZ", "UTC0");
    try environment.put("HOME", "/nonexistent");
    try environment.put("XDG_CONFIG_HOME", "/nonexistent");
    try environment.put("GIT_OPTIONAL_LOCKS", "0");
    try environment.put("GIT_CONFIG_NOSYSTEM", "1");
    try environment.put("GIT_CONFIG_SYSTEM", "/dev/null");
    try environment.put("GIT_CONFIG_GLOBAL", "/dev/null");
    try environment.put("GIT_CONFIG_COUNT", "0");
    try environment.put("GIT_TERMINAL_PROMPT", "0");
    return environment;
}

fn runGit(
    allocator: std.mem.Allocator,
    io: std.Io,
    environment: *const std.process.Environ.Map,
    argv: []const []const u8,
) ![]u8 {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
        .environ_map = environment,
        .stdout_limit = .limited(4 * 1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer allocator.free(result.stderr);
    const ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!ok) {
        allocator.free(result.stdout);
        return MappingError.RepositoryQueryFailed;
    }
    return result.stdout;
}

fn readTrackedSource(
    allocator: std.mem.Allocator,
    io: std.Io,
    root: std.Io.Dir,
    path: []const u8,
) ![]u8 {
    try validateCanonicalRelativePath(path);
    return root.readFileAlloc(io, path, allocator, .limited(16 * 1024 * 1024));
}

fn deriveMapping(allocator: std.mem.Allocator, sources: []const SourceFile) !Mapping {
    try validateProvenance(
        historical_candidate_rank,
        historical_source,
        historical_revision,
        mapping_target_revision,
        mapping_authority,
        fresh_cohort_status,
        air_row_binding,
        fully_qualified_symbol,
    );
    for (sources) |source| try validateCanonicalRelativePath(source.path);

    const main_source = findSource(sources, module_root_path) orelse return MappingError.ImportChainMismatch;
    const std_source = findSource(sources, std_root_path) orelse return MappingError.ImportChainMismatch;
    const io_source = findSource(sources, io_module_path) orelse return MappingError.ImportChainMismatch;
    const threaded_source = findSource(sources, definition_source_path) orelse return MappingError.DefinitionMissing;

    try requireImportAlias(allocator, main_source, "std", "\"std\"", false);
    try requireFieldAlias(allocator, main_source, "Io", "std", "Io", false);
    try requireImportAlias(allocator, std_source, "Io", "\"Io.zig\"", true);
    try requireImportAlias(allocator, io_source, "Threaded", "\"Io/Threaded.zig\"", true);

    var exact_identifier_tokens: usize = 0;
    var definitions: usize = 0;
    for (sources) |source| {
        const counts = try classifyIdentifier(allocator, source.bytes);
        exact_identifier_tokens += counts.tokens;
        definitions += counts.definitions;
        if (counts.definitions != 0 and !std.mem.eql(u8, source.path, definition_source_path)) {
            return MappingError.AmbiguousDefinition;
        }
    }
    if (definitions == 0) return MappingError.DefinitionMissing;
    if (definitions != 1) return MappingError.AmbiguousDefinition;
    if (exact_identifier_tokens != 2) return MappingError.IdentifierOccurrenceMismatch;

    return .{
        .definition_path = threaded_source.path,
        .exact_identifier_tokens = exact_identifier_tokens,
        .definitions = definitions,
    };
}

fn validateRevision(actual: []const u8) !void {
    if (!std.mem.eql(u8, actual, mapping_target_revision)) return MappingError.InvalidRevision;
}

fn validateProvenance(
    rank: []const u8,
    source: []const u8,
    historical_pin: []const u8,
    mapping_pin: []const u8,
    authority: []const u8,
    cohort_status: []const u8,
    row_binding: []const u8,
    symbol: []const u8,
) !void {
    if (!std.mem.eql(u8, rank, historical_candidate_rank)) return MappingError.InvalidProvenance;
    if (!std.mem.eql(u8, source, historical_source)) return MappingError.InvalidProvenance;
    if (!std.mem.eql(u8, historical_pin, historical_revision)) return MappingError.InvalidProvenance;
    if (!std.mem.eql(u8, mapping_pin, mapping_target_revision)) return MappingError.InvalidProvenance;
    if (std.mem.eql(u8, historical_pin, mapping_pin)) return MappingError.InvalidProvenance;
    if (!std.mem.eql(u8, authority, mapping_authority)) return MappingError.InvalidProvenance;
    if (!std.mem.eql(u8, cohort_status, fresh_cohort_status)) return MappingError.InvalidProvenance;
    if (!std.mem.eql(u8, row_binding, air_row_binding)) return MappingError.InvalidProvenance;
    if (!std.mem.eql(u8, symbol, fully_qualified_symbol)) return MappingError.InvalidProvenance;
}

fn findSource(sources: []const SourceFile, path: []const u8) ?SourceFile {
    var found: ?SourceFile = null;
    for (sources) |source| {
        if (!std.mem.eql(u8, source.path, path)) continue;
        if (found != null) return null;
        found = source;
    }
    return found;
}

fn requireImportAlias(
    allocator: std.mem.Allocator,
    source: SourceFile,
    alias: []const u8,
    expected_literal: []const u8,
    require_public: bool,
) !void {
    const sentinel = try allocator.dupeZ(u8, source.bytes);
    defer allocator.free(sentinel);
    var tree = try std.zig.Ast.parse(allocator, sentinel, .zig);
    defer tree.deinit(allocator);
    if (tree.errors.len != 0) return MappingError.ParseFailure;

    var matches: usize = 0;
    for (tree.rootDecls()) |decl| {
        const var_decl = tree.fullVarDecl(decl) orelse continue;
        if (!std.mem.eql(u8, tree.tokenSlice(var_decl.ast.mut_token + 1), alias)) continue;
        matches += 1;
        if ((var_decl.visib_token != null) != require_public) return MappingError.ImportChainMismatch;
        const init = var_decl.ast.init_node.unwrap() orelse return MappingError.ImportChainMismatch;
        var params_buffer: [2]std.zig.Ast.Node.Index = undefined;
        const params = tree.builtinCallParams(&params_buffer, init) orelse return MappingError.ImportChainMismatch;
        if (!std.mem.eql(u8, tree.tokenSlice(tree.nodeMainToken(init)), "@import")) return MappingError.ImportChainMismatch;
        if (params.len != 1 or tree.nodeTag(params[0]) != .string_literal) return MappingError.ImportChainMismatch;
        if (!std.mem.eql(u8, tree.tokenSlice(tree.nodeMainToken(params[0])), expected_literal)) return MappingError.ImportChainMismatch;
    }
    if (matches == 0) return MappingError.ImportChainMismatch;
    if (matches != 1) return MappingError.AmbiguousAlias;
}

fn requireFieldAlias(
    allocator: std.mem.Allocator,
    source: SourceFile,
    alias: []const u8,
    lhs_name: []const u8,
    field_name: []const u8,
    require_public: bool,
) !void {
    const sentinel = try allocator.dupeZ(u8, source.bytes);
    defer allocator.free(sentinel);
    var tree = try std.zig.Ast.parse(allocator, sentinel, .zig);
    defer tree.deinit(allocator);
    if (tree.errors.len != 0) return MappingError.ParseFailure;

    var matches: usize = 0;
    for (tree.rootDecls()) |decl| {
        const var_decl = tree.fullVarDecl(decl) orelse continue;
        if (!std.mem.eql(u8, tree.tokenSlice(var_decl.ast.mut_token + 1), alias)) continue;
        matches += 1;
        if ((var_decl.visib_token != null) != require_public) return MappingError.ImportChainMismatch;
        const init = var_decl.ast.init_node.unwrap() orelse return MappingError.ImportChainMismatch;
        if (tree.nodeTag(init) != .field_access) return MappingError.ImportChainMismatch;
        const data = tree.nodeData(init).node_and_token;
        if (tree.nodeTag(data[0]) != .identifier) return MappingError.ImportChainMismatch;
        if (!std.mem.eql(u8, tree.tokenSlice(tree.nodeMainToken(data[0])), lhs_name)) return MappingError.ImportChainMismatch;
        if (!std.mem.eql(u8, tree.tokenSlice(data[1]), field_name)) return MappingError.ImportChainMismatch;
    }
    if (matches == 0) return MappingError.ImportChainMismatch;
    if (matches != 1) return MappingError.AmbiguousAlias;
}

const IdentifierCounts = struct {
    tokens: usize,
    definitions: usize,
};

fn classifyIdentifier(allocator: std.mem.Allocator, source: []const u8) !IdentifierCounts {
    const sentinel = try allocator.dupeZ(u8, source);
    defer allocator.free(sentinel);
    var tree = try std.zig.Ast.parse(allocator, sentinel, .zig);
    defer tree.deinit(allocator);
    if (tree.errors.len != 0) return MappingError.ParseFailure;

    var tokens: usize = 0;
    for (0..tree.tokens.len) |index| {
        const token: std.zig.Ast.TokenIndex = @intCast(index);
        if (tree.tokenTag(token) == .identifier and std.mem.eql(u8, tree.tokenSlice(token), definition_identifier)) {
            tokens += 1;
        }
    }

    var definitions: usize = 0;
    for (0..tree.nodes.len) |index| {
        const node: std.zig.Ast.Node.Index = @enumFromInt(index);
        if (tree.nodeTag(node) != .fn_decl) continue;
        var buffer: [1]std.zig.Ast.Node.Index = undefined;
        const proto = tree.fullFnProto(&buffer, node) orelse continue;
        const name_token = proto.name_token orelse continue;
        if (std.mem.eql(u8, tree.tokenSlice(name_token), definition_identifier)) definitions += 1;
    }
    return .{ .tokens = tokens, .definitions = definitions };
}

fn validateCanonicalRelativePath(path: []const u8) !void {
    if (path.len == 0 or std.fs.path.isAbsolute(path)) return MappingError.InvalidPath;
    if (std.mem.indexOfScalar(u8, path, '\\') != null or std.mem.indexOfScalar(u8, path, 0) != null) return MappingError.InvalidPath;
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..")) {
            return MappingError.InvalidPath;
        }
    }
}

fn hashHex(bytes: []const u8) [Sha256.digest_length * 2]u8 {
    var digest: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(bytes, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

fn hashInputs(sources: []const SourceFile) FileDigests {
    const module_root = hashHex((findSource(sources, module_root_path) orelse unreachable).bytes);
    const std_root = hashHex((findSource(sources, std_root_path) orelse unreachable).bytes);
    const io_module = hashHex((findSource(sources, io_module_path) orelse unreachable).bytes);
    const definition_source = hashHex((findSource(sources, definition_source_path) orelse unreachable).bytes);
    var hasher = Sha256.init(.{});
    hasher.update(schema);
    hasher.update("\x00");
    hasher.update(historical_candidate_rank);
    hasher.update("\x00");
    hasher.update(historical_source);
    hasher.update("\x00");
    hasher.update(historical_revision);
    hasher.update("\x00");
    hasher.update(mapping_target_revision);
    hasher.update("\x00");
    hasher.update(mapping_authority);
    hasher.update("\x00");
    hasher.update(fresh_cohort_status);
    hasher.update("\x00");
    hasher.update(air_row_binding);
    hasher.update("\x00");
    hasher.update(fully_qualified_symbol);
    for (sources) |source| {
        hasher.update("\x00");
        hasher.update(source.path);
        hasher.update("\x00");
        const digest = hashHex(source.bytes);
        hasher.update(&digest);
    }
    var digest: [Sha256.digest_length]u8 = undefined;
    hasher.final(&digest);
    return .{
        .module_root = module_root,
        .std_root = std_root,
        .io_module = io_module,
        .definition_source = definition_source,
        .mapping_input = std.fmt.bytesToHex(digest, .lower),
    };
}

fn encodeRecord(allocator: std.mem.Allocator, mapping: Mapping, digests: FileDigests) ![]u8 {
    if (!std.mem.eql(u8, mapping.definition_path, definition_source_path)) return MappingError.InvalidProvenance;
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    const writer = &output.writer;
    try writer.writeAll("field\tvalue\n");
    try writer.print("schema\t{s}\n", .{schema});
    try writer.print("historical_candidate_rank\t{s}\n", .{historical_candidate_rank});
    try writer.print("historical_module_root_source\t{s}\n", .{historical_source});
    try writer.print("historical_candidate_zig_pin\t{s}\n", .{historical_revision});
    try writer.print("mapping_target_zig_pin\t{s}\n", .{mapping_target_revision});
    try writer.print("mapping_authority\t{s}\n", .{mapping_authority});
    try writer.print("fresh_cohort_status\t{s}\n", .{fresh_cohort_status});
    try writer.print("air_row_binding\t{s}\n", .{air_row_binding});
    try writer.print("module_root_path\t{s}\n", .{module_root_path});
    try writer.print("fully_qualified_symbol\t{s}\n", .{fully_qualified_symbol});
    try writer.writeAll("declaration_class\tfunction_definition\n");
    try writer.print("definition_source_path\t{s}\n", .{mapping.definition_path});
    try writer.print("mapping_method\t{s}\n", .{mapping_method});
    try writer.print("exact_identifier_tokens\t{}\n", .{mapping.exact_identifier_tokens});
    try writer.print("definition_count\t{}\n", .{mapping.definitions});
    try writer.print("module_root_sha256\t{s}\n", .{&digests.module_root});
    try writer.print("std_root_sha256\t{s}\n", .{&digests.std_root});
    try writer.print("io_module_sha256\t{s}\n", .{&digests.io_module});
    try writer.print("definition_source_sha256\t{s}\n", .{&digests.definition_source});
    try writer.print("mapping_input_sha256\t{s}\n", .{&digests.mapping_input});
    const record = try output.toOwnedSlice();
    if (std.mem.indexOfScalar(u8, record, '\r') != null or record.len == 0 or record[record.len - 1] != '\n') {
        allocator.free(record);
        return MappingError.NonCanonicalRecord;
    }
    return record;
}

const good_sources = [_]SourceFile{
    .{ .path = module_root_path, .bytes =
    \\const std = @import("std");
    \\const Io = std.Io;
    \\
    },
    .{ .path = std_root_path, .bytes =
    \\pub const Io = @import("Io.zig");
    \\
    },
    .{ .path = io_module_path, .bytes =
    \\pub const Threaded = @import("Io/Threaded.zig");
    \\
    },
    .{ .path = definition_source_path, .bytes =
    \\const posix = @import("std").posix;
    \\const use_it = doNothingSignalHandler;
    \\fn doNothingSignalHandler(_: posix.SIG) callconv(.c) void {}
    \\
    },
};

test "rank-2 AST import chain derives one definition" {
    const mapping = try deriveMapping(std.testing.allocator, &good_sources);
    try std.testing.expectEqualStrings(definition_source_path, mapping.definition_path);
    try std.testing.expectEqual(@as(usize, 2), mapping.exact_identifier_tokens);
    try std.testing.expectEqual(@as(usize, 1), mapping.definitions);
}

test "missing and altered import-chain links fail closed" {
    var missing = good_sources;
    missing[2].bytes = "pub const Threaded = @import(\"wrong.zig\");\n";
    try std.testing.expectError(MappingError.ImportChainMismatch, deriveMapping(std.testing.allocator, &missing));

    var altered = good_sources;
    altered[0].bytes = "const std = @import(\"std\");\nconst Io = other.Io;\n";
    try std.testing.expectError(MappingError.ImportChainMismatch, deriveMapping(std.testing.allocator, &altered));
}

test "missing duplicate and ambiguous definitions fail closed" {
    var missing = good_sources;
    missing[3].bytes = "const doNothingSignalHandler = 1;\nconst use_it = doNothingSignalHandler;\n";
    try std.testing.expectError(MappingError.DefinitionMissing, deriveMapping(std.testing.allocator, &missing));

    var duplicate = good_sources;
    duplicate[3].bytes =
        "fn doNothingSignalHandler() void {}\nfn doNothingSignalHandler() void {}\n";
    try std.testing.expectError(MappingError.AmbiguousDefinition, deriveMapping(std.testing.allocator, &duplicate));

    var ambiguous = good_sources;
    ambiguous[1].bytes =
        "pub const Io = @import(\"Io.zig\");\nfn doNothingSignalHandler() void {}\n";
    try std.testing.expectError(MappingError.AmbiguousDefinition, deriveMapping(std.testing.allocator, &ambiguous));
}

test "parse errors and occurrence drift fail closed" {
    var invalid = good_sources;
    invalid[3].bytes = "fn doNothingSignalHandler( {\n";
    try std.testing.expectError(MappingError.ParseFailure, deriveMapping(std.testing.allocator, &invalid));

    var drift = good_sources;
    drift[3].bytes = "fn doNothingSignalHandler() void {}\n";
    try std.testing.expectError(MappingError.IdentifierOccurrenceMismatch, deriveMapping(std.testing.allocator, &drift));
}

test "canonical repository-relative paths reject traversal and aliases" {
    try validateCanonicalRelativePath("lib/std/Io/Threaded.zig");
    try std.testing.expectError(MappingError.InvalidPath, validateCanonicalRelativePath("../lib/std.zig"));
    try std.testing.expectError(MappingError.InvalidPath, validateCanonicalRelativePath("lib//std.zig"));
    try std.testing.expectError(MappingError.InvalidPath, validateCanonicalRelativePath("/lib/std.zig"));
    try std.testing.expectError(MappingError.InvalidPath, validateCanonicalRelativePath("lib\\std.zig"));
}

test "pin and candidate provenance mismatches fail closed" {
    try validateRevision(mapping_target_revision);
    try std.testing.expectError(MappingError.InvalidRevision, validateRevision("0000000000000000000000000000000000000000"));
    try validateProvenance(
        historical_candidate_rank,
        historical_source,
        historical_revision,
        mapping_target_revision,
        mapping_authority,
        fresh_cohort_status,
        air_row_binding,
        fully_qualified_symbol,
    );
    try std.testing.expectError(MappingError.InvalidProvenance, validateProvenance(
        historical_candidate_rank,
        "lib/std/Io/Threaded.zig",
        historical_revision,
        mapping_target_revision,
        mapping_authority,
        fresh_cohort_status,
        air_row_binding,
        fully_qualified_symbol,
    ));
    try std.testing.expectError(MappingError.InvalidProvenance, validateProvenance(
        historical_candidate_rank,
        historical_source,
        mapping_target_revision,
        mapping_target_revision,
        mapping_authority,
        fresh_cohort_status,
        air_row_binding,
        fully_qualified_symbol,
    ));
    try std.testing.expectError(MappingError.InvalidProvenance, validateProvenance(
        historical_candidate_rank,
        historical_source,
        historical_revision,
        mapping_target_revision,
        mapping_authority,
        "materialized",
        "true",
        fully_qualified_symbol,
    ));
}

test "closed Git environment is deterministic and excludes parent authority" {
    var environment = try createGitEnvironment(std.testing.allocator);
    defer environment.deinit();
    try std.testing.expectEqual(@as(usize, 11), environment.count());
    try std.testing.expectEqualStrings("C", environment.get("LC_ALL") orelse "");
    try std.testing.expectEqualStrings("C", environment.get("LANG") orelse "");
    try std.testing.expectEqualStrings("UTC0", environment.get("TZ") orelse "");
    try std.testing.expectEqualStrings("0", environment.get("GIT_OPTIONAL_LOCKS") orelse "");
    try std.testing.expectEqualStrings("1", environment.get("GIT_CONFIG_NOSYSTEM") orelse "");
    try std.testing.expectEqualStrings("/dev/null", environment.get("GIT_CONFIG_GLOBAL") orelse "");
    try std.testing.expect(environment.get("GIT_DIR") == null);
    try std.testing.expect(environment.get("GIT_WORK_TREE") == null);
    try std.testing.expect(environment.get("GIT_INDEX_FILE") == null);
}

test "versioned record is canonical and binds security-critical inputs" {
    const mapping = try deriveMapping(std.testing.allocator, &good_sources);
    const digests = hashInputs(&good_sources);
    const record = try encodeRecord(std.testing.allocator, mapping, digests);
    defer std.testing.allocator.free(record);
    try std.testing.expect(std.mem.startsWith(u8, record, "field\tvalue\nschema\texecution-oracle-definition-mapping-v1\n"));
    try std.testing.expect(std.mem.indexOf(u8, record, "historical_candidate_rank\t2\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, record, "historical_candidate_zig_pin\t141bfce0883017ff7ebe03e3af3db07fff0c5dc3\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, record, "mapping_target_zig_pin\tbdee02bc0c7f227c0f11bc9a449df673fe803540\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, record, "mapping_authority\tcurrent_definition_only\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, record, "fresh_cohort_status\tnot_materialized\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, record, "air_row_binding\tfalse\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, record, "\npinned_revision\t") == null);
    try std.testing.expect(std.mem.indexOf(u8, record, "definition_source_path\tlib/std/Io/Threaded.zig\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, record, "mapping_input_sha256\t") != null);
    try std.testing.expect(record[record.len - 1] == '\n');
    try std.testing.expect(std.mem.indexOfScalar(u8, record, '\r') == null);
}
