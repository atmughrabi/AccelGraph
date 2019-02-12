#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <omp.h>

#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphAdjLinkedList.h"
#include "graphConfig.h"
#include "adjLinkedList.h"
#include "timer.h"

void graphAdjLinkedListReset(struct GraphAdjLinkedList* graphAdjLinkedList){

     struct AdjLinkedList* vertices;
    __u32 vertex_id;
    // #if DIRECTED
    //     if(inverse){
    //         vertices = graph->inverse_vertices; // sorted edge array
    //     }else{
    //         vertices = graph->vertices;
    //     }
    // #else
            vertices = graphAdjLinkedList->vertices;
    // #endif

    graphAdjLinkedList->iteration = 0;
    graphAdjLinkedList->processed_nodes = 0;

    #pragma omp parallel for default(none) private(vertex_id) shared(vertices,graphAdjLinkedList)
    for(vertex_id = 0; vertex_id < graphAdjLinkedList->num_vertices ; vertex_id++){
                if(vertices[vertex_id].out_degree)
                    graphAdjLinkedList->parents[vertex_id] = vertices[vertex_id].out_degree * (-1);
                else
                    graphAdjLinkedList->parents[vertex_id] = -1;
     }


}

// A utility function that creates a graphAdjLinkedList of V vertices
struct GraphAdjLinkedList* graphAdjLinkedListGraphNew(__u32 V){

    // printf("\n Create graphAdjLinkedList #Vertecies: %d\n ", V);

	// struct graphAdjLinkedList* graphAdjLinkedList = (struct graphAdjLinkedList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct graphAdjLinkedList));
    #if ALIGNED
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_aligned_malloc( sizeof(struct GraphAdjLinkedList));
    #else
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_malloc( sizeof(struct GraphAdjLinkedList));
    #endif

	graphAdjLinkedList->num_vertices = V;
	// graphAdjLinkedList->vertices = (struct AdjLinkedList*) aligned_alloc(CACHELINE_BYTES, V * sizeof(struct AdjLinkedList));
    #if ALIGNED
        graphAdjLinkedList->vertices = (struct AdjLinkedList*) my_aligned_malloc( V * sizeof(struct AdjLinkedList));
    #else
        graphAdjLinkedList->vertices = (struct AdjLinkedList*) my_malloc( V * sizeof(struct AdjLinkedList));
    #endif

	__u32 i;
    #pragma omp parallel for
	for(i = 0; i < V; i++){

		graphAdjLinkedList->vertices[i].outNodes = NULL;
        graphAdjLinkedList->vertices[i].out_degree = 0; 

        #if DIRECTED
            graphAdjLinkedList->vertices[i].inNodes = NULL; 
            graphAdjLinkedList->vertices[i].in_degree = 0;
        #endif

        graphAdjLinkedList->vertices[i].visited = 0;
	}

    graphAdjLinkedList->iteration = 0;
    graphAdjLinkedList->processed_nodes = 0;

    // printf("\n Success!!! V: %d\n ", V);

    return graphAdjLinkedList;

}

struct GraphAdjLinkedList* graphAdjLinkedListEdgeListNew(struct EdgeList* edgeList){

    // struct graphAdjLinkedList* graphAdjLinkedList = (struct graphAdjLinkedList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct graphAdjLinkedList));
    #if ALIGNED
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_aligned_malloc( sizeof(struct GraphAdjLinkedList));
    #else
        struct GraphAdjLinkedList* graphAdjLinkedList = (struct GraphAdjLinkedList*) my_malloc( sizeof(struct GraphAdjLinkedList));
    #endif

    graphAdjLinkedList->num_vertices = edgeList->num_vertices;
    graphAdjLinkedList->num_edges = edgeList->num_edges;
    // graphAdjLinkedList->vertices = (struct AdjLinkedList*) aligned_alloc(CACHELINE_BYTES, graphAdjLinkedList->V * sizeof(struct AdjLinkedList));

    #if ALIGNED
        graphAdjLinkedList->vertices = (struct AdjLinkedList*) my_aligned_malloc( graphAdjLinkedList->num_vertices * sizeof(struct AdjLinkedList));
    #else
        graphAdjLinkedList->vertices = (struct AdjLinkedList*) my_malloc( graphAdjLinkedList->num_vertices * sizeof(struct AdjLinkedList));
    #endif

    #if ALIGNED
        graphAdjLinkedList->parents  = (int*) my_aligned_malloc( graphAdjLinkedList->num_vertices * sizeof(int));
    #else
        graphAdjLinkedList->parents  = (int*) my_malloc( graphAdjLinkedList->num_vertices *sizeof(int));
    #endif

     
    #if WEIGHTED
        graphAdjLinkedList->max_weight =  edgeList->max_weight;
    #endif



    __u32 i;
    #pragma omp parallel for
    for(i = 0; i < graphAdjLinkedList->num_vertices; i++){

        graphAdjLinkedList->parents[i] = -1; 

        graphAdjLinkedList->vertices[i].outNodes = NULL;
        graphAdjLinkedList->vertices[i].out_degree = 0; 

        #if DIRECTED
            graphAdjLinkedList->vertices[i].inNodes = NULL; 
            graphAdjLinkedList->vertices[i].in_degree = 0;
        #endif

        graphAdjLinkedList->vertices[i].visited = 0;
    }   

     #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graphAdjLinkedList->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graphAdjLinkedList->num_vertices *sizeof(omp_lock_t));
    #endif


    #pragma omp parallel for
    for (i=0; i<graphAdjLinkedList->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

    #pragma omp parallel for
    for(i = 0; i < edgeList->num_edges; i++){

        // #if DIRECTED
        //     adjLinkedListAddEdgeDirected(graphAdjLinkedList, &(edgeList->edges_array[i]));
        // #else
        //     adjLinkedListAddEdgeUndirected(graphAdjLinkedList, &(edgeList->edges_array[i]));
        // #endif
        adjLinkedListAddEdge(graphAdjLinkedList, &(edgeList->edges_array[i]),vertex_lock);

        }

    #pragma omp parallel for
    for (i=0; i<graphAdjLinkedList->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(vertex_lock);
    graphAdjLinkedList->iteration = 0;
    graphAdjLinkedList->processed_nodes = 0;

    return graphAdjLinkedList;

}


// A utility function to print the adjacency list 
// representation of graphAdjLinkedList
void graphAdjLinkedListPrint(struct GraphAdjLinkedList* graphAdjLinkedList){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "GraphAdjLinkedList Properties");
    printf(" -----------------------------------------------------\n");
    #if WEIGHTED       
                printf("| %-51s | \n", "WEIGHTED");
    #else
                printf("| %-51s | \n", "UN-WEIGHTED");
    #endif

    #if DIRECTED
                printf("| %-51s | \n", "DIRECTED");
    #else
                printf("| %-51s | \n", "UN-DIRECTED");
    #endif
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Vertices (V)");
    printf("| %-51u | \n", graphAdjLinkedList->num_vertices);
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", graphAdjLinkedList->num_edges);  
    printf(" -----------------------------------------------------\n");


	// __u32 v;
 //    for (v = 0; v < graphAdjLinkedList->num_vertices; ++v)
 //    {
 //        struct AdjLinkedListNode* pCrawl = graphAdjLinkedList->vertices[v].outNodes;
 //        printf("\n Adjacency list of vertex %d\n  out_degree: %d \n", v, graphAdjLinkedList->vertices[v].out_degree);
 //        while (pCrawl)
 //        {
 //            printf("-> %d", pCrawl->dest);
 //            pCrawl = pCrawl->next;
 //        }
 //        printf("\n");


 //        #if DIRECTED
	//         pCrawl = graphAdjLinkedList->vertices[v].inNodes;
	//         printf("\n Adjacency list of vertex %d\n  in_degree: %d \n", v, graphAdjLinkedList->vertices[v].in_degree);
	//         while (pCrawl)
	//         {
	//             printf("<- %d", pCrawl->dest);
	//             pCrawl = pCrawl->next;
	//         }
	//         printf("\n");
 //        #endif
 //    }


}

void graphAdjLinkedListFree(struct GraphAdjLinkedList* graphAdjLinkedList){

    __u32 v;
    struct AdjLinkedListNode* pCrawl;
    struct AdjLinkedListNode* pFree;

    for (v = 0; v < graphAdjLinkedList->num_vertices; ++v)
    {
        pCrawl = graphAdjLinkedList->vertices[v].outNodes;
        pFree  = graphAdjLinkedList->vertices[v].outNodes;

        while (pCrawl)
        {

            pFree = pCrawl;
            pCrawl = pCrawl->next;
            free(pFree);

        }

         #if DIRECTED
	        pCrawl = graphAdjLinkedList->vertices[v].inNodes;
	        pFree  = graphAdjLinkedList->vertices[v].inNodes;

	        while (pCrawl)
	        {

	            pFree = pCrawl;
	            pCrawl = pCrawl->next;
	            free(pFree);

	        }
        #endif
       
    }

    free(graphAdjLinkedList->parents);
    free(graphAdjLinkedList->vertices);
    free(graphAdjLinkedList);


}

void adjLinkedListAddEdge(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge, omp_lock_t *vertex_lock){

    // omp_set_lock(&(vertex_lock[edge->src]));
    // omp_unset_lock((&vertex_lock[edge->src]));

    // Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjLinkedListNode* newNode = newAdjLinkedListOutNode(edge);
    omp_set_lock(&(vertex_lock[edge->src]));
    newNode->next = graphAdjLinkedList->vertices[edge->src].outNodes;
    graphAdjLinkedList->vertices[edge->src].out_degree++;
    graphAdjLinkedList->vertices[edge->src].visited = 0;
    graphAdjLinkedList->vertices[edge->src].outNodes = newNode;
   
    omp_unset_lock((&vertex_lock[edge->src]));

    // omp_set_lock(&(vertex_lock[edge->dest]));
    // omp_unset_lock((&vertex_lock[edge->dest]));
    // Since graphAdjLinkedList is undirected, add an edge from
    // dest to src also
    newNode = newAdjLinkedListInNode(edge);
    omp_set_lock(&(vertex_lock[edge->dest]));
    #if DIRECTED
        newNode->next = graphAdjLinkedList->vertices[edge->dest].inNodes;
        graphAdjLinkedList->vertices[edge->dest].in_degree++; 
        graphAdjLinkedList->vertices[edge->dest].visited = 0;  
        graphAdjLinkedList->vertices[edge->dest].inNodes = newNode;
    #else
        newNode->next = graphAdjLinkedList->vertices[edge->dest].outNodes;
        graphAdjLinkedList->vertices[edge->dest].out_degree++;  
        graphAdjLinkedList->vertices[edge->dest].visited = 0;
        graphAdjLinkedList->vertices[edge->dest].outNodes = newNode;
    #endif

    omp_unset_lock((&vertex_lock[edge->dest]));

}

// Adds an edge to an undirected graphAdjLinkedList
void adjLinkedListAddEdgeUndirected(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge){

	// Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjLinkedListNode* newNode = newAdjLinkedListOutNode(edge);
    newNode->next = graphAdjLinkedList->vertices[edge->src].outNodes;
    graphAdjLinkedList->vertices[edge->src].out_degree++;
    graphAdjLinkedList->vertices[edge->src].visited = 0;
    graphAdjLinkedList->vertices[edge->src].outNodes = newNode;
   

    // Since graphAdjLinkedList is undirected, add an edge from
    // dest to src also
    newNode = newAdjLinkedListInNode(edge);
    newNode->next = graphAdjLinkedList->vertices[edge->dest].outNodes;
    graphAdjLinkedList->vertices[edge->dest].out_degree++;  
    graphAdjLinkedList->vertices[edge->dest].visited = 0;
    graphAdjLinkedList->vertices[edge->dest].outNodes = newNode;
  

}
// Adds an edge to a directed graphAdjLinkedList
void adjLinkedListAddEdgeDirected(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge){

    // Add an edge from src to dest.  A new node is 
    // added to the adjacency list of src.  The node
    // is added at the begining
    struct AdjLinkedListNode* newNode = newAdjLinkedListOutNode(edge);
    newNode->next = graphAdjLinkedList->vertices[edge->src].outNodes;
    graphAdjLinkedList->vertices[edge->src].out_degree++;  
    graphAdjLinkedList->vertices[edge->src].visited = 0;   
    graphAdjLinkedList->vertices[edge->src].outNodes = newNode;
   

    #if DIRECTED
        newNode = newAdjLinkedListInNode(edge);
        newNode->next = graphAdjLinkedList->vertices[edge->dest].inNodes;
        graphAdjLinkedList->vertices[edge->dest].in_degree++;  
        graphAdjLinkedList->vertices[edge->dest].visited = 0;  
        graphAdjLinkedList->vertices[edge->dest].inNodes = newNode;
    #endif


}


void   graphAdjLinkedListPrintMessageWithtime(const char * msg, double time){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}
struct GraphAdjLinkedList* graphAdjLinkedListPreProcessingStep (const char * fnameb, __u32 lmode, __u32 symmetric, __u32 weighted){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));



    Start(timer);
    struct EdgeList* edgeList = readEdgeListsbin(fnameb, 0, symmetric, weighted);
    Stop(timer);
    // edgeListPrint(edgeList);
    graphAdjLinkedListPrintMessageWithtime("Read Edge List From File (Seconds)",Seconds(timer));

    Start(timer); 
    struct GraphAdjLinkedList* graphAdjLinkedList = graphAdjLinkedListEdgeListNew(edgeList);
    Stop(timer);
    graphAdjLinkedListPrintMessageWithtime("Create Adj Linked List from EdgeList (Seconds)",Seconds(timer));

    freeEdgeList(edgeList);
    free(timer);
    return graphAdjLinkedList;


}