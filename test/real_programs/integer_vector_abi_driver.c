#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
typedef uint8_t Bytes __attribute__((vector_size(16)));
typedef uint16_t Words __attribute__((vector_size(16)));
extern Bytes byte_mix(Bytes,Bytes);
extern Words word_mix(Words,Words);
extern Bytes byte_call(Bytes,Bytes);
extern Words word_call(Words,Words);
extern Bytes byte_spill8(Bytes,Bytes,Bytes,Bytes,Bytes,Bytes,Bytes,Bytes,Bytes *);
extern Words word_loop(Words,Words);
Bytes external_bytes(Bytes x) { Bytes y; for(unsigned i=0;i<16;i++) y[i]=(uint8_t)(x[(i+3)%16]^0x39); return y; }
Words external_words(Words x,Words y) { return x^y; }
int main(int argc,char **argv) {
 unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
 size_t observations=0;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"integer-vector-abi fault=%u observation=%zu\n",fault,observations); return 1; } } while(0)
 for(unsigned seed=0;seed<64;seed++) {
  Bytes inputs[8];
  Words a,b;
  for(unsigned j=0;j<8;j++) for(unsigned i=0;i<16;i++) inputs[j][i]=(uint8_t)(seed*31+i*19+j*37);
  for(unsigned i=0;i<8;i++) { a[i]=(uint16_t)(seed*297+i*6013); b[i]=(uint16_t)(seed*731+i*1937); }
  Bytes got=byte_mix(inputs[0],inputs[1]);
  if(fault==1) got[0]^=1;
  for(unsigned i=0;i<16;i++) CHECK(got[i]==(uint8_t)((uint8_t)(inputs[0][15-i]+inputs[1][i])^0xa5));
  Words wg=word_mix(a,b);
  for(unsigned i=0;i<8;i++) CHECK(wg[i]==(uint16_t)((uint16_t)((uint32_t)a[i]<<(b[i]&15))^b[i]));
  got=byte_call(inputs[0],inputs[1]);
  for(unsigned i=0;i<16;i++) CHECK(got[i]==(uint8_t)((inputs[0][(i+3)%16]^0x39)+inputs[1][i]));
  wg=word_call(a,b);
  for(unsigned i=0;i<8;i++) CHECK(wg[i]==(uint16_t)((a[i]^b[i])+a[i]));
  struct { unsigned char pre[16]; Bytes value; unsigned char post[16]; } out;
  memset(&out,0x5a,sizeof(out));
  got=byte_spill8(inputs[0],inputs[1],inputs[2],inputs[3],inputs[4],inputs[5],inputs[6],inputs[7],&out.value);
  for(unsigned i=0;i<16;i++) {
   uint8_t expected=0; for(unsigned j=0;j<8;j++) expected^=inputs[j][i];
   CHECK(got[i]==expected&&out.value[i]==expected);
  }
  wg=word_loop(a,b);
  for(unsigned i=0;i<8;i++) CHECK(wg[i]==(uint16_t)(a[i]+3*b[i]));
  if(fault==2) out.pre[0]^=1;
  if(fault==3) out.post[15]^=1;
  unsigned bad_pre=0,bad_post=0;
  for(unsigned i=0;i<16;i++) { bad_pre|=out.pre[i]^0x5a; bad_post|=out.post[i]^0x5a; }
  CHECK(!bad_pre); CHECK(!bad_post);
 }
 printf("integer-vector-abi observations=%zu byte=halfword=xmm=8-inputs=c-interop=loops=guards=preserved\n",observations);
 return 0;
}
