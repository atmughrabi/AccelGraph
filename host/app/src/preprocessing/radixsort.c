#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
// #include "adjlist.h"
#include "capienv.h"
#include "radixsort.h"
#include "edgelist.h"
#include "vertex.h"
#include "mymalloc.h"

// A function to do counting sort of edgeList according to
// the digit represented by exp
struct GraphRadixSorted* radixSortCountSortEdgesBySource (struct GraphRadixSorted* graph, struct EdgeList* edgeList, int exp){

	long i;
	__u32 key;
	__u32 pos;

	

	// count occurrence of key: id of the source vertex
	for(i = 0; i < graph->num_edges; i++){
		key = edgeList->edges_array[i].src;
		graph->vertex_count[(key/exp)%10]++;
	}

	for (i = 1; i < 10; i++) {
        graph->vertex_count[i] += graph->vertex_count[i - 1];
	}

	// fill-in the sorted array of edges
	for(i = graph->num_edges-1; i >= 0; i--){
		key = edgeList->edges_array[i].src;
		pos = graph->vertex_count[(key/exp)%10]-1;
		graph->sorted_edges_array[pos] = edgeList->edges_array[i];
		graph->vertex_count[(key/exp)%10]--;
	}

	for (i = 0; i < graph->num_edges; i++){
        edgeList->edges_array[i] = graph->sorted_edges_array[i];
	}

	for (i = 0; i < 10; i++) {
        graph->vertex_count[i] = 0;
	}

	return graph;

}



struct GraphRadixSorted* radixSortEdgesBySource (struct EdgeList* edgeList){

	printf("*** START Radix Sort Edges By Source *** \n");

	__u32 exp;
	struct GraphRadixSorted* graph = radixSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number
	 for (exp = 1; (edgeList->num_vertices/exp) > 0; exp *= 10){
	 	graph = radixSortCountSortEdgesBySource (graph, edgeList, exp);
	 }
	
	graph = radixSortMapVertices (graph);

	printf("DONE Radix Sort Edges By Source \n");
	radixSortedGraphPrint(graph);


	return graph;

}

struct GraphRadixSorted* radixSortMapVertices (struct GraphRadixSorted* graph){

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

struct GraphRadixSorted* radixSortEdgesBySourceAndDestination (struct EdgeList* edgeList){

	printf("*** START Radix Sort Edges By Source And Destination *** \n");

	// __u32 exp;
	// long i;
	// __u32 key;
	// __u32 pos;

	struct GraphRadixSorted* graph = radixSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

	__u32 count = edgeList->num_edges;
	__u32 mIndex[8][256] = { 0 };
	__u32 * pmIndex;
	__u32 i, j, m, n;
	__u32 u;

	 for (i = 0; i < count; i++) {       /* generate histograms */
		u = edgeList->edges_array[i].dest;
        mIndex[7][(u >> 0)  & 0xff]++;
        mIndex[6][(u >> 8)  & 0xff]++;
        mIndex[5][(u >> 16) & 0xff]++;
        mIndex[4][(u >> 24) & 0xff]++;

        u = edgeList->edges_array[i].src;
        mIndex[3][(u >> 0)  & 0xff]++;
        mIndex[2][(u >> 8)  & 0xff]++;
        mIndex[1][(u >> 16) & 0xff]++;
        mIndex[0][(u >> 24) & 0xff]++;



    }

    for (j = 0; j < 4; j++) {           /* convert to indices generate prefixsum */
        pmIndex = mIndex[j];
        n = 0;
        for (i = 0; i < 256; i++) {
            m = pmIndex[i];
            pmIndex[i] = n;
            n += m;
        }
    }

     for (j = 4; j < 8; j++) {           /* convert to indices generate prefixsum */
        pmIndex = mIndex[j];
        n = 0;
        for (i = 0; i < 256; i++) {
            m = pmIndex[i];
            pmIndex[i] = n;
            n += m;
        }
    }

     for (i = 0; i < count; i++) {       /* radix sort */
        u = edgeList->edges_array[i].dest;
        graph->sorted_edges_array[mIndex[7][(u >> 0) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = graph->sorted_edges_array[i].dest;
        edgeList->edges_array[mIndex[6][(u >> 8) & 0xff]++] = graph->sorted_edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = edgeList->edges_array[i].dest;
        graph->sorted_edges_array[mIndex[5][(u >> 16) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = graph->sorted_edges_array[i].dest;
        edgeList->edges_array[mIndex[4][(u >> 24) & 0xff]++] = graph->sorted_edges_array[i];
    }

    for (i = 0; i < count; i++) {       /* radix sort */
        u = edgeList->edges_array[i].src;
        graph->sorted_edges_array[mIndex[3][(u >> 0) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = graph->sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[2][(u >> 8) & 0xff]++] = graph->sorted_edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = edgeList->edges_array[i].src;
        graph->sorted_edges_array[mIndex[1][(u >> 16) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = graph->sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[0][(u >> 24) & 0xff]++] = graph->sorted_edges_array[i];
    }

    freeEdgeArray(graph->sorted_edges_array);

    graph->sorted_edges_array = edgeList->edges_array;
	
	graph = radixSortMapVertices (graph);

	printf("DONE Radix Sort Edges By Source And Destination \n");
	radixSortedGraphPrint(graph);


	return graph;
}



struct GraphRadixSorted* radixSortedCreateGraph(__u32 V, __u32 E){

	// struct GraphRadixSorted* graph = (struct GraphRadixSorted*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphRadixSorted));
	#ifdef ALIGNED
		struct GraphRadixSorted* graph = (struct GraphRadixSorted*) my_aligned_alloc( sizeof(struct GraphRadixSorted));
	#else
        struct GraphRadixSorted* graph = (struct GraphRadixSorted*) my_malloc( sizeof(struct GraphRadixSorted));
    #endif

	graph->num_vertices = V;
	graph->num_edges = E;
	graph->vertices = newVertexArray(V);
	// graph->vertex_count = (__u32*) aligned_alloc(CACHELINE_BYTES, V * sizeof(__u32));
	#ifdef ALIGNED
		graph->vertex_count = (__u32*) my_aligned_alloc( 10 * sizeof(__u32));
	#else
        graph->vertex_count = (__u32*) my_malloc( 10 * sizeof(__u32));
    #endif

	graph->sorted_edges_array = newEdgeArray(E);

	int i;
	for(i = 0; i < 10; i++){
        graph->vertex_count[i] = 0;  
	}

    return graph;
}

void radixSortedFreeGraph (struct GraphRadixSorted* graph){

	freeVertexArray(graph->vertices);
	free(graph->vertex_count);
	freeEdgeArray(graph->sorted_edges_array);
	free(graph);

}

void radixSortedGraphPrint(struct GraphRadixSorted* graph){

	 
    printf("number of vertices (V) : %d \n", graph->num_vertices);
    printf("number of edges    (E) : %d \n", graph->num_edges);   

	// __u32 i;
 //    for(i = 0; i < graph->num_edges; i++){

 //        printf("%d -> %d w: %d \n", graph->sorted_edges_array[i].src, graph->sorted_edges_array[i].dest, graph->sorted_edges_array[i].weight);   

 //     }

   
}


struct GraphRadixSorted* radixSortEdgesBySourceOptimized (struct EdgeList* edgeList){

	printf("*** START Radix Sort Edges By Source *** \n");

	// __u32 exp;
	// long i;
	// __u32 key;
	// __u32 pos;

	struct GraphRadixSorted* graph = radixSortedCreateGraph(edgeList->num_vertices, edgeList->num_edges);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

	__u32 count = edgeList->num_edges;
	__u32 mIndex[4][256] = { 0 };
	__u32 * pmIndex;
	__u32 i, j, m, n;
	__u32 u;

	 for (i = 0; i < count; i++) {       /* generate histograms */
        u = edgeList->edges_array[i].src;
        mIndex[3][(u >> 0)  & 0xff]++;
        mIndex[2][(u >> 8)  & 0xff]++;
        mIndex[1][(u >> 16) & 0xff]++;
        mIndex[0][(u >> 24) & 0xff]++;
    }

    for (j = 0; j < 4; j++) {           /* convert to indices generate prefixsum */
        pmIndex = mIndex[j];
        n = 0;
        for (i = 0; i < 256; i++) {
            m = pmIndex[i];
            pmIndex[i] = n;
            n += m;
        }
    }

    for (i = 0; i < count; i++) {       /* radix sort */
        u = edgeList->edges_array[i].src;
        graph->sorted_edges_array[mIndex[3][(u >> 0) & 0xff]++] = edgeList->edges_array[i];
    }

    for (i = 0; i < count; i++) {
        u = graph->sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[2][(u >> 8) & 0xff]++] = graph->sorted_edges_array[i];
    }

    for (i = 0; i < count; i++) {
        u = edgeList->edges_array[i].src;
        graph->sorted_edges_array[mIndex[1][(u >> 16) & 0xff]++] = edgeList->edges_array[i];
    }

    for (i = 0; i < count; i++) {
        u = graph->sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[0][(u >> 24) & 0xff]++] = graph->sorted_edges_array[i];
    }

	freeEdgeArray(graph->sorted_edges_array);
    graph->sorted_edges_array = edgeList->edges_array;

	graph = radixSortMapVertices (graph);

	printf("DONE Radix Sort Edges By Source \n");
	radixSortedGraphPrint(graph);


	return graph;

} 





