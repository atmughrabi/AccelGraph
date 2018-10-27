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
float calculateModularityGain(__u32 v,struct GraphCSR* graph);

#endif