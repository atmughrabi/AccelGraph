// -----------------------------------------------------------------------------
//
//		"00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : BFS_Kernels.c
// Create : 2019-10-11 16:26:36
// Revise : 2019-10-11 19:22:44
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#include "myMalloc.h"

#ifdef GEM5_HARNESS
#include "gem5/gem5_harness.h"
#endif

#include "cache.h"
#include "BFS_Kernels.h"

// you should add these to Aladdin as an extern "aladdin_sys_constants.h"
unsigned ACCELGRAPH = 0x300;

