define i32 @alias_metadata_preserve(ptr %a, ptr %b) {
entry:
  %x = load i32, ptr %a, align 4, !tbaa !0, !alias.scope !3, !noalias !6
  store i32 %x, ptr %b, align 4, !tbaa !0, !alias.scope !6, !noalias !3
  ret i32 %x
}

!0 = !{!1, !1, i64 0}
!1 = !{!"int", !2}
!2 = !{!"Simple C/C++ TBAA"}
!3 = !{!4}
!4 = distinct !{!4, !5}
!5 = distinct !{!5}
!6 = !{!7}
!7 = distinct !{!7, !5}
