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

#include <assert.h>
#include "graphTest.h"

int numThreads;
mt19937state *mt19937var;

// "   mm                        ""#             mmm                       #     \n"
// "   ##    mmm    mmm    mmm     #           m"   "  m mm   mmm   mmmm   # mm  \n"
// "  #  #  #"  "  #"  "  #"  #    #           #   mm  #"  " "   #  #" "#  #"  # \n"
// "  #mm#  #      #      #""""    #     """   #    #  #     m"""#  #   #  #   # \n"
// " #    # "#mm"  "#mm"  "#mm"    "mm          "mmm"  #     "mm"#  ##m#"  #   # \n"
// "                                                                #            \n"


int
main (int argc, char **argv)
{

    struct Arguments arguments;
    /* Default values. */

    arguments.wflag = 0;
    arguments.xflag = 0;
    arguments.sflag = 0;

    arguments.iterations = 200;
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
        arguments.trials = (generateRandInt(mt19937var) % 50) + 1; // random number of trials
        arguments.iterations = 100;

        while(arguments.trials)
        {
            arguments.root = generateRandomRootGeneral(graph, &arguments); // random root each trial

            for(arguments.algorithm = 0 ; arguments.algorithm < 8; arguments.algorithm++)
            {
                arguments.pushpull = 0;
                ref_data = runGraphAlgorithmsTest(graph, &arguments); // ref stats should mach oother algo
                for(arguments.pushpull = 0 ; arguments.pushpull < 10; arguments.pushpull++)
                {

                    cmp_data = runGraphAlgorithmsTest(graph, &arguments);

                    if(ref_data != NULL && cmp_data != NULL)
                    {
                        missmatch = cmpGraphAlgorithmsTestStats(ref_data, cmp_data, arguments.algorithm);
                    }


                    total_missmatch += missmatch;
                    if(missmatch != 0)
                    {
                        printf("FAIL : Trial [%u] Graph [%s] Missmatches [%u] \nFAIL : DataStructure [%u] Algorithm [%u] Direction [%u]\n\n", arguments.trials, arguments.fnameb, missmatch, arguments.datastructure, arguments.algorithm, arguments.pushpull);
                        exit (1);
                    }
                    else
                    {
                        printf("PASS : Trial [%u] Graph [%s] Missmatches [%u] \nPASS : DataStructure [%u] Algorithm [%u] Direction [%u]\n\n", arguments.trials, arguments.fnameb, missmatch, arguments.datastructure, arguments.algorithm, arguments.pushpull);
                    }

                    freeGraphStatsGeneral(cmp_data, arguments.algorithm);
                }

                freeGraphStatsGeneral(ref_data, arguments.algorithm);

            }

            arguments.trials--;
        }
        freeGraphDataStructure(graph, arguments.datastructure);
    }

    if(total_missmatch != 0)
    {
        printf("FAIL : Trial [%u] Graph [%s] Missmatches [%u]\n", arguments.trials, arguments.fnameb, total_missmatch);
    }
    else
    {
        printf("PASS : Trial [%u] Graph [%s] Missmatches [%u]\n", arguments.trials, arguments.fnameb, total_missmatch);
    }


    free(timer);
    exit (0);
}





