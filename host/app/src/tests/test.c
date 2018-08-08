#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "libcxl.h"

#include "capienv.h"
#include "adjlist.h" 
#include "dynamicqueue.h"
#include "edgelist.h"

#include "countsort.h"
#include "radixsort.h"
#include "graph.h"
#include "vertex.h"
#include "timer.h"
#include "BFS.h"

int main()
{
    // create the graph given in above fugure
    // int V = 5;

    // const char * fname = "host/app/datasets/test/test.txt";
    // const char * fname = "host/app/datasets/wiki-vote/wiki-Vote.txt";
    // const char * fname = "host/app/datasets/twitter/twitter_rv.txt";
    // const char * fname = "host/app/datasets/facebook/facebook_combined.txt";


    // const char * fnameb = "host/app/datasets/test/test.txt.bin";
    // const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin";
    const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin8";
    // const char * fnameb = "host/app/datasets/facebook/facebook_combined.txt.bin";
    // const char * fnameb = "host/app/datasets/wiki-vote/wiki-Vote.txt.bin";


    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));


    // Start(timer);
    // readEdgeListstxt(fname);
    // Stop(timer);
    // printf("Read Edge List From File converted to binary : %f Seconds \n",Seconds(timer));

    Start(timer);
    struct EdgeList* edgeList = readEdgeListsbin(fnameb,0);
    Stop(timer);
    // edgeListPrint(edgeList);
    printf("Read Edge List From File : %f Seconds \n",Seconds(timer));
    
    #if DIRECTED
        Start(timer);
        struct EdgeList* inverse_edgeList = readEdgeListsbin(fnameb,1);
        Stop(timer);
        // edgeListPrint(inverse_edgeList);
        printf("Read Inverse Edge List List From File : %f Seconds \n",Seconds(timer));
    #endif

    struct Graph* graph_radixSort = graphNew(edgeList->num_vertices, edgeList->num_edges, 1);
    

    // Start(timer);
    // struct GraphAdjList* graph_adjList = adjListCreateGraphEdgeList(edgeList);
    // Stop(timer);
    // printf("adjacency Linked List Edges By Source : %f Seconds \n",Seconds(timer));

    // adjListFreeGraph(graph_adjList);

    // Start(timer);
    // struct Graph* graph_countSort = countSortEdgesBySource(edgeList);
    // Stop(timer);
    // printf("Count Sort Edges By Source : %f Seconds \n",Seconds(timer));

    // countSortedFreeGraph(graph_countSort);

    Start(timer);
    graph_radixSort = radixSortEdgesBySourceOptimized(graph_radixSort, edgeList, 0);
    Stop(timer);
    printf("Radix Sort Edges By Source : %f Seconds \n",Seconds(timer));


    #if DIRECTED
        Start(timer);
        graph_radixSort = radixSortEdgesBySourceOptimized(graph_radixSort, inverse_edgeList, 1);
        Stop(timer);
        printf("Radix Sort Inverse Edges By Source : %f Seconds \n",Seconds(timer));
    #endif


    Start(timer);
    graph_radixSort = mapVerticesWithInOutDegree (graph_radixSort,0);
    Stop(timer);
    printf("Process In/Out degrees of Nodes : %f Seconds \n",Seconds(timer));


    #if DIRECTED
        Start(timer);
        graph_radixSort = mapVerticesWithInOutDegree (graph_radixSort,1);
        Stop(timer);
        printf("Process In/Out degrees of Inverse Nodes : %f Seconds \n",Seconds(timer));
    #endif

    graphPrint(graph_radixSort);
    // Start(timer);
    // struct Graph* graph_radixSort = radixSortEdgesBySourceAndDestination(edgeList);
    // Stop(timer);
    // printf("Radix Sort Edges By Source : %f Seconds \n",Seconds(timer));


    // Start(timer);
    // bfs(428333, graph_radixSort);
    // Stop(timer);
    // printf("BFS with array queue : %f Seconds \n",Seconds(timer));

    Start(timer);
    breadthFirstSearch(428333, graph_radixSort);
    // breadthFirstSearch(6, graph_radixSort);
    Stop(timer);
    printf("breadthFirstSearch with array queue : %f Seconds \n",Seconds(timer));

    // printGraphParentsArray(graph_radixSort);

    graphFree(graph_radixSort);
    // freeEdgeList(edgeList);

    // edgeListPrint(edgeList);
    // countSortedGraphPrint(graph_countSort);
    // radixSortedGraphPrint(graph2);
    
    // int weight = 1;

    // adjListAddEdgeDirected(graph, 0, 1,weight);
    // adjListAddEdgeDirected(graph, 0, 4,weight);
    // adjListAddEdgeDirected(graph, 1, 2,weight);
    // adjListAddEdgeDirected(graph, 1, 3,weight);
    // adjListAddEdgeDirected(graph, 1, 4,weight);
    // adjListAddEdgeDirected(graph, 2, 3,weight);
    // adjListAddEdgeDirected(graph, 3, 4,weight);


    // Driver Program to test queue functions
   
    
    // enQueue(q, 10);
    // enQueue(q, 20);
    // deQueue(q);
    // deQueue(q);
    // enQueue(q, 30);
    // enQueue(q, 40);
    // enQueue(q, 50);
    // struct QNode *n = deQueue(q);
    // if (n != NULL)
    //   printf("Dequeued item is %d", n->key);
   

 
    // print the adjacency list representation of the above graph
    // adjListPrintGraph(graph);
 
    return 0;
}