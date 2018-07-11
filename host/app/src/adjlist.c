#include <stdio.h>
#include <stdlib.h>

#include "adjlist.h"

// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(int dest){

struct AdjListNode* newNode = (struct AdjListNode*) aligned_alloc(alignment, sizeof(struct AdjListNode));
newNode->dest = dest;
newNode->next = NULL;

return newNode;

}
// A utility function that creates a graph of V vertices
struct Graph* createGraph(int V){

struct Graph* graph = (struct Graph*) aligned_alloc(alignment, sizeof(struct Graph));

graph->V = V;
graph->array = (struct AdjList*) aligned_alloc(alignment, V * sizeof(struct AdjList));

int i;
for(i = 0; i < V; i++){
	graph->array[i].head = NULL;
}


}
// Adds an edge to an undirected graph
void addEdge(struct Graph* graph, int src, int dest){

	// Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjListNode* newNode = newAdjListNode(dest);
    newNode->next = graph->array[src].head;
    graph->array[src].head = newNode;
 
    // Since graph is undirected, add an edge from
    // dest to src also
    newNode = newAdjListNode(src);
    newNode->next = graph->array[dest].head;
    graph->array[dest].head = newNode;

}
// A utility function to print the adjacency list 
// representation of graph
void printGraph(struct Graph* graph){

	int v;
    for (v = 0; v < graph->V; ++v)
    {
        struct AdjListNode* pCrawl = graph->array[v].head;
        printf("\n Adjacency list of vertex %d\n head ", v);
        while (pCrawl)
        {
            printf("-> %d", pCrawl->dest);
            pCrawl = pCrawl->next;
        }
        printf("\n");
    }


}