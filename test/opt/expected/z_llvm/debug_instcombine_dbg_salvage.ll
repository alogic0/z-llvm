define i32 @debug_instcombine_dbg_salvage(i32 %a) !dbg !4 {
entry:
  %use = mul i32 %a, 2, !dbg !8
  ret i32 %use
}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !2, producer: "z_llvm", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !{!0}
!2 = !DIFile(filename: "debug_instcombine.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_instcombine_dbg_salvage", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{!7, !7}
!7 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
!8 = !DILocation(line: 2, column: 10, scope: !4)

