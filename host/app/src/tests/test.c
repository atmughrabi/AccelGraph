#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "libcxl.h"

#include "capienv.h"
#include "adjlist.h" 
#include "queue.h"
#include "edgelist.h"

#include "countsort.h"
#include "radixsort.h"

#include "timer.h"

int main()
{
    // create the graph given in above fugure
    // int V = 5;

    // const char * fname = "host/app/datasets/test/test.txt";
    // const char * fname = "host/app/datasets/wiki-vote/wiki-Vote.txt";
    // const char * fname = "host/app/datasets/twitter/twitter_rv.txt";
    // const char * fname = "host/app/datasets/facebook/facebook_combined.txt";


    // const char * fnameb = "host/app/datasets/test/test.txt.bin";
    const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin";
    // const char * fnameb = "host/app/datasets/facebook/facebook_combined.txt.bin";
    // const char * fnameb = "host/app/datasets/wiki-vote/wiki-Vote.txt.bin";


    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    // Start(timer);
    // struct EdgeList* edgeList = readEdgeListstxt(fname);
    // Stop(timer);
    // printf("Read Edge List From File : %f Seconds \n",Seconds(timer));

    Start(timer);
    struct EdgeList* edgeList = readEdgeListsbin(fnameb);
    Stop(timer);
    printf("Read Edge List From File : %f Seconds \n",Seconds(timer));
    
    // Start(timer);
    // struct Graph* graph_adjList = adjListCreateGraphEdgeList(edgeList);
    // Stop(timer);
    // printf("adjacency Linked List Edges By Source : %f Seconds \n",Seconds(timer));

    // adjListFreeGraph(graph_adjList);

    // Start(timer);
    // struct GraphCountSorted* graph_countSort = countSortEdgesBySource(edgeList);
    // Stop(timer);
    // printf("Count Sort Edges By Source : %f Seconds \n",Seconds(timer));

    // countSortedFreeGraph(graph_countSort);

    Start(timer);
    struct GraphRadixSorted* graph_radixSort = radixSortEdgesBySourceOptimized(edgeList);
    Stop(timer);
    printf("Radix Sort Edges By Source : %f Seconds \n",Seconds(timer));

    // Start(timer);
    // struct GraphRadixSorted* graph_radixSort = radixSortEdgesBySourceAndDestination(edgeList);
    // Stop(timer);
    // printf("Radix Sort Edges By Source : %f Seconds \n",Seconds(timer));

    radixSortedFreeGraph(graph_radixSort);
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