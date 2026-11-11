target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128"
declare i64 @scalar_vector_select_clobber(i64)
define i64 @scalar_vector_select_0(i64 %choice,ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %condition = trunc i64 %choice to i1
 %selected = select i1 %condition,fp128 %a,fp128 %b
 %probe = call i64 @scalar_vector_select_clobber(i64 %live)
 store fp128 %selected,ptr %output,align 1
 %answer = xor i64 %probe,%choice
 ret i64 %answer
}
define i64 @scalar_vector_select_1(i64 %choice,ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %condition = trunc i64 %choice to i1
 %selected = select i1 %condition,fp128 0xL00000000000000017FFF000000000000,fp128 %b
 %probe = call i64 @scalar_vector_select_clobber(i64 %live)
 store fp128 %selected,ptr %output,align 1
 %answer = xor i64 %probe,%choice
 ret i64 %answer
}
define i64 @scalar_vector_select_2(i64 %choice,ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %a = load <2 x float>,ptr %left,align 1
 %b = load <2 x float>,ptr %right,align 1
 %condition = trunc i64 %choice to i1
 %selected = select i1 %condition,<2 x float> %a,<2 x float> %b
 %probe = call i64 @scalar_vector_select_clobber(i64 %live)
 store <2 x float> %selected,ptr %output,align 1
 %answer = xor i64 %probe,%choice
 ret i64 %answer
}
define i64 @scalar_vector_select_3(i64 %choice,ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %a = load <2 x double>,ptr %left,align 1
 %b = load <2 x double>,ptr %right,align 1
 %condition = trunc i64 %choice to i1
 %selected = select i1 %condition,<2 x double> %a,<2 x double> %b
 %probe = call i64 @scalar_vector_select_clobber(i64 %live)
 store <2 x double> %selected,ptr %output,align 1
 %answer = xor i64 %probe,%choice
 ret i64 %answer
}
