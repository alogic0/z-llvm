define i32 @debug_dce_dbg_drop(i32 %a) !dbg !4 {
entry:
  ret i32 %a
}

!llvm.dbg.cu = !{!0}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!2 = !DIFile(filename: "debug_dce.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_dce_dbg_drop", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 5, scope: !4)

