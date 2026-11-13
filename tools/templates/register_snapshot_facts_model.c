/* Observe preserved registers at call entry, before a C prologue can change them. */
__asm__(
".text\n.globl snapshot_check\n.type snapshot_check,@function\nsnapshot_check:\n"
"cmpq %rdi,0x28(%rdi)\njne 1f\n"
"cmpq %rbx,0x18(%rdi)\njne 1f\n"
"cmpq %rbp,0x30(%rdi)\njne 1f\n"
"cmpq %r12,0x60(%rdi)\njne 1f\n"
"cmpq %r13,0x68(%rdi)\njne 1f\n"
"cmpq %r14,0x70(%rdi)\njne 1f\n"
"cmpq %r15,0x78(%rdi)\njne 1f\n"
"leaq 8(%rsp),%rax\ncmpq %rax,0x38(%rdi)\njne 1f\n"
"movq 0x80(%rdi),%rax\ncmpq %rsi,%rax\njb 1f\n"
"leaq 65536(%rsi),%rcx\ncmpq %rcx,%rax\njae 1f\n"
"movl $1,%eax\nret\n1:\nxorl %eax,%eax\nret\n.size snapshot_check,.-snapshot_check\n");
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)item;(void)expected;uint64_t one=1,token=clobber_model(salt);memcpy(input,&seed,sizeof seed);memcpy(gold,&one,8);memcpy(gold+136,&token,8);
    return (struct test_model){8,1,144,SIZE_MAX,255,token^one};
}
