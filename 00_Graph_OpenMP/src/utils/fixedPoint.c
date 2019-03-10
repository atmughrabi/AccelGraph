#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "fixedPoint.h"


void initFixedPoint(struct FixedPoint* fp, __u32 size,__u32 scale32,__u32 scale64){

	fp->size = size;
	fp->scale64 = scale64;
	fp->scale32 = scale32;

	fp->fractionMask32 = (0xFFFFFFFF >> (32-fp->scale32));
	fp->fractionMask64 = (0xFFFFFFFFFFFFFFFF >> (64-fp->scale64));
	fp->wholeMask32 = (-1 ^ fp->fractionMask32);
	fp->wholeMask64 = (-1 ^ fp->fractionMask64);

}

__u32 floatToFixed32(struct FixedPoint* fp, float num){

	return (__u32)((num) * (float)((__u32)(1)<<SCALEF) + (float)(num >= 0 ? 0.5 : -0.5));

}	//((num) * (float)((__u32)(1)<<SCALEF))

__u32 doubleToFixed32(struct FixedPoint* fp, double num){

	return (__u32)((num) * (double)((__u64)(1)<<SCALEF) + (double)(num >= 0 ? 0.5 : -0.5));

}	//((num) * (double)((__u32)(1)<<SCALEF))

__u64 floatToFixed64(struct FixedPoint* fp, float num){

	return (__u64)((num) * (float)((__u64)(1)<<SCALED) + (float)(num >= 0 ? 0.5 : -0.5));

}	//((num) * (float)((__u32)(1)<<SCALEF))

__u64 doubleToFixed64(struct FixedPoint* fp, double num){

	return (__u64)((num) * (double)((__u64)(1)<<SCALED) + (double)(num >= 0 ? 0.5 : -0.5));

}	//((num) * (double)((__u64)(1)<<SCALED))

float fixed32ToFloat(struct FixedPoint* fp, __u32 num){

	return ((float)(num) / (float)((__u32)(1)<<SCALEF));

}	//((float)(num) / (float)((__u32)(1)<<SCALEF))

float fixed32ToDouble(struct FixedPoint* fp, __u32 num){

	return ((double)(num) / (double)((__u32)(1)<<SCALEF));

}	//((float)(num) / (float)((__u64)(1)<<SCALED))

float fixed64ToFloat(struct FixedPoint* fp, __u64 num){

	return (float)((double)(num) / (double)((__u64)(1)<<SCALED));

}	//((float)(num) / (float)((__u32)(1)<<SCALEF))
double fixed64ToDouble(struct FixedPoint* fp, __u64 num){

	return ((double)(num) / (double)((__u64)(1)<<SCALED));

}	//((float)(num) / (float)((__u64)(1)<<SCALED))

__u32 uInt32ToFixed32(struct FixedPoint* fp, __u32 num){

	return (__u32)((__u32) (num)<<SCALEF);

}	//((__u32) (num)<<SCALEF)

__u32 uInt64ToFixed32(struct FixedPoint* fp, __u64 num){

	return (__u32) ((__u64) (num)<<SCALEF);

}	//((__u64) (num)<<SCALED)

__u64 uInt32ToFixed64(struct FixedPoint* fp, __u32 num){

	return (__u64)((__u64) (num)<<SCALED);

}	//((__u32) (num)<<SCALEF)

__u64 uInt64ToFixed64(struct FixedPoint* fp, __u64 num){

	return (__u64)((__u64) (num)<<SCALED);

}	//((__u64) (num)<<SCALED)

__u32 int32ToFixed32(struct FixedPoint* fp, int num){

	return (__u32)((int) (num)<<SCALEF);

}	//( (num)<<SCALEF)
__u32 int64ToFixed32(struct FixedPoint* fp, long num){

	return (__u32)((int) (num)<<SCALEF);

}	//( (num)<<SCALED)

__u64 int32ToFixed64(struct FixedPoint* fp, int num){

	return (__u64)((long) (num)<<SCALED);

}	//( (num)<<SCALEF)
__u64 int64ToFixed64(struct FixedPoint* fp, long num){

	return (__u64)((long) (num)<<SCALED);

}	//( (num)<<SCALED)

__u32 fixed32ToUInt32(struct FixedPoint* fp, __u32 num){

	return (__u32)( (num)>>SCALEF);

}	//((__u32) (num)>>SCALEF)

__u64 fixed32ToUInt64(struct FixedPoint* fp, __u32 num){

	return (__u64)( (num)>>SCALEF);

}	//((__u64) (num)>>SCALED)

__u32 fixed64ToUInt32(struct FixedPoint* fp, __u64 num){

	return (__u32)( (num)>>SCALED);

}	//((__u32) (num)>>SCALEF)
__u64 fixed64ToUInt64(struct FixedPoint* fp, __u64 num){

	return (__u64)( (num)>>SCALED);

}	//((__u64) (num)>>SCALED)

int fixed32ToInt32(struct FixedPoint* fp, __u32 num){

	return (int)( (num)>>SCALEF);

} 	//( (num)>>SCALEF)
long fixed32ToInt64(struct FixedPoint* fp, __u32 num){

	return (long)( (num)>>SCALEF);

}	//( (num)>>SCALED)

int fixed64ToInt32(struct FixedPoint* fp, __u64 num){

	return (int)( (num)>>SCALED);

}  	//( (num)>>SCALEF)

long fixed64ToInt64(struct FixedPoint* fp, __u64 num){

	return (long)( (num)>>SCALED);

}	//( (num)>>SCALED)

__u32 fractionPart32(struct FixedPoint* fp, __u32 num){

	return ( (num) & FRACTION_MASK_32);

}	//( (num) & FRACTION_MASK_32)
__u32 wholePart32(struct FixedPoint* fp, __u32 num){

	return ( (num) & WHOLE_MASK_32);

}	//( (num) & WHOLE_MASK_32)

__u64 fractionPart64(struct FixedPoint* fp, __u64 num){

	return ( (num) & FRACTION_MASK_64);

}	//( (num) & FRACTION_MASK_64)
__u64 wholePart64(struct FixedPoint* fp, __u64 num){

	return ( (num) & WHOLE_MASK_64);

}	//( (num) & WHOLE_MASK_64)

__u64 mul32U(struct FixedPoint* fp, __u32 x,__u32 y){

	return (__u64)((__u64)((__u64)(x)*(__u64)(y)));

}          //((__u64)((__u64)(x)*(__u64)(y)))

__u32 mulFixed32V1(struct FixedPoint* fp, __u32 x,__u32 y){

	return (__u32)(mul32U(fp,x,y)>>SCALEF); // slow

} //(MUL32U(x,y)>>SCALEF) // slow

__u32 mulFixed32V1ROUND(struct FixedPoint* fp, __u32 x,__u32 y){

	return (__u32)(mul32U(fp,x,y)  + (mul32U(fp,x,y) & (1<<(SCALEF-1))<<1));

} //(MUL32U(x,y)  + (MUL32U(x,y) & (1<<(SCALEF-1))<<1)) // slow

__uint128_t mul64U(struct FixedPoint* fp, __u64 x,__u64 y){

	return (__uint128_t)((__uint128_t)((__uint128_t)(x)*(__uint128_t)(y)));

}          //((__uint128_t)((__uint128_t)(x)*(__uint128_t)(y)))

__u64 mulFixed64V1(struct FixedPoint* fp, __u64 x,__u64 y){

	return (__u64)(mul64U(fp,x,y)>>SCALED);

} //(MUL64U(x,y)>>SCALED) // slow

__u64 mulFixed64V1ROUND(struct FixedPoint* fp, __u64 x,__u64 y){

	return (__u64)(mul64U(fp,x,y)  + (mul64U(fp,x,y) & ((__u64)1<<(SCALED-1))<<1));

} //(MUL64U(x,y)  + (MUL64U(x,y) & (1<<(SCALED-1))<<1)) // slow
 

__u32 divFixed32V1(struct FixedPoint* fp, __u32 x,__u32 y){

	return (__u32)(((__u64)(x) << SCALEF)/(__u64)(y));

} //(((__u64)(x) << SCALEF)/(__u64)(y)) // slow

__u64 divFixed64V1(struct FixedPoint* fp, __u64 x,__u64 y){

	return (__u64)(((__uint128_t)(x) << SCALED)/(__uint128_t)(y));


} //(((__uint128_t)(x) << SCALED)/(__uint128_t)(y))