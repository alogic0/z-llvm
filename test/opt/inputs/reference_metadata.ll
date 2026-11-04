; Metadata strings are data; typed operands in records and constants are uses.
@metadata_constant = internal global i32 23, align 4, !dbg !33
@metadata_mutable = internal global i32 0, align 4
@metadata_dead = internal global i32 99
@metadata_a = internal unnamed_addr constant i32 7
@metadata_b = internal unnamed_addr constant i32 7
@metadata_only = internal global i32 19
@metadata_alias = alias i32, ptr @metadata_mutable
@metadata_callbacks = internal constant [1 x ptr] [ptr @metadata_helper]

define i32 @metadata_read_constant(i32 %x) #0 !dbg !22 {
entry:
  %constant = load i32, ptr @metadata_constant, !dbg !36
  %sum = add i32 %constant, %x
  ret i32 %sum
}

define i32 @metadata_store_gep_load(i32 %x) #0 {
entry:
  store i32 %x, ptr getelementptr (i32, ptr @metadata_mutable, i64 0)
  %loaded = load i32, ptr @metadata_mutable
  ret i32 %loaded
}

define internal i32 @metadata_helper(i32 %x) #0 {
entry:
  %sum = add i32 %x, 5
  ret i32 %sum
}

define i32 @metadata_table_call(i32 %x) #0 {
entry:
  %callback = load ptr, ptr getelementptr ([1 x ptr], ptr @metadata_callbacks, i64 0, i64 0)
  %called = call i32 %callback(i32 %x)
  ret i32 %called
}

define i32 @metadata_alias_load(i32 %x) #0 {
entry:
  store i32 %x, ptr @metadata_alias
  %loaded = load i32, ptr @metadata_mutable
  ret i32 %loaded
}

define i32 @metadata_constant_refs() #0 {
entry:
  %a = load i32, ptr getelementptr (i32, ptr @metadata_a, i64 0)
  %b = load i32, ptr @metadata_b
  %sum = add i32 %a, %b
  ret i32 %sum
}

define internal i32 @metadata_dead_function() #0 {
entry:
  ret i32 99
}

attributes #0 = { nounwind "frame-pointer"="all" }

!llvm.module.flags = !{!0, !31, !32}
!llvm.dbg.cu = !{!20}
!0 = !{i32 1, !"z_llvm.reference", ptr @metadata_only}
!1 = !{!"@metadata_dead blockaddress(@metadata_dead_function, %entry)"}
!20 = distinct !DICompileUnit(language: DW_LANG_C99, file: !21, producer: "reference regression", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !30, globals: !35)
!21 = !DIFile(filename: "reference_metadata.ll", directory: ".")
!22 = distinct !DISubprogram(name: "metadata_read_constant", scope: !21, file: !21, line: 1, type: !23, scopeLine: 1, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !20)
!23 = !DISubroutineType(types: !24)
!24 = !{!25, !25}
!25 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
!26 = !DICompositeType(tag: DW_TAG_structure_type, name: "Node", file: !21, size: 64, align: 64, elements: !27)
!27 = !{!28}
!28 = !DIDerivedType(tag: DW_TAG_member, name: "next", scope: !26, baseType: !29, size: 64, align: 64)
!29 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !26, size: 64)
!30 = !{!26}
!31 = !{i32 2, !"Debug Info Version", i32 3}
!32 = !{i32 2, !"Dwarf Version", i32 5}
!33 = !DIGlobalVariableExpression(var: !34, expr: !DIExpression())
!34 = distinct !DIGlobalVariable(name: "metadata_constant", scope: !20, file: !21, line: 1, type: !25, isLocal: true, isDefinition: true)
!35 = !{!33}
!36 = !DILocation(line: 1, column: 1, scope: !22)
