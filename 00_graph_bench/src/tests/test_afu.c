// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : test_afu.c
// Create : 2019-09-28 15:19:20
// Revise : 2019-09-30 20:25:26
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
// File   : test_afu.c
// Create : 2019-09-28 15:14:53
// Revise : 2019-09-28 15:19:20
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------

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

#define ALGO_STATUS            0x3fffff8             // 0x3fffff8 >> 2 = 0xfffffe
#define ALGO_REQUEST           0x3fffff0             // 0x3fffff8 >> 2 = 0xfffffc
#define ERROR_REG              0x3FFFFE8

#ifdef  SIM
#define DEVICE              "/dev/cxl/afu0.0d"
#else
#define DEVICE              "/dev/cxl/afu1.0d"
#endif

struct __attribute__((__packed__)) WEDGraphCSR
{
    __u32 num_edges;                    // 4-Bytes
    __u32 num_vertices;                 // 4-Bytes
    __u32 max_weight;                   // 4-Bytes
    void *vertex_out_degree;            // 8-Bytes
    void *vertex_in_degree;             // 8-Bytes
    void *vertex_edges_idx;             // 8-Bytes
    void *edges_array_weight;           // 8-Bytes
    void *edges_array_src;              // 8-Bytes
    void *edges_array_dest;             // 8-Bytes
    //---------------------------------------------------//
    void *inverse_vertex_out_degree;    // 8-Bytes  --// 64bytes
    //---------------------------------------------------//
    void *inverse_vertex_in_degree;     // 8-Bytes
    void *inverse_vertex_edges_idx;     // 8-Bytes
    void *inverse_edges_array_weight;   // 8-Bytes
    void *inverse_edges_array_src;      // 8-Bytes
    void *inverse_edges_array_dest;     // 8-Bytes
    void *auxiliary1;                  // 8-Bytes
    void *auxiliary2;                  // 8-Bytes
    __u32 done;                         // 4-Bytes
}; // 108-bytes used from 128-Bytes WED


// "   mm                        ""#             mmm                       #     \n"
// "   ##    mmm    mmm    mmm     #           m"   "  m mm   mmm   mmmm   # mm  \n"
// "  #  #  #"  "  #"  "  #"  #    #           #   mm  #"  " "   #  #" "#  #"  # \n"
// "  #mm#  #      #      #""""    #     """   #    #  #     m"""#  #   #  #   # \n"
// " #    # "#mm"  "#mm"  "#mm"    "mm          "mmm"  #     "mm"#  ##m#"  #   # \n"
// "                                                                #            \n"

struct  WEDGraphCSR *mapGraphCSRToWED(struct GraphCSR *graph)
{

    struct WEDGraphCSR *wed = my_malloc(sizeof(struct WEDGraphCSR));

    wed->num_edges    = graph->num_edges;
    wed->num_vertices = graph->num_vertices;
#if WEIGHTED
    wed->max_weight   = graph->max_weight;
#else
    wed->max_weight   = 0;
#endif

    wed->vertex_out_degree  = graph->vertices->out_degree;
    wed->vertex_in_degree   = graph->vertices->in_degree;
    wed->vertex_edges_idx   = graph->vertices->edges_idx;

    wed->edges_array_src    = graph->sorted_edges_array->edges_array_src;
    wed->edges_array_dest   = graph->sorted_edges_array->edges_array_dest;
#if WEIGHTED
    wed->edges_array_weight = graph->sorted_edges_array->edges_array_weight;
#endif

#if DIRECTED
    wed->inverse_vertex_out_degree  = graph->inverse_vertices->out_degree;
    wed->inverse_vertex_in_degree   = graph->inverse_vertices->in_degree;
    wed->inverse_vertex_edges_idx   = graph->inverse_vertices->edges_idx;

    wed->inverse_edges_array_src    = graph->inverse_sorted_edges_array->edges_array_src;
    wed->inverse_edges_array_dest   = graph->inverse_sorted_edges_array->edges_array_dest;
#if WEIGHTED
    wed->inverse_edges_array_weight = graph->inverse_sorted_edges_array->edges_array_weight;
#endif
#endif



    wed->done = 0;

    return wed;
}

void printMMIO_error( uint64_t error )
{

    if(error >> 12)
    {
        switch(error >> 12)
        {
        case 1:
            printf("(BIT-12) Job Address Error\n");
            break;
        case 2:
            printf("(BIT-13) Job Command Error\n");
            break;
        }
    }
    else if(error >> 10)
    {
        switch(error >> 10)
        {
        case 1:
            printf("(BIT-10) MMIO Address Parity-Error\n");
            break;
        case 2:
            printf("(BIT-11) MMIO Data Parity-Error\n");
            break;
        }

    }
    else if(error >> 9)
    {
        printf("(BIT-9) Write Tag Parity-Error\n");
    }
    else if(error >> 7)
    {
        switch(error >> 7)
        {
        case 1:
            printf("(BIT-7) Read Data Parity-Error\n");
            break;
        case 2:
            printf("(BIT-8) Read Tag Parity-Error\n");
            break;
        }

    }
    else if(error >> 0)
    {
        switch(error >> 0)
        {
        case 1:
            printf("(BIT-0) Response AERROR\n");
            break;
        case 2:
            printf("(BIT-1) Response DERROR\n");
            break;
        case 4:
            printf("(BIT-2) Response FAILD\n");
            break;
        case 8:
            printf("(BIT-3) Response FAULT\n");
            break;
        case 64:
            printf("(BIT-6) Response tag Parity-Error\n");
            break;
        }
    }

}

void printWEDGraphCSRPointers(struct  WEDGraphCSR *wed)
{

    printf("[WEDGraphCSR structure\n");
    printf("  wed: %p\n", wed);
    printf("  wed->num_edges: %u\n", wed->num_edges);
    printf("  wed->num_vertices: %u\n", wed->num_vertices);
#if WEIGHTED
    printf("  wed->max_weight: %u\n", wed->max_weight);
#endif
    printf("  wed->vertex_in_degree: %p\n", wed->vertex_in_degree);
    printf("  wed->vertex_out_degree: %p\n", wed->vertex_out_degree);
    printf("  wed->vertex_edges_idx: %p\n", wed->vertex_edges_idx);

    printf("  wed->edges_array_src: %p\n", wed->edges_array_src);
    printf("  wed->edges_array_dest: %p\n", wed->edges_array_dest);
#if WEIGHTED
    printf("  wed->edges_array_weight: %p\n", wed->edges_array_weight);
#endif

#if DIRECTED
    printf("  wed->inverse_vertex_in_degree: %p\n", wed->inverse_vertex_in_degree);
    printf("  wed->inverse_vertex_out_degree: %p\n", wed->inverse_vertex_out_degree);
    printf("  wed->inverse_vertex_edges_idx: %p\n", wed->inverse_vertex_edges_idx);

    printf("  wed->inverse_edges_array_src: %p\n", wed->inverse_edges_array_src);
    printf("  wed->inverse_edges_array_dest: %p\n", wed->inverse_edges_array_dest);
#if WEIGHTED
    printf("  wed->inverse_edges_array_weight: %p\n", wed->inverse_edges_array_weight);
#endif
#endif

    printf("  wed->auxiliary1: %p\n", wed->auxiliary1);
    printf("  wed->auxiliary2: %p\n", wed->auxiliary2);
    printf("  wed->done: %p\n", &(wed->done));

}

void printWEDGraphCSRVertex(struct  WEDGraphCSR *wed)
{

    __u32 i;

    for (i = 0; i <  wed->num_vertices; ++i)
    {
        printf("v-> %u\n", i);
        // printf("  wed->vertex_out_degree: %u\n",    ((__u32 *)wed->vertex_out_degree)[i]);
        // printf("  wed->vertex_in_degree: %u\n",     ((__u32 *)wed->vertex_in_degree)[i]);
        // printf("  wed->vertex_edges_idx: %u\n",     ((__u32 *)wed->vertex_edges_idx)[i]);

#if DIRECTED
        printf("  wed->inverse_vertex_out_degree:%u\n", ((__u32 *)wed->inverse_vertex_out_degree)[i]);
        // printf("  wed->prnext: %u\n", ((__u32 *)wed->auxiliary2)[i]);
        printf("  wed->inverse_vertex_edges_idx: %u\n", ((__u32 *)wed->inverse_vertex_edges_idx)[i]);
#endif
    }
    // printf("\n");
    // for(i = 0; i < wed->num_edges ; i++)
    // {
    //     printf("%u src:  %u dest %u\n", i, ((__u32 *)wed->inverse_edges_array_src)[i], ((__u32 *)wed->inverse_edges_array_dest)[i]);
    // }

}

int
main (int argc, char **argv)
{

    struct cxl_afu_h *afu;
    struct WEDGraphCSR *wedGraphCSR;




    struct Arguments arguments;
    /* Default values. */

    arguments.wflag = 0;
    arguments.xflag = 0;
    arguments.sflag = 0;
    arguments.dflag = 0;
    arguments.iterations = 200;
    arguments.trials = 100;
    arguments.epsilon = 0.0001;
    arguments.root = 5319;
    arguments.algorithm = 0;
    arguments.datastructure = 0; // CSR DataStructure
    arguments.pushpull = 0;
    arguments.sort = 0;
    arguments.lmode = 0;
    arguments.symmetric = 0;
    arguments.weighted = 0;
    arguments.delta = 1;
    arguments.numThreads = 4;
    // arguments.fnameb = "../03_test_graphs/test/graph.wbin";
    arguments.fnameb = "../03_test_graphs/v300_e2730/graph.wbin";
    // arguments.fnameb = "../03_test_graphs/v51_e1021/graph.wbin";
    // arguments.fnameb = "../03_test_graphs/p2p-Gnutella31/graph.wbin";
    arguments.fnameb_format = 1;
    arguments.convert_format = 1;

    void *graph = NULL;

    numThreads =  arguments.numThreads;

    struct Timer *timer = (struct Timer *) my_malloc(sizeof(struct Timer));


    mt19937var = (mt19937state *) my_malloc(sizeof(mt19937state));
    initializeMersenneState (mt19937var, 27491095);

    omp_set_nested(1);
    omp_set_num_threads(numThreads);




    printf("*-----------------------------------------------------*\n");
    printf("| %-20s %-30u | \n", "Number of Threads :", numThreads);
    printf(" -----------------------------------------------------\n");




    // ********************************************************************************************
    // ***************                  CSR DataStructure                            **************
    // ********************************************************************************************


    graph = generateGraphDataStructure(&arguments);


    __u32 *divclause = (__u32 *) my_malloc(((struct GraphCSR *)graph)->num_vertices * sizeof(__u32));
    __u32 *prnext = (__u32 *) my_malloc(((struct GraphCSR *)graph)->num_vertices * sizeof(__u32));

    for (__u32 i = 0; i < ((struct GraphCSR *)graph)->num_vertices; ++i)
    {
        divclause[i] = 1;
        prnext[i] = 0;
    }

    // (struct GraphCSR *)graph
    wedGraphCSR = mapGraphCSRToWED((struct GraphCSR *)graph);

    wedGraphCSR->auxiliary1 = divclause;
    wedGraphCSR->auxiliary2 = prnext;

    // ********************************************************************************************
    // ***************                  CSR DataStructure                            **************
    // ********************************************************************************************


    // printWEDGraphCSRVertex(wedGraphCSR);

    printWEDGraphCSRPointers(wedGraphCSR);


    // ********************************************************************************************
    // ***************                 Setup AFU                                     **************
    // ********************************************************************************************


    afu = cxl_afu_open_dev("/dev/cxl/afu0.0d");
    if(!afu)
    {
        printf("Failed to open AFU: %m\n");
        return 1;
    }

    cxl_afu_attach(afu, (__u64)wedGraphCSR);
    printf("Attached to AFU\n");

    int base_address = cxl_mmio_map (afu, CXL_MMIO_BIG_ENDIAN);

    if (base_address < 0)
    {
        printf("fail cxl_mmio_map %d", base_address);
        return -1;
    }
    else
    {
        printf("succ cxl_mmio_map %d", base_address);
    }

    // ********************************************************************************************
    // ***************                 Setup AFU                                     **************
    // ********************************************************************************************


    uint64_t algo_status = 0;
    uint64_t num_cu      = 64;
    uint64_t error       = 0;

    cxl_mmio_write64(afu, ALGO_REQUEST, num_cu);

    printf("Waiting for completion by AFU\n");
    do
    {
        cxl_mmio_read64(afu, ALGO_STATUS, &algo_status);
        cxl_mmio_read64(afu, ERROR_REG, &error);
    }
    while((!algo_status) && (!error));

    printMMIO_error(error);
    printf("Vertices: %lu\n", ((algo_status << 32) >> 32));
    printf("Edges: %lu\n", ((algo_status) >> 32));

    printf("Releasing AFU\n");
    cxl_mmio_unmap (afu);
    cxl_afu_free(afu);

    free(timer);
    exit (0);
}





