define i32 @debug_early_cse_dbg_preserve(i32 %a) !dbg !4 {
entry:
  %x = add i32 %a, 1, !dbg !8
  ret i32 %x
}

!llvm.dbg.cu = !{!0}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!2 = !DIFile(filename: "debug_early_cse.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_early_cse_dbg_preserve", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 10, scope: !4)
!9 = !DILocation(line: 3, column: 10, scope: !4)

