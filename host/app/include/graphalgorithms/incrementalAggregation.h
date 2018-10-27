#ifndef INCREMENTALAGGREGATION_H
#define INCREMENTALAGGREGATION_H

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void incrementalAggregationGraphCSR(struct GraphCSR* graph);
void calculateModularityGain(float *deltaQ, __u32 *u, __u32 v, struct GraphCSR* graph);

#endif