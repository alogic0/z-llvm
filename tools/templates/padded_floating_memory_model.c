__attribute__((noinline)) void complete_touch(void *value){__asm__ volatile("":"+r"(value)::"memory");}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;uint64_t state=seed+UINT64_C(0x123456789abcdef1);for(unsigned i=0;i<16;i++){state=state*UINT64_C(6364136223846793005)+1;input[i]=(unsigned char)(state>>32);}
    static const unsigned char f32[]={0,0,0x80,0x3f,0,0,0,0x80,1,0,0xc0,0x7f,0,0,0xa0,0x7f};static const unsigned char f16[]={0,0x3c,0,0x80,0,0x7c,0,0xfc,1,0x7e,0x55,0x7d,1,0,0xff,3};
    memcpy(gold,item->kind?(item->bits==32?f32:f16):input,16);uint64_t token=clobber_model(salt);memcpy(gold+16,&token,8);gold[24]=0x51;gold[25]=0xa3;
    return (struct test_model){16,1,26,SIZE_MAX,255,token};
}
