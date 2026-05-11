source_filename = "named_types"
target triple = "x86_64-unknown-linux-gnu"

%os.linux.rlimit = type { i64, i64 }
%os.linux.stack_t__struct_3163 = type { ptr, i32, [4 x i8], i64 }

define void @use_named_type(ptr %p) {
entry:
  %slot = alloca %os.linux.rlimit, align 8
  ret void
}
