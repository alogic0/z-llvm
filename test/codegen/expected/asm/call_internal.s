	.text
	.globl callee
callee:
	movl $7, %eax
	retq
	.text
	.globl call_internal
call_internal:
	subq $8, %rsp
	callq callee
	addq $8, %rsp
	retq
