@a = private constant i32 5
@b = private constant i32 5

define i32 @read() local_unnamed_addr {
entry:
  %x = load i32, ptr @a, align 4
  %y = load i32, ptr @b, align 4
  %z = add i32 %x, %y
  ret i32 %z
}
