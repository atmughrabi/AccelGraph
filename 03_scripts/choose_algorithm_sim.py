#!/usr/bin/env python
import sys

datastructure = int(sys.argv[1])
algorithm = int(sys.argv[2])
direction = int(sys.argv[3])
cu_count = sys.argv[4]


graph_algorithm_arr = ["cu_BFS","cu_PageRank","",""]
data_structure_arr = ["CSR","Grid","AdjLinkedList","AdjArrayList"]
 
direction_arr = [
				["PULL","PUSH","PULLPUSH","PUSH","PULLPUSH"],
				["PULL", "PUSH",
				 "PULL","PUSH",
				 "PULL","PUSH",
				 "PULL","PUSH",
				 "PULLPUSH","PULL","PULL","PULL","PULL","PULL"]
				 ]

precision_arr = [["BottomUp","NONE"],["FloatPoint", "FloatPoint",
				 "FixedPoint","FixedPoint",
				 "Quantized","Quantized",
				 "FloatPoint","FloatPoint",
				 "FloatPoint","FixedPoint","FixedPoint","FixedPoint","Quantized","Quantized"]]

# workloads_grid = [[],["PageRank_pull_row", "PageRank_push_col",
# 				 "PageRank_pull_row_FixedPoint","PageRank_push_col_FixedPoint"]]

# accel_graph = [workloads_csr,workloads_grid]

set_variables = "set graph_algorithm " + graph_algorithm_arr[algorithm] + " ;" + "set data_structure " + data_structure_arr[datastructure] + " ;" + "set direction " + direction_arr[algorithm][direction] + " ;" + "set cu_precision " + precision_arr[algorithm][direction] + " ;" + "set cu_count " + cu_count + " ;"

try:
	print(set_variables)
except IndexError:
 	print(" ")
 