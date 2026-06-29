const std = @import("std");

pub const section_name = "zllvm-error-union-call-facts-v1";

pub const CallFact = struct {
    caller: []const u8,
    call_inst: u32,
    callee: []const u8,
    result_type: []const u8,
};

pub const CalleeFact = struct {
    callee: []const u8,
    result_type: []const u8,
    success_arg_index: u32,
    success_arg_eq_i32: i32,
    success_payload_i32: i32,
    error_name: ?[]const u8 = null,
};

pub const Fact = struct {
    caller: []const u8,
    call_inst: u32,
    callee: []const u8,
    result_type: []const u8,
    success_arg_index: u32,
    success_arg_eq_i32: i32,
    success_payload_i32: i32,
    error_name: ?[]const u8 = null,
};

pub const Provider = struct {
    calls: []const CallFact = &.{},
    callees: []const CalleeFact = &.{},

    pub fn lookup(provider: Provider, caller: []const u8, call_inst: u32) ?Fact {
        for (provider.calls) |call| {
            if (call.call_inst != call_inst) continue;
            if (!std.mem.eql(u8, call.caller, caller)) continue;
            const callee = provider.lookupCallee(call.callee) orelse return null;
            if (!std.mem.eql(u8, call.result_type, callee.result_type)) return null;
            return .{
                .caller = call.caller,
                .call_inst = call.call_inst,
                .callee = call.callee,
                .result_type = call.result_type,
                .success_arg_index = callee.success_arg_index,
                .success_arg_eq_i32 = callee.success_arg_eq_i32,
                .success_payload_i32 = callee.success_payload_i32,
                .error_name = callee.error_name,
            };
        }
        return null;
    }

    fn lookupCallee(provider: Provider, callee_name: []const u8) ?CalleeFact {
        for (provider.callees) |callee| {
            if (std.mem.eql(u8, callee.callee, callee_name) or hasShortName(callee.callee, callee_name)) return callee;
        }
        return null;
    }

    pub fn deinit(provider: Provider, allocator: std.mem.Allocator) void {
        for (provider.calls) |call| {
            allocator.free(call.caller);
            allocator.free(call.callee);
            allocator.free(call.result_type);
        }
        for (provider.callees) |callee| {
            allocator.free(callee.callee);
            allocator.free(callee.result_type);
            if (callee.error_name) |error_name| allocator.free(error_name);
        }
        allocator.free(provider.calls);
        allocator.free(provider.callees);
    }
};

pub const empty_provider: Provider = .{};

pub fn parseSidecar(allocator: std.mem.Allocator, contents: []const u8) !Provider {
    var calls: std.ArrayList(CallFact) = .empty;
    var callees: std.ArrayList(CalleeFact) = .empty;
    errdefer {
        for (calls.items) |call| {
            allocator.free(call.caller);
            allocator.free(call.callee);
            allocator.free(call.result_type);
        }
        for (callees.items) |callee| {
            allocator.free(callee.callee);
            allocator.free(callee.result_type);
            if (callee.error_name) |error_name| allocator.free(error_name);
        }
        calls.deinit(allocator);
        callees.deinit(allocator);
    }

    var saw_header = false;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        if (!saw_header) {
            if (!std.mem.eql(u8, line, section_name)) return error.InvalidErrorUnionCallFactSidecar;
            saw_header = true;
            continue;
        }
        if (std.mem.startsWith(u8, line, "call ")) {
            const caller = extractQuotedField(line, "caller=") orelse return error.InvalidErrorUnionCallFactSidecar;
            const callee = extractQuotedField(line, "callee=") orelse return error.InvalidErrorUnionCallFactSidecar;
            const result_type = extractQuotedField(line, "result=") orelse return error.InvalidErrorUnionCallFactSidecar;
            try calls.append(allocator, .{
                .caller = try allocator.dupe(u8, caller),
                .call_inst = try parseU32Field(line, "call_inst="),
                .callee = try allocator.dupe(u8, callee),
                .result_type = try allocator.dupe(u8, result_type),
            });
        } else if (std.mem.startsWith(u8, line, "callee ")) {
            const callee = extractQuotedField(line, "callee=") orelse return error.InvalidErrorUnionCallFactSidecar;
            const result_type = extractQuotedField(line, "result=") orelse return error.InvalidErrorUnionCallFactSidecar;
            const error_name = extractQuotedField(line, "error=");
            try callees.append(allocator, .{
                .callee = try allocator.dupe(u8, callee),
                .result_type = try allocator.dupe(u8, result_type),
                .success_arg_index = try parseU32Field(line, "success_arg_index="),
                .success_arg_eq_i32 = try parseI32Field(line, "success_arg_eq_i32="),
                .success_payload_i32 = try parseI32Field(line, "success_payload_i32="),
                .error_name = if (error_name) |name| try allocator.dupe(u8, name) else null,
            });
        } else return error.InvalidErrorUnionCallFactSidecar;
    }
    if (!saw_header) return error.InvalidErrorUnionCallFactSidecar;
    return .{
        .calls = try calls.toOwnedSlice(allocator),
        .callees = try callees.toOwnedSlice(allocator),
    };
}

fn extractQuotedField(line: []const u8, marker: []const u8) ?[]const u8 {
    const marker_index = std.mem.indexOf(u8, line, marker) orelse return null;
    const after_marker = line[marker_index + marker.len ..];
    if (after_marker.len == 0 or after_marker[0] != '"') return null;
    const after_quote = after_marker[1..];
    const quote_end = std.mem.indexOfScalar(u8, after_quote, '"') orelse return null;
    return after_quote[0..quote_end];
}

fn parseU32Field(line: []const u8, marker: []const u8) !u32 {
    return std.fmt.parseInt(u32, scalarField(line, marker) orelse return error.InvalidErrorUnionCallFactSidecar, 10) catch
        error.InvalidErrorUnionCallFactSidecar;
}

fn parseI32Field(line: []const u8, marker: []const u8) !i32 {
    return std.fmt.parseInt(i32, scalarField(line, marker) orelse return error.InvalidErrorUnionCallFactSidecar, 10) catch
        error.InvalidErrorUnionCallFactSidecar;
}

fn scalarField(line: []const u8, marker: []const u8) ?[]const u8 {
    const marker_index = std.mem.indexOf(u8, line, marker) orelse return null;
    const value = line[marker_index + marker.len ..];
    const end = std.mem.indexOfScalar(u8, value, ' ') orelse value.len;
    return value[0..end];
}

fn hasShortName(fqn: []const u8, short_name: []const u8) bool {
    if (fqn.len <= short_name.len) return false;
    if (!std.mem.endsWith(u8, fqn, short_name)) return false;
    return fqn[fqn.len - short_name.len - 1] == '.';
}

test "error-union call facts parse sidecar contract" {
    const contents =
        section_name ++ "\n" ++
        "callee callee=\"aggregates.maybeError\" result=\"error{Bad}!i32\" success_arg_index=0 success_arg_eq_i32=0 success_payload_i32=7 error=\"Bad\"\n" ++
        "call caller=\"aggregates.error_union_payload\" call_inst=4 callee=\"maybeError\" result=\"error{Bad}!i32\"\n";
    const provider = try parseSidecar(std.testing.allocator, contents);
    defer provider.deinit(std.testing.allocator);
    const fact = provider.lookup("aggregates.error_union_payload", 4).?;
    try std.testing.expectEqualStrings("maybeError", fact.callee);
    try std.testing.expectEqual(@as(i32, 7), fact.success_payload_i32);
    try std.testing.expectEqualStrings("Bad", fact.error_name.?);
}

test "error-union call facts reject missing header" {
    try std.testing.expectError(
        error.InvalidErrorUnionCallFactSidecar,
        parseSidecar(std.testing.allocator, "fact caller=\"x\"\n"),
    );
}
