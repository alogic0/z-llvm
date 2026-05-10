	.text
	.globl conditional_return
conditional_return:
	testb %dil, %dil
	je .Lconditional_return_else
.Lconditional_return_then:
	movl %esi, %eax
	retq
.Lconditional_return_else:
	movl %edx, %eax
	retq
