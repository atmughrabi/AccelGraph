#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "myMalloc.h"
#include "timer.h"
#include "mt19937.h"
#include "bloomFilter.h"
#include "bloomMultiHash.h"

int numThreads;
mt19937state *mt19937var;

int main(int argc, char *argv[])
{


    __u32 i;
    __u32 size = 194510;
    __u32 found = 0;
    __u32 falsepos = 0;
    double error = 0.01;

    printf("%s\n", "Create bloomfilter" );
    struct BloomFilter *bloomFilter = newBloomFilter(size, 12);
    struct BloomMultiHash *bloomMultiHash  = newBloomMultiHash(size, error);

    printf("K: %u partition %u \n",bloomMultiHash->k );

    for(i = 0; i < 1000 ; i++ )
    {

        // addToBloomFilter(bloomFilter, i);
        addToBloomMultiHash(bloomMultiHash,i);

    }

     for(i = 0; i < 1000 ; i++ )
    {

        // addToBloomFilter(bloomFilter, i);
        addToBloomMultiHash(bloomMultiHash,i);

    }

    // for(i = 0; i < size ; i++ )
    // {

    //     found = findInBloomFilter(bloomFilter, i);
    //     if(found && i > 1000)
    //     {
    //         falsepos++;
    //         printf("%s %u \n", "Found", i);
    //     }

    // }

    //    for(i = 0; i < bloomMultiHash->size ; i++ )
    // {

    //   printf("[%u]=%u \n",i, bloomMultiHash->counter[i]);
    // }

    //   for(i = 0; i < bloomMultiHash->size ; i++ )
    // {

    //     found = findInBloomMultiHash(bloomMultiHash, i);

    //     if(found)
    //     {
    //         falsepos++;
    //         printf("%s %u \n", "Found MHB", i);
    //     }

    // }



    printf("%.24f \n", (falsepos / (float)size) );

    printf("%s\n", "free BloomFilter" );
    freeBloomFilter(bloomFilter);
    freeBloomMultiHash(bloomMultiHash);



    return 0;

}