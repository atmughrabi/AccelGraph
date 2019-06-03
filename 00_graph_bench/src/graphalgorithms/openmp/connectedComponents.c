#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include <Judy.h>

#include "mt19937.h"
// #include "libchash.h"
#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "bitmap.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"
#include "reorder.h"
#include "connectedComponents.h"


Pvoid_t JArray = (PWord_t) NULL; // Declare static hash table

// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************



struct CCStats *newCCStatsGraphCSR(struct GraphCSR *graph)
{

    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->iterations = 0;
    stats->neighbor_rounds = 2;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->counts = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->labels = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
        stats->labels[v] = v;
        stats->counts[v] = 0;
    }

    return stats;

}
struct CCStats *newCCStatsGraphGrid(struct GraphGrid *graph)
{

    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->neighbor_rounds = 2;
    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->counts = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->labels = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
        stats->labels[v] = v;
        stats->counts[v] = 0;
    }

    return stats;

}
struct CCStats *newCCStatsGraphAdjArrayList(struct GraphAdjArrayList *graph)
{
    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->neighbor_rounds = 2;
    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->counts = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->labels = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
        stats->labels[v] = v;
        stats->counts[v] = 0;
    }
    return stats;

}
struct CCStats *newCCStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{
    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->neighbor_rounds = 2;
    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->counts = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->labels = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
        stats->labels[v] = v;
        stats->counts[v] = 0;
    }

    return stats;
}

void freeCCStats(struct CCStats *stats)
{

    if(stats)
    {
        if(stats->components)
            free(stats->components);
        if(stats->counts)
            free(stats->counts);
        if(stats->labels)
            free(stats->labels);
        free(stats);
    }
}

void printCCStats(struct CCStats *stats)
{

    Word_t *PValue;
    Word_t   Index;
    __u32 k = 5;
    __u32 numComp = 0;
    __u32 i;

    for(i = 0; i < stats->num_vertices; i++)
    {
        addSample(stats->components[i]);
    }


    Index = 0;
    JLF(PValue, JArray, Index);
    while (PValue != NULL)
    {
        // printf("%lu %lu\n", Index, *PValue);
        stats->counts[Index] = *PValue;
        * PValue = 0;
        JLN(PValue, JArray, Index);

    }

    for(i = 0; i < stats->num_vertices; i++)
    {
        if(stats->counts[i])
            numComp++;
    }

    stats->labels = radixSortEdgesByDegree(stats->counts, stats->labels, stats->num_vertices);
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Top Clusters", "Count");
    printf(" -----------------------------------------------------\n");

    for(i = (stats->num_vertices - 1); i > (stats->num_vertices - 1 - k); i--)
    {

        printf("| %-21u | %-27u | \n", stats->labels[i], stats->counts[i] );

    }
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27u | \n", "Num Components", numComp);
    printf(" -----------------------------------------------------\n");
}

void printComponents(struct CCStats *stats)
{

    __u32 i;
    for(i = 0 ; i < stats->num_vertices; i++)
    {
        printf("v : %u comp : %u \n", i, stats->components[i]);
    }

}

// ********************************************************************************************
// ***************              Afforest Helper Functions                        **************
// ********************************************************************************************

void linkNodes(__u32 u, __u32 v, __u32 *components)
{
    __u32 p1 = components[u];
    __u32 p2 = components[v];

    while(p1 != p2)
    {
        __u32 high = p1 > p2 ? p1 : p2;
        __u32 low = p1 + (p2 - high);
        __u32 phigh = components[high];

        if ((phigh == low) ||
                (phigh == high && __sync_bool_compare_and_swap(&(components[high]), high, low)))
            break;
        p1 = components[components[high]];
        p2 = components[low];

    }

}


void compressNodes(__u32 num_vertices, __u32 *components)
{
    __u32 n;
    #pragma omp parallel for schedule(dynamic, 2048)
    for (n = 0; n < num_vertices; n++)
    {
        while (components[n] != components[components[n]])
        {
            components[n] = components[components[n]];
        }
    }
}


void addSample(__u32 id)
{
    Word_t *PValue;

    JLI(PValue, JArray, id);
    *PValue += 1;

}

__u32 sampleFrequentNode(__u32 num_vertices, __u32 num_samples, __u32 *components)
{

    Word_t *PValue;
    Word_t   Index;
    __u32 i;
    for (i = 0; i < num_samples; i++)
    {
        __u32 n = generateRandInt(mt19937var) % num_vertices;
        addSample(components[n]);
    }

    __u32 maxKey = 0;
    __u32 maxCount = 0;

    Index = 0;
    JLF(PValue, JArray, Index);
    while (PValue != NULL)
    {
        // printf("%lu %lu\n", Index, *PValue);
        if(*PValue > maxCount)
        {
            maxCount = *PValue;
            maxKey = Index;

        }
        *PValue = 0;
        JLN(PValue, JArray, Index);

    }

    float fractiongraph = ((float)maxCount / num_samples);

    printf("| %-21s | %-27u | \n", "Skipping(%)", (int)fractiongraph * 100);



    return maxKey;
}

// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

struct CCStats *connectedComponentsGraphCSR(__u32 iterations, __u32 pushpull, struct GraphCSR *graph)
{

    struct CCStats *stats = NULL;

    switch (pushpull)
    {

    case 0: // pull
        stats = connectedComponentsShiloachVishkinGraphCSR( iterations, graph);
        break;
    case 1: // push
        stats = connectedComponentsAfforestGraphCSR( iterations, graph);
        break;
    default:// pull
        stats = connectedComponentsShiloachVishkinGraphCSR( iterations, graph);
        break;
    }

    return stats;

}
struct CCStats *connectedComponentsAfforestGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

    __u32 u;
    __u32 componentsCount = 0;
    Word_t    Bytes;
    __u32 num_samples = 1024;

    if(num_samples > graph->num_vertices)
        num_samples = graph->num_vertices / 2;

    struct CCStats *stats = newCCStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));


    stats->neighbor_rounds = 2;


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Afforest Connected Components");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Neighbor Round", "Time (S)");
    printf(" -----------------------------------------------------\n");

    __u32 r = 0;

    Start(timer);
    for(r = 0; r < stats->neighbor_rounds; r++)
    {
        Start(timer_inner);
        #pragma omp parallel for schedule(dynamic, 2048)
        for(u = 0; u < graph->num_vertices; u++)
        {
            __u32 j;
            __u32 v;
            __u32 degree_out =  graph->vertices->out_degree[u];
            __u32 edge_idx_out =  graph->vertices->edges_idx[u];

            for(j = (edge_idx_out + r) ; j < (edge_idx_out + degree_out) ; j++)
            {
                v =  graph->sorted_edges_array->edges_array_dest[j];
                linkNodes(u, v, stats->components);
                break;
            }
        }
        Stop(timer_inner);
        printf("| %-21u | %-27f | \n", r, Seconds(timer_inner));

        Start(timer_inner);
        compressNodes(graph->num_vertices, stats->components);
        Stop(timer_inner);
        printf(" -----------------------------------------------------\n");
        printf("| %-21s | %-27s | \n", "Compress", "Time (S)");
        printf(" -----------------------------------------------------\n");
        printf("| %-21s | %-27f | \n", "", Seconds(timer_inner));
        printf(" -----------------------------------------------------\n");

    }// end neighbor_rounds loop


    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Sampling Components", "");
    printf(" -----------------------------------------------------\n");
    Start(timer_inner);
    __u32 sampleComp = sampleFrequentNode(graph->num_vertices, num_samples,  stats->components);
    Stop(timer_inner);
    printf("| Most freq ID: %-7u | %-27f | \n", sampleComp, Seconds(timer_inner));

    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Final Link Phase", "Time (S)");
    printf(" -----------------------------------------------------\n");
    Start(timer_inner);
#if DIRECTED
    #pragma omp parallel for schedule(dynamic, 2048)
    for(u = 0; u < graph->num_vertices; u++)
    {
        __u32 j;
        __u32 v;
        __u32 degree_out;
        __u32 degree_in;
        __u32 edge_idx_out;
        __u32 edge_idx_in;

        if(stats->components[u] == sampleComp)
            continue;

        degree_out =  graph->vertices->out_degree[u];
        edge_idx_out =  graph->vertices->edges_idx[u];

        for(j = (edge_idx_out + stats->neighbor_rounds) ; j < (edge_idx_out + degree_out) ; j++)
        {
            v =  graph->sorted_edges_array->edges_array_dest[j];
            linkNodes(u, v, stats->components);
        }

        degree_in =  graph->inverse_vertices->out_degree[u];
        edge_idx_in =  graph->inverse_vertices->edges_idx[u];

        for(j = (edge_idx_in) ; j < (edge_idx_in + degree_in) ; j++)
        {
            v =  graph->inverse_sorted_edges_array->edges_array_dest[j];
            linkNodes(u, v, stats->components);
        }

    }
#else
    #pragma omp parallel for schedule(dynamic, 2048)
    for(u = 0; u < graph->num_vertices; u++)
    {
        __u32 j;
        __u32 v;
        __u32 degree_out;
        __u32 degree_in;
        __u32 edge_idx_out;
        __u32 edge_idx_in;

        if(stats->components[u] == sampleComp)
            continue;

        degree_out =  graph->vertices->out_degree[u];
        edge_idx_out =  graph->vertices->edges_idx[u];

        for(j = (edge_idx_out + stats->neighbor_rounds) ; j < (edge_idx_out + degree_out) ; j++)
        {
            v =  graph->sorted_edges_array->edges_array_dest[j];
            linkNodes(u, v, stats->components);
        }
    }
#endif
    Stop(timer_inner);
    printf("| %-21u | %-27f | \n", componentsCount, Seconds(timer_inner));

    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Compress", "Time (S)");
    printf(" -----------------------------------------------------\n");
    Start(timer_inner);
    compressNodes(graph->num_vertices, stats->components);
    Stop(timer_inner);
    printf("| %-21u | %-27f | \n", r, Seconds(timer_inner));
    Stop(timer);
    stats->time_total = Seconds(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iterations", "Components", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-15u | %-15u | %-15f | \n", stats->neighbor_rounds, componentsCount, stats->time_total);
    printf(" -----------------------------------------------------\n");


    free(timer);
    free(timer_inner);

    printCCStats(stats);

    JSLFA(Bytes, JArray);
    return stats;

}
struct CCStats *connectedComponentsShiloachVishkinGraphCSR( __u32 iterations, struct GraphCSR *graph)
{

    __u32 v;
    __u32 degree;
    __u32 edge_idx;
    __u32 componentsCount = 0;


    struct CCStats *stats = newCCStatsGraphCSR(graph);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

    struct Vertex *vertices = NULL;
    __u32 *sorted_edges_array = NULL;

#if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edges_array->edges_array_dest;
#else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edges_array->edges_array_dest;
#endif


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Shiloach-Vishkin Connected Components");
    printf(" -----------------------------------------------------\n");
    printf("| %-21s | %-27s | \n", "Iteration", "Time (S)");
    printf(" -----------------------------------------------------\n");


    Start(timer);
    for(stats->iterations = 0; stats->iterations < iterations; stats->iterations++)
    {
        Start(timer_inner);

        #pragma omp parallel for private(v,degree,edge_idx) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            __u32 j;
            __u32 src = v;
            __u32 dest;

            degree = graph->vertices->out_degree[src];
            edge_idx = graph->vertices->edges_idx[src];

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                dest = graph->sorted_edges_array->edges_array_dest[j];


            }
        }


        Stop(timer_inner);
        printf("| %-21u | %-27f | \n", stats->iterations, Seconds(timer_inner));

    }// end iteration loop


    Stop(timer);
    stats->time_total = Seconds(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iterations", "Components", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-15u | %-15u | %-15f | \n", stats->iterations, componentsCount, stats->time_total);
    printf(" -----------------------------------------------------\n");


    free(timer);
    free(timer_inner);
    return stats;

}