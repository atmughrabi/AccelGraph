#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include <limits.h> //UINT_MAX


#include "sortRun.h"
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

__u32 bellmanFordAtomicMin(__u32 *dist , __u32 newValue){

	__u32 oldValue;
	__u32 flag = 0;

	do{

		oldValue = *dist;
		if(oldValue > newValue){
			if(__sync_bool_compare_and_swap(dist, oldValue, newValue)){
	    		flag = 1;
	    	}
		}
		else{
			return 0;
		}
	}while(!flag);

	return 1;
}

__u32 bellmanFordCompareDistanceArrays(struct BellmanFordStats* stats1, struct BellmanFordStats* stats2){

	__u32 v=0;


	for(v =0 ; v< stats1->num_vertices ; v++){

		if(stats1->Distances[v] != stats2->Distances[v]){

			return 0;
		}
		// else if(stats1->Distances[v] != UINT_MAX/2)


	}

	return 1;

}

int bellmanFordAtomicRelax(struct Edge* edge, struct BellmanFordStats* stats, struct Bitmap* bitmapNext){
	__u32 oldParent, newParent;
	__u32 oldDistanceV = UINT_MAX/2;
	__u32 oldDistanceU = UINT_MAX/2;
	__u32 newDistance = UINT_MAX/2;
	__u32 flagu = 0;
	__u32 flagv = 0;
	__u32 flagp = 0;
	__u32 activeVertices = 0;

    do {

    flagu = 0;
	flagv = 0;
	flagp = 0;

     
    oldDistanceV = stats->Distances[edge->src];
    oldDistanceU = stats->Distances[edge->dest];
    oldParent = stats->parents[edge->dest];
    newDistance = oldDistanceV + edge->weight;

	    if( oldDistanceU > newDistance ){

	    	newParent = edge->src;
	    	newDistance = oldDistanceV + edge->weight;

	    	if(__sync_bool_compare_and_swap(&(stats->Distances[edge->src]), oldDistanceV, oldDistanceV)){
	    		flagv = 1;
	    	}

	    	if(__sync_bool_compare_and_swap(&(stats->Distances[edge->dest]), oldDistanceU, newDistance) && flagv){
	    		flagu = 1;
	    	}

	    	if(__sync_bool_compare_and_swap(&(stats->parents[edge->dest]), oldParent, newParent) && flagv && flagu){
	    		flagp = 1;
	    	}
	    	
    		if(!getBit(bitmapNext, edge->dest) && flagv && flagu && flagp){
			 	setBitAtomic(bitmapNext, edge->dest);
			 	activeVertices++; 	
			}

	    }
	    else{
	    	return activeVertices;
	    }

    } while (!flagu || !flagv || !flagp);


    return activeVertices;

}



int bellmanFordRelax(struct Edge* edge, struct BellmanFordStats* stats, struct Bitmap* bitmapNext){
	
	__u32 activeVertices = 0;
	__u32 newDistance = stats->Distances[edge->src] + edge->weight;

  	if( stats->Distances[edge->dest] > newDistance ){


		stats->Distances[edge->dest] = newDistance;
		stats->parents[edge->dest] = edge->src;	
		
		if(!getBit(bitmapNext, edge->dest)){
			activeVertices++;
		 	setBit(bitmapNext, edge->dest);	 	
		}
	}


    return activeVertices;

}

void bellmanFordPrintStats(struct BellmanFordStats* stats){
	__u32 v;

	for(v = 0; v < stats->num_vertices; v++){
   	
   	 if(stats->Distances[v] != UINT_MAX/2){

   	 	// printf("d %u \n", stats->Distances[v]);

   	 }
   	 

 	}


}


// -- To shuffle an array a of n elements (indices 0..n-1):
// for i from 0 to n−2 do
//      j ← random integer such that i ≤ j < n
//      exchange a[i] and a[j]


// used with Bannister, M. J.; Eppstein, D. (2012). Randomized speedup of the Bellman–Ford algorithm

void durstenfeldShuffle(__u32* vertices, __u32 size){

	__u32 v;
	for(v = 0; v < size; v++){
   		
   		__u32 idx = (genrand_int31() % (size-1));
   		__u32 temp = vertices[v];
   		vertices[v] = vertices[idx];
   		vertices[idx] = temp;

 	}

}


// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

void bellmanFordGraphGrid(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphGrid* graph){


	struct BellmanFordStats* stats1 = bellmanFordPushColumnGraphGrid(source, iterations, graph);
	struct BellmanFordStats* stats2 = bellmanFordPullRowGraphGrid(source, iterations, graph);
	// struct BellmanFordStats* stats3 = bellmanFordRandomizedDataDrivenPushGraphCSR(source, iterations, graph);

	if(bellmanFordCompareDistanceArrays( stats1, stats2)){
		printf("Match!!\n");
	}else{
		printf("NOT Match!!\n");
	}

	switch (pushpull)
      { 
        case 0: // push
        	bellmanFordPushColumnGraphGrid(source, iterations, graph);
        break;
        case 1: // pull
            bellmanFordPullRowGraphGrid(source, iterations, graph);
        break;
        default:// push
           	bellmanFordPushColumnGraphGrid(source, iterations, graph);
        break;          
      }

}
struct BellmanFordStats* bellmanFordPullRowGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph){

	__u32 v;
	__u32 u;
	__u32 n;
	__u32 * vertices;
	__u32 * degrees;
	__u32 iter = 0;
	__u32 totalPartitions  = graph->grid->num_partitions;
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
        stats->Distances = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        stats->Distances  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif
	
  	// printf(" -----------------------------------------------------\n");
    // printf("| %-51s | \n", "Starting Bellman-Ford Algorithm ROW-WISE DD (Source)");
    // printf(" -----------------------------------------------------\n");
    // printf("| %-51u | \n", source);
    // printf(" -----------------------------------------------------\n");
    // printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    // printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		// printf(" -----------------------------------------------------\n");
    	// printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	// printf(" -----------------------------------------------------\n");
		return;
	}

    graphCSRReset(graph);

    Start(timer);

    Start(timer_inner);
    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   	
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

	// printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer_inner));
	// printf(" -----------------------------------------------------\n");

	for(iter = 0; iter < iterations; iter++){
		Start(timer_inner);
		stats->processed_nodes += activeVertices;
		activeVertices = 0;
    	
	 __u32 i;
      #pragma omp parallel for private(i) reduction(+ : activeVertices) schedule (dynamic,8)
      for (i = 0; i < totalPartitions; ++i){ // iterate over partitions rowwise
        __u32 j;
        // #pragma omp parallel for private(j) 
        for (j = 0; j < totalPartitions; ++j){
            __u32 k;
            __u32 src;
            // __u32 dest;
            // __u32 weight;
            struct Partition* partition = &graph->grid->partitions[(i*totalPartitions)+j];
            for (k = 0; k < partition->num_edges; ++k){
                src  = partition->edgeList->edges_array[k].src;
                // dest = partition->edgeList->edges_array[k].dest;
                // weight = partition->edgeList->edges_array[k].weight;

                if(getBit(bitmapCurr, src)){
                if(numThreads == 1)
	        		activeVertices += bellmanFordRelax(&(partition->edgeList->edges_array[k]), stats, bitmapNext);
	        	else
	        		activeVertices += bellmanFordAtomicRelax(&(partition->edgeList->edges_array[k]), stats, bitmapNext);
            	}
          	}
        }
      }


		swapBitmaps(&bitmapCurr, &bitmapNext);
		clearBitmap(bitmapNext);

		Stop(timer_inner);
		
    	// printf("| %-15u | %-15u | %-15f | \n",iter, activeVertices, Seconds(timer_inner));
	    if(activeVertices == 0)
	      break;
	}
  	
	
	Stop(timer);
	stats->time_total += Seconds(timer);
	// printf(" -----------------------------------------------------\n");
	// printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	// printf(" -----------------------------------------------------\n");


 
  free(timer);
  free(timer_inner);

  // bellmanFordPrintStats(stats);
  return stats;


}
struct BellmanFordStats* bellmanFordPushColumnGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph){

	__u32 v;
	__u32 u;
	__u32 n;
	__u32 * vertices;
	__u32 * degrees;
	__u32 iter = 0;
	__u32 totalPartitions  = graph->grid->num_partitions;
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
        stats->Distances = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        stats->Distances  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif
	
  	// printf(" -----------------------------------------------------\n");
    // printf("| %-51s | \n", "Starting Bellman-Ford Algorithm COL-WISE DD (Source)");
    // printf(" -----------------------------------------------------\n");
    // printf("| %-51u | \n", source);
    // printf(" -----------------------------------------------------\n");
    // printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    // printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		// printf(" -----------------------------------------------------\n");
    	// printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	// printf(" -----------------------------------------------------\n");
		return;
	}

    graphCSRReset(graph);

    Start(timer);

    Start(timer_inner);
    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   	
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

	// printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer_inner));
	// printf(" -----------------------------------------------------\n");

	for(iter = 0; iter < iterations; iter++){
		Start(timer_inner);
		stats->processed_nodes += activeVertices;
		activeVertices = 0;
    	
	 __u32 j;
      #pragma omp parallel for private(j) reduction(+ : activeVertices) schedule (dynamic,8)
      for (j = 0; j < totalPartitions; ++j){ // iterate over partitions colwise
        __u32 i;
        // #pragma omp parallel for private(j) 
        for (i = 0; i < totalPartitions; ++i){
            __u32 k;
            __u32 src;
            // __u32 dest;
            // __u32 weight;
            struct Partition* partition = &graph->grid->partitions[(i*totalPartitions)+j];
            for (k = 0; k < partition->num_edges; ++k){
                src  = partition->edgeList->edges_array[k].src;
                // dest = partition->edgeList->edges_array[k].dest;
                // weight = partition->edgeList->edges_array[k].weight;

                if(getBit(bitmapCurr, src)){
                if(numThreads == 1)
	        		activeVertices += bellmanFordRelax(&(partition->edgeList->edges_array[k]), stats, bitmapNext);
	        	else
	        		activeVertices += bellmanFordAtomicRelax(&(partition->edgeList->edges_array[k]), stats, bitmapNext);
            	}
          	}
        }
      }


		swapBitmaps(&bitmapCurr, &bitmapNext);
		clearBitmap(bitmapNext);

		Stop(timer_inner);
		
    	// printf("| %-15u | %-15u | %-15f | \n",iter, activeVertices, Seconds(timer_inner));
	    if(activeVertices == 0)
	      break;
	}
  	
	
	Stop(timer);
	stats->time_total += Seconds(timer);
	// printf(" -----------------------------------------------------\n");
	// printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	// printf(" -----------------------------------------------------\n");


 
  free(timer);
  free(timer_inner);

  // bellmanFordPrintStats(stats);
  return stats;


}

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void bellmanFordSpiltGraphCSR(struct GraphCSR* graph, struct GraphCSR** graphPlus, struct GraphCSR** graphMinus){

// The first subset, Ef, contains all edges (vi, vj) such that i < j; the second, Eb, contains edges (vi, vj) such that i > j.

	//calculate the size of each edge array
	__u32 edgesPlusCounter = 0;
	__u32 edgesMinusCounter = 0;
	__u32 e;
	__u32 src;
	__u32 dest;

	#pragma omp parallel for private(e) shared(graph) reduction(+:edgesPlusCounter,edgesMinusCounter)
	for(e =0 ; e < graph->num_edges ; e++){

		 src  = graph->sorted_edges_array[e].src;
		 dest = graph->sorted_edges_array[e].dest;
		if(src <= dest){
			edgesPlusCounter++;
		}
		else if (src > dest){
			edgesMinusCounter++;
		}
	}

	*graphPlus = graphCSRNew(graph->num_vertices, edgesPlusCounter, 1);
	*graphMinus =  graphCSRNew(graph->num_vertices, edgesMinusCounter, 1);

	struct EdgeList* edgesPlus = newEdgeList(edgesPlusCounter);
	struct EdgeList* edgesMinus = newEdgeList(edgesMinusCounter);

	
	edgesPlus->num_vertices = graph->num_vertices;
	edgesMinus->num_vertices = graph->num_vertices;

	__u32 edgesPlus_idx = 0;
	__u32 edgesMinus_idx = 0;

	#pragma omp parallel for private(e) shared(edgesMinus_idx,edgesPlus_idx, edgesPlus,edgesMinus,graph)
	for(e =0 ; e < graph->num_edges ; e++){

		 src  = graph->sorted_edges_array[e].src;
		 dest = graph->sorted_edges_array[e].dest;
		if(src <= dest){
			edgesPlus->edges_array[__sync_fetch_and_add(&edgesPlus_idx,1)] = graph->sorted_edges_array[e];
		}
		else if (src > dest){
			edgesMinus->edges_array[__sync_fetch_and_add(&edgesMinus_idx,1)] = graph->sorted_edges_array[e];
		}
	}

	

	edgesPlus = sortRunAlgorithms(edgesPlus ,0);
	edgesMinus = sortRunAlgorithms(edgesMinus ,0);

	graphCSRAssignEdgeList ((*graphPlus),edgesPlus,0); 
	graphCSRAssignEdgeList ((*graphMinus),edgesMinus,0); 


}

void bellmanFordGraphCSR(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph){

	// struct BellmanFordStats* stats1 = bellmanFordDataDrivenPushGraphCSR(source, iterations, graph);
	// struct BellmanFordStats* stats2 = bellmanFordDataDrivenPullGraphCSR(source, iterations, graph);
	// struct BellmanFordStats* stats3 = bellmanFordRandomizedDataDrivenPushGraphCSR(source, iterations, graph);

	// if(bellmanFordCompareDistanceArrays( stats1, stats3) && bellmanFordCompareDistanceArrays( stats1, stats2)){
		// printf("Match!!\n");
	// }else{
		// printf("NOT Match!!\n");
	// }


	switch (pushpull)
      { 
        case 0: // push
        	bellmanFordDataDrivenPushGraphCSR(source, iterations, graph);
        break;
        case 1: // pull
            bellmanFordDataDrivenPullGraphCSR(source, iterations, graph);
        break;
        case 2: // randomized push
            bellmanFordRandomizedDataDrivenPushGraphCSR(source, iterations, graph);
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
        stats->Distances = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        stats->Distances  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif

  
    struct Vertex* vertices = NULL;
	struct Edge*  sorted_edges_array = NULL;

 	#if DIRECTED
		vertices = graph->inverse_vertices;
		sorted_edges_array = graph->inverse_sorted_edges_array;
	#else
		vertices = graph->vertices;
		sorted_edges_array = graph->sorted_edges_array;
	#endif

	
  	// printf(" -----------------------------------------------------\n");
    // printf("| %-51s | \n", "Starting Bellman-Ford Algorithm Pull DD (Source)");
    // printf(" -----------------------------------------------------\n");
    // printf("| %-51u | \n", source);
    // printf(" -----------------------------------------------------\n");
    // printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    // printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		// printf(" -----------------------------------------------------\n");
    	// printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	// printf(" -----------------------------------------------------\n");
		return;
	}

    graphCSRReset(graph);

    Start(timer);

    Start(timer_inner);
    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   
   	 stats->Distances[v] = UINT_MAX/2;
   	 stats->parents[v] = UINT_MAX;

 	}

 	setBit(bitmapNext,source);
    bitmapNext->numSetBits++;
	stats->parents[source] = source;
	stats->Distances[source] = 0;

	__u32 degree = graph->vertices[source].out_degree;
  	__u32 edge_idx = graph->vertices[source].edges_idx;
  	__u32 j;
  	 for(v = edge_idx ; v < (edge_idx + degree) ; v++){

  	 __u32 t = graph->sorted_edges_array[v].dest;
  	 stats->parents[t] = source;
  	 bitmapNext->numSetBits++;
  	 setBit(bitmapNext,t);
  	 activeVertices++;

  	 }

	swapBitmaps(&bitmapCurr, &bitmapNext);
	clearBitmap(bitmapNext);
	activeVertices++;

	Stop(timer_inner);

	// printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer_inner));
	// printf(" -----------------------------------------------------\n");

	for(iter = 0; iter < iterations; iter++){
		Start(timer_inner);
		stats->processed_nodes += activeVertices;
		activeVertices = 0;
    	

    	#pragma omp parallel for private(v) shared(vertices,sorted_edges_array,graph,stats,bitmapNext,bitmapCurr) reduction(+ : activeVertices) schedule (dynamic,128)
    	for(v = 0; v < graph->num_vertices; v++){

    		__u32 minDistance = UINT_MAX/2;
    		__u32 degree;
    		__u32 j,u,w;
    		__u32 edge_idx;

    		if(getBit(bitmapCurr, v)){

    			degree = vertices[v].out_degree;
		      	edge_idx = vertices[v].edges_idx;
		      	
		      	for(j = edge_idx ; j < (edge_idx + degree) ; j++){
		      	 	u = sorted_edges_array[j].dest;
		      	 	w = sorted_edges_array[j].weight;

		      	 	if (minDistance > (stats->Distances[u] + w)){
		      	 		minDistance = (stats->Distances[u] + w);
		      	 	}
		        }




		        if(bellmanFordAtomicMin(&(stats->Distances[v]) , minDistance)){
		        	// stats->Distances[v] = minDistance;

		        	degree = graph->vertices[v].out_degree;
			      	edge_idx = graph->vertices[v].edges_idx;
			      	
			      	for(j = edge_idx ; j < (edge_idx + degree) ; j++){
			      	 	u = graph->sorted_edges_array[j].dest;
			      	 	w = graph->sorted_edges_array[j].weight;


						if(!getBit(bitmapNext, u)){
							activeVertices++;
						 	setBit(bitmapNext, u);	 	
						}		      	 	
			        }
		        }
    		}  
		}


		swapBitmaps(&bitmapCurr, &bitmapNext);
		clearBitmap(bitmapNext);

		Stop(timer_inner);



    	// printf("| %-15u | %-15u | %-15f | \n",iter, activeVertices, Seconds(timer_inner));
	    if(activeVertices == 0)
	      break;
	}
  	
	
	Stop(timer);
	stats->time_total = Seconds(timer);
	// printf(" -----------------------------------------------------\n");
	// printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	// printf(" -----------------------------------------------------\n");


 
  free(timer);
  free(timer_inner);



  // bellmanFordPrintStats(stats);
  return stats;


}



struct BellmanFordStats* bellmanFordDataDrivenPushGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph){

	__u32 v;
	__u32 u;
	__u32 n;

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
   

        stats->Distances = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
     

        stats->Distances  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif
	
  	// printf(" -----------------------------------------------------\n");
    // printf("| %-51s | \n", "Starting Bellman-Ford Algorithm Push DD (Source)");
    // printf(" -----------------------------------------------------\n");
    // printf("| %-51u | \n", source);
    // printf(" -----------------------------------------------------\n");
    // printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    // printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		// printf(" -----------------------------------------------------\n");
    	// printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	// printf(" -----------------------------------------------------\n");
		return;
	}

    graphCSRReset(graph);

    Start(timer);

    Start(timer_inner);
    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
  
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

	// printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer_inner));
	// printf(" -----------------------------------------------------\n");

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

		      	 	// graph->sorted_edges_array[j].weight = 1;
		        	if(numThreads == 1)
		        		activeVertices += bellmanFordRelax(&(graph->sorted_edges_array[j]), stats, bitmapNext);
		        	else
		        		activeVertices += bellmanFordAtomicRelax(&(graph->sorted_edges_array[j]), stats, bitmapNext);
		        }

    		}  
		}


		swapBitmaps(&bitmapCurr, &bitmapNext);
		clearBitmap(bitmapNext);

		Stop(timer_inner);
		
    	// printf("| %-15u | %-15u | %-15f | \n",iter, activeVertices, Seconds(timer_inner));
	    if(activeVertices == 0)
	      break;
	}
  	
	
	Stop(timer);
	stats->time_total += Seconds(timer);
	// printf(" -----------------------------------------------------\n");
	// printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	// printf(" -----------------------------------------------------\n");


 
  free(timer);
  free(timer_inner);
 


  // bellmanFordPrintStats(stats);
  return stats;
}


// Randomized Speedup of the Bellman–Ford Algorithm

// number the vertices randomly such that all permutations with s first are equally likely
// 	C ← {s}
// 		while C 6= ∅ do
// 			for each vertex u in numerical order do
// 				if u ∈ C or D[v] has changed since start of iteration then
// 					for each edge uv in graph G+ do
// 						relax(u, v)
// for each vertex u in reverse numerical order do
// 	if u ∈ C or D[v] has changed since start of iteration then
// 		for each edge uv in graph G− do
// 			relax(u, v)
// C ← {vertices v for which D[v] changed}

struct BellmanFordStats* bellmanFordRandomizedDataDrivenPushGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph){

	__u32 v;
	__u32 u;
	__u32 n;
	__u32 * vertices;
	__u32 * degrees;
	__u32 iter = 0;
	struct GraphCSR* graphPlus = NULL;
	struct GraphCSR* graphMinus = NULL;

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
	
  	// printf(" -----------------------------------------------------\n");
    // printf("| %-51s | \n", "Starting Bellman-Ford Algorithm Push DD");
    // printf("| %-51s | \n", "Randomized G+/G- optimization (Source)");
    // printf(" -----------------------------------------------------\n");
    // printf("| %-51u | \n", source);
    // printf(" -----------------------------------------------------\n");
    // printf("| %-51s | \n", "Start Split G+/G-");
    // printf(" -----------------------------------------------------\n");
    Start(timer_inner);
    bellmanFordSpiltGraphCSR(graph, &graphPlus, &graphMinus);
    Stop(timer_inner);
    // printf("| %-51f | \n",  Seconds(timer_inner));
    // printf(" -----------------------------------------------------\n");

    // printf(" -----------------------------------------------------\n");
    // printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    // printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		// printf(" -----------------------------------------------------\n");
    	// printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	// printf(" -----------------------------------------------------\n");
		return;
	}

    graphCSRReset(graph);

    Start(timer);

    

    Start(timer_inner);

  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   	 vertices[v]= v;
   	 degrees[v] = graph->vertices[v].out_degree;

   	 stats->Distances[v] = UINT_MAX/2;
   	 stats->parents[v] = UINT_MAX;

 	}

 	//randomize iteratiing accross verticess

 	durstenfeldShuffle(vertices, graph->num_vertices);

 	setBit(bitmapNext,source);
    bitmapNext->numSetBits = 1;
	stats->parents[source] = source;
	stats->Distances[source] = 0;

	swapBitmaps(&bitmapCurr, &bitmapNext);
	clearBitmap(bitmapNext);
	activeVertices++;

	Stop(timer_inner);

	// printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer_inner));
	// printf(" -----------------------------------------------------\n");

	for(iter = 0; iter < iterations; iter++){
		Start(timer_inner);
		stats->processed_nodes += activeVertices;
		activeVertices = 0;
    	

    	#pragma omp parallel for private(v,n) shared(vertices,graphPlus,stats,bitmapNext,bitmapCurr) reduction(+ : activeVertices) schedule (dynamic,128)
    	for(n = 0; n < graphPlus->num_vertices; n++){

    		v = vertices[n];

    		if(getBit(bitmapCurr, v)){

    			__u32 degree = graphPlus->vertices[v].out_degree;
		      	__u32 edge_idx = graphPlus->vertices[v].edges_idx;
		      	__u32 j;
		      	 for(j = edge_idx ; j < (edge_idx + degree) ; j++){
		      	 	__u32 u = graphPlus->sorted_edges_array[j].dest;
		      	 	__u32 w = graphPlus->sorted_edges_array[j].weight;

		      	 	// graph->sorted_edges_array[j].weight = 1;
		        	if(numThreads == 1)
		        		activeVertices += bellmanFordRelax(&(graphPlus->sorted_edges_array[j]), stats, bitmapNext);
		        	else
		        		activeVertices += bellmanFordAtomicRelax(&(graphPlus->sorted_edges_array[j]), stats, bitmapNext);
		        }

    		}  
		}

		#pragma omp parallel for private(v,n) shared(vertices,graphMinus,stats,bitmapNext,bitmapCurr) reduction(+ : activeVertices) schedule (dynamic,128)
    	for(n = 0; n < graphMinus->num_vertices; n++){

    		v = vertices[n];

    		if(getBit(bitmapCurr, v)){

    			__u32 degree = graphMinus->vertices[v].out_degree;
		      	__u32 edge_idx = graphMinus->vertices[v].edges_idx;
		      	__u32 j;
		      	 for(j = edge_idx ; j < (edge_idx + degree) ; j++){
		      	 	__u32 u = graphMinus->sorted_edges_array[j].dest;
		      	 	__u32 w = graphMinus->sorted_edges_array[j].weight;

		      	 	// graph->sorted_edges_array[j].weight = 1;
		        	if(numThreads == 1)
		        		activeVertices += bellmanFordRelax(&(graphMinus->sorted_edges_array[j]), stats, bitmapNext);
		        	else
		        		activeVertices += bellmanFordAtomicRelax(&(graphMinus->sorted_edges_array[j]), stats, bitmapNext);
		        }

    		}  
		}


		swapBitmaps(&bitmapCurr, &bitmapNext);
		clearBitmap(bitmapNext);

		Stop(timer_inner);
		
    	// printf("| %-15u | %-15u | %-15f | \n",iter, activeVertices, Seconds(timer_inner));
	    if(activeVertices == 0)
	      break;
	}
  	
	
	Stop(timer);
	stats->time_total += Seconds(timer);
	// printf(" -----------------------------------------------------\n");
	// printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	// printf(" -----------------------------------------------------\n");


 
  free(timer);
  free(timer_inner);
  free(vertices);
  free(degrees);
  // graphCSRFree(graphPlus);
  // graphCSRFree(graphMinus);


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
