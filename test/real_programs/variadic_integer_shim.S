.text
.globl zllvm_varargs_one
.type zllvm_varargs_one,@function
zllvm_varargs_one:
    testb %al, %al
    jne .Lbad_one
    jmp zllvm_varargs_one_impl
.Lbad_one:
    movl $-555, %eax
    ret
.size zllvm_varargs_one,.-zllvm_varargs_one

.globl zllvm_varargs_two
.type zllvm_varargs_two,@function
zllvm_varargs_two:
    testb %al, %al
    jne .Lbad_two
    jmp zllvm_varargs_two_impl
.Lbad_two:
    movl $-777, %eax
    ret
.size zllvm_varargs_two,.-zllvm_varargs_two
.section .note.GNU-stack,"",@progbits
