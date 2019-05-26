#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>
#include <limits.h> //UINT_MAX

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "incrementalAggregation.h"
#include "reorder.h"


#include "arrayQueue.h"
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************

struct IncrementalAggregationStats *newIncrementalAggregationStatsGraphCSR(struct GraphCSR *graph)
{

    __u32 v;

    struct IncrementalAggregationStats *stats = (struct IncrementalAggregationStats *) malloc(sizeof(struct IncrementalAggregationStats));

    stats->totalQ = 0.0;

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

    stats->totalQ = 0.0;

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

        free(stats);
    }

}



// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

__u32  *incrementalAggregationGraphCSR( struct GraphCSR *graph)
{

    __u32 v;
    __u32 u;
    __u32 n;
    float deltaQ = -1.0;
    __u32   *labels = NULL;
    struct IncrementalAggregationStats *stats = newIncrementalAggregationStatsGraphCSR(graph);
    struct ArrayQueue *Neighbors = newArrayQueue(graph->num_vertices);
    struct ArrayQueue *reachableSet = newArrayQueue(graph->num_vertices);
    struct ArrayQueue *topLevelSet = newArrayQueue(graph->num_vertices);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Incremental Aggregation");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    //order vertices according to degree

    stats->vertices = radixSortEdgesByDegree(stats->degrees, stats->vertices, graph->num_vertices);

    //initialize variables
    #pragma omp parallel for private(u)
    for(v = 0 ; v < graph->num_vertices; v++)
    {
        u = stats->vertices[v];
        stats->atomDegree[u] = graph->vertices->out_degree[u];
        stats->atomChild[u] = UINT_MAX;

        // atom[v].degree = graph->vertices[u].out_degree;
        // atom[u].child = UINT_MAX;

        stats->sibling[u] = UINT_MAX;
        stats->dest[u] = u;
        stats->weightSum[u] = 0;
    }





    //incrementally aggregate vertices
    for(v = 0 ; v < graph->num_vertices; v++)
    {

        deltaQ = -1.0;
        __u32 atomVchild;
        __u32 atomVdegree;
        u = stats->vertices[v];
        n = stats->vertices[v];

        __u32 degreeU = UINT_MAX;

        // //atomic swap
        __u32 degreeUtemp = stats->atomDegree[u];
        degreeU = degreeUtemp;
        stats->atomDegree[u] = degreeU;

        findBestDestination(Neighbors, reachableSet, &deltaQ, &n, u, stats, graph);
        // printf("n %u u %u deltaQ %f\n",n,u,deltaQ );

        if(deltaQ <= 0)
        {
            stats->atomDegree[u] = degreeU;
            enArrayQueueAtomic(topLevelSet, u);
            continue;
        }

        //atomic load
        // #pragma omp atomic read
        atomVchild = stats->atomChild[n];

        // #pragma omp atomic read
        atomVdegree = stats->atomDegree[n];
        // printf("atomVdegree %u \n",atomVdegree );

        if(atomVdegree != UINT_MAX)
        {
            stats->sibling[u] = atomVchild;

            __u32 atomVdegreep = atomVdegree + degreeU;
            __u32 atomVchildp = u;

            stats->atomChild[n] = atomVchildp;
            stats->atomDegree[n] = atomVdegreep;


            stats->dest[u] = n;
            continue;

        }

        stats->atomDegree[u] = degreeU;
        stats->sibling[u] = UINT_MAX;

        stats->totalQ += (double)deltaQ;

    }


    for(v = 0; v < graph->num_vertices; v++)
    {
        u = stats->vertices[v];
        // printf("[u] %u child %u sibling %u deg %u dest %u\n", u, atomChild[u], sibling[u], atomDegree[u], dest[u]);
    }

    // printSet(topLevelSet);
    labels = returnLabelsOfNodesFromDendrogram(topLevelSet, stats->atomChild, stats->sibling, graph->num_vertices);

    Stop(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "Clusters", sizeArrayQueueCurr(topLevelSet),  Seconds(timer));
    printf(" -----------------------------------------------------\n");
    // printf(" -----------------------------------------------------\n");
    // printf("| %-15s | %-15lf | %-15f | \n", "total Q", totalQ, Seconds(timer));
    // printf(" -----------------------------------------------------\n");


    freeArrayQueue(topLevelSet);
    freeArrayQueue(reachableSet);
    freeArrayQueue(Neighbors);
    freeIncrementalAggregationStats(stats);

    //  for(v = 0; v < graph->num_vertices; v++)
    // {

    //     printf("%u %u \n", v, labels[v]);
    //     // printf("[u] %u child %u sibling %u deg %u dest %u\n", u, atomChild[u], sibling[u], atomDegree[u], dest[u]);
    // }


    return labels;
}


void findBestDestination(struct ArrayQueue *Neighbors, struct ArrayQueue *reachableSet, float *deltaQ, __u32 *u, __u32 v, struct IncrementalAggregationStats* stats, struct GraphCSR *graph)
{


    __u32 j;
    __u32 k;

    __u32 tempV;
    __u32 tempU;
    __u32 degreeTemp;
    __u32 edgeTemp;

    __u32 edgeWeightVU = 0;
    __u32 edgeWeightUV = 0;
    __u32 degreeVout = 0;
    __u32 degreeVin = 0;
    __u32 degreeUout = 0;
    __u32 degreeUin = 0;
    float deltaQtemp = 0.0;
    float numEdgesm = 1.0 / ((graph->num_edges));
    float numEdgesm2 = numEdgesm * numEdgesm;

    // struct Vertex *vertices = NULL;
    // struct EdgeList  *sorted_edges_array = NULL;

    // #if DIRECTED
    //     vertices = graph->inverse_vertices;
    //     sorted_edges_array = graph->inverse_sorted_edges_array;
    // #else
    //     vertices = graph->vertices;
    //     sorted_edges_array = graph->sorted_edges_array;
    // #endif

    returnReachableSetOfNodesFromDendrogram(v, stats->atomChild, stats->sibling, reachableSet);

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
                stats->dest[tempU] = stats->dest[stats->dest[tempU]];
            }

            #pragma omp atomic update
            stats->weightSum[stats->dest[tempU]]++;

            if(!isEnArrayQueued(Neighbors, stats->dest[tempU]) &&  stats->dest[stats->dest[tempV]] != stats->dest[tempU])
            {
                enArrayQueueWithBitmap(Neighbors, stats->dest[tempU]);
                // printf("->%u %u - ",dest[tempV], dest[tempU]);
            }

        }



    }


    // edge_idv = graph->vertices[v].edges_idx;
    degreeVout = stats->atomDegree[stats->dest[v]];
    degreeVin = stats->atomDegree[stats->dest[v]];

    for(j = Neighbors->head ; j < Neighbors->tail; j++)
    {

        deltaQtemp = 0.0;
        // edgeWeightVU =   weightSum[dest[v]];
        __u32 i = Neighbors->queue[j];
        degreeUout = stats->atomDegree[stats->dest[i]];

        // if(degreeUout != UINT_MAX)
        // {


        degreeUin = stats->atomDegree[stats->dest[i]];


        edgeWeightUV = stats->weightSum[stats->dest[i]];
        edgeWeightVU = stats->weightSum[stats->dest[i]];

        deltaQtemp = ((edgeWeightVU * numEdgesm) - (float)(degreeVin * degreeUout * numEdgesm2)) + ((edgeWeightUV * numEdgesm) - (float)(degreeUin * degreeVout * numEdgesm2));


        if((*deltaQ) < deltaQtemp)
        {
            (*deltaQ) = deltaQtemp;
            (*u) = i;
        }


        // printf("v %u u %u q %lf\n", v, i, deltaQtemp);
        // }

    }

    for(j = reachableSet->head ; j < reachableSet->tail; j++)
    {
        tempV = reachableSet->queue[j];

        degreeTemp = graph->vertices->out_degree[tempV];
        edgeTemp = graph->vertices->edges_idx[tempV];

        for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++)
        {
            tempU = graph->sorted_edges_array->edges_array_dest[k];

            #pragma omp atomic write
            stats->weightSum[stats->dest[tempU]] = 0;
        }
    }

    resetArrayQueue(reachableSet);
    resetArrayQueue(Neighbors);
}




void returnReachableSetOfNodesFromDendrogram(__u32 v, __u32 *atomChild, __u32 *sibling, struct ArrayQueue *reachableSet)
{

    traversDendrogramReachableSetDFS(v, atomChild, sibling, reachableSet);

}


void traversDendrogramReachableSetDFS(__u32 v, __u32 *atomChild, __u32 *sibling, struct ArrayQueue *reachableSet)
{

    if(atomChild[v] != UINT_MAX)
        traversDendrogramReachableSetDFS(atomChild[v], atomChild, sibling, reachableSet);

    enArrayQueue(reachableSet, v);

    if(sibling[v] != UINT_MAX)
        traversDendrogramReachableSetDFS(sibling[v], atomChild, sibling, reachableSet);



}


__u32 *returnLabelsOfNodesFromDendrogram(struct ArrayQueue *reachableSet, __u32 *atomChild, __u32 *sibling, __u32 num_vertices)
{

    __u32 i;
    __u32 newLablesCounter = 0;
    __u32 *newLables = (__u32 *) my_malloc(num_vertices * sizeof(__u32));

    for(i = reachableSet->head ; i < reachableSet->tail; i++)
    {
        // printf("%u \n", reachableSet->queue[i]);
        traversDendrogramLabelsDFS(&newLablesCounter, newLables, reachableSet->queue[i], atomChild, sibling);

    }

    return newLables;

}


void traversDendrogramLabelsDFS(__u32 *newLablesCounter, __u32 *newLables, __u32 v, __u32 *atomChild, __u32 *sibling)
{

    if(v == UINT_MAX)
        return;

    traversDendrogramLabelsDFS(newLablesCounter, newLables, atomChild[v], atomChild, sibling);
    // printf("%u %u \n", v, (*newLablesCounter));
    newLables[v] = (*newLablesCounter);
    (*newLablesCounter)++;
    traversDendrogramLabelsDFS(newLablesCounter, newLables, sibling[v], atomChild, sibling);



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