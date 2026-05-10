	.text
	.globl bitwise_args
bitwise_args:
	movl %edi, %eax
	xorl %esi, %eax
	retq
