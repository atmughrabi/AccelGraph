#!/usr/bin/env python
import sys

datastructure = int(sys.argv[1])
algorithm = int(sys.argv[2])
direction = int(sys.argv[3])

datastructure_arr = ["CSR","Grid","AdjLinkedList","AdjArrayList"]

workloads_csr = [["BFS_pull","BFS_push"],["PageRank_pull", "PageRank_push",
				 "PageRank_pull_FixedPoint","PageRank_push_FixedPoint",
				 "PageRank_pull_Quant","PageRank_push_Quant",
				 "PageRank_DD_pull","PageRank_DD_push",
				 "PageRank_DD_pullpush"]]

workloads_grid = [[],["PageRank_pull_row", "PageRank_push_col",
				 "PageRank_pull_row_FixedPoint","PageRank_push_col_FixedPoint"]]



# accel_graph = [workloads_csr,workloads_grid]

try:
	print("cu_" + datastructure_arr[datastructure] + "_" + workloads_csr[algorithm][direction])
except IndexError:
 	print(" ")
    