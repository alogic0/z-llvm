__attribute__((noinline)) uint64_t identity_echo(const void *pointer,uint64_t value){
    uint64_t observed;memcpy(&observed,pointer,8);
    return (observed^value)*UINT64_C(0x123456789abcdef1)+complete_clobber(value,2,3,4,5,6,7,8);
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;
    for(unsigned i=0;i<64;i++)input[i]=(unsigned char)(((seed+1)*UINT64_C(0x9182736455aaccdd)>>(8*(i%8)))^(i*71));
    if(seed==0)memset(input,0,64);if(seed==1)memset(input,255,64);
    uint64_t value,threshold=salt+7,chosen,token;memcpy(&value,input+(salt&7),8);
    if(item->kind==0)chosen=value<threshold?value+threshold:value^threshold;
    else if(item->kind==1){uint64_t selected=value<threshold?value:threshold;chosen=(value^selected)*UINT64_C(0x123456789abcdef1)+clobber_model(selected);}
    else chosen=(value&3)==0?value+threshold:(value&3)==1?value^threshold:value-threshold;
    token=clobber_model(salt^chosen);memcpy(gold,&chosen,8);memcpy(gold+8,&token,8);memcpy(gold+16,&value,8);
    return (struct test_model){64,1,24,SIZE_MAX,255,chosen+token+value};
}
