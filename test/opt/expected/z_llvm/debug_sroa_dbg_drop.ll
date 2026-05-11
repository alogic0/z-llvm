define i32 @debug_sroa_dbg_drop(i32 %a, i32 %b) !dbg !4 {
entry:
  %sum = add i32 %a, %b, !dbg !15
  ret i32 %sum
}

!llvm.dbg.cu = !{!0}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!2 = !DIFile(filename: "debug_sroa.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_sroa_dbg_drop", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 5, scope: !4)
!9 = !DILocation(line: 3, column: 5, scope: !4)
!10 = !DILocation(line: 4, column: 5, scope: !4)
!11 = !DILocation(line: 5, column: 5, scope: !4)
!12 = !DILocation(line: 6, column: 5, scope: !4)
!13 = !DILocation(line: 7, column: 5, scope: !4)
!14 = !DILocation(line: 8, column: 5, scope: !4)
!15 = !DILocation(line: 9, column: 5, scope: !4)
