@base = global i32 0

@b = alias i32, ptr @base
@a = alias i32, ptr @base

define ptr @use_alias() {
entry:
  ret ptr @a
}

