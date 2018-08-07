#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "adjlist.h"
#include "capienv.h"
#include "mymalloc.h"

// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(__u32 src, __u32 dest, __u32 weight){

	// struct AdjListNode* newNode = (struct AdjListNode*) aligned_alloc(CACHELINE_BYTES, sizeof(struct AdjListNode));
    #if ALIGNED
        struct AdjListNode* newNode = (struct AdjListNode*) my_aligned_alloc(sizeof(struct AdjListNode));
    #else
        struct AdjListNode* newNode = (struct AdjListNode*) my_malloc(sizeof(struct AdjListNode));
    #endif

	newNode->dest = dest;
    newNode->src = src;
    #ifdef WEIGHTED
     newNode->weight = weight;
    #endif
     
	newNode->next = NULL;

	return newNode;

}
// A utility function that creates a GraphAdjList of V vertices
struct GraphAdjList* adjListCreateGraphAdjList(__u32 V){

    // printf("\n Create GraphAdjList #Vertecies: %d\n ", V);

	// struct GraphAdjList* GraphAdjList = (struct GraphAdjList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphAdjList));
    #if ALIGNED
        struct GraphAdjList* GraphAdjList = (struct GraphAdjList*) my_aligned_alloc( sizeof(struct GraphAdjList));
    #else
        struct GraphAdjList* GraphAdjList = (struct GraphAdjList*) my_malloc( sizeof(struct GraphAdjList));
    #endif

	GraphAdjList->V = V;
	// GraphAdjList->parent_array = (struct AdjList*) aligned_alloc(CACHELINE_BYTES, V * sizeof(struct AdjList));
    #if ALIGNED
        GraphAdjList->parent_array = (struct AdjList*) my_aligned_alloc( V * sizeof(struct AdjList));
    #else
        GraphAdjList->parent_array = (struct AdjList*) my_malloc( V * sizeof(struct AdjList));
    #endif

	__u32 i;
	for(i = 0; i < V; i++){

		GraphAdjList->parent_array[i].head = NULL;
        GraphAdjList->parent_array[i].out_degree = 0;  
        GraphAdjList->parent_array[i].in_degree = 0;
        GraphAdjList->parent_array[i].visited = 0;
	}

    // printf("\n Success!!! V: %d\n ", V);

    return GraphAdjList;

}

struct GraphAdjList* adjListCreateGraphAdjListEdgeList(struct EdgeList* edgeList){

    // struct GraphAdjList* GraphAdjList = (struct GraphAdjList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphAdjList));
    #if ALIGNED
        struct GraphAdjList* GraphAdjList = (struct GraphAdjList*) my_aligned_alloc( sizeof(struct GraphAdjList));
    #else
        struct GraphAdjList* GraphAdjList = (struct GraphAdjList*) my_malloc( sizeof(struct GraphAdjList));
    #endif

    GraphAdjList->V = edgeList->num_vertices;
    GraphAdjList->num_edges = edgeList->num_edges;
    // GraphAdjList->parent_array = (struct AdjList*) aligned_alloc(CACHELINE_BYTES, GraphAdjList->V * sizeof(struct AdjList));

    #if ALIGNED
        GraphAdjList->parent_array = (struct AdjList*) my_aligned_alloc( GraphAdjList->V * sizeof(struct AdjList));
    #else
        GraphAdjList->parent_array = (struct AdjList*) my_malloc( GraphAdjList->V * sizeof(struct AdjList));
    #endif

    __u32 i;
    for(i = 0; i < GraphAdjList->V; i++){

        GraphAdjList->parent_array[i].head = NULL;
        GraphAdjList->parent_array[i].out_degree = 0;  
        GraphAdjList->parent_array[i].in_degree = 0;
        GraphAdjList->parent_array[i].visited = 0;
    }
   
    for(i = 0; i < edgeList->num_edges; i++){
            adjListAddEdgeUndirected(GraphAdjList, edgeList->edges_array[i].src, edgeList->edges_array[i].dest, edgeList->edges_array[i].weight);
        }



    return GraphAdjList;

}



// Adds an edge to an undirected GraphAdjList
void adjListAddEdgeUndirected(struct GraphAdjList* GraphAdjList, __u32 src, __u32 dest, __u32 weight){

	// Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjListNode* newNode = newAdjListNode(src,dest,weight);
    newNode->next = GraphAdjList->parent_array[src].head;
    GraphAdjList->parent_array[src].out_degree++;
    GraphAdjList->parent_array[src].in_degree++;
    GraphAdjList->parent_array[src].visited = 0;
    GraphAdjList->parent_array[src].head = newNode;


    // Since GraphAdjList is undirected, add an edge from
    // dest to src also
    newNode = newAdjListNode(dest,src,weight);
    newNode->next = GraphAdjList->parent_array[dest].head;
    GraphAdjList->parent_array[dest].out_degree++;  
    GraphAdjList->parent_array[dest].in_degree++;  
    GraphAdjList->parent_array[dest].visited = 0;
    GraphAdjList->parent_array[dest].head = newNode;

}
// Adds an edge to a directed GraphAdjList
void adjListAddEdgeDirected(struct GraphAdjList* GraphAdjList, __u32 src, __u32 dest, __u32 weight){

    // Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjListNode* newNode = newAdjListNode(src,dest,weight);
    newNode->next = GraphAdjList->parent_array[src].head;
    GraphAdjList->parent_array[src].out_degree++;  
    GraphAdjList->parent_array[src].visited = 0;
    GraphAdjList->parent_array[dest].in_degree++;     
    GraphAdjList->parent_array[src].head = newNode;


}
// A utility function to print the adjacency list 
// representation of GraphAdjList
void adjListPrintGraphAdjList(struct GraphAdjList* GraphAdjList){

	__u32 v;
    for (v = 0; v < GraphAdjList->V; ++v)
    {
        struct AdjListNode* pCrawl = GraphAdjList->parent_array[v].head;
        printf("\n Adjacency list of vertex %d\n  out_degree: %d  in_degree: %d \n", v, GraphAdjList->parent_array[v].out_degree, GraphAdjList->parent_array[v].in_degree);
        while (pCrawl)
        {
            printf("-> %d", pCrawl->dest);
            pCrawl = pCrawl->next;
        }
        printf("\n");
    }


}

void adjListFreeGraphAdjList(struct GraphAdjList* GraphAdjList){

    __u32 v;
    for (v = 0; v < GraphAdjList->V; ++v)
    {
        struct AdjListNode* pCrawl = GraphAdjList->parent_array[v].head;
        struct AdjListNode* pFree  = GraphAdjList->parent_array[v].head;
        while (pCrawl)
        {

            pFree = pCrawl;
            pCrawl = pCrawl->next;
            free(pFree);

        }
       
    }

    free(GraphAdjList->parent_array);
    free(GraphAdjList);


}