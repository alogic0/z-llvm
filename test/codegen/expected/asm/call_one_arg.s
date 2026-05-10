	.text
	.globl call_one_arg
call_one_arg:
	subq $8, %rsp
	callq callee
	addq $8, %rsp
	retq
