static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned lanes=item->kind%128,kind=item->kind/128,bytes=item->bits/8;size_t payload=(size_t)lanes*bytes;
    uint64_t state=seed+UINT64_C(0x123456789abcdef1);
    for(unsigned lane=0;lane<lanes;lane++){
        unsigned char *value=input+lane*bytes;
        if(kind<3){int n=kind==0?4+(int)((seed+lane)%17):kind==1?(int)((seed+lane)%10)-5:(int)((seed+lane)%8)-4;memset(value,n<0?255:0,bytes);value[0]=(unsigned char)n;}
        else{unsigned nonzero=0;for(unsigned b=0;b<bytes;b++){state=state*UINT64_C(6364136223846793005)+1;value[b]=(unsigned char)(state>>32);nonzero|=value[b];}if(!nonzero)value[0]=1;}
    }
    uint64_t token=clobber_model(salt);memcpy(gold,input,payload);memcpy(gold+payload,&token,8);
    return (struct test_model){lanes==3?16:payload,1,payload+8,SIZE_MAX,255,token^salt};
}
