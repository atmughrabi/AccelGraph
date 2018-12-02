#ifndef INCREMENTALAGGREGATION_H
#define INCREMENTALAGGREGATION_H

#include "arrayQueue.h"
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"
#include "cluster.h"

// ********************************************************************************************
// ***************					Incremental Aggregation DataStructures		 **************
// ********************************************************************************************

// struct Dendrogram
// {
// 	__u32 * atomChild;
// 	__u32 * sibling;
	
// };


// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void incrementalAggregationGraphCSR(struct GraphCSR* graph);
void findBestDestination(float *deltaQ, __u32 *u, __u32 v, __u32* weightSum, __u32* dest, __u32* atomDegree, __u32* atomChild,__u32* sibling, struct GraphCSR* graph, struct ArrayQueue* reachableSet, struct ArrayQueue* Neighbors, struct Bitmap * mergeEdgeBitmap,struct GraphCluster* graphCluster);
void traversDendrogramReachableSetDFS(__u32 v,__u32* atomChild,__u32* sibling,struct ArrayQueue* reachableSet);
void printSet(struct ArrayQueue* Set);
void returnReachableSetOfNodesFromDendrogram(__u32 v,__u32* atomChild,__u32* sibling, struct ArrayQueue* reachableSet);
void modularityGain(float *deltaQ, __u32 *u, __u32 v, __u32* dest,float numEdgesm , __u32* atomDegree, struct GraphCSR* graph);

void mergeClusters(__u32 v, __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest);
void mergeClustersExtra(__u32 v,  __u32 n, __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest);
void compressCluster( __u32 u, struct GraphCSR* graph, struct GraphCluster* graphCluster,  __u32* dest, struct ArrayQueue* Neighbors);


#endif