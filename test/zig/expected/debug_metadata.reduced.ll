source_filename = "debug_metadata"

define i32 @debug_add(i32 %a) !dbg !4 {
entry:
  %sum = add i32 %a, 1, !dbg !8
  ret i32 %sum
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!1}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !{i32 2, !"Debug Info Version", i32 3}
!2 = !DIFile(filename: "debug_metadata.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_add", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 12, scope: !4)
