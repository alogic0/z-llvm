target triple = "x86_64-unknown-linux-gnu"
define <2 x float> @vector_fptrunc(<2 x double> %x) {
entry:
  %y = fptrunc <2 x double> %x to <2 x float>
  ret <2 x float> %y
}
