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
	__u32 * vertices;
	__u32 * degrees;
	double deltaQ = 0.0;
	float totalQ = 0.0;
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

    	deltaQ = calculateModularityGain(vertices[v], graph);
    	totalQ += deltaQ;
    	printf("%lf\n",deltaQ );

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


float calculateModularityGain(__u32 v, struct GraphCSR* graph){


	__u32 j;
	__u32 edge_idx;
	float deltaQ = 0.0;
	float deltaQtemp = 0.0;
	float op1 = 0.0;
	float op2 = 0.0;
	__u32 edgeWeight = 1;
	__u32 degreeV = 0;
	__u32 degreeU = 0;

	float numEdges2m = 1.0/((graph->num_edges/2)*2);
	float numEdges2m2 = numEdges2m*numEdges2m;

	__u32 out_degree;
	// struct Vertex* vertices = NULL;
	// struct Edge*  sorted_edges_array = NULL;
    

 //    #if DIRECTED
	// 	vertices = graph->inverse_vertices;
	// 	sorted_edges_array = graph->inverse_sorted_edges_array;
	// #else
	// 	vertices = graph->vertices;
	// 	sorted_edges_array = graph->sorted_edges_array;
	// #endif

	edge_idx = graph->vertices[v].edges_idx;
	degreeV = graph->vertices[v].out_degree;

	for(j = edge_idx ; j < (edge_idx + degreeV) ; j++){
     
        __u32 u = graph->sorted_edges_array[j].dest;
      	degreeU = graph->vertices[u].out_degree;

		#if WEIGHTED
      		edgeWeight =  graph->sorted_edges_array[j].weight;
		#endif


      	deltaQtemp = 2*(numEdges2m - (float)(degreeU*degreeV*numEdges2m2));

  		printf("v %u u %u q %lf \n",v,u,deltaQtemp);

      	if(deltaQ <= deltaQtemp)
      		deltaQ = deltaQtemp;


    }

    return deltaQ;
}


