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
	
    
	printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, ++graph->processed_nodes , Seconds(timer_inner));

    Start(timer);
	while(!isEmptyArrayStack(sharedFrontierStack)){ // start while 

		if(mf > (mu/alpha)){

			Start(timer_inner);
			arrayStackToBitmap(sharedFrontierStack,bitmapCurr);
			nf = sizeArrayStack(sharedFrontierStack);
			Stop(timer_inner);
			printf("| E  %-12s | %-15s | %-15f | \n"," ", " " , Seconds(timer_inner));

			do{
				Start(timer_inner);
				nf_prev = nf;
				nf = bottomUpStepDFSGraphCSR(graph,bitmapCurr,bitmapNext);
				swapBitmaps(&bitmapCurr, &bitmapNext);
				clearBitmap(bitmapNext);
				Stop(timer_inner);

				//stats collection
				inner_time +=  Seconds(timer_inner);
				graph->processed_nodes += nf;
				printf("| BU %-12u | %-15u | %-15f | \n",graph->iteration++, nf , Seconds(timer_inner));
			
			}while(( nf > nf_prev) || // growing;
				   ( nf > (n/beta)));

			Start(timer_inner);
			bitmapToArrayStack(bitmapCurr,sharedFrontierStack,localFrontierStacks);
			Stop(timer_inner);
			printf("| C  %-12s | %-15s | %-15f | \n"," ", " " , Seconds(timer_inner));

			mf = 1;

		}
		else{
			
			Start(timer_inner);
			mu -= mf;		
			mf = topDownStepDFSGraphCSR(graph, sharedFrontierStack,localFrontierStacks);
			slideWindowArrayStack(sharedFrontierStack);
			Stop(timer_inner);

			//stats collection
			inner_time +=  Seconds(timer_inner);
			graph->processed_nodes += sharedFrontierStack->tail - sharedFrontierStack->head;;
			printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, sharedFrontierStack->tail - sharedFrontierStack->head, Seconds(timer_inner));

		}



	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes, inner_time);
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


// top-down-step(graph, sharedFrontierStack, next, parents)
// 	for v ∈ sharedFrontierStack do
// 		for u ∈ neighbors[v] do
// 			if parents[u] = -1 then
// 				parents[u] ← v
// 				next ← next ∪ {u}
// 			end if
// 		end for
// 	end for

__u32 topDownStepDFSGraphCSR(struct GraphCSR* graph, struct ArrayStack* sharedFrontierStack, struct ArrayStack** localFrontierStacks){


	
	__u32 v;
	__u32 u;
	__u32 i;
	__u32 j;
	__u32 edge_idx;
	__u32 mf = 0;


	#pragma omp parallel default (none) private(u,v,j,i,edge_idx) shared(localFrontierStacks,graph,sharedFrontierStack,mf)
  	{
  		__u32 t_id = omp_get_thread_num();
  		struct ArrayStack* localFrontierQueue = localFrontierStacks[t_id];
		
  		
  		#pragma omp for reduction(+:mf) schedule(auto)
		for(i = sharedFrontierStack->head ; i < sharedFrontierStack->tail; i++){
			v = sharedFrontierStack->Stack[i];
			edge_idx = graph->vertices[v].edges_idx;

	    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
	         
	            u = graph->sorted_edge_array[j];
	            int u_parent = graph->parents[u]; 
	            if(u_parent < 0 ){
				if(__sync_bool_compare_and_swap(&graph->parents[u],u_parent,v))
					{ 
	                pushArrayStack(localFrontierQueue, u);
	                mf +=  -(u_parent);
	          	  }
	        	}
	        }

		} 

		flushArrayStackToShared(localFrontierQueue,sharedFrontierStack);
	}
	
	return mf;
}


// bottom-up-step(graph, sharedFrontierStack, next, parents) //pull
// 	for v ∈ vertices do
// 		if parents[v] = -1 then
// 			for u ∈ neighbors[v] do
// 				if u ∈ sharedFrontierStack then
// 				parents[v] ← u
// 				next ← next ∪ {v}
// 				break
// 				end if
// 			end for
// 		end if
// 	end for

__u32 bottomUpStepDFSGraphCSR(struct GraphCSR* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext){


	__u32 v;
	__u32 u;
	__u32 j;
	__u32 edge_idx;
	__u32 out_degree;
	struct Vertex* vertices = NULL;
	__u32* sorted_edges_array = NULL;

	// __u32 processed_nodes = bitmapCurr->numSetBits;
    __u32 nf = 0; // number of vertices in sharedFrontierStack
    // graph->processed_nodes += processed_nodes;

    #if DIRECTED
		vertices = graph->inverse_vertices;
		sorted_edges_array = graph->inverse_sorted_edge_array;
	#else
		vertices = graph->vertices;
		sorted_edges_array = graph->sorted_edge_array;
	#endif

	#pragma omp parallel for default(none) private(j,u,v,out_degree,edge_idx) shared(bitmapCurr,bitmapNext,graph,vertices,sorted_edges_array) reduction(+:nf) schedule(dynamic, 1024)
	for(v=0 ; v < graph->num_vertices ; v++){
				out_degree = vertices[v].out_degree;
				if(graph->parents[v] < 0){ // optmization 
					edge_idx = vertices[v].edges_idx;

		    		for(j = edge_idx ; j < (edge_idx + out_degree) ; j++){
		    			 u = sorted_edges_array[j];
		    			 if(getBit(bitmapCurr, u)){
		    			 	graph->parents[v] = u;
		    			 	setBit(bitmapNext, v);
		    			 	nf++;
		    			 	break;
		    			 }
		    		}

		    	}
    	
	}
	return nf;
}

