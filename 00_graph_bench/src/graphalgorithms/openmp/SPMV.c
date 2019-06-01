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
    stats->time_total = 0.0f;
    stats->vector_output = (float *) my_malloc(graph->num_vertices * sizeof(float));
    stats->vector_input = (float *) my_malloc(graph->num_vertices * sizeof(float));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector_output[v] =  0.0f;
        stats->vector_input[v] =  0.0f;
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
    stats->vector_output = (float *) my_malloc(graph->num_vertices * sizeof(float));
    stats->vector_input = (float *) my_malloc(graph->num_vertices * sizeof(float));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector_output[v] =  0.0f;
        stats->vector_input[v] =  0.0f;
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
    stats->vector_output = (float *) my_malloc(graph->num_vertices * sizeof(float));
    stats->vector_input = (float *) my_malloc(graph->num_vertices * sizeof(float));


    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector_output[v] =  0.0f;
        stats->vector_input[v] =  0.0f;
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
    stats->vector_output = (float *) my_malloc(graph->num_vertices * sizeof(float));
    stats->vector_input = (float *) my_malloc(graph->num_vertices * sizeof(float));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->vector_output[v] =  0.0f;
        stats->vector_input[v] =  0.0f;
    }

    return stats;

}

void freeSPMVStats(struct SPMVStats *stats)
{

    if(stats)
    {
        if(stats->vector_output)
            free(stats->vector_output);
        free(stats);
    }

}

// ********************************************************************************************
// ***************                  GRID DataStructure                           **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphGrid( __u32 iterations, __u32 pushpull, struct GraphGrid *graph)
{

    struct SPMVStats *stats = NULL;

    switch (pushpull)
    {
    case 0: // push
        stats = SPMVPullRowGraphGrid( iterations, graph);
        break;
    case 1: // pull
        stats = SPMVPushColumnGraphGrid( iterations, graph);
        break;
    case 2: // pull
        stats = SPMVPullRowFixedPointGraphGrid( iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushColumnFixedPointGraphGrid( iterations, graph);
        break;
    default:// pull
        stats = SPMVPullRowGraphGrid( iterations, graph);
        break;
    }

    return stats;

}
struct SPMVStats *SPMVPullRowGraphGrid( __u32 iterations, struct GraphGrid *graph)
{

    __u32 v;
    double sum = 0.0;

    __u32 totalPartitions  = graph->grid->num_partitions;

    struct SPMVStats *stats = newSPMVStatsGraphGrid(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting SPMV-Row");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Iteration", "Time (S)");
    printf(" -----------------------------------------------------\n");

    //assume any vector input for benchamrking purpose.
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        if(graph->grid->out_degree[v])
            stats->vector_input[v] =  (1.0f / graph->grid->out_degree[v]);
        else
            stats->vector_input[v] = 0.001f;
    }

    Start(timer);
    for(stats->iterations = 0; stats->iterations < iterations; stats->iterations++)
    {
        Start(timer_inner);

        __u32 i;
        #pragma omp parallel for private(i) schedule (dynamic,numThreads)
        for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
        {
            __u32 j;
            // #pragma omp parallel for private(j)
            for (j = 0; j < totalPartitions; ++j)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                float weight = 0.0001f;
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

#if WEIGHTED
                    weight = partition->edgeList->edges_array_weight[k];
#endif

                    // #pragma omp atomic update
                    // __sync_fetch_and_add(&stats->vector_output[dest],(weight * stats->vector_input[src]));
                    // addAtomicFloat(&stats->vector_output[dest], (weight * stats->vector_input[src])

                    // #pragma omp atomic update
                    stats->vector_output[src] +=  (weight * stats->vector_input[dest]);
                }
            }
        }

        Stop(timer_inner);
        printf("| %-21u | %-27f | \n", stats->iterations, Seconds(timer_inner));

    }// end iteration loop

    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {

        sum += ((int)(stats->vector_output[v] * 10 + .5) / 10.0);
    }

    Stop(timer);
    stats->time_total = Seconds(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iterations", "Sum", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-15u | %-15lf | %-15f | \n", stats->iterations, sum, stats->time_total);
    printf(" -----------------------------------------------------\n");


    free(timer);
    free(timer_inner);
    return stats;


}
struct SPMVStats *SPMVPushColumnGraphGrid( __u32 iterations, struct GraphGrid *graph)
{
    __u32 v;
    double sum = 0.0;

    __u32 totalPartitions  = graph->grid->num_partitions;

    struct SPMVStats *stats = newSPMVStatsGraphGrid(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting SPMV-Column");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Iteration", "Time (S)");
    printf(" -----------------------------------------------------\n");

    //assume any vector input for benchamrking purpose.
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        if(graph->grid->out_degree[v])
            stats->vector_input[v] =  (1.0f / graph->grid->out_degree[v]);
        else
            stats->vector_input[v] = 0.001f;
    }

    Start(timer);
    for(stats->iterations = 0; stats->iterations < iterations; stats->iterations++)
    {
        Start(timer_inner);

        __u32 j;
        // #pragma omp parallel for private(j)
        for (j = 0; j < totalPartitions; ++j)  // iterate over partitions colwise
        {
            __u32 i;
            #pragma omp parallel for private(i) schedule (dynamic,numThreads)
            for (i = 0; i < totalPartitions; ++i)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                float weight = 0.0001f;
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

#if WEIGHTED
                    weight = partition->edgeList->edges_array_weight[k];
#endif

                    // #pragma omp atomic update
                    // __sync_fetch_and_add(&stats->vector_output[dest],(weight * stats->vector_input[src]));
                    // addAtomicFloat(&stats->vector_output[dest], (weight * stats->vector_input[src])

                    // #pragma omp atomic update
                    stats->vector_output[src] +=  (weight * stats->vector_input[dest]);
                }
            }
        }

        Stop(timer_inner);
        printf("| %-21u | %-27f | \n", stats->iterations, Seconds(timer_inner));

    }// end iteration loop

    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {

        sum += ((int)(stats->vector_output[v] * 10 + .5) / 10.0);
    }

    Stop(timer);
    stats->time_total = Seconds(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iterations", "Sum", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-15u | %-15lf | %-15f | \n", stats->iterations, sum, stats->time_total);
    printf(" -----------------------------------------------------\n");


    free(timer);
    free(timer_inner);
    return stats;

}
struct SPMVStats *SPMVPullRowFixedPointGraphGrid( __u32 iterations, struct GraphGrid *graph)
{

    __u32 v;
    double sum = 0.0;

    __u32 totalPartitions  = graph->grid->num_partitions;

    struct SPMVStats *stats = newSPMVStatsGraphGrid(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

    __u64 *vector_input = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *vector_output = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting SPMV-Row Fixed-Point");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Iteration", "Time (S)");
    printf(" -----------------------------------------------------\n");

    //assume any vector input for benchamrking purpose.
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        if(graph->grid->out_degree[v])
            stats->vector_input[v] =  (1.0f / graph->grid->out_degree[v]);
        else
            stats->vector_input[v] = 0.001f;
    }

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        vector_input[v] = DoubleToFixed64(stats->vector_input[v]);
    }


    Start(timer);
    for(stats->iterations = 0; stats->iterations < iterations; stats->iterations++)
    {
        Start(timer_inner);

        __u32 i;
        #pragma omp parallel for private(i) schedule (dynamic,numThreads)
        for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
        {
            __u32 j;
            // #pragma omp parallel for private(j)
            for (j = 0; j < totalPartitions; ++j)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                __u64 weight = DoubleToFixed64(0.0001);
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

#if WEIGHTED
                    weight = DoubleToFixed64(partition->edgeList->edges_array_weight[k]);
#endif

                    // #pragma omp atomic update
                    // __sync_fetch_and_add(&stats->vector_output[dest],(weight * stats->vector_input[src]));
                    // addAtomicFloat(&stats->vector_output[dest], (weight * stats->vector_input[src])

                    // #pragma omp atomic update
                    vector_output[src] += MULFixed64V1(weight, vector_input[dest]);
                }
            }
        }

        Stop(timer_inner);
        printf("| %-21u | %-27f | \n", stats->iterations, Seconds(timer_inner));

    }// end iteration loop

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        stats->vector_output[v] = Fixed64ToDouble(vector_output[v]);
    }


    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {

        sum += ((int)(stats->vector_output[v] * 10 + .5) / 10.0);
    }

    Stop(timer);
    stats->time_total = Seconds(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iterations", "Sum", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-15u | %-15lf | %-15f | \n", stats->iterations, sum, stats->time_total);
    printf(" -----------------------------------------------------\n");


    free(timer);
    free(timer_inner);
    free(vector_output);
    free(vector_input);

    return stats;


}
struct SPMVStats *SPMVPushColumnFixedPointGraphGrid( __u32 iterations, struct GraphGrid *graph)
{

     __u32 v;
    double sum = 0.0;

    __u32 totalPartitions  = graph->grid->num_partitions;

    struct SPMVStats *stats = newSPMVStatsGraphGrid(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

    __u64 *vector_input = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *vector_output = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting SPMV-Column Fixed-Point");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Iteration", "Time (S)");
    printf(" -----------------------------------------------------\n");

    //assume any vector input for benchamrking purpose.
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        if(graph->grid->out_degree[v])
            stats->vector_input[v] =  (1.0f / graph->grid->out_degree[v]);
        else
            stats->vector_input[v] = 0.001f;
    }

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        vector_input[v] = DoubleToFixed64(stats->vector_input[v]);
    }


    Start(timer);
    for(stats->iterations = 0; stats->iterations < iterations; stats->iterations++)
    {
        Start(timer_inner);

         __u32 j;
        // #pragma omp parallel for private(j)
        for (j = 0; j < totalPartitions; ++j)  // iterate over partitions colwise
        {
            __u32 i;
            #pragma omp parallel for private(i) schedule (dynamic,numThreads)
            for (i = 0; i < totalPartitions; ++i)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                __u64 weight = DoubleToFixed64(0.0001);
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

#if WEIGHTED
                    weight = DoubleToFixed64(partition->edgeList->edges_array_weight[k]);
#endif

                    // #pragma omp atomic update
                    // __sync_fetch_and_add(&stats->vector_output[dest],(weight * stats->vector_input[src]));
                    // addAtomicFloat(&stats->vector_output[dest], (weight * stats->vector_input[src])

                    // #pragma omp atomic update
                    vector_output[src] += MULFixed64V1(weight, vector_input[dest]);
                }
            }
        }

        Stop(timer_inner);
        printf("| %-21u | %-27f | \n", stats->iterations, Seconds(timer_inner));

    }// end iteration loop

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        stats->vector_output[v] = Fixed64ToDouble(vector_output[v]);
    }


    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {

        sum += ((int)(stats->vector_output[v] * 10 + .5) / 10.0);
    }

    Stop(timer);
    stats->time_total = Seconds(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iterations", "Sum", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-15u | %-15lf | %-15f | \n", stats->iterations, sum, stats->time_total);
    printf(" -----------------------------------------------------\n");


    free(timer);
    free(timer_inner);
    free(vector_output);
    free(vector_input);
    
    return stats;

}

// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphCSR( __u32 iterations, __u32 pushpull, struct GraphCSR *graph)
{

    struct SPMVStats *stats = NULL;

    switch (pushpull)
    {

    case 0: // pull
        stats = SPMVPullGraphCSR( iterations, graph);
        break;
    case 1: // push
        stats = SPMVPushGraphCSR( iterations, graph);
        break;

    case 2: // pull
        stats = SPMVPullFixedPointGraphCSR( iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushFixedPointGraphCSR( iterations, graph);
        break;
    case 4: // pull
        stats = SPMVPullFixedPointGraphCSR( iterations, graph);
        break;
    case 5: // push
        stats = SPMVPushFixedPointGraphCSR( iterations, graph);
        break;
    case 6: // pull
        stats = SPMVDataDrivenPullGraphCSR( iterations, graph);
        break;
    case 7: // push
        stats = SPMVDataDrivenPushGraphCSR( iterations, graph);
        break;
    default:// pull
        stats = SPMVPullGraphCSR( iterations, graph);
        break;
    }

    return stats;

}
struct SPMVStats *SPMVPullGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

}
struct SPMVStats *SPMVPushGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

}

struct SPMVStats *SPMVPullFixedPointGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

}
struct SPMVStats *SPMVPushFixedPointGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

}

struct SPMVStats *SPMVDataDrivenPullGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

}
struct SPMVStats *SPMVDataDrivenPushGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

}

// ********************************************************************************************
// ***************                  ArrayList DataStructure                      **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphAdjArrayList( __u32 iterations, __u32 pushpull, struct GraphAdjArrayList *graph)
{

    struct SPMVStats *stats = NULL;

    switch (pushpull)
    {

    case 0: // pull
        stats = SPMVPullGraphAdjArrayList( iterations, graph);
        break;
    case 1: // push
        stats = SPMVPushGraphAdjArrayList( iterations, graph);
        break;
    case 2: // pull
        stats = SPMVPullFixedPointGraphAdjArrayList( iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushFixedPointGraphAdjArrayList( iterations, graph);
        break;
    case 4: // pull
        stats = SPMVDataDrivenPullGraphAdjArrayList( iterations, graph);
        break;
    case 5: // push
        stats = SPMVDataDrivenPushGraphAdjArrayList( iterations, graph);
        break;
    default:// push
        stats = SPMVPullGraphAdjArrayList( iterations, graph);
        break;
    }


    return stats;

}
struct SPMVStats *SPMVPullGraphAdjArrayList( __u32 iterations, struct GraphAdjArrayList *graph)
{

}
struct SPMVStats *SPMVPushGraphAdjArrayList( __u32 iterations, struct GraphAdjArrayList *graph)
{

}

struct SPMVStats *SPMVPullFixedPointGraphAdjArrayList( __u32 iterations, struct GraphAdjArrayList *graph)
{

}
struct SPMVStats *SPMVPushFixedPointGraphAdjArrayList( __u32 iterations, struct GraphAdjArrayList *graph)
{

}
struct SPMVStats *SPMVDataDrivenPullGraphAdjArrayList( __u32 iterations, struct GraphAdjArrayList *graph)
{

}
struct SPMVStats *SPMVDataDrivenPushGraphAdjArrayList( __u32 iterations, struct GraphAdjArrayList *graph)
{

}


// ********************************************************************************************
// ***************                  LinkedList DataStructure                     **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphAdjLinkedList( __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList *graph)
{

    struct SPMVStats *stats = NULL;

    switch (pushpull)
    {

    case 0: // pull
        stats = SPMVPullGraphAdjLinkedList( iterations, graph);
        break;
    case 1: // push
        stats = SPMVPushGraphAdjLinkedList( iterations, graph);
        break;
    case 2: // pull
        stats = SPMVPullFixedPointGraphAdjLinkedList( iterations, graph);
        break;
    case 3: // push
        stats = SPMVPushFixedPointGraphAdjLinkedList( iterations, graph);
        break;
    case 4: // pull
        stats = SPMVDataDrivenPullGraphAdjLinkedList( iterations, graph);
        break;
    case 5: // push
        stats = SPMVDataDrivenPushGraphAdjLinkedList( iterations, graph);
        break;
    default:// push
        stats = SPMVPullGraphAdjLinkedList( iterations, graph);
        break;
    }


    return stats;

}
struct SPMVStats *SPMVPullGraphAdjLinkedList( __u32 iterations, struct GraphAdjLinkedList *graph)
{

}
struct SPMVStats *SPMVPushGraphAdjLinkedList( __u32 iterations, struct GraphAdjLinkedList *graph)
{

}

struct SPMVStats *SPMVPullFixedPointGraphAdjLinkedList( __u32 iterations, struct GraphAdjLinkedList *graph)
{

}
struct SPMVStats *SPMVPushFixedPointGraphAdjLinkedList( __u32 iterations, struct GraphAdjLinkedList *graph)
{

}

struct SPMVStats *SPMVDataDrivenPullGraphAdjLinkedList( __u32 iterations, struct GraphAdjLinkedList *graph)
{

}
struct SPMVStats *SPMVDataDrivenPushGraphAdjLinkedList( __u32 iterations, struct GraphAdjLinkedList *graph)
{

}
