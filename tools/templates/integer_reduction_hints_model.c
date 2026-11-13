static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned bits=item->bits,count=item->kind/2,literal=item->kind%2,bytes=bits/8;unsigned __int128 mask=bits==128?~(unsigned __int128)0:((unsigned __int128)1<<bits)-1,product=1;
    for(unsigned i=0;i<count;i++){
        unsigned __int128 value=(((unsigned __int128)(seed+1)*UINT64_C(0x9182736455aaccdd))<<64)^((unsigned __int128)i*UINT64_C(0x123456789abcdef1))^seed;
        if(seed==0)value=0;if(seed==1)value=mask;if(seed==2)value=3;if(seed==3)value=(unsigned __int128)1<<(bits-1);value&=mask;
        for(unsigned j=0;j<bytes;j++)input[i*bytes+j]=(unsigned char)(value>>(8*j));
        product=(product*(literal?2*((i+1)%7)+1:value))&mask;
    }
    for(unsigned j=0;j<bytes;j++)gold[j]=(unsigned char)(product>>(8*j));uint64_t token=clobber_model(salt);memcpy(gold+bytes,&token,8);
    return (struct test_model){count*bytes,1,bytes+8,SIZE_MAX,255,token};
}
