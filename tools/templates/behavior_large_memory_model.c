static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;size_t bytes=(item->bits+7)/8;unsigned mask=item->bits%8?(1u<<(item->bits%8))-1:255;
    uint64_t state=seed+UINT64_C(0x123456789abcdef1);
    for(size_t j=0;j<bytes;j++){state=state*UINT64_C(6364136223846793005)+1;input[j]=seed==0?0:seed==1?255:seed==2?0xaa:seed==3?0x55:(unsigned char)(state>>32);}
    if(seed==4){memset(input,0,bytes);input[0]=1;}
    if(seed==5){memset(input,0,bytes);input[(item->bits-1)/8]=(unsigned char)(1u<<((item->bits-1)%8));}
    /* Non-byte-sized LLVM loads require zero padding for a defined value. */
    input[bytes-1]&=(unsigned char)mask;
    unsigned all_ones=1;for(size_t j=0;j<bytes;j++){unsigned m=j+1==bytes?mask:255;all_ones&=(input[j]&m)==m;}
    memcpy(gold,input,bytes);gold[bytes-1]&=(unsigned char)mask;memset(gold+bytes,0,8);
    return (struct test_model){bytes,1,bytes+8,bytes-1,mask,salt^all_ones};
}
