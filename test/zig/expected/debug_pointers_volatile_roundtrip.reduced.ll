source_filename = "debug_pointers_volatile_roundtrip"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@volatile_roundtrip = alias i32 (ptr, i32), ptr @pointers_memory.volatile_roundtrip

define internal i32 @pointers_memory.volatile_roundtrip(ptr nonnull align 4 %0, i32 %1) unnamed_addr #0 align 1 !dbg !4 {
Entry:
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8, !dbg !8
    #dbg_declare(ptr %3, !9, !DIExpression(), !8)
  store i32 %1, ptr %2, align 4, !dbg !8
    #dbg_declare(ptr %2, !12, !DIExpression(), !8)
  store volatile i32 %1, ptr %0, align 4, !dbg !13
  %4 = load volatile i32, ptr %0, align 4, !dbg !14
  ret i32 %4, !dbg !14
}

attributes #0 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!15, !16}
!0 = distinct !DICompileUnit(language: DW_LANG_Zig, file: !2, producer: "zig", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!2 = !DIFile(filename: "pointers_memory.zig", directory: ".")
!4 = distinct !DISubprogram(name: "volatile_roundtrip", linkageName: "pointers_memory.volatile_roundtrip", scope: !2, file: !2, line: 1, type: !5, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{!7, !10, !7}
!7 = !DIBasicType(name: "i32", size: 32, encoding: DW_ATE_signed)
!8 = !DILocation(line: 1, column: 1, scope: !4)
!9 = !DILocalVariable(name: "p", arg: 1, scope: !4, file: !2, line: 1, type: !10)
!10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !11, size: 64)
!11 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !7)
!12 = !DILocalVariable(name: "value", arg: 2, scope: !4, file: !2, line: 1, type: !7)
!13 = !DILocation(line: 2, column: 5, scope: !4)
!14 = !DILocation(line: 3, column: 5, scope: !4)
!15 = !{i32 2, !"Debug Info Version", i32 3}
!16 = !{i32 2, !"Dwarf Version", i32 5}
