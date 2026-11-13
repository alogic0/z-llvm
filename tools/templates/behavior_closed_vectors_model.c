static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    unsigned width=item->bits,bytes=width/8;size_t payload=64*bytes;
    for(unsigned lane=0;lane<64;lane++){
        unsigned char *p=input+lane*bytes;
        for(unsigned j=0;j<bytes;j++)p[j]=(unsigned char)(seed*37+lane*83+j*127);
        if(seed<258){
            memset(p,seed==1||seed>=130?255:0,bytes);
            if(seed>=2){unsigned bit=((seed<130?seed-2:seed-130)+lane)%width;p[bit/8]^=(unsigned char)(1u<<(bit%8));}
        }
        unsigned count=0;
        for(unsigned bit=0;bit<width;bit++){
            unsigned index=item->kind?width-1-bit:bit;
            if((p[index/8]>>(index%8))&1)break;count++;
        }
        uint32_t n=count;memcpy(expected+lane*4,&n,4);memcpy(gold+lane*4,&n,4);
    }
    memcpy(gold+256,input,payload);memset(gold+256+payload,0,8);
    return (struct test_model){payload,256,256+payload+8,SIZE_MAX,255,clobber_model(salt)};
}
