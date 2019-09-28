// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : incrementalAggregation.c
// Create : 2019-09-28 15:34:51
// Revise : 2019-09-28 15:38:11
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>
#include <limits.h> //UINT_MAX

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"

#include "graphConfig.h"

#include "arrayQueue.h"
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

#include "incrementalAggregation.h"
#include "reorder.h"

// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************

struct IncrementalAggregationStats *newIncrementalAggregationStatsGraphCSR(struct GraphCSR *graph)
{

    __u32 v;

    struct IncrementalAggregationStats *stats = (struct IncrementalAggregationStats *) malloc(sizeof(struct IncrementalAggregationStats));

    stats->totalQ = 0.0;
    stats->num_clusters = 0;
    stats->atom = (union Atom *) my_malloc(graph->num_vertices * sizeof(union Atom));;

    stats->vertices = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->degrees = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->weightSum  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->atomDegree = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->atomChild = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    // union Atom *atom = (union Atom *) my_malloc(graph->num_vertices * sizeof(union Atom));

    stats->sibling = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->dest = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        stats->vertices[v] = v;
        stats->degrees[v] = graph->vertices->out_degree[v];
    }

    return stats;
}
struct IncrementalAggregationStats *newIncrementalAggregationStatsGraphGrid(struct GraphGrid *graph)
{

    __u32 v;

    struct IncrementalAggregationStats *stats = (struct IncrementalAggregationStats *) malloc(sizeof(struct IncrementalAggregationStats));

    stats->totalQ = 0.0;
    stats->num_clusters = 0;

    stats->vertices = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->degrees = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->weightSum  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->atomDegree = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->atomChild = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    // union Atom *atom = (union Atom *) my_malloc(graph->num_vertices * sizeof(union Atom));

    stats->sibling = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->dest = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        stats->vertices[v] = v;
        stats->degrees[v] = graph->grid->out_degree[v];
    }


    return stats;

}
struct IncrementalAggregationStats *newIncrementalAggregationStatsGraphAdjArrayList(struct GraphAdjArrayList *graph)
{

    __u32 v;

    struct IncrementalAggregationStats *stats = (struct IncrementalAggregationStats *) malloc(sizeof(struct IncrementalAggregationStats));

    stats->totalQ = 0.0;
    stats->num_clusters = 0;

    stats->vertices = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->degrees = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->weightSum  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->atomDegree = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->atomChild = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    // union Atom *atom = (union Atom *) my_malloc(graph->num_vertices * sizeof(union Atom));

    stats->sibling = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->dest = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        stats->vertices[v] = v;
        stats->degrees[v] = graph->vertices[v].out_degree;
    }


    return stats;
}
struct IncrementalAggregationStats *newIncrementalAggregationStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

    __u32 v;

    struct IncrementalAggregationStats *stats = (struct IncrementalAggregationStats *) malloc(sizeof(struct IncrementalAggregationStats));

    stats->time_total =  0.0;
    stats->totalQ = 0.0;
    stats->num_clusters = 0;

    stats->vertices = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->degrees = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->weightSum  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->atomDegree = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->atomChild = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    // union Atom *atom = (union Atom *) my_malloc(graph->num_vertices * sizeof(union Atom));

    stats->sibling = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->dest = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        stats->vertices[v] = v;
        stats->degrees[v] = graph->vertices[v].out_degree;
    }


    return stats;
}

void freeIncrementalAggregationStats(struct IncrementalAggregationStats *stats)
{
    if(stats)
    {
        if(stats->vertices)
            free(stats->vertices);
        if(stats->degrees)
            free(stats->degrees);
        if(stats->weightSum)
            free(stats->weightSum);
        if(stats->atomDegree)
            free(stats->atomDegree);
        if(stats->atomChild)
            free(stats->atomChild);
        if(stats->sibling)
            free(stats->sibling);
        if(stats->dest)
            free(stats->dest);
        if(stats->labels)
            free(stats->labels);

        free(stats);
    }

}



// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

struct IncrementalAggregationStats *incrementalAggregationGraphCSR( struct GraphCSR *graph)
{

    __u32 v;

    float deltaQ = -1.0;
    struct IncrementalAggregationStats *stats = newIncrementalAggregationStatsGraphCSR(graph);

    struct ArrayQueue *topLevelSet = newArrayQueue(graph->num_vertices);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Incremental Aggregation");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    //order vertices according to degree

    stats->vertices = radixSortEdgesByDegree(stats->degrees, stats->vertices, graph->num_vertices);

    //initialize variables
    #pragma omp parallel for
    for(v = 0 ; v < graph->num_vertices; v++)
    {
        stats->atomDegree[v] = graph->vertices->out_degree[v];
        stats->atomChild[v] = UINT_MAX;
        stats->atom[v].pair.degree = graph->vertices->out_degree[v];
        stats->atom[v].pair.child = UINT_MAX;

        stats->sibling[v] = UINT_MAX;
        stats->dest[v] = v;
        stats->weightSum[v] = 0;
    }



    #pragma omp parallel shared(stats, graph, topLevelSet)
    {

        //incrementally aggregate vertices
        struct ArrayQueue *Neighbors = newArrayQueue(graph->num_vertices);
        struct ArrayQueue *reachableSet = newArrayQueue(graph->num_vertices);


        #pragma omp for schedule (dynamic,1024)
        for(v = 0 ; v < graph->num_vertices; v++)
        {
            __u32 u;
            __u32 n;
            deltaQ = -1.0;
            u = stats->vertices[v];
            n = u;

            __u32 degreeU = UINT_MAX;

            //atomic swap
            degreeU =  __sync_val_compare_and_swap(&(stats->atom[u].pair.degree), stats->atom[u].pair.degree, UINT_MAX );

            findBestDestination(Neighbors, reachableSet, &deltaQ, &n, degreeU, u, stats, graph);

            if(deltaQ <= 0)
            {
                stats->atom[u].pair.degree = degreeU;
                enArrayQueueAtomic(topLevelSet, u);
                continue;
            }

            //atomic load
            union Atom atomv;

            #pragma omp atomic read
            atomv.atomicPair = stats->atom[n].atomicPair;

            if(atomv.pair.degree != UINT_MAX)
            {

                union Atom atomp;

                stats->sibling[u] = atomv.pair.child;
                atomp.pair.degree = atomv.pair.degree + degreeU;
                atomp.pair.child = u;

                if(__sync_bool_compare_and_swap(&(stats->atom[n].atomicPair), stats->atom[n].atomicPair, atomp.atomicPair))
                {
                    stats->dest[u] = n;
                    continue;
                }

            }

            stats->atom[u].pair.degree = degreeU;

            stats->sibling[u] = UINT_MAX;

            stats->totalQ += (double)deltaQ;
        }

        freeArrayQueue(reachableSet);
        freeArrayQueue(Neighbors);
    }

    stats->labels = returnLabelsOfNodesFromDendrogram(topLevelSet, stats->atom, stats->sibling, graph->num_vertices);
    stats->num_clusters = sizeArrayQueueCurr(topLevelSet);
    Stop(timer);


    stats->time_total =  Seconds(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "num_clusters", sizeArrayQueueCurr(topLevelSet),  stats->time_total);
    printf(" -----------------------------------------------------\n");


    freeArrayQueue(topLevelSet);


    return stats;
}


void findBestDestination(struct ArrayQueue *Neighbors, struct ArrayQueue *reachableSet, float *deltaQ, __u32 *u, __u32 degreeVout, __u32 v, struct IncrementalAggregationStats *stats, struct GraphCSR *graph)
{


    __u32 j;
    __u32 k;
    __u32 t;

    __u32 tempV;
    __u32 tempU;
    __u32 degreeTemp;
    __u32 edgeTemp;

    __u32 edgeWeightUV = 0;

    float deltaQtemp = 0.0;
    float numEdgesm = 1.0 / ((graph->num_edges));
    float numEdgesm2 = numEdgesm * numEdgesm;
    struct Bitmap *bitmapNC = newBitmap(graph->num_vertices);


    returnReachableSetOfNodesFromDendrogram(v, stats->atom, stats->sibling, reachableSet);
    // #pragma omp parallel for private(degreeTemp,edgeTemp,tempV,k,tempU) shared (bitmapNC,reachableSet,stats)
    for(j = reachableSet->head ; j < reachableSet->tail; j++)
    {
        tempV = reachableSet->queue[j];

        degreeTemp = graph->vertices->out_degree[tempV];
        edgeTemp = graph->vertices->edges_idx[tempV];

        for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++)
        {
            tempU = graph->sorted_edges_array->edges_array_dest[k];

            while(stats->dest[stats->dest[tempU]] != stats->dest[tempU])
            {
                // #pragma omp atomic write
                stats->dest[tempU] = stats->dest[stats->dest[tempU]];
            }
            setBitAtomic(bitmapNC, tempU);
            // edgeWeightUV++;
        }
    }

    // #pragma omp parallel for shared(Neighbors, graph, stats) reduction (+:edgeWeightUV)
    for(t = 0; t < graph->num_vertices ; t++)
    {
        if(getBit(bitmapNC, t))
        {
            if(!isEnArrayQueued(Neighbors, stats->dest[t]))
            {
                edgeWeightUV++;
                enArrayQueueWithBitmapAtomic(Neighbors, stats->dest[t]);
            }
        }
    }

    deltaQtemp = 0.0;

    for(j = Neighbors->head ; j < Neighbors->tail; j++)
    {
        __u32 i = Neighbors->queue[j];
        __u32 degreeUout = 0;
        degreeUout = stats->atom[stats->dest[i]].pair.degree;

        if(degreeUout != UINT_MAX)
        {
            deltaQtemp = 2 * ((edgeWeightUV * numEdgesm) - (float)(degreeVout * degreeUout * numEdgesm2));
            if((*deltaQ) < deltaQtemp && i != v)
            {
                (*deltaQ) = deltaQtemp;
                (*u) = i;
            }
        }
    }

    resetArrayQueue(reachableSet);
    resetArrayQueue(Neighbors);
    freeBitmap(bitmapNC);
}




void returnReachableSetOfNodesFromDendrogram(__u32 v, union Atom *atom, __u32 *sibling, struct ArrayQueue *reachableSet)
{

    traversDendrogramReachableSetDFS(v, atom, sibling, reachableSet);

}


void traversDendrogramReachableSetDFS(__u32 v, union Atom *atom, __u32 *sibling, struct ArrayQueue *reachableSet)
{

    if(atom[v].pair.child != UINT_MAX)
        traversDendrogramReachableSetDFS(atom[v].pair.child, atom, sibling, reachableSet);

    enArrayQueueWithBitmap(reachableSet, v);

    if(sibling[v] != UINT_MAX)
        traversDendrogramReachableSetDFS(sibling[v], atom, sibling, reachableSet);



}


__u32 *returnLabelsOfNodesFromDendrogram(struct ArrayQueue *reachableSet, union Atom *atom, __u32 *sibling, __u32 num_vertices)
{

    __u32 i;
    __u32 newLablesCounter = 0;
    __u32 *newLables = (__u32 *) my_malloc(num_vertices * sizeof(__u32));

    for(i = reachableSet->head ; i < reachableSet->tail; i++)
    {
        // printf("%u \n", reachableSet->queue[i]);
        traversDendrogramLabelsDFS(&newLablesCounter, newLables, reachableSet->queue[i], atom, sibling);

    }

    return newLables;

}


void traversDendrogramLabelsDFS(__u32 *newLablesCounter, __u32 *newLables, __u32 v, union Atom *atom, __u32 *sibling)
{

    if(v == UINT_MAX)
        return;

    traversDendrogramLabelsDFS(newLablesCounter, newLables, atom[v].pair.child, atom, sibling);
    // printf("%u %u \n", v, (*newLablesCounter));
    newLables[v] = (*newLablesCounter);
    (*newLablesCounter)++;
    traversDendrogramLabelsDFS(newLablesCounter, newLables, sibling[v], atom, sibling);

}

void printSet(struct ArrayQueue *Set)
{
    __u32 i;
    printf("S : ");
    for(i = Set->head ; i < Set->tail; i++)
    {
        printf("%u|", Set->queue[i]);
    }
    printf("\n");

}