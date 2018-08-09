#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "countsort.h"
#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphCSR.h"

struct EdgeList*  countSortEdgesBySource (struct EdgeList* edgeList){


	
	
	long i;
	__u32 key;
	__u32 pos;
	__u32 num_vertices = edgeList->num_vertices;
	__u32 num_edges = edgeList->num_edges;


	struct Edge* sorted_edges_array = newEdgeArray(num_edges);

	#if ALIGNED
		__u32* vertex_count = (__u32*) my_aligned_alloc( num_vertices * sizeof(__u32));
	#else
        __u32* vertex_count = (__u32*) my_malloc( num_vertices * sizeof(__u32));
    #endif
	
	// count occurrence of key: id of the source vertex
	for(i = 0; i < num_edges; i++){
		key = edgeList->edges_array[i].src;
		vertex_count[key]++;
	}

	// transfrom the cumulative sum
	
	for(i = 1; i < num_vertices; i++){
		vertex_count[i] += vertex_count[i-1];
	}

	// fill-in the sorted array of edges
	
	for(i = num_edges-1; i >= 0; i--){	
			
		key = edgeList->edges_array[i].src;
		
		pos = vertex_count[key]-1;
		
		sorted_edges_array[pos] = edgeList->edges_array[i];
		
		vertex_count[key]--;
		
	}


	free(vertex_count);
	freeEdgeArray(edgeList->edges_array);

	edgeList->edges_array = sorted_edges_array;

	return edgeList;

}



struct EdgeList*  countSortEdgesBySourceAndDestination (struct EdgeList* edgeList){



	return edgeList;
}






