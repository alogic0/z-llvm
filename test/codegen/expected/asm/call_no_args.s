	.text
	.globl call_no_args
call_no_args:
	subq $8, %rsp
	callq callee
	addq $8, %rsp
	retq
