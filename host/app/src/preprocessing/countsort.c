#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
// #include "adjlist.h"
#include "capienv.h"
#include "countsort.h"
#include "edgelist.h"
#include "vertex.h"
#include "mymalloc.h"
#include "graph.h"

struct Graph* countSortEdgesBySource (struct EdgeList* edgeList){

	 printf("*** START Count Sort Edges By Source *** \n");

	struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges);

	#if ALIGNED
		graph->vertex_count = (__u32*) my_aligned_alloc( edgeList->num_vertices * sizeof(__u32));
	#else
        graph->vertex_count = (__u32*) my_malloc( edgeList->num_vertices * sizeof(__u32));
    #endif
	
	long i;
	__u32 key;
	__u32 pos;

	
	// count occurrence of key: id of the source vertex
	for(i = 0; i < graph->num_edges; i++){
		key = edgeList->edges_array[i].src;
		graph->vertex_count[key]++;
	}


	// transfrom the cumulative sum
	
	for(i = 1; i < graph->num_vertices; i++){
		graph->vertex_count[i] += graph->vertex_count[i-1];
	}

	// fill-in the sorted array of edges
	
	for(i = graph->num_edges-1; i >= 0; i--){	
			
		key = edgeList->edges_array[i].src;
		
		pos = graph->vertex_count[key]-1;
		
		graph->sorted_edges_array[pos] = edgeList->edges_array[i];
		

		graph->vertex_count[key]--;
		
	}


	graph = mapVertices (graph);

	printf("DONE Count Sort Edges By Source \n");
	graphPrint(graph);
	return graph;

}



struct Graph* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList){

	struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges);


	return graph;
}






