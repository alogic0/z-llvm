source_filename = "debug_value_intrinsic"

declare void @llvm.dbg.value(metadata, metadata, metadata)

define i32 @debug_value(i32 %a) !dbg !4 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !9, metadata !DIExpression()), !dbg !8
  ret i32 %a
}

!llvm.dbg.cu = !{!0}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!2 = !DIFile(filename: "debug_value.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_value", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 5, scope: !4)
!9 = !DILocalVariable(name: "a", arg: 1, scope: !4, file: !2, line: 1, type: !10)
!10 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
