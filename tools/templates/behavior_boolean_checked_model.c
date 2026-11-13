#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run;unsigned n,kind;};
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[3];
    for(unsigned m=0;m<3;m++){
        maps[m]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
        if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;
    }
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
        unsigned n=cases[which].n,k=cases[which].kind,packed=(n+7)/8,extent=n+2*packed;
        unsigned char *a=maps[0]+2*page-n,*b=maps[1]+2*page-n,*out=maps[2]+2*page-extent-8;
        unsigned char sa[64],sb[64],expected[80]={0},guard[8];
        memset(guard,0xa5,8);memset(out-8,0xa5,extent+16);
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;
        unsigned any=0;
        for(unsigned lane=0;lane<n;lane++){
            unsigned x=(seed+lane)&1,y=((seed>>1)+lane/2)&1;
            a[lane]=(unsigned char)((seed*37+lane*82)&254)|x;
            b[lane]=(unsigned char)((seed*93+lane*44)&254)|y;
            int l=k>=3?-(int)x:(int)x,r=k>=3?-(int)y:(int)y;
            int full=k%3==0?l+r:k%3==1?l-r:l*r;
            unsigned raw=(unsigned)full&1;
            unsigned ov=k>=3?(full< -1||full>0):(full<0||full>1);
            expected[lane]=(unsigned char)raw;
            expected[n+lane/8]|=(unsigned char)(ov<<(lane%8));
            expected[n+packed+lane/8]|=(unsigned char)(raw<<(lane%8));any|=ov;
        }
        memcpy(sa,a,n);memcpy(sb,b,n);
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page,PROT_READ))return 2;
        uint64_t salt=UINT64_C(0xfedcba9876543211)*seed,answer=cases[which].run(out,a,b,salt);
        if(fault==1)out[0]^=1;if(fault==2)out[n]^=1;if(fault==3)out[extent]^=1;
        int flags=1,wrapped=1;
        for(unsigned j=0;j<packed;j++){
            unsigned mask=j+1==packed&&n%8?(1u<<(n%8))-1:255;
            flags&=(out[n+j]&mask)==(expected[n+j]&mask);
            wrapped&=(out[n+packed+j]&mask)==(expected[n+packed+j]&mask);
        }
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"boolean-checked case=%zu n=%u kind=%u seed=%u observation=%zu fault=%u\n",which,n,k,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==(salt^any));CHECK(memcmp(out,expected,n)==0);CHECK(flags);CHECK(wrapped);
        CHECK(memcmp(out-8,guard,8)==0);CHECK(memcmp(out+extent,guard,8)==0);
        CHECK(memcmp(a,sa,n)==0);CHECK(memcmp(b,sb,n)==0);
#undef CHECK
    }
    printf("boolean-checked observations=%zu exhaustive-one-bit-pairs=signed-unsigned=packed-flags=canonical-lanes=readonly-inputs=guard-pages=preserved\n",observations);
    for(unsigned m=0;m<3;m++)if(munmap(maps[m],page*3))return 2;
    return 0;
}
