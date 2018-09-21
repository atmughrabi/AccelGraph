#ifndef MYMALLOC_H
#define MYMALLOC_H

// extern int errno ;

#define ALIGNED 1
#define CACHELINE_BYTES 128

char *strerror(int errnum);
void * my_aligned_malloc( size_t size );
void * my_malloc( size_t size );

#endif