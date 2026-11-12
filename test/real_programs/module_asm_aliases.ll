target triple = "x86_64-unknown-linux-gnu"
module asm ".globl module_alias_a; .type module_alias_a, @function; .set module_alias_a, module_alias_b;"
module asm ".set module_alias_b, module_alias_existing; .type module_alias_b, @function; .globl module_alias_b;"
@module_alias_existing = alias i64 (i64), ptr @module_alias_body
@module_alias_seen = global i64 0, align 8
declare i64 @module_alias_a(i64)
declare i64 @module_alias_b(i64)
define internal i64 @module_alias_body(i64 %input) {
entry:
  store i64 %input, ptr @module_alias_seen, align 8
  %result = add i64 %input, 99
  ret i64 %result
}
