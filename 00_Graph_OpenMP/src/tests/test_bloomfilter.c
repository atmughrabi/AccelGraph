#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


#include "bloomFilter.h"

#include "bloomMultiHash.h"

int numThreads;

int main(int argc, char *argv[])
{


    __u32 i;
    __u32 size = 3355;
    __u32 found = 0;
    __u32 falsepos = 0;
    printf("%s\n", "Create bloomfilter" );
    struct BloomFilter *bloomFilter = newBloomFilter(size, 12);


    for(i = 0; i < 100 ; i++ )
    {

        addToBloomFilter(bloomFilter, i);

    }

    for(i = 0; i < size ; i++ )
    {

        found = findInBloomFilter(bloomFilter, i);

        if(found && i > 100)
        {
            falsepos++;
            printf("%s %u \n", "Found", i);
        }

    }


    printf("%.24f \n", (falsepos / (float)size) );

    printf("%s\n", "free BloomFilter" );
    freeBloomFilter(bloomFilter);




    return 0;

}