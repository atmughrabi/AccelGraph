#ifndef CLUSTER_H
#define CLUSTER_H

#include <linux/types.h>
#include "graphCSR.h"
// ********************************************************************************************
// ***************                  Clustered Graph DataStructure                **************
// ********************************************************************************************


// struct  Edge {

//     __u32 src;
//     __u32 dest;
//     #if WEIGHTED
//     __u32 weight;
//     #endif

// };

struct  Cluster{

    __u32 out_degree;
    __u32 sizeOutNodes;
    struct Edge* outNodes;

    #if DIRECTED
        __u32 in_degree;
        __u32 sizeInNodes;
        struct Edge* inNodes;
    #endif

};

struct GraphCluster{

    __u32 num_vertices;
    __u32 num_edges;
    
    struct Cluster* clusters;

    struct Vertex* vertices;
    struct Edge* sorted_edges_array; // sorted edge array

    #if DIRECTED
        struct Vertex* inverse_vertices;
        struct Edge* inverse_sorted_edges_array; // sorted edge array
    #endif
};

struct GraphCluster * graphClusterNew(__u32 V);
void graphClusterFree(struct GraphCluster* graphCluster);
void initClusterGraphCSR(struct GraphCSR* graph, struct GraphCluster* graphCluster, __u32 v);
void mergeCluster(struct Cluster* cluster1, struct Cluster* cluster2, struct Bitmap * mergeEdgeBitmap, __u32* dest);
void graphClusterPrint(struct GraphCluster* graphCluster);
void clusterPrint(struct Cluster* cluster);


#endif