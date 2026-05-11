source_filename = "debug_call_chain"

define i32 @debug_callee(i32 %value) !dbg !4 {
entry:
  %doubled = mul i32 %value, 2, !dbg !8
  ret i32 %doubled
}

define i32 @debug_call_chain(i32 %value) !dbg !9 {
entry:
  %called = call i32 @debug_callee(i32 %value), !dbg !13
  %result = add i32 %called, 1, !dbg !14
  ret i32 %result
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!1}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !{i32 2, !"Debug Info Version", i32 3}
!2 = !DIFile(filename: "control_flow_calls.zig", directory: ".")
!4 = distinct !DISubprogram(name: "callee", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = !DILocation(line: 2, column: 18, scope: !4)
!9 = distinct !DISubprogram(name: "call_chain", scope: !2, file: !2, line: 4, type: !5, scopeLine: 4, spFlags: DISPFlagDefinition, unit: !0)
!13 = !DILocation(line: 5, column: 12, scope: !9)
!14 = !DILocation(line: 5, column: 26, scope: !9)
