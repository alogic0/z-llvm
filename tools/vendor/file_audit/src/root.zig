//! Read-only Linux file auditing. No deletion or hardlink mutation API.
pub const version = "0.1.2";
pub const Metadata = @import("metadata.zig").Metadata;
pub const Kind = @import("metadata.zig").Kind;
pub const metadata = @import("metadata.zig");
pub const Options = @import("snapshot.zig").Options;
pub const Entry = @import("snapshot.zig").Entry;
pub const Snapshot = @import("snapshot.zig").Snapshot;
pub const OwnedSnapshot = @import("snapshot.zig").OwnedSnapshot;
pub const scan = @import("snapshot.zig").scan;
pub const verify = @import("snapshot.zig").verify;
pub const Duplicate = @import("duplicates.zig").Duplicate;
pub const DuplicateReport = @import("duplicates.zig").Report;
pub const OwnedDuplicates = @import("duplicates.zig").Owned;
pub const findDuplicates = @import("duplicates.zig").find;
