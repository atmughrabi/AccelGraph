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
__u32 topDownStepDFSGraphCSR(struct GraphCSR* graph, struct ArrayStack* sharedFrontierStack,  struct ArrayStack** localFrontierStacks);
__u32 bottomUpStepDFSGraphCSR(struct GraphCSR* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext);



#endif