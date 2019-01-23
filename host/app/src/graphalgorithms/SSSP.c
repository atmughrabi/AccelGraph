
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
#include "SSSP.h"


#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// ********************************************************************************************
// ***************					Auxiliary functions  	  					 **************
// ********************************************************************************************

__u32 SSSPAtomicMin(__u32 *dist , __u32 newValue){

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

__u32 SSSPCompareDistanceArrays(struct SSSPStats* stats1, struct SSSPStats* stats2){

	__u32 v=0;


	for(v =0 ; v< stats1->num_vertices ; v++){

		if(stats1->Distances[v] != stats2->Distances[v]){

			return 0;
		}
		// else if(stats1->Distances[v] != UINT_MAX/2)


	}

	return 1;

}

int SSSPAtomicRelax(struct Edge* edge, struct SSSPStats* stats, struct Bitmap* bitmapNext, struct Bitmap* bitmapSet){
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
			 	setBitAtomic(bitmapSet, edge->dest);
			 	activeVertices++; 	
			}

	    }
	    else{
	    	return activeVertices;
	    }

    } while (!flagu || !flagv || !flagp);


    return activeVertices;

}



int SSSPRelax(struct Edge* edge, struct SSSPStats* stats){
	
	
	__u32 newDistance = stats->Distances[edge->src] + edge->weight;
	__u32 bucket = UINT_MAX/2;
	

  	if( stats->Distances[edge->dest] > newDistance ){

  		
  		if(stats->Distances[edge->dest] == UINT_MAX/2) // if bucket not assigned
  				stats->buckets_total++;

		stats->Distances[edge->dest] = newDistance;
		stats->parents[edge->dest] = edge->src;	

		bucket = newDistance / stats->delta;

		// if(stats->buckets_map[edge->dest] > bucket)
		stats->buckets_map[edge->dest] = bucket;

		if (bucket ==  stats->bucket_current)
			 stats->bucket_counter = 1;

	}

	// printf(" d %u b %u bc %u bt %u dist %u \n", edge->dest, stats->buckets_map[edge->dest], stats->bucket_current, stats->buckets_total, stats->Distances[edge->dest]);

    return stats->buckets_total;

}

void SSSPPrintStats(struct SSSPStats* stats){
	__u32 v;

	for(v = 0; v < stats->num_vertices; v++){
   	
   	 if(stats->Distances[v] != UINT_MAX/2){

   	 	printf("d %u \n", stats->Distances[v]);

   	 }
   	 

 	}


}

void SSSPPrintStatsDetails(struct SSSPStats* stats){
	__u32 v;
	__u32 minDistance = UINT_MAX/2;
	__u32 maxDistance = 0;
	__u32 numberOfDiscoverNodes = 0;


	#pragma omp parallel for reduction(max:maxDistance) reduction(+:numberOfDiscoverNodes) reduction(min:minDistance)
	for(v = 0; v < stats->num_vertices; v++){
   	
   	 if(stats->Distances[v] != UINT_MAX/2){

   	 	numberOfDiscoverNodes++;

   	 	if(minDistance >  stats->Distances[v] && stats->Distances[v] != 0)
   	 		minDistance = stats->Distances[v];

   	 	if(maxDistance < stats->Distances[v])
   	 		maxDistance = stats->Distances[v];


   	 }
   	
 	}

 	printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Min Dist", "Max Dist", " Discovered");
    printf(" -----------------------------------------------------\n");
	printf("| %-15u | %-15u | %-15u | \n",minDistance, maxDistance, numberOfDiscoverNodes);
	printf(" -----------------------------------------------------\n");


}

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void SSSPSpiltGraphCSR(struct GraphCSR* graph, struct GraphCSR** graphPlus, struct GraphCSR** graphMinus, __u32 delta){

// The first subset, Ef, contains all edges (vi, vj) such that i < j; the second, Eb, contains edges (vi, vj) such that i > j.

	//calculate the size of each edge array
	__u32 edgesPlusCounter = 0;
	__u32 edgesMinusCounter = 0;
	// __u32 numVerticesPlusCounter = 0;
	// __u32 numVerticesMinusCounter = 0;
	__u32 e;
	__u32 weight;
	// __u32 src;
	// __u32 dest;

	#pragma omp parallel for private(e,weight) shared(graph,delta) reduction(+:edgesPlusCounter,edgesMinusCounter)
	for(e =0 ; e < graph->num_edges ; e++){

		 // src  = graph->sorted_edges_array[e].src;
		 // dest = graph->sorted_edges_array[e].dest;
		 weight =  graph->sorted_edges_array[e].weight;

		
               

		if(weight > delta){
			edgesPlusCounter++;
			// numVerticesPlusCounter = maxTwoIntegers(numVerticesPlusCounter,maxTwoIntegers(src, dest));
		}
		else if (weight <= delta){
			edgesMinusCounter++;
			// numVerticesMinusCounter = maxTwoIntegers(numVerticesMinusCounter,maxTwoIntegers(src, dest));
	
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

	#pragma omp parallel for private(e,weight) shared(edgesMinus_idx,edgesPlus_idx, delta,edgesPlus,edgesMinus,graph)
	for(e =0 ; e < graph->num_edges ; e++){

		 weight =  graph->sorted_edges_array[e].weight;
		if(weight > delta){
			edgesPlus->edges_array[__sync_fetch_and_add(&edgesPlus_idx,1)] = graph->sorted_edges_array[e];
		}
		else if (weight <= delta){
			edgesMinus->edges_array[__sync_fetch_and_add(&edgesMinus_idx,1)] = graph->sorted_edges_array[e];
		}
	}

	

	edgesPlus = sortRunAlgorithms(edgesPlus ,0);
	edgesMinus = sortRunAlgorithms(edgesMinus ,0);

	graphCSRAssignEdgeList ((*graphPlus),edgesPlus,0); 
	graphCSRAssignEdgeList ((*graphMinus),edgesMinus,0); 


}

void SSSPGraphCSR(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph, __u32 delta){

	switch (pushpull)
      { 
        case 0: // push
        	SSSPDataDrivenPushGraphCSR(source, iterations, graph, delta);
        break;
        case 1: // pull
            SSSPDataDrivenPullGraphCSR(source, iterations, graph, delta);
        break;
        default:// push
           	SSSPDataDrivenPushGraphCSR(source, iterations, graph, delta);
        break;          
      }


}

struct SSSPStats* SSSPDataDrivenPullGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph, __u32 delta){

	
	__u32 v;
	__u32 iter = 0;
	iterations = graph->num_vertices - 1;

	struct SSSPStats* stats = (struct SSSPStats*) malloc(sizeof(struct SSSPStats));
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

	
  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Delta-Stepping Algorithm Pull DD (Source)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		printf(" -----------------------------------------------------\n");
    	printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	printf(" -----------------------------------------------------\n");
		return NULL;
	}


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

	printf("| %-15s | %-15u | %-15f | \n","Init", activeVertices,  Seconds(timer_inner));
	printf(" -----------------------------------------------------\n");

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




		        if(SSSPAtomicMin(&(stats->Distances[v]) , minDistance)){
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



    	printf("| %-15u | %-15u | %-15f | \n",iter, activeVertices, Seconds(timer_inner));
	    if(activeVertices == 0)
	      break;
	}
  	
	
	Stop(timer);
	stats->time_total = Seconds(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	printf(" -----------------------------------------------------\n");
	SSSPPrintStatsDetails(stats);


 
  free(timer);
  free(timer_inner);



  // SSSPPrintStats(stats);
  return stats;


}



struct SSSPStats* SSSPDataDrivenPushGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph, __u32 delta){

	__u32 v;
	__u32 iter = 0;
	iterations = graph->num_vertices - 1;


	struct SSSPStats* stats = (struct SSSPStats*) malloc(sizeof(struct SSSPStats));
	
	stats->bucket_counter = 0;
	stats->delta = graph->max_weight ;
	// stats->delta = 1;
	stats->bucket_current = 0;
	stats->processed_nodes = 0;
	stats->buckets_total = 0;
	stats->time_total = 0.0;
	stats->num_vertices = graph->num_vertices;

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  	struct Bitmap* bitmapSetCurr = newBitmap(graph->num_vertices);
  	
    __u32 activeVertices = 0;

	#if ALIGNED
        stats->Distances = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        stats->buckets_map = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        stats->Distances  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->parents = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        stats->buckets_map = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif

    struct GraphCSR* graphHeavy = NULL;
	struct GraphCSR* graphLight = NULL;
	
  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Delta-Stepping Algorithm Push DD (Source)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Start Split Heavy/Light");
    printf(" -----------------------------------------------------\n");
    Start(timer_inner);
    SSSPSpiltGraphCSR(graph, &graphHeavy, &graphLight, stats->delta);
    Stop(timer_inner);
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Graph Light Edges (Number)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", graphLight->num_edges );
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Graph Heavy Edges (Number)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", graphHeavy->num_edges);
	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "END Split Heavy/Light");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n",  Seconds(timer_inner));
    printf(" -----------------------------------------------------\n");


    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Active Buckets", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source > graph->num_vertices){
		printf(" -----------------------------------------------------\n");
    	printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
    	printf(" -----------------------------------------------------\n");
		return NULL;
	}

    Start(timer);

    Start(timer_inner);
    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
  
  	 stats->buckets_map[v] = UINT_MAX/2;
   	 stats->Distances[v] = UINT_MAX/2;
   	 stats->parents[v] = UINT_MAX;

 	}

	stats->parents[source] = source;
	stats->Distances[source] = 0;

	stats->buckets_map[source] = 0; // maps to bucket zero
	stats->bucket_counter = 1;
	stats->buckets_total = 1;
	stats->bucket_current = 0;

	activeVertices = 1;

	Stop(timer_inner);

	printf("| %-15s | %-15u | %-15f | \n","Init", stats->buckets_total ,  Seconds(timer_inner));
	printf(" -----------------------------------------------------\n");


	while (stats->buckets_total){
		// Start(timer_inner);
		stats->processed_nodes += activeVertices;
		activeVertices = 0;
		stats->bucket_counter = 1;
		clearBitmap(bitmapSetCurr);

		while(stats->bucket_counter){
			Start(timer_inner);
			stats->bucket_counter = 0;
			// process light edges
			for(v = 0; v < graphLight->num_vertices; v++){

				// if(stats->buckets_map[v] != UINT_MAX/2)
					// printf("iter %u v %u b %u bc %u bt %u \n",iter, v, stats->buckets_map[v], stats->bucket_current, stats->buckets_total);
    			if(stats->buckets_map[v] == stats->bucket_current) {
    				
    				// pop vertex from bucket list
    				setBit(bitmapSetCurr, v);	 
    				stats->buckets_total--;
    				stats->buckets_map[v] = UINT_MAX/2;

	    			__u32 degree = graphLight->vertices[v].out_degree;
			      	__u32 edge_idx = graphLight->vertices[v].edges_idx;
			      	__u32 j;
			      	 for(j = edge_idx ; j < (edge_idx + degree) ; j++){
			        	// if(numThreads == 1)


			        		activeVertices += SSSPRelax(&(graphLight->sorted_edges_array[j]), stats);
			        	// else
			        	// 	activeVertices += SSSPAtomicRelax(&(graphLight->sorted_edges_array[j]), stats, bitmapNext, bitmapSet);
			        }

			        // printf("v %u b %u bc %u bt %u \n", v, stats->buckets_map[v], stats->bucket_current, stats->buckets_total);
	    		}  
			}

			Stop(timer_inner);

				if(activeVertices)
    				printf("| L%-14u | %-15u | %-15f \n",iter, stats->buckets_total, Seconds(timer_inner));
		}

		Start(timer_inner);
		for(v = 0; v < graphHeavy->num_vertices; v++){
    		if(getBit(bitmapSetCurr, v)){

    			__u32 degree = graphHeavy->vertices[v].out_degree;
		      	__u32 edge_idx = graphHeavy->vertices[v].edges_idx;
		      	__u32 j;

		      	
		      	for(j = edge_idx ; j < (edge_idx + degree) ; j++){
						// if(numThreads == 1)
			        		activeVertices += SSSPRelax(&(graphHeavy->sorted_edges_array[j]), stats);
			        	// else
			        	// 	activeVertices += SSSPAtomicRelax(&(graphHeavy->sorted_edges_array[j]), stats, bitmapNext, bitmapSet);
		        }

		         // printf("*v %u b %u bc %u bt %u \n", v, stats->buckets_map[v], stats->bucket_current, stats->buckets_total);
    		}  
		}

		iter++;
		stats->bucket_current++;
		Stop(timer_inner);
		if(activeVertices)
    		printf("| H%-14u | %-15u | %-15f | \n",iter, stats->buckets_total, Seconds(timer_inner));


    }
	
	Stop(timer);
	stats->time_total += Seconds(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", stats->processed_nodes, stats->time_total);
	printf(" -----------------------------------------------------\n");
	SSSPPrintStatsDetails(stats);

 
  free(timer);
  free(timer_inner);
  // graphCSRFree(graphHeavy);
  // graphCSRFree(graphLight);

  // SSSPPrintStats(stats);
  return stats;
}
