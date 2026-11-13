static void floating_hint_lane(unsigned bits,unsigned kind,unsigned char *out){
    uint64_t low=0,high=0;
    if(bits==64){static const uint64_t values[]={UINT64_C(0x3ff0000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x7ff8000000000001),UINT64_C(0xc000000000000000),0,1,UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000)};memcpy(out,&values[kind],8);return;}
    if(bits==80){static const uint64_t fraction[]={UINT64_C(0x8000000000000000),0,UINT64_C(0xc000000000000000),UINT64_C(0x8000000000000000),0,1,UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000)};static const uint16_t exponent[]={0x3fff,0x8000,0x4000,0xbfff,0,0,0x7fff,0xffff};memcpy(out,&fraction[kind],8);memcpy(out+8,&exponent[kind],2);return;}
    {static const uint64_t upper[]={UINT64_C(0x3fff000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x40007fff00000000),UINT64_C(0xc000000000000000),0,0,UINT64_C(0x7fff000000000000),UINT64_C(0xffff000000000000)};high=upper[kind];low=kind==2||kind==5?1:0;}
    memcpy(out,&low,8);memcpy(out+8,&high,8);
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned arity=item->kind/2,literal=item->kind%2;size_t bytes=item->bits/8,payload=4*arity*bytes;
    for(unsigned i=0;i<4*arity;i++){floating_hint_lane(item->bits,(seed+i)%8,input+i*bytes);floating_hint_lane(item->bits,literal?i%4:(seed+i)%8,gold+i*bytes);}
    uint64_t token=clobber_model(salt);memcpy(gold+payload,&token,8);memcpy(gold+payload+8,gold,payload);memcpy(gold+2*payload+8,&token,8);
    return (struct test_model){payload,1,2*payload+16,SIZE_MAX,255,token^salt};
}
