	.text
	.globl call_return_used
call_return_used:
	subq $8, %rsp
	movl %edi, (%rsp)
	callq callee
	movl (%rsp), %edi
	addq $8, %rsp
	addl %edi, %eax
	retq
