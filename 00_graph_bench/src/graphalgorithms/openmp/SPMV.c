#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "bitmap.h"
#include "SPMV.h"

#include "fixedPoint.h"
#include "quantization.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"



// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************


struct SPMVStats *newSPMVStatsGraphCSR(struct GraphCSR *graph)
{

    __u32 v;

    struct SPMVStats *stats = (struct SPMVStats *) my_malloc(sizeof(struct SPMVStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0;
    stats->error_total = 0.0;
    stats->vector = (float *) my_malloc(graph->num_vertices * sizeof(float));;


    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector[v] =  0.0f;
    }

    return stats;

}
struct SPMVStats *newSPMVStatsGraphGrid(struct GraphGrid *graph)
{

    __u32 v;

    struct SPMVStats *stats = (struct SPMVStats *) my_malloc(sizeof(struct SPMVStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->error_total = 0.0f;
    stats->vector = (float *) my_malloc(graph->num_vertices * sizeof(float));;


    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector[v] =  0.0f;
    }

    return stats;

}
struct SPMVStats *newSPMVStatsGraphAdjArrayList(struct GraphAdjArrayList *graph)
{

    __u32 v;

    struct SPMVStats *stats = (struct SPMVStats *) my_malloc(sizeof(struct SPMVStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->error_total = 0.0f;
    stats->vector = (float *) my_malloc(graph->num_vertices * sizeof(float));;


    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector[v] =  0.0f;
    }

    return stats;

}
struct SPMVStats *newSPMVStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

    __u32 v;

    struct SPMVStats *stats = (struct SPMVStats *) my_malloc(sizeof(struct SPMVStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->error_total = 0.0f;
    stats->vector = (float *) my_malloc(graph->num_vertices * sizeof(float));;


    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector[v] =  0.0f;
    }

    return stats;

}

void freeSPMVStats(struct SPMVStats *stats)
{

    if(stats)
    {
        if(stats->vector)
            free(stats->vector);
        free(stats);
    }

}
