define i32 @debug_sroa_dbg_drop(i32 %a, i32 %b) !dbg !4 {
entry:
  %agg = alloca { i32, i32 }, !dbg !8
  %p0 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 0, !dbg !9
  %p1 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 1, !dbg !10
  store i32 %a, ptr %p0, !dbg !11
  store i32 %b, ptr %p1, !dbg !12
  %x = load i32, ptr %p0, !dbg !13
  %y = load i32, ptr %p1, !dbg !14
  %sum = add i32 %x, %y, !dbg !15
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
