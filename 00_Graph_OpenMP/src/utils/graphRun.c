#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

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


void generateGraphPrintMessageWithtime(const char *msg, double time)
{

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}



void *generateGraphDataStructure(const char *fnameb, __u32 datastructure, __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    void *graph = NULL;

    printf("*-----------------------------------------------------*\n");
    printf("| %-20s %-30u | \n", "Number of Threads :", numThreads);
    printf(" -----------------------------------------------------\n");

    switch (datastructure)
    {
    case 0: // CSR
    case 4:
        Start(timer);
        graph = (void *)graphCSRPreProcessingStep (fnameb, sort, lmode, symmetric, weighted);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));
        break;
    case 1: // Grid
    case 5:
        Start(timer);
        graph = (void *)graphGridPreProcessingStep (fnameb, sort, lmode, symmetric, weighted);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphGrid Preprocessing Step Time (Seconds)", Seconds(timer));
        break;
    case 2: // Adj Linked List
        Start(timer);
        graph = (void *)graphAdjLinkedListPreProcessingStep (fnameb, lmode, symmetric, weighted);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphAdjLinkedList Preprocessing Step Time (Seconds)", Seconds(timer));
        break;
    case 3: // Adj Array List
        Start(timer);
        graph = (void *)graphAdjArrayListPreProcessingStep (fnameb, sort, lmode, symmetric, weighted);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphAdjArrayList Preprocessing Step Time (Seconds)", Seconds(timer));
        break;
    default:// CSR
        Start(timer);
        graph = (void *)graphCSRPreProcessingStep (fnameb, sort, lmode, symmetric, weighted);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));

        break;
    }


    free(timer);
    return graph;

}


void runGraphAlgorithms(void *graph, __u32 datastructure, __u32 algorithm, int root, __u32 iterations, double epsilon, __u32 trials, __u32 pushpull,  __u32 delta)
{

    switch (algorithm)
    {
    case 0: // bfs filename root
        runBreadthFirstSearchAlgorithm(graph, datastructure, root, trials);
        break;
    case 1: // pagerank filename
        runPageRankAlgorithm(graph, datastructure, epsilon, iterations, trials, pushpull);
        break;
    case 2: // SSSP-Dijkstra file name root
        runSSSPAlgorithm(graph, datastructure, root, iterations, trials, pushpull, delta);
        break;
    case 3: // SSSP-Bellmanford file name root
        runBellmanFordAlgorithm(graph, datastructure, root, iterations, trials, pushpull);
        break;
    case 4: // DFS file name root
        runDepthFirstSearchAlgorithm(graph, datastructure, root, trials);
        break;
    case 5: // incremental Aggregation file name root
        runIncrementalAggregationAlgorithm(graph, datastructure, trials);
        break;
    default:// bfs file name root
        runBreadthFirstSearchAlgorithm(graph, datastructure, root, trials);
        break;
    }

}



void runBreadthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 trials)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct GraphCSR *graphCSR = NULL;
    struct GraphGrid *graphGrid = NULL;
    struct GraphAdjLinkedList *graphAdjLinkedList = NULL;
    struct GraphAdjArrayList *graphAdjArrayList = NULL;

    switch (datastructure)
    {
    case 0: // CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            breadthFirstSearchGraphCSR(root, graphCSR);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                breadthFirstSearchGraphCSR(root, graphCSR);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;

    case 1: // Grid
        graphGrid = (struct GraphGrid *)graph;
        if(root < graphGrid->num_vertices)
        {
            breadthFirstSearchGraphGrid(root, graphGrid);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphGrid->num_vertices)
                {
                    if(graphGrid->grid->out_degree[root] > 0)
                        break;
                }
            }
            if(root < graphGrid->num_vertices)
            {
                breadthFirstSearchGraphGrid(root, graphGrid);
            }
            trials--;
        }
        Start(timer);
        graphGridFree(graphGrid);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)", Seconds(timer));
        break;

    case 2: // Adj Linked List
        graphAdjLinkedList = (struct GraphAdjLinkedList *)graph;
        if(root < graphAdjLinkedList->num_vertices)
        {
            breadthFirstSearchGraphAdjLinkedList(root, graphAdjLinkedList);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphAdjLinkedList->num_vertices)
                {
                    if(graphAdjLinkedList->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphAdjLinkedList->num_vertices)
            {
                breadthFirstSearchGraphAdjLinkedList(root, graphAdjLinkedList);
            }
            trials--;
        }
        Start(timer);
        graphAdjLinkedListFree(graphAdjLinkedList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)", Seconds(timer));
        break;

    case 3: // Adj Array List
        graphAdjArrayList = (struct GraphAdjArrayList *)graph;
        if(root < graphAdjArrayList->num_vertices)
        {
            breadthFirstSearchGraphAdjArrayList(root, graphAdjArrayList);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphAdjArrayList->num_vertices)
                {
                    if(graphAdjArrayList->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphAdjArrayList->num_vertices)
            {
                breadthFirstSearchGraphAdjArrayList(root, graphAdjArrayList);
            }
            trials--;
        }
        Start(timer);
        graphAdjArrayListFree(graphAdjArrayList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)", Seconds(timer));
        break;

    case 4: // CSR with no frontier only Bitmaps
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            breadthFirstSearchUsingBitmapsGraphCSR(root, graphCSR);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                breadthFirstSearchUsingBitmapsGraphCSR(root, graphCSR);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;

    case 5: // Grid with no frontiers only Bitmaps
        graphGrid = (struct GraphGrid *)graph;
        if(root < graphGrid->num_vertices)
        {
            breadthFirstSearchGraphGridBitmap(root, graphGrid);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphGrid->num_vertices)
                {
                    if(graphGrid->grid->out_degree[root] > 0)
                        break;
                }
            }
            if(root < graphGrid->num_vertices)
            {
                breadthFirstSearchGraphGridBitmap(root, graphGrid);
            }
            trials--;
        }
        Start(timer);
        graphGridFree(graphGrid);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)", Seconds(timer));
        break;



    default:// CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            breadthFirstSearchGraphCSR(root, graphCSR);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                breadthFirstSearchGraphCSR(root, graphCSR);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;
    }

    free(timer);

}

void runDepthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 trials)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct GraphCSR *graphCSR = NULL;
    struct GraphGrid *graphGrid = NULL;
    struct GraphAdjLinkedList *graphAdjLinkedList = NULL;
    struct GraphAdjArrayList *graphAdjArrayList = NULL;

    switch (datastructure)
    {
    case 0: // CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            depthFirstSearchGraphCSR(root, graphCSR);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                depthFirstSearchGraphCSR(root, graphCSR);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;

    case 1: // Grid
        graphGrid = (struct GraphGrid *)graph;

        Start(timer);
        graphGridFree(graphGrid);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)", Seconds(timer));
        break;

    case 2: // Adj Linked List
        graphAdjLinkedList = (struct GraphAdjLinkedList *)graph;

        Start(timer);
        graphAdjLinkedListFree(graphAdjLinkedList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)", Seconds(timer));
        break;

    case 3: // Adj Array List
        graphAdjArrayList = (struct GraphAdjArrayList *)graph;

        Start(timer);
        graphAdjArrayListFree(graphAdjArrayList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)", Seconds(timer));
        break;


    default:// CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            breadthFirstSearchGraphCSR(root, graphCSR);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                breadthFirstSearchGraphCSR(root, graphCSR);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;
    }

    free(timer);

}


void runIncrementalAggregationAlgorithm(void *graph, __u32 datastructure, __u32 trials)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct GraphCSR *graphCSR = NULL;
    struct GraphGrid *graphGrid = NULL;
    struct GraphAdjLinkedList *graphAdjLinkedList = NULL;
    struct GraphAdjArrayList *graphAdjArrayList = NULL;

    switch (datastructure)
    {
    case 0: // CSR
        graphCSR = (struct GraphCSR *)graph;
        while(trials)
        {
            incrementalAggregationGraphCSR(graphCSR);
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;

    case 1: // Grid
        graphGrid = (struct GraphGrid *)graph;

        Start(timer);
        graphGridFree(graphGrid);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)", Seconds(timer));
        break;

    case 2: // Adj Linked List
        graphAdjLinkedList = (struct GraphAdjLinkedList *)graph;

        Start(timer);
        graphAdjLinkedListFree(graphAdjLinkedList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)", Seconds(timer));
        break;

    case 3: // Adj Array List
        graphAdjArrayList = (struct GraphAdjArrayList *)graph;

        Start(timer);
        graphAdjArrayListFree(graphAdjArrayList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)", Seconds(timer));
        break;


    default:// CSR
        graphCSR = (struct GraphCSR *)graph;
        while(trials)
        {
            incrementalAggregationGraphCSR(graphCSR);
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;
    }

    free(timer);

}



void runPageRankAlgorithm(void *graph, __u32 datastructure, double epsilon, __u32 iterations, __u32 trials, __u32 pushpull)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct GraphCSR *graphCSR = NULL;
    struct GraphGrid *graphGrid = NULL;
    struct GraphAdjLinkedList *graphAdjLinkedList = NULL;
    struct GraphAdjArrayList *graphAdjArrayList = NULL;
    float *pageRanks = NULL;

    switch (datastructure)
    {
    case 0: // CSR
        graphCSR = (struct GraphCSR *)graph;
        pageRanks = pageRankGraphCSR(epsilon, iterations, pushpull, graphCSR);
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;

    case 1: // Grid
        graphGrid = (struct GraphGrid *)graph;
        pageRanks = pageRankGraphGrid(epsilon, iterations, pushpull, graphGrid);
        Start(timer);
        graphGridFree(graphGrid);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)", Seconds(timer));
        break;

    case 2: // Adj Linked List
        graphAdjLinkedList = (struct GraphAdjLinkedList *)graph;
        pageRanks = pageRankGraphAdjLinkedList(epsilon, iterations, pushpull, graphAdjLinkedList);
        Start(timer);
        graphAdjLinkedListFree(graphAdjLinkedList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)", Seconds(timer));
        break;

    case 3: // Adj Array List
        graphAdjArrayList = (struct GraphAdjArrayList *)graph;
        pageRanks = pageRankGraphAdjArrayList(epsilon, iterations, pushpull, graphAdjArrayList);
        Start(timer);
        graphAdjArrayListFree(graphAdjArrayList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)", Seconds(timer));
        break;

    default:// CSR
        graphCSR = (struct GraphCSR *)graph;
        pageRanks = pageRankGraphCSR(epsilon, iterations, pushpull, graphCSR);
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;
    }

    free(pageRanks);
    free(timer);

}

void runBellmanFordAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 trials, __u32 pushpull)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct GraphCSR *graphCSR = NULL;
    struct GraphGrid *graphGrid = NULL;
    struct GraphAdjLinkedList *graphAdjLinkedList = NULL;
    struct GraphAdjArrayList *graphAdjArrayList = NULL;


    switch (datastructure)
    {
    case 0: // CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            bellmanFordGraphCSR(root, iterations, pushpull, graphCSR);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                bellmanFordGraphCSR(root, iterations, pushpull, graphCSR);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));

        break;

    case 1: // Grid
        graphGrid = (struct GraphGrid *)graph;
        if(root < graphGrid->num_vertices)
        {
            bellmanFordGraphGrid(root, iterations, pushpull, graphGrid);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphGrid->num_vertices)
                {
                    if(graphGrid->grid->out_degree[root] > 0)
                        break;
                }
            }
            if(root < graphGrid->num_vertices)
            {
                bellmanFordGraphGrid(root, iterations, pushpull, graphGrid);
            }
            trials--;
        }
        Start(timer);
        graphGridFree(graphGrid);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)", Seconds(timer));
        break;

    case 2: // Adj Linked List
        graphAdjLinkedList = (struct GraphAdjLinkedList *)graph;
        if(root < graphAdjLinkedList->num_vertices)
        {
            bellmanFordGraphAdjLinkedList(root, iterations, pushpull, graphAdjLinkedList);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphAdjLinkedList->num_vertices)
                {
                    if(graphAdjLinkedList->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphAdjLinkedList->num_vertices)
            {
                bellmanFordGraphAdjLinkedList(root, iterations, pushpull, graphAdjLinkedList);
            }
            trials--;
        }
        Start(timer);
        graphAdjLinkedListFree(graphAdjLinkedList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)", Seconds(timer));
        break;

    case 3: // Adj Array List
        graphAdjArrayList = (struct GraphAdjArrayList *)graph;
        if(root < graphAdjArrayList->num_vertices)
        {
            bellmanFordGraphAdjArrayList(root, iterations, pushpull, graphAdjArrayList);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphAdjArrayList->num_vertices)
                {
                    if(graphAdjArrayList->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphAdjArrayList->num_vertices)
            {
                bellmanFordGraphAdjArrayList(root, iterations, pushpull, graphAdjArrayList);
            }
            trials--;
        }
        Start(timer);
        graphAdjArrayListFree(graphAdjArrayList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)", Seconds(timer));

        break;

    default:// CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            bellmanFordGraphCSR(root, iterations, pushpull, graphCSR);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                bellmanFordGraphCSR(root, iterations, pushpull, graphCSR);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;
    }

    free(timer);

}


void runSSSPAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 trials, __u32 pushpull, __u32 delta)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct GraphCSR *graphCSR = NULL;
    struct GraphGrid *graphGrid = NULL;
    struct GraphAdjLinkedList *graphAdjLinkedList = NULL;
    struct GraphAdjArrayList *graphAdjArrayList = NULL;


    switch (datastructure)
    {
    case 0: // CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            SSSPGraphCSR(root, iterations, pushpull, graphCSR, delta);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                SSSPGraphCSR(root, iterations, pushpull, graphCSR, delta);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));

        break;

    case 1: // Grid
        graphGrid = (struct GraphGrid *)graph;
        if(root < graphGrid->num_vertices)
        {
            // bellmanFordGraphGrid(root , iterations, pushpull, graphGrid);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphGrid->num_vertices)
                {
                    if(graphGrid->grid->out_degree[root] > 0)
                        break;
                }
            }
            if(root < graphGrid->num_vertices)
            {
                // bellmanFordGraphGrid(root , iterations, pushpull, graphGrid);
            }
            trials--;
        }
        Start(timer);
        graphGridFree(graphGrid);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)", Seconds(timer));
        break;

    case 2: // Adj Linked List
        graphAdjLinkedList = (struct GraphAdjLinkedList *)graph;
        if(root < graphAdjLinkedList->num_vertices)
        {
            // bellmanFordGraphAdjLinkedList(root , iterations, pushpull, graphAdjLinkedList);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphAdjLinkedList->num_vertices)
                {
                    if(graphAdjLinkedList->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphAdjLinkedList->num_vertices)
            {
                // bellmanFordGraphAdjLinkedList(root , iterations, pushpull, graphAdjLinkedList);
            }
            trials--;
        }
        Start(timer);
        graphAdjLinkedListFree(graphAdjLinkedList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)", Seconds(timer));
        break;

    case 3: // Adj Array List
        graphAdjArrayList = (struct GraphAdjArrayList *)graph;
        if(root < graphAdjArrayList->num_vertices)
        {
            // bellmanFordGraphAdjArrayList(root , iterations, pushpull, graphAdjArrayList);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphAdjArrayList->num_vertices)
                {
                    if(graphAdjArrayList->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphAdjArrayList->num_vertices)
            {
                // bellmanFordGraphAdjArrayList(root , iterations, pushpull, graphAdjArrayList);
            }
            trials--;
        }
        Start(timer);
        graphAdjArrayListFree(graphAdjArrayList);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)", Seconds(timer));

        break;

    default:// CSR
        graphCSR = (struct GraphCSR *)graph;
        if(root < graphCSR->num_vertices)
        {
            SSSPGraphCSR(root, iterations, pushpull, graphCSR, delta);
        }
        while(trials)
        {
            while(1)
            {
                root = generateRandInt(mt19937var);
                if(root < graphCSR->num_vertices)
                {
                    if(graphCSR->vertices[root].out_degree > 0)
                        break;
                }
            }
            if(root < graphCSR->num_vertices)
            {
                SSSPGraphCSR(root, iterations, pushpull, graphCSR, delta);
            }
            trials--;
        }
        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
        break;
    }

    free(timer);

}