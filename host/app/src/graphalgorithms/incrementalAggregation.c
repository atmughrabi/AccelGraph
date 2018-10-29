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
	__u32 * vertices;
	__u32 * degrees;

	//dendogram
	__u32 * atomDegree;
	__u32 * atomChild;
	__u32 * sibling;
	__u32 * dest;

	float deltaQ = -1.0;
	double totalQ = 0.0;
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));


	struct ArrayQueue* topLevelSet = newArrayQueue(graph->num_vertices);

	#if ALIGNED
        vertices = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));

        atomDegree = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        atomChild = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        sibling = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        dest = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        vertices = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));

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
    }
	

    for(v = 0; v < graph->num_vertices; v++){
     u = vertices[v];
   	 printf("[u] %u child %u sibling %u deg %u dest %u\n",u,atomChild[u],sibling[u],atomDegree[u],dest[u]);
 	}

	//incrementally aggregate vertices
    for(v=0 ; v < graph->num_vertices; v++){
    	deltaQ = -1.0;
    	__u32 atomVchild;
    	__u32 atomVdegree;
    	u = vertices[v];
    	n = vertices[v];

    	__u32 degreeU = UINT_MAX;

    	//atomic swap
    	__u32 degreeUtemp = atomDegree[u];
    	atomDegree[u] = degreeU;
    	degreeU = degreeUtemp;
    	
    	calculateModularityGain(&deltaQ, &n, u, dest, atomChild, sibling, graph);
    	printf("n %u u %u deltaQ %f\n",n,u,deltaQ );

    	if(deltaQ <= 0){
    		atomDegree[u] = degreeU;
    		enArrayQueueAtomic(topLevelSet, u);
    		continue;
    	}

    	//atomic load
    	#pragma omp atomic read
    		atomVchild = atomChild[n];

    	#pragma omp atomic read
    		atomVdegree = atomDegree[n];

    	if(atomVdegree != UINT_MAX){
    		sibling[u] = atomVchild;
    	
	    	__u32 atomVdegreep = atomVdegree + degreeU;
	    	__u32 atomVchildp = atomChild[u];

	    	if(__sync_bool_compare_and_swap(&atomChild[n],atomVchild,atomVchildp) && __sync_bool_compare_and_swap(&atomDegree[n],atomVdegree,atomVdegreep)){ 
	    		dest[u] = n;
				continue;
			}

    	}

    	atomDegree[u] = degreeU;
		sibling[u] = UINT_MAX;

    	totalQ += (double)deltaQ;
    	
    }


    for(v = 0; v < graph->num_vertices; v++){
     u = vertices[v];
   	 printf("[u] %u child %u sibling %u deg %u dest %u\n",u,atomChild[u],sibling[u],atomDegree[u],dest[u]);
 	}

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
	free(atomDegree);
	free(atomChild);
	free(sibling);
	free(dest);
	free(timer);
}


void calculateModularityGain(float *deltaQ, __u32 *u, __u32 v, __u32* dest, __u32* atomChild,__u32* sibling, struct GraphCSR* graph){


	__u32 j;
	__u32 k;
	__u32 edge_idv;
	__u32 edge_idu;
	float deltaQtemp = 0.0;
	__u32 edgeWeightVU = 0;
	__u32 edgeWeightUV = 0;
	__u32 degreeVout = 0;
	__u32 degreeVin = 0;
	__u32 degreeUout = 0;
	__u32 degreeUin = 0;

	struct Vertex* vertices = NULL;
	struct Edge*  sorted_edges_array = NULL;
    
 	#if DIRECTED
		vertices = graph->inverse_vertices;
		sorted_edges_array = graph->inverse_sorted_edges_array;
	#else
		vertices = graph->vertices;
		sorted_edges_array = graph->sorted_edges_array;
	#endif

	float numEdgesm = 1.0/((graph->num_edges));
	float numEdgesm2 = numEdgesm*numEdgesm;

	edge_idv = graph->vertices[v].edges_idx;
	degreeVout = graph->vertices[v].out_degree;
	degreeVin = graph->vertices[v].in_degree;


	struct ArrayQueue* Neighbors = newArrayQueue(graph->num_vertices);
	struct ArrayQueue* reachableSet = returnReachableSetOfNodesFromDendrogram(v, atomChild, sibling, graph);
	for(j = reachableSet->head ; j < reachableSet->tail; j++){
			__u32 tempV = reachableSet->queue[j];

			while(dest[dest[tempV]]!= dest[tempV]){
				dest[tempV] = dest[dest[tempV]];
			}

			printf("|%u|",tempV);
	}
	printf("\n");

	for(j = reachableSet->head ; j < reachableSet->tail; j++){
		__u32 tempt = reachableSet->queue[j];
		__u32 tempn = dest[tempt];


		enArrayQueue(Neighbors, tempn);	
	}


	for(j = edge_idv ; j < (edge_idv + degreeVout) ; j++){
     	
     	deltaQtemp = 0.0;
     	edgeWeightVU =  1;
        __u32 i = graph->sorted_edges_array[j].dest;
      	degreeUout = graph->vertices[i].out_degree;
		degreeUin = graph->vertices[i].in_degree;

		//check if there is an opposite edge when directed graph is chosen
		#if DIRECTED
			edge_idu = vertices[i].edges_idx;
			for(k = edge_idu ; k < (edge_idu + degreeUin) ; k++){
	     
		        __u32 n = sorted_edges_array[k].dest;
		      	edgeWeightUV = 0;

			        #if WEIGHTED
		        		if(n == v){
	      					edgeWeightUV =  sorted_edges_array[k].weight;
	      					break;
	      				}
	      			#else
	      				if(n == v){
	      					edgeWeightUV =  1;
	      					break;
	      				}
					#endif


				 
			}
		#else
			#if WEIGHTED
      			edgeWeightVU =  graph->sorted_edges_array[j].weight;
      			edgeWeightUV =  graph->sorted_edges_array[j].weight;
	    	#else
				edgeWeightVU = 1;
				edgeWeightUV = 1;
			#endif
		#endif



      	deltaQtemp = ((edgeWeightVU*numEdgesm) - (float)(degreeVin*degreeUout*numEdgesm2)) + ((edgeWeightUV*numEdgesm) - (float)(degreeUin*degreeVout*numEdgesm2));


      	if((*deltaQ) <= deltaQtemp){
      		(*deltaQ) = deltaQtemp;
      		(*u) = i;
      	}

      	
      	printf("v %u u %u q %lf\n", v, i, deltaQtemp);

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

	if(atomChild[v] == UINT_MAX)
		enArrayQueue(reachableSet, v);
	else
		traversDendrogramReachableSetDFS(atomChild[v],atomChild,sibling,reachableSet);

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