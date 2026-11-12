declare <16 x i8> @external_bytes(<16 x i8>)
declare <8 x i16> @external_words(<8 x i16>, <8 x i16>)
define <16 x i8> @byte_mix(<16 x i8> %a, <16 x i8> %b) {
entry:
 %reverse = shufflevector <16 x i8> %a, <16 x i8> poison, <16 x i32> <i32 15, i32 14, i32 13, i32 12, i32 11, i32 10, i32 9, i32 8, i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1, i32 0>
 %sum = add <16 x i8> %reverse, %b
 %mix = xor <16 x i8> %sum, <i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165, i8 165>
 ret <16 x i8> %mix
}
define <8 x i16> @word_mix(<8 x i16> %a, <8 x i16> %b) {
entry:
 %count = and <8 x i16> %b, <i16 15, i16 15, i16 15, i16 15, i16 15, i16 15, i16 15, i16 15>
 %shift = shl <8 x i16> %a, %count
 %mix = xor <8 x i16> %shift, %b
 ret <8 x i16> %mix
}
define <16 x i8> @byte_call(<16 x i8> %a, <16 x i8> %b) {
entry:
 %other = call <16 x i8> @external_bytes(<16 x i8> %a)
 %mix = add <16 x i8> %other, %b
 ret <16 x i8> %mix
}
define <8 x i16> @word_call(<8 x i16> %a, <8 x i16> %b) {
entry:
 %other = call <8 x i16> @external_words(<8 x i16> %a, <8 x i16> %b)
 %mix = add <8 x i16> %other, %a
 ret <8 x i16> %mix
}
define <16 x i8> @byte_spill8(<16 x i8> %a0, <16 x i8> %a1, <16 x i8> %a2, <16 x i8> %a3, <16 x i8> %a4, <16 x i8> %a5, <16 x i8> %a6, <16 x i8> %a7, ptr %out) {
entry:
 %v1 = xor <16 x i8> %a0, %a1
 %v2 = xor <16 x i8> %v1, %a2
 %v3 = xor <16 x i8> %v2, %a3
 %v4 = xor <16 x i8> %v3, %a4
 %v5 = xor <16 x i8> %v4, %a5
 %v6 = xor <16 x i8> %v5, %a6
 %v7 = xor <16 x i8> %v6, %a7
 store <16 x i8> %v7, ptr %out, align 1
 ret <16 x i8> %v7
}
define <8 x i16> @word_loop(<8 x i16> %a, <8 x i16> %b) {
entry:
 br label %loop
loop:
 %value = phi <8 x i16> [ %a, %entry ], [ %sum, %loop ]
 %index = phi i32 [ 0, %entry ], [ %next, %loop ]
 %sum = add <8 x i16> %value, %b
 %next = add i32 %index, 1
 %again = icmp ult i32 %next, 3
 br i1 %again, label %loop, label %exit
exit:
 ret <8 x i16> %sum
}
