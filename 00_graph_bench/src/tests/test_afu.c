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
// Revise : 2019-10-28 14:29:42
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
#include "capienv.h"

int numThreads;
mt19937state *mt19937var;


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
    printf("\n");
    for(i = 0; i < wed->num_edges ; i++)
    {
        printf("%u src:  %u dest %u\n", i, ((__u32 *)wed->inverse_edges_array_src)[i], ((__u32 *)wed->inverse_edges_array_dest)[i]);
    }

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
    // arguments.fnameb = "../03_test_graphs/v300_e2730/graph.wbin";
    arguments.fnameb = "../03_test_graphs/v51_e1021/graph.wbin";
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

    // ********************************************************************************************
    // ***************                  MAP CSR DataStructure                        **************
    // ********************************************************************************************

    wedGraphCSR = mapGraphCSRToWED((struct GraphCSR *)graph);

    wedGraphCSR->auxiliary1 = divclause;
    wedGraphCSR->auxiliary2 = prnext;
    wedGraphCSR->afu_config = 3; // config to use cache
    wedGraphCSR->afu_config = 0; // config to don't use cache


    // ********************************************************************************************
    // ***************                  CSR DataStructure                            **************
    // ********************************************************************************************

    printWEDGraphCSRVertex(wedGraphCSR);
    printWEDGraphCSRPointers(wedGraphCSR);

    // ********************************************************************************************
    // ***************                 Setup AFU                                     **************
    // ********************************************************************************************

    setupAFUGraphCSR(&afu, wedGraphCSR);

    struct AFUStatus afu_status;
    afu_status.algo_status = 0;
    afu_status.num_cu = 1; // non zero CU triggers the AFU to work
    afu_status.error = 0;


    // ********************************************************************************************
    // ***************                 START AFU                                     **************
    // ********************************************************************************************
    printf("Start AFU\n");
    startAFU(&afu, afu_status);
   
    
    // ********************************************************************************************
    // ***************                 WAIT AFU                                     **************
    // ********************************************************************************************
    printf("Waiting for completion by AFU\n");
    waitAFU(&afu, &afu_status);

    printMMIO_error(afu_status.error);

    printf("Vertices: %lu\n", (((afu_status.algo_status) << 32) >> 32));
    printf("Edges: %lu\n", ((afu_status.algo_status) >> 32));

     for (__u32 i = 0; i < ((struct GraphCSR *)graph)->num_vertices; ++i)
    {
        printf("prnext[%u] = %u \n", i,prnext[i]);
    }

    // ********************************************************************************************
    // ***************                 Releasing AFU                                     **************
    // ********************************************************************************************

    printf("Releasing AFU\n");
    releaseAFU(&afu);

    free(timer);
    exit (0);
}





