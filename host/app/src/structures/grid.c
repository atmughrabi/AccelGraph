#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "grid.h"
#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphConfig.h"


void gridPrint(struct Grid *grid){



}
struct Grid * gridNew(struct EdgeList* edgeList){




}
void  gridFree(struct Grid *grid){



}


struct Grid * gridPartitionSizePreprocessing(struct EdgeList* edgeList){



}
__u32 gridCalculatePartitions(struct EdgeList* edgeList){




}
__u32 gridGetPartitionIndexFromEdge(struct Edge* edgeList){




}
struct Partition* gridIteratePartitions(__u32 start){




}
struct Partition* gridIteratePartitionEdges(struct Partition* partition, __u32 start){



	return partition;
}
