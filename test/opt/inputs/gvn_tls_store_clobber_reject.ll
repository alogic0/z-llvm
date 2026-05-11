@tls = internal thread_local global i32 0

define i32 @gvn_tls_store_clobber_reject(i32 %v) {
entry:
  %first = load i32, ptr @tls, align 4
  store i32 %v, ptr @tls, align 4
  %second = load i32, ptr @tls, align 4
  %sum = add i32 %first, %second
  ret i32 %sum
}
