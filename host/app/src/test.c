#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "libcxl.h"

#include "capienv.h"
#include "adjlist.h" 
#include "queue.h"
#include "edgelist.h"

int main()
{
    // create the graph given in above fugure
    int V = 5;
    struct Graph* graph = adjlist_createGraph(V);
    int weight = 1;

    adjlist_addEdge_undirected(graph, 0, 1,weight);
    adjlist_addEdge_undirected(graph, 0, 4,weight);
    adjlist_addEdge_undirected(graph, 1, 2,weight);
    adjlist_addEdge_undirected(graph, 1, 3,weight);
    adjlist_addEdge_undirected(graph, 1, 4,weight);
    adjlist_addEdge_undirected(graph, 2, 3,weight);
    adjlist_addEdge_undirected(graph, 3, 4,weight);


    // Driver Program to test anove functions
    struct Queue *q = createQueue();
    
    enQueue(q, 10);
    enQueue(q, 20);
    deQueue(q);
    deQueue(q);
    enQueue(q, 30);
    enQueue(q, 40);
    enQueue(q, 50);
    struct QNode *n = deQueue(q);
    if (n != NULL)
      printf("Dequeued item is %d", n->key);
   

 
    // print the adjacency list representation of the above graph
    adjlist_printGraph(graph);
 
    return 0;
}