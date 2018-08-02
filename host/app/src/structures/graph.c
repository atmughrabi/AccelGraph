
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
	if(graph->sorted_edges_array)
		freeEdgeArray(graph->sorted_edges_array);
	if(graph)
		free(graph);

}

void graphPrint(struct Graph* graph){

	 
    printf("number of vertices (V) : %d \n", graph->num_vertices);
    printf("number of edges    (E) : %d \n", graph->num_edges);   

	// __u32 i;
 //    for(i = 0; i < graph->num_edges; i++){

 //    	#if WEIGHTED
 //        	printf("%u -> %u w: %d \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest, graph->sorted_edges_array[i].weight);   
 //        #else
 //        	printf("%u -> %u \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest);   
 //        #endif
 //     }

   
}


struct Graph* graphNew(__u32 V, __u32 E){

	// struct Graph* graph = (struct Graph*) aligned_alloc(CACHELINE_BYTES, sizeof(struct Graph));
	#if ALIGNED
		struct Graph* graph = (struct Graph*) my_aligned_alloc( sizeof(struct Graph));
	#else
        struct Graph* graph = (struct Graph*) my_malloc( sizeof(struct Graph));
    #endif

	graph->num_vertices = V;
	graph->num_edges = E;
	graph->vertices = newVertexArray(V);
	// graph->vertex_count = (__u32*) aligned_alloc(CACHELINE_BYTES, V * sizeof(__u32));
	
	graph->sorted_edges_array = newEdgeArray(E);


    return graph;
}