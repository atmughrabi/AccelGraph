#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <err.h>

#include "edgelist.h"

// read edge file to edge_array in memory
struct EdgeList* read_edgelists(const char * fname)
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

        if (buf_addr == (void*) -1) {
                err(1, "mmap: %s", fname);
                close(fd);
                return 0;
        }
 
        buf_addr_end = buf_addr + fs.st_size;
 
        begin = end = buf_addr;
        while (1) {
                if (! (*end == '\r' || *end == '\n')) {
                        if (++end < buf_addr_end) continue;
                } else if (1 + end < buf_addr_end) {
                        /* see if we got "\r\n" or "\n\r" here */
                        c = *(1 + end);
                        if ( (c == '\r' || c == '\n') && c != *end)
                                ++end;
                }
 
                /* call the call back and check error indication. Announce
                   error here, because we didn't tell call_back the file name */
                if ((begin = ++end) >= buf_addr_end)
                        break;
        }
 
        munmap(buf_addr, fs.st_size);
        close(fd);
        return 1;
}

void edgelist_print(struct EdgeList* edgeList){









}