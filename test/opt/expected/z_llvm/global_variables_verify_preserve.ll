source_filename = "global_variables"
target triple = "x86_64-unknown-linux-gnu"

%os.linux.rlimit = type { i64, i64 }
%os.linux.stack_t__struct_3163 = type { ptr, i32, [4 x i8], i64 }

@__init_array_start = extern_weak constant ptr, align 8
@__init_array_end = extern_weak constant ptr, align 8
@os.linux.tls.area_desc.0 = internal unnamed_addr global i64 undef, align 8
@os.linux.tls.area_desc.4 = internal unnamed_addr global ptr undef, align 8
@os.linux.tls.main_thread_area_buffer = private unnamed_addr global [4096 x i8] undef, align 4096
@__anon_3154 = private unnamed_addr constant [13 x i8] c"hello world!\00", align 1
@Thread.maybeAttachSignalStack.global.signal_stack = private thread_local unnamed_addr global [262144 x i8] undef, align 1
