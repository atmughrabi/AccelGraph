#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <argp.h>
#include <stdbool.h>
#include <omp.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <argp.h>
#include <stdbool.h>
#include <omp.h>


#include "graphStats.h"
#include "edgeList.h"
#include "myMalloc.h"

#include "graphCSR.h"
#include "graphAdjLinkedList.h"
#include "graphAdjArrayList.h"
#include "graphGrid.h"

#include "mt19937.h"
#include "graphConfig.h"
#include "timer.h"
#include "graphRun.h"

#include "BFS.h"
#include "DFS.h"
#include "pageRank.h"
#include "incrementalAggregation.h"
#include "bellmanFord.h"
#include "SSSP.h"
#include "connectedComponents.h"
#include "triangleCount.h"

#include "libcxl.h"

int numThreads;
mt19937state *mt19937var;

#define MMIO_ADDR             0x3fffff8             // 0x3fffff8 >> 2 = 0xfffffe

#ifdef  SIM
#define DEVICE              "/dev/cxl/afu0.0d"
#else
#define DEVICE              "/dev/cxl/afu1.0d"
#endif


typedef struct
{
    __u64 size;
    void *stripe1;
    void *stripe2;
    void *parity;
    __u64 done;
} parity_request;


int main(int argc, char *argv[])
{
    struct cxl_afu_h *afu;

    parity_request *example;
    size_t size = 256;


    afu = cxl_afu_open_dev("/dev/cxl/afu0.0d");
    if(!afu)
    {
        printf("Failed to open AFU: %m\n");
        return 1;
    }

    example = my_malloc(sizeof(*example));
    example->size = 256;
    example->stripe1 = my_malloc(size);
    example->stripe2 = my_malloc(size);
    example->parity = my_malloc(size);

    memcpy(example->stripe1,
           "asfb190jwqsefx0amxAqa1nlkaf78sa0g&0ha8dngj3t21078fnajl38n32j3np2"
           "x3t8wefiankxkfmgm ncmbqx8ehn2jkaeubgfbuapwnjxkg09f0w9es80872981"
           "asfb190jwqsefx0amxAqa1nlkaf78sa0g&0ha8dngj3t21078fnajl38n32j3np2"
           "x3t8wefiankxkfmgm ncmbqx8ehn2jkaeubgfbuapwnjxkg09f0w9es80872981",
           size);
    memcpy(example->stripe2,
           "\x35\x1b\x07\x16\x11\x50\x43\x4a\x04\x1e\x1e\x00\x46\x08\x42\x0e"
           "\x1d\x1d\x33\x51\x11\x50\x1c\x05\x1f\x18\x47\x17\x6c\x1b\x08\x43"
           "\x47\x4f\x43\x48\x04\x40\x05\x0d\x13\x06\x4a\x54\x45\x59\x51\x43"
           "\x18\x2f\x49\x0c\x4a\x09\x4b\x48\x0b\x50\x46\x03\x5d\x09\x50\x46"
           "\x17\x13\x07\x5d\x12\x4b\x46\x20\x46\x0a\x4b\x19\x07\x15\x02\x47"
           "\x01\x49\x05\x06\x4d\x16\x1e\x58\x4b\x00\x0d\x4e\x46\x02\x02\x12"
           "\x45\x07\x17\x09\x08\x0b\x1b\x06\x50\x18\x00\x4a\x0b\x04\x0a\x55"
           "\x19\x14\x55\x16\x55\x45\x14\x5d\x51\x4a\x17\x41\x56\x57\x5f"
           "\x35\x1b\x07\x16\x11\x50\x43\x4a\x04\x1e\x1e\x00\x46\x08\x42\x0e"
           "\x1d\x1d\x33\x51\x11\x50\x1c\x05\x1f\x18\x47\x17\x6c\x1b\x08\x43"
           "\x47\x4f\x43\x48\x04\x40\x05\x0d\x13\x06\x4a\x54\x45\x59\x51\x43"
           "\x18\x2f\x49\x0c\x4a\x09\x4b\x48\x0b\x50\x46\x03\x5d\x09\x50\x46"
           "\x17\x13\x07\x5d\x12\x4b\x46\x20\x46\x0a\x4b\x19\x07\x15\x02\x47"
           "\x01\x49\x05\x06\x4d\x16\x1e\x58\x4b\x00\x0d\x4e\x46\x02\x02\x12"
           "\x45\x07\x17\x09\x08\x0b\x1b\x06\x50\x18\x00\x4a\x0b\x04\x0a\x55"
           "\x19\x14\x55\x16\x55\x45\x14\x5d\x51\x4a\x17\x41\x56\x57\x5f",
           size);
    example->done = 0;

    printf("[example structure\n");
    printf("  example: %p\n", example);
    printf("  example->size: %llu\n", example->size);
    printf("  example->stripe1: %p\n", example->stripe1);
    printf("  example->stripe2: %p\n", example->stripe2);
    printf("  example->parity: %p\n", example->parity);
    printf("  &(example->done): %p\n", &(example->done));

    cxl_afu_attach(afu, (__u64)example);
    printf("Attached to AFU\n");

    printf("Waiting for completion by AFU\n");
    while(!example->done)
    {
        sleep(1);
    }

    printf("PARITY:\n%s\n", (char *)example->parity);

    printf("Releasing AFU\n");
    cxl_afu_free(afu);

    return 0;
}
