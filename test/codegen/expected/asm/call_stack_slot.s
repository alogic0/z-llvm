	.text
	.globl call_stack_slot
call_stack_slot:
	subq $24, %rsp
	movl %edi, (%rsp)
	movl (%rsp), %edi
	callq callee
	addq $24, %rsp
	retq
