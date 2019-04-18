
#include <linux/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "graphCSR.h"
#include "myMalloc.h"
#include "epochReorder.h"
#include "bitmap.h"



struct EpochReorder* newEpochReoder( __u32 softThreshold, __u32 hardThreshold, __u32 numCounters, __u32 numVertices){

        // struct EdgeList* newEdgeList = (struct EdgeList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct EdgeList));
		#if ALIGNED
                struct EpochReorder* epochReorder = (struct EpochReorder*) my_aligned_malloc(sizeof(struct EpochReorder));  
        #else
                struct EpochReorder* epochReorder = (struct EpochReorder*) my_malloc(sizeof(struct EpochReorder));
        #endif

		epochReorder->softThreshold = softThreshold;
        epochReorder->hardThreshold = hardThreshold;
        epochReorder->numCounters = numCounters;
        epochReorder->numVertices = numVertices;

        epochReorder->recencyBits = newBitmap(numVertices);

        #if ALIGNED
                epochReorder->frequency = (__u32*) my_aligned_malloc(sizeof(__u32)*numCounters*numVertices);
        #else
                epochReorder->frequency = (__u32*) my_malloc(sizeof(__u32)*numCounters*numVertices);
        #endif
        
        return epochReorder;

}


void epochReorderRecordPageRank(){


}


void epochReorderRecordBFS(){


}


void freeEpochReorder(struct EpochReorder* epochReorder){

	if(epochReorder){
	freeBitmap(epochReorder->recencyBits);
	free( epochReorder->frequency);
	free( epochReorder);
	}
}


