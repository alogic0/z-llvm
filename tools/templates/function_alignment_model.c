static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)seed;(void)input;(void)expected;memset(gold,0,16);
    uint64_t constant=UINT64_C(0x123456789abcdef0)^((uint64_t)item->kind*17);
    uint64_t direct=salt^constant,indirect=(salt^UINT64_C(0x987654321))^constant;
    return (struct test_model){1,1,16,SIZE_MAX,255,direct+3*indirect};
}
struct address_case {void *(*get)(void);uint64_t (*alias)(uint64_t);unsigned alignment;};
static int addresses_aligned(const struct address_case *cases,size_t count){
    for(size_t i=0;i<count;i++)if(((uintptr_t)cases[i].get()&(cases[i].alignment-1))||(uintptr_t)cases[i].get()!=(uintptr_t)cases[i].alias){
        fprintf(stderr,"function-alignment case=%zu alignment=%u invalid address\n",i,cases[i].alignment);return 0;
    }
    return 1;
}
