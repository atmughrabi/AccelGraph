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
    // const char * fname = "host/app/datasets/wiki-vote/wiki-Vote.txt";
    const char * fname = "host/app/datasets/twitter/twitter_rv.net";
    // const char * fname = "host/app/datasets/facebook/facebook_combined.txt";
    struct EdgeListAttributes* graphAttr = (struct EdgeListAttributes*)malloc(sizeof(struct EdgeListAttributes));
    graphAttr->WEIGHTED = 0;
    graphAttr->DIRECTED = 0;

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    Start(timer);
    struct EdgeList* edgeList = readEdgeListstxt(fname, graphAttr);
    Stop(timer);
    printf("Read Edge List From File : %f Seconds \n",Seconds(timer));

    
    
    // Start(timer);
    // struct Graph* graph = adjListCreateGraphEdgeList(edgeList);
    // Stop(timer);
    // printf("adjacency Linked List Edges By Source : %f Seconds \n",Seconds(timer));

    // Start(timer);
    // struct GraphCountSorted* graph1 = countSortEdgesBySource(edgeList);
    // Stop(timer);
    // printf("Count Sort Edges By Source : %f Seconds \n",Seconds(timer));

    // Start(timer);
    // struct GraphRadixSorted* graph2 = radixSortEdgesBySource(edgeList);
    // Stop(timer);
    // printf("Radix Sort Edges By Source : %f Seconds \n",Seconds(timer));

    // edgeListPrint(edgeList);
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