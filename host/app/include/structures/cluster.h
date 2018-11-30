#ifndef CLUSTER_H
#define CLUSTER_H

#include <linux/types.h>
#include "graphCSR.h"
#include "libchash.h"
// ********************************************************************************************
// ***************                  Clustered Graph DataStructure                **************
// ********************************************************************************************



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

    __u32* mergedCluster;
    struct Cluster* clusters;
    struct GraphCSR* clustersCSR;
    __u32  edge_index;
    struct HashTable* edgesHash;

};

struct GraphCluster * graphClusterNew(__u32 V, __u32 E);
void graphClusterFree(struct GraphCluster* graphCluster);
void initClusterGraphCSR(struct GraphCSR* graph, struct GraphCluster* graphCluster, __u32 v);
void mergeCluster(struct Cluster* cluster1, struct Cluster* cluster2, struct Bitmap * mergeEdgeBitmap, __u32* dest);
void graphClusterPrint(struct GraphCluster* graphCluster);
void clusterPrint(struct Cluster* cluster);


#endif