#ifndef ARRAYQUEUE_H
#define ARRAYQUEUE_H

#include <linux/types.h>
#include "bitmap.h"

struct __attribute__((__packed__)) ArrayQueue
{
	__u32 head;
	__u32 tail;
	__u32* queue;
	struct Bitmap*;
	__u32 size;

};












