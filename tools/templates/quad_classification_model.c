static unsigned quad_classification(uint64_t low,uint64_t high){
    unsigned negative=(unsigned)(high>>63),exponent=(unsigned)((high>>48)&32767);uint64_t fraction=low|(high&UINT64_C(0x0000ffffffffffff));
    if(exponent==32767)return fraction?((high&UINT64_C(0x0000800000000000))?2:1):(negative?4:512);
    if(!exponent)return fraction?(negative?16:128):(negative?32:64);
    return negative?8:256;
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned literal=item->kind/1024,mask=item->kind%1024,kind=seed%16;uint64_t low=0,high=0;
    if(literal){static const uint64_t upper[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x7fff800000000000),UINT64_C(0x7fff000000000000)};high=upper[literal-1];low=literal>=3?1:0;}
    else{
        static const uint64_t upper[]={0,0,UINT64_C(0x0000ffffffffffff),UINT64_C(0x0001000000000000),UINT64_C(0x3fff000000000000),UINT64_C(0x7ffeffffffffffff),UINT64_C(0x7fff000000000000),UINT64_C(0x7fff800000000000),UINT64_C(0x7fff000000000000),UINT64_C(0x7fff400000000000),UINT64_C(0x4000123456789abc),UINT64_C(0x0001000000000001),UINT64_C(0x7fffffffffffffff),UINT64_C(0x7fff000000000001),UINT64_C(0x0020000000000000),UINT64_C(0x7000000000000000)};
        high=upper[kind];low=kind==1||kind==8||kind==13?1:kind==2||kind==5||kind==12?UINT64_MAX:0;
        if(seed&16)high|=UINT64_C(0x8000000000000000);if(seed>=32&&kind!=0&&kind!=6)low|=UINT64_C(0x123456789abcdef0);
    }
    memcpy(input,&low,8);memcpy(input+8,&high,8);uint64_t flag=(quad_classification(low,high)&mask)!=0,token=clobber_model(salt);memcpy(gold,&flag,8);memcpy(gold+8,&token,8);memcpy(gold+16,input,16);
    return (struct test_model){16,1,32,SIZE_MAX,255,flag^token};
}
