static int check_value(uint64_t actual,uint64_t expected,const char *name) {
    if(inject_fault==1)actual^=1;
    if(actual!=expected) {
        fprintf(stderr,"integer ABI entry mismatch function=%s actual=%llx expected=%llx fault=%u\n",name,(unsigned long long)actual,(unsigned long long)expected,inject_fault);
        return 1;
    }
    ++observations;
    return 0;
}
static int check_wrapper(const struct wrapper *test,uint64_t a,uint64_t b,uint64_t salt,const uint64_t *args) {
    uint64_t box[6]={abi_key,0,0,0,0,abi_key^1},*out=box+1;
    uint64_t low,high,nested,probe=salt^abi_key;
    if(test->words) {
        low=nested=word_expected(args,test->words); high=0;
    } else {
        u128 wide=test->constant ? mask_bits(test->bits) : (((u128)b<<64)|a)&mask_bits(test->bits);
        uint64_t hash=weighted(args,test->prefix)+salt*19;
        u128 result=wide_expected(wide,hash,test->bits);
        low=(uint64_t)result; high=(uint64_t)(result>>64);
        nested=entry_expected(args,test->prefix,result,salt,test->bits);
    }
    uint64_t expected=low^high^nested^probe^a^b^salt;
    uint64_t actual=test->run(a,b,salt,out);
    if(inject_fault==1)actual^=1;
    if(inject_fault>=2&&inject_fault<=5)out[inject_fault-2]^=1;
    if(inject_fault==6)box[0]^=1;
    if(inject_fault==7)box[5]^=1;
    if(actual!=expected||out[0]!=low||out[1]!=high||out[2]!=nested||out[3]!=probe||box[0]!=abi_key||box[5]!=(abi_key^1)) {
        fprintf(stderr,"integer ABI call mismatch words=%u bits=%u prefix=%u constant=%u a=%llx b=%llx salt=%llx actual=%llx expected=%llx fields=%llx,%llx,%llx,%llx expected_fields=%llx,%llx,%llx,%llx fault=%u\n",test->words,test->bits,test->prefix,test->constant,(unsigned long long)a,(unsigned long long)b,(unsigned long long)salt,(unsigned long long)actual,(unsigned long long)expected,(unsigned long long)out[0],(unsigned long long)out[1],(unsigned long long)out[2],(unsigned long long)out[3],(unsigned long long)low,(unsigned long long)high,(unsigned long long)nested,(unsigned long long)probe,inject_fault);
        return 1;
    }
    ++observations;
    return 0;
}
