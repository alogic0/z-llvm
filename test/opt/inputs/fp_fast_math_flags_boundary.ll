define float @fadd_nsz_zero(float %a) {
entry:
  %r = fadd nsz float %a, 0.000000e+00
  ret float %r
}

define i1 @fcmp_nnan_self(float %a) {
entry:
  %r = fcmp nnan oeq float %a, %a
  ret i1 %r
}

define float @fmul_ninf_preserve(float %a, float %b) {
entry:
  %r = fmul ninf float %a, %b
  ret float %r
}

define float @fadd_reassoc_preserve(float %a, float %b) {
entry:
  %r = fadd reassoc float %a, %b
  ret float %r
}

define float @fdiv_arcp_preserve(float %a, float %b) {
entry:
  %r = fdiv arcp float %a, %b
  ret float %r
}

define float @fmul_contract_preserve(float %a, float %b) {
entry:
  %r = fmul contract float %a, %b
  ret float %r
}

define float @fdiv_afn_preserve(float %a, float %b) {
entry:
  %r = fdiv afn float %a, %b
  ret float %r
}

define float @fmul_fast_preserve(float %a, float %b) {
entry:
  %r = fmul fast float %a, %b
  ret float %r
}
