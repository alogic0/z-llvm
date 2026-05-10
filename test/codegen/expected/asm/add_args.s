	.text
	.globl add_args
add_args:
	movl %edi, %eax
	addl %esi, %eax
	retq
