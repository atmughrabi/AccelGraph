#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "adjlist.h"
#include "capienv.h"

// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(int dest){

	struct AdjListNode* newNode = (struct AdjListNode*) aligned_alloc(CACHELINE_BYTES, sizeof(struct AdjListNode));
	newNode->dest = dest;
	newNode->next = NULL;

	return newNode;

}
// A utility function that creates a graph of V vertices
struct Graph* adjlist_createGraph(int V){

    printf("\n Create Graph #Vertecies: %d\n ", V);

	struct Graph* graph = (struct Graph*) aligned_alloc(CACHELINE_BYTES, sizeof(struct Graph));

	graph->V = V;
	graph->array = (struct AdjList*) aligned_alloc(CACHELINE_BYTES, V * sizeof(struct AdjList));

	int i;
	for(i = 0; i < V; i++){
		graph->array[i].head = NULL;
        graph->array[i].neighbours = 0;
	}

    printf("\n Success!!! V: %d\n ", V);

    return graph;

}
// Adds an edge to an undirected graph
void adjlist_addEdge_undirected(struct Graph* graph, int src, int dest){

	// Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjListNode* newNode = newAdjListNode(dest);
    newNode->next = graph->array[src].head;
    graph->array[src].neighbours++;     
    graph->array[src].head = newNode;


    // Since graph is undirected, add an edge from
    // dest to src also
    newNode = newAdjListNode(src);
    newNode->next = graph->array[dest].head;
    graph->array[dest].neighbours++;  
    graph->array[dest].head = newNode;

}
// Adds an edge to a directed graph
void adjlist_addEdge_directed(struct Graph* graph, int src, int dest){

    // Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjListNode* newNode = newAdjListNode(dest);
    newNode->next = graph->array[src].head;
    graph->array[src].neighbours++;     
    graph->array[src].head = newNode;


}
// A utility function to print the adjacency list 
// representation of graph
void adjlist_printGraph(struct Graph* graph){

	int v;
    for (v = 0; v < graph->V; ++v)
    {
        struct AdjListNode* pCrawl = graph->array[v].head;
        printf("\n Adjacency list of vertex %d\n head %d neighbours ", v, graph->array[v].neighbours);
        while (pCrawl)
        {
            printf("-> %d", pCrawl->dest);
            pCrawl = pCrawl->next;
        }
        printf("\n");
    }


}