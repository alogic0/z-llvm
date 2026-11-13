static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;size_t bytes=item->bits/8,half=bytes/2;
    for(size_t j=0;j<bytes;j++)input[j]=(unsigned char)(seed*37+j*83+(j>>1)*127);
    memcpy(gold,input+(salt&1)*half,half);memset(gold+half,0,8);
    return (struct test_model){bytes,1,half+8,SIZE_MAX,255,salt};
}
