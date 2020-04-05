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

void dump_stats_to_file(char * fname, void *ref, uint32_t pushpull)
{
    FILE * f_ranks;
    FILE * f_floats;
    struct PageRankStats *ref_stats = (struct PageRankStats * )ref;
    uint32_t * ranks = ref_stats->realRanks;
    float * floats = ref_stats->pageRanks;

    char * ranks_fname = (char *) malloc((strlen(fname) + 40) * sizeof(char));
    char * floats_fname = (char *) malloc((strlen(fname) + 40) * sizeof(char));
    strcpy(ranks_fname, fname);
    strcpy(floats_fname, fname);
    switch (pushpull)
    {
    case 0: strcat(ranks_fname, "_float_ranks.out");
            strcat(floats_fname, "_float_floats.out");
        break;
    case 4: strcat(ranks_fname, "_quant32_ranks.out");
            strcat(floats_fname, "_quant32_floats.out");
        break;
    case 10: strcat(ranks_fname, "_quant16_ranks.out");
             strcat(floats_fname, "_quant16_floats.out");
        break;
    case 11: strcat(ranks_fname, "_quant8_ranks.out");
             strcat(floats_fname, "_quant8_floats.out");
        break;
    default:
	return;
        break;
    }

    f_ranks = fopen(ranks_fname, "w+");
    f_floats = fopen(floats_fname, "w+");
    
    for (uint32_t v = 0; v < ref_stats->num_vertices; v++)
    {
        fprintf(f_ranks, "%u\n", ranks[v]);
        fprintf(f_floats, "%.9g\n", floats[v]);
    }
    fclose(f_ranks);
    fclose(f_floats);
    free(floats_fname);
    free(ranks_fname);
}

uint32_t top_k_mismatches(void *cmp, void *ref, uint32_t k)
{
    uint32_t v;
    uint32_t mismatches = 0;
    struct PageRankStats *ref_stats = (struct PageRankStats * )ref;
    struct PageRankStats *cmp_stats = (struct PageRankStats * )cmp;

    uint32_t ref_size = ref_stats->num_vertices;
    uint32_t cmp_size = cmp_stats->num_vertices;

    if(cmp_size != ref_size)
        return 0;

    uint32_t *ref_final_ranks = (uint32_t *) my_malloc(ref_size * sizeof(uint32_t));
    uint32_t *cmp_final_ranks = (uint32_t *) my_malloc(cmp_size * sizeof(uint32_t));

    for(v = 0; v < ref_size; v++)
    {
        ref_final_ranks[v] = v;
        cmp_final_ranks[v] = v;
    }

    ref_final_ranks = radixSortEdgesByPageRank(ref_stats->pageRanks, ref_final_ranks, ref_size);
    cmp_final_ranks = radixSortEdgesByPageRank(cmp_stats->pageRanks, cmp_final_ranks, cmp_size);


    for (v = ref_size - 1; v > ref_size - k - 1; v--)
    {
        if (ref_final_ranks[v] != cmp_final_ranks[v])
            mismatches++;
    }

    free(ref_final_ranks);
    free(cmp_final_ranks);
    return mismatches;
}

//here the avg rank shift (total shift div by num of mismatches)
double top_k_avg_rank_shift(void *cmp, void *ref, uint32_t k)
{
    uint32_t v;
    uint32_t counter = 0;
    double shift = 0.0;
    struct PageRankStats *ref_stats = (struct PageRankStats * )ref;
    struct PageRankStats *cmp_stats = (struct PageRankStats * )cmp;
    uint32_t ref_size = ref_stats->num_vertices;
    uint32_t cmp_size = cmp_stats->num_vertices;

    uint32_t *ref_final_ranks = ref_stats->realRanks;
    uint32_t *cmp_final_ranks = cmp_stats->realRanks;

    //the array's index is the Vertix number, and the realRanks are the array contents
    uint32_t *cmp_final_ranks_inv = (uint32_t *) my_malloc(cmp_size * sizeof(uint32_t));

    for(v = 0; v < cmp_size; v++)
    {
        cmp_final_ranks_inv[cmp_final_ranks[v]] = v;
    }

    //Top k for loop
    for (v = ref_size - 1; v > ref_size - (k + 1); v--)
    {
        uint32_t temp_rank = cmp_final_ranks_inv[ref_final_ranks[v]];
        if (temp_rank != v)
        {
            shift += abs(temp_rank - v);
            counter++;
        }
    }
    free(cmp_final_ranks_inv);

    if(counter)
        return (double)shift / (double)counter;
    else
        return 0;
}

double get_avg_error_float(void *cmp, void *ref)
{
    double error = 0.0;
    double epsilon = 1e-8f;

    struct PageRankStats *ref_stats = (struct PageRankStats * )ref;
    struct PageRankStats *cmp_stats = (struct PageRankStats * )cmp;

    float *cmp_arr = cmp_stats->pageRanks;
    uint32_t cmp_size = cmp_stats->num_vertices;
    float *ref_arr = ref_stats->pageRanks;
    uint32_t ref_size = ref_stats->num_vertices;
    uint32_t i;

    if(cmp_size != ref_size)
        return 0;

    for( i = 0 ; i < cmp_size; i++ )
    {
        if (!equalFloat(ref_arr[i], cmp_arr[i], epsilon))
        {
            error += fabs(cmp_arr[i] - ref_arr[i]) / (double)ref_arr[i];
        }
    }
    return error / (double)ref_size;
}

double get_avg_distortion(void *cmp, void *ref)
{
    double dist = 0.0;
    struct PageRankStats *ref_stats = (struct PageRankStats * )ref;
    struct PageRankStats *cmp_stats = (struct PageRankStats * )cmp;

    float *cmp_arr = cmp_stats->pageRanks;
    uint32_t cmp_size = cmp_stats->num_vertices;
    float *ref_arr = ref_stats->pageRanks;
    uint32_t ref_size = ref_stats->num_vertices;

    if(cmp_size != ref_size)
        return 0;

    for(uint32_t i = 0 ; i < cmp_size; i++ )
    {
        dist += pow(fabs(cmp_arr[i] - ref_arr[i]), 2);
    }
    return dist / cmp_size;
}

void tester(void *cmp, void *ref, uint32_t k)
{
    uint32_t i;

    struct PageRankStats *ref_stats = (struct PageRankStats * )ref;
    struct PageRankStats *cmp_stats = (struct PageRankStats * )cmp;

    uint32_t cmp_size = cmp_stats->num_vertices;
    uint32_t ref_size = ref_stats->num_vertices;

    if(cmp_size != ref_size)
        return;

    uint32_t *ref_final_ranks = ref_stats->realRanks;
    uint32_t *cmp_final_ranks = cmp_stats->realRanks;

    uint32_t v;

    for (v = ref_size - 1; v > ref_size - (k+1); v--)
    {
        printf("Rank = %u, Vertix %u\n", v, ref_final_ranks[v], ref_stats->pageRanks[ref_final_ranks[v]]);
        printf("Quant Rank = %u, Quant Vertix %u\n\n", v, cmp_final_ranks[v], cmp_stats->pageRanks[cmp_final_ranks[v]]);
    }
    return;
}

int main (int argc, char **argv)
{

    char *benchmarks_dir = "../../01_GraphDatasets/";

    char *benchmarks[15] =
    {
        "amazon-2008",
        "arabic-2005",
        "cnr-2000",
        "dblp-2010",
        "enron",
        "eu-2005",
        "hollywood-2009",
        "in-2004",
        "indochina-2004",
        "it-2004",
        "ljournal-2008",
        "sk-2005",
        "uk-2002",
        "uk-2005",
        "webbase-2001"
    };

    char *extension = "/graph.wbin";

    struct Arguments arguments;
    arguments.wflag = 0;
    arguments.xflag = 0;
    arguments.sflag = 0;

    arguments.iterations = 200;
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
    printf("| %-40s | \n", "Quantization Avg Rank Shift Test");
    printf("*-----------------------------------------------------*\n");
    printf("| %-20s %-30u | \n", "Number of Threads :", numThreads);
    printf(" -----------------------------------------------------\n");

    void *ref_data;
    void *cmp_data;

    FILE *f_mismatch = fopen("quant_rank_mismatch.out", "w+");
    FILE *f_shift = fopen("quant_rank_shift.out", "w+");
    fclose(f_mismatch);
    fclose(f_shift);

    if (f_mismatch == NULL || f_shift == NULL)
        printf("Error opening the file");

    int k[6] = {30, 100, 300, 1000, 5000, 10000};
    int k_size = 6;

    for(uint32_t i = 0; i < 15; i++)
    {
        //1. Open the files
        f_mismatch = fopen("quant_rank_mismatch.out", "a+");
        f_shift = fopen("quant_rank_shift.out", "a+");

        arguments.fnameb = (char *) malloc((strlen(benchmarks_dir) + 40) * sizeof(char));
        strcpy(arguments.fnameb, benchmarks_dir);
        strcat(arguments.fnameb, benchmarks[i]);
        strcat(arguments.fnameb, extension);
        fprintf(f_mismatch, "%s\n", benchmarks[i]);
        fprintf(f_shift, "%s\n", benchmarks[i]);

        printf("Begin tests for %s\n", benchmarks[i]);

        graph = generateGraphDataStructure(&arguments);
        arguments.root = generateRandomRootGeneral(graph, &arguments); // random root each trial
        ref_data = runGraphAlgorithmsTest(graph, &arguments); // ref stats should mach oother algo
	
	dump_stats_to_file(benchmarks[i], ref_data,  arguments.pushpull);
        
	for(arguments.pushpull = 4; arguments.pushpull < 12; arguments.pushpull++)
        {
            if ((arguments.pushpull != 0) &&
                    (arguments.pushpull != 4) &&
                    (arguments.pushpull != 10) &&
                    (arguments.pushpull != 11))
            {
                continue;
            }

            cmp_data = runGraphAlgorithmsTest(graph, &arguments);
	    dump_stats_to_file(benchmarks[i], cmp_data, arguments.pushpull);
            if(ref_data != NULL && cmp_data != NULL)
            {
                for (int j = 0; j < k_size; j++)
                {
		    //tester(cmp_data, ref_data, k[j]);
                    //fprintf(f_mismatch, "%u\t", top_k_mismatches(cmp_data, ref_data, k[j]));
                    //fprintf(f_shift, "%lf\t", top_k_avg_rank_shift(cmp_data, ref_data, k[j]));
                }
                //fprintf(f_mismatch, "\n");
                //fprintf(f_shift, "\n");
            }
            freeGraphStatsGeneral(cmp_data, arguments.algorithm);
        }
        fclose(f_mismatch);
        fclose(f_shift);

        freeGraphStatsGeneral(ref_data, arguments.algorithm);
        freeGraphDataStructure(graph, arguments.datastructure);

        printf("Finished tests for %s\n", benchmarks[i]);
    }

    free(timer);
    printf("*-----------------------------------------------------*\n");
    printf("| %-50s | \n", "Test Done!");
    printf("*-----------------------------------------------------*\n");
    return 0;
}



