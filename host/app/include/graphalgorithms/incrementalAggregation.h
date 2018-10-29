#ifndef INCREMENTALAGGREGATION_H
#define INCREMENTALAGGREGATION_H

#include "arrayQueue.h"
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// struct Atom{
// 	__u32 


// }


// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void incrementalAggregationGraphCSR(struct GraphCSR* graph);
void calculateModularityGain(float *deltaQ, __u32 *u, __u32 v, __u32* dest, __u32* atomChild,__u32* sibling, struct GraphCSR* graph);
void traversDendrogramReachableSetDFS(__u32 v,__u32* atomChild,__u32* sibling,struct ArrayQueue* reachableSet);
void printSet(struct ArrayQueue* Set);
struct ArrayQueue* returnReachableSetOfNodesFromDendrogram(__u32 v,__u32* atomChild,__u32* sibling,struct GraphCSR* graph);


#endif