	.text
	.globl stack_slot
stack_slot:
	subq $8, %rsp
	movl %edi, (%rsp)
	movl (%rsp), %eax
	addq $8, %rsp
	retq
