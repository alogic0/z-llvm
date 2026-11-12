static __attribute__((noinline)) u128 model(u128 a,u128 b,unsigned op){
 u128 all=~(u128)0,sign=(u128)1<<127,result;unsigned n=(unsigned)(b&127);op&=3;
 if(op==0)result=a>(all>>n)?all:a<<n;
 else if(op==1){int negative=(a&sign)!=0;u128 magnitude=negative?(u128)0-a:a,limit=negative?sign:sign-1;if(magnitude>(limit>>n))result=negative?sign:sign-1;else{result=magnitude<<n;if(negative)result=(u128)0-result;}}
 else if(op==2){if(__builtin_mul_overflow(a,b,&result))result=all;}
 else{i128 x,y,r;memcpy(&x,&a,16);memcpy(&y,&b,16);if(__builtin_mul_overflow(x,y,&r))result=((x<0)^(y<0))?sign:sign-1;else memcpy(&result,&r,16);}
 return result^b;
}
