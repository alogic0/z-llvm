static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;uint32_t literal=item->bits,dynamic=seed*UINT32_C(0x9e3779b1)^UINT32_C(0xa5a5a5a5);
    uint64_t token=clobber_model(salt);memcpy(input,&dynamic,4);
    for(unsigned i=0;i<4;i++)memcpy(gold+i*4,&literal,4);
    memcpy(gold+16,&dynamic,4);memcpy(gold+20,&token,8);
    return (struct test_model){4,1,28,SIZE_MAX,255,token};
}
