#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
// #include "adjlist.h"
#include "capienv.h"
#include "countsort.h"
#include "edgelist.h"
#include "vertex.h"


struct GraphCountSorted* countSortEdgesBySource (struct EdgeList* edgeList){

	struct GraphCountSorted* graph = GraphCountSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);

	int i;
	int key;
	int pos;


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


	return graph;

}
struct GraphCountSorted* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList){

	struct GraphCountSorted* graph = GraphCountSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);


	return graph;
}



struct GraphCountSorted* GraphCountSortedCreateGraph(int V, int E){

	struct GraphCountSorted* graph = (struct GraphCountSorted*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphCountSorted));

	graph->num_vertices = V;
	graph->num_edges = E;
	graph->vertices = newVertexArray(V);
	graph->vertex_count = (int*) aligned_alloc(CACHELINE_BYTES, V * sizeof(int));
	graph->sorted_edges_array = newEdgeArray(E);

	int i;
	for(i = 0; i < V; i++){
        graph->vertex_count[i] = 0;  
	}

    return graph;
}

void CountSortedGraphPrint(struct GraphCountSorted* graph){

	 
    printf("number of vertices (V) : %d \n", graph->num_vertices);
    printf("number of edges    (E) : %d \n", graph->num_edges);   

	int i;
    for(i = 0; i < graph->num_edges; i++){

        printf("%d -> %d w: %d \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest, graph->sorted_edges_array[i].weight);   

     }

   
}