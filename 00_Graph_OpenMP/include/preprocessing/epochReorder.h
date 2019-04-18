#ifndef EPOCHREORDER_H
#define EPOCHREORDER_H

#include <linux/types.h>
#include "graphCSR.h"
#include "bitmap.h"


struct EpochReorder
{

	__u32 softThreshold;
	__u32 hardThreshold;
	__u32 numCounters;  //frequncy[numcounters][numverticies]
	__u32 numVertices;
	__u32* frequency;
	struct Bitmap* recencyBits;

};



struct EpochReorder* newEpochReoder( __u32 softThreshold, __u32 hardThreshold, __u32 numCounters, __u32 numVertices);
void freeEpochReorder(struct EpochReorder* epochReorder);



#endif