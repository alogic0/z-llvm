extern unsigned char symbolic_roundtrip_storage[256];
__attribute__((noinline)) uint64_t complete_pointer_echo(const void *value){__asm__ volatile("":"+r"(value)::"memory");return (uintptr_t)value;}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;input[0]=(unsigned char)seed;size_t offset=item->bits+(item->kind&&!(salt&1));uint64_t address=(uintptr_t)(symbolic_roundtrip_storage+offset),one=1,token=clobber_model(salt);
    memcpy(gold,&address,8);memcpy(gold+8,&one,8);memcpy(gold+16,&address,8);memcpy(gold+24,&token,8);
    return (struct test_model){1,1,32,SIZE_MAX,255,address^token};
}
