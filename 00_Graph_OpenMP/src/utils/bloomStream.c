#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "bloomStream.h"
#include "bitmap.h"
#include "hash.h"
#include <limits.h>
#include "myMalloc.h"

struct BloomStream * newBloomStream(__u32 size, __u32 k){

    __u32 i;
    __u32 alignedSize = ((size+kBitsPerWord - 1)/kBitsPerWord)*kBitsPerWord;
    // __u32 nextPrimePartition = findNextPrime((alignedSize/k));
    

    // alignedSize = (((nextPrimePartition*k)+kBitsPerWord - 1)/kBitsPerWord)*kBitsPerWord;


	#if ALIGNED
		struct BloomStream * bloomStream = (struct BloomStream *) my_aligned_malloc( sizeof(struct BloomStream));
        bloomStream->counter = (__u32*) my_aligned_malloc(alignedSize *sizeof(__u32));
        bloomStream->counterHistory = (__u32*) my_aligned_malloc(alignedSize *sizeof(__u32));
	#else
        struct BloomStream * bloomStream = (struct BloomStream *) my_malloc( sizeof(struct BloomStream));
        bloomStream->counter = (__u32*) my_malloc(alignedSize *sizeof(__u32));
        bloomStream->counterHistory = (__u32*) my_malloc(alignedSize *sizeof(__u32));
	#endif

    for(i=0 ; i< alignedSize; i++){
        bloomStream->counter[i] = 0;
        bloomStream->counterHistory[i] = 0;
    }

    bloomStream->bloom = newBitmap(size);
    bloomStream->bloomPrime = newBitmap(size);
    bloomStream->bloomHistory = newBitmap(size);
    bloomStream->lowestCounter = newBitmap(size);


    bloomStream->size = alignedSize;
    bloomStream->k = k;
    bloomStream->partition = bloomStream->size/bloomStream->k;
    bloomStream->membership = 0;
    bloomStream->temperature  = 0;

    bloomStream->threashold = 0;
    bloomStream->decayPeriod  = 0;
    bloomStream->numIO = 0;
    


     return bloomStream;

}


void freeBloomStream( struct BloomStream * bloomStream){

	if(bloomStream){
		freeBitmap(bloomStream->bloom);
        freeBitmap(bloomStream->bloomPrime);
        freeBitmap(bloomStream->bloomHistory);
        free(bloomStream->counter);
        free(bloomStream->counterHistory);
		free(bloomStream);
	}


}
void clearBloomStream( struct BloomStream * bloomStream){

	clearBitmap(bloomStream->bloom);
    clearBitmap(bloomStream->bloomPrime);

}


void addToBloomStream(struct BloomStream * bloomStream, __u64 item){

    
    printf("add- %lx %lu \n", item,item);
	__u64 z = magicHash64(item);
	__u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;
    __u32 minCount = UINT_MAX;
    __u32 freqCount = 0;
    __u32 index = 0;

    __u32 found = findInBloomStream(bloomStream, item);


    if(!found){
        for (i = 0; i < bloomStream->k; ++i) {
        __u64 k = (h1 + i * h2) % bloomStream->partition; // bit to set
        __u64 j = k + (i * bloomStream->partition);       // in parition 'i'
        setBitXOR(bloomStream->bloom, (__u32)j);
        }

    }
    else{
         for (i = 0; i < bloomStream->k; ++i) {
        __u64 k = (h1 + i * h2) % bloomStream->partition; // bit to set
        __u64 j = k + (i * bloomStream->partition);       // in parition 'i'
        setBitXOR(bloomStream->bloomPrime, (__u32)j);
        bloomStream->counter[(__u32)j]++;


            freqCount = bloomStream->counterHistory[(__u32)j];
             if(minCount > freqCount){
                index = (__u32)j;
                minCount = freqCount;
            }


        }

        swapBitmaps(&bloomStream->bloomPrime , &bloomStream->bloom);
        setBit(bloomStream->lowestCounter, index);
       
    }

    // BloomStream->size++;

}

__u32 findInBloomStream(struct BloomStream * bloomStream, __u64 item){


	// MitzenmacherKirsch optimization
	__u64 z = magicHash64(item);
	__u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;
    __u32 index = 0;
    __u32 found = 0;

    bloomStream->membership = 0;
    bloomStream->temperature  = 0;

    __u64 k = 0; // bit to set
    __u64 j = 0;       // in parition 'i'
    __u32 minCount = UINT_MAX;
    __u32 freqCount = 0;
    

    for (i = 0; i < bloomStream->k; ++i) {
         k = (h1 + i * h2) % bloomStream->partition; // bit to set
         j = k + (i * bloomStream->partition);       // in parition 'i'

        if(getBit(bloomStream->bloom, j)){
            freqCount = bloomStream->counter[(__u32)j];
        }
        else{
            freqCount = 0;
        }

        if(minCount > freqCount){
            index = (__u32)j;
            minCount = freqCount;
        }
        
    }

    found = getBit(bloomStream->bloomHistory, index) | getBit(bloomStream->bloom, index) | getBit(bloomStream->bloomPrime, index);

    if(found){
        bloomStream->membership = 1;
        bloomStream->temperature = bloomStream->counterHistory[index];
        

        printf("FOUND item : %u counter : %u \n", item, bloomStream->counterHistory[index]);
    }
    else{
        bloomStream->membership = 0;
        bloomStream->temperature = 0;


        printf("NOT FOUND\n");
    }

	return bloomStream->membership;
}


void aggregateBloomFilterToHistory(struct BloomStream * bloomStream){

    __u32 i;

    for(i=0 ; i< bloomStream->size ; i++){

        if(!(bloomStream->counterHistory[i]/2)){
            clearBit(bloomStream->bloomHistory, i);
        }

        // if(getBit(bloomStream->lowestCounter, i)){
            if(getBit(bloomStream->bloom, i) | getBit(bloomStream->bloomPrime, i) | getBit(bloomStream->bloomHistory, i)){
                setBit(bloomStream->bloomHistory, i);
            }
        // }

        bloomStream->counterHistory[i] = (bloomStream->counterHistory[i]/2) + bloomStream->counter[i];
        bloomStream->counter[i] = 0;
    }

    clearBitmap(bloomStream->bloom);
    clearBitmap(bloomStream->bloomPrime);


}
