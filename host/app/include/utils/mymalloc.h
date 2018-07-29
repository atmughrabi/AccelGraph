#ifndef MYMALLOC_H
#define MYMALLOC_H

// extern int errno ;

char *strerror(int errnum);
void * my_aligned_alloc( size_t size );
void * my_malloc( size_t size );

#endif