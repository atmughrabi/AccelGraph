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
#include "timer.h"

// A function to do counting sort of edgeList according to
// the digit represented by exp
struct Graph* radixSortCountSortEdgesBySource (struct Graph* graph, struct EdgeList* edgeList, int exp){

	long i;
	__u32 key;
	__u32 pos;

	for (i = 0; i < 10; i++) {
        graph->vertex_count[i] = 0;
	}

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

	

	return graph;

}



struct Graph* radixSortEdgesBySource (struct Graph* graph, struct EdgeList* edgeList){

	// printf("*** START Radix Sort Edges By Source *** \n");

	__u32 exp;
	// struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, 0);

	#if ALIGNED
		graph->vertex_count = (__u32*) my_aligned_alloc( 10 * sizeof(__u32));
	#else
        graph->vertex_count = (__u32*) my_malloc( 10 * sizeof(__u32));
    #endif

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number
	 for (exp = 1; (edgeList->num_vertices/exp) > 0; exp *= 10){
	 	graph = radixSortCountSortEdgesBySource (graph, edgeList, exp);
	 }
	
	graph = mapVertices (graph, 0);

	// printf("DONE Radix Sort Edges By Source \n");
	// graphPrint(graph);


	return graph;

}



struct Graph* radixSortEdgesBySourceAndDestination (struct Graph* graph, struct EdgeList* edgeList,  __u8 inverse){

	// printf("*** START Radix Sort Edges By Source And Destination *** \n");

	// struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

	__u32 count = edgeList->num_edges;
	__u32 mIndex[8][256] = { 0 };
	__u32 * pmIndex;
	__u32 i, j, m, n;
	__u32 u;


    struct Edge* sorted_edges_array;

    #if DIRECTED    

    if(inverse)
        sorted_edges_array = graph->inverse_sorted_edges_array;
    else
        sorted_edges_array = graph->sorted_edges_array;

    #else
        sorted_edges_array = graph->sorted_edges_array;
    #endif   

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
        sorted_edges_array[mIndex[7][(u >> 0) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].dest;
        edgeList->edges_array[mIndex[6][(u >> 8) & 0xff]++] = sorted_edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = edgeList->edges_array[i].dest;
        sorted_edges_array[mIndex[5][(u >> 16) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].dest;
        edgeList->edges_array[mIndex[4][(u >> 24) & 0xff]++] = sorted_edges_array[i];
    }

    for (i = 0; i < count; i++) {       /* radix sort */
        u = edgeList->edges_array[i].src;
        sorted_edges_array[mIndex[3][(u >> 0) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[2][(u >> 8) & 0xff]++] = sorted_edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = edgeList->edges_array[i].src;
        sorted_edges_array[mIndex[1][(u >> 16) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[0][(u >> 24) & 0xff]++] = sorted_edges_array[i];
    }

    freeEdgeArray(sorted_edges_array);

   #if DIRECTED
    
    if(inverse)
        graph->inverse_sorted_edges_array = edgeList->edges_array;
    else
        graph->sorted_edges_array = edgeList->edges_array;

    #else
        graph->sorted_edges_array = edgeList->edges_array;
    #endif

    // sorted_edges_array = edgeList->edges_array;
	
	graph = mapVertices(graph, inverse);

	// printf("DONE Radix Sort Edges By Source And Destination \n");

	// graphPrint(graph);


	return graph;
}









struct Graph* radixSortEdgesBySourceOptimized (struct Graph* graph, struct EdgeList* edgeList, __u8 inverse){

	// printf("*** START Radix Sort Edges By Source *** \n");

	// struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

	__u32 radix = 4;  // 32/8 8 bit radix needs 4 iterations
	__u32 buckets = 256; // 2^radix = 256 buckets
	__u32 num_edges = edgeList->num_edges;

	__u32 t4 = 0, t3 = 0, t2 = 0, t1 = 0;
	__u32 o4 = 0, o3 = 0, o2 = 0, o1 = 0;
	__u32 u = 0;
	__u32 i = 0;

    struct Edge* sorted_edges_array;

	#if ALIGNED
		graph->vertex_count = (__u32*) my_aligned_alloc( radix * buckets * sizeof(__u32));
	#else
        graph->vertex_count = (__u32*) my_malloc( radix * buckets * sizeof(__u32));
    #endif

     
    #if DIRECTED    

    if(inverse)
        sorted_edges_array = graph->inverse_sorted_edges_array;
    else
        sorted_edges_array = graph->sorted_edges_array;

    #else
        sorted_edges_array = graph->sorted_edges_array;
    #endif   


	 for (i = 0; i < num_edges; i++) {       /* generate histograms */
        u = edgeList->edges_array[i].src;
        t4 = (u >> 0)  & 0xff;
        t3 = (u >> 8)  & 0xff;
        t2 = (u >> 16) & 0xff;
        t1 = (u >> 24) & 0xff;
        graph->vertex_count[3*buckets + t4]++;
        graph->vertex_count[2*buckets + t3]++;
        graph->vertex_count[1*buckets + t2]++;
        graph->vertex_count[0*buckets + t1]++;

    }


    for(i=0; i< buckets; i++){ /* convert to indices generate prefixsum */

    	t4 = o4 + graph->vertex_count[3*buckets + i];
        t3 = o3 + graph->vertex_count[2*buckets + i];
        t2 = o2 + graph->vertex_count[1*buckets + i];
        t1 = o1 + graph->vertex_count[0*buckets + i];

        graph->vertex_count[3*buckets + i] = o4;
        graph->vertex_count[2*buckets + i] = o3;
        graph->vertex_count[1*buckets + i] = o2;
        graph->vertex_count[0*buckets + i] = o1;

        o4 = t4;
        o3 = t3;
        o2 = t2;
        o1 = t1;
    }


    for (i = 0; i < num_edges; i++) {       /* radix sort */
        u = edgeList->edges_array[i].src;
        t4 = (u >> 0)  & 0xff;
        sorted_edges_array[graph->vertex_count[3*buckets + t4]++] = edgeList->edges_array[i];
    }

    for (i = 0; i < num_edges; i++) {
        u = sorted_edges_array[i].src;
        t3 = (u >> 8)  & 0xff;
        edgeList->edges_array[graph->vertex_count[2*buckets + t3]++] = sorted_edges_array[i];
    }

    for (i = 0; i < num_edges; i++) {
        u = edgeList->edges_array[i].src;
        t2 = (u >> 16) & 0xff;
        sorted_edges_array[graph->vertex_count[1*buckets + t2]++] = edgeList->edges_array[i];
    }

    for (i = 0; i < num_edges; i++) {
        u = sorted_edges_array[i].src;
        t1 = (u >> 24) & 0xff;
        edgeList->edges_array[graph->vertex_count[0*buckets + t1]++] = sorted_edges_array[i];
    }




	freeEdgeArray(sorted_edges_array);

    #if DIRECTED
    
    if(inverse)
        graph->inverse_sorted_edges_array = edgeList->edges_array;
    else
        graph->sorted_edges_array = edgeList->edges_array;

    #else
        graph->sorted_edges_array = edgeList->edges_array;
    #endif

    // sorted_edges_array = edgeList->edges_array;

    // struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    // Start(timer);


    graph = mapVertices (graph, inverse);
    // graph = mapVerticesWithInOutDegree (graph);
    // Stop(timer);
    // printf("Map vertices to sorted Edge List : %f Seconds \n",Seconds(timer));
    

	// graph = mapVertices (graph);

	// printf("DONE Radix Sort Edges By Source \n");
	// graphPrint(graph);


	return graph;

} 




