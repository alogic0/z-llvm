source_filename = "debug_scope_branch"

define i32 @debug_scope_branch(i1 %cond, i32 %value) !dbg !4 {
entry:
  br i1 %cond, label %then, label %exit, !dbg !9
then:
  %inc = add i32 %value, 1, !dbg !11
  br label %exit, !dbg !12
exit:
  %result = phi i32 [ %value, %entry ], [ %inc, %then ], !dbg !13
  ret i32 %result
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!1}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !{i32 2, !"Debug Info Version", i32 3}
!2 = !DIFile(filename: "debug_scope_branch.zig", directory: ".")
!4 = distinct !DISubprogram(name: "debug_scope_branch", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = distinct !DILexicalBlock(scope: !4, file: !2, line: 2, column: 5)
!9 = !DILocation(line: 2, column: 5, scope: !4)
!11 = !DILocation(line: 3, column: 16, scope: !8)
!12 = !DILocation(line: 4, column: 5, scope: !8)
!13 = !DILocation(line: 6, column: 12, scope: !4)
