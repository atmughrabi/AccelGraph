#!/usr/bin/env python
import sys

datastructure = int(sys.argv[1])
algorithm = int(sys.argv[2])
direction = int(sys.argv[3])

workloads_csr = [["bottomUpStepGraphCSRKernelAladdin","topDownStepGraphCSRKernelAladdin"],["pageRankPullGraphCSRKernelAladdin", "pageRankPushGraphCSRKernelAladdin",
				 "pageRankPullFixedPointGraphCSRKernelAladdin","pageRankPushFixedPointGraphCSRKernelAladdin",
				 "pageRankPullQuantizationGraphCSRKernelAladdin","pageRankPushQuantizationGraphCSRKernelAladdin",
				 "pageRankDataDrivenPullGraphCSRKernelAladdin","pageRankDataDrivenPushGraphCSRKernelAladdin",
				 "pageRankDataDrivenPullPushGraphCSRKernelAladdin"]]

workloads_grid = [[],["pageRankPullRowGraphGridKernelAladdin", "pageRankPushColumnGraphGridKernelAladdin",
				 "pageRankPullRowFixedPointGraphGridKernelAladdin","pageRankPushColumnFixedPointGraphGridKernelAladdin"]]



accel_graph = [workloads_csr,workloads_grid]

try:
	print(accel_graph[datastructure][algorithm][direction])
except IndexError:
 	print(" ")
    