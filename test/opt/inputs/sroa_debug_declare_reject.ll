declare void @llvm.dbg.declare(metadata, metadata, metadata)

define i32 @sroa_debug_declare_reject(i32 %a) !dbg !4 {
entry:
  %agg = alloca { i32, i32 }
  call void @llvm.dbg.declare(metadata ptr %agg, metadata !9, metadata !DIExpression()), !dbg !8
  %p0 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 0
  store i32 %a, ptr %p0
  %x = load i32, ptr %p0
  ret i32 %x
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!1}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !2, producer: "z_llvm", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !{i32 2, !"Debug Info Version", i32 3}
!2 = !DIFile(filename: "sroa_debug.zig", directory: ".")
!4 = distinct !DISubprogram(name: "sroa_debug_declare_reject", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{!7}
!7 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
!8 = !DILocation(line: 1, column: 1, scope: !4)
!9 = !DILocalVariable(name: "agg", scope: !4, file: !2, line: 1, type: !7)
