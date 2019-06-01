#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include "mt19937.h"

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "bitmap.h"
#include "connectedComponents.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************



struct CCStats *newCCStatsGraphCSR(struct GraphCSR *graph)
{

    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
    }

    return stats;

}
struct CCStats *newCCStatsGraphGrid(struct GraphGrid *graph)
{

    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
    }

    return stats;

}
struct CCStats *newCCStatsGraphAdjArrayList(struct GraphAdjArrayList *graph)
{
    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
    }

    return stats;

}
struct CCStats *newCCStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{
    __u32 v;

    struct CCStats *stats = (struct CCStats *) my_malloc(sizeof(struct CCStats));

    stats->iterations = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;
    stats->components = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for default(none) private(v) shared(stats)
    for(v = 0; v < stats->num_vertices; v++)
    {
        stats->components[v] = v;
    }

    return stats;
}

void freeCCStats(struct CCStats *stats)
{

    if(stats)
    {
        if(stats->components)
            free(stats->components);
        free(stats);
    }
}

// ********************************************************************************************
// ***************					Helper Functions							 **************
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
    #pragma omp parallel for schedule(static, 2048)
    for (n = 0; n < num_vertices; n++)
    {
        while (components[n] != components[components[n]])
        {
            components[n] = components[components[n]];
        }
    }



}


int sortByCount( struct SampleCounts *sample1, struct SampleCounts *sample2)
{
    if (sample1->count == sample2->count) return 0;
    return (sample1->count < sample2->count) ? -1 : 1;
}

void addSample(__u32 id, struct SampleCounts *sampleCounts)
{
    struct SampleCounts *sample;
    HASH_FIND_INT(sampleCounts, &id, sample);  /* id already in the hash? */
    if (sample == NULL)
    {
        sample = (struct SampleCounts *)my_malloc(sizeof(struct SampleCounts));
        sample->id = id;
        sample->id = 1;
        HASH_ADD_INT( sampleCounts, id, sample );  /* id: name of key field */
    }
    else
    {
        sample->id++;
    }
}

__u32 sampleFrequentNode(__u32 num_vertices, __u32 num_samples, __u32 *components)
{

    struct SampleCounts *sampleCounts = NULL;
    struct SampleCounts *sampleMax = NULL;

    for (__u32 i = 0; i < num_samples; i++)
    {
        __u32 n = generateRandInt(mt19937var) % num_vertices;
        addSample(components[n], sampleCounts);
    }
    // Find most frequent element in samples (estimate of most frequent overall)

    HASH_SORT(sampleCounts, sortByCount);
    sampleMax = sampleCounts;
    float fractiongraph = ((float)sampleMax->count / num_samples * 100);

    printf("Skipping largest intermediate component (ID: %u , approx.(%) %f of the graph)\n", sampleMax->id, fractiongraph);

    return sampleMax->id;
}