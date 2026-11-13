static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;size_t bytes=item->kind<2?item->bits/8:8;uint64_t state=seed+UINT64_C(0xfedcba9876543211);
    for(size_t i=0;i<bytes;i++){state=state*UINT64_C(6364136223846793005)+1;input[i]=(unsigned char)(state>>32);}
    uint64_t token=clobber_model(salt);
    if(item->kind<2){for(size_t i=0;i<bytes;i++){unsigned char before=item->kind?0xa5:input[i];gold[i]=before;gold[bytes+i]=before^0x5a;}return (struct test_model){bytes,1,bytes*2,SIZE_MAX,255,token};}
    uint64_t value;if(item->kind==7){uint32_t v;memcpy(&v,input,4);value=v+UINT32_C(13);}else{uint64_t values[]={UINT64_MAX-122,0,123,item->bits==32?UINT64_C(0x80000000):UINT64_C(0x8000000000000000),item->bits==32?UINT64_C(0xffffffff):UINT64_MAX};value=values[item->kind-2];if(item->bits==32)value=(uint32_t)value;}
    memcpy(gold,&value,8);memcpy(gold+8,&token,8);return (struct test_model){8,1,16,SIZE_MAX,255,token^value};
}
