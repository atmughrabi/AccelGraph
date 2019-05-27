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

int numThreads;
mt19937state *mt19937var;

// "   mm                        ""#             mmm                       #     \n"
// "   ##    mmm    mmm    mmm     #           m"   "  m mm   mmm   mmmm   # mm  \n"
// "  #  #  #"  "  #"  "  #"  #    #           #   mm  #"  " "   #  #" "#  #"  # \n"
// "  #mm#  #      #      #""""    #     """   #    #  #     m"""#  #   #  #   # \n"
// " #    # "#mm"  "#mm"  "#mm"    "mm          "mmm"  #     "mm"#  ##m#"  #   # \n"
// "                                                                #            \n"

__u32 cmpGraphAlgorithmsTestStats(void *ref_stats, void *cmp_stats, __u32 algorithm);
__u32 compareDistanceArrays(__u32 *arr1, __u32 *arr2, __u32 arr1_size, __u32 arr2_size);
void *runGraphAlgorithmsTest(void *graph, struct Arguments *arguments);

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

__u32 cmpGraphAlgorithmsTestStats(void *ref_stats, void *cmp_stats, __u32 algorithm)
{

    __u32 missmatch = 0;

    switch (algorithm)
    {
    case 0:  // bfs filename root
    {
        struct BFSStats *ref_stats_tmp = (struct BFSStats * )ref_stats;
        struct BFSStats *cmp_stats_tmp = (struct BFSStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 1: // pagerank filename
    {
        struct PageRankStats *ref_stats_tmp = (struct PageRankStats * )ref_stats;
        struct PageRankStats *cmp_stats_tmp = (struct PageRankStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->realRanks, cmp_stats_tmp->realRanks, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);

    }
    break;
    case 2: // SSSP-Dijkstra file name root
    {
        struct SSSPStats *ref_stats_tmp = (struct SSSPStats * )ref_stats;
        struct SSSPStats *cmp_stats_tmp = (struct SSSPStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 3: // SSSP-Bellmanford file name root
    {
        struct BellmanFordStats *ref_stats_tmp = (struct BellmanFordStats * )ref_stats;
        struct BellmanFordStats *cmp_stats_tmp = (struct BellmanFordStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 4: // DFS file name root
    {
        struct DFSStats *ref_stats_tmp = (struct DFSStats * )ref_stats;
        struct DFSStats *cmp_stats_tmp = (struct DFSStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    case 5: // incremental Aggregation file name root
    {
        struct IncrementalAggregationStats *ref_stats_tmp = (struct IncrementalAggregationStats * )ref_stats;
        struct IncrementalAggregationStats *cmp_stats_tmp = (struct IncrementalAggregationStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->labels, cmp_stats_tmp->labels, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    default:// bfs file name root
    {
        struct BFSStats *ref_stats_tmp = (struct BFSStats * )ref_stats;
        struct BFSStats *cmp_stats_tmp = (struct BFSStats * )cmp_stats;
        missmatch += compareDistanceArrays(ref_stats_tmp->distances, cmp_stats_tmp->distances, ref_stats_tmp->num_vertices, cmp_stats_tmp->num_vertices);
    }
    break;
    }

    return missmatch;
}

void *runGraphAlgorithmsTest(void *graph, struct Arguments *arguments)
{

    void *ref_stats = NULL;

    switch (arguments->algorithm)
    {
    case 0:  // bfs filename root
    {
        ref_stats = runBreadthFirstSearchAlgorithm( graph,  arguments->datastructure,  arguments->root,  arguments->pushpull);
    }
    break;
    case 1: // pagerank filename
    {
        ref_stats = runPageRankAlgorithm(graph,  arguments->datastructure,  arguments->epsilon,  arguments->iterations,  arguments->pushpull);
    }
    break;
    case 2: // SSSP-Dijkstra file name root
    {
        ref_stats = runSSSPAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->iterations, arguments->pushpull,  arguments->delta);
    }
    break;
    case 3: // SSSP-Bellmanford file name root
    {
        ref_stats = runBellmanFordAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->iterations, arguments->pushpull);
    }
    break;
    case 4: // DFS file name root
    {
        ref_stats = runDepthFirstSearchAlgorithm(graph,  arguments->datastructure,  arguments->root);
    }
    break;
    case 5: // incremental Aggregation file name root
    {
        ref_stats = runIncrementalAggregationAlgorithm(graph,  arguments->datastructure);
    }
    break;
    default:// bfs file name root
    {
        ref_stats = runBreadthFirstSearchAlgorithm(graph,  arguments->datastructure,  arguments->root, arguments->pushpull);
    }
    break;
    }

    return ref_stats;
}



int
main (int argc, char **argv)
{

    struct Arguments arguments;
    /* Default values. */

    arguments.wflag = 0;
    arguments.xflag = 0;
    arguments.sflag = 0;

    arguments.iterations = 20;
    arguments.trials = 100;
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

    __u32 missmatch = 0;
    __u32 total_missmatch = 0;
    void *ref_data;
    void *cmp_data;

    // ********************************************************************************************
    // ***************                  CSR DataStructure                            **************
    // ********************************************************************************************

    for(arguments.datastructure = 0 ; arguments.datastructure < 4; arguments.datastructure++)
    {
        graph = generateGraphDataStructure(&arguments);
        arguments.trials = 20;

        while(arguments.trials)
        {
            arguments.root = generateRandomRootGeneral(graph, &arguments);

            for(arguments.algorithm = 0 ; arguments.algorithm < 6; arguments.algorithm++)
            {
                arguments.pushpull = 0;
                ref_data = runGraphAlgorithmsTest(graph, &arguments);
                for(arguments.pushpull = 0 ; arguments.pushpull < 10; arguments.pushpull++)
                {

                    cmp_data = runGraphAlgorithmsTest(graph, &arguments);

                    if(ref_data != NULL && cmp_data != NULL)
                        missmatch = cmpGraphAlgorithmsTestStats(ref_data, cmp_data, arguments.algorithm);
                    total_missmatch += missmatch;
                    if(missmatch != 0)
                        printf("FAIL : Trial [%u] Graph [%s] Missmatches [%u] \nFAIL : DataStructure [%u] Algorithm [%u] Direction [%u]\n\n", arguments.trials, arguments.fnameb, missmatch, arguments.datastructure, arguments.algorithm, arguments.pushpull);
                    else
                        printf("PASS : Trial [%u] Graph [%s] Missmatches [%u] \nPASS : DataStructure [%u] Algorithm [%u] Direction [%u]\n\n", arguments.trials, arguments.fnameb, missmatch, arguments.datastructure, arguments.algorithm, arguments.pushpull);

                    freeGraphStatsGeneral(cmp_data, arguments.algorithm);
                }

                freeGraphStatsGeneral(ref_data, arguments.algorithm);

            }

            arguments.trials--;
        }
        freeGraphDataStructure(graph, arguments.datastructure);
    }

    if(total_missmatch != 0)
        printf("FAIL : Trial [%u] Graph [%s] Missmatches [%u]", arguments.trials, arguments.fnameb, missmatch);
    else
        printf("PASS : Trial [%u] Graph [%s] Missmatches [%u]", arguments.trials, arguments.fnameb, missmatch);


    free(timer);
    exit (0);
}





