declare void @takes_byval(ptr byval({ i32, i32 }), ptr sret({ i32, i32 }))

define void @abi_byval_sret_attrs_preserve(ptr byval({ i32, i32 }) %src, ptr sret({ i32, i32 }) %dst) {
entry:
  ret void
}
