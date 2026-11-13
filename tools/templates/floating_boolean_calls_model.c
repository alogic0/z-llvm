static void boolean_float_input(unsigned bits,unsigned kind,unsigned char *out){
    uint64_t lo=0,hi=0;
    if(bits==16){uint16_t values[]={0,0x8000,0x3c00,0xbc00,0x7c00,0xfc00,1,0x7bff,0x7e01,0x7c01};memcpy(out,&values[kind],2);return;}
    if(bits==32){uint32_t values[]={0,0x80000000,0x3f800000,0xbf800000,0x7f800000,0xff800000,1,0x7f7fffff,0x7fc00001,0x7f800001};memcpy(out,&values[kind],4);return;}
    if(bits==64){uint64_t values[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x3ff0000000000000),UINT64_C(0xbff0000000000000),UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),1,UINT64_C(0x7fefffffffffffff),UINT64_C(0x7ff8000000000001),UINT64_C(0x7ff0000000000001)};memcpy(out,&values[kind],8);return;}
    if(bits==80){uint16_t exponent[]={0,0x8000,0x3fff,0xbfff,0x7fff,0xffff,0,0x7ffe,0x7fff,0x7fff};uint64_t significand[]={0,0,UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000),1,UINT64_MAX,UINT64_C(0xc000000000000001),UINT64_C(0x8000000000000001)};memcpy(out,&significand[kind],8);memcpy(out+8,&exponent[kind],2);return;}
    {uint64_t high[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x3fff000000000000),UINT64_C(0xbfff000000000000),UINT64_C(0x7fff000000000000),UINT64_C(0xffff000000000000),0,UINT64_C(0x7ffeffffffffffff),UINT64_C(0x7fff800000000000),UINT64_C(0x7fff000000000000)};hi=high[kind];lo=kind==7?UINT64_MAX:kind>=6?1:0;}
    memcpy(out,&lo,8);memcpy(out+8,&hi,8);
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned first=seed%10,second=(seed+3)%10;size_t stride=item->bits>=80?16:item->bits/8;memset(input,0,stride*item->kind);boolean_float_input(item->bits,first,input);if(item->kind==2)boolean_float_input(item->bits,second,input+stride);
    uint64_t result=first<8&&(item->kind==1||second<8),token=clobber_model(salt);memcpy(gold,&result,8);memcpy(gold+8,&token,8);
    return (struct test_model){stride*item->kind,1,16,SIZE_MAX,255,result^token};
}
