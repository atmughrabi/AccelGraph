#ifndef GRAPHGRID_H
#define GRAPHGRID_H

#include <linux/types.h>

#include "edgeList.h"
#include "grid.h"
#include "graphConfig.h"


// A structure to represent an adjacency list
struct  GraphGrid {

	__u32 num_edges;
	__u32 num_vertices;
	
	#if WEIGHTED
	__u32 max_weight;
	#endif

	
	struct Grid* grid;
	

};

void  graphGridReset(struct GraphGrid *graphGrid);
void  graphGridPrint(struct GraphGrid *graphGrid);
struct GraphGrid * graphGridNew(struct EdgeList* edgeList);
void   graphGridFree(struct GraphGrid *graphGrid);
void   graphGridPrintMessageWithtime(const char * msg, double time);
struct GraphGrid* graphGridPreProcessingStep (const char * fnameb, __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted);

#endif