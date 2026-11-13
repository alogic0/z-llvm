/* Independent bit model: no wide C arithmetic or backend limb algorithm. */
struct wide_bits { uint64_t word[4]; };
static unsigned wide_bit(struct wide_bits value,unsigned bit){return (unsigned)((value.word[bit/64]>>(bit%64))&1);}
static void wide_set(struct wide_bits *value,unsigned bit){value->word[bit/64]|=UINT64_C(1)<<(bit%64);}
static struct wide_bits wide_read(const unsigned char *input,unsigned bits){
    struct wide_bits value={{0,0,0,0}};
    for(unsigned bit=0;bit<bits;bit++)if((input[bit/8]>>(bit%8))&1)wide_set(&value,bit);
    return value;
}
static struct wide_bits wide_sat(struct wide_bits value,unsigned bits,unsigned shift,unsigned is_signed){
    struct wide_bits result={{0,0,0,0}};unsigned overflow=0,sign=wide_bit(value,bits-1);
    for(unsigned bit=shift;bit<bits;bit++)if(wide_bit(value,bit-shift))wide_set(&result,bit);
    if(is_signed){
        for(unsigned bit=bits-shift-1;bit<bits;bit++)if(wide_bit(value,bit)!=sign)overflow=1;
    }else{
        for(unsigned bit=bits-shift;bit<bits;bit++)if(wide_bit(value,bit))overflow=1;
    }
    if(overflow){
        memset(&result,0,sizeof result);
        for(unsigned bit=0;bit<bits;bit++)if(!is_signed||((bit==bits-1)==(sign!=0)))wide_set(&result,bit);
    }
    return result;
}
static int wide_cmp(struct wide_bits left,struct wide_bits right,unsigned bits,unsigned is_signed){
    unsigned ls=wide_bit(left,bits-1),rs=wide_bit(right,bits-1);
    if(is_signed&&ls!=rs)return ls?-1:1;
    for(unsigned bit=bits;bit>0;bit--){unsigned l=wide_bit(left,bit-1),r=wide_bit(right,bit-1);if(l!=r)return l?1:-1;}
    return 0;
}
static unsigned wide_pred(unsigned predicate,int comparison){
    switch(predicate){case 0:return comparison==0;case 1:return comparison!=0;case 2:case 6:return comparison>0;case 3:case 7:return comparison>=0;case 4:case 8:return comparison<0;default:return comparison<=0;}
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;
    for(unsigned i=0;i<80;i++)input[i]=(unsigned char)(((seed+1)*UINT64_C(0x9182736455aaccdd)>>(8*(i%8)))^(i*71));
    for(unsigned which=0;which<2;which++){
        unsigned bits=which?200:140,offset=which?32:0,bytes=(bits+7)/8;
        if(seed<8){
            memset(input+offset,0,32);
            if(seed==1)memset(input+offset,255,bytes);
            if(seed==2)input[offset+(bits-1)/8]=(unsigned char)(1U<<((bits-1)%8));
            if(seed==3){memset(input+offset,255,bytes);input[offset+(bits-1)/8]&=(unsigned char)~(1U<<((bits-1)%8));}
            if(seed==4)input[offset+100/8]=(unsigned char)(1U<<(100%8));
            if(seed==5)input[offset]=1;
            if(seed==6)input[offset+128/8]=1;
            if(seed==7)input[offset+bytes-1]=(unsigned char)(255U<<((bits-1)%8+1));
        }
    }
    static const unsigned shifts140[16]={0,1,17,20,38,39,63,64,65,100,127,128,137,138,139,5};
    static const unsigned shifts200[16]={0,1,17,38,63,64,65,100,127,128,139,190,197,198,199,5};
    uint64_t s=shifts140[seed%16],t=shifts200[(seed*5)%16];memcpy(input+64,&s,8);memcpy(input+72,&t,8);
    struct wide_bits a=wide_read(input,140),b=wide_read(input+32,200),constant={{0,0,0,0}},results[6],right[4];wide_set(&constant,100);
    results[0]=wide_sat(a,140,(unsigned)s,0);results[1]=wide_sat(a,140,(unsigned)s,1);
    results[2]=wide_sat(constant,140,(unsigned)s,0);results[3]=wide_sat(constant,140,(unsigned)s,1);
    results[4]=wide_sat(b,200,(unsigned)t,0);results[5]=wide_sat(b,200,(unsigned)t,1);
    memset(right,0,sizeof right);
    for(unsigned bit=0;bit<140;bit++)wide_set(&right[1],bit);
    for(unsigned bit=0;bit<139;bit++)wide_set(&right[2],bit);wide_set(&right[3],139);
    unsigned predicate=item->kind/2;uint64_t mask=0,token=clobber_model(salt);
    for(unsigned lane=0;lane<4;lane++)if(wide_pred(predicate,wide_cmp(results[lane],right[lane],140,predicate>=6)))mask|=UINT64_C(1)<<lane;
    size_t out=0;
    for(unsigned i=0;i<6;i++)for(unsigned word=0;word<(i<4?3U:4U);word++){memcpy(gold+out,&results[i].word[word],8);out+=8;}
    memcpy(gold+160,&mask,8);memcpy(gold+168,&token,8);
    return (struct test_model){80,1,176,SIZE_MAX,255,token^mask};
}
