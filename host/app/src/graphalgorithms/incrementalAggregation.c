#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>
#include <limits.h> //UINT_MAX

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "incrementalAggregation.h"
#include "reorder.h"


#include "arrayQueue.h"
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"



// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************



void incrementalAggregationGraphCSR( struct GraphCSR* graph){

	__u32 v;
	__u32 u;
	__u32 n;
	__u32 t;
	__u32 * vertices;
	__u32 * degrees;

	//dendogram
	__u32 * atomDegree;
	__u32 * atomChild;
	__u32 * sibling;
	__u32 * dest;
	__u32 * weightSum;


	float deltaQ = -1.0;
	double totalQ = 0.0;
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));


	struct ArrayQueue* topLevelSet = newArrayQueue(graph->num_vertices);

	#if ALIGNED
        vertices = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));

        weightSum = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        atomDegree = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        atomChild = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        sibling = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        dest = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        vertices = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));

        weightSum  = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        atomDegree = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        atomChild = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        sibling = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        dest = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif
	
  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Incremental Aggregation");
    printf(" -----------------------------------------------------\n");

    graphCSRReset(graph);

    Start(timer);

    //order vertices according to degree
  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   	 vertices[v]= v;
   	 degrees[v] = graph->vertices[v].out_degree;
 	}

  	vertices = radixSortEdgesByDegree(degrees, vertices, graph->num_vertices);    

    //initialize variables
    #pragma omp parallel for private(u)
    for(v=0 ; v < graph->num_vertices; v++){
    	u = vertices[v];
    	atomDegree[u] = graph->vertices[u].out_degree;
    	atomChild[u] = UINT_MAX;
    	sibling[u] = UINT_MAX;
    	dest[u] = u;
    	weightSum[u] = 0;
    }
	

	


	//incrementally aggregate vertices
    for(v=0 ; v < graph->num_vertices; v++){

    	#pragma omp parallel for
	    for(t=0 ; t < graph->num_vertices; t++){
	    	weightSum[t] = 0;
	    }

  //   	__u32 x,y;
  //   	for(x = 0; x < graph->num_vertices; x++){
		// 	     y = vertices[x];
		// 	   	 printf("[u] %u child %u sibling %u deg %u dest %u\n",y,atomChild[y],sibling[y],atomDegree[y],dest[y]);
		// }

		// printf("\n");

    	deltaQ = -1.0;
    	__u32 atomVchild;
    	__u32 atomVdegree;
    	u = vertices[v];
    	n = vertices[v];

    	__u32 degreeU = UINT_MAX;

    	//atomic swap
    	__u32 degreeUtemp = atomDegree[u];
    	// atomDegree[u] = degreeU;
    	degreeU = degreeUtemp;
    	
    	findBestDestination(&deltaQ, &n, u, weightSum, dest, atomDegree, atomChild, sibling, graph);
    	// printf("n %u u %u deltaQ %f\n",n,u,deltaQ );
    	atomDegree[u] = degreeU;
    	if(deltaQ <= 0){
    		atomDegree[u] = degreeU;
    		enArrayQueueAtomic(topLevelSet, u);
    		continue;
    	}

    	//atomic load
    	// #pragma omp atomic read
    		atomVchild = atomChild[n];

    	// #pragma omp atomic read
    		atomVdegree = atomDegree[n];
    		// printf("atomVdegree %u \n",atomVdegree );

    	if(atomVdegree != UINT_MAX){
    		sibling[u] = atomVchild;
    	
	    	__u32 atomVdegreep = atomVdegree + degreeU;
	    	__u32 atomVchildp = u;

	    	atomChild[n] = atomVchildp;
	    	atomDegree[n] = atomVdegreep;
	    	dest[u] = n;
			continue;

    	}


    	atomDegree[u] = degreeU;
		sibling[u] = UINT_MAX;

    	totalQ += (double)deltaQ;
    	
    }


    for(v = 0; v < graph->num_vertices; v++){
     u = vertices[v];
   	 // printf("[u] %u child %u sibling %u deg %u dest %u\n",u,atomChild[u],sibling[u],atomDegree[u],dest[u]);
 	}

 	// printSet(topLevelSet);

	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes,  Seconds(timer));
	printf(" -----------------------------------------------------\n");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15lf | %-15f | \n","total Q",totalQ, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	
	freeArrayQueue(topLevelSet);
	free(vertices);
	free(degrees);
	free(weightSum);
	free(atomDegree);
	free(atomChild);
	free(sibling);
	free(dest);
	free(timer);
}


void findBestDestination(float *deltaQ, __u32 *u, __u32 v, __u32* weightSum, __u32* dest, __u32* atomDegree, __u32* atomChild,__u32* sibling, struct GraphCSR* graph){


	__u32 j;
	__u32 k;
	__u32 edge_idv;
	__u32 edge_idu;

	__u32 tempV;
	__u32 tempU;
	__u32 degreeTemp;
	__u32 edgeTemp;

	__u32 edgeWeightVU = 0;
	__u32 edgeWeightUV = 0;
	__u32 degreeVout = 0;
	__u32 degreeVin = 0;
	__u32 degreeUout = 0;
	__u32 degreeUin = 0;
	float deltaQtemp = 0.0;
	float numEdgesm = 1.0/((graph->num_edges));
	float numEdgesm2 = numEdgesm*numEdgesm;

	struct Vertex* vertices = NULL;
	struct Edge*  sorted_edges_array = NULL;
    
 	#if DIRECTED
		vertices = graph->inverse_vertices;
		sorted_edges_array = graph->inverse_sorted_edges_array;
	#else
		vertices = graph->vertices;
		sorted_edges_array = graph->sorted_edges_array;
	#endif
	
	struct ArrayQueue* Neighbors = newArrayQueue(graph->num_vertices);
	struct ArrayQueue* reachableSet = returnReachableSetOfNodesFromDendrogram(v, atomChild, sibling, graph);

	for(j = reachableSet->head ; j < reachableSet->tail; j++){
		tempV = reachableSet->queue[j];

		degreeTemp = graph->vertices[tempV].out_degree;
		edgeTemp = graph->vertices[tempV].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = graph->sorted_edges_array[k].dest;
			
			while(dest[dest[tempU]]!= dest[tempU]){
				dest[tempU] = dest[dest[tempU]];
			}

			weightSum[dest[tempU]]++;
		}
	}


	for(j = reachableSet->head ; j < reachableSet->tail; j++){
		tempV = reachableSet->queue[j];

		degreeTemp = graph->vertices[tempV].out_degree;
		edgeTemp = graph->vertices[tempV].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = graph->sorted_edges_array[k].dest;

			if(!isEnArrayQueued(Neighbors, dest[tempU]) &&  dest[tempV] != dest[tempU]){
				enArrayQueueWithBitmap(Neighbors, dest[tempU]);	
			}
		}
	}


	// edge_idv = graph->vertices[v].edges_idx;
	degreeVout = atomDegree[dest[v]];
	degreeVin = atomDegree[dest[v]];

	for(j = Neighbors->head ; j < Neighbors->tail; j++){
     	
     	deltaQtemp = 0.0;
     	// edgeWeightVU =   weightSum[dest[v]];
        __u32 i = Neighbors->queue[j];
      	degreeUout = atomDegree[dest[i]];
      	if(degreeUout == UINT_MAX)
      		continue;
		degreeUin = atomDegree[dest[i]];
		

		edgeWeightUV = weightSum[dest[i]];
		edgeWeightVU = weightSum[dest[i]];

      	deltaQtemp = ((edgeWeightVU*numEdgesm) - (float)(degreeVin*degreeUout*numEdgesm2)) + ((edgeWeightUV*numEdgesm) - (float)(degreeUin*degreeVout*numEdgesm2));


      	if((*deltaQ) < deltaQtemp){
      		(*deltaQ) = deltaQtemp;
      		(*u) = i;
      	}

      	
      	// printf("v %u u %u q %lf\n", v, i, deltaQtemp);

    }


    freeArrayQueue(Neighbors);
    freeArrayQueue(reachableSet);
}




struct ArrayQueue* returnReachableSetOfNodesFromDendrogram(__u32 v,__u32* atomChild,__u32* sibling,struct GraphCSR* graph){

	struct ArrayQueue* reachableSet = newArrayQueue(graph->num_vertices);
	
	traversDendrogramReachableSetDFS(v, atomChild, sibling, reachableSet);

	return reachableSet;
}


void traversDendrogramReachableSetDFS(__u32 v,__u32* atomChild,__u32* sibling,struct ArrayQueue* reachableSet){

	if(atomChild[v] != UINT_MAX)
		traversDendrogramReachableSetDFS(atomChild[v],atomChild,sibling,reachableSet);
	
	enArrayQueue(reachableSet, v);
	
	if(sibling[v] != UINT_MAX)
		traversDendrogramReachableSetDFS(sibling[v],atomChild,sibling,reachableSet);
		
	

}

void printSet(struct ArrayQueue* Set){
	__u32 i;
	printf("S : ");
	for(i = Set->head ; i < Set->tail; i++){
			printf("%u|",Set->queue[i]);
	}
	printf("\n");

}