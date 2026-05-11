source_filename = "debug_declare_intrinsic"

declare void @llvm.dbg.declare(metadata, metadata, metadata)

define void @debug_declare(ptr %p) !dbg !4 {
entry:
  call void @llvm.dbg.declare(metadata ptr %p, metadata !9, metadata !DIExpression()), !dbg !8
  ret void
}

!llvm.dbg.cu = !{!0}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!2 = !DIFile(filename: "debug_declare.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_declare", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 5, scope: !4)
!9 = !DILocalVariable(name: "p", arg: 1, scope: !4, file: !2, line: 1, type: !10)
!10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !11, size: 64)
!11 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
