@tls = internal thread_local(localexec) unnamed_addr global i32 1, align 4

define i32 @read_tls_model() {
entry:
  %v = load i32, ptr @tls, align 4
  ret i32 %v
}
