#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayStack.h"
#include "bitmap.h"
#include "DFS.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"



// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************



// depth-first-search(graph, source)
// 	sharedFrontierStack ← {source}
// 	next ← {}
// 	parents ← [-1,-1,. . . -1]
// 		while sharedFrontierStack 6= {} do
// 			top-down-step(graph, sharedFrontierStack, next, parents)
// 			sharedFrontierStack ← next
// 			next ← {}
// 		end while
// 	return parents

void depthFirstSearchGraphCSRBase(__u32 source, struct GraphCSR* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
	double inner_time = 0;
	struct ArrayStack* sharedFrontierStack = newArrayStack(graph->num_vertices);
	struct Bitmap* bitmapCurr = newBitmap(graph->num_vertices);
    struct Bitmap* bitmapNext = newBitmap(graph->num_vertices);

	__u32 P = numThreads;
	__u32 mu = graph->num_edges; // number of edges to check from sharedFrontierStack
	__u32 mf = graph->vertices[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in sharedFrontierStack
	__u32 nf_prev = 0; // number of vertices in sharedFrontierStack
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 15;
	__u32 beta = 18;

	#if ALIGNED
		struct ArrayStack** localFrontierStacks = (struct ArrayStack**) my_aligned_malloc( P * sizeof(struct ArrayStack*));
	#else
        struct ArrayStack** localFrontierStacks = (struct ArrayStack**) my_malloc( P * sizeof(struct ArrayStack*));
    #endif

   __u32 i;
   for(i=0 ; i < P ; i++){
		localFrontierStacks[i] = newArrayStack(graph->num_vertices);
		
   }

  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source < 0 && source > graph->num_vertices){
		printf(" -----------------------------------------------------\n");
    	printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	printf(" -----------------------------------------------------\n");
		return;
	}

	graphCSRReset(graph);

  	Start(timer_inner);
	pushArrayStack(sharedFrontierStack, source);
    // setBit(sharedFrontierStack->q_bitmap,source);
	graph->parents[source] = source;  
	Stop(timer_inner);
	inner_time +=  Seconds(timer_inner);
	// graph->vertices[source].visited = 1;
	
    
	printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, graph->processed_nodes , Seconds(timer_inner));

    Start(timer);
	while(!isEmptyArrayStackCurr(sharedFrontierStack)){ // start while 

		 
			
			__u32 v = popArrayStack(sharedFrontierStack);

			graph->processed_nodes++;
			__u32 edge_idx = graph->vertices[v].edges_idx;
			__u32 j;

	    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
	         
	            __u32 u = graph->sorted_edge_array[j];
	            int u_parent = graph->parents[u]; 
	            if(u_parent < 0 ){
					graph->parents[u] = v;
	                pushArrayStack(sharedFrontierStack, u);
	        	}
	        }


	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes,  Seconds(timer));
	printf(" -----------------------------------------------------\n");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", graph->processed_nodes, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	graphCSRReset(graph);
	for(i=0 ; i < P ; i++){
		freeArrayStack(localFrontierStacks[i]);		
   	}
   	free(localFrontierStacks);
	freeArrayStack(sharedFrontierStack);
	freeBitmap(bitmapNext);
	freeBitmap(bitmapCurr);
	free(timer);
	free(timer_inner);
}



void depthFirstSearchGraphCSR(__u32 source, struct GraphCSR* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
	double inner_time = 0;
	struct ArrayStack* sharedFrontierStack = newArrayStack(graph->num_vertices);
	struct Bitmap* bitmapCurr = newBitmap(graph->num_vertices);
    struct Bitmap* bitmapNext = newBitmap(graph->num_vertices);

	__u32 P = numThreads;
	__u32 mu = graph->num_edges; // number of edges to check from sharedFrontierStack
	__u32 mf = graph->vertices[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in sharedFrontierStack
	__u32 nf_prev = 0; // number of vertices in sharedFrontierStack
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 15;
	__u32 beta = 18;

	#if ALIGNED
		struct ArrayStack** localFrontierStacks = (struct ArrayStack**) my_aligned_malloc( P * sizeof(struct ArrayStack*));
	#else
        struct ArrayStack** localFrontierStacks = (struct ArrayStack**) my_malloc( P * sizeof(struct ArrayStack*));
    #endif

   __u32 i;
   for(i=0 ; i < P ; i++){
		localFrontierStacks[i] = newArrayStack(graph->num_vertices);
		
   }

  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source < 0 && source > graph->num_vertices){
		printf(" -----------------------------------------------------\n");
    	printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	printf(" -----------------------------------------------------\n");
		return;
	}

	graphCSRReset(graph);

  	Start(timer_inner);
	pushArrayStack(sharedFrontierStack, source);
    // setBit(sharedFrontierStack->q_bitmap,source);
	graph->parents[source] = source;  
	Stop(timer_inner);
	inner_time +=  Seconds(timer_inner);
	// graph->vertices[source].visited = 1;
	
    
	printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, graph->processed_nodes , Seconds(timer_inner));

    Start(timer);
	while(!isEmptyArrayStackCurr(sharedFrontierStack)){ // start while 

		 
			
			__u32 v = popArrayStack(sharedFrontierStack);

			graph->processed_nodes++;
			__u32 edge_idx = graph->vertices[v].edges_idx;
			__u32 j;

	    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
	         
	            __u32 u = graph->sorted_edge_array[j];
	            int u_parent = graph->parents[u]; 
	            if(u_parent < 0 ){
					graph->parents[u] = v;
	                pushArrayStack(sharedFrontierStack, u);
	        	}
	        }


	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes,  Seconds(timer));
	printf(" -----------------------------------------------------\n");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", graph->processed_nodes, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	graphCSRReset(graph);
	for(i=0 ; i < P ; i++){
		freeArrayStack(localFrontierStacks[i]);		
   	}
   	free(localFrontierStacks);
	freeArrayStack(sharedFrontierStack);
	freeBitmap(bitmapNext);
	freeBitmap(bitmapCurr);
	free(timer);
	free(timer_inner);
}

