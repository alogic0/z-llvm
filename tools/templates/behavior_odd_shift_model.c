#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run;unsigned n,kind;};
__attribute__((noinline)) uint64_t odd_shift_clobber(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h){
    __asm__ volatile("":::"rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","memory");
    return a^(b*3)^(c*5)^(d*7)^(e*11)^(f*13)^(g*17)^(h*19);
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *maps[3];
    for(unsigned m=0;m<3;m++){
        maps[m]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
        if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;
    }
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<128;seed++){
        unsigned n=cases[which].n,k=cases[which].kind,extent=n*3;
        unsigned char *a=maps[0]+2*page-extent,*b=maps[1]+2*page-extent,*out=maps[2]+2*page-extent-8;
        unsigned char sa[192],sb[192],expected[192],guard[8];
        memset(guard,0xa5,8);memset(out-8,0xa5,extent+16);
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;
        for(unsigned lane=0;lane<n;lane++){
            uint32_t edges[]={0,1,0x7fffff,0x800000,0xffffff,0xfffffe,0x555555,0xaaaaaa};
            uint32_t x=seed<8?edges[(seed+lane)%8]:(seed*UINT32_C(0x918273)^lane*UINT32_C(0x55aacc))&0xffffff;
            unsigned shift=(seed+lane*7)%24;uint32_t r;
            if(k==0)r=(x<<shift)&0xffffff;
            else {r=x>>shift;if(k==2&&(x&0x800000)&&shift)r|=(0xffffffu<<(24-shift))&0xffffff;}
            for(unsigned j=0;j<3;j++){a[lane*3+j]=(unsigned char)(x>>(8*j));b[lane*3+j]=(unsigned char)(shift>>(8*j));expected[lane*3+j]=(unsigned char)(r>>(8*j));}
        }
        memcpy(sa,a,extent);memcpy(sb,b,extent);
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page,PROT_READ))return 2;
        uint64_t salt=UINT64_C(0xfedcba9876543211)*seed;
        uint64_t model=salt^UINT64_C(6)^UINT64_C(15)^UINT64_C(28)^UINT64_C(55)^UINT64_C(78)^UINT64_C(119)^UINT64_C(152);
        uint64_t answer=cases[which].run(out,a,b,salt);
        if(fault==1)out[0]^=1;if(fault==2)answer^=1;if(fault==3)out[extent]^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"odd-shift case=%zu n=%u kind=%u seed=%u observation=%zu fault=%u\n",which,n,k,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==(model^salt));CHECK(memcmp(out,expected,extent)==0);
        CHECK(memcmp(out-8,guard,8)==0);CHECK(memcmp(out+extent,guard,8)==0);
        CHECK(memcmp(a,sa,extent)==0);CHECK(memcmp(b,sb,extent)==0);
#undef CHECK
    }
    printf("odd-shift observations=%zu i24-all-valid-counts=three-operators=call-clobbers=spilled-inputs=readonly-inputs=guard-pages=preserved\n",observations);
    for(unsigned m=0;m<3;m++)if(munmap(maps[m],page*3))return 2;
    return 0;
}
