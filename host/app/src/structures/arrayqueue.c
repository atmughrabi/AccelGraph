#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "mymalloc.h"
#include "arrayqueue.h"


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

    #if ALIGNED
		arrayQueue->queue = (__u32*) my_aligned_alloc(size*sizeof(__u32));
	#else
        arrayQueue->queue = (__u32*) my_malloc(size*sizeof(__u32));
	#endif

    arrayQueue->bitmap = newBitmap(size);


    return arrayQueue;

}

void freeArrayQueue(struct ArrayQueue *q){

	freeBitmap(q->bitmap);
	free(q->queue);
	free(q);

}

void enArrayQueue (struct ArrayQueue *q, __u32 k){

	q->queue[q->tail] = k;
	setBit(q->bitmap, k);
	q->tail = q->tail_next;
	q->tail++;
	q->tail_next++;

}


void enArrayQueueDelayed (struct ArrayQueue *q, __u32 k){

	q->queue[q->tail_next] = k;
	setBit(q->bitmap, k);
	q->tail_next++;

}


void slideWindowArrayQueue (struct ArrayQueue *q){

	q->head = q->tail;
	q->tail = q->tail_next;
	q->iteration++;

}



__u32 deArrayQueue(struct ArrayQueue *q){

	__u32 k = q->queue[q->head];

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

// struct ArrayQueue *unionArrayQueued (struct ArrayQueue *q1, struct ArrayQueue *q2);