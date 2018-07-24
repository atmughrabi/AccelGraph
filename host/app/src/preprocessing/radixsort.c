#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
// #include "adjlist.h"
#include "capienv.h"
#include "radixsort.h"
#include "edgelist.h"
#include "vertex.h"


// A function to do counting sort of edgeList according to
// the digit represented by exp
struct GraphRadixSorted* CountSortedgesBySource (struct GraphRadixSorted* graph, struct EdgeList* edgeList, int exp){

	int i;
	int key;
	int pos;

	// count occurrence of key: id of the source vertex
	for(i = 0; i < graph->num_edges; i++){
		key = edgeList->edges_array[i].src;
		graph->vertex_count[(key/exp)%10]++;
	}


	// transfrom the cumulative sum
	for(i = 1; i < graph->num_vertices; i++){
		graph->vertex_count[i] += graph->vertex_count[i-1];
	}

	// fill-in the sorted array of edges
	for(i = graph->num_edges-1; i >= 0; i--){
		key = edgeList->edges_array[i].src;
		pos = graph->vertex_count[(key/exp)%10]-1;
		graph->sorted_edges_array[pos] = edgeList->edges_array[i];
		graph->vertex_count[(key/exp)%10]--;
	}

	return graph;

}

struct GraphRadixSorted* RadixSortedgesBySource (struct EdgeList* edgeList){

	int exp;
	struct GraphRadixSorted* graph = GraphRadixSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number
	 for (exp = 1; (edgeList->num_vertices/exp) > 0; exp *= 10){
	 	graph = CountSortedgesBySource (graph, edgeList, exp);
	 }
		

	graph = radixSortMapVertices (graph);

	return graph;

}

struct GraphRadixSorted* radixSortMapVertices (struct GraphRadixSorted* graph){

	int i;
	int vertex_id;

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

struct GraphRadixSorted* RadixSortedgesBySourceAndDestination (struct EdgeList* edgeList){

	struct GraphRadixSorted* graph = GraphRadixSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);


	return graph;
}



struct GraphRadixSorted* GraphRadixSortedCreateGraph(int V, int E){

	struct GraphRadixSorted* graph = (struct GraphRadixSorted*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphRadixSorted));

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

void RadixSortedGraphPrint(struct GraphRadixSorted* graph){

	 
    printf("number of vertices (V) : %d \n", graph->num_vertices);
    printf("number of edges    (E) : %d \n", graph->num_edges);   

	int i;
    for(i = 0; i < graph->num_edges; i++){

        printf("%d -> %d w: %d \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest, graph->sorted_edges_array[i].weight);   

     }

   
}