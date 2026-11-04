//! Bounded specialized-node field schemas, following LLVM LLParser.cpp's
//! VISIT_MD_FIELDS tables. Unlisted kinds/fields/enumerants remain unknown.
const std = @import("std");

pub const Kind = enum { node, non_null_node, string, boolean, u8, u16, u32, u64, s32, s64, integer, uint_or_node, sint_or_node, tag, encoding, language, flags, sp_flags, emission, checksum, name_table };
pub const Field = struct { name: []const u8, kind: Kind, required: bool = false };

fn f(name: []const u8, kind: Kind) Field {
    return .{ .name = name, .kind = kind };
}
fn r(name: []const u8, kind: Kind) Field {
    return .{ .name = name, .kind = kind, .required = true };
}

pub fn schema(name: []const u8) ?[]const Field {
    if (std.mem.eql(u8, name, "DIGlobalVariableExpression")) return comptime &.{ r("var", .node), r("expr", .node) };
    if (std.mem.eql(u8, name, "DIGlobalVariable")) return comptime &.{
        f("name", .string),     f("scope", .node),           f("linkageName", .string),  f("file", .node),        f("line", .u32),  f("type", .node),
        f("isLocal", .boolean), f("isDefinition", .boolean), f("templateParams", .node), f("declaration", .node), f("align", .u32), f("annotations", .node),
    };
    if (std.mem.eql(u8, name, "DIFile")) return comptime &.{ r("filename", .string), r("directory", .string), f("checksumkind", .checksum), f("checksum", .string), f("source", .string) };
    if (std.mem.eql(u8, name, "DIBasicType")) return comptime &.{
        f("tag", .tag), f("name", .string), f("size", .uint_or_node), f("align", .u32), f("dataSize", .u32), f("encoding", .encoding), f("num_extra_inhabitants", .u32), f("flags", .flags),
    };
    if (std.mem.eql(u8, name, "DICompositeType")) return comptime &.{
        r("tag", .tag),                   f("name", .string),         f("file", .node),         f("line", .u32),        f("scope", .node),           f("baseType", .node),     f("size", .uint_or_node),
        f("align", .u32),                 f("offset", .uint_or_node), f("flags", .flags),       f("elements", .node),   f("runtimeLang", .language), f("vtableHolder", .node), f("templateParams", .node),
        f("identifier", .string),         f("discriminator", .node),  f("dataLocation", .node), f("associated", .node), f("allocated", .node),       f("rank", .sint_or_node), f("annotations", .node),
        f("num_extra_inhabitants", .u32), f("specification", .node),  f("bitStride", .node),
    };
    if (std.mem.eql(u8, name, "DIDerivedType")) return comptime &.{
        r("tag", .tag),   f("name", .string),         f("file", .node),   f("line", .u32),       f("scope", .node),            r("baseType", .node),    f("size", .uint_or_node),
        f("align", .u32), f("offset", .uint_or_node), f("flags", .flags), f("extraData", .node), f("dwarfAddressSpace", .u32), f("annotations", .node),
    };
    if (std.mem.eql(u8, name, "DIEnumerator")) return comptime &.{ r("name", .string), r("value", .integer), f("isUnsigned", .boolean) };
    if (std.mem.eql(u8, name, "DICompileUnit")) return comptime &.{
        r("file", .non_null_node),        f("language", .language),     f("producer", .string),            f("isOptimized", .boolean),           f("flags", .string),             f("runtimeVersion", .u32),
        f("splitDebugFilename", .string), f("emissionKind", .emission), f("enums", .node),                 f("retainedTypes", .node),            f("globals", .node),             f("imports", .node),
        f("macros", .node),               f("dwoId", .u64),             f("splitDebugInlining", .boolean), f("debugInfoForProfiling", .boolean), f("nameTableKind", .name_table), f("rangesBaseAddress", .boolean),
        f("sysroot", .string),            f("sdk", .string),
    };
    if (std.mem.eql(u8, name, "DISubrange")) return comptime &.{ f("count", .sint_or_node), f("lowerBound", .sint_or_node), f("upperBound", .sint_or_node), f("stride", .sint_or_node) };
    if (std.mem.eql(u8, name, "DISubroutineType")) return comptime &.{ f("flags", .flags), r("types", .node) };
    if (std.mem.eql(u8, name, "DISubprogram")) return comptime &.{
        f("scope", .node),            f("name", .string),             f("linkageName", .string),  f("file", .node),        f("line", .u32),           f("type", .node),        f("isLocal", .boolean),
        f("isDefinition", .boolean),  f("scopeLine", .u32),           f("containingType", .node), f("virtualIndex", .u32), f("thisAdjustment", .s32), f("flags", .flags),      f("spFlags", .sp_flags),
        f("isOptimized", .boolean),   f("unit", .node),               f("templateParams", .node), f("declaration", .node), f("retainedNodes", .node), f("thrownTypes", .node), f("annotations", .node),
        f("targetFuncName", .string), f("keyInstructions", .boolean),
    };
    if (std.mem.eql(u8, name, "DILocalVariable")) return comptime &.{
        r("scope", .non_null_node), f("name", .string), f("arg", .u16), f("file", .node), f("line", .u32), f("type", .node), f("flags", .flags), f("align", .u32), f("annotations", .node),
    };
    if (std.mem.eql(u8, name, "DILocation")) return comptime &.{
        f("line", .u32), f("column", .u16), r("scope", .non_null_node), f("inlinedAt", .node), f("isImplicitCode", .boolean), f("atomGroup", .u64), f("atomRank", .u8),
    };
    if (std.mem.eql(u8, name, "DILexicalBlock")) return comptime &.{ r("scope", .non_null_node), f("file", .node), f("line", .u32), f("column", .u16) };
    return null;
}

pub fn enumerants(kind: Kind) []const []const u8 {
    return switch (kind) {
        .tag => &.{ "DW_TAG_array_type", "DW_TAG_enumeration_type", "DW_TAG_member", "DW_TAG_pointer_type", "DW_TAG_structure_type", "DW_TAG_typedef", "DW_TAG_union_type", "DW_TAG_base_type", "DW_TAG_const_type", "DW_TAG_volatile_type", "DW_TAG_restrict_type", "DW_TAG_reference_type", "DW_TAG_rvalue_reference_type", "DW_TAG_subroutine_type" },
        .encoding => &.{ "DW_ATE_address", "DW_ATE_boolean", "DW_ATE_float", "DW_ATE_signed", "DW_ATE_signed_char", "DW_ATE_unsigned", "DW_ATE_unsigned_char", "DW_ATE_UTF", "DW_ATE_complex_float" },
        .language => &.{ "DW_LANG_C", "DW_LANG_C89", "DW_LANG_C99", "DW_LANG_C11", "DW_LANG_C_plus_plus", "DW_LANG_C_plus_plus_11", "DW_LANG_C_plus_plus_14", "DW_LANG_Rust" },
        .flags => &.{ "DIFlagZero", "DIFlagPrivate", "DIFlagProtected", "DIFlagPublic", "DIFlagFwdDecl", "DIFlagArtificial", "DIFlagPrototyped", "DIFlagObjectPointer", "DIFlagVector", "DIFlagStaticMember", "DIFlagLValueReference", "DIFlagRValueReference", "DIFlagBitField", "DIFlagNoReturn", "DIFlagTypePassByValue", "DIFlagTypePassByReference", "DIFlagEnumClass", "DIFlagThunk", "DIFlagNonTrivial", "DIFlagBigEndian", "DIFlagLittleEndian", "DIFlagAllCallsDescribed" },
        .sp_flags => &.{ "DISPFlagZero", "DISPFlagVirtual", "DISPFlagPureVirtual", "DISPFlagLocalToUnit", "DISPFlagDefinition", "DISPFlagOptimized", "DISPFlagPure", "DISPFlagElemental", "DISPFlagRecursive", "DISPFlagMainSubprogram" },
        .emission => &.{ "NoDebug", "FullDebug", "LineTablesOnly", "DebugDirectivesOnly" },
        .checksum => &.{ "CSK_MD5", "CSK_SHA1", "CSK_SHA256" },
        .name_table => &.{ "Default", "GNU", "None", "Apple" },
        else => &.{},
    };
}
