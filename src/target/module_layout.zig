//! Borrowed, module-aware memory geometry. These facts grant no register ABI
//! or backend support. Callers select native defaults and admission separately.
const std = @import("std");
const ir = @import("../ir/core.zig");
const identifiers = @import("../ir/identifiers.zig");
const parser = @import("../ir/parser_types_values.zig");
const syntax = @import("../ir/parser_syntax.zig");
const Fields = @import("../ir/structure.zig").Fields;

pub const Facts = struct {
    store_bytes: u64,
    allocation_bytes: u64,
    abi_alignment: u64,
};

pub const Options = struct {
    identifier_equality: enum { spelling, decoded } = .decoded,
    max_depth: u8 = 32,
    max_extent: u64 = std.math.maxInt(u64),
    max_array_count: u64 = std.math.maxInt(u64),
    /// Called for every complete node, including a zero-length array's child.
    admit: ?*const fn ([]const u8, ir.Type, Facts) bool = null,
};

pub const Field = struct { ty: ir.Type, offset: u64 };

pub const Query = struct {
    text: []const u8,
    named_types: []const ir.NamedTypeDefinition,
    options: Options,

    pub fn init(text: []const u8, named_types: []const ir.NamedTypeDefinition, options: Options) ?Query {
        if (options.max_depth == 0 or options.max_depth > 64) return null;
        var parts = std.mem.splitScalar(u8, text, '-');
        while (parts.next()) |part| {
            if (part.len == 0) continue;
            switch (part[0]) {
                'i', 'f', 'v' => _ = primitive(part) orelse return null,
                'a' => _ = aggregateAlignment(part) orelse return null,
                'p' => _ = pointerSpec(part) orelse return null,
                else => {},
            }
        }
        return .{ .text = text, .named_types = named_types, .options = options };
    }

    pub fn query(self: Query, ty: ir.Type) ?Facts {
        return self.queryDepth(ty, 0);
    }

    /// A prefix offset is returned only after the entire source layout passes.
    pub fn field(self: Query, source: ir.Type, index: usize) ?Field {
        _ = self.query(source) orelse return null;
        var ty = source;
        var depth: u8 = 0;
        while (depth < self.options.max_depth) : (depth += 1) {
            if (ty != .aggregate) return null;
            const text = trim(ty.aggregate);
            if (text.len == 0) return null;
            if (text[0] == '%') {
                ty = self.resolve(text[1..]) orelse return null;
                continue;
            }
            var fields = Fields.init(text) orelse return null;
            var offset: u64 = 0;
            var at: usize = 0;
            while (fields.next()) |raw| : (at += 1) {
                const child_ty = parse(raw) orelse return null;
                const child = self.query(child_ty) orelse return null;
                if (!fields.packed_type) offset = alignForward(offset, child.abi_alignment) orelse return null;
                if (at == index) return .{ .ty = child_ty, .offset = offset };
                offset = std.math.add(u64, offset, child.allocation_bytes) catch return null;
            }
            return null;
        }
        return null;
    }

    fn resolve(self: Query, name: []const u8) ?ir.Type {
        var found: ?[]const u8 = null;
        for (self.named_types) |named| {
            const matches = switch (self.options.identifier_equality) {
                .spelling => std.mem.eql(u8, named.name, name),
                .decoded => identifiers.eql(named.name, name),
            };
            if (matches) {
                if (found != null) return null;
                found = named.body;
            }
        }
        return parse(found orelse return null);
    }

    fn queryDepth(self: Query, ty: ir.Type, depth: u8) ?Facts {
        if (depth >= self.options.max_depth) return null;
        const facts = switch (ty) {
            .void, .metadata => return null,
            .aggregate => |raw| blk: {
                const text = trim(raw);
                if (text.len == 0 or (syntax.findTopLevelTokenEnd(text) orelse return null) != text.len) return null;
                if (text[0] == '%') break :blk self.queryDepth(self.resolve(text[1..]) orelse return null, depth + 1) orelse return null;
                if (text[0] == '[' and text[text.len - 1] == ']') {
                    const inside = trim(text[1 .. text.len - 1]);
                    var tokens = std.mem.tokenizeAny(u8, inside, " \t\r\n");
                    const count = std.fmt.parseUnsigned(u64, tokens.next() orelse return null, 10) catch return null;
                    if (count > self.options.max_array_count or !std.mem.eql(u8, tokens.next() orelse return null, "x")) return null;
                    const child = self.queryDepth(parse(trim(tokens.rest())) orelse return null, depth + 1) orelse return null;
                    const bytes = std.math.mul(u64, count, child.allocation_bytes) catch return null;
                    break :blk Facts{ .store_bytes = bytes, .allocation_bytes = bytes, .abi_alignment = child.abi_alignment };
                }
                var fields = Fields.init(text) orelse return null;
                var bytes: u64 = 0;
                var alignment: u64 = if (fields.packed_type) 1 else self.aggregateFloor();
                while (fields.next()) |raw_field| {
                    const child = self.queryDepth(parse(raw_field) orelse return null, depth + 1) orelse return null;
                    if (!fields.packed_type) {
                        alignment = @max(alignment, child.abi_alignment);
                        bytes = alignForward(bytes, child.abi_alignment) orelse return null;
                    }
                    bytes = std.math.add(u64, bytes, child.allocation_bytes) catch return null;
                    if (bytes > self.options.max_extent) return null;
                }
                bytes = alignForward(bytes, alignment) orelse return null;
                break :blk Facts{ .store_bytes = bytes, .allocation_bytes = bytes, .abi_alignment = alignment };
            },
            .vector => |vector| blk: {
                if (vector.len == 0) return null;
                const bits = std.math.mul(u64, vector.len, self.scalarBits(vector.elem_ty.toType()) orelse return null) catch return null;
                const bytes = (std.math.add(u64, bits, 7) catch return null) / 8;
                const natural = std.math.ceilPowerOfTwo(u64, bytes) catch return null;
                const alignment = self.exactAlignment('v', bits) orelse natural;
                break :blk scalarFacts(bytes, alignment) orelse return null;
            },
            else => blk: {
                const bits = self.scalarBits(ty) orelse return null;
                const bytes = (std.math.add(u64, bits, 7) catch return null) / 8;
                const alignment = switch (ty) {
                    .int => self.integerAlignment(bits),
                    .ptr => self.pointer().alignment,
                    else => self.exactAlignment('f', bits) orelse (std.math.ceilPowerOfTwo(u64, bytes) catch return null),
                };
                break :blk scalarFacts(bytes, alignment) orelse return null;
            },
        };
        if (facts.store_bytes > self.options.max_extent or facts.allocation_bytes > self.options.max_extent) return null;
        if (self.options.admit) |admit| if (!admit(self.text, ty, facts)) return null;
        return facts;
    }

    fn scalarBits(self: Query, ty: ir.Type) ?u64 {
        return switch (ty) {
            .int => |bits| if (bits == 0) null else bits,
            .half => 16,
            .float => 32,
            .double => 64,
            .x86_fp80 => 80,
            .fp128 => 128,
            .ptr => self.pointer().bits,
            else => null,
        };
    }

    fn pointer(self: Query) Pointer {
        var result: Pointer = .{ .space = 0, .bits = 64, .alignment = 8 };
        var parts = std.mem.splitScalar(u8, self.text, '-');
        while (parts.next()) |part| {
            if (part.len == 0 or part[0] != 'p') continue;
            const spec = pointerSpec(part).?;
            if (spec.space == 0) result = spec;
        }
        return result;
    }

    fn aggregateFloor(self: Query) u64 {
        var result: u64 = 1;
        var parts = std.mem.splitScalar(u8, self.text, '-');
        while (parts.next()) |part| if (std.mem.startsWith(u8, part, "a:")) {
            result = aggregateAlignment(part).?;
        };
        return result;
    }

    fn exactAlignment(self: Query, kind: u8, bits: u64) ?u64 {
        var result: ?u64 = null;
        var parts = std.mem.splitScalar(u8, self.text, '-');
        while (parts.next()) |part| {
            if (part.len == 0 or part[0] != kind) continue;
            const spec = primitive(part).?;
            if (spec.bits == bits) result = spec.alignment;
        }
        return result;
    }

    fn integerAlignment(self: Query, bits: u64) u64 {
        const defaults = [_]Primitive{
            .{ .bits = 8, .alignment = 1 },  .{ .bits = 16, .alignment = 2 },
            .{ .bits = 32, .alignment = 4 }, .{ .bits = 64, .alignment = 4 },
        };
        var above: ?u64 = null;
        var largest: u64 = 0;
        for (defaults) |spec| chooseWidth(spec.bits, bits, &above, &largest);
        var parts = std.mem.splitScalar(u8, self.text, '-');
        while (parts.next()) |part| if (part.len != 0 and part[0] == 'i') {
            chooseWidth(primitive(part).?.bits, bits, &above, &largest);
        };
        const selected = above orelse largest;
        if (self.exactAlignment('i', selected)) |alignment| return alignment;
        for (defaults) |spec| if (spec.bits == selected) return spec.alignment;
        unreachable; // An explicit selected width necessarily has a spec.
    }
};

const Primitive = struct { bits: u64, alignment: u64 };
const Pointer = struct { space: u32, bits: u64, alignment: u64 };

fn chooseWidth(width: u64, wanted: u64, above: *?u64, largest: *u64) void {
    largest.* = @max(largest.*, width);
    if (width >= wanted and (above.* == null or width < above.*.?)) above.* = width;
}

fn primitive(part: []const u8) ?Primitive {
    const colon = std.mem.indexOfScalar(u8, part, ':') orelse return null;
    const bits = std.fmt.parseUnsigned(u32, part[1..colon], 10) catch return null;
    if (bits == 0) return null;
    return .{ .bits = bits, .alignment = alignmentFields(part[colon + 1 ..], false) orelse return null };
}

fn aggregateAlignment(part: []const u8) ?u64 {
    if (!std.mem.startsWith(u8, part, "a:")) return null;
    return alignmentFields(part[2..], true);
}

fn alignmentFields(text: []const u8, zero: bool) ?u64 {
    var fields = std.mem.splitScalar(u8, text, ':');
    const abi = std.fmt.parseUnsigned(u32, fields.next() orelse return null, 10) catch return null;
    if (!(zero and abi == 0) and (abi < 8 or !std.math.isPowerOfTwo(abi))) return null;
    if (fields.next()) |raw| {
        const preferred = std.fmt.parseUnsigned(u32, raw, 10) catch return null;
        if (preferred < abi or (!(zero and preferred == 0) and (preferred < 8 or !std.math.isPowerOfTwo(preferred)))) return null;
    }
    if (fields.next() != null) return null;
    return @max(1, @as(u64, abi) / 8);
}

fn pointerSpec(part: []const u8) ?Pointer {
    const colon = std.mem.indexOfScalar(u8, part, ':') orelse return null;
    const space = if (colon == 1) 0 else std.fmt.parseUnsigned(u32, part[1..colon], 10) catch return null;
    var fields = std.mem.splitScalar(u8, part[colon + 1 ..], ':');
    const bits = std.fmt.parseUnsigned(u32, fields.next() orelse return null, 10) catch return null;
    const abi = std.fmt.parseUnsigned(u32, fields.next() orelse return null, 10) catch return null;
    if (bits == 0 or bits % 8 != 0 or abi < 8 or !std.math.isPowerOfTwo(abi)) return null;
    if (fields.next()) |raw| {
        const preferred = std.fmt.parseUnsigned(u32, raw, 10) catch return null;
        if (preferred < abi or !std.math.isPowerOfTwo(preferred)) return null;
    }
    if (fields.next()) |raw| {
        const index = std.fmt.parseUnsigned(u32, raw, 10) catch return null;
        if (index == 0 or index > bits) return null;
    }
    if (fields.next() != null) return null;
    return .{ .space = space, .bits = bits, .alignment = abi / 8 };
}

fn scalarFacts(bytes: u64, alignment: u64) ?Facts {
    return .{ .store_bytes = bytes, .allocation_bytes = alignForward(bytes, alignment) orelse return null, .abi_alignment = alignment };
}

fn alignForward(value: u64, alignment: u64) ?u64 {
    const remainder = value % alignment;
    return if (remainder == 0) value else std.math.add(u64, value, alignment - remainder) catch null;
}

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t\r\n");
}

fn parse(text: []const u8) ?ir.Type {
    return parser.parseType(trim(text)) catch null;
}
