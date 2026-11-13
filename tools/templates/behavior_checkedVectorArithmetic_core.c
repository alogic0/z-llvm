#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run;unsigned n,bits,kind,zero;};
static uint64_t read_lane(const unsigned char *p,unsigned bytes){uint64_t r=0;for(unsigned i=0;i<bytes;i++)r|=(uint64_t)p[i]<<(8*i);return r;}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[3];for(unsigned m=0;m<3;m++){maps[m]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;}
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
        const struct test_case *item=&cases[which];unsigned n=item->n,bits=item->bits,bytes=bits/8;
        size_t input_size=n*bytes,flag_bytes=(n+7)/8,extent=input_size+flag_bytes;
        unsigned char *a=maps[0]+2*page-input_size,*b=maps[1]+2*page-input_size,*out=maps[2]+2*page-extent-8;
        unsigned char saved_a[256],saved_b[256],expected[272]={0},guards[8];memset(guards,0xa5,8);memset(out-8,0xa5,extent+16);
        uint64_t mask=(UINT64_C(1)<<bits)-1,sign=UINT64_C(1)<<(bits-1);
        uint64_t edges[]={0,1,sign-1,sign,mask-1,mask,mask/3,mask/5};
        unsigned any=0;
        for(unsigned lane=0;lane<n;lane++){
            uint64_t x=seed<8?edges[(seed+lane)%8]:(((uint64_t)seed*UINT64_C(0x9182736455aaccdd))^((uint64_t)lane*UINT64_C(0x123456789abcdef1)))&mask;
            uint64_t y=seed<8?edges[(seed+3+lane*3)%8]:(~x&mask);
            for(unsigned byte=0;byte<bytes;byte++){a[lane*bytes+byte]=(unsigned char)(x>>(byte*8));b[lane*bytes+byte]=(unsigned char)(y>>(byte*8));}
            uint64_t left=item->zero?0:x,raw;unsigned overflow;
            if(item->kind<3){
                uint64_t full=item->kind==0?left+y:item->kind==1?left-y:left*y;
                raw=full&mask;overflow=item->kind==1?left<y:full>mask;
            }else{
                int64_t l=(int64_t)left,r=(int64_t)y;
                if(left&sign)l-=(INT64_C(1)<<bits);if(y&sign)r-=(INT64_C(1)<<bits);
                int64_t full=item->kind==3?l+r:item->kind==4?l-r:l*r;
                raw=(uint64_t)full&mask;overflow=full<-(int64_t)sign||full>(int64_t)(sign-1);
            }
            for(unsigned byte=0;byte<bytes;byte++)expected[lane*bytes+byte]=(unsigned char)(raw>>(byte*8));
            if(overflow)expected[input_size+lane/8]|=(unsigned char)(1u<<(lane%8));any|=overflow;
        }
        memcpy(saved_a,a,input_size);memcpy(saved_b,b,input_size);
        uint64_t salt=UINT64_C(0xfedcba9876543211)*seed,answer=item->run(out,a,b,salt);
        if(fault==1)out[0]^=1;if(fault==2)out[input_size]^=1;if(fault==3)out[extent]^=1;
        int flags_equal=1;for(size_t byte=0;byte<flag_bytes;byte++){
            unsigned byte_mask=(byte+1==flag_bytes&&n%8)?(1u<<(n%8))-1:255;
            flags_equal&=(out[input_size+byte]&byte_mask)==(expected[input_size+byte]&byte_mask);
        }
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"checked-vector case=%zu n=%u bits=%u kind=%u zero=%u seed=%u observation=%zu fault=%u\n",which,n,bits,item->kind,item->zero,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==(salt^any));CHECK(memcmp(out,expected,input_size)==0);CHECK(flags_equal);
        CHECK(memcmp(out-8,guards,8)==0);CHECK(memcmp(out+extent,guards,8)==0);CHECK(memcmp(a,saved_a,input_size)==0);CHECK(memcmp(b,saved_b,input_size)==0);
#undef CHECK
    }
    printf("checked-vector-arithmetic observations=%zu wrapped-lanes=packed-overflow-flags=live-values=exact-stores=guard-pages=preserved\n",observations);
    for(unsigned m=0;m<3;m++)if(munmap(maps[m],page*3)!=0)return 2;return 0;
}
