const canonicalize = @import("semantic_descriptor_v2_canonicalize.zig");
const programs = @import("semantic_descriptor_v2_programs.zig");
const verify_api = @import("semantic_descriptor_v2_verify.zig");

pub const verify = verify_api.verify;
pub const lowerToStructuredIr = programs.lowerToStructuredIr;

pub const releaseCanonicalizationReport = canonicalize.releaseCanonicalizationReport;
pub const releaseCanonicalizationSummary = canonicalize.releaseCanonicalizationSummary;

pub const writeText = programs.writeText;
pub const programFromSurface = programs.programFromSurface;
pub const programFromSemanticBody = programs.programFromSemanticBody;
pub const programFromSourceDescriptor = programs.programFromSourceDescriptor;
pub const programFromFullDescriptor = programs.programFromFullDescriptor;
pub const programFromSourceFacts = programs.programFromSourceFacts;
pub const programFromSourceFactProgram = programs.programFromSourceFactProgram;
pub const programFromSourceFactProgramDirect = programs.programFromSourceFactProgramDirect;
pub const programFromSerializedReturn = programs.programFromSerializedReturn;
pub const bodyForDiagnosticSurface = programs.bodyForDiagnosticSurface;
pub const bodyForName = programs.bodyForName;
pub const isRealDescriptorProgram = programs.isRealDescriptorProgram;
pub const isSurfaceToBodyAdapter = programs.isSurfaceToBodyAdapter;
pub const isCannedReturnDescriptor = programs.isCannedReturnDescriptor;
pub const isSourceDerivedDescriptor = programs.isSourceDerivedDescriptor;
pub const isBodyEnumDispatch = programs.isBodyEnumDispatch;
pub const firstUnsupportedConstruct = programs.firstUnsupportedConstruct;
