#ifndef ARRAYQUEUE_H
#define ARRAYQUEUE_H

#include <linux/types.h>
#include "bitmap.h"

struct __attribute__((__packed__)) ArrayQueue
{
	__u32 head;
	__u32 tail;
	__u32 tail_next;
	__u32 size;
	__u32 iteration;
	__u32 processed_nodes;
	__u32* queue;
	struct Bitmap* bitmap;
	struct Bitmap* bitmap_next;

};


struct ArrayQueue *newArrayQueue (__u32 size);
void 	freeArrayQueue	(struct ArrayQueue *q);
void	 enArrayQueue 	(struct ArrayQueue *q, __u32 k);
__u32 	deArrayQueue	(struct ArrayQueue *q);
__u32 	frontArrayQueue (struct ArrayQueue *q);
__u8  isEmptyArrayQueue (struct ArrayQueue *q);
__u8  isEnArrayQueued 	(struct ArrayQueue *q, __u32 k);
void enArrayQueueDelayed (struct ArrayQueue *q, __u32 k);
void slideWindowArrayQueue (struct ArrayQueue *q);
__u8 isEmptyArrayQueueNext (struct ArrayQueue *q);
__u8 isEmptyArrayQueueCurr (struct ArrayQueue *q);
__u32 sizeArrayQueueCurr(struct ArrayQueue *q);
__u32 sizeArrayQueueNext(struct ArrayQueue *q);
__u32 sizeArrayQueue(struct ArrayQueue *q);
__u8  isEnArrayQueuedNext 	(struct ArrayQueue *q, __u32 k);
void flushArrayQueueToShared(struct ArrayQueue *local_q, struct ArrayQueue *shared_q);
void arrayQueueToBitmap(struct ArrayQueue *q);
void bitmapToArrayQueue(struct ArrayQueue *q);

#endif


