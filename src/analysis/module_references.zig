//! Read-only enumeration of module symbol uses. Value.named beginning with @
//! is global; bare names are local SSA names. Alias targets and direct callees
//! are symbols by their field's contract. Definition names and CFG labels are
//! not uses. Removed instructions and replacement bookkeeping are skipped.
//!
//! Bounded attribute, metadata and constant grammars establish coverage only
//! with a module context. Unsupported regions report unknown references, never
//! absence inferred from a substring search. Standalone walks stay conservative.
//! Visitors declare Error and visit(site, event); borrowed pointers/text remain
//! valid only while the source module and its storage remain unchanged.
const std = @import("std");
const ir = @import("../ir.zig");
const opaque_names = @import("../ir/opaque_names.zig");
const reference_attributes = @import("reference_attributes.zig");
const reference_metadata = @import("reference_metadata.zig");
const reference_constants = @import("reference_constants.zig");
const Cursor = @import("reference_syntax.zig").Cursor;

/// Borrow one module while owning lookup/reference storage. Attribute and
/// metadata records must remain unchanged during this context's lifetime.
/// Scoped walks validate metadata IDs; their retained definition references
/// are emitted by walkModuleScope. Consumers must include that scope too.
pub const Context = struct {
    module: *const ir.Module,
    groups: reference_attributes.Groups,
    metadata: reference_metadata.Index,

    pub fn init(allocator: std.mem.Allocator, module: *const ir.Module) !Context {
        var groups = try reference_attributes.Groups.init(allocator, module.attribute_groups.items);
        errdefer groups.deinit();
        return .{ .module = module, .groups = groups, .metadata = try reference_metadata.Index.init(allocator, module.metadata.items) };
    }

    pub fn deinit(context: *Context) void {
        context.groups.deinit();
        context.metadata.deinit();
    }

    pub fn walkModule(context: *const Context, visitor: anytype) @TypeOf(visitor).Error!void {
        try walkModuleWithContext(context.module, context, visitor);
    }

    pub fn walkModuleScope(context: *const Context, visitor: anytype) @TypeOf(visitor).Error!void {
        try walkModuleScopeWithContext(context.module, context, visitor);
    }

    pub fn walkFunction(context: *const Context, function: *const ir.Function, visitor: anytype) @TypeOf(visitor).Error!void {
        try walkFunctionWithContext(function, context, visitor);
    }

    pub fn walkGlobal(context: *const Context, global: *const ir.Global, visitor: anytype) @TypeOf(visitor).Error!void {
        try walkGlobalWithContext(global, context, visitor);
    }

    pub fn query(context: *const Context, name: []const u8) Summary {
        var summary: Summary = .{ .has_unknown = !ir.identifiers.isValid(name) };
        context.walkModule(Query{ .name = name, .summary = &summary }) catch unreachable;
        return summary;
    }

    pub fn hasUnknown(context: *const Context) bool {
        var summary: Summary = .{};
        context.walkModule(Query{ .name = "", .summary = &summary }) catch unreachable;
        return summary.has_unknown;
    }
};

pub const Site = union(enum) {
    module,
    global: *const ir.Global,
    alias: *const ir.GlobalAlias,
    function: *const ir.Function,
    declaration: *const ir.FunctionDecl,
    instruction: *const ir.Instruction,
    terminator: *const ir.Terminator,
};

pub const OpaqueKind = enum { value, initializer, assembly, metadata, attributes, raw_arguments, operand_bundle, block_address, symbol_name };
pub const Event = union(enum) {
    /// Module symbol spelling without @, as stored in definition names.
    symbol: []const u8,
    /// Positive evidence only; its containing opaque region remains unknown.
    block_address: opaque_names.BlockAddress,
    unknown: OpaqueKind,
};

pub fn isDirectValue(value: ir.Value, name: []const u8) bool {
    return value == .named and value.named.len > 1 and value.named[0] == '@' and ir.identifiers.eql(value.named[1..], name);
}

fn symbolReference(name: []const u8, site: Site, visitor: anytype) @TypeOf(visitor).Error!void {
    if (ir.identifiers.isValid(name)) {
        try visitor.visit(site, .{ .symbol = name });
    } else {
        try visitor.visit(site, .{ .unknown = .symbol_name });
    }
}

fn valueReference(value: ir.Value, ty: ir.Type, site: Site, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    switch (value) {
        .named => |name| {
            if (name.len != 0 and name[0] == '@') {
                try symbolReference(name[1..], site, visitor);
            } else if (name.len != 0 and name[0] == '!') {
                if (context) |ctx| {
                    if (try ctx.metadata.value(name, TextVisitor(@TypeOf(visitor)){ .site = .module, .visitor = visitor })) return;
                }
                try opaqueText(name, .metadata, site, visitor);
            }
        },
        .vector => |raw| try constantText(raw, ty, .value, site, context, visitor),
        .constant_expr => |raw| try constantText(raw, ty, .value, site, context, visitor),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => {},
    }
}

fn ValueVisitor(comptime Visitor: type) type {
    return struct {
        pub const Error = Visitor.Error;
        visitor: Visitor,
        site: Site,
        context: ?*const Context,
        pub fn visit(walker: @This(), value: *const ir.Value, ty: ir.Type) Error!void {
            try valueReference(value.*, ty, walker.site, walker.context, walker.visitor);
        }
    };
}

fn TextVisitor(comptime Visitor: type) type {
    return struct {
        pub const Error = Visitor.Error;
        visitor: Visitor,
        site: Site,
        pub fn symbol(walker: @This(), name: []const u8) Error!void {
            try symbolReference(name, walker.site, walker.visitor);
        }
    };
}

fn constantText(text: []const u8, ty: ir.Type, kind: OpaqueKind, site: Site, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    if (context != null and try reference_constants.value(text, ty, TextVisitor(@TypeOf(visitor)){ .site = site, .visitor = visitor })) return;
    try opaqueText(text, kind, site, visitor);
}

fn opaqueText(text: ?[]const u8, kind: OpaqueKind, site: Site, visitor: anytype) @TypeOf(visitor).Error!void {
    if (text) |s| {
        if (s.len != 0) {
            try visitor.visit(site, .{ .unknown = kind });
            var tokens: opaque_names.Iterator = .{ .raw = s };
            while (tokens.next() catch {
                try visitor.visit(site, .{ .unknown = .block_address });
                return;
            }) |token| switch (token) {
                .local => {},
                .block_address => |address| try visitor.visit(site, .{ .block_address = address }),
            };
        }
    }
}

fn attributes(text: ?[]const u8, site: Site, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    if (text) |s| {
        const groups = if (context) |ctx| &ctx.groups else null;
        var cursor: Cursor = .{ .text = s };
        while (!cursor.done()) {
            const complete = if (cursor.peek() == '!') blk: {
                const ctx = context orelse break :blk false;
                // A metadata use on a load is not another direct load use.
                break :blk try ctx.metadata.attachment(&cursor, TextVisitor(@TypeOf(visitor)){ .site = .module, .visitor = visitor });
            } else reference_attributes.takeOne(&cursor, groups);
            if (!complete or (cursor.take(',') and cursor.done())) {
                try opaqueText(s, .attributes, site, visitor);
                return;
            }
        }
    }
}

fn metadataText(text: ?[]const u8, site: Site, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    if (text) |s| {
        if (context) |ctx| {
            var cursor: Cursor = .{ .text = s };
            var complete = true;
            while (!cursor.done()) {
                if (!try ctx.metadata.attachment(&cursor, TextVisitor(@TypeOf(visitor)){ .site = .module, .visitor = visitor })) {
                    complete = false;
                    break;
                }
                if (cursor.done()) break;
                if (!cursor.take(',') or cursor.done()) {
                    complete = false;
                    break;
                }
            }
            if (complete) return;
        }
        try opaqueText(s, .metadata, site, visitor);
    }
}

pub fn walkInstruction(inst: *const ir.Instruction, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkInstructionWithContext(inst, null, visitor);
}

fn walkInstructionWithContext(inst: *const ir.Instruction, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    if (inst.removed) return;
    const site: Site = .{ .instruction = inst };
    // The operand API's generic coverage also flags reference-free attributes;
    // inspect those fields below under the explicit module-reference policy.
    _ = try ir.operands.instruction(inst, ValueVisitor(@TypeOf(visitor)){ .site = site, .visitor = visitor, .context = context });
    try metadataText(inst.metadata, site, context, visitor);
    switch (inst.kind) {
        .call => |call| {
            if (call.inline_asm != null) {
                try visitor.visit(site, .{ .unknown = .assembly });
            } else if (call.callee_value == null) {
                try symbolReference(call.callee, site, visitor);
            }
            for (call.args.items) |arg| try attributes(arg.attrs, site, context, visitor);
            try attributes(call.attrs, site, context, visitor);
            try attributes(call.ret_attrs, site, context, visitor);
            try opaqueText(call.raw_args, .raw_arguments, site, visitor);
            try opaqueText(call.operand_bundle, .operand_bundle, site, visitor);
        },
        .alloca => |alloca| try attributes(alloca.attrs, site, context, visitor),
        else => {},
    }
}

pub fn walkTerminator(term: *const ir.Terminator, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkTerminatorWithContext(term, null, visitor);
}

fn walkTerminatorWithContext(term: *const ir.Terminator, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    const site: Site = .{ .terminator = term };
    _ = try ir.operands.terminator(term, ValueVisitor(@TypeOf(visitor)){ .site = site, .visitor = visitor, .context = context });
    switch (term.*) {
        .br => |x| try metadataText(x.metadata, site, context, visitor),
        .condbr => |x| try metadataText(x.metadata, site, context, visitor),
        .@"switch" => |x| try metadataText(x.metadata, site, context, visitor),
        .indirectbr => |x| try metadataText(x.metadata, site, context, visitor),
        .ret, .@"unreachable" => {},
    }
}

/// References that remain even after dead definitions are removed.
pub fn walkModuleScope(module: *const ir.Module, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkModuleScopeWithContext(module, null, visitor);
}

fn walkModuleScopeWithContext(module: *const ir.Module, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    for (module.module_asm.items) |_| try visitor.visit(.module, .{ .unknown = .assembly });
    if (context == null or context.?.groups.has_unknown) {
        // A malformed record can be empty in constructed IR. Coverage must
        // remain unknown even when there is no text for the positive walker.
        if (module.attribute_groups.items.len != 0) try visitor.visit(.module, .{ .unknown = .attributes });
        for (module.attribute_groups.items) |text| try opaqueText(text, .attributes, .module, visitor);
    }
    if (context) |ctx| {
        if (ctx.metadata.has_unknown) {
            try visitor.visit(.module, .{ .unknown = .metadata });
            for (module.metadata.items) |text| try opaqueText(text, .metadata, .module, visitor);
        }
        for (ctx.metadata.symbols.items) |name| try symbolReference(name, .module, visitor);
    } else {
        if (module.metadata.items.len != 0) try visitor.visit(.module, .{ .unknown = .metadata });
        for (module.metadata.items) |text| try opaqueText(text, .metadata, .module, visitor);
    }
    for (module.declarations.items) |*decl| {
        const site: Site = .{ .declaration = decl };
        if (!ir.identifiers.isValid(decl.name)) try visitor.visit(site, .{ .unknown = .symbol_name });
        try attributes(decl.attrs, site, context, visitor);
        try attributes(decl.ret_attrs, site, context, visitor);
        for (decl.params.items) |param| try attributes(param.attrs, site, context, visitor);
    }
}

pub fn walkAlias(alias: *const ir.GlobalAlias, visitor: anytype) @TypeOf(visitor).Error!void {
    const site: Site = .{ .alias = alias };
    if (!ir.identifiers.isValid(alias.name)) try visitor.visit(site, .{ .unknown = .symbol_name });
    try symbolReference(alias.target, site, visitor);
}

pub fn walkGlobal(global: *const ir.Global, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkGlobalWithContext(global, null, visitor);
}

fn walkGlobalWithContext(global: *const ir.Global, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    const site: Site = .{ .global = global };
    if (!ir.identifiers.isValid(global.name)) try visitor.visit(site, .{ .unknown = .symbol_name });
    switch (global.initializer) {
        .none, .c_string => {}, // A parsed byte string is data, not IR syntax.
        .scalar => |value| try valueReference(value, global.ty, site, context, visitor),
        .array => |array| for (array.values.items) |value| try valueReference(value, array.elem_ty, site, context, visitor),
        .@"opaque" => |raw| try constantText(raw, global.ty, .initializer, site, context, visitor),
    }
    try attributes(global.attrs, site, context, visitor);
    try attributes(global.address_attrs, site, context, visitor);
}

pub fn walkFunction(function: *const ir.Function, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkFunctionWithContext(function, null, visitor);
}

fn walkFunctionWithContext(function: *const ir.Function, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    const site: Site = .{ .function = function };
    if (!ir.identifiers.isValid(function.name)) try visitor.visit(site, .{ .unknown = .symbol_name });
    try attributes(function.attrs, site, context, visitor);
    try attributes(function.ret_attrs, site, context, visitor);
    for (function.params.items) |param| try attributes(param.attrs, site, context, visitor);
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*inst| try walkInstructionWithContext(inst, context, visitor);
        if (block.terminator) |*term| try walkTerminatorWithContext(term, context, visitor);
    }
}

pub fn walkModule(module: *const ir.Module, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkModuleWithContext(module, null, visitor);
}

fn walkModuleWithContext(module: *const ir.Module, context: ?*const Context, visitor: anytype) @TypeOf(visitor).Error!void {
    try walkModuleScopeWithContext(module, context, visitor);
    for (module.aliases.items) |*alias| try walkAlias(alias, visitor);
    for (module.globals.items) |*global| try walkGlobalWithContext(global, context, visitor);
    for (module.functions.items) |*function| try walkFunctionWithContext(function, context, visitor);
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
            .symbol => |name| if (ir.identifiers.eql(search.name, name)) {
                search.summary.direct_uses += 1;
            },
            .unknown => search.summary.has_unknown = true,
            .block_address => |address| if (ir.identifiers.eql(search.name, address.function)) {
                search.summary.direct_uses += 1;
            },
        }
    }
};

/// Known absence means zero direct uses AND no unknown regions. A known use
/// and incomplete coverage can coexist. This is not a transitive alias graph.
pub fn query(module: *const ir.Module, name: []const u8) Summary {
    var summary: Summary = .{ .has_unknown = !ir.identifiers.isValid(name) };
    walkModule(module, Query{ .name = name, .summary = &summary }) catch unreachable;
    return summary;
}

/// Whether any reference region is incomplete, without querying a symbol.
pub fn hasUnknown(module: *const ir.Module) bool {
    var summary: Summary = .{};
    walkModule(module, Query{ .name = "", .summary = &summary }) catch unreachable;
    return summary.has_unknown;
}
