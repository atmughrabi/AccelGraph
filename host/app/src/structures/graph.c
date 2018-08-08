
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
// #include "adjlist.h"
#include "capienv.h"
#include "radixsort.h"
#include "edgelist.h"
#include "vertex.h"
#include "mymalloc.h"
#include "graph.h"
#include "graphconfig.h"

void graphFree (struct Graph* graph){

	if(graph->vertices)
		freeVertexArray(graph->vertices);
	if(graph->vertex_count)
		free(graph->vertex_count);
	if(graph->parents)
		free(graph->parents);
	if(graph->sorted_edges_array)
		freeEdgeArray(graph->sorted_edges_array);
	if(graph)
		free(graph);

}

void graphPrint(struct Graph* graph){

	 
    printf("number of vertices (V) : %d \n", graph->num_vertices);
    printf("number of edges    (E) : %d \n", graph->num_edges);  
    vertexArrayMaxOutdegree(graph->vertices, graph->num_vertices);
 	vertexArrayMaxInDegree(graph->vertices, graph->num_vertices);
 	// printVertexArray(graph->vertices, graph->num_vertices);
	// __u32 i;

	// printf("Edge List (E) : %d \n", graph->num_edges);  
 //    for(i = 0; i < graph->num_edges; i++){

 //    	#if WEIGHTED
 //        	printf("%u -> %u w: %d \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest, graph->sorted_edges_array[i].weight);   
 //        #else
 //        	printf("%u -> %u \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest);   
 //        #endif
 //     }

 //    printf("Inverted Edge List (E) : %d \n", graph->num_edges);  
 //      for(i = 0; i < graph->num_edges; i++){

 //    	#if WEIGHTED
 //        	printf("%u -> %u w: %d \n", graph->inverse_sorted_edges_array[i].src, graph->inverse_sorted_edges_array[i].dest, graph->inverse_sorted_edges_array[i].weight);   
 //        #else
 //        	printf("%u -> %u \n", graph->inverse_sorted_edges_array[i].src, graph->inverse_sorted_edges_array[i].dest);   
 //        #endif
 //     }

   
}


struct Graph* graphNew(__u32 V, __u32 E, __u8 inverse){
	int i;
	// struct Graph* graph = (struct Graph*) aligned_alloc(CACHELINE_BYTES, sizeof(struct Graph));
	#if ALIGNED
		struct Graph* graph = (struct Graph*) my_aligned_alloc( sizeof(struct Graph));
	#else
        struct Graph* graph = (struct Graph*) my_malloc( sizeof(struct Graph));
    #endif

	graph->num_vertices = V;
	graph->num_edges = E;

	graph->vertices = newVertexArray(V);

	#if DIRECTED
		if (inverse)
			graph->inverse_vertices = newVertexArray(V);
	#endif

	#if ALIGNED
		graph->parents  = (int*) my_aligned_alloc( V * sizeof(int));
	#else
        graph->parents  = (int*) my_malloc( V *sizeof(int));
    #endif


     for(i = 0; i < V; i++){
                graph->parents[i] = -1;
     }
	// graph->vertex_count = (__u32*) aligned_alloc(CACHELINE_BYTES, V * sizeof(__u32));
	
	graph->sorted_edges_array = newEdgeArray(E);

	#if DIRECTED
		if (inverse)
			graph->inverse_sorted_edges_array = newEdgeArray(E);
	#endif


    return graph;
}

void printGraphParentsArray(struct Graph* graph){


    __u32 i;

    printf("| %-15s | %-15s | %-15s | %-15s | \n", "Node", "out_degree", "Parent", "Visited");

    for(i =0; i < graph->num_vertices; i++){

        if((graph->vertices[i].out_degree > 0) || (graph->vertices[i].in_degree > 0))
        printf("| %-15u | %-15u | %-15d | %-15u | \n",i,  graph->vertices[i].out_degree, graph->parents[i], graph->vertices[i].visited);
    
    }

}

