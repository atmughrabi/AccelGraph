#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <linux/types.h>
#include <omp.h>

#include "myMalloc.h"
#include "arrayQueue.h"
#include "bitmap.h"

struct ArrayQueue *newArrayQueue(__u32 size){

	#if ALIGNED
		struct ArrayQueue* arrayQueue = (struct ArrayQueue*) my_aligned_alloc( sizeof(struct ArrayQueue));
	#else
        struct ArrayQueue* arrayQueue = (struct ArrayQueue*) my_malloc( sizeof(struct ArrayQueue));
	#endif

    arrayQueue->head = 0;
    arrayQueue->tail = 0;
    arrayQueue->tail_next = 0;
    arrayQueue->size = size;
    arrayQueue->iteration = 0;
    arrayQueue->processed_nodes = 0;


    #if ALIGNED
		arrayQueue->queue = (__u32*) my_aligned_alloc(size*sizeof(__u32));
	#else
        arrayQueue->queue = (__u32*) my_malloc(size*sizeof(__u32));
	#endif

    arrayQueue->bitmap = newBitmap(size);

    arrayQueue->bitmap_next = newBitmap(size);


    return arrayQueue;

}

void freeArrayQueue(struct ArrayQueue *q){

	freeBitmap(q->bitmap_next);
	freeBitmap(q->bitmap);
	free(q->queue);
	free(q);

}

void enArrayQueue (struct ArrayQueue *q, __u32 k){

	q->queue[q->tail] = k;
	// setBit(q->bitmap, k);
	// setBit(q->bitmap_next, k);
	q->tail = q->tail_next;
	q->tail++;
	q->tail_next++;

}


void enArrayQueueDelayed (struct ArrayQueue *q, __u32 k){

	q->queue[q->tail_next] = k;
	// setBit(q->bitmap_next, k);
	q->tail_next++;

}

void enArrayQueueDelayedBitmap (struct ArrayQueue *q, __u32 k){

	// q->queue[q->tail_next] = k;
	setBit(q->bitmap_next, k);
	// q->tail_next++;

}


void slideWindowArrayQueue (struct ArrayQueue *q){

	// if(q->tail_next > q->tail){
		q->head = q->tail;
		q->tail = q->tail_next;
		
		// reset(q->bitmap);
		// q->bitmap = orBitmap(q->bitmap,q->bitmap_next);
	// }
	
}



__u32 deArrayQueue(struct ArrayQueue *q){

	__u32 k = q->queue[q->head];
	// clearBit(q->bitmap,k);
	q->head++;

	return k;

}

__u32 frontArrayQueue (struct ArrayQueue *q){

	__u32 k = q->queue[q->head];

	return k;

}

__u8 isEmptyArrayQueueCurr (struct ArrayQueue *q){

  if((q->tail > q->head))
  	return 0;
  else
  	return 1;

}

__u8 isEmptyArrayQueue (struct ArrayQueue *q){

  if(!isEmptyArrayQueueCurr(q) || !isEmptyArrayQueueNext(q))
  	return 0;
  else
  	return 1;

}

__u8 isEmptyArrayQueueNext (struct ArrayQueue *q){

  if((q->tail_next > q->head))
  	return 0;
  else
  	return 1;

}

__u8  isEnArrayQueued 	(struct ArrayQueue *q, __u32 k){


	return getBit(q->bitmap, k);

}

__u8  isEnArrayQueuedNext 	(struct ArrayQueue *q, __u32 k){


	return getBit(q->bitmap_next, k);

}

__u32 sizeArrayQueueCurr(struct ArrayQueue *q){

	return q->tail - q->head;

}

__u32 sizeArrayQueueNext(struct ArrayQueue *q){

	return q->tail_next - q->tail;
}


__u32 sizeArrayQueue(struct ArrayQueue *q){

	return q->tail_next - q->head;

}

void flushArrayQueueToShared(struct ArrayQueue *local_q, struct ArrayQueue *shared_q){

__u32 i;

__u32 shared_q_tail_next = 0;
__u32 local_q_tail = 0;
local_q_tail = local_q->tail;

	#pragma omp critical
	{
		shared_q_tail_next = shared_q->tail_next;	
		shared_q->tail_next += local_q_tail;
	}


	for(i = local_q->head ; i < local_q->tail; i++){

		shared_q->queue[shared_q_tail_next] = local_q->queue[i];
		shared_q_tail_next++;

	}

	local_q->head = 0;
    local_q->tail = 0;
    local_q->tail_next = 0;


}

void arrayQueueToBitmap(struct ArrayQueue *q){

	__u32 v;
	__u32 i;
	// printf("Q-Bit %u -> %u \n", q->head, q->tail );
	for(i = q->head ; i < q->tail; i++){
		// printf("%u \n", i );
		v = q->queue[i];
		// printf("%u \n", v );
		setBit(q->bitmap, v);
		// q->head++;
	}

	q->head = q->tail;


}

void bitmapToArrayQueue(struct ArrayQueue *q){
	__u32 i;

	for(i= 0 ; i < (q->bitmap->size); i++){
		if(getBit(q->bitmap, i)){
			q->queue[q->tail] = i;
			q->tail++;
		}
		
	}

	q->tail_next = q->tail;

}

// struct ArrayQueue *unionArrayQueued (struct ArrayQueue *q1, struct ArrayQueue *q2);