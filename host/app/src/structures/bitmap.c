#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <linux/types.h>

#include "myMalloc.h"
#include "bitmap.h"

struct Bitmap* newBitmap( __u32 size){


	#if ALIGNED
		struct Bitmap* bitmap = (struct Bitmap*) my_aligned_malloc( sizeof(struct Bitmap));
	#else
        struct Bitmap* bitmap = (struct Bitmap*) my_malloc( sizeof(struct Bitmap));
	#endif


    #if ALIGNED
		bitmap->bitarray = (__u32*) my_aligned_malloc(sizeof(__u32)*((size+kBitsPerWord - 1)/kBitsPerWord));
	#else
        bitmap->bitarray = (__u32*) my_malloc(sizeof(__u32)*((size+kBitsPerWord - 1)/kBitsPerWord));
	#endif

      

    memset(bitmap->bitarray, 0, (sizeof(__u32)*((size+kBitsPerWord - 1)/kBitsPerWord)));
	bitmap->size =  size;
	bitmap->numSetBits =  0;

	return bitmap;
}


void freeBitmap( struct Bitmap* bitmap){

        free(bitmap->bitarray);
        free(bitmap);
	
}

void reset(struct Bitmap* bitmap){

	 memset(bitmap->bitarray, 0, (sizeof(__u32)*((bitmap->size+kBitsPerWord - 1)/kBitsPerWord)));
	 bitmap->numSetBits =  0;

}

void setBit(struct Bitmap* bitmap, __u32 pos){

	// ba_set(bitmap->bitarray, pos);
	// bitmap->numSetBits++;
	bitmap->bitarray[word_offset(pos)] |= (__u32) (1 << bit_offset(pos));

}

void setBitRange(struct Bitmap* bitmap, __u32 start,__u32 end){

 __u32 pos;

 for (pos = start; pos < end; ++pos)
 {
 	setBit(bitmap, pos);
 	// bitmap->numSetBits++;
 }

}

void setBitAtomic(struct Bitmap* bitmap, __u32 pos){

	// ba_set(bitmap->bitarray, pos);
	 // __u64 *bitarray = bitmap->bitarray;
	 __u32 old_val, new_val;
    do {
      old_val = bitmap->bitarray[word_offset(pos)];
      new_val = old_val | (__u32) (1 << bit_offset(pos));
    } while (!__sync_bool_compare_and_swap(&bitmap->bitarray[word_offset(pos)], old_val, new_val));

	

}

__u8 getBit(struct Bitmap* bitmap, __u32 pos){

	// __u8 bit = ba_get(bitmap->bitarray, pos);
	return (__u8)(bitmap->bitarray[word_offset(pos)] >> bit_offset(pos)) & 1l;;

}

void clearBit(struct Bitmap* bitmap, __u32 pos){

	// ba_clear(bitmap->bitarray, pos);
	// bitmap->numSetBits--;
	bitmap->bitarray[word_offset(pos)] &= ((__u32) (~(1l << bit_offset(pos))));

}

struct Bitmap*  orBitmap(struct Bitmap* bitmap1, struct Bitmap* bitmap2){


	__u32 i;
	__u32 *byte1 = bitmap1->bitarray;
	__u32 *byte2 = bitmap2->bitarray;
	bitmap1->numSetBits = 0;

	for(i= 0 ; i <((bitmap1->size+kBitsPerWord - 1)/kBitsPerWord); i++){
		byte1[i] = byte1[i] | byte2[i]; 

	}

	bitmap1->numSetBits = getNumOfSetBits(bitmap1);

	return bitmap1;

}


struct Bitmap*  andBitmap(struct Bitmap* bitmap1, struct Bitmap* bitmap2){


	__u32 i;
	__u32 *byte1 = bitmap1->bitarray;
	__u32 *byte2 = bitmap2->bitarray;
	bitmap1->numSetBits = 0;

	for(i= 0 ; i < ((bitmap1->size+kBitsPerWord - 1)/kBitsPerWord); i++){
		byte1[i] = byte1[i] & byte2[i]; 

	}

	bitmap1->numSetBits = getNumOfSetBits(bitmap1);

	return bitmap1;

}


void swapBitmaps (struct Bitmap** bitmap1, struct Bitmap** bitmap2){

	
	struct Bitmap* temp_bitmap = *bitmap1;
	*bitmap1 = *bitmap2;
	*bitmap2 = temp_bitmap;

}



__u32 getNumOfSetBits (struct Bitmap* bitmap){

	__u32 i;
	__u32 numSetBits = 0;

	#pragma omp parallel for reduction(+:numSetBits)
	for(i= 0 ; i < (bitmap->size); i++){
		if(getBit(bitmap, i))
			numSetBits++;
	}

	return numSetBits;
}

void printSetBits (struct Bitmap* bitmap){

	__u32 i;

	for(i= 0 ; i < (bitmap->size); i++){
		if(getBit(bitmap, i)){
			printf("**%u \n", i);
		}
	}

}