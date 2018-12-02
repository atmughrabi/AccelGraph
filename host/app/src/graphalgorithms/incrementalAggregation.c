#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>
#include <limits.h> //UINT_MAX

#include "libchash.h"
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
	__u32 * vertices;
	__u32 * degrees;

	//dendogram
	__u32 * atomChild;
	__u32 * sibling;

	__u32 * atomDegree;
	__u32 * dest;
	__u32 * weightSum;


	float deltaQ = -1.0;
	float totalQ = 0.0;
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));


	struct ArrayQueue* topLevelSet = newArrayQueue(graph->num_vertices);
	struct ArrayQueue* reachableSet = newArrayQueue(graph->num_vertices);
	struct ArrayQueue* Neighbors = newArrayQueue(graph->num_vertices);
	struct GraphCluster * graphCluster =  graphClusterNew(graph->num_vertices, graph->num_edges*2);

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

    printf(" -----------------------------------------------------\n");
    printf("| %-15s   %-15s | %-15s | \n", "initialize", "", "Time (Seconds)");
	printf(" -----------------------------------------------------\n");
	
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
    	// u = vertices[v];
    	
    	atomChild[v] = UINT_MAX;
    	sibling[v] = UINT_MAX;
    	dest[v] = v;
    	weightSum[v] = 0;
    	atomDegree[v] = graph->vertices[v].out_degree;

    	if(!atomDegree[v]){
    		enArrayQueueAtomic(topLevelSet, v);
    	}
    }
	
	Stop(timer);

	printf("| %-15s | %-15u | %-15f | \n","0-degree nodes", sizeArrayQueueCurr(topLevelSet),  Seconds(timer));
	printf(" -----------------------------------------------------\n");


	Start(timer);

	//incrementally aggregate vertices
    for(v=0 ; v < graph->num_vertices; v++){

    	u = vertices[v];
    	if(!atomDegree[u]){
    		continue;
    	}


    	deltaQ = -1.0;
    	__u32 atomVchild;
    	__u32 atomVdegree;
    	
    	n = vertices[v];
    	
    	__u32 degreeU = UINT_MAX;

    	//atomic swap
    	__u32 degreeUtemp = atomDegree[u];
    	// atomDegree[u] = degreeU;
    	degreeU = degreeUtemp;
    	atomDegree[u] = degreeU;

    	findBestDestination(&deltaQ, &n, u, weightSum, dest, atomDegree, atomChild, sibling, graph, reachableSet, Neighbors, mergeEdgeBitmap, graphCluster);
    	
    	// totalQ += deltaQ;
    	// printf("%lf\n", deltaQ);
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

    	if(atomVdegree != UINT_MAX){
    		sibling[u] = atomVchild;
    	
	    	__u32 atomVdegreep = atomVdegree + degreeU;
	    	__u32 atomVchildp = u;

	    	atomChild[n] = atomVchildp;
	    	atomDegree[n] = atomVdegreep;
	    	dest[u] = n;
 
 			// printf("%u <- %u \n\n",n,u );
	    	// mergeClusters(u, n, graph, graphCluster, dest);
			continue;
    	}


    	atomDegree[u] = degreeU;
		sibling[u] = UINT_MAX;

    	
    }

 	printSet(topLevelSet);

	Stop(timer);
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


void findBestDestination_test(float *deltaQ, __u32 *u, __u32 v, __u32* weightSum, __u32* dest, __u32* atomDegree, __u32* atomChild,__u32* sibling, struct GraphCSR* graph, struct ArrayQueue* reachableSet, struct ArrayQueue* Neighbors, struct Bitmap * mergeEdgeBitmap, struct GraphCluster* graphCluster){

	__u32 k;

	__u32 tempV;
	__u32 tempU;
	__u32 degreeTemp;
	__u32 edgeTemp;

	float numEdgesm = 1.0/((graph->num_edges));
	struct GraphCSR* graphPtr = NULL;

	if(graphCluster->mergedCluster[v]){
		graphPtr = graphCluster->clustersCSR;
	} 
	else{
		graphPtr = graph;
	}

	tempV = v;
	
	degreeTemp = graphPtr->vertices[tempV].out_degree;
	edgeTemp = graphPtr->vertices[tempV].edges_idx;

	for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
		tempU = graphPtr->sorted_edges_array[k].dest;

		while(dest[dest[tempU]]!= dest[tempU]){
			dest[tempU] = dest[dest[tempU]];	
		}
	}

	compressCluster( tempV, graph, graphCluster, dest, Neighbors);
	modularityGain(deltaQ, u, v, dest,numEdgesm, atomDegree, graphPtr);

}


void findBestDestination(float *deltaQ, __u32 *u, __u32 v, __u32* weightSum, __u32* dest, __u32* atomDegree, __u32* atomChild,__u32* sibling, struct GraphCSR* graph, struct ArrayQueue* reachableSet, struct ArrayQueue* Neighbors, struct Bitmap * mergeEdgeBitmap, struct GraphCluster* graphCluster){

	__u32 i;
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

	struct Edge* outNodes;
    __u32 out_degree;

 	#if DIRECTED
		vertices = graph->inverse_vertices;
		sorted_edges_array = graph->inverse_sorted_edges_array;
	#else
		vertices = graph->vertices;
		sorted_edges_array = graph->sorted_edges_array;
	#endif
	
	// struct ArrayQueue* reachableSet = newArrayQueue(graph->num_vertices);
	// struct ArrayQueue* Neighbors = newArrayQueue(graph->num_vertices);

	// outNodes = graphCluster->clusters[dest[v]].outNodes;
	// out_degree = graphCluster->clusters[dest[v]].out_degree;

	// for(j = 0 ; j < out_degree ; j++){
	// 	tempU = outNodes[j].dest;

	// 	while(dest[dest[tempU]]!= dest[tempU]){ 
	// 	    	__u32 prevDest = dest[tempU];
	// 			dest[tempU] = dest[dest[tempU]];
	// 			// mergeCluster(&graphCluster->clusters[tempU], &graphCluster->clusters[prevDest], mergeEdgeBitmap, dest);
	//    // 			clearBitmap(mergeEdgeBitmap);
	//    // 			mergeCluster(&graphCluster->clusters[prevDest], &graphCluster->clusters[dest[tempU]], mergeEdgeBitmap, dest);
	//    // 			clearBitmap(mergeEdgeBitmap);
	// 	}
			
	// 	weightSum[dest[tempU]] += outNodes[j].weight;

	// 	if(!isEnArrayQueued(Neighbors, dest[tempU]) &&  dest[v] != dest[tempU]){
	// 		enArrayQueueWithBitmap(Neighbors, dest[tempU]);	
	// 	}
	
	// 	// printf("%u %u %u w%u- ",v ,outNodes[j].dest,dest[outNodes[j].dest],weightSum[dest[tempU]]);
	// }
	// printf("\n");

	// for(j = 0 ; j < out_degree ; j++){
	// 	tempU = outNodes[j].dest;
	// 	if(!isEnArrayQueued(Neighbors, dest[tempU]) &&  dest[v] != dest[tempU]){
	// 			enArrayQueueWithBitmap(Neighbors, dest[tempU]);	
	// 	}
	// }



	returnReachableSetOfNodesFromDendrogram(v, atomChild, sibling, reachableSet);

	for(i = reachableSet->head ; i < reachableSet->tail; i++){
		tempV = reachableSet->queue[i];


		
		degreeTemp = graph->vertices[tempV].out_degree;
		edgeTemp = graph->vertices[tempV].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = graph->sorted_edges_array[k].dest;
			
			while(dest[dest[tempU]]!= dest[tempU]){
		    	// __u32 prevDest = dest[tempU];
				dest[tempU] = dest[dest[tempU]];
			}

			weightSum[dest[tempU]] += graph->sorted_edges_array[k].weight;
			// printf("%u %u - ",dest[tempV], dest[tempU]);
			if(!isEnArrayQueued(Neighbors, dest[tempU]) &&  dest[dest[tempV]] != dest[tempU]){
				enArrayQueueWithBitmap(Neighbors, dest[tempU]);	
				// printf("->%u %u - ",dest[tempV], dest[tempU]);
			}
		}

		
	}

	
	
	// for(j = reachableSet->head ; j < reachableSet->tail; j++){
	// 	tempV = reachableSet->queue[j];

	// 	degreeTemp = graph->vertices[tempV].out_degree;
	// 	edgeTemp = graph->vertices[tempV].edges_idx;

	// 	for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
	// 		tempU = graph->sorted_edges_array[k].dest;

	// 		if(!isEnArrayQueued(Neighbors, dest[tempU]) &&  dest[tempV] != dest[tempU]){
	// 			enArrayQueueWithBitmap(Neighbors, dest[tempU]);	
	// 			// printf("%u %u - ",dest[tempV], dest[tempU]);
	// 		}
	// 	}
	// }

	// printSet(Neighbors);
	edge_idv = graph->vertices[v].edges_idx;
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

      	// printf("v %u u %u w %u dv %u du %u q %lf\n",tempV, i, edgeWeightUV, degreeVout, degreeUout, deltaQtemp);

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


	// for(j = 0 ; j < out_degree ; j++){
	// 	tempU = outNodes[j].dest;
	// 	weightSum[dest[tempU]] = 0;
	// }


	// memset(weightSum, 0, (sizeof(__u32)*(graph->num_vertices)));

	resetArrayQueue(reachableSet);
    resetArrayQueue(Neighbors);

}


void modularityGain(float *deltaQ, __u32 *u, __u32 v, __u32* dest, float numEdgesm , __u32* atomDegree, struct GraphCSR* graph){

	__u32 edgeWeightVU = 0;
	__u32 edgeWeightUV = 0;
	__u32 degreeVout = 0;
	__u32 degreeVin = 0;
	__u32 degreeUout = 0;
	__u32 degreeUin = 0;
	float deltaQtemp = 0.0;
	// float numEdgesm = 1.0/((graph->num_edges));
	float numEdgesm2 = numEdgesm*numEdgesm;

	degreeVout = atomDegree[v];
	degreeVin = atomDegree[v];

	__u32 k;

	__u32 tempV;
	__u32 tempU;
	__u32 degreeTemp;
	__u32 edgeTemp;

	tempV = v;
		
	degreeTemp = graph->vertices[tempV].out_degree;
	edgeTemp = graph->vertices[tempV].edges_idx;

	for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
		tempU = graph->sorted_edges_array[k].dest;
		deltaQtemp = 0.0;
		degreeUout = atomDegree[dest[tempU]];
		degreeUin = atomDegree[dest[tempU]];

		if(degreeUout == UINT_MAX || tempU == tempV){
      		continue;
      	}
		

      	edgeWeightUV = graph->sorted_edges_array[k].weight;
		edgeWeightVU = graph->sorted_edges_array[k].weight;

		deltaQtemp = ((edgeWeightVU*numEdgesm) - (float)(degreeVin*degreeUout*numEdgesm2)) + ((edgeWeightUV*numEdgesm) - (float)(degreeUin*degreeVout*numEdgesm2));

		// printf("v %u u %u w %u dv %u du %u q %lf\n",tempV, tempU, edgeWeightUV, degreeVout, degreeUout, deltaQtemp);

      	if((*deltaQ) < deltaQtemp){
      		(*deltaQ) = deltaQtemp;
      		(*u) = tempU;
      	}

	}

	// printf("\n");


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

void compressCluster( __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest, struct ArrayQueue* Neighbors){

		__u32 degreeTemp;
		__u32 edgeTemp;
		__u32 k;
		__u32 j;
		__u32 out_degree = 0;
		// graphCluster->edgesHash;
		__u32 tempU;
		HTItem* bck = NULL;


		ClearHashTable(graphCluster->edgesHash);

		degreeTemp = graph->vertices[u].out_degree;
		edgeTemp = graph->vertices[u].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = dest[graph->sorted_edges_array[k].dest];
			
			bck = HashFindOrInsert(graphCluster->edgesHash, tempU, 0);     /* initialize to 0 */
			if(!bck->data ){
				out_degree++;
				enArrayQueueWithBitmap(Neighbors, tempU);	
			}

			// printf("c %u-dest %u: w %u d %u \n", u, tempU, graphPtr->sorted_edges_array[k].weight, bck->data);
    		bck->data += graph->sorted_edges_array[k].weight;
		}

		
		__u32 edge_index = graph->vertices[u].edges_idx;
		// graphPtr->vertices[u].out_degree = HashSize(graphCluster->edgesHash);
		graph->vertices[u].out_degree = out_degree;


		// printf("Clusters | ");


   		for(j = Neighbors->head ; j < Neighbors->tail; j++){
			bck = HashFind(graphCluster->edgesHash, Neighbors->queue[j]);
			// printf(" %u |", bck->key);
			graph->sorted_edges_array[edge_index].dest = bck->key;
  	     	graph->sorted_edges_array[edge_index].weight = bck->data;
  	     	edge_index++;
		}



  	//   	for(bck = HashFirstBucket(graphCluster->edgesHash); bck!= NULL ; bck = HashNextBucket(graphCluster->edgesHash)){
  	//   		printf(" %u |",bck->key);
			// 	graphPtr->sorted_edges_array[edge_index].dest = bck->key;
  	//      	graphPtr->sorted_edges_array[edge_index].weight = bck->data;
  	//      	edge_index++;
			// }

		// printf("\n");
		resetArrayQueue(Neighbors);
    	

}

void compressCluster1( __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest, struct ArrayQueue* Neighbors){

		__u32 degreeTemp;
		__u32 edgeTemp;
		__u32 k;
		__u32 j;
		__u32 out_degree = 0;
		// graphCluster->edgesHash;
		__u32 tempU;
		HTItem* bck = NULL;


		ClearHashTable(graphCluster->edgesHash);

		struct GraphCSR* graphPtr = NULL;
	
		if(graphCluster->mergedCluster[u]){
			graphPtr = graphCluster->clustersCSR;
		} 
		else{
			graphPtr = graph;
		}

		degreeTemp = graphPtr->vertices[u].out_degree;
		edgeTemp = graphPtr->vertices[u].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = dest[graphPtr->sorted_edges_array[k].dest];
			
			bck = HashFindOrInsert(graphCluster->edgesHash, tempU, 0);     /* initialize to 0 */
			if(!bck->data ){
				out_degree++;
				enArrayQueueWithBitmap(Neighbors, tempU);	
			}

			// printf("c %u-dest %u: w %u d %u \n", u, tempU, graphPtr->sorted_edges_array[k].weight, bck->data);
    		bck->data += graphPtr->sorted_edges_array[k].weight;
		}

		
		__u32 edge_index = graphPtr->vertices[u].edges_idx;
		// graphPtr->vertices[u].out_degree = HashSize(graphCluster->edgesHash);
		graphPtr->vertices[u].out_degree = out_degree;


		// printf("Clusters | ");


   		for(j = Neighbors->head ; j < Neighbors->tail; j++){
			bck = HashFind(graphCluster->edgesHash, Neighbors->queue[j]);
			// printf(" %u |", bck->key);
			graphPtr->sorted_edges_array[edge_index].dest = bck->key;
  	     	graphPtr->sorted_edges_array[edge_index].weight = bck->data;
  	     	edge_index++;
		}



  	//   	for(bck = HashFirstBucket(graphCluster->edgesHash); bck!= NULL ; bck = HashNextBucket(graphCluster->edgesHash)){
  	//   		printf(" %u |",bck->key);
			// 	graphPtr->sorted_edges_array[edge_index].dest = bck->key;
  	//      	graphPtr->sorted_edges_array[edge_index].weight = bck->data;
  	//      	edge_index++;
			// }

		// printf("\n");
		resetArrayQueue(Neighbors);
    	

}

void mergeClusters(__u32 v, __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest){

		__u32 degreeTemp;
		__u32 edgeTemp;
		__u32 k;
		__u32 out_degree = 0;
		// __u32 max_out_degree = 0;
		// graphCluster->edgesHash;
		__u32 tempU;

		HTItem* bck = NULL;

		ClearHashTable(graphCluster->edgesHash);

		struct GraphCSR* graphPtr = NULL;
		// printf("** \n");
		if(graphCluster->mergedCluster[v]){
			graphPtr = graphCluster->clustersCSR;
		} 
		else{
			graphPtr = graph;
		}

		degreeTemp = graphPtr->vertices[v].out_degree;
		edgeTemp = graphPtr->vertices[v].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = dest[graphPtr->sorted_edges_array[k].dest];
			// printf("%u-dest %u: w %u\n", v, tempU, graphPtr->sorted_edges_array[k].weight);
			
			bck = HashFindOrInsert(graphCluster->edgesHash, tempU, 0);     /* initialize to 0 */
			if(!bck->data  )
				out_degree++;
    		bck->data += graphPtr->sorted_edges_array[k].weight;

		}

		

		if(graphCluster->mergedCluster[u]){
			graphPtr = graphCluster->clustersCSR;
		} 
		else{
			graphPtr = graph;
		}

		degreeTemp = graphPtr->vertices[u].out_degree;
		edgeTemp = graphPtr->vertices[u].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			tempU = dest[graphPtr->sorted_edges_array[k].dest];
			// printf("%u-dest %u: w %u\n", u, tempU, graphPtr->sorted_edges_array[k].weight);
			bck = HashFindOrInsert(graphCluster->edgesHash, tempU, 0);     /* initialize to 0 */
			if(!bck->data )
				out_degree++;
    		bck->data += graphPtr->sorted_edges_array[k].weight;

		}

		// printf("\n");
		// out_degree = HashSize(graphCluster->edgesHash);
		graphCluster->mergedCluster[v] = 1;
		graphCluster->mergedCluster[u] = 1;
		__u32 edge_index = 0;
		

		if(out_degree > graphCluster->clustersCSR->vertices[u].out_degree){
			edge_index = graphCluster->edge_index;
			graphCluster->clustersCSR->vertices[u].edges_idx = graphCluster->edge_index;
			graphCluster->edge_index += out_degree;
				// printf("new cluster %u/%u \n", graphCluster->edge_index,graphCluster->num_edges );
		}
		else{
			edge_index = graphCluster->clustersCSR->vertices[u].edges_idx;
		}

		graphCluster->clustersCSR->vertices[u].out_degree = out_degree;

		for(bck = HashFirstBucket(graphCluster->edgesHash); bck!= NULL ; bck = HashNextBucket(graphCluster->edgesHash)){
			// printf("%u dest %u: w %u\n",u, bck->key, bck->data);
			graphCluster->clustersCSR->sorted_edges_array[edge_index].src = u;
       	 	graphCluster->clustersCSR->sorted_edges_array[edge_index].dest = bck->key;
       	 	graphCluster->clustersCSR->sorted_edges_array[edge_index].weight = bck->data;
       	 	edge_index++;
		}

		
    	// printf("***\n");

}

// void mergeClustersExtra(__u32 v,  __u32 n, __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest){

// 		__u32 degreeTemp;
// 		__u32 edgeTemp;
// 		__u32 k;
// 		// graphCluster->edgesHash;
// 		__u32 tempU;
// 		__u32 out_degree = 0;

// 		struct EdgeH *edge = NULL;

// 		HASH_CLEAR(hh,graphCluster->edgesHash);
// 		struct GraphCSR* graphPtr = NULL;

// 		if(graphCluster->mergedCluster[v]){
// 			graphPtr = graphCluster->clustersCSR;
// 		} 
// 		else{
// 			graphPtr = graph;
// 		}

// 		degreeTemp = graphPtr->vertices[v].out_degree;
// 		edgeTemp = graphPtr->vertices[v].edges_idx;

// 		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
// 			tempU = dest[graphPtr->sorted_edges_array[k].dest];
// 			// printf("%u-dest %u: w %u\n", v, tempU, graphPtr->sorted_edges_array[k].weight);
// 			HASH_FIND_INT(graphCluster->edgesHash, &tempU, edge);  /* id already in the hash? */
// 		    if (edge==NULL) {
// 		      edge = (struct EdgeH *)malloc(sizeof (struct EdgeH));
// 		      edge->id = tempU;
// 		      edge->weight = 0;
// 		      HASH_ADD_INT(graphCluster->edgesHash, id, edge);  /* id: name of key field */
// 		      out_degree++;
// 		    }
// 		    edge->weight += graphPtr->sorted_edges_array[k].weight;

// 		}

// 		edge = NULL;

// 		if(graphCluster->mergedCluster[n]){
// 			graphPtr = graphCluster->clustersCSR;
// 		} 
// 		else{
// 			graphPtr = graph;
// 		}

// 		degreeTemp = graphPtr->vertices[n].out_degree;
// 		edgeTemp = graphPtr->vertices[n].edges_idx;

// 		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
// 			tempU = dest[graphPtr->sorted_edges_array[k].dest];
// 			// printf("%u-dest %u: w %u\n", n, tempU, graphPtr->sorted_edges_array[k].weight);
// 			HASH_FIND_INT(graphCluster->edgesHash, &tempU, edge);  /* id already in the hash? */
// 		    if (edge==NULL) {
// 		      edge = (struct EdgeH *)malloc(sizeof (struct EdgeH));
// 		      edge->id = tempU;
// 		      edge->weight = 0;
// 		      HASH_ADD_INT(graphCluster->edgesHash, id, edge);  /* id: name of key field */
// 		      out_degree++;
// 		    }
// 		    edge->weight += graphPtr->sorted_edges_array[k].weight;

// 		}

// 		edge = NULL;

// 		if(graphCluster->mergedCluster[u]){
// 			graphPtr = graphCluster->clustersCSR;
// 		} 
// 		else{
// 			graphPtr = graph;
// 		}

// 		degreeTemp = graphPtr->vertices[u].out_degree;
// 		edgeTemp = graphPtr->vertices[u].edges_idx;

// 		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
// 			tempU = dest[graphPtr->sorted_edges_array[k].dest];
// 			// printf("%u-dest %u: w %u\n", u, tempU, graphPtr->sorted_edges_array[k].weight);
// 			HASH_FIND_INT(graphCluster->edgesHash, &tempU, edge);  /* id already in the hash? */
// 		    if (edge==NULL) {
// 		      edge = (struct EdgeH *)malloc(sizeof (struct EdgeH));
// 		      edge->id = tempU;
// 		      edge->weight = 0;
// 		      HASH_ADD_INT((graphCluster->edgesHash), id, edge);  /* id: name of key field */
// 		      out_degree++;
// 		    }
// 		    edge->weight += graphPtr->sorted_edges_array[k].weight;

// 		}

// 		// printf("\n");

// 		graphCluster->mergedCluster[n] = 1;
// 		graphCluster->mergedCluster[v] = 1;
// 		graphCluster->mergedCluster[u] = 1;

// 		__u32 edge_index = 0;
		

// 		if(out_degree > graphCluster->clustersCSR->vertices[u].out_degree){
// 			edge_index = graphCluster->edge_index;
// 			graphCluster->clustersCSR->vertices[u].edges_idx = graphCluster->edge_index;
// 			graphCluster->clustersCSR->vertices[u].out_degree = out_degree;
// 			graphCluster->edge_index += out_degree;
// 				// printf("new cluster %u/%u \n", graphCluster->edge_index,graphCluster->num_edges );
// 		}
// 		else{

// 			edge_index = graphCluster->clustersCSR->vertices[u].edges_idx;
// 			graphCluster->clustersCSR->vertices[u].out_degree = out_degree;
// 		}
	
// 		for(edge=graphCluster->edgesHash; edge != NULL; edge=(struct EdgeH*)(edge->hh.next)) {
//        	 	// printf("%u dest %u: w %u\n",u, edge->id, edge->weight);
//        	 	graphCluster->clustersCSR->sorted_edges_array[edge_index].src = u;
//        	 	graphCluster->clustersCSR->sorted_edges_array[edge_index].dest = edge->id;
//        	 	graphCluster->clustersCSR->sorted_edges_array[edge_index].weight = edge->weight;
//        	 	edge_index++;
//     	}

//     	// printf("\n");

// }