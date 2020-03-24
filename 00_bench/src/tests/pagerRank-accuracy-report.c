// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Mohannad Ibrahim
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : test_accel-graph.c
// Create : 2019-07-29 16:52:00
// Revise : 2019-09-28 15:36:29
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <argp.h>
#include <stdbool.h>
#include <omp.h>
#include <string.h>
#include <math.h>
#include <stdint.h>


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

double get_avg_error(void *cmp, void *ref)
{
    double error = 0;
    uint32_t counter = 0;
    struct PageRankStats *ref_stats = (struct PageRankStats * )ref;
    struct PageRankStats *cmp_stats = (struct PageRankStats * )cmp;

    float *cmp_arr = cmp_stats->pageRanks;
    uint32_t cmp_size = cmp_stats->num_vertices;
    float *ref_arr = ref_stats->pageRanks;
    uint32_t ref_size = cmp_stats->num_vertices;

    if(cmp_size != ref_size)
        return 0;

    for(uint32_t i = 0 ; i < cmp_size; i++)
    {
        if (ref_arr[i] != 0)
        {
            error += fabs(cmp_arr[i] - ref_arr[i]) / ref_arr[i];
            counter++;
        }
    }
    return error / (double)counter;
}

int main (int argc, char **argv)
{

    char *benchmarks_dir = "../../01_GraphDatasets/";
   
    char *benchmarks_law[15] =
    {
        "amazon-2008/",
        "arabic-2005/",
        "cnr-2000/",
        "dblp-2010/",
        "enron/",
        "eu-2005/",
        "hollywood-2009/",
        "in-2004/",
        "indochina-2004/",
        "it-2004/",
        "ljournal-2008/",
        "sk-2005/",
        "uk-2002/",
        "uk-2005/",
        "webbase-2001/"
    };

    char *extension = "graph.wbin";

    struct Arguments arguments;
    arguments.wflag = 0;
    arguments.xflag = 0;
    arguments.sflag = 0;

    arguments.iterations = 100;
    arguments.trials = 1;
    arguments.epsilon = 1e-8;
    arguments.root = 5319;
    arguments.algorithm = 1;
    arguments.datastructure = 0;
    arguments.pushpull = 0;
    arguments.sort = 0;
    arguments.lmode = 0;
    arguments.symmetric = 0;
    arguments.weighted = 0;
    arguments.delta = 1;
    arguments.numThreads = omp_get_max_threads();
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

    void *ref_data;
    void *cmp_data;
    FILE *fp = fopen("pr_error.report", "w+");

    if (fp == NULL)
        printf("Error opening the file");

    //for every benchmark
    uint32_t i;
    for(i = 0; i < 15; i++)
    {
        arguments.fnameb = (char *) malloc((strlen(benchmarks_dir) + 40) * sizeof(char));
        strcpy(arguments.fnameb, benchmarks_dir);
        strcat(arguments.fnameb, benchmarks_law[i]);
        strcat(arguments.fnameb, extension);
        fprintf(fp, "%s\n", benchmarks_law[i]);
        //appropriate filename
        printf("Begin tests for %s\n", benchmarks_law[i]);

        graph = generateGraphDataStructure(&arguments);
        arguments.root = generateRandomRootGeneral(graph, &arguments); // random root each trial
        ref_data = runGraphAlgorithmsTest(graph, &arguments); // ref stats should mach oother algo

        for(arguments.pushpull = 0 ; arguments.pushpull < 10; arguments.pushpull++)
        {

            if ((arguments.pushpull != 0) &&
                    (arguments.pushpull != 2) &&
                    (arguments.pushpull != 4) &&
                    (arguments.pushpull != 9))
            {
                continue;
            }

            cmp_data = runGraphAlgorithmsTest(graph, &arguments);

            if(ref_data != NULL && cmp_data != NULL)
            {
                struct PageRankStats *temp = (struct PageRankStats * )cmp_data;
                double avg_error = get_avg_error(cmp_data, ref_data);
                uint32_t error_count = cmpGraphAlgorithmsTestStats(ref_data, cmp_data, arguments.algorithm);
                fprintf(fp, "Avg Error Val: %f,\t", avg_error);
                printf("Avg Error Val: %lf,\t", avg_error);
                fprintf(fp, "Error(%%): %lf,\t", (double)error_count * (double)100 / (double)temp->num_vertices);
                fprintf(fp, "Mismatches: %d\n", error_count);
                printf("Error(%%): %lf,\t", (double)error_count * (double)100 / (double)temp->num_vertices);
                printf("Mismatches: %d\n", error_count);
            }

            freeGraphStatsGeneral(cmp_data, arguments.algorithm);
        }

        freeGraphStatsGeneral(ref_data, arguments.algorithm);

        freeGraphDataStructure(graph, arguments.datastructure);

        printf("Finished tests for %s\n", benchmarks_law[i]);
    }

    fclose(fp);
    free(timer);
    printf("Page Rank Error Test Done .......");
    return 0;
}





