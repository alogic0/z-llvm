extern unsigned char pointer_order_global[128];
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned form=item->kind/8,predicate=item->kind%8;
    static const uint64_t edges[8]={0,1,4095,UINT64_C(0x7fffffffffffffff),UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000001),UINT64_MAX-1,UINT64_MAX};
    uint64_t left=seed<32?edges[seed%8]:(seed+1)*UINT64_C(0x9182736455aaccdd),right=seed<32?edges[(seed/8+seed)%8]:~left;
    if(form==1||form==3){left=seed%64;right=(seed*17+7)%64;}
    if(form==2){left=0;right=seed%64;}
    if(form==4)left=0;
    if(form==5)left=UINT64_C(0x8000000000000000);
    if(form==6)left=(uintptr_t)pointer_order_global;
    if(form==7){left=31;right=seed%64;}
    if(form==8)right=0;
    if(form==9)right=UINT64_MAX;
    memcpy(input,&left,8);memcpy(input+8,&right,8);
    uint64_t x=left,y=right;if(predicate>=4){x^=UINT64_C(0x8000000000000000);y^=UINT64_C(0x8000000000000000);}
    uint64_t result=predicate%4==0?x<y:predicate%4==1?x<=y:predicate%4==2?x>y:x>=y;
    uint64_t delta=right-left,token=clobber_model(salt);
    memcpy(gold,&result,8);memcpy(gold+8,&delta,8);memcpy(gold+16,&token,8);
    return (struct test_model){128,1,24,SIZE_MAX,255,token^result};
}
