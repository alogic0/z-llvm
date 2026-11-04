//! Closed reference-free attribute grammar. This is not a general attribute
//! verifier: unsupported syntax and keys remain unknown. In particular, an
//! arbitrary string attribute may name a helper (for example, probe-stack).
const std = @import("std");
const ir = @import("../ir.zig");
const Cursor = @import("reference_syntax.zig").Cursor;
const constants = @import("reference_constants.zig");

pub const Groups = struct {
    allocator: std.mem.Allocator,
    known: std.AutoHashMapUnmanaged(u32, bool) = .empty,
    has_unknown: bool = false,

    pub fn init(allocator: std.mem.Allocator, records: []const []const u8) !Groups {
        var groups: Groups = .{ .allocator = allocator };
        errdefer groups.deinit();
        for (records) |record| {
            const parsed = groupRecord(record) orelse {
                groups.has_unknown = true;
                continue;
            };
            const entry = try groups.known.getOrPut(allocator, parsed.id);
            if (entry.found_existing) {
                // Even equal duplicate definitions cannot establish coverage.
                entry.value_ptr.* = false;
                groups.has_unknown = true;
            } else {
                entry.value_ptr.* = referenceFree(parsed.body, null);
                if (!entry.value_ptr.*) groups.has_unknown = true;
            }
        }
        return groups;
    }

    pub fn deinit(groups: *Groups) void {
        groups.known.deinit(groups.allocator);
    }
};

const GroupRecord = struct { id: u32, body: []const u8 };

fn groupRecord(text: []const u8) ?GroupRecord {
    var cursor: Cursor = .{ .text = text };
    if (!std.mem.eql(u8, cursor.word() orelse return null, "attributes")) return null;
    if (!cursor.take('#')) return null;
    const id = cursor.number(u32) orelse return null;
    if (!cursor.take('=') or !cursor.take('{')) return null;
    const rest = std.mem.trim(u8, cursor.text[cursor.index..], " \t\r\n");
    if (rest.len == 0 or rest[rest.len - 1] != '}') return null;
    const body = std.mem.trim(u8, rest[0 .. rest.len - 1], " \t\r\n");
    if (body.len == 0) return null;
    return .{ .id = id, .body = body };
}

pub fn referenceFree(text: []const u8, groups: ?*const Groups) bool {
    var cursor: Cursor = .{ .text = text };
    while (!cursor.done()) {
        if (!takeOne(&cursor, groups)) return false;
        // Fields such as global alignment use comma-separated attributes.
        if (cursor.take(',') and cursor.done()) return false;
    }
    return true;
}

/// Consume exactly one attribute. Metadata attachments are handled separately.
pub fn takeOne(cursor: *Cursor, groups: ?*const Groups) bool {
    if (cursor.take('#')) {
        const id = cursor.number(u32) orelse return false;
        const context = groups orelse return false;
        if (!(context.known.get(id) orelse false)) return false;
    } else if (cursor.peek() == '"') {
        const key = cursor.string() orelse return false;
        if (!cursor.take('=')) return false;
        const value = cursor.string() orelse return false;
        if (ir.identifiers.eql(key, "frame-pointer")) {
            if (!ir.identifiers.eql(value, "all") and !ir.identifiers.eql(value, "non-leaf") and !ir.identifiers.eql(value, "none")) return false;
        } else if (!ir.identifiers.eql(key, "target-cpu") and !ir.identifiers.eql(key, "target-features")) return false;
    } else {
        const word = cursor.word() orelse return false;
        if (std.mem.eql(u8, word, "align")) {
            const alignment = cursor.number(u64) orelse return false;
            // LLVM Value::MaximumAlignment bounds this spelling too.
            if (alignment == 0 or alignment > 1 << 32 or alignment & (alignment - 1) != 0) return false;
        } else if (std.mem.eql(u8, word, "memory")) {
            if (!memoryEffects(cursor)) return false;
        } else if (constants.oneOf(word, &.{ "sret", "byval", "byref", "inalloca", "preallocated", "elementtype" })) {
            if (!cursor.take('(')) return false;
            _ = constants.typeName(cursor, 0) orelse return false;
            if (!cursor.take(')')) return false;
        } else if (std.mem.eql(u8, word, "captures")) {
            if (!cursor.take('(') or !cursor.keyword("none") or !cursor.take(')')) return false;
        } else if (constants.oneOf(word, &.{ "dereferenceable", "dereferenceable_or_null" })) {
            if (!cursor.take('(')) return false;
            _ = cursor.number(u64) orelse return false;
            if (!cursor.take(')')) return false;
        } else if (!simpleAttribute(word)) return false;
    }
    return true;
}

fn simpleAttribute(word: []const u8) bool {
    const known = [_][]const u8{
        "local_unnamed_addr", "unnamed_addr",   "nounwind",              "noundef",
        "noinline",           "alwaysinline",   "inlinehint",            "readnone",
        "readonly",           "writeonly",      "nocapture",             "nonnull",
        "noalias",            "willreturn",     "noreturn",              "nofree",
        "nosync",             "cold",           "hot",                   "optsize",
        "minsize",            "optnone",        "uwtable",               "dso_local",
        "dso_preemptable",    "signext",        "zeroext",               "inreg",
        "immarg",             "nocallback",     "nocreateundeforpoison", "nosanitize_coverage",
        "skipprofile",        "speculatable",   "norecurse",             "mustprogress",
        "returned",           "dead_on_unwind",
    };
    for (known) |candidate| if (std.mem.eql(u8, word, candidate)) return true;
    return false;
}

fn memoryEffects(cursor: *Cursor) bool {
    if (!cursor.take('(')) return false;
    var seen_location = false;
    while (true) {
        var access = cursor.word() orelse return false;
        if (cursor.take(':')) {
            if (!std.mem.eql(u8, access, "argmem") and !std.mem.eql(u8, access, "inaccessiblemem") and !std.mem.eql(u8, access, "errnomem")) return false;
            seen_location = true;
            access = cursor.word() orelse return false;
        } else if (seen_location) return false;
        if (!std.mem.eql(u8, access, "none") and !std.mem.eql(u8, access, "read") and !std.mem.eql(u8, access, "write") and !std.mem.eql(u8, access, "readwrite")) return false;
        if (cursor.take(')')) return true;
        if (!cursor.take(',')) return false;
    }
}
