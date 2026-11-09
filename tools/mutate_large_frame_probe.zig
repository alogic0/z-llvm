//! Negative control: remove only the page touches in large_frame_probe while
//! preserving every stack displacement, instruction offset, symbol and relocation.
const std = @import("std");
const u = @import("validation/common.zig");
const objects = @import("validation/object_contract.zig");

fn integer(comptime T: type, data: []const u8, offset: u64) !T {
    if (offset > data.len or @sizeOf(T) > data.len - offset) return error.InvalidElfBounds;
    return std.mem.readInt(T, data[@intCast(offset)..][0..@sizeOf(T)], .little);
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const args = try init.minimal.args.toSlice(c.a);
    if (args.len != 4) return error.ExpectedInputOutputMetadata;
    const input = try c.join(&.{args[1]});
    const output = try c.ownedPath(args[2]);
    const metadata = try c.ownedPath(args[3]);
    if (u.exists(c.io, output) or u.exists(c.io, metadata)) return error.EvidenceAlreadyExists;
    const data = try c.a.dupe(u8, try c.read(input));
    const before = try objects.parse(c.a, data);
    var found: ?[]u.Value = null;
    for (try u.json.array(try u.get(before, "symbols"))) |symbol| {
        const row = try u.json.array(symbol);
        if (!u.json.is(row[0], "large_frame_probe")) continue;
        if (found != null or row[3] != .string or (try u.json.integer(row[1])) & 15 != 2)
            return error.InvalidProbeSymbol;
        found = row;
    }
    const symbol = found orelse return error.MissingProbeSymbol;
    const value: u64 = @intCast(try u.json.integer(symbol[4]));
    const size: u64 = @intCast(try u.json.integer(symbol[5]));
    const table = try integer(u64, data, 40);
    const count = try integer(u16, data, 60);
    const strings = table + @as(u64, try integer(u16, data, 62)) * 64;
    const names_offset = try integer(u64, data, strings + 24);
    const names_size = try integer(u64, data, strings + 32);
    var start: ?usize = null;
    for (0..count) |index| {
        const header = table + index * 64;
        const name_offset = try integer(u32, data, header);
        if (name_offset >= names_size) return error.InvalidSectionName;
        const rest = data[@intCast(names_offset + name_offset)..@intCast(names_offset + names_size)];
        const end = std.mem.indexOfScalar(u8, rest, 0) orelse return error.InvalidSectionName;
        if (!std.mem.eql(u8, rest[0..end], symbol[3].string)) continue;
        if (start != null) return error.AmbiguousProbeSection;
        const offset = try integer(u64, data, header + 24);
        const section_size = try integer(u64, data, header + 32);
        if (value > section_size or size > section_size - value or
            offset > data.len or section_size > data.len - offset) return error.InvalidProbeBounds;
        start = @intCast(offset + value);
    }
    const first = start orelse return error.MissingProbeSection;
    const prefix = "\x48\x81\xec\xf8\x0f\x00\x00\x68\x00\x00\x00\x00";
    var cursor = first;
    var touches: usize = 0;
    while (cursor - first <= size and prefix.len <= size - (cursor - first) and
        std.mem.eql(u8, data[cursor..][0..prefix.len], prefix))
    {
        // sub rsp,4088; push 0 -> sub rsp,4088; sub rsp,8; nop.
        @memcpy(data[cursor + 7 ..][0..5], "\x48\x83\xec\x08\x90");
        cursor += prefix.len;
        touches += 1;
    }
    if (touches != 1792) return error.UnexpectedProbePageCount;
    const function_start = value;
    const mutated_prefix_bytes = cursor - first;
    for (try u.json.array(try u.get(before, "relocations"))) |relocation| {
        const row = try u.json.array(relocation);
        if (!u.json.eql(row[0], symbol[3])) continue;
        const at: u64 = @intCast(try u.json.integer(row[1]));
        if (at >= function_start and at - function_start < mutated_prefix_bytes)
            return error.RelocationInsideProbePrefix;
    }
    const after = try objects.parse(c.a, data);
    if (!u.json.eql(try u.get(before, "symbols"), try u.get(after, "symbols")) or
        !u.json.eql(try u.get(before, "relocations"), try u.get(after, "relocations")))
        return error.MutationChangedObjectIdentity;
    const file = try std.Io.Dir.cwd().createFile(c.io, output, .{ .exclusive = true });
    defer file.close(c.io);
    try file.writeStreamingAll(c.io, data);
    try c.writeJson(metadata, try u.toValue(c.a, .{
        .scope = "Negative control only; no accepted compiler or source mutation",
        .input = input,
        .input_sha256 = try c.digest(input),
        .output = output,
        .output_sha256 = try c.digest(output),
        .function = "large_frame_probe",
        .removed_page_touches = touches,
        .function_file_offset = first,
        .mutated_prefix_bytes = mutated_prefix_bytes,
        .object_bytes = data.len,
        .stack_displacements_symbols_relocations_and_code_offsets_preserved = true,
    }));
}
