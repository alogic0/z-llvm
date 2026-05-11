@tls = internal thread_local global i32 0

define i32 @dce_tls_store_preserve(i32 %v) {
entry:
  store i32 %v, ptr @tls, align 4
  %r = load i32, ptr @tls, align 4
  ret i32 %r
}
