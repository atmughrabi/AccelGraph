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
#include "cluster.h"
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
	float totalQ = 0.0;
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));


	struct ArrayQueue* topLevelSet = newArrayQueue(graph->num_vertices);
	struct ArrayQueue* reachableSet = newArrayQueue(graph->num_vertices);
	struct ArrayQueue* Neighbors = newArrayQueue(graph->num_vertices);
	struct GraphCluster * graphCluster =  graphClusterNew(graph->num_vertices);

	struct Bitmap * mergeEdgeBitmap = newBitmap(graph->num_vertices);

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

    	deltaQ = -1.0;
    	__u32 atomVchild;
    	__u32 atomVdegree;
    	u = vertices[v];
    	n = vertices[v];
    	if(!atomDegree[u]){
    		enArrayQueueAtomic(topLevelSet, u);
    		continue;
    	}

    	__u32 degreeU = UINT_MAX;

    	//atomic swap
    	__u32 degreeUtemp = atomDegree[u];
    	// atomDegree[u] = degreeU;
    	degreeU = degreeUtemp;
    	atomDegree[u] = degreeU;

    	findBestDestination(&deltaQ, &n, u, weightSum, dest, atomDegree, atomChild, sibling, graph, reachableSet, Neighbors);
    	

    	// printf("%f \n",deltaQ );

    	// totalQ += deltaQ;

    	if(deltaQ <= 0){
    		atomDegree[u] = degreeU;
    		enArrayQueueAtomic(topLevelSet, u);
    		continue;
    	}

    	if(graphCluster->clusters[v].sizeOutNodes == 0)
    		initClusterGraphCSR(graph, graphCluster, v);
    	if(graphCluster->clusters[n].sizeOutNodes == 0)
    		initClusterGraphCSR(graph, graphCluster, n);
    	
    	printf("VC%u ",u );
    	clusterPrint(&graphCluster->clusters[u]);

    	printf("UC%u ",n );
    	clusterPrint(&graphCluster->clusters[n]);
    	// mergeCluster(&graphCluster->clusters[v], &graphCluster->clusters[n], mergeEdgeBitmap, dest);
    	// graphClusterPrint(graphCluster);

    	printf("\n");
    	clearBitmap(mergeEdgeBitmap);
    	//atomic load
    	// #pragma omp atomic read
    		atomVchild = atomChild[n];

    	// #pragma omp atomic read
    		atomVdegree = atomDegree[n];

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

    	
    }

 	printSet(topLevelSet);

	Stop(timer);
	printf(" -----------------------------------------------------\n");
    printf("| %-15s   %-15s | %-15s | \n", "", "", "Time (Seconds)");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","Clusters", sizeArrayQueueCurr(topLevelSet),  Seconds(timer));
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15f | %-15f | \n","total Q",totalQ, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	
	freeArrayQueue(topLevelSet);
    freeArrayQueue(Neighbors);
    freeArrayQueue(reachableSet);
    freeBitmap(mergeEdgeBitmap);
    graphClusterFree(graphCluster);
	free(vertices);
	free(degrees);
	free(weightSum);
	free(atomDegree);
	free(atomChild);
	free(sibling);
	free(dest);
	free(timer);
}


void findBestDestination(float *deltaQ, __u32 *u, __u32 v, __u32* weightSum, __u32* dest, __u32* atomDegree, __u32* atomChild,__u32* sibling, struct GraphCSR* graph, struct ArrayQueue* reachableSet, struct ArrayQueue* Neighbors){


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
	
	// struct ArrayQueue* reachableSet = newArrayQueue(graph->num_vertices);
	// struct ArrayQueue* Neighbors = newArrayQueue(graph->num_vertices);
	returnReachableSetOfNodesFromDendrogram(v, atomChild, sibling, reachableSet);

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
	degreeVout = atomDegree[v];
	degreeVin = atomDegree[v];

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

    }



   for(j = reachableSet->head ; j < reachableSet->tail; j++){
		tempV = reachableSet->queue[j];

		degreeTemp = graph->vertices[tempV].out_degree;
		edgeTemp = graph->vertices[tempV].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = graph->sorted_edges_array[k].dest;

			weightSum[dest[tempU]] = 0;
		}
	}


	// memset(weightSum, 0, (sizeof(__u32)*(graph->num_vertices)));

	resetArrayQueue(reachableSet);
    resetArrayQueue(Neighbors);

}



void returnReachableSetOfNodesFromDendrogram(__u32 v,__u32* atomChild,__u32* sibling, struct ArrayQueue* reachableSet){
	
	traversDendrogramReachableSetDFS(v, atomChild, sibling, reachableSet);

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
	printf("Clusters | ");
	for(i = Set->head ; i < Set->tail; i++){
			printf(" %u |",Set->queue[i]);
	}
	printf("\n");

}