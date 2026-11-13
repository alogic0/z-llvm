static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;uint64_t state=seed+UINT64_C(0x123456789abcdef1),sum=0,first=0;unsigned count=item->kind?item->kind%16:1;
    for(unsigned i=0;i<count;i++){state=state*UINT64_C(6364136223846793005)+1;memcpy(input+i*8,&state,8);memcpy(gold+i*8,&state,8);sum+=state;if(!i)first=state;}
    uint64_t token=clobber_model(salt);if(!item->kind){memcpy(gold+8,&token,8);return (struct test_model){8,1,16,SIZE_MAX,255,token};}
    if(item->kind>=16)sum+=first;return (struct test_model){count*8,1,count*8,SIZE_MAX,255,sum^token};
}
