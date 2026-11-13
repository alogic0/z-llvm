__attribute__((noinline)) void spill_object_copy(const void *source,void *destination,uint64_t bytes){
    memcpy(destination,source,(size_t)bytes);
    __asm__ volatile("":::"rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","memory");
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)seed;(void)input;(void)expected;
    static const unsigned counts[3]={16,40,72};
    unsigned shape=item->kind/2,count=counts[shape],bytes=item->bits/8;
    for(unsigned object=0;object<count;object++)for(unsigned lane=0;lane<32/bytes;lane++){
        uint64_t value=(object+1)*257+lane*17+shape*13;
        for(unsigned byte=0;byte<bytes;byte++)gold[object*32+lane*bytes+byte]=(unsigned char)(value>>(byte*8));
    }
    uint64_t token=clobber_model(salt);memcpy(gold+count*32,&token,8);
    return (struct test_model){1,1,count*32+8,SIZE_MAX,255,token^salt};
}
