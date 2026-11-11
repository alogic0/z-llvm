target triple = "x86_64-unknown-linux-gnu"
declare void @word_pair_freeze_clobber()
define i64 @word_pair_freeze_0_0(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = add i64 %b, 0
 %first = insertvalue { ptr, i64 } poison, ptr %v0, 0
 %whole = insertvalue { ptr, i64 } %first, i64 %v1, 1
 %frozen = freeze { ptr, i64 } %whole
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, i64 } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, i64 } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_0_1(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = add i64 %b, 0
 %first = insertvalue { ptr, i64 } poison, ptr %v0, 0
 %whole = insertvalue { ptr, i64 } %first, i64 %v1, 1
 %frozen = freeze { ptr, i64 } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, i64 } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, i64 } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_0_2(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = add i64 %b, 0
 %first = insertvalue { ptr, i64 } undef, ptr %v0, 0
 %whole = insertvalue { ptr, i64 } %first, i64 %v1, 1
 %frozen = freeze { ptr, i64 } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, i64 } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, i64 } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_0_3(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = add i64 %b, 0
 %first = insertvalue { ptr, i64 } poison, ptr %v0, 0
 %whole = insertvalue { ptr, i64 } %first, i64 %v1, 1
 %frozen = freeze { ptr, i64 } zeroinitializer
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, i64 } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, i64 } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_1_0(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { i64, ptr } poison, i64 %v0, 0
 %whole = insertvalue { i64, ptr } %first, ptr %v1, 1
 %frozen = freeze { i64, ptr } %whole
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, ptr } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, ptr } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_1_1(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { i64, ptr } poison, i64 %v0, 0
 %whole = insertvalue { i64, ptr } %first, ptr %v1, 1
 %frozen = freeze { i64, ptr } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, ptr } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, ptr } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_1_2(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { i64, ptr } undef, i64 %v0, 0
 %whole = insertvalue { i64, ptr } %first, ptr %v1, 1
 %frozen = freeze { i64, ptr } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, ptr } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, ptr } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_1_3(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { i64, ptr } poison, i64 %v0, 0
 %whole = insertvalue { i64, ptr } %first, ptr %v1, 1
 %frozen = freeze { i64, ptr } zeroinitializer
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, ptr } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, ptr } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_2_0(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { ptr, ptr } poison, ptr %v0, 0
 %whole = insertvalue { ptr, ptr } %first, ptr %v1, 1
 %frozen = freeze { ptr, ptr } %whole
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, ptr } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, ptr } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_2_1(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { ptr, ptr } poison, ptr %v0, 0
 %whole = insertvalue { ptr, ptr } %first, ptr %v1, 1
 %frozen = freeze { ptr, ptr } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, ptr } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, ptr } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_2_2(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { ptr, ptr } undef, ptr %v0, 0
 %whole = insertvalue { ptr, ptr } %first, ptr %v1, 1
 %frozen = freeze { ptr, ptr } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, ptr } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, ptr } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_2_3(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = inttoptr i64 %a to ptr
 %v1 = inttoptr i64 %b to ptr
 %first = insertvalue { ptr, ptr } poison, ptr %v0, 0
 %whole = insertvalue { ptr, ptr } %first, ptr %v1, 1
 %frozen = freeze { ptr, ptr } zeroinitializer
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { ptr, ptr } %frozen, 0
 %word0 = ptrtoint ptr %field0 to i64
 %address0 = getelementptr i8, ptr %out, i64 0
 store ptr %field0, ptr %address0, align 1
 %field1 = extractvalue { ptr, ptr } %frozen, 1
 %word1 = ptrtoint ptr %field1 to i64
 %address1 = getelementptr i8, ptr %out, i64 8
 store ptr %field1, ptr %address1, align 1
 %field2 = extractvalue { ptr, ptr } %frozen, 0
 %word2 = ptrtoint ptr %field2 to i64
 %address2 = getelementptr i8, ptr %out, i64 16
 store ptr %field2, ptr %address2, align 1
 %field3 = extractvalue { ptr, ptr } %frozen, 1
 %word3 = ptrtoint ptr %field3 to i64
 %address3 = getelementptr i8, ptr %out, i64 24
 store ptr %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_3_0(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = add i64 %b, 0
 %first = insertvalue { i64, i64 } poison, i64 %v0, 0
 %whole = insertvalue { i64, i64 } %first, i64 %v1, 1
 %frozen = freeze { i64, i64 } %whole
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, i64 } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, i64 } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_3_1(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = add i64 %b, 0
 %first = insertvalue { i64, i64 } poison, i64 %v0, 0
 %whole = insertvalue { i64, i64 } %first, i64 %v1, 1
 %frozen = freeze { i64, i64 } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, i64 } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, i64 } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_3_2(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = add i64 %b, 0
 %first = insertvalue { i64, i64 } undef, i64 %v0, 0
 %whole = insertvalue { i64, i64 } %first, i64 %v1, 1
 %frozen = freeze { i64, i64 } %first
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, i64 } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, i64 } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %same_second
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
define i64 @word_pair_freeze_3_3(i64 %a, i64 %b, i64 %live, ptr %out) {
entry:
 %v0 = add i64 %a, 0
 %v1 = add i64 %b, 0
 %first = insertvalue { i64, i64 } poison, i64 %v0, 0
 %whole = insertvalue { i64, i64 } %first, i64 %v1, 1
 %frozen = freeze { i64, i64 } zeroinitializer
 call void @word_pair_freeze_clobber()
 %field0 = extractvalue { i64, i64 } %frozen, 0
 %word0 = add i64 %field0, 0
 %address0 = getelementptr i8, ptr %out, i64 0
 store i64 %field0, ptr %address0, align 1
 %field1 = extractvalue { i64, i64 } %frozen, 1
 %word1 = add i64 %field1, 0
 %address1 = getelementptr i8, ptr %out, i64 8
 store i64 %field1, ptr %address1, align 1
 %field2 = extractvalue { i64, i64 } %frozen, 0
 %word2 = add i64 %field2, 0
 %address2 = getelementptr i8, ptr %out, i64 16
 store i64 %field2, ptr %address2, align 1
 %field3 = extractvalue { i64, i64 } %frozen, 1
 %word3 = add i64 %field3, 0
 %address3 = getelementptr i8, ptr %out, i64 24
 store i64 %field3, ptr %address3, align 1
 %same_first = xor i64 %word0, %word2
 %same_second = xor i64 %word1, %word3
 %stable = or i64 %same_first, %same_second
 %observed = xor i64 %word0, %word1
 %checked = xor i64 %observed, %stable
 %answer = xor i64 %checked, %live
 ret i64 %answer
}
