#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

typedef uint64_t (*kernel)(unsigned char *, const unsigned char *, const unsigned char *, uint64_t);
extern uint64_t vector_storage_16_32(unsigned char *,const unsigned char *,const unsigned char *,uint64_t);
extern uint64_t vector_storage_17_32(unsigned char *,const unsigned char *,const unsigned char *,uint64_t);
extern uint64_t vector_storage_3_64(unsigned char *,const unsigned char *,const unsigned char *,uint64_t);
extern uint64_t vector_storage_64_64(unsigned char *,const unsigned char *,const unsigned char *,uint64_t);
static uint64_t next(uint64_t *s) { *s ^= *s << 13; *s ^= *s >> 7; *s ^= *s << 17; return *s; }
static void fail(const char *s) { fprintf(stderr,"vector-storage failure: %s\n",s); exit(1); }

/* Linked C owns the observable escape and validates physical alignment and
   nonaliasing, including array allocation strides and simultaneous lifetimes. */
uint64_t vector_storage_touch(unsigned char *a,unsigned char *b,unsigned char *c,
        unsigned char *d,unsigned char *e,uint64_t bytes,uint64_t alignment) {
    unsigned char *p[5]={a,b,c,d,e};
    uint64_t h=0x4e12398b;
    for (unsigned j=0;j<5;j++) {
        if ((uintptr_t)p[j] % alignment) fail("alignment");
        for (unsigned k=0;k<j;k++) {
            uintptr_t x=(uintptr_t)p[j],y=(uintptr_t)p[k];
            if (x<y+bytes && y<x+bytes) fail("overlapping live vectors");
        }
        for (uint64_t i=0;i<bytes;i++) h=(h<<7|h>>57)^p[j][i];
        p[j][0]^=(unsigned char)(0x31+j);
        p[j][bytes-1]^=(unsigned char)(0x73+j);
    }
    return h;
}

int main(int argc,char **argv) {
    int fault=argc>1?atoi(argv[1]):0;
    if (fault<0 || fault>3) return 2;
    const kernel functions[4]={vector_storage_16_32,vector_storage_17_32,vector_storage_3_64,vector_storage_64_64};
    const unsigned lanes[4]={16,17,3,64},widths[4]={4,4,8,8};
    size_t page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[2];
    for(unsigned j=0;j<2;j++) {
        maps[j]=mmap(0,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
        if(maps[j]==MAP_FAILED || mprotect(maps[j]+page,page,PROT_NONE)) fail("guard mapping");
    }
    uint64_t random=0x876543210fedcba9,observations=0;
    for (unsigned shape=0;shape<4;shape++) for (unsigned sample=0;sample<64;sample++) {
        unsigned bytes=lanes[shape]*widths[shape];
        unsigned char *a=maps[0]+page-bytes,*b=maps[1]+page-bytes;
        unsigned char expected[5][512],actual[5*512+2],saved[2][512];
        memset(expected,0,sizeof expected); memset(actual,0xa6,sizeof actual);
        for(unsigned i=0;i<lanes[shape];i++) {
            uint64_t x=sample==0?0:sample==1?UINT64_MAX:next(&random);
            uint64_t y=sample==0?UINT64_MAX:sample==1?1:next(&random);
            uint64_t values[5]={x,y,x+y,x-y,x^y};
            memcpy(a+i*widths[shape],&x,widths[shape]); memcpy(b+i*widths[shape],&y,widths[shape]);
            for(unsigned j=0;j<5;j++) memcpy(expected[j]+i*widths[shape],&values[j],widths[shape]);
        }
        memcpy(saved[0],a,bytes); memcpy(saved[1],b,bytes);
        uint64_t h=0x4e12398b,salt=next(&random);
        for(unsigned j=0;j<5;j++) {
            for(unsigned i=0;i<bytes;i++) h=(h<<7|h>>57)^expected[j][i];
            expected[j][0]^=(unsigned char)(0x31+j); expected[j][bytes-1]^=(unsigned char)(0x73+j);
        }
        uint64_t result=functions[shape](actual+1,a,b,salt);
        if(fault==1) result^=1;
        if(fault==2) actual[1]^=1;
        if(fault==3) actual[sizeof actual-1]^=1;
        if(fault) fprintf(stderr,"fault=%d\n",fault);
        if(result!=(h^salt)) fail("return or live salt");
        observations++;
        if(actual[0]!=0xa6 || actual[sizeof actual-1]!=0xa6) fail("outer canary");
        for(unsigned j=0;j<5;j++) for(unsigned i=0;i<512;i++) {
            if(actual[1+j*512+i]!=(i<bytes?expected[j][i]:0xa6)) fail("payload or exact tail");
            if(i<bytes) observations++;
        }
        if(memcmp(a,saved[0],bytes) || memcmp(b,saved[1],bytes)) fail("input preservation");
    }
    for(unsigned j=0;j<2;j++) if(munmap(maps[j],page*2)) fail("unmap");
    if(observations!=214016) fail("observation count");
    printf("vector-storage observations=%llu alignment=nonaliasing=array-strides=live-objects=guard-pages=preserved\n",(unsigned long long)observations);
    return 0;
}
