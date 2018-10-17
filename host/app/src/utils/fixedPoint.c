#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "fixedPoint.h"


void initFixedPoint(struct FixedPoint* fp){


}

__u32 floatToFixed32(float num){



}	//((num) * (float)((__u32)(1)<<SCALEF))
__u32 doubleToFixed32(double num){



}	//((num) * (double)((__u32)(1)<<SCALEF))

__u64 floatToFixed64(float num){



}	//((num) * (float)((__u32)(1)<<SCALEF))
__u64 doubleToFixed64(double num){




}	//((num) * (double)((__u64)(1)<<SCALED))

double fixed32ToDouble32(__u32 num){



}	//((double)(num) / (double)((__u32)(1)<<SCALEF))
double fixed32ToDouble64(__u32 num){



}	//((double)(num) / (double)((__u64)(1)<<SCALED))

float fixed32ToFloat(__u32 num){



}	//((float)(num) / (float)((__u32)(1)<<SCALEF))
float fixed32ToDouble(__u32 num){



}	//((float)(num) / (float)((__u64)(1)<<SCALED))

float fixed64ToFloat(__u64 num){



}	//((float)(num) / (float)((__u32)(1)<<SCALEF))
double fixed64ToDouble(__u64 num){



}	//((float)(num) / (float)((__u64)(1)<<SCALED))

__u32 uInt32ToFixed32(__u32 num){



}	//((__u32) (num)<<SCALEF)
__u32 uInt64ToFixed32(__u64 num){



}	//((__u64) (num)<<SCALED)

__u64 int32ToFixed64(int num){




}	//( (num)<<SCALEF)
__u64 int64ToFixed64(long num){




}	//( (num)<<SCALED)

__u64 int32ToFixed64(int num){




}	//( (num)<<SCALEF)
__u64 int64ToFixed64(long num){




}	//( (num)<<SCALED)

__u32 fixed32ToUInt32(__u32 num){




}	//((__u32) (num)>>SCALEF)
__u64 fixed32ToUInt64(__u32 num){




}	//((__u64) (num)>>SCALED)

__u32 fixed64ToUInt32(__u64 num){




}	//((__u32) (num)>>SCALEF)
__u64 fixed64ToUInt64(__u64 num){




}	//((__u64) (num)>>SCALED)

int fixed32ToInt32(__u32 num){




}  	//( (num)>>SCALEF)
long fixed32ToInt64(__u32 num){




}	//( (num)>>SCALED)

int fixed64ToInt32(__u64 num){




}  	//( (num)>>SCALEF)
long fixed64ToInt64(__u64 num){




}	//( (num)>>SCALED)

__u32 fractionPart32(__u32 num){




}	//( (num) & FRACTION_MASK_32)
__u32 wholePart32(__u32 num){




}	//( (num) & WHOLE_MASK_32)

__u64 fractionPart64(__u64 num){




}	//( (num) & FRACTION_MASK_64)
__u64 wholePart64(__u64 num){




}	//( (num) & WHOLE_MASK_64)

__u64 mul32U(__u32 x,__u32 y){




}         //((__u64)((__u64)(x)*(__u64)(y)))
__u32 mulFixed32V1(__u32 x,__u32 y){




} //(MUL32U(x,y)>>SCALEF) // slow
__u32 mulFixed32V1ROUND(__u32 x,__u32 y){




} //(MUL32U(x,y)  + (MUL32U(x,y) & (1<<(SCALEF-1))<<1)) // slow

__uint128_t mul64U(__u64 x,__u64 y){




}         //((__uint128_t)((__uint128_t)(x)*(__uint128_t)(y)))
__u64 mulFixed64V1(__u64 x,__u64 y){




} //(MUL64U(x,y)>>SCALED) // slow
__u64 mulFixed64V1ROUND(__u64 x,__u64 y){




} //(MUL64U(x,y)  + (MUL64U(x,y) & (1<<(SCALED-1))<<1)) // slow
 

__u32 divFixed32V1(__u32 x,__u32 y){




} //(((__u64)(x) << SCALEF)/(__u64)(y)) // slow
__u64 divFixed64V1(__u64 x,__u64 y){



	
} //(((__uint128_t)(x) << SCALED)/(__uint128_t)(y))