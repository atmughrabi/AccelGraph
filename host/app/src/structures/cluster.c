#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>
#include "libchash.h"

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
	graphCluster->num_edges = 0;

    #if ALIGNED
        graphCluster->clusters = (struct Cluster*) my_aligned_malloc( V * sizeof(struct Cluster));
    #else
        graphCluster->clusters = (struct Cluster*) my_malloc( V * sizeof(struct Cluster));
    #endif

    #if ALIGNED
        graphCluster->mergedCluster = (__u32*) my_aligned_malloc( V * sizeof(__u32));
    #else
        graphCluster->mergedCluster = (__u32*) my_malloc( V * sizeof(__u32));
    #endif


	__u32 i;
	for(i = 0; i < V; i++){

        graphCluster->clusters[i].sizeOutNodes = 0;
        graphCluster->clusters[i].out_degree = 0;
        // graphCluster->clusters[i].outNodes =  AllocateHashTable(4, 0);
        graphCluster->mergedCluster[i] = 0;

        #if DIRECTED
        	graphCluster->clusters[i].sizeInNodes = 0;
            graphCluster->clusters[i].in_degree = 0;
            // graphCluster->clusters[i].inNodes =  AllocateHashTable(4, 0);
        #endif
	}

    

    return graphCluster;

}




void graphClusterFree(struct GraphCluster* graphCluster){

    __u32 v;
    struct Cluster* pCrawl;

    // for (v = 0; v < graphCluster->num_vertices; ++v)
    // {
    //     pCrawl = &(graphCluster->clusters[v]);
        
    //     if(pCrawl->out_degree  != 0)
    //     	// FreeHashTable(pCrawl->outNodes);
    //     #if DIRECTED
    //     if(pCrawl->in_degree  != 0)
    //         // FreeHashTable(pCrawl->inNodes);
    //     #endif
       
    // }

    
    free(graphCluster->clusters);
    free(graphCluster);
}

