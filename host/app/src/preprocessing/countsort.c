#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
// #include "adjlist.h"
#include "capienv.h"
#include "countsort.h"
#include "edgelist.h"
#include "vertex.h"
#include "mymalloc.h"


struct GraphCountSorted* countSortEdgesBySource (struct EdgeList* edgeList){

	 printf("START Count Sort Edges By Source \n");

	struct GraphCountSorted* graph = countSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);

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


	graph = countSortMapVertices (graph);

	printf("DONE Count Sort Edges By Source \n");
	countSortedGraphPrint(graph);
	return graph;

}

struct GraphCountSorted* countSortMapVertices (struct GraphCountSorted* graph){

	__u32 i;
	__u32 vertex_id;

	vertex_id = graph->sorted_edges_array[0].src;
	graph->vertices[vertex_id].edges_idx = 0;

	for(i =1; i < graph->num_edges; i++){
		if(graph->sorted_edges_array[i].src != graph->sorted_edges_array[i-1].src){			
			vertex_id = graph->sorted_edges_array[i].src;
			graph->vertices[vertex_id].edges_idx = 1;
		}
	}

return graph;

}

struct GraphCountSorted* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList){

	struct GraphCountSorted* graph = countSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);


	return graph;
}



struct GraphCountSorted* countSortedCreateGraph(__u32 V, __u32 E){

	// struct GraphCountSorted* graph = (struct GraphCountSorted*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphCountSorted));
	struct GraphCountSorted* graph = (struct GraphCountSorted*) my_aligned_alloc( sizeof(struct GraphCountSorted));


	graph->num_vertices = V;
	graph->num_edges = E;
	graph->vertices = newVertexArray(V);
	// graph->vertex_count = (__u32*) aligned_alloc(CACHELINE_BYTES, V * sizeof(__u32));
	graph->vertex_count = (__u32*) my_aligned_alloc( V * sizeof(__u32));
	graph->sorted_edges_array = newEdgeArray(E);

	__u32 i;
	for(i = 0; i < V; i++){
        graph->vertex_count[i] = 0;  
	}

    return graph;
}


void countSortedFreeGraph (struct GraphCountSorted* graph){

	freeVertexArray(graph->vertices);
	free(graph->vertex_count);
	freeEdgeArray(graph->sorted_edges_array);
	free(graph);

}

void countSortedGraphPrint(struct GraphCountSorted* graph){

	 
    printf("number of vertices (V) : %d \n", graph->num_vertices);
    printf("number of edges    (E) : %d \n", graph->num_edges);   

	// int i;
    // for(i = 0; i < graph->num_edges; i++){

    //     printf("%d -> %d w: %d \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest, graph->sorted_edges_array[i].weight);   

    //  }

   
}