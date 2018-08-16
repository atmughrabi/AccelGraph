#ifndef GRID_H
#define GRID_H

#include <linux/types.h>

#include "edgeList.h"
#include "vertex.h"
#include "graphConfig.h"

// A structure to represent an adjacency list
struct __attribute__((__packed__)) Partition {

	// __u32 src_range;
	// __u32 dest_range;
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
	__u32 *activePartitions;
};


void gridPrint(struct Grid *grid);
struct Grid * gridNew(struct EdgeList* edgeList);
void  gridFree(struct Grid *grid);


struct Grid * gridPartitionSizePreprocessing(struct Grid *grid, struct EdgeList* edgeList);
__u32 gridCalculatePartitions(struct EdgeList* edgeList);
struct Grid * gridPartitionsMemoryAllocations(struct Grid *grid);
struct Grid * gridPartitionEdgePopulation(struct Grid *grid, struct EdgeList* edgeList);
void   graphGridSetActivePartitions(struct Grid *grid, __u32 vertex);
void   graphGridResetActivePartitions(struct Grid *grid);
// void   graphGridMapVerticesInPartitions(struct Grid *grid);

__u32 getPartitionID(__u32 vertices, __u32 partitions, __u32 vertex_id);
__u32 getPartitionRangeBegin(__u32 vertices, __u32 partitions, __u32 partition_id);
__u32 getPartitionRangeEnd(__u32 vertices, __u32 partitions, __u32 partition_id);

#endif