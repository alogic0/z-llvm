const std = @import("std");

/// Canonical typed dependency graph for derived addresses.
///
/// Identities are copied into fixed inline storage. They never borrow parser,
/// map-key, or temporary caller memory, and a copied domain owns an independent
/// copy of every name. Views borrow the particular domain and remain valid until
/// that domain is next mutated; callers must not retain a view across mutation.
/// The explicit limits are deliberately fail-closed rather than allocating or
/// truncating metadata during selection.
pub const AddressDependencyDomain = struct {
    // The frozen O2 capture contains at most 156 static derived-address sites in
    // one function. Keep bounded inline storage with explicit review headroom.
    pub const max_owners = 192;
    pub const max_dependencies_per_owner = 3;
    pub const max_identity_bytes = 192;

    owners: [max_owners]Owner = undefined,
    owner_count: u8 = 0,

    pub const IdentityType = enum {
        address,
        pointer,
        integer,
        frame_object,
    };

    pub const Role = enum {
        base,
        index,
        addend,
    };

    pub const DependencySpec = struct {
        name: []const u8,
        identity_type: IdentityType,
        role: Role,
    };

    pub const DependencyView = struct {
        name: []const u8,
        identity_type: IdentityType,
        role: Role,
    };

    pub const OwnerView = struct {
        name: []const u8,
        identity_type: IdentityType,
        dependencies: [max_dependencies_per_owner]DependencyView = undefined,
        dependency_count: u8 = 0,

        pub fn dependencySlice(owner: *const OwnerView) []const DependencyView {
            return owner.dependencies[0..owner.dependency_count];
        }
    };

    const Identity = struct {
        bytes: [max_identity_bytes]u8 = undefined,
        len: u8 = 0,

        fn init(name: []const u8) !Identity {
            if (name.len == 0) return error.AddressDependencyEmptyIdentity;
            if (name.len > max_identity_bytes) return error.AddressDependencyIdentityTooLong;
            var identity: Identity = .{};
            @memcpy(identity.bytes[0..name.len], name);
            identity.len = @intCast(name.len);
            return identity;
        }

        fn slice(identity: *const Identity) []const u8 {
            return identity.bytes[0..identity.len];
        }

        fn eql(identity: *const Identity, name: []const u8) bool {
            return std.mem.eql(u8, identity.slice(), name);
        }

        fn eqlIdentity(identity: *const Identity, other: *const Identity) bool {
            return identity.eql(other.slice());
        }
    };

    const Dependency = struct {
        identity: Identity,
        identity_type: IdentityType,
        role: Role,
    };

    const Owner = struct {
        identity: Identity,
        identity_type: IdentityType,
        dependencies: [max_dependencies_per_owner]Dependency = undefined,
        dependency_count: u8 = 0,
    };

    pub fn replaceAddress(
        domain: *AddressDependencyDomain,
        owner_name: []const u8,
        dependencies: []const DependencySpec,
    ) !void {
        if (dependencies.len > max_dependencies_per_owner)
            return error.AddressDependencyOwnerCapacityExceeded;

        if (dependencies.len == 0) {
            domain.removeOwner(owner_name);
            return;
        }

        var next = domain.*;
        const owner_index = next.ownerIndex(owner_name) orelse blk: {
            if (next.owner_count == max_owners) return error.AddressDependencyDomainCapacityExceeded;
            const index = next.owner_count;
            next.owner_count += 1;
            break :blk index;
        };
        var owner = Owner{
            .identity = try Identity.init(owner_name),
            .identity_type = .address,
        };
        for (dependencies, 0..) |dependency, index| {
            owner.dependencies[index] = .{
                .identity = try Identity.init(dependency.name),
                .identity_type = dependency.identity_type,
                .role = dependency.role,
            };
            owner.dependency_count += 1;
        }
        next.owners[owner_index] = owner;
        try next.validate();
        domain.* = next;
    }

    pub fn removeOwner(domain: *AddressDependencyDomain, owner_name: []const u8) void {
        // Removal cannot fail. Resolve the borrowed name before compacting the
        // owned records; a speculative copy only adds full-domain traffic to
        // every binding write, including the common absent-owner case.
        domain.removeOwnerInPlace(owner_name);
    }

    pub fn count(domain: *const AddressDependencyDomain) usize {
        return domain.owner_count;
    }

    pub fn ownerAt(domain: *const AddressDependencyDomain, index: usize) ?OwnerView {
        if (index >= domain.owner_count) return null;
        return ownerView(&domain.owners[index]);
    }

    pub fn ownerNamed(domain: *const AddressDependencyDomain, name: []const u8) ?OwnerView {
        const index = domain.ownerIndex(name) orelse return null;
        return ownerView(&domain.owners[index]);
    }

    pub fn validate(domain: *const AddressDependencyDomain) !void {
        for (domain.owners[0..domain.owner_count], 0..) |*owner, owner_index| {
            if (owner.identity_type != .address) return error.AddressDependencyInvalidOwnerType;
            var seen_roles: [@typeInfo(Role).@"enum".field_names.len]bool = @splat(false);
            for (owner.dependencies[0..owner.dependency_count], 0..) |*dependency, dependency_index| {
                if (owner.identity.eqlIdentity(&dependency.identity)) return error.AddressDependencyCycle;
                const role_index = @backingInt(dependency.role);
                if (seen_roles[role_index]) return error.AddressDependencyDuplicateRole;
                seen_roles[role_index] = true;
                switch (dependency.role) {
                    .base => switch (dependency.identity_type) {
                        .address, .pointer, .frame_object => {},
                        .integer => return error.AddressDependencyInvalidRoleType,
                    },
                    .index, .addend => if (dependency.identity_type != .integer)
                        return error.AddressDependencyInvalidRoleType,
                }
                try domain.validateIdentityType(dependency.identity.slice(), dependency.identity_type);
                for (owner.dependencies[dependency_index + 1 .. owner.dependency_count]) |*other| {
                    if (dependency.identity.eqlIdentity(&other.identity))
                        return error.AddressDependencyDuplicateIdentity;
                }
            }
            for (domain.owners[owner_index + 1 .. domain.owner_count]) |*other| {
                if (owner.identity.eqlIdentity(&other.identity))
                    return error.AddressDependencyDuplicateOwner;
            }
        }

        var states: [max_owners]VisitState = @splat(.unseen);
        for (domain.owners[0..domain.owner_count], 0..) |_, index| {
            try domain.validateAcyclic(index, &states);
        }
    }

    /// Returns whether `name` is in the transitive dependency closure of any
    /// directly-live owner. Edges are traversed owner -> dependency only: a
    /// live dependency never revives an owner that does not reach it.
    pub fn dependencyIsRequired(
        domain: *const AddressDependencyDomain,
        name: []const u8,
        live_context: anytype,
    ) !bool {
        try domain.validate();
        for (domain.owners[0..domain.owner_count], 0..) |*owner, index| {
            if (!try live_context.isOwnerLive(owner.identity.slice())) continue;
            try live_context.validateOwner(ownerView(owner));
            var visited: [max_owners]bool = @splat(false);
            if (try domain.ownerRequires(index, name, &visited, live_context)) return true;
        }
        return false;
    }

    /// Validates the canonical dependency closure for `owner_name` when that
    /// identity is a registered derived-address owner. Non-owner identities
    /// have no outgoing edges and therefore require no owner-closure work.
    pub fn validateOwnerClosure(
        domain: *const AddressDependencyDomain,
        owner_name: []const u8,
        live_context: anytype,
    ) !void {
        try domain.validate();
        const owner_index = domain.ownerIndex(owner_name) orelse return;
        var visited: [max_owners]bool = @splat(false);
        try domain.validateOwnerClosureAt(owner_index, &visited, live_context);
    }

    pub fn eql(domain: *const AddressDependencyDomain, other: *const AddressDependencyDomain) bool {
        if (domain.owner_count != other.owner_count) return false;
        for (domain.owners[0..domain.owner_count], other.owners[0..other.owner_count]) |*lhs, *rhs| {
            if (!lhs.identity.eqlIdentity(&rhs.identity) or
                lhs.identity_type != rhs.identity_type or
                lhs.dependency_count != rhs.dependency_count) return false;
            for (lhs.dependencies[0..lhs.dependency_count], rhs.dependencies[0..rhs.dependency_count]) |*lhs_dep, *rhs_dep| {
                if (!lhs_dep.identity.eqlIdentity(&rhs_dep.identity) or
                    lhs_dep.identity_type != rhs_dep.identity_type or
                    lhs_dep.role != rhs_dep.role) return false;
            }
        }
        return true;
    }

    const VisitState = enum { unseen, visiting, complete };

    fn ownerView(owner: *const Owner) OwnerView {
        var view = OwnerView{
            .name = owner.identity.slice(),
            .identity_type = owner.identity_type,
            .dependency_count = owner.dependency_count,
        };
        for (owner.dependencies[0..owner.dependency_count], 0..) |*dependency, index| {
            view.dependencies[index] = .{
                .name = dependency.identity.slice(),
                .identity_type = dependency.identity_type,
                .role = dependency.role,
            };
        }
        return view;
    }

    fn ownerIndex(domain: *const AddressDependencyDomain, name: []const u8) ?u8 {
        for (domain.owners[0..domain.owner_count], 0..) |*owner, index| {
            if (owner.identity.eql(name)) return @intCast(index);
        }
        return null;
    }

    fn removeOwnerInPlace(domain: *AddressDependencyDomain, owner_name: []const u8) void {
        const index = domain.ownerIndex(owner_name) orelse return;
        const last = domain.owner_count - 1;
        var cursor = index;
        while (cursor < last) : (cursor += 1) domain.owners[cursor] = domain.owners[cursor + 1];
        domain.owner_count = last;
    }

    fn validateIdentityType(
        domain: *const AddressDependencyDomain,
        name: []const u8,
        identity_type: IdentityType,
    ) !void {
        for (domain.owners[0..domain.owner_count]) |*owner| {
            if (owner.identity.eql(name) and owner.identity_type != identity_type)
                return error.AddressDependencyIdentityTypeMismatch;
            for (owner.dependencies[0..owner.dependency_count]) |*dependency| {
                if (dependency.identity.eql(name) and dependency.identity_type != identity_type)
                    return error.AddressDependencyIdentityTypeMismatch;
            }
        }
    }

    fn validateAcyclic(
        domain: *const AddressDependencyDomain,
        owner_index: usize,
        states: *[max_owners]VisitState,
    ) !void {
        switch (states[owner_index]) {
            .complete => return,
            .visiting => return error.AddressDependencyCycle,
            .unseen => states[owner_index] = .visiting,
        }
        const owner = &domain.owners[owner_index];
        for (owner.dependencies[0..owner.dependency_count]) |*dependency| {
            if (domain.ownerIndex(dependency.identity.slice())) |dependency_owner| {
                try domain.validateAcyclic(dependency_owner, states);
            }
        }
        states[owner_index] = .complete;
    }

    fn ownerRequires(
        domain: *const AddressDependencyDomain,
        owner_index: usize,
        name: []const u8,
        visited: *[max_owners]bool,
        live_context: anytype,
    ) !bool {
        if (visited[owner_index]) return false;
        visited[owner_index] = true;
        const owner = &domain.owners[owner_index];
        for (owner.dependencies[0..owner.dependency_count]) |*dependency| {
            try live_context.validateDependency(.{
                .name = dependency.identity.slice(),
                .identity_type = dependency.identity_type,
                .role = dependency.role,
            });
            if (dependency.identity.eql(name)) return true;
            if (domain.ownerIndex(dependency.identity.slice())) |dependency_owner| {
                if (try domain.ownerRequires(dependency_owner, name, visited, live_context)) return true;
            }
        }
        return false;
    }

    fn validateOwnerClosureAt(
        domain: *const AddressDependencyDomain,
        owner_index: usize,
        visited: *[max_owners]bool,
        live_context: anytype,
    ) !void {
        if (visited[owner_index]) return;
        visited[owner_index] = true;
        const owner = &domain.owners[owner_index];
        try live_context.validateOwner(ownerView(owner));
        for (owner.dependencies[0..owner.dependency_count]) |*dependency| {
            try live_context.validateDependency(.{
                .name = dependency.identity.slice(),
                .identity_type = dependency.identity_type,
                .role = dependency.role,
            });
            if (domain.ownerIndex(dependency.identity.slice())) |dependency_owner| {
                try domain.validateOwnerClosureAt(dependency_owner, visited, live_context);
            }
        }
    }
};
