static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;size_t bytes=item->bits/8;uint64_t state=seed+UINT64_C(0xfedcba9876543211);
    for(size_t i=0;i<bytes;i++){state=state*UINT64_C(6364136223846793005)+1;input[i]=(unsigned char)(state>>32);gold[i]=input[i];gold[bytes+i]=input[i]^0x5a;}
    return (struct test_model){bytes,1,bytes*2,SIZE_MAX,255,clobber_model(salt)};
}
