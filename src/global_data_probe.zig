//! Parser and global decoder imports for the standalone validation tool.
pub const ir = @import("ir.zig");
pub const data = @import("mc/global_data.zig");
pub const elf = @import("mc/elf.zig");
pub const Context = @import("codegen/x86_64/constant_table.zig").ReadOnlyModuleContext;
