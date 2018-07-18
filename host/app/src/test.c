#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "libcxl.h"

#include "capienv.h"
#include "adjlist.h" 


int main()
{
    // create the graph given in above fugure
    int V = 5;
    struct Graph* graph = adjlist_createGraph(V);

    
    adjlist_addEdge_undirected(graph, 0, 1);
    adjlist_addEdge_undirected(graph, 0, 4);
    adjlist_addEdge_undirected(graph, 1, 2);
    adjlist_addEdge_undirected(graph, 1, 3);
    adjlist_addEdge_undirected(graph, 1, 4);
    adjlist_addEdge_undirected(graph, 2, 3);
    adjlist_addEdge_undirected(graph, 3, 4);
 
    // print the adjacency list representation of the above graph
    adjlist_printGraph(graph);
 
    return 0;
}