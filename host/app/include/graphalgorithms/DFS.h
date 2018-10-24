#ifndef DFS_H
#define DFS_H

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"
#include "arrayStack.h"
#include "bitmap.h"

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void depthFirstSearchGraphCSR(__u32 source, struct GraphCSR* graph);
void depthFirstSearchGraphCSRBase(__u32 source, struct GraphCSR* graph);


#endif