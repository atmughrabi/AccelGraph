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
    stats->atom = (struct Atom *) my_malloc(graph->num_vertices * sizeof(struct Atom));;

    stats->vertices = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->degrees = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->weightSum  = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    stats->atomDegree = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    stats->atomChild = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    // struct Atom *atom = (struct Atom *) my_malloc(graph->num_vertices * sizeof(struct Atom));

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

    // struct Atom *atom = (struct Atom *) my_malloc(graph->num_vertices * sizeof(struct Atom));

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

    // struct Atom *atom = (struct Atom *) my_malloc(graph->num_vertices * sizeof(struct Atom));

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

    // struct Atom *atom = (struct Atom *) my_malloc(graph->num_vertices * sizeof(struct Atom));

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
        stats->atom[v].degree = graph->vertices->out_degree[v];
        stats->atom[v].child = UINT_MAX;

        stats->sibling[v] = UINT_MAX;
        stats->dest[v] = v;
        stats->weightSum[v] = 0;
    }



    // #pragma omp parallel shared(stats, graph, topLevelSet)
    {

        //incrementally aggregate vertices
        struct ArrayQueue *Neighbors = newArrayQueue(graph->num_vertices);
        struct ArrayQueue *reachableSet = newArrayQueue(graph->num_vertices);



        // #pragma omp  for
        for(v = 0 ; v < graph->num_vertices; v++)
        {
            __u32 u;
            __u32 n;
            deltaQ = -1.0;
            __u32 atomVchild;
            __u32 atomVdegree;
            u = stats->vertices[v];
            n = u;

            __u32 degreeU = UINT_MAX;

            // //atomic swap
            __u32 degreeUtemp = stats->atom[u].degree;
            degreeU = degreeUtemp;
            stats->atom[u].degree = degreeU;

            // __sync_bool_compare_and_swap()

            findBestDestination(Neighbors, reachableSet, &deltaQ, &n, u, stats, graph);

            if(deltaQ <= 0)
            {
                stats->atom[u].degree = degreeU;
                enArrayQueueAtomic(topLevelSet, u);
                continue;
            }

            //atomic load
            // #pragma omp atomic read
            atomVchild = stats->atom[n].child;
            atomVdegree = stats->atom[n].degree;

            if(atomVdegree != UINT_MAX)
            {
                stats->sibling[u] = atomVchild;

                struct Atom atomp;

                atomp.degree = atomVdegree + degreeU;
                atomp.child = u;

                stats->atom[n] = atomp;

                stats->dest[u] = n;
                continue;

            }
            stats->atom[u].degree = degreeU;

            stats->sibling[u] = UINT_MAX;

            stats->totalQ += (double)deltaQ;
        }

        freeArrayQueue(reachableSet);
        freeArrayQueue(Neighbors);
    }

    printSet(topLevelSet);
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


void findBestDestination(struct ArrayQueue *Neighbors, struct ArrayQueue *reachableSet, float *deltaQ, __u32 *u, __u32 v, struct IncrementalAggregationStats *stats, struct GraphCSR *graph)
{


    __u32 j;
    __u32 k;
    __u32 t;

    __u32 tempV;
    __u32 tempU;
    __u32 degreeTemp;
    __u32 edgeTemp;

    __u32 edgeWeightUV = 0;
    __u32 degreeVout = 0;
    __u32 degreeUout = 0;
    float deltaQtemp = 0.0;
    float numEdgesm = 1.0 / ((graph->num_edges));
    float numEdgesm2 = numEdgesm * numEdgesm;
    struct Bitmap *bitmapNC = newBitmap(graph->num_vertices);

    // struct Vertex *vertices = NULL;
    // struct EdgeList  *sorted_edges_array = NULL;

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
                #pragma omp atomic write
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


    // edge_idv = graph->vertices[v].edges_idx;
    degreeVout = stats->atom[stats->dest[v]].degree;

    for(j = Neighbors->head ; j < Neighbors->tail; j++)
    {
        __u32 i = Neighbors->queue[j];
        deltaQtemp = 0.0;
        degreeUout = stats->atom[stats->dest[i]].degree;

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




void returnReachableSetOfNodesFromDendrogram(__u32 v, struct Atom *atom, __u32 *sibling, struct ArrayQueue *reachableSet)
{

    traversDendrogramReachableSetDFS(v, atom, sibling, reachableSet);

}


void traversDendrogramReachableSetDFS(__u32 v, struct Atom *atom, __u32 *sibling, struct ArrayQueue *reachableSet)
{

    if(atom[v].child != UINT_MAX)
        traversDendrogramReachableSetDFS(atom[v].child, atom, sibling, reachableSet);

    enArrayQueueWithBitmap(reachableSet, v);

    if(sibling[v] != UINT_MAX)
        traversDendrogramReachableSetDFS(sibling[v], atom, sibling, reachableSet);



}


__u32 *returnLabelsOfNodesFromDendrogram(struct ArrayQueue *reachableSet, struct Atom *atom, __u32 *sibling, __u32 num_vertices)
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


void traversDendrogramLabelsDFS(__u32 *newLablesCounter, __u32 *newLables, __u32 v, struct Atom *atom, __u32 *sibling)
{

    if(v == UINT_MAX)
        return;

    traversDendrogramLabelsDFS(newLablesCounter, newLables, atom[v].child, atom, sibling);
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