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

#include <assert.h>


// "   mm                        ""#             mmm                       #     \n"
// "   ##    mmm    mmm    mmm     #           m"   "  m mm   mmm   mmmm   # mm  \n"
// "  #  #  #"  "  #"  "  #"  #    #           #   mm  #"  " "   #  #" "#  #"  # \n"
// "  #mm#  #      #      #""""    #     """   #    #  #     m"""#  #   #  #   # \n"
// " #    # "#mm"  "#mm"  "#mm"    "mm          "mmm"  #     "mm"#  ##m#"  #   # \n"
// "                                                                #            \n"

__u32 compareDistanceArrays(__u32 *arr1, __u32 *arr2, __u32 arr1_size, __u32 arr2_size)
{
    __u32 i = 0;
    __u32 missmatch = 0;

    if(arr1_size != arr2_size)
        return 1;

    for(i = 0 ; i < arr1_size; i++)
    {
        if(arr1[i] != arr2[i])
        {
            missmatch++;
        }
    }
    return missmatch;
}

int numThreads;
mt19937state *mt19937var;

int
main (int argc, char **argv)
{

    struct Arguments arguments;
    /* Default values. */

    arguments.wflag = 0;
    arguments.xflag = 0;
    arguments.sflag = 0;

    arguments.iterations = 20;
    arguments.trials = 1;
    arguments.epsilon = 0.0001;
    arguments.root = 5319;
    arguments.algorithm = 0;
    arguments.datastructure = 0;
    arguments.pushpull = 0;
    arguments.sort = 0;
    arguments.lmode = 0;
    arguments.symmetric = 0;
    arguments.weighted = 0;
    arguments.delta = 1;
    arguments.numThreads = 4;
    arguments.fnameb = "../03_test_graphs/p2p-Gnutella31/graph.wbin";
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

    __u32 missmatch = 0;
    arguments.algorithm = 0;

    struct BFSStats *ref_stats = runBreadthFirstSearchAlgorithm( graph,  arguments.datastructure,  arguments.root,  arguments.pushpull);
    struct BFSStats *dbg_stats;
    __u32 i;
    for(i = 0 ; i < 10; i++)
    {
        arguments.pushpull = i;
        dbg_stats = runBreadthFirstSearchAlgorithm( graph,  arguments.datastructure,  arguments.root,  arguments.pushpull);
        missmatch += compareDistanceArrays(ref_stats->distances, dbg_stats->distances, ref_stats->num_vertices, dbg_stats->num_vertices);
        printf("%u \n", missmatch);
    }

    freeBFSStats(ref_stats);

    arguments.algorithm = 3;
    arguments.pushpull = 0;
    struct BellmanFordStats *ref_stats2 = runBellmanFordAlgorithm( graph,  arguments.datastructure,  arguments.root, arguments.iterations, arguments.pushpull);
    struct BellmanFordStats *dbg_stats2;

    for(i = 0 ; i < 10; i++)
    {
        arguments.pushpull = i;
        dbg_stats2 = runBellmanFordAlgorithm( graph,  arguments.datastructure,  arguments.root, arguments.iterations, arguments.pushpull);
        missmatch += compareDistanceArrays(ref_stats2->distances, dbg_stats2->distances, ref_stats2->num_vertices, dbg_stats2->num_vertices);
        printf("%u \n", missmatch);
    }

    freeBellmanFordStats(ref_stats2);


    free(timer);
    exit (0);
}





