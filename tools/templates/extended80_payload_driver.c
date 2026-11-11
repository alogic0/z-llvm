#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <float.h>

_Static_assert(sizeof(long double)==16 && LDBL_MANT_DIG==64 && LDBL_MAX_EXP==16384,"requires x86-64 extended80 ABI");

static const u128 mask80 = ((u128)1<<80)-1;
static const uint64_t key = UINT64_C(0x9e3779b97f4a7c15);
static unsigned observations, fault;

__attribute__((noinline)) uint64_t extended80_payload_clobber(uint64_t seed) {
    uint64_t result=seed^key;
    __asm__ volatile(
        "xor %%eax,%%eax\n\txor %%ecx,%%ecx\n\txor %%edx,%%edx\n\t"
        "xor %%edi,%%edi\n\txor %%esi,%%esi\n\txor %%r8d,%%r8d\n\t"
        "xor %%r9d,%%r9d\n\txor %%r10d,%%r10d\n\txor %%r11d,%%r11d"
        :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","cc","memory");
    return result;
}

static uint64_t random_word(void) {
    static uint64_t state=UINT64_C(0x88123456789abcde);
    state^=state<<13; state^=state>>7; state^=state<<17;
    return state;
}

static u128 read80(const uint8_t *bytes) {
    u128 result=0;
    for (unsigned i=0;i<10;++i) result|=(u128)bytes[i]<<(8*i);
    return result;
}

static void write80(uint8_t *bytes,u128 value) {
    for (unsigned i=0;i<10;++i) bytes[i]=(uint8_t)(value>>(8*i));
}

__attribute__((noinline)) long double extended80_call_provider(
        uint64_t a,long double x,uint64_t b,uint64_t c,uint64_t d,uint64_t e,
        uint64_t f,uint64_t g,long double y,long double z,uint8_t *observed) {
    uint8_t xb[16],yb[16],zb[16],result[16]={0};
    memcpy(xb,&x,16); memcpy(yb,&y,16); memcpy(zb,&z,16);
    uint64_t mix=((((((a^key)^b)+c)^d)+e)^f)+g;
    u128 raw=read80(xb)^read80(yb)^read80(zb)^mix;
    write80(observed,raw); write80(result,raw);
    extended80_payload_clobber(mix);
    long double value; memcpy(&value,result,16);
    return value;
}

static int mismatch(unsigned which,unsigned row,const char *stage) {
    fprintf(stderr,"extended80 payload mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",
            which,row,stage,fault,observations);
    return 1;
}

static int check(uint8_t *source,unsigned which,unsigned row,unsigned index,unsigned choice) {
    u128 raw=((u128)random_word()<<64)|random_word(), payload=raw&mask80;
    if (row<80) payload=(u128)1<<row;
    else if (row<160) payload=mask80^((u128)1<<(row-80));
    else if (row==160) payload=0;
    else if (row==161) payload=mask80;
    else if (row==162) payload=((u128)0x7fff<<64)|((u128)1<<63)|1;
    raw=(raw&~mask80)|payload;
    u128 a=payload^(((u128)0x1234<<64)|UINT64_C(0x56789abcdef00123));
    u128 b=(((payload>>17)|(payload<<63))&mask80)^(((u128)0x89ab<<64)|UINT64_C(0xcdef123456789001));
    memset(source,0x39,26);
    write80(source,a); write80(source+16,b);
    uint8_t source_before[26]; memcpy(source_before,source,26);
    const uint8_t *input=which==1?source:source+16;
    u128 expected=which==1?(index?b:a):b;
    if ((which==3||which==4)&&!choice) expected=payload;
    if (which==7) expected=((u128)0x7fff<<64)|((u128)1<<63)|1;
    uint64_t live=(uint64_t)raw^(uint64_t)(raw>>64)^row;
    uint64_t extra=~live+UINT64_C(0x445566778899aabb);
    uint64_t mixed=(((live^key)^extra)+index)^choice;
    uint8_t guarded[32]; memset(guarded,0xa7,sizeof guarded);
    uint8_t *out=guarded+1;
    u128 actual=cases[which](input,out,raw,index,choice,live,extra);
    if (fault==1) actual^=1;
    if (fault==2) out[0]^=1;
    if (fault==3) out[20]^=1;
    u128 decoded=actual^raw^mixed, first=read80(out), second=read80(out+10);
    if (decoded>mask80||decoded!=first) return mismatch(which,row,"return-live");
    if (first!=second) return mismatch(which,row,"stable-freeze");
    if (which!=5&&which!=6&&first!=expected) return mismatch(which,row,"defined-bits");
    if (guarded[0]!=0xa7) return mismatch(which,row,"prefix-guard");
    for (unsigned i=21;i<sizeof guarded;++i)
        if (guarded[i]!=0xa7) return mismatch(which,row,"suffix-guard");
    if (memcmp(source,source_before,26)) return mismatch(which,row,"input-mutated");
    ++observations;
    return 0;
}

static int check_incoming(unsigned row,unsigned index,unsigned choice) {
    u128 x=(((u128)random_word()<<64)|random_word())&mask80;
    u128 y=(((u128)random_word()<<64)|random_word())&mask80;
    uint8_t xb[16]={0},yb[16]={0};
    write80(xb,x); write80(yb,y);
    long double xf,yf;
    memcpy(&xf,xb,16); memcpy(&yf,yb,16);
    uint64_t a=(uint64_t)x^row,b=UINT64_C(0x123456789abcdef0)^index,c=~a;
    uint64_t d=UINT64_C(0x9e3779b97f4a7c15)^choice,e=UINT64_C(0xaabbccddeeff0011);
    uint64_t f=UINT64_C(0x1122334455667788),g=~b;
    uint64_t mixed=((((((a^key)^b)+c)^d)+e)^f)+g;
    u128 expected=x^y^mixed;
    uint8_t guarded[32]; memset(guarded,0xa7,sizeof guarded);
    uint8_t *out=guarded+1;
    u128 actual=extended80_incoming(a,xf,b,c,d,e,f,g,yf,out);
    if (fault==1) actual^=1;
    if (fault==2) out[0]^=1;
    if (fault==3) out[20]^=1;
    if (actual!=expected) return mismatch(8,row,"incoming-return-live");
    if (read80(out)!=x||read80(out+10)!=y) return mismatch(8,row,"incoming-stores");
    if (guarded[0]!=0xa7) return mismatch(8,row,"incoming-prefix");
    for (unsigned i=21;i<sizeof guarded;++i)
        if (guarded[i]!=0xa7) return mismatch(8,row,"incoming-suffix");
    ++observations;
    return 0;
}

static int check_return(uint8_t *source,unsigned which,unsigned row,unsigned index,unsigned choice) {
    u128 x=(((u128)random_word()<<64)|random_word())&mask80;
    u128 y=(((u128)random_word()<<64)|random_word())&mask80;
    if (row<80) x=(u128)1<<row;
    else if (row<160) x=mask80^((u128)1<<(row-80));
    else if (row==160) x=0;
    else if (row==161) x=mask80;
    else if (row==162) x=((u128)0x7fff<<64)|((u128)1<<63)|1;
    else if (row==163) x=(u128)0x8000<<64;
    uint8_t xb[16]={0},yb[16]={0};
    write80(xb,x); write80(yb,y); write80(source+16,x);
    long double xf,yf,result;
    memcpy(&xf,xb,16); memcpy(&yf,yb,16);
    uint64_t live=(uint64_t)x^row^((uint64_t)index<<32)^choice;
    uint8_t guarded[24]; memset(guarded,0xa7,sizeof guarded);
    uint8_t *out=guarded+1;
    unsigned short before,after;
    __asm__ volatile("fnstsw %0":"=am"(before));
    if (which==0) result=extended80_return_load(source+16,out,live);
    else if (which==1) result=extended80_return_phi(live,xf,yf,choice,out);
    else result=extended80_return_constant(out,live);
    uint8_t returned[16]; memcpy(returned,&result,16);
    __asm__ volatile("fnstsw %0":"=am"(after));
    u128 actual=read80(returned);
    u128 expected=which==0?x:which==1?(choice?x:y):(((u128)0x7fff<<64)|((u128)1<<63)|1);
    if (fault==1) actual^=1;
    if (fault==2) out[0]^=1;
    if (fault==3) out[8]^=1;
    uint64_t stored; memcpy(&stored,out,8);
    if (actual!=expected) return mismatch(9+which,row,"x87-return-bits");
    if (stored!=(live^key)) return mismatch(9+which,row,"x87-return-live");
    if ((before^after)&0x3800) return mismatch(9+which,row,"x87-stack-depth");
    if (guarded[0]!=0xa7) return mismatch(9+which,row,"return-prefix");
    for (unsigned i=9;i<sizeof guarded;++i)
        if (guarded[i]!=0xa7) return mismatch(9+which,row,"return-suffix");
    ++observations;
    return 0;
}

static int check_call(uint8_t *source,unsigned row,unsigned index,unsigned choice) {
    u128 raw=((u128)random_word()<<64)|random_word(),z=raw&mask80;
    u128 x=(((u128)random_word()<<64)|random_word())&mask80;
    u128 y=(((u128)random_word()<<64)|random_word())&mask80;
    write80(source,x); write80(source+16,y);
    uint8_t original[26]; memcpy(original,source,26);
    uint64_t live=(uint64_t)raw^row,extra=~live+UINT64_C(0x123456789abcdef0);
    uint64_t first_mix=((((((live^key)^index)+extra)^live)+index)^extra)+live;
    uint64_t second_mix=((((((extra^key)^index)+live)^extra)+index)^live)+extra;
    u128 first=x^y^z^first_mix,second=x^y^z^second_mix;
    uint64_t mixed=(((live^key)^extra)+index)^choice;
    uint8_t guarded[40]; memset(guarded,0xa7,sizeof guarded);
    uint8_t *out=guarded+1;
    unsigned short before,after;
    __asm__ volatile("fnstsw %0":"=am"(before));
    u128 actual=extended80_call(source,out,raw,index,choice,live,extra);
    __asm__ volatile("fnstsw %0":"=am"(after));
    if (fault==1) actual^=1;
    if (fault==2) out[0]^=1;
    if (fault==3) out[30]^=1;
    if (actual!=(first^raw^mixed)) return mismatch(12,row,"call-return-live");
    if (read80(out)!=first||read80(out+10)!=second||read80(out+20)!=first)
        return mismatch(12,row,"call-stores");
    if ((before^after)&0x3800) return mismatch(12,row,"call-x87-depth");
    if (guarded[0]!=0xa7) return mismatch(12,row,"call-prefix");
    for (unsigned i=31;i<sizeof guarded;++i)
        if (guarded[i]!=0xa7) return mismatch(12,row,"call-suffix");
    if (memcmp(source,original,26)) return mismatch(12,row,"call-input-mutated");
    ++observations;
    return 0;
}

int main(int argc,char **argv) {
    if (argc==2) fault=(unsigned)strtoul(argv[1],0,10);
    if (argc>2||fault>3) return 2;
    long page=sysconf(_SC_PAGESIZE);
    if (page<4096) return 2;
    uint8_t *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if (mapping==MAP_FAILED) return 2;
    if (mprotect(mapping+page,(size_t)page,PROT_NONE)) return 2;
    uint8_t *source=mapping+page-26;
    for (unsigned which=0;which<8;++which) for (unsigned row=0;row<1024;++row)
        for (unsigned index=0;index<2;++index) for (unsigned choice=0;choice<2;++choice)
            if (check(source,which,row,index,choice)) return 1;
    for (unsigned row=0;row<1024;++row) for (unsigned index=0;index<2;++index)
        for (unsigned choice=0;choice<2;++choice)
            if (check_incoming(row,index,choice)) return 1;
    for (unsigned which=0;which<3;++which) for (unsigned row=0;row<1024;++row)
        for (unsigned index=0;index<2;++index) for (unsigned choice=0;choice<2;++choice)
            if (check_return(source,which,row,index,choice)) return 1;
    for (unsigned row=0;row<1024;++row) for (unsigned index=0;index<2;++index)
        for (unsigned choice=0;choice<2;++choice)
            if (check_call(source,row,index,choice)) return 1;
    if (observations!=53248) return mismatch(0,0,"count");
    if (munmap(mapping,(size_t)page*2)) return 2;
    puts("extended80-payload observations=53248 bits=storage=freeze=phi=live=stride=abi=page=guards=preserved");
    return 0;
}
