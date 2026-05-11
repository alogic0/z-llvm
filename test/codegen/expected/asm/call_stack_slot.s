	.text
	.globl call_stack_slot
call_stack_slot:
	subq $8, %rsp
	movl %edi, (%rsp)
	movl (%rsp), %edi
	callq callee
	addq $8, %rsp
	retq
