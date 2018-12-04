#include <linux/types.h>
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"
#include "edgeList.h"

// struct BellmanFordStats{
// 	__u32* Distances;
// 	__u32* parents;
// };

// ********************************************************************************************
// ***************					Auxiliary functions  	  					 **************
// ********************************************************************************************

struct BellmanFordStats* newBellmanFordStatst( __u32 num_vertices);
void bellmanFordRelax(struct Edge*, struct BellmanFordStats* stats);

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

void bellmanFordGraphGrid(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphGrid* graph);
struct BellmanFordStats* bellmanFordPullRowGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph);
struct BellmanFordStats* bellmanFordPushColumnGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph);

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void bellmanFordGraphCSR(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph);

struct BellmanFordStats* bellmanFordDataDrivenPullGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph);
struct BellmanFordStats* bellmanFordDataDrivenPushGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph);

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

void bellmanFordGraphAdjArrayList(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList* graph);


struct BellmanFordStats* bellmanFordDataDrivenPullGraphAdjArrayList(__u32 source,  __u32 iterations, struct GraphAdjArrayList* graph);
struct BellmanFordStats* bellmanFordDataDrivenPushGraphAdjArrayList(__u32 source,  __u32 iterations, struct GraphAdjArrayList* graph);

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************

void bellmanFordGraphAdjLinkedList(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList* graph);

struct BellmanFordStats* bellmanFordPullGraphAdjLinkedList(__u32 source,  __u32 iterations, struct GraphAdjLinkedList* graph);
struct BellmanFordStats* bellmanFordPushGraphAdjLinkedList(__u32 source,  __u32 iterations, struct GraphAdjLinkedList* graph);
