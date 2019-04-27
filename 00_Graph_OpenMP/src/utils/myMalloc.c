#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include "myMalloc.h"

extern int errno ;

void * aligned_malloc( size_t size )
{

	void *dataOut = aligned_alloc(CACHELINE_BYTES, size);
    // void *dataOut = malloc ( size ) ;
    if ( !dataOut )
    {
        fprintf ( stderr, "Error, aligned_alloc: %s\n", strerror ( errno )) ;
        exit ( EXIT_FAILURE ) ;
    }
    return dataOut ;
}

void * regular_malloc( size_t size )
{

    // void *dataOut = aligned_alloc(CACHELINE_BYTES, size);
    void *dataOut = malloc ( size ) ;
    if ( !dataOut )
    {
        fprintf ( stderr, "Error, malloc: %s\n", strerror ( errno )) ;
        exit ( EXIT_FAILURE ) ;
    }
    return dataOut ;
}

void * my_malloc( size_t size )
{

    // void *dataOut = aligned_alloc(CACHELINE_BYTES, size);
    void *dataOut = NULL;
    #if ALIGNED
       dataOut =   aligned_malloc(size);
    #else
       dataOut =   regular_malloc(size);
    #endif

    return dataOut;
}


