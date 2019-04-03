#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "bloomFilter.h"
#include "bitmap.h"
#include "myMalloc.h"

struct BloomFilter * newBloomFilter(__u32 size){


	#if ALIGNED
		struct BloomFilter * bloomFilter = (struct BloomFilter *) my_aligned_malloc( sizeof(struct BloomFilter));
	#else
        struct BloomFilter * bloomFilter = (struct BloomFilter *) my_malloc( sizeof(struct BloomFilter));
	#endif

     bloomFilter->bloom = newBitmap(size);
     bloomFilter->size = size;

     return bloomFilter;


}
void freeBloomFilter( struct BloomFilter * bloomFilter){

	if(bloomFilter){
		freeBitmap(bloomFilter->bloom);
		free(bloomFilter);
	}


}
void clearBloomFilter( struct BloomFilter * bloomFilter){

	clearBitmap(bloomFilter->bloom);

}


void addToBloomFilter(struct BloomFilter * bloomFilter, __u32 item){


}
__u32 findInBloomFilter(struct BloomFilter * bloomFilter, __u32 item){

	return 0;


}