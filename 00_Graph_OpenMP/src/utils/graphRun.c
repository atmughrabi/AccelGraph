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

void writeSerializedGraphDataStructure(struct arguments *arguments)  // for now this only support graph CSR
{

    // check input type edgelist text/bin or graph csr
    // read input file create CSR graph then write to binaryfile
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));

    if(arguments->fnameb_format == 0 && arguments->convert_format == 1)  // for now it edge list is text only convert to binary
    {
        Start(timer);
        arguments->fnameb = readEdgeListstxt(arguments->fnameb, arguments->weighted);
        arguments->fnameb_format = 1; // now you have a bin file
        arguments->weighted = 0; // no need to generate weights again this affects readedgelistbin
        Stop(timer);
        generateGraphPrintMessageWithtime("Serialize EdgeList text to binary (Seconds)", Seconds(timer));
    }
    else if(arguments->fnameb_format == 0 && arguments->convert_format == 2)  // for now it edge list is text only convert to binary
    {
        void *graph = NULL;
        struct GraphCSR *graphCSR = NULL;

        Start(timer);
        arguments->fnameb = readEdgeListstxt(arguments->fnameb, arguments->weighted);
        arguments->fnameb_format = 1; // now you have a bin file
        arguments->weighted = 0; // no need to generate weights again this affects readedgelistbin
        Stop(timer);
        generateGraphPrintMessageWithtime("Serialize EdgeList text to binary (Seconds)", Seconds(timer));

        Start(timer);
        graph = (void *)graphCSRPreProcessingStep ( arguments->fnameb,  arguments->sort,  arguments->lmode,  arguments->symmetric,  arguments->weighted);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));

        graphCSR = (struct GraphCSR *)graph;
        Start(timer);
        writeToBinFileGraphCSR (arguments->fnameb, graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));

        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
    }
    else if(arguments->fnameb_format == 1 && arguments->convert_format == 2)   // for now it edge list is text only convert to binary
    {
        void *graph = NULL;
        struct GraphCSR *graphCSR = NULL;


        Start(timer);
        graph = (void *)graphCSRPreProcessingStep ( arguments->fnameb,  arguments->sort,  arguments->lmode,  arguments->symmetric,  arguments->weighted);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));


        graphCSR = (struct GraphCSR *)graph;
        Start(timer);
        writeToBinFileGraphCSR (arguments->fnameb, graph);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));

        Start(timer);
        graphCSRFree(graphCSR);
        Stop(timer);
        generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)", Seconds(timer));
    }
    else if(arguments->fnameb_format == arguments->convert_format)    // for now it edge list is text only convert to binary
    {

        Start(timer);
        Stop(timer);
        generateGraphPrintMessageWithtime("INPUT and OUTPUT Same format no need to serialize", Seconds(timer));
    }


    free(timer);

}

void readSerializeGraphDataStructure(struct arguments *arguments)  // for now this only support graph CSR
{

    // check input type edgelist text/bin or graph csr
    // read input file create to the correct structure without preprocessing

}


void *generateGraphDataStructure(struct arguments *arguments)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    void *graph = NULL;

    if(arguments->fnameb_format == 0)  // for now it edge list is text only convert to binary
    {
        Start(timer);
        arguments->fnameb = readEdgeListstxt(arguments->fnameb, arguments->weighted);
        arguments->fnameb_format = 1; // now you have a bin file
        arguments->weighted = 0; // no need to generate weights again this affects readedgelistbin
        Stop(timer);
        generateGraphPrintMessageWithtime("Serialize EdgeList text to binary (Seconds)", Seconds(timer));
    }

    if(arguments->fnameb_format == 1 ) // if it is a graphCSR binary file
    {

        switch (arguments->datastructure)
        {
        case 0: // CSR
        case 4:
            Start(timer);
            graph = (void *)graphCSRPreProcessingStep ( arguments->fnameb,  arguments->sort,  arguments->lmode,  arguments->symmetric,  arguments->weighted);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));
            break;
        case 1: // Grid
        case 5:
            Start(timer);
            graph = (void *)graphGridPreProcessingStep ( arguments->fnameb,  arguments->sort,  arguments->lmode,  arguments->symmetric,  arguments->weighted);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphGrid Preprocessing Step Time (Seconds)", Seconds(timer));
            break;
        case 2: // Adj Linked List
            Start(timer);
            graph = (void *)graphAdjLinkedListPreProcessingStep ( arguments->fnameb,  arguments->lmode,  arguments->symmetric,  arguments->weighted);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphAdjLinkedList Preprocessing Step Time (Seconds)", Seconds(timer));
            break;
        case 3: // Adj Array List
            Start(timer);
            graph = (void *)graphAdjArrayListPreProcessingStep ( arguments->fnameb,  arguments->sort,  arguments->lmode,  arguments->symmetric,  arguments->weighted);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphAdjArrayList Preprocessing Step Time (Seconds)", Seconds(timer));
            break;
        default:// CSR
            Start(timer);
            graph = (void *)graphCSRPreProcessingStep ( arguments->fnameb,  arguments->sort,  arguments->lmode,  arguments->symmetric,  arguments->weighted);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));

            break;
        }
    }
    else if(arguments->fnameb_format == 2)
    {
        Start(timer);
        graph = (void *)readFromBinFileGraphCSR (arguments->fnameb);
        Stop(timer);
        generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)", Seconds(timer));
    }
    else
    {
        Start(timer);
        Stop(timer);
        generateGraphPrintMessageWithtime("UNKOWN Graph format Preprocessing Step Time (Seconds)", Seconds(timer));
    }

    free(timer);
    return graph;

}


void runGraphAlgorithms(void *graph, struct arguments *arguments)
{

    switch ( arguments->algorithm)
    {
    case 0: // bfs filename root
        runBreadthFirstSearchAlgorithm( graph,  arguments->datastructure,  arguments->root,  arguments->trials);
        break;
    case 1: // pagerank filename
        runPageRankAlgorithm(graph,  arguments->datastructure,  arguments->epsilon,  arguments->iterations,  arguments->trials,  arguments->pushpull);
        break;
    case 2: // SSSP-Dijkstra file name root
        runSSSPAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->iterations,  arguments->trials,  arguments->pushpull,  arguments->delta);
        break;
    case 3: // SSSP-Bellmanford file name root
        runBellmanFordAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->iterations,  arguments->trials,  arguments->pushpull);
        break;
    case 4: // DFS file name root
        runDepthFirstSearchAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->trials);
        break;
    case 5: // incremental Aggregation file name root
        runIncrementalAggregationAlgorithm(graph,  arguments->datastructure,  arguments->trials);
        break;
    default:// bfs file name root
        runBreadthFirstSearchAlgorithm(graph,  arguments->datastructure,  arguments->root,  arguments->trials);
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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
                    if(graphCSR->vertices->out_degree[root] > 0)
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