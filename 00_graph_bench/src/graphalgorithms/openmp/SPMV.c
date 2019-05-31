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

// ********************************************************************************************
// ***************                  GRID DataStructure                           **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphGrid(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphGrid *graph){

    struct SPMVStats *stats = NULL;

    switch (pushpull)
    {
    case 0: // push
        stats = SPMVPullRowGraphGrid(epsilon, iterations, graph);
        break;
    case 1: // pull
        stats = SPMVPushColumnGraphGrid(epsilon, iterations, graph);
        break;
    case 2: // pull
        stats = SPMVPullRowFixedPointGraphGrid(epsilon, iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushColumnFixedPointGraphGrid(epsilon, iterations, graph);
        break;
    default:// pull
        stats = SPMVPullRowGraphGrid(epsilon, iterations, graph);
        break;
    }

    return stats;

}
struct SPMVStats *SPMVPullRowGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph){

}
struct SPMVStats *SPMVPushColumnGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph){

}
struct SPMVStats *SPMVPullRowFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph){

}
struct SPMVStats *SPMVPushColumnFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph){

}

// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphCSR(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphCSR *graph){

    struct SPMVStats *stats = NULL;

    switch (pushpull)
    {

    case 0: // pull
        stats = SPMVPullGraphCSR(epsilon, iterations, graph);
        break;
    case 1: // push
        stats = SPMVPushGraphCSR(epsilon, iterations, graph);
        break;

    case 2: // pull
        stats = SPMVPullFixedPointGraphCSR(epsilon, iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushFixedPointGraphCSR(epsilon, iterations, graph);
        break;
    case 4: // pull
        stats = SPMVPullFixedPointGraphCSR(epsilon, iterations, graph);
        break;
    case 5: // push
        stats = SPMVPushFixedPointGraphCSR(epsilon, iterations, graph);
        break;
    case 6: // pull
        stats = SPMVDataDrivenPullGraphCSR(epsilon, iterations, graph);
        break;
    case 7: // push
        stats = SPMVDataDrivenPushGraphCSR(epsilon, iterations, graph);
        break;
    default:// pull
        stats = SPMVPullGraphCSR(epsilon, iterations, graph);
        break;
    }

    return stats;

}
struct SPMVStats *SPMVPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph){

}
struct SPMVStats *SPMVPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph){

}

struct SPMVStats *SPMVPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph){

}
struct SPMVStats *SPMVPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph){

}

struct SPMVStats *SPMVDataDrivenPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph){

}
struct SPMVStats *SPMVDataDrivenPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph){

}

// ********************************************************************************************
// ***************                  ArrayList DataStructure                      **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphAdjArrayList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList *graph){

    struct SPMVStats *stats = NULL;

    switch (pushpull)
    {

    case 0: // pull
        stats = SPMVPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 1: // push
        stats = SPMVPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 2: // pull
        stats = SPMVPullFixedPointGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushFixedPointGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 4: // pull
        stats = SPMVDataDrivenPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 5: // push
        stats = SPMVDataDrivenPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
    default:// push
        stats = SPMVPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
    }


    return stats;

}
struct SPMVStats *SPMVPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph){

}
struct SPMVStats *SPMVPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph){

}

struct SPMVStats *SPMVPullFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph){

}
struct SPMVStats *SPMVPushFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph){

}

struct SPMVStats *SPMVDataDrivenPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph){

}
struct SPMVStats *SPMVDataDrivenPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph){

}


// ********************************************************************************************
// ***************                  LinkedList DataStructure                     **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphAdjLinkedList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList *graph){

     struct SPMVStats *stats = NULL;

    switch (pushpull)
    {

    case 0: // pull
        stats = SPMVPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 1: // push
        stats = SPMVPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 2: // pull
        stats = SPMVPullFixedPointGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushFixedPointGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 4: // pull
        stats = SPMVDataDrivenPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 5: // push
        stats = SPMVDataDrivenPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    default:// push
        stats = SPMVPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    }


    return stats;

}
struct SPMVStats *SPMVPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph){

}
struct SPMVStats *SPMVPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph){

}

struct SPMVStats *SPMVPullFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph){

}
struct SPMVStats *SPMVPushFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph){

}

struct SPMVStats *SPMVDataDrivenPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph){

}
struct SPMVStats *SPMVDataDrivenPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph){

}
