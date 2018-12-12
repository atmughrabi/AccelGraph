
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

int SSSPAtomicRelax(struct Edge* edge, struct SSSPStats* stats, struct Bitmap* bitmapNext){
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



int SSSPRelax(struct Edge* edge, struct SSSPStats* stats, struct Bitmap* bitmapNext){
	
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
