//! Read-only enumeration of module symbol uses. Value.named beginning with @
//! is global; bare names are local SSA names. Alias targets and direct callees
//! are symbols by their field's contract. Definition names and CFG labels are
//! not uses. Removed instructions and replacement bookkeeping are skipped.
//!
//! Opaque expressions/aggregates, assembly, metadata, bundles and raw arguments
//! report unknown references, never absence inferred from a substring search.
//! Only an explicit grammar of reference-free attributes is accepted as absent.
//! Visitors declare Error and visit(site, event); borrowed pointers/text remain
//! valid only while the source module and its storage remain unchanged.
const std = @import("std");
const ir = @import("../ir.zig");

pub const Site = union(enum) {
    module,
    global: *const ir.Global,
    alias: *const ir.GlobalAlias,
    function: *const ir.Function,
    declaration: *const ir.FunctionDecl,
    instruction: *const ir.Instruction,
    terminator: *const ir.Terminator,
};

pub const OpaqueKind = enum { value, initializer, assembly, metadata, attributes, raw_arguments, operand_bundle };
pub const Event = union(enum) {
    /// Module symbol spelling without @, as stored in definition names.
    symbol: []const u8,
    unknown: OpaqueKind,
};

pub fn isDirectValue(value: ir.Value, name: []const u8) bool {
    return value == .named and value.named.len > 1 and value.named[0] == '@' and std.mem.eql(u8, value.named[1..], name);
}

fn valueReference(value: ir.Value, site: Site, visitor: anytype) @TypeOf(visitor).Error!void {
    switch (value) {
        .named => |name| {
            if (name.len > 1 and name[0] == '@') {
                try visitor.visit(site, .{ .symbol = name[1..] });
            } else if (name.len != 0 and name[0] == '!') {
                try visitor.visit(site, .{ .unknown = .metadata });
            }
        },
        .vector, .constant_expr => try visitor.visit(site, .{ .unknown = .value }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => {},
    }
}

fn ValueVisitor(comptime Visitor: type) type {
    return struct {
        pub const Error = Visitor.Error;
        visitor: Visitor,
        site: Site,
        pub fn visit(walker: @This(), value: *const ir.Value, _: ir.Type) Error!void {
            try valueReference(value.*, walker.site, walker.visitor);
        }
    };
}

fn opaqueText(text: ?[]const u8, kind: OpaqueKind, site: Site, visitor: anytype) @TypeOf(visitor).Error!void {
    if (text) |s| {
        if (s.len != 0) try visitor.visit(site, .{ .unknown = kind });
    }
}

// This is a complete whitelist for this small grammar, not a search for @.
// Unknown tokens (including attribute-group references) retain unknown status.
fn referenceFreeAttributes(text: []const u8) bool {
    var tokens = std.mem.tokenizeAny(u8, text, " \t\r\n,");
    while (tokens.next()) |token| {
        if (std.mem.eql(u8, token, "align")) {
            _ = std.fmt.parseInt(u64, tokens.next() orelse return false, 10) catch return false;
            continue;
        }
        const known = [_][]const u8{
            "local_unnamed_addr", "unnamed_addr", "nounwind",   "noundef",
            "noinline",           "alwaysinline", "inlinehint", "readnone",
            "readonly",           "writeonly",    "nocapture",  "nonnull",
            "noalias",            "willreturn",   "noreturn",   "nofree",
            "nosync",             "cold",         "hot",        "optsize",
            "minsize",            "optnone",      "uwtable",    "dso_local",
            "dso_preemptable",    "signext",      "zeroext",    "inreg",
            "immarg",
        };
        var recognized = false;
        for (known) |word| {
            if (std.mem.eql(u8, token, word)) {
                recognized = true;
                break;
            }
        }
        if (!recognized) return false;
    }
    return true;
}

fn attributes(text: ?[]const u8, site: Site, visitor: anytype) @TypeOf(visitor).Error!void {
    if (text) |s| {
        if (!referenceFreeAttributes(s)) try visitor.visit(site, .{ .unknown = .attributes });
    }
}

pub fn walkInstruction(inst: *const ir.Instruction, visitor: anytype) @TypeOf(visitor).Error!void {
    if (inst.removed) return;
    const site: Site = .{ .instruction = inst };
    // The operand API's generic coverage also flags reference-free attributes;
    // inspect those fields below under the explicit module-reference policy.
    _ = try ir.operands.instruction(inst, ValueVisitor(@TypeOf(visitor)){ .site = site, .visitor = visitor });
    try opaqueText(inst.metadata, .metadata, site, visitor);
    switch (inst.kind) {
        .call => |call| {
            if (call.inline_asm != null) {
                try visitor.visit(site, .{ .unknown = .assembly });
            } else if (call.callee_value == null) {
                try visitor.visit(site, .{ .symbol = call.callee });
            }
            for (call.args.items) |arg| try attributes(arg.attrs, site, visitor);
            try attributes(call.attrs, site, visitor);
            try attributes(call.ret_attrs, site, visitor);
            try opaqueText(call.raw_args, .raw_arguments, site, visitor);
            try opaqueText(call.operand_bundle, .operand_bundle, site, visitor);
        },
        .alloca => |alloca| try attributes(alloca.attrs, site, visitor),
        else => {},
    }
}

pub fn walkTerminator(term: *const ir.Terminator, visitor: anytype) @TypeOf(visitor).Error!void {
    const site: Site = .{ .terminator = term };
    _ = try ir.operands.terminator(term, ValueVisitor(@TypeOf(visitor)){ .site = site, .visitor = visitor });
    switch (term.*) {
        .br => |x| try opaqueText(x.metadata, .metadata, site, visitor),
        .condbr => |x| try opaqueText(x.metadata, .metadata, site, visitor),
        .@"switch" => |x| try opaqueText(x.metadata, .metadata, site, visitor),
        .indirectbr => |x| try opaqueText(x.metadata, .metadata, site, visitor),
        .ret, .@"unreachable" => {},
    }
}

/// References that remain even after dead definitions are removed.
pub fn walkModuleScope(module: *const ir.Module, visitor: anytype) @TypeOf(visitor).Error!void {
    for (module.module_asm.items) |_| try visitor.visit(.module, .{ .unknown = .assembly });
    for (module.attribute_groups.items) |text| try opaqueText(text, .attributes, .module, visitor);
    for (module.metadata.items) |text| try opaqueText(text, .metadata, .module, visitor);
    for (module.declarations.items) |*decl| {
        const site: Site = .{ .declaration = decl };
        try attributes(decl.attrs, site, visitor);
        try attributes(decl.ret_attrs, site, visitor);
        for (decl.params.items) |param| try attributes(param.attrs, site, visitor);
    }
}

pub fn walkAlias(alias: *const ir.GlobalAlias, visitor: anytype) @TypeOf(visitor).Error!void {
    try visitor.visit(.{ .alias = alias }, .{ .symbol = alias.target });
}

pub fn walkGlobal(global: *const ir.Global, visitor: anytype) @TypeOf(visitor).Error!void {
    const site: Site = .{ .global = global };
    switch (global.initializer) {
        .none, .c_string => {}, // A parsed byte string is data, not IR syntax.
        .scalar => |value| try valueReference(value, site, visitor),
        .array => |array| for (array.values.items) |value| try valueReference(value, site, visitor),
        .@"opaque" => try visitor.visit(site, .{ .unknown = .initializer }),
    }
    try attributes(global.attrs, site, visitor);
    try attributes(global.address_attrs, site, visitor);
}

pub fn walkFunction(function: *const ir.Function, visitor: anytype) @TypeOf(visitor).Error!void {
    const site: Site = .{ .function = function };
    try attributes(function.attrs, site, visitor);
    try attributes(function.ret_attrs, site, visitor);
    for (function.params.items) |param| try attributes(param.attrs, site, visitor);
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*inst| try walkInstruction(inst, visitor);
        if (block.terminator) |*term| try walkTerminator(term, visitor);
    }
}

pub fn walkModule(module: *const ir.Module, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkModuleScope(module, visitor);
    for (module.aliases.items) |*alias| try walkAlias(alias, visitor);
    for (module.globals.items) |*global| try walkGlobal(global, visitor);
    for (module.functions.items) |*function| try walkFunction(function, visitor);
}

pub const Summary = struct {
    direct_uses: usize = 0,
    has_unknown: bool = false,

    pub fn mayReference(summary: Summary) bool {
        return summary.direct_uses != 0 or summary.has_unknown;
    }
};

const Query = struct {
    pub const Error = error{};
    name: []const u8,
    summary: *Summary,
    pub fn visit(search: Query, _: Site, event: Event) Error!void {
        switch (event) {
            .symbol => |name| if (std.mem.eql(u8, search.name, name)) {
                search.summary.direct_uses += 1;
            },
            .unknown => search.summary.has_unknown = true,
        }
    }
};

/// Known absence means zero direct uses AND no unknown regions. A known use
/// and incomplete coverage can coexist. This is not a transitive alias graph.
pub fn query(module: *const ir.Module, name: []const u8) Summary {
    var summary: Summary = .{};
    walkModule(module, Query{ .name = name, .summary = &summary }) catch unreachable;
    return summary;
}
