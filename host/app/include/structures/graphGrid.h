#ifndef GRAPHGRID_H
#define GRAPHGRID_H

#include <linux/types.h>

#include "edgeList.h"
#include "grid.h"
#include "graphConfig.h"


// A structure to represent an adjacency list
struct __attribute__((__packed__)) GraphGrid {

	__u32 num_edges;
	__u32 num_vertices;
	struct Grid* grid;

};

void  graphGridPrint(struct GraphGrid *graphGrid);
struct GraphGrid * graphGridNew(struct EdgeList* edgeList);
void   graphGridFree(struct GraphGrid *graphGrid);


#endif