	.text
	.globl call_two_args
call_two_args:
	subq $8, %rsp
	callq callee
	addq $8, %rsp
	retq
