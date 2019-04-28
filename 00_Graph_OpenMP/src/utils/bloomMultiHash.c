#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "bloomMultiHash.h"
#include "bitmap.h"
#include "hash.h"
#include <limits.h>
#include "myMalloc.h"

struct BloomMultiHash *newBloomMultiHash(__u32 size, __u32 k)
{

    __u32 i;
    __u32 alignedSize = ((size + kBitsPerWord - 1) / kBitsPerWord) * kBitsPerWord;
    // __u32 nextPrimePartition = findNextPrime((alignedSize/k));


    // alignedSize = (((nextPrimePartition*k)+kBitsPerWord - 1)/kBitsPerWord)*kBitsPerWord;



    struct BloomMultiHash *bloomMultiHash = (struct BloomMultiHash *) my_malloc( sizeof(struct BloomMultiHash));
    bloomMultiHash->counter = (__u32 *) my_malloc(alignedSize * sizeof(__u32));
    bloomMultiHash->counterHistory = (__u32 *) my_malloc(alignedSize * sizeof(__u32));

    for(i = 0 ; i < alignedSize; i++)
    {
        bloomMultiHash->counter[i] = 0;
        bloomMultiHash->counterHistory[i] = 0;
    }

    bloomMultiHash->bloom = newBitmap(size);
    bloomMultiHash->bloomPrime = newBitmap(size);
    bloomMultiHash->bloomHistory = newBitmap(size);
    bloomMultiHash->lowestCounter = newBitmap(size);


    bloomMultiHash->size = alignedSize;
    bloomMultiHash->k = k;
    bloomMultiHash->partition = bloomMultiHash->size / bloomMultiHash->k;
    bloomMultiHash->membership = 0;
    bloomMultiHash->temperature  = 0;

    bloomMultiHash->threashold = 0;
    bloomMultiHash->decayPeriod  = 0;
    bloomMultiHash->numIO = 0;



    return bloomMultiHash;

}

void freeBloomMultiHash( struct BloomMultiHash *bloomMultiHash)
{

    if(bloomMultiHash)
    {
        freeBitmap(bloomMultiHash->bloom);
        freeBitmap(bloomMultiHash->bloomPrime);
        freeBitmap(bloomMultiHash->bloomHistory);
        free(bloomMultiHash->counter);
        free(bloomMultiHash->counterHistory);
        free(bloomMultiHash);
    }


}
void clearBloomMultiHash( struct BloomMultiHash *bloomMultiHash)
{

    clearBitmap(bloomMultiHash->bloom);
    clearBitmap(bloomMultiHash->bloomPrime);

}


void addToBloomMultiHash(struct BloomMultiHash *bloomMultiHash, __u32 item)
{


    __u64 z = magicHash64((__u64)item);
    __u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;
    __u32 minCount = UINT_MAX;
    __u32 freqCount = 0;
    __u32 index = 0;

    __u32 found = findInBloomMultiHash(bloomMultiHash, item);


    if(!found)
    {
        for (i = 0; i < bloomMultiHash->k; ++i)
        {
            __u64 k = (h1 + i * h2) % bloomMultiHash->partition; // bit to set
            __u64 j = k + (i * bloomMultiHash->partition);       // in parition 'i'
            setBitXOR(bloomMultiHash->bloom, (__u32)j);
        }

    }
    else
    {
        for (i = 0; i < bloomMultiHash->k; ++i)
        {
            __u64 k = (h1 + i * h2) % bloomMultiHash->partition; // bit to set
            __u64 j = k + (i * bloomMultiHash->partition);       // in parition 'i'
            setBitXOR(bloomMultiHash->bloomPrime, (__u32)j);
            bloomMultiHash->counter[(__u32)j]++;


            freqCount = bloomMultiHash->counterHistory[(__u32)j];
            if(minCount > freqCount)
            {
                index = (__u32)j;
                minCount = freqCount;
            }


        }

        swapBitmaps(&bloomMultiHash->bloomPrime, &bloomMultiHash->bloom);
        setBit(bloomMultiHash->lowestCounter, index);

    }

    // BloomMultiHash->size++;

}

__u32 findInBloomMultiHash(struct BloomMultiHash *bloomMultiHash, __u32 item)
{


    // MitzenmacherKirsch optimization
    __u64 z = magicHash64((__u64)item);
    __u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;
    __u32 index = 0;
    __u32 found = 0;

    bloomMultiHash->membership = 0;
    bloomMultiHash->temperature  = 0;

    __u64 k = 0; // bit to set
    __u64 j = 0;       // in parition 'i'
    __u32 minCount = UINT_MAX;
    __u32 freqCount = 0;


    for (i = 0; i < bloomMultiHash->k; ++i)
    {
        k = (h1 + i * h2) % bloomMultiHash->partition; // bit to set
        j = k + (i * bloomMultiHash->partition);       // in parition 'i'

        if(getBit(bloomMultiHash->bloom, j))
        {
            freqCount = bloomMultiHash->counter[(__u32)j];
        }
        else
        {
            freqCount = 0;
        }

        if(minCount > freqCount)
        {
            index = (__u32)j;
            minCount = freqCount;
        }

    }

    found = getBit(bloomMultiHash->bloomHistory, index) | getBit(bloomMultiHash->bloom, index) | getBit(bloomMultiHash->bloomPrime, index);

    if(found)
    {
        bloomMultiHash->membership = 1;
        bloomMultiHash->temperature = bloomMultiHash->counterHistory[index];


        printf("FOUND item : %u counter : %u \n", item, bloomMultiHash->counterHistory[index]);
    }
    else
    {
        bloomMultiHash->membership = 0;
        bloomMultiHash->temperature = 0;


        printf("NOT FOUND\n");
    }

    return bloomMultiHash->membership;
}


