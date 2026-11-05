//! Authenticated semantic facts for the offline selector-v3 audit.
const std = @import("std");
const u = @import("common.zig");
pub const schema = "real-candidate-facts-v1";
pub const manifest_schema = "real-candidate-facts-manifest-v1";
pub const target = "x86_64-linux-gnu";
pub const Fact = struct {
    signature: []const u8,
    instructions: i64,
    calls: i64,
    global_refs: i64,
    runtime_refs: i64,
    undefined_result: bool,
    typed_sha256: []const u8,

    pub fn value(fact: Fact, a: std.mem.Allocator) !u.Value {
        var result = u.object(a);
        inline for (@typeInfo(Fact).@"struct".field_names) |name| {
            const item = @field(fact, name);
            try u.put(a, &result, name, if (@TypeOf(item) == []const u8) u.s(item) else if (@TypeOf(item) == bool) u.b(item) else u.n(item));
        }
        return result;
    }
};
pub const Facts = struct { functions: std.StringHashMap(Fact), duplicates: []const []const u8, descriptor_sha256: []const u8 };

pub fn validHash(hash: []const u8) bool {
    if (hash.len != 64) return false;
    for (hash) |ch| if (!std.ascii.isDigit(ch) and (ch < 'a' or ch > 'f')) return false;
    return true;
}
pub fn rejectionCount(audit: u.Value) !i64 {
    return if (audit.object.get("unstable_signatures_or_empty_bodies_count")) |count| u.json.integer(count) else @intCast((try u.json.array(try u.get(audit, "unstable_signatures_or_empty_bodies"))).len);
}
pub fn rejectionDigest(a: std.mem.Allocator, names: []const []const u8) ![]const u8 {
    return u.digestBytes(a, try u.canonical(a, try u.strings(a, names)));
}
pub fn validate(c: *u.Context, payload: u.Value, mode: []const u8, pin: []const u8, descriptor: []const u8) !Facts {
    const keys = [_][]const u8{ "schema", "source_pin", "mode", "target", "descriptor_sha256" };
    const values = [_][]const u8{ schema, pin, mode, target, descriptor };
    for (keys, values) |key, value| if (!u.json.is(try u.get(payload, key), value)) return c.fail("candidate fact identity mismatch", .{});
    if (!validHash(descriptor)) return c.fail("candidate fact identity mismatch", .{});
    const functions = try u.get(payload, "functions");
    if (functions != .object) return error.InvalidCandidateFactPopulation;
    const duplicates = try u.stringSlice(c.a, try u.get(payload, "ambiguous_symbols_excluded"));
    for (duplicates, 0..) |name, i| {
        if (name.len == 0 or functions.object.contains(name) or (i != 0 and !std.mem.lessThan(u8, duplicates[i - 1], name))) return error.InvalidCandidateFactPopulation;
    }
    if (try u.json.integer(try u.get(payload, "unambiguous_functions")) != functions.object.count()) return error.InvalidCandidateFactPopulation;
    var result = std.StringHashMap(Fact).init(c.a);
    for (functions.object.keys(), functions.object.values()) |name, value| {
        if (name.len == 0) return error.InvalidCandidateFunctionFacts;
        try u.json.exact(value, &.{ "signature", "instructions", "calls", "global_refs", "runtime_refs", "undefined_result", "typed_sha256" });
        const fact: Fact = .{ .signature = try u.json.str(value, "signature"), .instructions = try u.json.integer(try u.get(value, "instructions")), .calls = try u.json.integer(try u.get(value, "calls")), .global_refs = try u.json.integer(try u.get(value, "global_refs")), .runtime_refs = try u.json.integer(try u.get(value, "runtime_refs")), .undefined_result = blk: {
            const boolean = try u.get(value, "undefined_result");
            if (boolean != .bool) return error.InvalidCandidateResult;
            break :blk boolean.bool;
        }, .typed_sha256 = try u.str(value, "typed_sha256") };
        if (fact.instructions < 0 or fact.calls < 0 or fact.global_refs < 0 or fact.runtime_refs < 0 or fact.calls > fact.instructions or fact.runtime_refs > fact.calls) return error.InvalidCandidateEffectCount;
        if (!validHash(fact.typed_sha256)) return error.InvalidTypedBodyHash;
        try result.put(name, fact);
    }
    return .{ .functions = result, .duplicates = duplicates, .descriptor_sha256 = descriptor };
}
pub fn load(c: *u.Context, path: []const u8, mode: []const u8, pin: []const u8, expected: []const u8, descriptor: []const u8) !Facts {
    if (!validHash(expected) or !std.mem.eql(u8, try c.digest(path), expected)) return c.fail("candidate fact hash mismatch", .{});
    return validate(c, try c.load(path), mode, pin, descriptor);
}
pub fn write(c: *u.Context, path: []const u8, mode: []const u8, pin: []const u8, facts: Facts) ![]const u8 {
    var functions = u.object(c.a);
    var iterator = facts.functions.iterator();
    while (iterator.next()) |entry| try u.put(c.a, &functions, entry.key_ptr.*, try entry.value_ptr.value(c.a));
    var payload = u.object(c.a);
    const keys = [_][]const u8{ "schema", "source_pin", "mode", "target", "descriptor_sha256" };
    const values = [_][]const u8{ schema, pin, mode, target, facts.descriptor_sha256 };
    for (keys, values) |key, value| try u.put(c.a, &payload, key, u.s(value));
    try u.put(c.a, &payload, "unambiguous_functions", u.n(facts.functions.count()));
    try u.put(c.a, &payload, "ambiguous_symbols_excluded", try u.strings(c.a, facts.duplicates));
    try u.put(c.a, &payload, "functions", functions);
    _ = try validate(c, payload, mode, pin, facts.descriptor_sha256);
    const data = try c.fmt("{s}\n", .{try u.canonical(c.a, payload)});
    const file = try std.Io.Dir.cwd().createFile(c.io, path, .{ .exclusive = true });
    defer file.close(c.io);
    try file.writeStreamingAll(c.io, data);
    return u.digestBytes(c.a, data);
}

pub const Descriptor = struct {
    data: []const u8,
    position: usize = 0,
    pub fn line(reader: *Descriptor) ![]const u8 {
        if (reader.position == reader.data.len) return "";
        const tail = reader.data[reader.position..];
        const size = std.mem.indexOfScalar(u8, tail, '\n') orelse return error.TruncatedDescriptorLine;
        reader.position += size + 1;
        return tail[0..size];
    }
    pub fn nonempty(reader: *Descriptor) ![]const u8 {
        var text = try reader.line();
        while (text.len == 0 and reader.position < reader.data.len) text = try reader.line();
        return text;
    }
    pub fn value(reader: *Descriptor, key: []const u8) ![]const u8 {
        const text = try reader.line();
        if (text.len <= key.len or !std.mem.startsWith(u8, text, key) or text[key.len] != '=') return error.UnexpectedDescriptorField;
        return text[key.len + 1 ..];
    }
    pub fn frame(reader: *Descriptor, key: []const u8) ![]const u8 {
        return reader.frameSize(try std.fmt.parseUnsigned(usize, try reader.value(key), 10));
    }
    pub fn frameSize(reader: *Descriptor, size: usize) ![]const u8 {
        if (size >= reader.data.len - reader.position or reader.data[reader.position + size] != '\n') return error.InvalidDescriptorFrame;
        const bytes = reader.data[reader.position .. reader.position + size];
        reader.position += size + 1;
        return bytes;
    }
};
pub fn scan(c: *u.Context, path: []const u8, mode: []const u8, pin: []const u8) !Facts {
    const metadata_path = try c.fmt("{s}.meta", .{path[0 .. path.len - std.fs.path.extension(path).len]});
    var metadata = std.StringHashMap([]const u8).init(c.a);
    var lines = std.mem.tokenizeScalar(u8, try c.read(metadata_path), '\n');
    while (lines.next()) |line| {
        const at = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        try metadata.put(line[0..at], line[at + 1 ..]);
    }
    if (!std.mem.eql(u8, metadata.get("schema") orelse "", "3") or !std.mem.eql(u8, metadata.get("ziglang_pin") orelse "", pin) or !std.mem.eql(u8, metadata.get("mode") orelse "", mode)) return c.fail("descriptor identity mismatch: {s}", .{path});
    const file = try std.Io.Dir.cwd().openFile(c.io, path, .{});
    defer file.close(c.io);
    const before = try file.stat(c.io);
    if (before.size == 0) return error.EmptyDescriptor;
    const data = try std.posix.mmap(null, @intCast(before.size), .{ .READ = true }, .{ .TYPE = .PRIVATE }, file.handle, 0);
    defer std.posix.munmap(data);
    const digest = try u.digestBytes(c.a, data);
    if (!std.mem.eql(u8, digest, metadata.get("descriptor_sha256") orelse "")) return c.fail("descriptor hash mismatch: {s}", .{path});
    const result = try scanBytes(c, data, mode, digest);
    const after = try file.stat(c.io);
    if (before.inode != after.inode or before.size != after.size or before.mtime.nanoseconds != after.mtime.nanoseconds) return error.DescriptorChangedDuringScan;
    return result;
}
pub fn scanBytes(c: *u.Context, data: []const u8, mode: []const u8, descriptor_hash: []const u8) !Facts {
    var reader: Descriptor = .{ .data = data };
    if (!std.mem.eql(u8, try reader.line(), "zllvm-air-export-v1")) return error.UnknownDescriptorContract;
    const version = try reader.value("contract_version");
    _ = try reader.value("payload");
    _ = try reader.value("producer");
    const root = try reader.value("root_source");
    _ = try reader.value("wrapper");
    const found_mode = try reader.value("mode");
    const found_target = try reader.value("target");
    const function_count = try std.fmt.parseUnsigned(usize, try reader.value("function_count"), 10);
    const global_count = try std.fmt.parseUnsigned(usize, try reader.value("global_count"), 10);
    if (!std.mem.eql(u8, found_mode, mode) or !std.mem.eql(u8, version, "1") or !std.mem.eql(u8, root, "main.zig") or !u.contains(&.{ target, "x86_64-unknown-linux5.10.0-gnu2.31.0" }, found_target)) return c.fail("incorrect descriptor header", .{});
    for (0..global_count) |_| {
        if (!std.mem.eql(u8, try reader.nonempty(), "global_begin")) return error.MissingGlobalFrame;
        _ = try reader.frame("name_bytes");
        _ = try reader.frame("type_bytes");
        _ = try reader.value("thread_local");
        _ = try reader.value("constant");
        _ = try reader.frame("initializer_bytes");
        if (!std.mem.eql(u8, try reader.nonempty(), "global_end")) return error.MissingGlobalEnd;
    }
    var next = try reader.nonempty();
    while (std.mem.startsWith(u8, next, "aggregate_layout_facts_bytes=") or std.mem.startsWith(u8, next, "error_union_call_facts_bytes=")) {
        _ = try reader.frameSize(try std.fmt.parseUnsigned(usize, next[(std.mem.indexOfScalar(u8, next, '=').? + 1)..], 10));
        next = try reader.nonempty();
    }
    var functions = std.StringHashMap(Fact).init(c.a);
    var duplicates = std.StringHashMap(void).init(c.a);
    for (0..function_count) |_| {
        if (!std.mem.eql(u8, next, "function_begin")) return error.MissingFunctionFrame;
        const name = try c.a.dupe(u8, try reader.frame("name_bytes"));
        const signature = try c.a.dupe(u8, try reader.frame("type_bytes"));
        if (!std.unicode.utf8ValidateSlice(name) or !std.unicode.utf8ValidateSlice(signature)) return error.InvalidDescriptorUtf8;
        const count = try std.fmt.parseUnsigned(i64, try reader.value("instruction_count"), 10);
        _ = try reader.value("main_body_count");
        _ = try reader.value("liveness");
        _ = try reader.frame("air_bytes");
        _ = try reader.frame("structured_air_bytes");
        const typed = try reader.frame("structured_air_v2_bytes");
        if (!std.mem.eql(u8, try reader.nonempty(), "function_end")) return error.MissingFunctionEnd;
        var fact: Fact = .{ .signature = signature, .instructions = count, .calls = 0, .global_refs = 0, .runtime_refs = 0, .undefined_result = false, .typed_sha256 = try u.digestBytes(c.a, typed) };
        var observed: i64 = 0;
        var typed_lines = std.mem.splitScalar(u8, typed, '\n');
        while (typed_lines.next()) |line| {
            if (!std.mem.startsWith(u8, line, "typed_inst|")) continue;
            var fields = std.mem.splitScalar(u8, line, '|');
            _ = fields.next();
            const index = fields.next() orelse return error.InvalidTypedInstruction;
            const opcode = fields.next() orelse return error.InvalidTypedInstruction;
            if (index.len > 0 and opcode.len > 0 and fields.peek() != null and allDigits(index)) {
                observed += 1;
                if (std.mem.startsWith(u8, opcode, "call")) fact.calls += 1;
            }
            if (std.mem.startsWith(u8, opcode, "call")) {
                for ([_][]const u8{ "compiler_rt", "__ubsan", "__zig", "panic", "defaultPanic", "memcpy", "memset", "memmove", "libc" }) |marker| if (std.mem.indexOf(u8, line, marker) != null) {
                    fact.runtime_refs += 1;
                    break;
                };
            }
            if (u.contains(&.{ "ret", "ret_safe" }, opcode) and std.mem.indexOf(u8, line, "undefined>") != null) fact.undefined_result = true;
        }
        for (typed, 0..) |ch, i| if (ch == '@' and i + 1 < typed.len and (std.ascii.isAlphabetic(typed[i + 1]) or typed[i + 1] == '_')) {
            fact.global_refs += 1;
        };
        if (observed != count) return c.fail("incomplete typed body: {s}", .{name});
        if (functions.contains(name)) try duplicates.put(name, {});
        try functions.put(name, fact);
        next = try reader.nonempty();
    }
    if (!u.contains(&.{ "", "air_export_end", "export_end" }, next) or u.trim(data[reader.position..]).len != 0) return error.UnexpectedExportTerminator;
    const excluded = try c.a.alloc([]const u8, duplicates.count());
    var iterator = duplicates.keyIterator();
    var i: usize = 0;
    while (iterator.next()) |name| : (i += 1) {
        excluded[i] = name.*;
        _ = functions.remove(name.*);
    }
    std.mem.sort([]const u8, excluded, {}, lessString);
    return .{ .functions = functions, .duplicates = excluded, .descriptor_sha256 = descriptor_hash };
}
fn allDigits(text: []const u8) bool {
    for (text) |ch| if (!std.ascii.isDigit(ch)) return false;
    return true;
}
pub fn lessString(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}
