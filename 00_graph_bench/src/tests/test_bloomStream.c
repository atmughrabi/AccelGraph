// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : test_bloomStream.c
// Create : 2019-09-28 15:21:12
// Revise : 2019-09-28 15:36:29
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : test_bloomStream.c
// Create : 2019-06-21 17:15:17
// Revise : 2019-09-28 15:21:12
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <linux/types.h>

#include "bloomStream.h"

int numThreads;

int main(int argc, char *argv[])
{


    __u32 i;
    __u32 size = 3355;
    __u32 *array = (__u32 *) malloc(size * sizeof(__u32));

    __u32 found = 0;
    __u32 falsepos = 0;
    printf("%s\n", "Create bloomStream" );
    struct BloomStream *bloomStream = newBloomStream(size, 4);


    for(i = 0; i < 10 ; i++ )
    {

        addToBloomStream(bloomStream, &array[i]);

    }

    for(i = 0; i < 15 ; i++ )
    {

        addToBloomStream(bloomStream, &array[i]);

    }

    for(i = 0; i < 20 ; i++ )
    {

        addToBloomStream(bloomStream, &array[i]);

    }

    for(i = 0; i < 25 ; i++ )
    {

        addToBloomStream(bloomStream, &array[i]);

    }

    for(i = 0; i < 10 ; i++ )
    {

        addToBloomStream(bloomStream, &array[i]);

    }

    for(i = 0; i < 10 ; i++ )
    {

        addToBloomStream(bloomStream, &array[i]);

    }

    aggregateBloomFilterToHistory(bloomStream);

    for(i = 0; i < 10 ; i++ )
    {

        addToBloomStream(bloomStream, &array[i]);

    }

    aggregateBloomFilterToHistory(bloomStream);

    printf("%s\n", "FIND ONLY Operation *****************************" );

    for(i = 0; i < 100 ; i++ )
    {

        found = findInBloomStream(bloomStream, &array[i]);

    }


    printf("%.24f \n", (falsepos / (float)size) );

    printf("%s\n", "free BloomStream" );
    freeBloomStream(bloomStream);




    return 0;

}