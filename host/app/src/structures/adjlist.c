#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "adjlist.h"
#include "capienv.h"

// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(int src, int dest, int weight){

	struct AdjListNode* newNode = (struct AdjListNode*) aligned_alloc(CACHELINE_BYTES, sizeof(struct AdjListNode));
	newNode->dest = dest;
    newNode->src = src;
    newNode->weight = weight;
	newNode->next = NULL;

	return newNode;

}
// A utility function that creates a graph of V vertices
struct Graph* adjListCreateGraph(int V){

    // printf("\n Create Graph #Vertecies: %d\n ", V);

	struct Graph* graph = (struct Graph*) aligned_alloc(CACHELINE_BYTES, sizeof(struct Graph));

	graph->V = V;
	graph->parent_array = (struct AdjList*) aligned_alloc(CACHELINE_BYTES, V * sizeof(struct AdjList));

	int i;
	for(i = 0; i < V; i++){

		graph->parent_array[i].head = NULL;
        graph->parent_array[i].out_degree = 0;  
        graph->parent_array[i].in_degree = 0;
        graph->parent_array[i].visited = 0;
	}

    // printf("\n Success!!! V: %d\n ", V);

    return graph;

}
// Adds an edge to an undirected graph
void adjListAddEdgeUndirected(struct Graph* graph, int src, int dest, int weight){

	// Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjListNode* newNode = newAdjListNode(src,dest,weight);
    newNode->next = graph->parent_array[src].head;
    graph->parent_array[src].out_degree++;
    graph->parent_array[src].in_degree++;
    graph->parent_array[src].visited = 0;
    graph->parent_array[src].head = newNode;


    // Since graph is undirected, add an edge from
    // dest to src also
    newNode = newAdjListNode(dest,src,weight);
    newNode->next = graph->parent_array[dest].head;
    graph->parent_array[dest].out_degree++;  
    graph->parent_array[dest].in_degree++;  
    graph->parent_array[dest].visited = 0;
    graph->parent_array[dest].head = newNode;

}
// Adds an edge to a directed graph
void adjListAddEdgeDirected(struct Graph* graph, int src, int dest, int weight){

    // Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjListNode* newNode = newAdjListNode(src,dest,weight);
    newNode->next = graph->parent_array[src].head;
    graph->parent_array[src].out_degree++;  
    graph->parent_array[src].visited = 0;
    graph->parent_array[dest].in_degree++;     
    graph->parent_array[src].head = newNode;


}
// A utility function to print the adjacency list 
// representation of graph
void adjListPrintGraph(struct Graph* graph){

	int v;
    for (v = 0; v < graph->V; ++v)
    {
        struct AdjListNode* pCrawl = graph->parent_array[v].head;
        printf("\n Adjacency list of vertex %d\n head %d neighbours ", v, graph->parent_array[v].out_degree);
        while (pCrawl)
        {
            printf("-> %d", pCrawl->dest);
            pCrawl = pCrawl->next;
        }
        printf("\n");
    }


}