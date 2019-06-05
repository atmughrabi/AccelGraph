#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <linux/types.h>
#include "bloomMultiHash.h"
#include "bitmap.h"
#include "hash.h"
#include <limits.h>
#include "myMalloc.h"

#include "graphConfig.h"

struct BloomMultiHash *newBloomMultiHash(__u32 size, double error)
{

    // __u32 n = ceil(m / (-k / log(1 - exp(log(error) / k))))
    // __u32 error = pow(1 - exp(-k / (m / n)), k)
    __u32 m = ceil((size * log(error)) / log(1 / pow(2, log(2))));
    // __u32 k = round((m / n) * log(2));

    __u32 i;
    __u32 alignedSize = ((m + kBitsPerWord - 1) / kBitsPerWord) * kBitsPerWord;





    struct BloomMultiHash *bloomMultiHash = (struct BloomMultiHash *) my_malloc( sizeof(struct BloomMultiHash));
    bloomMultiHash->counter = (__u32 *) my_malloc(alignedSize * sizeof(__u32));
    bloomMultiHash->recency = newBitmap(alignedSize);


    for(i = 0 ; i < alignedSize; i++)
    {
        bloomMultiHash->counter[i] = 0;
    }

    bloomMultiHash->size = alignedSize;

    bloomMultiHash->threashold = 7;
    bloomMultiHash->decayPeriod  = alignedSize;
    bloomMultiHash->numIO = 0;

    bloomMultiHash->error = error;

    double num = log(bloomMultiHash->error);
    double denom = 0.480453013918201; // ln(2)^2
    bloomMultiHash->bpe = -(num / denom);

    bloomMultiHash->k = (__u32)ceil(0.693147180559945 * bloomMultiHash->bpe);  // ln(2)
    bloomMultiHash->partition = bloomMultiHash->size / bloomMultiHash->k;

    printf("n: %u \n", size);
    printf("p: %.2f%% \n", error);
    printf("m: %u \n", m);
    printf("k: %u \n", bloomMultiHash->k );

    return bloomMultiHash;

}

void freeBloomMultiHash( struct BloomMultiHash *bloomMultiHash)
{
    if(bloomMultiHash)
    {
        freeBitmap(bloomMultiHash->recency);
        free(bloomMultiHash->counter);
        free(bloomMultiHash);
    }
}

void addToBloomMultiHash(struct BloomMultiHash *bloomMultiHash, __u64 item)
{

    __u64 z = magicHash64(item);
    __u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;

    bloomMultiHash->numIO++;

    for (i = 0; i < bloomMultiHash->k; ++i)
    {
        __u64 k = (h1 + i * h2) % bloomMultiHash->partition; // bit to set
        __u64 j = k + (i * bloomMultiHash->partition);       // in parition 'i'

        // if(getBit(bloomMultiHash->recency, j))
        // {
            // bloomMultiHash->counter[(__u32)j] += 2;
            // printf("%u %u %u\n",j,bloomMultiHash->counter[(__u32)j], item );
        // }
        // else
        // {
            bloomMultiHash->counter[(__u32)j]++;
            // printf("%u %u %u\n",j,bloomMultiHash->counter[(__u32)j], item );
            // setBit(bloomMultiHash->recency, j);
        // }

    }

    if(bloomMultiHash->numIO > bloomMultiHash->decayPeriod)
    {
        decayBloomMultiHash(bloomMultiHash);
    }

}

__u32 findInBloomMultiHash(struct BloomMultiHash *bloomMultiHash, __u64 item)
{


    // MitzenmacherKirsch optimization
    __u64 z = magicHash64(item);
    __u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;

    __u64 k = 0; // bit to set
    __u64 j = 0;       // in parition 'i'
    __u32 freqCount = 0;


    for (i = 0; i < bloomMultiHash->k; ++i)
    {
        k = (h1 + i * h2) % bloomMultiHash->partition; // bit to set
        j = k + (i * bloomMultiHash->partition);       // in parition 'i'


        freqCount = bloomMultiHash->counter[(__u32)j];

        if(freqCount < bloomMultiHash->threashold)
            return 0;

    }

    return 1;
}


void decayBloomMultiHash(struct BloomMultiHash *bloomMultiHash)
{


    __u64 i;
    for(i = 0 ; i < bloomMultiHash->size; i++)
    {
        bloomMultiHash->counter[i] /= 2;
    }

    // clearBitmap(bloomMultiHash->recency);

    bloomMultiHash->numIO = 0;

}