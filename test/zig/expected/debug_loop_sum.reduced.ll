source_filename = "debug_loop_sum"

define i32 @debug_loop_sum(i32 %limit) !dbg !4 {
entry:
  br label %loop, !dbg !9
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %body ], !dbg !11
  %sum = phi i32 [ 0, %entry ], [ %acc, %body ], !dbg !12
  %cond = icmp slt i32 %i, %limit, !dbg !13
  br i1 %cond, label %body, label %exit, !dbg !14
body:
  %acc = add i32 %sum, %i, !dbg !16
  %next = add i32 %i, 1, !dbg !17
  br label %loop, !dbg !18
exit:
  ret i32 %sum
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!1}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !{i32 2, !"Debug Info Version", i32 3}
!2 = !DIFile(filename: "control_flow_calls.zig", directory: ".")
!4 = distinct !DISubprogram(name: "loop_sum", scope: !2, file: !2, line: 8, type: !5, scopeLine: 8, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{}
!8 = distinct !DILexicalBlock(scope: !4, file: !2, line: 11, column: 5)
!9 = !DILocation(line: 9, column: 5, scope: !4)
!11 = !DILocation(line: 11, column: 12, scope: !8)
!12 = !DILocation(line: 11, column: 12, scope: !8)
!13 = !DILocation(line: 11, column: 18, scope: !8)
!14 = !DILocation(line: 11, column: 5, scope: !8)
!16 = !DILocation(line: 12, column: 13, scope: !8)
!17 = !DILocation(line: 11, column: 33, scope: !8)
!18 = !DILocation(line: 13, column: 5, scope: !8)
