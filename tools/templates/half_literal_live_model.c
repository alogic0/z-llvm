static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned kind=item->kind/4,form=item->kind%4;
    static const uint16_t lhs[6]={0x0000,0x8000,0x3e00,0xc000,0x7c00,0x7e00};
    static const uint16_t sums[6]={0x3c00,0x8000,0x4380,0xbe00,0x7e00,0x7e00};
    uint64_t word=seed<4?(uint64_t[]){0,UINT64_MAX,salt,salt^UINT64_C(0x8000000000000000)}[seed]:(seed+1)*UINT64_C(0x9182736455aaccdd);
    uint64_t kept=item->bits==1?word<salt:item->bits==32?(uint32_t)(word^salt):word^salt;
    uint16_t sum=kind==1&&form>=2?0:sums[kind];
    uint64_t token=clobber_model(salt);
    memcpy(input,&word,8);memcpy(input+8,&lhs[kind],2);
    memcpy(gold,&kept,8);memcpy(gold+8,&sum,2);memcpy(gold+10,&token,8);
    return (struct test_model){10,1,18,SIZE_MAX,255,kept^token};
}
