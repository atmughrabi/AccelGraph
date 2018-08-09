#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphCSR.h"
#include "graphConfig.h"


void graphCSRFree (struct GraphCSR* graphCSR){

	if(graphCSR->vertices)
		freeVertexArray(graphCSR->vertices);
	if(graphCSR->parents)
		free(graphCSR->parents);
	if(graphCSR->sorted_edges_array)
		freeEdgeArray(graphCSR->sorted_edges_array);
	

	#if DIRECTED
		if(graphCSR->inverse_vertices)
			freeVertexArray(graphCSR->inverse_vertices);
		if(graphCSR->inverse_sorted_edges_array)
			freeEdgeArray(graphCSR->inverse_sorted_edges_array);
	#endif


	if(graphCSR)
		free(graphCSR);

}

void graphCSRPrint(struct GraphCSR* graphCSR){

	
	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "GraphCSR Properties");
    printf(" -----------------------------------------------------\n");
    #if WEIGHTED       
                printf("| %-51s | \n", "WEIGHTED");
    #else
                printf("| %-51s | \n", "UN-WEIGHTED");
    #endif

    #if DIRECTED
                printf("| %-51s | \n", "DIRECTED");
    #else
       			printf("| %-51s | \n", "UN-DIRECTED");
    #endif
	printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Vertices (V)");
    printf("| %-51u | \n", graphCSR->num_vertices);
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", graphCSR->num_edges);  
    printf(" -----------------------------------------------------\n");
    vertexArrayMaxOutdegree(graphCSR->vertices, graphCSR->num_vertices);
 	vertexArrayMaxInDegree(graphCSR->vertices, graphCSR->num_vertices);
 // 	printVertexArray(graphCSR->vertices, graphCSR->num_vertices);
	// __u32 i;

	// printf("Edge List (E) : %d \n", graphCSR->num_edges);  
 //    for(i = 0; i < graphCSR->num_edges; i++){

 //    	#if WEIGHTED
 //        	printf("%u -> %u w: %d \n", graphCSR->sorted_edges_array[i].src, graphCSR->sorted_edges_array[i].dest, graphCSR->sorted_edges_array[i].weight);   
 //        #else
 //        	printf("%u -> %u \n", graphCSR->sorted_edges_array[i].src, graphCSR->sorted_edges_array[i].dest);   
 //        #endif
 //     }

 //    printf("Inverted Edge List (E) : %d \n", graphCSR->num_edges);  
 //      for(i = 0; i < graphCSR->num_edges; i++){

 //    	#if WEIGHTED
 //        	printf("%u -> %u w: %d \n", graphCSR->inverse_sorted_edges_array[i].src, graphCSR->inverse_sorted_edges_array[i].dest, graphCSR->inverse_sorted_edges_array[i].weight);   
 //        #else
 //        	printf("%u -> %u \n", graphCSR->inverse_sorted_edges_array[i].src, graphCSR->inverse_sorted_edges_array[i].dest);   
 //        #endif
 //     }

   
}


struct GraphCSR* graphCSRNew(__u32 V, __u32 E, __u8 inverse){
	int i;
	// struct GraphCSR* graphCSR = (struct GraphCSR*) aligned_alloc(CACHELINE_BYTES, sizeof(struct GraphCSR));
	#if ALIGNED
		struct GraphCSR* graphCSR = (struct GraphCSR*) my_aligned_alloc( sizeof(struct GraphCSR));
	#else
        struct GraphCSR* graphCSR = (struct GraphCSR*) my_malloc( sizeof(struct GraphCSR));
    #endif

	graphCSR->num_vertices = V;
	graphCSR->num_edges = E;

	graphCSR->vertices = newVertexArray(V);

	#if DIRECTED
		if (inverse)
			graphCSR->inverse_vertices = newVertexArray(V);
	#endif

	#if ALIGNED
		graphCSR->parents  = (int*) my_aligned_alloc( V * sizeof(int));
	#else
        graphCSR->parents  = (int*) my_malloc( V *sizeof(int));
    #endif


     for(i = 0; i < V; i++){
                graphCSR->parents[i] = -1;
     }
	


    return graphCSR;
}

void graphCSRPrintParentsArray(struct GraphCSR* graphCSR){


    __u32 i;

    printf("| %-15s | %-15s | %-15s | %-15s | \n", "Node", "out_degree", "Parent", "Visited");

    for(i =0; i < graphCSR->num_vertices; i++){

        if((graphCSR->vertices[i].out_degree > 0) || (graphCSR->vertices[i].in_degree > 0))
        printf("| %-15u | %-15u | %-15d | %-15u | \n",i,  graphCSR->vertices[i].out_degree, graphCSR->parents[i], graphCSR->vertices[i].visited);
    
    }

}


struct GraphCSR* graphCSRAssignEdgeList (struct GraphCSR* graphCSR, struct EdgeList* edgeList, __u8 inverse){


	#if DIRECTED
	    
	    if(inverse)
	        graphCSR->inverse_sorted_edges_array = edgeList->edges_array;
	    else
	        graphCSR->sorted_edges_array = edgeList->edges_array;

    #else

      	graphCSR->sorted_edges_array = edgeList->edges_array;
    
    #endif

  
	return mapVerticesWithInOutDegree (graphCSR,inverse);   
    
}
