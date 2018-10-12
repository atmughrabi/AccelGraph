#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "fixedPoint.h"


__u32 floatToFixed(float num){

	return (num * (float)((__u32)1<<SCALEF));

}

__u64 doubleToFixed(double num){

	return (num * (double)((__u64)1<<SCALED));

}

double fixedToDouble(__u64 num){

	return ((double)num / (double)((__u64)1<<SCALED));

}

float  fixedToFloat(__u32 num){

	return ((float)num / (float)((__u32)1<<SCALEF));

}

__u32 uInt32ToFixed(__u32 num){

	return ((__u32) num<<SCALEF);

}	

__u64 uInt64ToFixed(__u64 num){

	return ((__u64) num<<SCALED);

}	

int int32ToFixed(int num){

	return (num<<SCALEF);

}	

long int64ToFixed(long num){

	return (num<<SCALED);

}	

__u64 fixeToUInt64(__u64 num){

	return ((__u64) num>>SCALED);

}	
__u32 fixeToUInt32(__u32 num){

	return ((__u32) num>>SCALEF);

}

int fixeToInt32(int num){

	return ( num>>SCALEF);

}

long fixeToInt64(long num){

	return ( num>>SCALED);

}	