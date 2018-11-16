#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>


#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "bitmap.h"

#include "arrayQueue.h"
#include "graphCSR.h"
// #include "graphGrid.h"
// #include "graphAdjArrayList.h"
// #include "graphAdjLinkedList.h"

#include "cluster.h"

struct GraphCluster * graphClusterNew(__u32 V){

	#if ALIGNED
        struct GraphCluster* graphCluster = (struct GraphCluster*) my_aligned_malloc( sizeof(struct GraphCluster));
    #else
        struct GraphCluster* graphCluster = (struct GraphCluster*) my_malloc( sizeof(struct GraphCluster));
    #endif

	graphCluster->num_vertices = V;

    #if ALIGNED
        graphCluster->clusters = (struct Cluster*) my_aligned_malloc( V * sizeof(struct Cluster));
    #else
        graphCluster->clusters = (struct Cluster*) my_malloc( V * sizeof(struct Cluster));
    #endif


	__u32 i;
	for(i = 0; i < V; i++){

        graphCluster->clusters[i].sizeOutNodes = 0;
        graphCluster->clusters[i].out_degree = 0;
        graphCluster->clusters[i].outNodes = NULL;

        #if DIRECTED
        	graphCluster->clusters[i].sizeInNodes = 0;
            graphCluster->clusters[i].in_degree = 0;
            graphCluster->clusters[i].inNodes = NULL;
        #endif
	}

    

    return graphCluster;

}


void initClusterGraphCSR(struct GraphCSR* graph, struct GraphCluster* graphCluster, __u32 v){

	__u32 degreeTemp;
	__u32 edgeTemp;
	__u32 tempU;
	__u32 k;



	 if(graph->vertices[v].out_degree){
        graphCluster->clusters[v].outNodes = newEdgeArray(graph->vertices[v].out_degree);
        graphCluster->clusters[v].out_degree = graph->vertices[v].out_degree;
        graphCluster->clusters[v].sizeOutNodes = graph->vertices[v].out_degree;
	 }
        
    #if DIRECTED
    if(graph->vertices[v].in_degree){
        graphCluster->clusters[v].inNodes = newEdgeArray(graph->vertices[v].in_degree);
        graphCluster->clusters[v].in_degree = graph->vertices[v].in_degree;
        graphCluster->clusters[v].sizeInNodes = graph->vertices[v].in_degree;
    }
    #endif


	if (graph->vertices[v].out_degree){
		degreeTemp = graph->vertices[v].out_degree;
		edgeTemp = graph->vertices[v].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			graphCluster->clusters[v].outNodes[(k-edgeTemp)] = graph->sorted_edges_array[k];
		}
	}

	#if DIRECTED
	if (graph->vertices[v].in_degree){
		degreeTemp = graph->inverse_vertices[v].out_degree;
		edgeTemp = graph->inverse_vertices[v].edges_idx;

		for(k = edgeTemp ; k < (edgeTemp + degreeTemp) ; k++){
			graphCluster->clusters[v].inNodes[(k-edgeTemp)] = graph->inverse_sorted_edges_array[k];
		}
	}
	#endif



}

void mergeCluster(struct Cluster* cluster1, struct Cluster* cluster2, struct Bitmap * mergeEdgeBitmap, __u32* dest){

	struct Edge* newOutNodes;
	__u32 newClusterOutdegree = cluster1->out_degree + cluster2->out_degree;
	__u32 newClusterSize = newClusterOutdegree;



    newOutNodes = newEdgeArray(newClusterSize);

    __u32 i;
    __u32 k;
    for(i = 0 ; i < cluster1->out_degree; i++){
    	cluster1->outNodes[i].dest = dest[cluster1->outNodes[i].dest];
    	if(!getBit(mergeEdgeBitmap ,cluster1->outNodes[i].dest)){
    		newOutNodes[i] = cluster1->outNodes[i];
    		setBit(mergeEdgeBitmap ,cluster1->outNodes[i].dest);
    	}
    	else{
    		for(k = 0; k < i; k++){
    			if(newOutNodes[k].dest == cluster1->outNodes[i].dest){
    				newOutNodes[k].weight++;
    				break;
    			}
    		}
    	}
    }

    i = 0;
    __u32 j;
    for(j = cluster1->out_degree; j < newClusterOutdegree; j++, i++){
    	cluster2->outNodes[i].dest = dest[cluster2->outNodes[i].dest];
		if(!getBit(mergeEdgeBitmap ,cluster1->outNodes[i].dest)){
		newOutNodes[j] = cluster2->outNodes[i];
		setBit(mergeEdgeBitmap ,cluster1->outNodes[i].dest);
    	}
    	else{

    		for(k = 0; k < i; k++){
    			if(newOutNodes[k].dest == cluster1->outNodes[i].dest){
    				newOutNodes[k].weight++;
    				break;
    			}
    		}
    	}
    }


    cluster1->out_degree = 0;
	cluster1->sizeOutNodes = 0;

	if(cluster1->outNodes != NULL)
		freeEdgeArray(cluster1->outNodes);

	if(cluster2->outNodes != NULL)
		freeEdgeArray(cluster2->outNodes);

	cluster2->out_degree = newClusterOutdegree;
	cluster2->sizeOutNodes = newClusterSize;
	cluster2->outNodes = newOutNodes;


}


void graphClusterFree(struct GraphCluster* graphCluster){

    __u32 v;
    struct Cluster* pCrawl;

    for (v = 0; v < graphCluster->num_vertices; ++v)
    {
        pCrawl = &(graphCluster->clusters[v]);
        
        if(pCrawl->outNodes)
        	freeEdgeArray(pCrawl->outNodes);
        #if DIRECTED
        if(pCrawl->inNodes)
            freeEdgeArray(pCrawl->inNodes);
        #endif
       
    }

    free(graphCluster->clusters);
    free(graphCluster);
}

void graphClusterPrint(struct GraphCluster* graphCluster){

        __u32 i;
        struct Edge* pCrawlEdge;
    	__u32 v;
    	struct Cluster* pCrawlCluster;

    	for (v = 0; v < graphCluster->num_vertices; ++v){
    		
		    pCrawlCluster = &(graphCluster->clusters[v]);
		    printf("C%u ",v);
		   	clusterPrint(pCrawlCluster);
		    
		}
}


void clusterPrint(struct Cluster* cluster){

	 __u32 i;
     
	 if(cluster->out_degree){	    	
		    	  for (i = 0; i < cluster->out_degree; ++i)
	        {
	             printf(" --w%u-->%u", cluster->outNodes[i].weight, cluster->outNodes[i].dest);
	        }	        
    }
    printf("\n");
    #if DIRECTED
	    if(cluster->in_degree){
	    	  for (i = 0; i < cluster->out_degree; ++i)
		        {
		             printf(" <--w%u--%u", cluster->outNodes[i].weight, cluster->outNodes[i].dest);
		        }
		        
	    }
	    printf("\n");
	#endif
}

