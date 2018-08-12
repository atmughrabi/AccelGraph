#ifndef GRID_H
#define GRID_H

#include <linux/types.h>

#include "edgeList.h"
#include "vertex.h"
#include "graphConfig.h"

// A structure to represent an adjacency list
struct __attribute__((__packed__)) Partition {

	__u32 src_range;
	__u32 dest_range;
	__u32 num_edges;
	__u32 num_vertices;
	struct Vertex* vertices;
	struct EdgeList* edgeList;

};


// A structure to represent an adjacency list
struct __attribute__((__packed__)) Grid {

	__u32 num_edges;
	__u32 num_vertices;
	__u32 num_partitions;
	struct Partition* partitions;

};


void gridPrint(struct Grid *grid);
struct Grid * gridNew(struct EdgeList* edgeList);
void  gridFree(struct Grid *grid);


struct Grid * gridPartitionSizePreprocessing(struct EdgeList* edgeList);
__u32 gridCalculatePartitions(struct EdgeList* edgeList);
__u32 gridGetPartitionIndexFromEdge(struct Edge* edgeList);
struct Partition* gridIteratePartitions(__u32 start);
struct Partition* gridIteratePartitionEdges(struct Partition* partition, __u32 start);


#endif