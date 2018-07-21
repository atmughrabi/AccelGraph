#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <err.h>

#include "edgelist.h"
#include "capienv.h"

// read edge file to edge_array in memory

struct EdgeList* newEdgeList( int num_edges){

        struct EdgeList* newEdgeList = (struct EdgeList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct EdgeList));

        newEdgeList->num_edges = num_edges;

        newEdgeList->edges_array = (struct Edge*) aligned_alloc(CACHELINE_BYTES, num_edges * sizeof(struct Edge));;
       
        return newEdgeList;

}

struct EdgeList* readEdgeListstxt(const char * fname)
{


        int fd = open(fname, O_RDONLY);
        struct stat fs;
        char *buf_addr, *buf_addr_end;
        char *begin, *end, c;
 
        if (fd == -1) {
                err(1, "open: %s", fname);
                return 0;
        }
 
        if (fstat(fd, &fs) == -1) {
                err(1, "stat: %s", fname);
                return 0;
        }
 
        /* fs.st_size could have been 0 actually */
        buf_addr = mmap(0, fs.st_size, PROT_WRITE, MAP_PRIVATE, fd, 0);

        printf("#Size: %llu\n", (__u64)fs.st_size);

        if (buf_addr == (void*) -1) {
                err(1, "mmap: %s", fname);
                close(fd);
                return 0;
        }
 
        buf_addr_end = buf_addr + fs.st_size;
 
        begin = end = buf_addr;
        
 
        munmap(buf_addr, fs.st_size);
        close(fd);
        return 1;
}

void edgeListPrint(struct EdgeList* edgeList){







}