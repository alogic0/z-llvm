static int transport(u128 a,u128 b,uint64_t seed,unsigned constant) {
 uint64_t out[6] __attribute__((aligned(16)))={UINT64_C(0x123456789abcdef0),0,0,0,0,UINT64_C(0xfedcba9876543210)};
 u128 chosen=constant?words(UINT64_C(0x0123456789abcdef),UINT64_C(0x7fff800000000123)):(seed&1?a:b);
 u128 expected=helper_expected(chosen,a,seed^key);
 quad result=constant?binary128_call_constant(payload(a),seed,out+1):binary128_transport(payload(a),payload(b),seed,out+1);
 u128 actual=bits(result);
 if(inject_fault==1)actual^=1;
 if(inject_fault>=2&&inject_fault<=5)out[inject_fault-1]^=1;
 if(inject_fault==6)out[0]^=1;
 if(inject_fault==7)out[5]^=1;
 if(actual!=expected||out[1]!=(uint64_t)expected||out[2]!=(uint64_t)(expected>>64)||
 out[3]!=(uint64_t)chosen||out[4]!=(uint64_t)(chosen>>64)||
 out[0]!=UINT64_C(0x123456789abcdef0)||out[5]!=UINT64_C(0xfedcba9876543210)) {
  fprintf(stderr,"binary128 transport mismatch constant=%u seed=%llx fault=%u fields=%llx,%llx,%llx,%llx guards=%llx,%llx\n",
  constant,(unsigned long long)seed,inject_fault,(unsigned long long)out[1],(unsigned long long)out[2],
  (unsigned long long)out[3],(unsigned long long)out[4],(unsigned long long)out[0],(unsigned long long)out[5]); return 1;
 }
 observations++; return 0;
}
static unsigned comparison_expected(unsigned predicate,quad a,quad b) {
 const u128 magnitude=((u128)1<<127)-1, infinity=(u128)0x7fff<<112;
 unsigned unordered=(bits(a)&magnitude)>infinity||(bits(b)&magnitude)>infinity;
 switch(predicate) {
 case 0:return 0; case 1:return !unordered&&a==b; case 2:return !unordered&&a>b;
 case 3:return !unordered&&a>=b; case 4:return !unordered&&a<b; case 5:return !unordered&&a<=b;
 case 6:return !unordered&&a!=b; case 7:return !unordered; case 8:return unordered;
 case 9:return unordered||a==b; case 10:return unordered||a>b; case 11:return unordered||a>=b;
 case 12:return unordered||a<b; case 13:return unordered||a<=b; case 14:return unordered||a!=b;
 case 15:return 1; default:abort();
 }
}
int main(int argc,char **argv) {
 if(argc==2)inject_fault=(unsigned)strtoul(argv[1],0,10);
 if(argc>2||inject_fault>7)return 2;
 const u128 raw[8]={0,1,(u128)1<<127,(u128)0x3fff<<112,(u128)0x7fff<<112,
  ((u128)0x7fff<<112)|1,((u128)UINT64_C(0xffff800000000123)<<64)|UINT64_C(0xfeedface01234567),~(u128)0};
 const uint64_t seeds[4]={0,1,UINT64_C(0x8000000000000000),UINT64_MAX};
 u128 comparison_bits[16]; memcpy(comparison_bits,raw,sizeof(raw));
 comparison_bits[8]=(u128)0xbfff<<112; comparison_bits[9]=(u128)0xc000<<112;
 comparison_bits[10]=((u128)0xfffe<<112)|(((u128)1<<112)-1);
 comparison_bits[11]=((u128)1<<127)|1; comparison_bits[12]=(u128)0xffff<<112;
 comparison_bits[13]=(u128)0x4000<<112;
 comparison_bits[14]=((u128)0x7ffe<<112)|(((u128)1<<112)-1);
 comparison_bits[15]=((u128)0x3fff<<112)|1;
 for(unsigned i=0;i<16;i++)for(unsigned j=0;j<16;j++)for(unsigned p=0;p<16;p++) {
  quad a=payload(comparison_bits[i]),b=payload(comparison_bits[j]);
  uint64_t out[4]={UINT64_C(0x123456789abcdef0),0,0,UINT64_C(0xfedcba9876543210)};
  unsigned actual=comparisons[p](a,b,out+1);
  if(check_bits("comparison",actual,comparison_expected(p,a,b))||
   words(out[1],out[2])!=comparison_bits[i]||out[0]!=UINT64_C(0x123456789abcdef0)||out[3]!=UINT64_C(0xfedcba9876543210)) {
   fprintf(stderr,"binary128 comparison input_a=%u input_b=%u predicate=%u\n",i,j,p);return 1;
  }
 }
 for(unsigned i=0;i<8;i++)for(unsigned j=0;j<8;j++)for(unsigned k=0;k<4;k++)
  if(transport(raw[i],raw[j],seeds[k],0)||transport(raw[i],raw[j],seeds[k],1))return 1;
 for(unsigned i=0;i<8;i++) {
  if(check_bits("identity",bits(binary128_identity(payload(raw[i]))),raw[i])||
   check_bits("bits",binary128_bits(payload(raw[i])),raw[i])||
   check_bits("from-bits",bits(binary128_from_bits(raw[i])),raw[i]))return 1;
  quad array[3]={payload(raw[i]),payload(raw[(i+1)%8]),payload(raw[(i+2)%8])};
  for(unsigned j=0;j<3;j++)if(check_bits("stride",bits(binary128_load_index(array,j)),raw[(i+j)%8]))return 1;
  for(unsigned k=0;k<4;k++) {
   quad args[8]; uint64_t lo=seeds[k]^key,hi=seeds[k];
   for(unsigned j=0;j<8;j++) {
    u128 value=raw[(i+j)%8]^words(key*(j+1),key*(j+3)); args[j]=payload(value);
    lo+=(uint64_t)value*(2*j+1);
    if(j==0)hi^=(uint64_t)(value>>64)*3; else hi+=(uint64_t)(value>>64)*(2*j+3);
   }
   if(check_bits("eight",bits(binary128_eight(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],seeds[k])),words(lo,hi)))return 1;
  }
 }
 long page=sysconf(_SC_PAGESIZE); if(page<16)return 2;
 void *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(mapping==MAP_FAILED||mprotect((char*)mapping+page,(size_t)page,PROT_NONE))return 2;
 quad *edge=(quad*)((char*)mapping+page-16); *edge=payload(raw[6]);
 if(check_bits("page-edge",bits(binary128_load_index(edge,0)),raw[6]))return 1;
 if(munmap(mapping,(size_t)page*2))return 2;
 const u128 finite_bits[8]={0,(u128)1<<127,1,(u128)0x3fff<<112,((u128)0xbfff<<112)|1,
  ((u128)0x4000<<112)|UINT64_C(0x123456789abcdef),((u128)0x7ffe<<112)|(((u128)1<<112)-1),
  ((u128)0x0001<<112)|UINT64_C(0xfedcba987654321)};
 quad numbers[8]; for(unsigned i=0;i<8;i++)numbers[i]=payload(finite_bits[i]);
 for(unsigned i=0;i<8;i++)for(unsigned j=0;j<8;j++) {
  quad a=numbers[i],b=numbers[j],divisor=b==0?(quad)1:b;
  if(check_quad("add",binary128_add(a,b),a+b)||check_quad("sub",binary128_sub(a,b),a-b)||
   check_quad("mul",binary128_mul(a,b),a*b)||check_quad("div",binary128_div(a,divisor),a/divisor))return 1;
 }
 const double doubles[8]={0.0,-0.0,1.0,-1.0,0x1p-1074,0x1.fffffffffffffp1023,0x1.0000000000001p0,-0x1.123456789abcdp-100};
 const float floats[8]={0.0f,-0.0f,1.0f,-1.0f,0x1p-149f,0x1.fffffep127f,0x1.000002p0f,-0x1.123456p-20f};
 const int32_t signed32[8]={INT32_MIN,-123456789,-1,0,1,123456789,INT32_MAX-1,INT32_MAX};
 const uint32_t unsigned32[8]={0,1,2,0x7fffffff,0x80000000,0xabcdef01,UINT32_MAX-1,UINT32_MAX};
 const int64_t signed64[8]={INT64_MIN,INT64_MIN+1,-1,0,1,INT64_C(0x123456789abcdef),INT64_MAX-1,INT64_MAX};
 const uint64_t unsigned64[8]={0,1,2,UINT64_C(0x7fffffffffffffff),UINT64_C(0x8000000000000000),UINT64_C(0xabcdef0123456789),UINT64_MAX-1,UINT64_MAX};
 for(unsigned i=0;i<8;i++) {
  if(check_quad("from-f32",binary128_from_f32(floats[i]),(quad)floats[i])||
   check_quad("from-f64",binary128_from_f64(doubles[i]),(quad)doubles[i]))return 1;
  float af=binary128_to_f32(numbers[i]),ef=(float)numbers[i];
  double ad=binary128_to_f64(numbers[i]),ed=(double)numbers[i];
  uint32_t afb,efb; uint64_t adb,edb; memcpy(&afb,&af,4);memcpy(&efb,&ef,4);memcpy(&adb,&ad,8);memcpy(&edb,&ed,8);
  if(check_bits("to-f32",afb,efb)||check_bits("to-f64",adb,edb))return 1;
  if(check_quad("from-i32",binary128_from_i32(signed32[i]),(quad)signed32[i])||
   check_quad("from-u32",binary128_from_u32(unsigned32[i]),(quad)unsigned32[i])||
   check_quad("from-i64",binary128_from_i64(signed64[i]),(quad)signed64[i])||
   check_quad("from-u64",binary128_from_u64(unsigned64[i]),(quad)unsigned64[i]))return 1;
  quad si=(quad)signed32[i]+(signed32[i]==INT32_MAX?(quad)0:(quad)0.25);
  quad sl=(quad)signed64[i]+(signed64[i]==INT64_MAX?(quad)0:(quad)0.25);
  int32_t ei=signed32[i]+(signed32[i]<0); int64_t el=signed64[i]+(signed64[i]<0);
  if(check_bits("to-i32",(uint64_t)(int64_t)binary128_to_i32(si),(uint64_t)(int64_t)ei)||
   check_bits("to-i64",(uint64_t)binary128_to_i64(sl),(uint64_t)el)||
   check_bits("to-u32",binary128_to_u32((quad)unsigned32[i]+(quad)0.25),unsigned32[i])||
   check_bits("to-u64",binary128_to_u64((quad)unsigned64[i]+(quad)0.25),unsigned64[i]))return 1;
 }
 printf("binary128-payloads observations=%u bits=abi=memory=arithmetic=conversions=comparisons=clobbers=guards=preserved\n",observations);
 return observations!=5041;
}
