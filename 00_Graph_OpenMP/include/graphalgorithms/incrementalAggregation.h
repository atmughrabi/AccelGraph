#ifndef INCREMENTALAGGREGATION_H
#define INCREMENTALAGGREGATION_H

#include "arrayQueue.h"
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// struct __attribute__((__packed__)) Atom{
// 	__u32 degree;
// 	__u32 child;
// }


// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void incrementalAggregationGraphCSR(struct GraphCSR *graph);
void findBestDestination(struct ArrayQueue *Neighbors,struct ArrayQueue *reachableSet,float *deltaQ, __u32 *u, __u32 v, __u32 *weightSum, __u32 *dest, __u32 *atomDegree, __u32 *atomChild, __u32 *sibling, struct GraphCSR *graph);
void traversDendrogramReachableSetDFS(__u32 v, __u32 *atomChild, __u32 *sibling, struct ArrayQueue *reachableSet);
void printSet(struct ArrayQueue *Set);
void returnReachableSetOfNodesFromDendrogram(__u32 v, __u32 *atomChild, __u32 *sibling, struct ArrayQueue *reachableSet);

void returnLabelsOfNodesFromDendrogram(struct ArrayQueue *reachableSet , __u32 *atomChild, __u32 *sibling);
void traversDendrogramLabelsDFS(__u32 *newLables, __u32 v, __u32 *atomChild, __u32 *sibling);

#endif