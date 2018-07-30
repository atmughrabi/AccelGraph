#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "adjlist.h"
#include "capienv.h"
#include "mymalloc.h"

// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(__u32 src, __u32 dest, __u32 weight){

	// struct AdjListNode* newNode = (struct AdjListNode*) aligned_alloc(CACHELINE_BYTES, sizeof(struct AdjListNode));
    #ifdef ALIGNED
        struct AdjListNode* newNode = (struct AdjListNode*) my_aligned_alloc(sizeof(struct AdjListNode));
    #else
        struct AdjListNode* newNode = (struct AdjListNode*) my_malloc(sizeof(struct AdjListNode));
    #endif

	newNode->dest = dest;
    newNode->src = src;
    newNode->weight = weight;
	newNode->next = NULL;

	return newNode;

}
// A utility function that creates a graph of V vertices
struct Graph* adjListCreateGraph(__u32 V){

    // printf("\n Create Graph #Vertecies: %d\n ", V);

	// struct Graph* graph = (struct Graph*) aligned_alloc(CACHELINE_BYTES, sizeof(struct Graph));
    #ifdef ALIGNED
        struct Graph* graph = (struct Graph*) my_aligned_alloc( sizeof(struct Graph));
    #else
        struct Graph* graph = (struct Graph*) my_malloc( sizeof(struct Graph));
    #endif

	graph->V = V;
	// graph->parent_array = (struct AdjList*) aligned_alloc(CACHELINE_BYTES, V * sizeof(struct AdjList));
    #ifdef ALIGNED
        graph->parent_array = (struct AdjList*) my_aligned_alloc( V * sizeof(struct AdjList));
    #else
        graph->parent_array = (struct AdjList*) my_malloc( V * sizeof(struct AdjList));
    #endif

	__u32 i;
	for(i = 0; i < V; i++){

		graph->parent_array[i].head = NULL;
        graph->parent_array[i].out_degree = 0;  
        graph->parent_array[i].in_degree = 0;
        graph->parent_array[i].visited = 0;
	}

    // printf("\n Success!!! V: %d\n ", V);

    return graph;

}

struct Graph* adjListCreateGraphEdgeList(struct EdgeList* edgeList){

    // struct Graph* graph = (struct Graph*) aligned_alloc(CACHELINE_BYTES, sizeof(struct Graph));
    #ifdef ALIGNED
        struct Graph* graph = (struct Graph*) my_aligned_alloc( sizeof(struct Graph));
    #else
        struct Graph* graph = (struct Graph*) my_malloc( sizeof(struct Graph));
    #endif

    graph->V = edgeList->num_vertices;
    graph->num_edges = edgeList->num_edges;
    // graph->parent_array = (struct AdjList*) aligned_alloc(CACHELINE_BYTES, graph->V * sizeof(struct AdjList));

    #ifdef ALIGNED
        graph->parent_array = (struct AdjList*) my_aligned_alloc( graph->V * sizeof(struct AdjList));
    #else
        graph->parent_array = (struct AdjList*) my_malloc( graph->V * sizeof(struct AdjList));
    #endif

    __u32 i;
    for(i = 0; i < graph->V; i++){

        graph->parent_array[i].head = NULL;
        graph->parent_array[i].out_degree = 0;  
        graph->parent_array[i].in_degree = 0;
        graph->parent_array[i].visited = 0;
    }
   
    for(i = 0; i < edgeList->num_edges; i++){
            adjListAddEdgeUndirected(graph, edgeList->edges_array[i].src, edgeList->edges_array[i].dest, edgeList->edges_array[i].weight);
        }



    return graph;

}



// Adds an edge to an undirected graph
void adjListAddEdgeUndirected(struct Graph* graph, __u32 src, __u32 dest, __u32 weight){

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
void adjListAddEdgeDirected(struct Graph* graph, __u32 src, __u32 dest, __u32 weight){

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

	__u32 v;
    for (v = 0; v < graph->V; ++v)
    {
        struct AdjListNode* pCrawl = graph->parent_array[v].head;
        printf("\n Adjacency list of vertex %d\n  out_degree: %d  in_degree: %d \n", v, graph->parent_array[v].out_degree, graph->parent_array[v].in_degree);
        while (pCrawl)
        {
            printf("-> %d", pCrawl->dest);
            pCrawl = pCrawl->next;
        }
        printf("\n");
    }


}

void adjListFreeGraph(struct Graph* graph){

    __u32 v;
    for (v = 0; v < graph->V; ++v)
    {
        struct AdjListNode* pCrawl = graph->parent_array[v].head;
        struct AdjListNode* pFree  = graph->parent_array[v].head;
        while (pCrawl)
        {

            pFree = pCrawl;
            pCrawl = pCrawl->next;
            free(pFree);

        }
       
    }

    free(graph->parent_array);
    free(graph);


}