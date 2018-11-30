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
    	printf("%lf\n", deltaQ);
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
 
 			printf("%u <- %u \n",n,u );
	    	mergeClusters(u, n, graph, graphCluster, dest);
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


void findBestDestination(float *deltaQ, __u32 *u, __u32 v, __u32* weightSum, __u32* dest, __u32* atomDegree, __u32* atomChild,__u32* sibling, struct GraphCSR* graph, struct ArrayQueue* reachableSet, struct ArrayQueue* Neighbors, struct Bitmap * mergeEdgeBitmap, struct GraphCluster* graphCluster){

	__u32 k;

	__u32 tempV;
	__u32 tempU;
	__u32 degreeTemp;
	__u32 edgeTemp;


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

	compressCluster( tempV, graph, graphCluster, dest);

	modularityGain(deltaQ, u, v, dest, atomDegree, graphPtr);

}

void modularityGain(float *deltaQ, __u32 *u, __u32 v, __u32* dest, __u32* atomDegree, struct GraphCSR* graph){

	__u32 edgeWeightVU = 0;
	__u32 edgeWeightUV = 0;
	__u32 degreeVout = 0;
	__u32 degreeVin = 0;
	__u32 degreeUout = 0;
	__u32 degreeUin = 0;
	float deltaQtemp = 0.0;
	float numEdgesm = 1.0/((graph->num_edges));
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
		degreeUout = atomDegree[tempU];
		degreeUin = atomDegree[tempU];

		if(degreeUout == UINT_MAX || tempU == tempV){
      		continue;
      	}
		
      	edgeWeightUV = graph->sorted_edges_array[k].weight;
		edgeWeightVU = graph->sorted_edges_array[k].weight;

		deltaQtemp = ((edgeWeightVU*numEdgesm) - (float)(degreeVin*degreeUout*numEdgesm2)) + ((edgeWeightUV*numEdgesm) - (float)(degreeUin*degreeVout*numEdgesm2));

      	if((*deltaQ) < deltaQtemp){
      		(*deltaQ) = deltaQtemp;
      		(*u) = tempU;
      	}

	}

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

void compressCluster( __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest){

		__u32 degreeTemp;
		__u32 edgeTemp;
		__u32 k;
		// __u32 max_out_degree = 0;
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
			// printf("%u-dest %u: w %u\n", u, tempU, graphPtr->sorted_edges_array[k].weight);
			bck = HashFindOrInsert(graphCluster->edgesHash, tempU, 0);     /* initialize to 0 */
    		bck->data += graphPtr->sorted_edges_array[k].weight;

		}

		
		__u32 edge_index = graphPtr->vertices[u].edges_idx;
		graphPtr->vertices[u].out_degree = HashSize(graphCluster->edgesHash);
		

    	for(bck = HashFirstBucket(graphCluster->edgesHash); bck!= NULL ; bck = HashNextBucket(graphCluster->edgesHash)){

			graphPtr->sorted_edges_array[edge_index].dest = bck->key;
       	 	graphPtr->sorted_edges_array[edge_index].weight = bck->data;
       	 	edge_index++;

		}

    	

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
    		bck->data += graphPtr->sorted_edges_array[k].weight;

		}

		// printf("\n");
		out_degree = HashSize(graphCluster->edgesHash);
		graphCluster->mergedCluster[v] = 1;
		graphCluster->mergedCluster[u] = 1;
		__u32 edge_index = 0;
		

		if(out_degree > graphCluster->clustersCSR->vertices[u].out_degree){
			edge_index = graphCluster->edge_index;
			graphCluster->clustersCSR->vertices[u].edges_idx = graphCluster->edge_index;
			graphCluster->clustersCSR->vertices[u].out_degree = out_degree;
			graphCluster->edge_index += out_degree;
				// printf("new cluster %u/%u \n", graphCluster->edge_index,graphCluster->num_edges );
		}
		else{

			edge_index = graphCluster->clustersCSR->vertices[u].edges_idx;
			graphCluster->clustersCSR->vertices[u].out_degree = out_degree;
		}

		for(bck = HashFirstBucket(graphCluster->edgesHash); bck!= NULL ; bck = HashNextBucket(graphCluster->edgesHash)){

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