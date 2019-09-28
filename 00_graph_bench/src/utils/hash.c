// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : hash.c
// Create : 2019-06-21 17:15:17
// Revise : 2019-09-28 15:37:12
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------
#include <linux/types.h>
#include "hash.h"

__u32 magicHash32(__u32 x)
{
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = (x >> 16) ^ x;
    return x;
}

__u32 magicHash32Reverse(__u32 x)
{
    x = ((x >> 16) ^ x) * 0x119de1f3;
    x = ((x >> 16) ^ x) * 0x119de1f3;
    x = (x >> 16) ^ x;
    return x;
}


__u64 magicHash64(__u64 x)
{
    x = (x ^ (x >> 30)) * (__u64)0xbf58476d1ce4e5b9;
    x = (x ^ (x >> 27)) * (__u64)0x94d049bb133111eb;
    x = x ^ (x >> 31);
    return x;
}

__u64 magicHash64Reverse(__u64 x)
{
    x = (x ^ (x >> 31) ^ (x >> 62)) * (__u64)0x319642b2d24d8ec3;
    x = (x ^ (x >> 27) ^ (x >> 54)) * (__u64)0x96de1b173f119089;
    x = x ^ (x >> 30) ^ (x >> 60);
    return x;
}

