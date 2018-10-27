#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "incrementalAggregation.h"
#include "reorder.h"

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
	__u32 * vertices;
	__u32 * degrees;
	float deltaQ = 0.0;
	double totalQ = 0.0;
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	#if ALIGNED
        vertices = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
    #else
        vertices = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    #endif
	
  	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Incremental Aggregation");
    printf(" -----------------------------------------------------\n");

  	#pragma omp parallel for
 	for(v = 0; v < graph->num_vertices; v++){
   	 vertices[v]= v;
   	 degrees[v] = graph->vertices[v].out_degree;
 	}

  	vertices = radixSortEdgesByDegree(degrees, vertices, graph->num_vertices);

	graphCSRReset(graph);

    Start(timer);
	
    for(v=0 ; v < graph->num_vertices; v++){

    	u = vertices[v];
    	calculateModularityGain(&deltaQ, &u, vertices[v], graph);
    	printf("v %u -> u %u q %lf\n", vertices[v], u, deltaQ);
    	totalQ += (double)deltaQ;
    	deltaQ = 0.0;

    }

    printf("%lf\n",totalQ );

	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes,  Seconds(timer));
	printf(" -----------------------------------------------------\n");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", graph->processed_nodes, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	
	free(timer);
}


void calculateModularityGain(float *deltaQ, __u32 *u, __u32 v, struct GraphCSR* graph){


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

      	
      	// printf("v %u u %u q %lf\n", v, i, deltaQtemp);s

    }

}


