#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <float.h>

_Static_assert(sizeof(float)==4&&sizeof(double)==8&&sizeof(quad)==16,"requires IEEE scalar carriers");
_Static_assert(sizeof(long double)==16&&LDBL_MANT_DIG==64&&LDBL_MAX_EXP==16384,"requires extended80 ABI");
struct format {unsigned bits,exponent,precision,bias,explicit_bit;};
static const struct format formats[]={ {16,5,11,15,0},{32,8,24,127,0},{64,11,53,1023,0},{128,15,113,16383,0},{80,15,64,16383,1} };
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static u128 mask(unsigned n){return n==128?~(u128)0:((u128)1<<n)-1;}
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x88123456789abcde);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
static u128 read_bits(const uint8_t *p,unsigned n){u128 v=0;for(unsigned i=0;i<n;++i)v|=(u128)p[i]<<(8*i);return v;}
static void write_bits(uint8_t *p,u128 v,unsigned n){for(unsigned i=0;i<n;++i)p[i]=(uint8_t)(v>>(8*i));}
__attribute__((noinline)) uint64_t extended80_float_clobber(uint64_t seed){
    uint64_t result=seed^key;
    __asm__ volatile(
        "xor %%eax,%%eax\n\txor %%ecx,%%ecx\n\txor %%edx,%%edx\n\t"
        "xor %%edi,%%edi\n\txor %%esi,%%esi\n\txor %%r8d,%%r8d\n\t"
        "xor %%r9d,%%r9d\n\txor %%r10d,%%r10d\n\txor %%r11d,%%r11d\n\t"
        "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\tpxor %%xmm2,%%xmm2\n\t"
        "pxor %%xmm3,%%xmm3\n\tpxor %%xmm4,%%xmm4\n\tpxor %%xmm5,%%xmm5\n\t"
        "pxor %%xmm6,%%xmm6\n\tpxor %%xmm7,%%xmm7\n\tpxor %%xmm8,%%xmm8\n\t"
        "pxor %%xmm9,%%xmm9\n\tpxor %%xmm10,%%xmm10\n\tpxor %%xmm11,%%xmm11\n\t"
        "pxor %%xmm12,%%xmm12\n\tpxor %%xmm13,%%xmm13\n\tpxor %%xmm14,%%xmm14\n\tpxor %%xmm15,%%xmm15"
        :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");
    return result;
}
static unsigned exponent(u128 raw,struct format f){return(unsigned)((raw>>(f.explicit_bit?64:f.precision-1))&mask(f.exponent));}
static int is_nan(u128 raw,struct format f){return exponent(raw,f)==(unsigned)mask(f.exponent)&&(raw&mask(f.precision-1))!=0&&(!f.explicit_bit||(raw&((u128)1<<63)));}
static u128 special(struct format f,unsigned sign,unsigned nan){
    return ((u128)sign<<(f.bits-1))|(mask(f.exponent)<<(f.explicit_bit?64:f.precision-1))|
        (f.explicit_bit?((u128)1<<63):0)|(nan?((u128)1<<(f.precision-2)):0);
}
static u128 rounded_shift(u128 value,int shift){
    if(shift<=0)return value<<-shift;
    if(shift>=128)return 0;
    u128 q=value>>shift,remainder=value&mask((unsigned)shift),halfway=(u128)1<<(shift-1);
    return q+(remainder>halfway||(remainder==halfway&&(q&1)));
}
/* Exact dyadic decode followed by a single integer round-to-nearest/even. */
static u128 convert_bits(u128 raw,struct format from,struct format to){
    unsigned sign=(unsigned)((raw>>(from.bits-1))&1),e=exponent(raw,from);
    if(e==(unsigned)mask(from.exponent))return special(to,sign,is_nan(raw,from));
    u128 significand=raw&mask(from.precision-1);
    if(e)significand|=(u128)1<<(from.precision-1);
    if(!significand)return(u128)sign<<(to.bits-1);
    unsigned top=0;for(u128 scan=significand;scan>>=1;)++top;
    int scale=(e?(int)e:1)-(int)from.bias-(int)from.precision+1;
    int value_exponent=scale+(int)top,minimum=1-(int)to.bias,maximum=(int)to.bias;
    if(value_exponent>maximum)return special(to,sign,0);
    int last_bit=(value_exponent<minimum?minimum:value_exponent)-(int)to.precision+1;
    u128 rounded=rounded_shift(significand,last_bit-scale);
    if(!rounded)return(u128)sign<<(to.bits-1);
    unsigned encoded;
    if(value_exponent<minimum){encoded=rounded>=((u128)1<<(to.precision-1));}
    else{
        if(rounded==((u128)1<<to.precision)){rounded>>=1;++value_exponent;}
        if(value_exponent>maximum)return special(to,sign,0);
        encoded=(unsigned)(value_exponent+(int)to.bias);
    }
    return((u128)sign<<(to.bits-1))|((u128)encoded<<(to.explicit_bit?64:to.precision-1))|
        (rounded&mask(to.explicit_bit?to.precision:to.precision-1));
}
static u128 input_bits(unsigned source,unsigned target,unsigned row){
    struct format from=formats[source],to=formats[target];
    u128 raw=((u128)random_word()<<64)|random_word();raw&=mask(from.bits);
    if(source==0)return row;
    if(row<from.bits)raw=(u128)1<<row;
    else if(row<2*from.bits)raw=mask(from.bits)^((u128)1<<(row-from.bits));
    else if((row&3)==0){
        int minimum=1-(int)to.bias,maximum=(int)to.bias;
        int edges[]={minimum-2,minimum-1,minimum,minimum+1,-1,0,1,maximum-1,maximum,maximum+1,maximum+2};
        int e=edges[(row/4)%11]+(int)from.bias;
        if(e>0&&e<(int)mask(from.exponent)){
            u128 fraction=raw&mask(from.precision-1);
            int shift=(int)from.precision-(int)to.precision;
            int unbiased=e-(int)from.bias;if(unbiased<minimum)shift+=minimum-unbiased;
            if(shift>0&&shift<(int)from.precision){
                u128 half=(u128)1<<(shift-1),low;
                switch((row/44)%5){case 0:low=0;break;case 1:low=half-1;break;case 2:low=half;break;case 3:low=half+1;break;default:low=mask((unsigned)shift);}
                fraction=(fraction&~mask((unsigned)shift))|low;
            }
            raw=(raw&((u128)1<<(from.bits-1)))|((u128)e<<(from.explicit_bit?64:from.precision-1))|fraction;
        }
    }
    if(from.explicit_bit){if(exponent(raw,from))raw|=(u128)1<<63;else raw&=~((u128)1<<63);}
    return raw;
}
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"extended80 float mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int guards(const uint8_t *p,unsigned size,unsigned used){if(p[0]!=0xa7)return 0;for(unsigned i=used+1;i<size;++i)if(p[i]!=0xa7)return 0;return 1;}
static int check_conversion(uint8_t *end,unsigned which,unsigned row){
    const struct conversion_case *test=&cases[which];struct format from=formats[test->source],to=formats[test->target];
    u128 raw=input_bits(test->source,test->target,row),expected=convert_bits(raw,from,to);
    unsigned input_size=(from.bits+7)/8,output_size=(to.bits+7)/8;
    uint8_t *input=end-input_size;write_bits(input,raw,input_size);uint8_t original[16];memcpy(original,input,input_size);
    uint64_t live=(uint64_t)raw^(uint64_t)(raw>>64)^row;uint8_t out[32];memset(out,0xa7,sizeof out);
    u128 actual=test->function(input,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[output_size+1]^=1;
    u128 converted=read_bits(out+1,output_size);
    if(actual!=(raw^(live^key)))return mismatch(which,row,"live-bits");
    if(is_nan(expected,to)?!is_nan(converted,to):converted!=expected)return mismatch(which,row,"rounding");
    if(!guards(out,sizeof out,output_size))return mismatch(which,row,"guards");
    if(memcmp(original,input,input_size))return mismatch(which,row,"input-mutated");
    ++observations;return 0;
}

static uint64_t scalar_mix(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g){return((((((a^key)^b)+c)^d)+e)^f)+g;}
static void mixed_stores(uint8_t *out,u128 x,u128 y,u128 q,uint64_t d0,uint32_t f0,uint64_t d1){
    write_bits(out,x,10);write_bits(out+10,y,10);write_bits(out+20,q,16);
    write_bits(out+36,d0,8);write_bits(out+44,f0,4);write_bits(out+48,d1,8);
}
__attribute__((noinline)) long double extended80_mixed_provider(
        uint64_t a,double d0,long double x,uint64_t b,float f0,uint64_t c,double d1,
        uint64_t d,uint64_t e,uint64_t f,uint64_t g,long double y,quad q,uint8_t *out){
    u128 xb=read_bits((const uint8_t*)&x,10),yb=read_bits((const uint8_t*)&y,10),qb;
    uint64_t d0b,d1b;uint32_t f0b;
    memcpy(&qb,&q,16);memcpy(&d0b,&d0,8);memcpy(&d1b,&d1,8);memcpy(&f0b,&f0,4);
    uint64_t scalar=scalar_mix(a,b,c,d,e,f,g);
    mixed_stores(out,xb,yb,qb,d0b,f0b,d1b);
    u128 raw=(xb^yb^qb^d0b^f0b^d1b^scalar)&mask(80);
    extended80_float_clobber(scalar);
    uint8_t result[16]={0};write_bits(result,raw,10);long double value;memcpy(&value,result,16);return value;
}
static int check_mixed(uint8_t *end,unsigned row,unsigned caller){
    u128 x=(((u128)random_word()<<64)|random_word())&mask(80);
    u128 y=(((u128)random_word()<<64)|random_word())&mask(80);
    u128 q=((u128)random_word()<<64)|random_word();
    uint64_t d0b=random_word(),d1b=random_word(),live=random_word();uint32_t f0b=(uint32_t)random_word();
    uint8_t *input=end-68;memset(input,0x39,68);
    write_bits(input,x,10);write_bits(input+16,y,10);write_bits(input+32,q,16);
    write_bits(input+48,d0b,8);write_bits(input+56,f0b,4);write_bits(input+60,d1b,8);
    uint8_t original[68];memcpy(original,input,68);
    uint8_t xb[16]={0},yb[16]={0};write_bits(xb,x,10);write_bits(yb,y,10);
    long double xf,yf;quad qf;double d0,d1;float f0;
    memcpy(&xf,xb,16);memcpy(&yf,yb,16);memcpy(&qf,&q,16);
    memcpy(&d0,&d0b,8);memcpy(&d1,&d1b,8);memcpy(&f0,&f0b,4);
    uint64_t a=live,b=13,c=17,d=19,e=23,f=29,g=31;
    if(!caller){b=~live;c=d0b;d=~d1b;e=live+19;f=d1b^31;g=~d0b;}
    u128 combination=x^y^q^d0b^f0b^d1b^scalar_mix(a,b,c,d,e,f,g);
    u128 expected=caller?((combination&mask(80))^q^(live^key)):combination;
    unsigned used=caller?66:56;
    uint8_t out[80],expected_stores[66];memset(out,0xa7,sizeof out);
    mixed_stores(expected_stores,x,y,q,d0b,f0b,d1b);
    if(caller)write_bits(expected_stores+56,combination&mask(80),10);
    unsigned short before,after;__asm__ volatile("fnstsw %0":"=am"(before));
    u128 actual=caller?extended80_mixed_call(input,out+1,live):
        extended80_mixed_incoming(a,d0,xf,b,f0,c,d1,d,e,f,g,yf,qf,out+1);
    __asm__ volatile("fnstsw %0":"=am"(after));
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[used+1]^=1;
    if(actual!=expected)return mismatch(10+caller,row,"mixed-return");
    if(memcmp(out+1,expected_stores,used))return mismatch(10+caller,row,"mixed-stores");
    if((before^after)&0x3800)return mismatch(10+caller,row,"mixed-x87-depth");
    if(!guards(out,sizeof out,used))return mismatch(10+caller,row,"mixed-guards");
    if(memcmp(original,input,68))return mismatch(10+caller,row,"mixed-input-mutated");
    ++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;
    long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)
        for(unsigned row=0;row<cases[which].rows;++row)if(check_conversion(mapping+page,which,row))return 1;
    for(unsigned caller=0;caller<2;++caller)for(unsigned row=0;row<4096;++row)if(check_mixed(mapping+page,row,caller))return 1;
    if(observations!=204800)return mismatch(0,0,"count");
    if(munmap(mapping,(size_t)page*2))return 2;
    puts("extended80-float observations=204800 rounding=subnormal=nan=mixed-abi=live=guards=preserved");return 0;
}
