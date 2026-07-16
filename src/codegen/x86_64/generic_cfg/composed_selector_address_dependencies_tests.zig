const std = @import("std");
const x86_64_machine = @import("../machine.zig");
const address_dependencies = @import("composed_selector_address_dependencies.zig");
const state_data = @import("composed_selector_state_data.zig");
const selector_state = @import("composed_selector_state.zig");
const stage2_planning = @import("stage2_planning.zig");

const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const MachineFunction = x86_64_machine.MachineFunction;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;

const TypedIdentity = struct {
    name: []const u8,
    identity_type: AddressDependencyDomain.IdentityType,
};

const TestLiveness = struct {
    live_owners: []const []const u8,
    identities: []const TypedIdentity,

    pub fn validateOwner(context: TestLiveness, owner: AddressDependencyDomain.OwnerView) !void {
        try context.requireIdentity(owner.name, owner.identity_type);
    }

    pub fn isOwnerLive(context: TestLiveness, owner_name: []const u8) !bool {
        for (context.live_owners) |live_name| {
            if (std.mem.eql(u8, live_name, owner_name)) return true;
        }
        return false;
    }

    pub fn validateDependency(context: TestLiveness, dependency: AddressDependencyDomain.DependencyView) !void {
        try context.requireIdentity(dependency.name, dependency.identity_type);
    }

    fn requireIdentity(context: TestLiveness, name: []const u8, identity_type: AddressDependencyDomain.IdentityType) !void {
        for (context.identities) |identity| {
            if (!std.mem.eql(u8, identity.name, name)) continue;
            if (identity.identity_type != identity_type) return error.TestIdentityTypeMismatch;
            return;
        }
        return error.TestMissingIdentity;
    }
};

test "generic cfg selector address dependency domain extends base index addend and transitive liveness in owner direction" {
    var domain: AddressDependencyDomain = .{};
    try domain.replaceAddress("derived", &.{
        .{ .name = "base-address", .identity_type = .address, .role = .base },
        .{ .name = "index", .identity_type = .integer, .role = .index },
        .{ .name = "addend", .identity_type = .integer, .role = .addend },
    });
    try domain.replaceAddress("base-address", &.{
        .{ .name = "root-pointer", .identity_type = .pointer, .role = .base },
    });
    const identities = [_]TypedIdentity{
        .{ .name = "derived", .identity_type = .address },
        .{ .name = "base-address", .identity_type = .address },
        .{ .name = "index", .identity_type = .integer },
        .{ .name = "addend", .identity_type = .integer },
        .{ .name = "root-pointer", .identity_type = .pointer },
    };
    const live = [_][]const u8{"derived"};
    const context = TestLiveness{ .live_owners = &live, .identities = &identities };

    try std.testing.expect(try domain.dependencyIsRequired("base-address", context));
    try std.testing.expect(try domain.dependencyIsRequired("index", context));
    try std.testing.expect(try domain.dependencyIsRequired("addend", context));
    try std.testing.expect(try domain.dependencyIsRequired("root-pointer", context));
    try std.testing.expect(!try domain.dependencyIsRequired("derived", context));
}

test "generic cfg selector address dependency domain fails closed for missing identities cycles and invalid roles" {
    var missing: AddressDependencyDomain = .{};
    try missing.replaceAddress("owner", &.{
        .{ .name = "missing", .identity_type = .integer, .role = .index },
    });
    const owner_only = [_]TypedIdentity{
        .{ .name = "owner", .identity_type = .address },
    };
    const live = [_][]const u8{"owner"};
    try std.testing.expectError(error.TestMissingIdentity, missing.dependencyIsRequired(
        "missing",
        TestLiveness{ .live_owners = &live, .identities = &owner_only },
    ));

    var cyclic: AddressDependencyDomain = .{};
    try cyclic.replaceAddress("first", &.{
        .{ .name = "second", .identity_type = .address, .role = .base },
    });
    const before_cycle = cyclic;
    try std.testing.expectError(error.AddressDependencyCycle, cyclic.replaceAddress("second", &.{
        .{ .name = "first", .identity_type = .address, .role = .base },
    }));
    try std.testing.expect(cyclic.eql(&before_cycle));

    var invalid: AddressDependencyDomain = .{};
    try std.testing.expectError(error.AddressDependencyInvalidRoleType, invalid.replaceAddress("bad", &.{
        .{ .name = "integer-base", .identity_type = .integer, .role = .base },
    }));
}

test "generic cfg selector address dependency domain releases dead owners and separates shared dependencies" {
    var domain: AddressDependencyDomain = .{};
    try domain.replaceAddress("first", &.{
        .{ .name = "shared", .identity_type = .integer, .role = .index },
    });
    try domain.replaceAddress("second", &.{
        .{ .name = "shared", .identity_type = .integer, .role = .index },
    });
    const identities = [_]TypedIdentity{
        .{ .name = "first", .identity_type = .address },
        .{ .name = "second", .identity_type = .address },
        .{ .name = "shared", .identity_type = .integer },
    };
    const both_live = [_][]const u8{ "first", "second" };
    try std.testing.expect(try domain.dependencyIsRequired(
        "shared",
        TestLiveness{ .live_owners = &both_live, .identities = &identities },
    ));

    domain.removeOwner("first");
    const second_live = [_][]const u8{"second"};
    try std.testing.expect(try domain.dependencyIsRequired(
        "shared",
        TestLiveness{ .live_owners = &second_live, .identities = &identities },
    ));

    const none_live = [_][]const u8{};
    try std.testing.expect(!try domain.dependencyIsRequired(
        "shared",
        TestLiveness{ .live_owners = &none_live, .identities = &identities },
    ));
    domain.removeOwner("second");
    try std.testing.expectEqual(@as(usize, 0), domain.count());
}

test "generic cfg selector address dependency domain rebind and failed replacement are atomic" {
    var domain: AddressDependencyDomain = .{};
    try domain.replaceAddress("owner", &.{
        .{ .name = "old-index", .identity_type = .integer, .role = .index },
    });
    try domain.replaceAddress("owner", &.{
        .{ .name = "new-index", .identity_type = .integer, .role = .index },
    });
    const identities = [_]TypedIdentity{
        .{ .name = "owner", .identity_type = .address },
        .{ .name = "old-index", .identity_type = .integer },
        .{ .name = "new-index", .identity_type = .integer },
    };
    const live = [_][]const u8{"owner"};
    const context = TestLiveness{ .live_owners = &live, .identities = &identities };
    try std.testing.expect(!try domain.dependencyIsRequired("old-index", context));
    try std.testing.expect(try domain.dependencyIsRequired("new-index", context));

    const before_failure = domain;
    try std.testing.expectError(error.AddressDependencyDuplicateRole, domain.replaceAddress("owner", &.{
        .{ .name = "one", .identity_type = .integer, .role = .index },
        .{ .name = "two", .identity_type = .integer, .role = .index },
    }));
    try std.testing.expect(domain.eql(&before_failure));
}

test "generic cfg selector address dependency domain fixed capacity and stable inline identity lifetime fail closed" {
    var domain: AddressDependencyDomain = .{};
    var owner_buffer = [_]u8{ 'o', 'w', 'n', 'e', 'r' };
    var dependency_buffer = [_]u8{ 'i', 'n', 'd', 'e', 'x' };
    try domain.replaceAddress(&owner_buffer, &.{
        .{ .name = &dependency_buffer, .identity_type = .integer, .role = .index },
    });
    @memset(&owner_buffer, 'x');
    @memset(&dependency_buffer, 'y');
    const stable = domain.ownerNamed("owner").?;
    try std.testing.expectEqualStrings("owner", stable.name);
    try std.testing.expectEqualStrings("index", stable.dependencySlice()[0].name);

    var full: AddressDependencyDomain = .{};
    var name_buffer: [32]u8 = undefined;
    for (0..AddressDependencyDomain.max_owners) |index| {
        const name = try std.fmt.bufPrint(&name_buffer, "owner-{d}", .{index});
        try full.replaceAddress(name, &.{
            .{ .name = "shared", .identity_type = .integer, .role = .index },
        });
    }
    const before_overflow = full;
    try std.testing.expectError(error.AddressDependencyDomainCapacityExceeded, full.replaceAddress("overflow", &.{
        .{ .name = "shared", .identity_type = .integer, .role = .index },
    }));
    try std.testing.expect(full.eql(&before_overflow));
}

test "generic cfg selector address dependency authority migrates stack pointer liveness and rolls back exactly" {
    var machine = MachineFunction.init("address-dependency-state", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("index", 1);
    try plan.interval_ends.put("addend", 1);
    try plan.interval_ends.put("pointer", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 5;
    try selector_state.bindValueLoc(&selector, "index", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "addend", .{ .scratch64 = .r9 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 4,
        .index = .{ .reg = .r8, .name = "index", .addend_name = "addend" },
    } });
    try std.testing.expect(try selector_state.valueIsLiveAfterCurrent(&selector, "index"));
    try std.testing.expect(try selector_state.valueIsLiveAfterCurrent(&selector, "addend"));

    const saved_domain = selector.address_dependencies;
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
    _ = selector_state.removeValueBinding(&selector, "pointer");
    try std.testing.expectEqual(@as(usize, 0), selector.address_dependencies.count());
    try transaction.rollback();
    try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
    try std.testing.expect(selector_state.valueLoc(&selector, "pointer") != null);
    transaction.deinit();

    _ = selector_state.removeValueBinding(&selector, "pointer");
    try std.testing.expect(!try selector_state.valueIsLiveAfterCurrent(&selector, "index"));
}

test "generic cfg selector address dependency liveness fails closed for missing binding plan entry and stale edge" {
    var machine = MachineFunction.init("address-dependency-malformed", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("index", 1);
    try plan.interval_ends.put("pointer", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 5;
    try selector_state.bindValueLoc(&selector, "index", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 4,
        .index = .{ .reg = .r8, .name = "index" },
    } });

    const index_binding = selector.values.get("index").?;
    _ = selector.values.remove("index");
    try std.testing.expectError(error.AddressDependencyMissingBinding, selector_state.valueIsLiveAfterCurrent(&selector, "index"));
    try selector.values.put("index", index_binding);

    _ = plan.interval_ends.remove("index");
    try std.testing.expectError(error.AddressDependencyMissingPlanEntry, selector_state.valueIsLiveAfterCurrent(&selector, "index"));
    try plan.interval_ends.put("index", 1);

    const pointer_binding = selector.values.get("pointer").?;
    _ = selector.values.remove("pointer");
    try std.testing.expectError(error.AddressDependencyMissingOwnerBinding, selector_state.valueIsLiveAfterCurrent(&selector, "index"));
    try selector.values.put("pointer", pointer_binding);

    try selector.values.put("pointer", .{ .vreg = pointer_binding.vreg, .loc = .{ .stack_i32_ptr = .{ .disp = 4 } } });
    try std.testing.expectError(error.AddressDependencyStaleEdge, selector_state.valueIsLiveAfterCurrent(&selector, "index"));
}
