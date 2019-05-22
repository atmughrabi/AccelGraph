#ifndef HASH_H
#define HASH_H


#include <linux/types.h>

__u32 magicHash32(__u32 x);
__u32 magicHash32Reverse(__u32 x);
__u64 magicHash64(__u64 x);
__u64 magicHash64Reverse(__u64 x);


#endif