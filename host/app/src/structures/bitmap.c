#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <linux/types.h>

#include "myMalloc.h"
#include "bitmap.h"

struct Bitmap* newBitmap( __u32 size){


	#if ALIGNED
		struct Bitmap* bitmap = (struct Bitmap*) my_aligned_alloc( sizeof(struct Bitmap));
	#else
        struct Bitmap* bitmap = (struct Bitmap*) my_malloc( sizeof(struct Bitmap));
	#endif


    #if ALIGNED
		bitmap->bitarray = (__u8*) my_aligned_alloc(sizeof(__u8)*((size+7)/8));
	#else
        bitmap->bitarray = (__u8*) my_malloc(sizeof(__u8)*((size+7)/8));
	#endif

    memset(bitmap->bitarray, 0, (sizeof(__u8)*((size+7)/8)));
	bitmap->size =  size;


	return bitmap;
}


void freeBitmap( struct Bitmap* bitmap){

        free(bitmap->bitarray);
        free(bitmap);
	
}

void reset(struct Bitmap* bitmap){

	 memset(bitmap->bitarray, 0, (sizeof(__u8)*((bitmap->size+7)/8)));

}

void setBit(struct Bitmap* bitmap, __u32 pos){

	ba_set(bitmap->bitarray, pos);

}

void setBitAtomic(struct Bitmap* bitmap, __u32 pos){

	ba_set(bitmap->bitarray, pos);

}

__u8 getBit(struct Bitmap* bitmap, __u32 pos){

	__u8 bit = ba_get(bitmap->bitarray, pos);
	return bit;

}

void clearBit(struct Bitmap* bitmap, __u32 pos){

	ba_clear(bitmap->bitarray, pos);

}

struct Bitmap*  orBitmap(struct Bitmap* bitmap1, struct Bitmap* bitmap2){


	__u32 i;
	__u8 *byte1 = bitmap1->bitarray;
	__u8 *byte2 = bitmap2->bitarray;

	for(i= 0 ; i < ((bitmap1->size+7)/8); i++){
		byte1[i] = byte1[i] | byte2[i]; 

	}

	return bitmap1;

}