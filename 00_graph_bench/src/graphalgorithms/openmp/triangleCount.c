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

#include "graphConfig.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

#include "triangleCount.h"




struct TCStats *newTCStatsGraphCSR(struct GraphCSR *graph)
{
    __u32 v;
    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->total_counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->counts = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->counts[v] =  0;
    }

    return stats;

}
struct TCStats *newTCStatsGraphGrid(struct GraphGrid *graph)
{
    __u32 v;
    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->total_counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->counts = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->counts[v] =  0;
    }
    return stats;
}
struct TCStats *newTCStatsGraphAdjArrayList(struct GraphAdjArrayList *graph)
{
    __u32 v;
    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->total_counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->counts = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->counts[v] =  0;
    }
    return stats;

}
struct TCStats *newTCStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{
    __u32 v;
    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->total_counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->counts = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->counts[v] =  0;
    }
    return stats;

}
void freeTCStats(struct TCStats *stats)
{

    if(stats)
    {
        if(stats->counts)
            free(stats->counts);

        free(stats);
    }

}

// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

struct TCStats *triangleCountGraphCSR(__u32 pushpull, struct GraphCSR *graph)
{
    struct TCStats *stats = NULL;

    switch (pushpull)
    {
    case 0: // pull
        stats = triangleCountBasicGraphCSR(graph);
        break;
    case 1: // pull
        stats = triangleCountPullGraphCSR(graph);
        break;
    case 2: // push
        stats = triangleCountPushGraphCSR(graph);
        break;
    default:// pull
        stats = triangleCountPullGraphCSR(graph);
        break;
    }

    return stats;

}
struct TCStats *triangleCountBasicGraphCSR(struct GraphCSR *graph)
{

    __u32 u;
    __u64 counts = 0;
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Triangle Count-basic");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Triangle Counts", "Time (S)");
    printf(" -----------------------------------------------------\n");

    struct TCStats *stats = newTCStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));

    Start(timer);
    #pragma omp parallel for shared(stats) schedule(dynamic, 1024)
    for(u = 0; u < graph->num_vertices; u++)
    {
        __u32 degree_u = graph->vertices->out_degree[u];
        __u32 edge_idx_u = graph->vertices->edges_idx[u];
        __u32 v;

        for(v = edge_idx_u; v < (edge_idx_u + degree_u) ; v++)
        {
            __u32 node_v = graph->sorted_edges_array->edges_array_dest[v];

            if(node_v > u)
                break;

            __u32 degree_v = graph->vertices->out_degree[node_v];
            __u32 edge_idx_v = graph->vertices->edges_idx[node_v];
            __u32 w;

            __u32 degree_iter = graph->vertices->out_degree[u];
            __u32 edge_idx_iter = graph->vertices->edges_idx[u];
            __u32 iter;

            for(w = edge_idx_v; w < (edge_idx_v + degree_v) ; w++)
            {

                __u32 node_w = graph->sorted_edges_array->edges_array_dest[w];

                // if(node_w > node_v)
                //     break;

                __u32 node_iter = graph->sorted_edges_array->edges_array_dest[edge_idx_iter];

                for(iter = edge_idx_iter; iter < (edge_idx_iter + degree_iter) ; iter++)
                {
                    node_iter = graph->sorted_edges_array->edges_array_dest[iter];

                    if(node_iter == node_w)
                        stats->counts[u]++;
                }

                // if(node_w == node_iter)

            }
        }
    }

    Stop(timer);
    stats->time_total = Seconds(timer);

    #pragma omp parallel for default(none) reduction (+ : counts) private(u) shared(stats)
    for(u = 0; u < stats->num_vertices; u++)
    {
        counts += stats->counts[u];
    }

    stats->total_counts = counts / 6;

    printf("| %-21llu | %-27f | \n", stats->total_counts, stats->time_total);
    printf(" -----------------------------------------------------\n");

    free(timer);
    return stats;

}
struct TCStats *triangleCountPullGraphCSR(struct GraphCSR *graph)
{

    __u32 u;
    __u64 counts = 0;
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Triangle Count-PULL");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Triangle Counts", "Time (S)");
    printf(" -----------------------------------------------------\n");

    struct TCStats *stats = newTCStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));

    Start(timer);
    #pragma omp parallel for shared(stats) reduction(+:counts) schedule(dynamic, 64)
    for(u = 0; u < graph->num_vertices; u++)
    {
        __u32 degree_u = graph->vertices->out_degree[u];
        __u32 edge_idx_u = graph->vertices->edges_idx[u];
        __u32 v;

        for(v = edge_idx_u; v < (edge_idx_u + degree_u) ; v++)
        {
            __u32 node_v = graph->sorted_edges_array->edges_array_dest[v];

            if(node_v > u)
                break;

            __u32 degree_v = graph->vertices->out_degree[node_v];
            __u32 edge_idx_v = graph->vertices->edges_idx[node_v];
            __u32 w;

            __u32 degree_iter = graph->vertices->out_degree[u];
            __u32 edge_idx_iter = graph->vertices->edges_idx[u];
            __u32 iter;

            for(w = edge_idx_v; w < (edge_idx_v + degree_v) ; w++)
            {

                __u32 node_w = graph->sorted_edges_array->edges_array_dest[w];

                if(node_w > node_v)
                    break;

                __u32 node_iter = graph->sorted_edges_array->edges_array_dest[edge_idx_iter];


                for(iter = edge_idx_iter; iter < (edge_idx_iter + degree_iter) ; iter++)
                {
                    node_iter = graph->sorted_edges_array->edges_array_dest[iter];

                    if(node_iter >= node_w)
                        break;
                }

                if(node_w == node_iter)
                {
                    counts++;
                    // printf("\rcounts: %llu ", counts * numThreads);
                    // fflush(stdout);
                }
            }
        }
    }

    Stop(timer);
    stats->time_total = Seconds(timer);

    // #pragma omp parallel for default(none) reduction (+ : counts) private(u) shared(stats)
    // for(u = 0; u < stats->num_vertices; u++)
    // {
    //     counts += stats->counts[u];
    // }

    stats->total_counts = counts;

    printf("| %-21llu | %-27f | \n", stats->total_counts, stats->time_total);
    printf(" -----------------------------------------------------\n");

    free(timer);
    return stats;

}
struct TCStats *triangleCountPushGraphCSR(struct GraphCSR *graph)
{

    __u32 u;
    __u64 counts = 0;
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Triangle Count-PUSH");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Triangle Counts", "Time (S)");
    printf(" -----------------------------------------------------\n");

    struct TCStats *stats = newTCStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));

    Start(timer);
    #pragma omp parallel for shared(stats) schedule(dynamic, 1024)
    for(u = 0; u < graph->num_vertices; u++)
    {
        __u32 degree_u = graph->vertices->out_degree[u];
        __u32 edge_idx_u = graph->vertices->edges_idx[u];
        __u32 v;

        for(v = edge_idx_u; v < (edge_idx_u + degree_u) ; v++)
        {
            __u32 node_v = graph->sorted_edges_array->edges_array_dest[v];

            if(node_v > u)
                break;

            __u32 degree_v = graph->vertices->out_degree[node_v];
            __u32 edge_idx_v = graph->vertices->edges_idx[node_v];
            __u32 w;

            __u32 degree_iter = graph->vertices->out_degree[u];
            __u32 edge_idx_iter = graph->vertices->edges_idx[u];
            __u32 iter;

            for(w = edge_idx_v; w < (edge_idx_v + degree_v) ; w++)
            {

                __u32 node_w = graph->sorted_edges_array->edges_array_dest[w];

                if(node_w > node_v)
                    break;

                __u32 node_iter = graph->sorted_edges_array->edges_array_dest[edge_idx_iter];

                for(iter = edge_idx_iter; iter < (edge_idx_iter + degree_iter) ; iter++)
                {
                    node_iter = graph->sorted_edges_array->edges_array_dest[iter];

                    if(node_iter >= node_w)
                        break;
                }

                if(node_w == node_iter)
                {
                    #pragma omp atomic update
                    stats->counts[node_w]++;
                }
            }
        }
    }

    Stop(timer);
    stats->time_total = Seconds(timer);

    #pragma omp parallel for default(none) reduction (+ : counts) private(u) shared(stats)
    for(u = 0; u < stats->num_vertices; u++)
    {
        counts += stats->counts[u];
    }

    stats->total_counts = counts;

    printf("| %-21llu | %-27f | \n", stats->total_counts, stats->time_total);
    printf(" -----------------------------------------------------\n");

    free(timer);
    return stats;

}

// ********************************************************************************************
// ***************                  GRID DataStructure                           **************
// ********************************************************************************************

struct TCStats *triangleCountGraphGrid(__u32 pushpull, struct GraphGrid *graph)
{
    struct TCStats *stats = NULL;

    switch (pushpull)
    {
    case 0: // pull
        stats = triangleCountRowGraphGrid(graph);
        break;
    case 1: // push
        stats = triangleCountColumnGraphGrid(graph);
        break;
    default:// pull
        stats = triangleCountRowGraphGrid(graph);
        break;
    }

    return stats;

}
struct TCStats *triangleCountRowGraphGrid(struct GraphGrid *graph)
{

}
struct TCStats *triangleCountColumnGraphGrid(struct GraphGrid *graph)
{

}

// ********************************************************************************************
// ***************                  ArrayList DataStructure                      **************
// ********************************************************************************************

struct TCStats *triangleCountGraphAdjArrayList(__u32 pushpull, struct GraphAdjArrayList *graph)
{
    struct TCStats *stats = NULL;

    switch (pushpull)
    {
    case 0: // pull
        stats = triangleCountPullGraphAdjArrayList(graph);
        break;
    case 1: // push
        stats = triangleCountPullGraphAdjArrayList(graph);
        break;
    default:// pull
        stats = triangleCountPullGraphAdjArrayList(graph);
        break;
    }

    return stats;
}
struct TCStats *triangleCountPullGraphAdjArrayList(struct GraphAdjArrayList *graph)
{

}
struct TCStats *triangleCountPushGraphAdjArrayList(struct GraphAdjArrayList *graph)
{

}

// ********************************************************************************************
// ***************                  LinkedList DataStructure                     **************
// ********************************************************************************************

struct TCStats *triangleCountGraphAdjLinkedList(__u32 pushpull, struct GraphAdjLinkedList *graph)
{
    struct TCStats *stats = NULL;

    switch (pushpull)
    {
    case 0: // pull
        stats = triangleCountPullGraphAdjLinkedList(graph);
        break;
    case 1: // push
        stats = triangleCountPushGraphAdjLinkedList(graph);
        break;
    default:// pull
        stats = triangleCountPullGraphAdjLinkedList(graph);
        break;
    }

    return stats;
}
struct TCStats *triangleCountPullGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

}
struct TCStats *triangleCountPushGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

}