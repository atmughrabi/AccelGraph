#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include <limits.h> //UINT_MAX

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "bitmap.h"
#include "bellmanFord.h"


#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


// ********************************************************************************************
// ***************					Auxiliary functions  	  					 **************
// ********************************************************************************************

struct BellmanFordStats* newBellmanFordStatst( __u32 num_vertices){


}
void bellmanFordRelax(struct Edge* edge, struct BellmanFordStats* stats){


}

void bellmanFordPrintStats(struct BellmanFordStats* stats){
	__u32 v;

	for(v = 0; v < stats->num_vertices; v++){
   	
   	 if(stats->Distances[v] != UINT_MAX/2){

   	 	printf("d %u \n", stats->Distances[v]);

   	 }
   	 

 	}


}


// -- To shuffle an array a of n elements (indices 0..n-1):
// for i from 0 to n−2 do
//      j ← random integer such that i ≤ j < n
//      exchange a[i] and a[j]


// used with Bannister, M. J.; Eppstein, D. (2012). Randomized speedup of the Bellman–Ford algorithm

void durstenfeldShuffle(__u32* vertices){


}


// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

void bellmanFordGraphGrid(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphGrid* graph){


}
struct BellmanFordStats* bellmanFordPullRowGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph){


}
struct BellmanFordStats* bellmanFordPushColumnGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph){


}

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void bellmanFordGraphCSR(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph){

	switch (pushpull)
      { 
        case 0: // push
        	bellmanFordDataDrivenPushGraphCSR(source, iterations, graph);
        break;
        case 1: // pull
            bellmanFordDataDrivenPullGraphCSR(source, iterations, graph);
        break;
        default:// push
           	bellmanFordDataDrivenPushGraphCSR(source, iterations, graph);
        break;          
      }


}

struct BellmanFordStats* bellmanFordDataDrivenPullGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph){

	__u32 v;
	__u32 u;
	__u32 n;
	__u32 * vertices;
	__u32 * degrees;

	iterations = graph->num_vertices - 1;

	struct BellmanFordStats* stats = (struct BellmanFordStats*) malloc(sizeof(struct BellmanFordStats));

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

	struct Bitmap* bitmapCurr = newBitmap(graph->num_vertices);
    struct Bitmap* bitmapNext = newBitmap(graph->num_vertices);
    int activeVertices = 0;

	#if ALIGNED
        vertices = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));

        stats->Distances = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        vertices = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));

        stats->Distances  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif
	
  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Bellman-Ford Algorithm Pull DD (Source)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		printf(" -----------------------------------------------------\n");
    	printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	printf(" -----------------------------------------------------\n");
		return;
	}

    graphCSRReset(graph);

    Start(timer);

    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   	 vertices[v]= v;
   	 degrees[v] = graph->vertices[v].out_degree;

   	 stats->Distances[v] = UINT_MAX;
   	 stats->parents[v] = UINT_MAX;

 	}

  	// vertices = radixSortEdgesByDegree(degrees, vertices, graph->num_vertices);    

    //initialize variables
    
	
	Stop(timer);

	printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer));
	printf(" -----------------------------------------------------\n");



}



struct BellmanFordStats* bellmanFordDataDrivenPushGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph){

	__u32 v;
	__u32 u;
	__u32 n;
	__u32 * vertices;
	__u32 * degrees;
	__u32 iter = 0;
	iterations = graph->num_vertices - 1;

	struct BellmanFordStats* stats = (struct BellmanFordStats*) malloc(sizeof(struct BellmanFordStats));
	stats->processed_nodes = 0;
	stats->time_total = 0.0;
	stats->num_vertices = graph->num_vertices;

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

	struct Bitmap* bitmapCurr = newBitmap(graph->num_vertices);
    struct Bitmap* bitmapNext = newBitmap(graph->num_vertices);
    int activeVertices = 0;

	#if ALIGNED
        vertices = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));

        stats->Distances = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        vertices = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));

        stats->Distances  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif
	
  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Bellman-Ford Algorithm Push DD (Source)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		printf(" -----------------------------------------------------\n");
    	printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	printf(" -----------------------------------------------------\n");
		return;
	}

    graphCSRReset(graph);

    Start(timer);

    Start(timer_inner);
    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   	 vertices[v]= v;
   	 degrees[v] = graph->vertices[v].out_degree;

   	 stats->Distances[v] = UINT_MAX/2;
   	 stats->parents[v] = UINT_MAX;

 	}

 	setBit(bitmapNext,source);
    bitmapNext->numSetBits = 1;
	stats->parents[source] = source;
	stats->Distances[source] = 0;

	swapBitmaps(&bitmapCurr, &bitmapNext);
	clearBitmap(bitmapNext);
	activeVertices++;

	Stop(timer_inner);

	printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer_inner));
	printf(" -----------------------------------------------------\n");

	for(iter = 0; iter < iterations; iter++){
		Start(timer_inner);
		stats->processed_nodes += activeVertices;
		activeVertices = 0;
    	

    	#pragma omp parallel for private(v) shared(graph,stats,bitmapNext,bitmapCurr) reduction(+ : activeVertices) schedule (dynamic,128)
    	for(v = 0; v < graph->num_vertices; v++){

    		if(getBit(bitmapCurr, v)){

    			__u32 degree = graph->vertices[v].out_degree;
		      	__u32 edge_idx = graph->vertices[v].edges_idx;
		      	__u32 j;
		      	 for(j = edge_idx ; j < (edge_idx + degree) ; j++){
		      	 	__u32 u = graph->sorted_edges_array[j].dest;
		      	 	__u32 w = graph->sorted_edges_array[j].weight;
		        	// relax step
		        	__u32 newDistance = UINT_MAX;

		        	#pragma omp atomic read
		        		newDistance = stats->Distances[v];
		        	
		        	newDistance += w;

		        	if(stats->Distances[u] > (newDistance)){

		        		#pragma omp atomic write
		        			stats->Distances[u] = newDistance;

		        		#pragma omp atomic write
		        			stats->parents[u] = v;
		        		
		        		activeVertices++;
		        		if(!getBit(bitmapNext, u)){
		    			 	setBitAtomic(bitmapNext, u);
		    			}
		        	}
		     	}
    		}  
		}


		swapBitmaps(&bitmapCurr, &bitmapNext);
		clearBitmap(bitmapNext);

		Stop(timer_inner);

    	printf("| %-15u | %-15u | %-15f | \n",iter, activeVertices, Seconds(timer_inner));
	    if(activeVertices == 0)
	      break;
	}
  	
	
	Stop(timer);
	stats->time_total = Seconds(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  
  free(timer);
  free(timer_inner);
  free(vertices);
  free(degrees);


  // bellmanFordPrintStats(stats);
  return stats;
}

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

void bellmanFordGraphAdjArrayList(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList* graph){


}


struct BellmanFordStats* bellmanFordDataDrivenPullGraphAdjArrayList(__u32 source,  __u32 iterations, struct GraphAdjArrayList* graph){


}
struct BellmanFordStats* bellmanFordDataDrivenPushGraphAdjArrayList(__u32 source,  __u32 iterations, struct GraphAdjArrayList* graph){


}

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************

void bellmanFordGraphAdjLinkedList(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList* graph){


}

struct BellmanFordStats* bellmanFordPullGraphAdjLinkedList(__u32 source,  __u32 iterations, struct GraphAdjLinkedList* graph){


}
struct BellmanFordStats* bellmanFordPushGraphAdjLinkedList(__u32 source,  __u32 iterations, struct GraphAdjLinkedList* graph){


}
