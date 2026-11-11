target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128"
declare i64 @wide_bswap_clobber(i64)
declare i80 @llvm.bswap.i80(i80)
define i128 @wide_bswap_80_argument(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %input to i80
 %swapped = call i80 @llvm.bswap.i80(i80 %narrow)
 %wide = zext i80 %swapped to i128
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_bswap_80_literal(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %input to i80
 %swapped = call i80 @llvm.bswap.i80(i80 236413554034190829997551)
 %wide = zext i80 %swapped to i128
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i96 @llvm.bswap.i96(i96)
define i128 @wide_bswap_96_argument(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %input to i96
 %swapped = call i96 @llvm.bswap.i96(i96 %narrow)
 %wide = zext i96 %swapped to i128
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_bswap_96_literal(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %input to i96
 %swapped = call i96 @llvm.bswap.i96(i96 36621017341320381151029480943)
 %wide = zext i96 %swapped to i128
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i112 @llvm.bswap.i112(i112)
define i128 @wide_bswap_112_argument(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %input to i112
 %swapped = call i112 @llvm.bswap.i112(i112 %narrow)
 %wide = zext i112 %swapped to i128
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_bswap_112_literal(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %input to i112
 %swapped = call i112 @llvm.bswap.i112(i112 3784607487998720198549558449130991)
 %wide = zext i112 %swapped to i128
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i128 @llvm.bswap.i128(i128)
define i128 @wide_bswap_128_argument(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = add i128 %input,0
 %swapped = call i128 @llvm.bswap.i128(i128 %narrow)
 %wide = add i128 %swapped,0
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_bswap_128_literal(i128 %input,ptr %output,i64 %live) {
entry:
 %narrow = add i128 %input,0
 %swapped = call i128 @llvm.bswap.i128(i128 -1512366075204170947332355369683137041)
 %wide = add i128 %swapped,0
 %probe = call i64 @wide_bswap_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
