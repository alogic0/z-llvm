static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;uint32_t a=seed*UINT32_C(0x9e3779b9)+(uint32_t)salt,b=~a^UINT32_C(0x12345678);memcpy(input,&a,4);memcpy(input+4,&b,4);
    uint64_t result=item->kind==0?b:item->kind==1?(uint32_t)(a+b):a,token=clobber_model(salt);memcpy(gold,&result,8);memcpy(gold+8,&token,8);
    return (struct test_model){8,1,16,SIZE_MAX,255,result^token};
}
