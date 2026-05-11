define i32 @debug_instcombine_dbg_drop(i32 %a) !dbg !4 {
entry:
  %sum = add i32 %a, 0, !dbg !8
  ret i32 %sum
}

!llvm.dbg.cu = !{!0}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!2 = !DIFile(filename: "debug_instcombine.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_instcombine_dbg_drop", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 10, scope: !4)

