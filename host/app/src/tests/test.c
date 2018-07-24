#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "libcxl.h"

#include "capienv.h"
#include "adjlist.h" 
#include "queue.h"
#include "edgelist.h"
#include "countsort.h"

int main()
{
    // create the graph given in above fugure
    // int V = 5;
    // const char * fname = "host/app/datasets/wiki-vote/wiki-Vote.txt";
    const char * fname = "host/app/datasets/facebook/facebook_combined.txt";

     // struct Queue *q = createQueue();
    // struct Graph* graph = adjListCreateGraph(V);
    struct EdgeList* edgeList = readEdgeListstxt(fname);
    struct GraphCountSorted* graph = countSortEdgesBySource(edgeList);

    // edgeListPrint(edgeList);
    // CountSortedGraphPrint(graph);
    
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