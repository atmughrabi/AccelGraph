#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphAdjLinkedList.h"
#include "graphConfig.h"
#include "adjLinkedList.h"




// A utility function that creates a graphAdjLinkedList of V vertices
struct GraphAdjLinkedList* graphAdjLinkedListGraphNew(__u32 V){

    // printf("\n Create graphAdjLinkedList #Vertecies: %d\n ", V);

	// struct graphAdjLinkedList* graphAdjLinkedList = (struct graphAdjLinkedList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct graphAdjLinkedList));
    #if ALIGNED
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_aligned_alloc( sizeof(struct GraphAdjLinkedList));
    #else
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_malloc( sizeof(struct GraphAdjLinkedList));
    #endif

	graphAdjLinkedList->num_vertices = V;
	// graphAdjLinkedList->parent_array = (struct AdjLinkedList*) aligned_alloc(CACHELINE_BYTES, V * sizeof(struct AdjLinkedList));
    #if ALIGNED
        graphAdjLinkedList->parent_array = (struct AdjLinkedList*) my_aligned_alloc( V * sizeof(struct AdjLinkedList));
    #else
        graphAdjLinkedList->parent_array = (struct AdjLinkedList*) my_malloc( V * sizeof(struct AdjLinkedList));
    #endif

	__u32 i;
	for(i = 0; i < V; i++){

		 graphAdjLinkedList->parent_array[i].outNodes = NULL;
        graphAdjLinkedList->parent_array[i].out_degree = 0; 

        #if DIRECTED
            graphAdjLinkedList->parent_array[i].inNodes = NULL; 
            graphAdjLinkedList->parent_array[i].in_degree = 0;
        #endif

        graphAdjLinkedList->parent_array[i].visited = 0;
	}

    // printf("\n Success!!! V: %d\n ", V);

    return graphAdjLinkedList;

}

struct GraphAdjLinkedList* graphAdjLinkedListEdgeListNew(struct EdgeList* edgeList){

    // struct graphAdjLinkedList* graphAdjLinkedList = (struct graphAdjLinkedList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct graphAdjLinkedList));
    #if ALIGNED
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_aligned_alloc( sizeof(struct GraphAdjLinkedList));
    #else
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_malloc( sizeof(struct GraphAdjLinkedList));
    #endif

    graphAdjLinkedList->num_vertices = edgeList->num_vertices;
    graphAdjLinkedList->num_edges = edgeList->num_edges;
    // graphAdjLinkedList->parent_array = (struct AdjLinkedList*) aligned_alloc(CACHELINE_BYTES, graphAdjLinkedList->V * sizeof(struct AdjLinkedList));

    #if ALIGNED
        graphAdjLinkedList->parent_array = (struct AdjLinkedList*) my_aligned_alloc( graphAdjLinkedList->num_vertices * sizeof(struct AdjLinkedList));
    #else
        graphAdjLinkedList->parent_array = (struct AdjLinkedList*) my_malloc( graphAdjLinkedList->num_vertices * sizeof(struct AdjLinkedList));
    #endif

    __u32 i;
    for(i = 0; i < graphAdjLinkedList->num_vertices; i++){

        graphAdjLinkedList->parent_array[i].outNodes = NULL;
        graphAdjLinkedList->parent_array[i].out_degree = 0; 

        #if DIRECTED
            graphAdjLinkedList->parent_array[i].inNodes = NULL; 
            graphAdjLinkedList->parent_array[i].in_degree = 0;
        #endif

        graphAdjLinkedList->parent_array[i].visited = 0;
    }
   
    for(i = 0; i < edgeList->num_edges; i++){
            adjLinkedListAddEdgeUndirected(graphAdjLinkedList, edgeList->edges_array[i].src, edgeList->edges_array[i].dest, edgeList->edges_array[i].weight);
        }

    return graphAdjLinkedList;

}


// A utility function to print the adjacency list 
// representation of graphAdjLinkedList
void graphAdjLinkedListPrint(struct GraphAdjLinkedList* graphAdjLinkedList){

	__u32 v;
    for (v = 0; v < graphAdjLinkedList->num_vertices; ++v)
    {
        struct AdjLinkedListNode* pCrawl = graphAdjLinkedList->parent_array[v].outNodes;
        printf("\n Adjacency list of vertex %d\n  out_degree: %d \n", v, graphAdjLinkedList->parent_array[v].out_degree);
        while (pCrawl)
        {
            printf("-> %d", pCrawl->dest);
            pCrawl = pCrawl->next;
        }
        printf("\n");


        #if DIRECTED
	        pCrawl = graphAdjLinkedList->parent_array[v].inNodes;
	        printf("\n Adjacency list of vertex %d\n  in_degree: %d \n", v, graphAdjLinkedList->parent_array[v].in_degree);
	        while (pCrawl)
	        {
	            printf("-> %d", pCrawl->dest);
	            pCrawl = pCrawl->next;
	        }
	        printf("\n");
        #endif
    }


}

void graphAdjLinkedListFree(struct GraphAdjLinkedList* graphAdjLinkedList){

    __u32 v;
    struct AdjLinkedListNode* pCrawl;
    struct AdjLinkedListNode* pFree;

    for (v = 0; v < graphAdjLinkedList->num_vertices; ++v)
    {
        pCrawl = graphAdjLinkedList->parent_array[v].outNodes;
        pFree  = graphAdjLinkedList->parent_array[v].outNodes;

        while (pCrawl)
        {

            pFree = pCrawl;
            pCrawl = pCrawl->next;
            free(pFree);

        }

         #if DIRECTED
	        pCrawl = graphAdjLinkedList->parent_array[v].inNodes;
	        pFree  = graphAdjLinkedList->parent_array[v].inNodes;

	        while (pCrawl)
	        {

	            pFree = pCrawl;
	            pCrawl = pCrawl->next;
	            free(pFree);

	        }
        #endif
       
    }

    free(graphAdjLinkedList->parent_array);
    free(graphAdjLinkedList);


}



// Adds an edge to an undirected graphAdjLinkedList
void adjLinkedListAddEdgeUndirected(struct GraphAdjLinkedList* graphAdjLinkedList, __u32 src, __u32 dest, __u32 weight){

	// Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjLinkedListNode* newNode = newAdjLinkedListNode(src,dest,weight);
    newNode->next = graphAdjLinkedList->parent_array[src].outNodes;
    graphAdjLinkedList->parent_array[src].out_degree++;
    graphAdjLinkedList->parent_array[src].visited = 0;
    graphAdjLinkedList->parent_array[src].outNodes = newNode;


    // Since graphAdjLinkedList is undirected, add an edge from
    // dest to src also
    newNode = newAdjLinkedListNode(dest,src,weight);
    newNode->next = graphAdjLinkedList->parent_array[dest].outNodes;
    graphAdjLinkedList->parent_array[dest].out_degree++;  
    graphAdjLinkedList->parent_array[dest].visited = 0;
    graphAdjLinkedList->parent_array[dest].outNodes = newNode;


}
// Adds an edge to a directed graphAdjLinkedList
void adjLinkedListAddEdgeDirected(struct GraphAdjLinkedList* graphAdjLinkedList, __u32 src, __u32 dest, __u32 weight){

    // Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjLinkedListNode* newNode = newAdjLinkedListNode(src,dest,weight);
    newNode->next = graphAdjLinkedList->parent_array[src].outNodes;
    graphAdjLinkedList->parent_array[src].out_degree++;  
    graphAdjLinkedList->parent_array[src].visited = 0;   
    graphAdjLinkedList->parent_array[src].outNodes = newNode;

    #if DIRECTED
        newNode = newAdjLinkedListNode(dest,src,weight);
        newNode->next = graphAdjLinkedList->parent_array[dest].inNodes;
        graphAdjLinkedList->parent_array[dest].in_degree++;  
        graphAdjLinkedList->parent_array[dest].visited = 0;  
        graphAdjLinkedList->parent_array[dest].inNodes = newNode;
    #endif

}
