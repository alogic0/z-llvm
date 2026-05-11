source_filename = "behavior_asm"
target triple = "x86_64-unknown-linux-gnu"

module asm ".globl this_is_my_alias;"
module asm ".type this_is_my_alias, @function;"
module asm ".set this_is_my_alias, derp;"

define i32 @derp() {
entry:
  ret i32 1
}
