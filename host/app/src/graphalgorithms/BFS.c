#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "BFS.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"
// #include "grid.h"

void resetParentArray(int* parents, __u32 V){

	__u32 i;
	 for(i = 0; i < V; i++){
                parents[i] = -1;
     }


}

void bfs(__u32 source, struct GraphCSR* graph){


 printf("*** START BFS *** \n");
 printf("Root node : %u \n", source);

   struct ArrayQueue* queue = newArrayQueue(graph->num_vertices);

   
    __u32 edge_idx = 0;        // used for iteration over the outgoing edges
    // __u32 out_degree = 0;  // index of the vertex, which should be visited
    __u32 new_vertex_idx = 0;  // index of the vertex, which should be visited
    __u32 discovered_nodes = 0;
    __u32 iteration = 0;
    __u32 discovered_nodes_Iter_1 = 0;
    __u32 discovered_nodes_Iter_2 = 0;
    __u32 vertex_idx = 0;      // index of dequeued vertex

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");
    // enqueue the index of the start vertex
    Start(timer);
  
    enArrayQueue(queue, source);
    // graph->vertices[source].visited = 1;
    discovered_nodes++;
    discovered_nodes_Iter_1++;
    discovered_nodes_Iter_2 = discovered_nodes_Iter_1;
  
    // while queue is not empty
    while(!isEmptyArrayQueue(queue)) {

        
        // dequeue the next vertex
        vertex_idx = deArrayQueue(queue);
        discovered_nodes_Iter_2--;

         if(discovered_nodes_Iter_2 == 0){
        	discovered_nodes_Iter_2 = discovered_nodes_Iter_1;
        	Stop(timer);
        	
        	 ;
  		    Start(timer);
  		    iteration++;
        	discovered_nodes_Iter_1 = 0;
        }

        // printf("Visiting vertex: %u \n", vertex_idx);
        
        // process the outgoing edges
        // out_degree = graph->vertices[vertex_idx].out_degree;
        edge_idx = graph->vertices[vertex_idx].edges_idx;

        
        
        if(edge_idx == NO_OUTGOING_EDGES) {
        // if(out_degree == 0) {
            // vertex doesn't have outgoing edges
            continue;
        }
            
        // iterate over the outgoing edges
        while(graph->sorted_edges_array[edge_idx].src == vertex_idx) {
            
            // destination vertex id
            new_vertex_idx = graph->sorted_edges_array[edge_idx].dest;

            // printf("new_vertex_idx: %u \n", new_vertex_idx);
            
            // if the destination vertex is not yet enqueued
            if(!isEnArrayQueued(queue, new_vertex_idx)) {
                
                // add the destination vertex to the queue 
                enArrayQueue(queue, new_vertex_idx);
                // graph->vertices[new_vertex_idx].visited = 1;
                discovered_nodes++;
                discovered_nodes_Iter_1++;
               
            }

            edge_idx++;
        }

       
      
    }
  
		  		
    printf(" -----------------------------------------------------\n");
    Stop(timer);
    printf("Discovered nodes : %u \n", discovered_nodes);

	freeArrayQueue(queue);    
    free(timer);
}



// breadth-first-search(graph, source)
// 	sharedFrontierQueue ← {source}
// 	next ← {}
// 	parents ← [-1,-1,. . . -1]
// 		while sharedFrontierQueue 6= {} do
// 			top-down-step(graph, sharedFrontierQueue, next, parents)
// 			sharedFrontierQueue ← next
// 			next ← {}
// 		end while
// 	return parents

void breadthFirstSearchGraphCSR(__u32 source, struct GraphCSR* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
	double inner_time = 0;
	struct ArrayQueue* sharedFrontierQueue = newArrayQueue(graph->num_vertices);
	struct Bitmap* bitmapCurr = newBitmap(graph->num_vertices);
    struct Bitmap* bitmapNext = newBitmap(graph->num_vertices);

	__u32 P = numThreads;
	__u32 mu = graph->num_edges; // number of edges to check from sharedFrontierQueue
	__u32 mf = graph->vertices[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in sharedFrontierQueue
	__u32 nf_prev = 0; // number of vertices in sharedFrontierQueue
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 20;
	__u32 beta = 20;

	#if ALIGNED
		struct ArrayQueue** localFrontierQueues = (struct ArrayQueue**) my_aligned_alloc( P * sizeof(struct ArrayQueue*));
	#else
        struct ArrayQueue** localFrontierQueues = (struct ArrayQueue**) my_alloc( P * sizeof(struct ArrayQueue*));
    #endif

   __u32 i;
   for(i=0 ; i < P ; i++){
		localFrontierQueues[i] = newArrayQueue(graph->num_vertices);
		
   }


	enArrayQueue(sharedFrontierQueue, source);
    // setBit(sharedFrontierQueue->q_bitmap,source);
	graph->parents[source] = source;  

	// graph->vertices[source].visited = 1;
	printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
	while(!isEmptyArrayQueue(sharedFrontierQueue)){ // start while 

		if(mf > (mu/alpha)){

			arrayQueueToBitmap(sharedFrontierQueue,bitmapCurr);

			nf = sizeArrayQueue(sharedFrontierQueue);
			
			do{

			nf_prev = nf;

			Start(timer_inner);
			nf = bottomUpStepGraphCSR(graph,bitmapCurr,bitmapNext);
			Stop(timer_inner);

			inner_time +=  Seconds(timer_inner);

			swapBitmaps(&bitmapCurr, &bitmapNext);
			reset(bitmapNext);

	
		
			}while(( nf > nf_prev) || // growing;
				   ( nf > (n/beta)));

			bitmapToArrayQueue(bitmapCurr,sharedFrontierQueue);

			mf = 1;

		}else{
		
			mu -= mf;

			Start(timer_inner);
			mf = topDownStepGraphCSR(graph, sharedFrontierQueue,localFrontierQueues);
			Stop(timer_inner);

			inner_time +=  Seconds(timer_inner);

			slideWindowArrayQueue(sharedFrontierQueue);

			// swapBitmaps(&sharedFrontierQueue->q_bitmap, &sharedFrontierQueue->q_bitmap_next);
			// reset(sharedFrontierQueue->q_bitmap_next);

		}



	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes, inner_time);
	printf(" -----------------------------------------------------\n");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", graph->processed_nodes, Seconds(timer));
	printf(" -----------------------------------------------------\n");


	resetParentArray(graph->parents, graph->num_vertices);
	freeArrayQueue(sharedFrontierQueue);
	freeBitmap(bitmapNext);
	freeBitmap(bitmapCurr);
	free(timer);
	free(timer_inner);
}


// top-down-step(graph, sharedFrontierQueue, next, parents)
// 	for v ∈ sharedFrontierQueue do
// 		for u ∈ neighbors[v] do
// 			if parents[u] = -1 then
// 				parents[u] ← v
// 				next ← next ∪ {u}
// 			end if
// 		end for
// 	end for

__u32 topDownStepGraphCSR(struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue** localFrontierQueues){


	
	__u32 v;
	__u32 u;
	__u32 i;
	__u32 j;
	__u32 edge_idx;
	__u32 processed_nodes = 0;
	__u32 processed_nodes_next = 0;
	__u32 mf = 0;

	// struct ArrayQueue* localFrontierQueue = newArrayQueue(graph->num_vertices);

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	#pragma omp parallel default (none) private(u,v,j,i,edge_idx) shared(processed_nodes_next,localFrontierQueues,graph,sharedFrontierQueue,processed_nodes,mf) 
  	{
  		__u32 t_id = omp_get_thread_num();
  		struct ArrayQueue* localFrontierQueue = localFrontierQueues[t_id];
		
  		
  		#pragma omp for reduction(+:mf,processed_nodes,processed_nodes_next) 
		for(i = sharedFrontierQueue->head ; i < sharedFrontierQueue->tail; i++){
			processed_nodes++;
			v = sharedFrontierQueue->queue[i];
			edge_idx = graph->vertices[v].edges_idx;

	    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
	        
	            // destination vertex id
	            u = graph->sorted_edges_array[j].dest;
	            

	            // if the destination vertex is not yet enqueued
	            // if((graph->parents[u]) == (-1)) { // fixed to implement optemizations
	            if((graph->parents[u]) < 0 ){
	            
	                // add the destination vertex to the queue 
	                enArrayQueue(localFrontierQueue, u);
	                mf +=  -(graph->parents[u]);
	                graph->parents[u] = v;  
	                processed_nodes_next++;

	            }
	        }

		} 

		flushArrayQueueToShared(localFrontierQueue,sharedFrontierQueue);
	}
	
	// sharedFrontierQueue->q_bitmap->numSetBits = processed_nodes;
	sharedFrontierQueue->q_bitmap_next->numSetBits = processed_nodes_next;

	Stop(timer);
	printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, processed_nodes, Seconds(timer));
	free(timer);
	graph->processed_nodes += processed_nodes;
	return mf;
}

// breadth-first-search(graph, source)
// 	sharedFrontierQueue ← {source}
// 	next ← {}
// 	parents ← [-1,-1,. . . -1]
// 		while sharedFrontierQueue 6= {} do
// 			top-down-step(graph, sharedFrontierQueue, next, parents)
// 			sharedFrontierQueue ← next
// 			next ← {}
// 		end while
// 	return parents

void breadthFirstSearchUsingBitmapsGraphCSR(__u32 source, struct GraphCSR* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
	double inner_time = 0;
	struct ArrayQueue* sharedFrontierQueue = newArrayQueue(graph->num_vertices);

	__u32 mu = graph->num_edges; // number of edges to check from sharedFrontierQueue
	__u32 mf = graph->vertices[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in sharedFrontierQueue
	__u32 nf_prev = 0; // number of vertices in sharedFrontierQueue
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 20;
	__u32 beta = 20;


    setBit(sharedFrontierQueue->q_bitmap_next,source);
    sharedFrontierQueue->q_bitmap_next->numSetBits = 1;
	graph->parents[source] = source;  

	swapBitmaps(&sharedFrontierQueue->q_bitmap, &sharedFrontierQueue->q_bitmap_next);
	reset(sharedFrontierQueue->q_bitmap_next);


	printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    while (sharedFrontierQueue->q_bitmap->numSetBits){

		if(mf > (mu/alpha)){
		
			nf = sharedFrontierQueue->q_bitmap->numSetBits;
		
			do{

			nf_prev = nf;

			Start(timer_inner);
			nf = bottomUpStepGraphCSR(graph,sharedFrontierQueue->q_bitmap,sharedFrontierQueue->q_bitmap_next);
			Stop(timer_inner);

			inner_time +=  Seconds(timer_inner);

			swapBitmaps(&sharedFrontierQueue->q_bitmap, &sharedFrontierQueue->q_bitmap_next);
			reset(sharedFrontierQueue->q_bitmap_next);

			
			}while(( nf > nf_prev) || // growing;
				   ( nf > (n/beta)));


			mf = 1;

		}else{
		
			mu -= mf;

			Start(timer_inner);
			mf = topDownStepUsingBitmapsGraphCSR(graph, sharedFrontierQueue);
			Stop(timer_inner);

			inner_time +=  Seconds(timer_inner);

			swapBitmaps(&sharedFrontierQueue->q_bitmap, &sharedFrontierQueue->q_bitmap_next);
			reset(sharedFrontierQueue->q_bitmap_next);

		}



	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","No OverHead", graph->processed_nodes, inner_time);
	printf(" -----------------------------------------------------\n");
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","total", graph->processed_nodes, Seconds(timer));
	printf(" -----------------------------------------------------\n");


	resetParentArray(graph->parents, graph->num_vertices);
	freeArrayQueue(sharedFrontierQueue);
	free(timer);
	free(timer_inner);
}


__u32 topDownStepUsingBitmapsGraphCSR(struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue){


	
	__u32 v;
	__u32 u;
	__u32 i;
	__u32 j;
	__u32 edge_idx;
	__u32 processed_nodes = sharedFrontierQueue->q_bitmap->numSetBits;
	__u32 processed_nodes_next = 0;
	__u32 mf = 0;

	// struct ArrayQueue* localFrontierQueue = newArrayQueue(graph->num_vertices);
	graph->processed_nodes += processed_nodes;

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);


	#pragma omp parallel default (none) private(u,v,j,i,edge_idx) shared(graph,sharedFrontierQueue,processed_nodes_next,mf) 
  	{
  		
  		
  		#pragma omp for reduction(+:mf,processed_nodes_next) schedule (dynamic , 1024)
		for(i= 0 ; i < (sharedFrontierQueue->q_bitmap->size); i++){
		if(getBit(sharedFrontierQueue->q_bitmap, i)){
			// processed_nodes++;
			v = i;
			edge_idx = graph->vertices[v].edges_idx;

	    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
	        
	       
	            u = graph->sorted_edges_array[j].dest;
	            int u_parent = graph->parents[u];
	         
	            if(u_parent < 0 ){
				if(__sync_bool_compare_and_swap(&graph->parents[u],u_parent,v))
					{	
		                mf +=  -(u_parent);
		                setBit(sharedFrontierQueue->q_bitmap_next, u);
		                processed_nodes_next++;

		            }

	            }
	        }

		} 

	}

}

	// sharedFrontierQueue->q_bitmap->numSetBits = processed_nodes;
	sharedFrontierQueue->q_bitmap_next->numSetBits = processed_nodes_next;

	Stop(timer);
	printf("| TD %-12u | %-15u | %-15f | \n",graph->iteration++, processed_nodes, Seconds(timer));
	free(timer);
	
	return mf;
}




// bottom-up-step(graph, sharedFrontierQueue, next, parents) //pull
// 	for v ∈ vertices do
// 		if parents[v] = -1 then
// 			for u ∈ neighbors[v] do
// 				if u ∈ sharedFrontierQueue then
// 				parents[v] ← u
// 				next ← next ∪ {v}
// 				break
// 				end if
// 			end for
// 		end if
// 	end for

__u32 bottomUpStepGraphCSR(struct GraphCSR* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext){


	__u32 v;
	__u32 u;
	__u32 j;
	__u32 edge_idx;
	__u32 out_degree;
	struct Vertex* vertices = NULL;
	struct Edge* sorted_edges_array = NULL;

	// __u32 processed_nodes = getNumOfSetBits(bitmapCurr);
	 __u32 processed_nodes_next = 0;
	 __u32 processed_nodes = bitmapCurr->numSetBits;
    __u32 nf = 0; // number of vertices in sharedFrontierQueue
    graph->processed_nodes += processed_nodes;

    #if DIRECTED
		vertices = graph->inverse_vertices;
		sorted_edges_array = graph->inverse_sorted_edges_array;
	#else
		vertices = graph->vertices;
		sorted_edges_array = graph->sorted_edges_array;
	#endif

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	#pragma omp parallel for default(none) private(j,u,v,out_degree,edge_idx) shared(bitmapCurr,bitmapNext,graph,vertices,sorted_edges_array) reduction(+:nf, processed_nodes_next)  
	for(v=0 ; v < graph->num_vertices ; v++){
				out_degree = vertices[v].out_degree;
				if(graph->parents[v] < 0){ // optmization 
					edge_idx = vertices[v].edges_idx;

		    		for(j = edge_idx ; j < (edge_idx + out_degree) ; j++){
		    			 u = sorted_edges_array[j].dest;
		    			 if(getBit(bitmapCurr, u)){
		    			 	graph->parents[v] = u;
		    			 	setBit(bitmapNext, v);
		    			 	processed_nodes_next++;
		    			 	nf++;
		    			 	break;
		    			 }
		    		}

		    	}
    	
	}

	bitmapNext->numSetBits = processed_nodes_next;
	
	Stop(timer);
	printf("| BU %-12u | %-15u | %-15f | \n",graph->iteration++, processed_nodes , Seconds(timer));
	free(timer);
	return nf;
}

// function STREAMVERTICES(Fv,F)
// 	Sum = 0
// 		for each vertex do
// 			if F(vertex) then
// 				Sum += Fv(edge)
// 			end if
// 		end for
// 	return Sum
// end function

// function STREAMEDGES(Fe,F)
// 	Sum = 0
// 		for each active block do >> block with active edges
// 			for each edge ∈ block do
// 				if F(edge.source) then
// 					Sum += Fe(edge)
// 				end if
// 			end for
// 		end for
// 	return Sum
// end function
//we assume that the edges are not sorted in each partition

void breadthFirstSearchGraphGrid(__u32 source, struct GraphGrid* graph){

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct Timer* timer_iteration = (struct Timer*) malloc(sizeof(struct Timer));
	struct ArrayQueue* sharedFrontierQueue = newArrayQueue(graph->num_vertices);
	__u32 P = numThreads;

	#if ALIGNED
		struct ArrayQueue** localFrontierQueues = (struct ArrayQueue**) my_aligned_alloc( P * sizeof(struct ArrayQueue*));
	#else
        struct ArrayQueue** localFrontierQueues = (struct ArrayQueue**) my_aligned_alloc( P * sizeof(struct ArrayQueue*));
    #endif

   __u32 i;
   for(i=0 ; i < P ; i++){
		localFrontierQueues[i] = newArrayQueue(graph->num_vertices);
	}


		
	__u32 processed_nodes = 0;

	enArrayQueue(sharedFrontierQueue, source);
	graph->parents[source] = source;
	graphGridSetActivePartitions(graph->grid, source);

	printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
	while(!isEmptyArrayQueue(sharedFrontierQueue)){ // start while 

		 Start(timer_iteration);
			breadthFirstSearchStreamEdgesGraphGrid(graph, sharedFrontierQueue, localFrontierQueues);
			processed_nodes = sharedFrontierQueue->tail - sharedFrontierQueue->head;
			slideWindowArrayQueue(sharedFrontierQueue);
			breadthFirstSearchSetActivePartitions(graph,sharedFrontierQueue);
		 Stop(timer_iteration);
		 printf("| %-15u | %-15u | %-15f | \n",graph->iteration++, processed_nodes, Seconds(timer_iteration));
	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","**", sharedFrontierQueue->tail_next, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	resetParentArray(graph->parents, graph->num_vertices);
	freeArrayQueue(sharedFrontierQueue);
	for(i=0 ; i < P ; i++){
		freeArrayQueue(localFrontierQueues[i]);
	}	
	free(localFrontierQueues);
	free(timer_iteration);
	free(timer);
}

// function STREAMEDGES(Fe,F)
// 	Sum = 0
// 		for each active block do >> block with active edges
// 			for each edge ∈ block do
// 				if F(edge.source) then
// 					Sum += Fe(edge)
// 				end if
// 			end for
// 		end for
// 	return Sum
// end function
//we assume that the edges are not sorted in each partition
void breadthFirstSearchStreamEdgesGraphGrid(struct GraphGrid* graph, struct ArrayQueue* sharedFrontierQueue,  struct ArrayQueue** localFrontierQueues){
	// struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	__u32 totalPartitions = 0;
     totalPartitions = graph->grid->num_partitions * graph->grid->num_partitions; // PxP
    __u32 i;	

	#pragma omp parallel
    #pragma	omp single nowait
    {	
   
    	for (i = 0; i < totalPartitions; ++i){
           		if(graph->grid->activePartitions[i]){
           			#pragma	omp task untied
           			{
           				__u32 t_id = omp_get_thread_num();

                        struct ArrayQueue* localFrontierQueue = localFrontierQueues[t_id];
	            		breadthFirstSearchPartitionGraphGrid(graph,&(graph->grid->partitions[i]),sharedFrontierQueue,localFrontierQueue);
           				flushArrayQueueToShared(localFrontierQueue,sharedFrontierQueue);
           			}
			    		
        	} 
        }
    }

        // flushArrayQueueToShared(localFrontierQueue,sharedFrontierQueue);
	// }
}
   
   
void breadthFirstSearchPartitionGraphGrid(struct GraphGrid* graph, struct Partition* partition,struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue* localFrontierQueue){

	 __u32 i;
	 __u32 src;
	 __u32 dest;

 
	// #pragma omp parallel default(none) private(i,src,dest) shared(graph,partition,sharedFrontierQueue,localFrontierQueue)
 //    {
    	
 //        // __u32 t_id = omp_get_thread_num();
 //        // struct ArrayQueue* localFrontierQueue = newArrayQueue(graph->num_vertices);
   
	// 	#pragma omp for
	    for (i = 0; i < partition->num_edges; ++i){
	    	src  = partition->edgeList->edges_array[i].src;
	        dest = partition->edgeList->edges_array[i].dest;
	        int v_dest = graph->parents[dest];
			if(isEnArrayQueued(sharedFrontierQueue, src) && (v_dest < 0)){
						if(__sync_bool_compare_and_swap(&graph->parents[dest],v_dest,src))
						{
			    		// graph->parents[dest] = src;
			    		enArrayQueue(localFrontierQueue, dest);
			    	}
			}
		}
		
			// flushArrayQueueToShared(localFrontierQueue,sharedFrontierQueue);
	// }

	
}

void breadthFirstSearchSetActivePartitions(struct GraphGrid* graph, struct ArrayQueue* sharedFrontierQueue){

	 __u32 i;
	 __u32 v;

	graphGridResetActivePartitions(graph->grid);

    for(i = sharedFrontierQueue->head ; i < sharedFrontierQueue->tail; i++){
    	v = sharedFrontierQueue->queue[i];
    	graphGridSetActivePartitions(graph->grid, v);
    }
}


// breadth-first-search(graph, source)
// 	sharedFrontierQueue ← {source}
// 	next ← {}
// 	parents ← [-1,-1,. . . -1]
// 		while sharedFrontierQueue 6= {} do
// 			top-down-step(graph, sharedFrontierQueue, next, parents)
// 			sharedFrontierQueue ← next
// 			next ← {}
// 		end while
// 	return parents


void breadthFirstSearchGraphAdjArrayList(__u32 source, struct GraphAdjArrayList* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct ArrayQueue* sharedFrontierQueue = newArrayQueue(graph->num_vertices);
	
	// enArrayQueueDelayed(sharedFrontierQueue, source);
	// slideWindowArrayQueue(sharedFrontierQueue);

	

	__u32 mu = graph->num_edges; // number of edges to check from sharedFrontierQueue
	__u32 mf = graph->parent_array[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in sharedFrontierQueue
	__u32 nf_prev = 0; // number of vertices in sharedFrontierQueue
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 14;
	__u32 beta = 24;


	enArrayQueue(sharedFrontierQueue, source);
	graph->parents[source] = source;  

	// graph->vertices[source].visited = 1;
	printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
	while(!isEmptyArrayQueue(sharedFrontierQueue)){ // start while 

		if(mf > (mu/alpha)){


			nf = sizeArrayQueue(sharedFrontierQueue);
			// slideWindowArrayQueue(sharedFrontierQueue);
			

			do{

			nf_prev = nf;
			nf = bottomUpStepGraphAdjArrayList(graph, sharedFrontierQueue);
			slideWindowArrayQueue(sharedFrontierQueue);

		
			}while(( nf > nf_prev) || // growing;
				   ( nf > (n/beta)));
			
			mf = 1;

		}else{
		
			mu -= mf;
			mf = topDownStepGraphAdjArrayList(graph, sharedFrontierQueue);
			slideWindowArrayQueue(sharedFrontierQueue);

		}


	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","**", sharedFrontierQueue->tail_next, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	resetParentArray(graph->parents, graph->num_vertices);
	freeArrayQueue(sharedFrontierQueue);
	free(timer);
}


// top-down-step(graph, sharedFrontierQueue, next, parents)
// 	for v ∈ sharedFrontierQueue do
// 		for u ∈ neighbors[v] do
// 			if parents[u] = -1 then
// 				parents[u] ← v
// 				next ← next ∪ {u}
// 			end if
// 		end for
// 	end for

__u32 topDownStepGraphAdjArrayList(struct GraphAdjArrayList* graph, struct ArrayQueue* sharedFrontierQueue){


	
	__u32 v;
	__u32 u;
	__u32 i;
	__u32 j;
	__u32 processed_nodes = sharedFrontierQueue->tail - sharedFrontierQueue->head;
	__u32 mf = 0;
	__u32 out_degree;
	struct Edge* outNodes;

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	for(i = sharedFrontierQueue->head ; i < sharedFrontierQueue->tail; i++){
		v = sharedFrontierQueue->queue[i];
		// v = deArrayQueue(sharedFrontierQueue);
		outNodes = graph->parent_array[v].outNodes;
		out_degree = graph->parent_array[v].out_degree;

    	for(j = 0 ; j < out_degree ; j++){
        
            // destination vertex id
            u = outNodes[j].dest;
            
            // if the destination vertex is not yet enqueued
            // if((graph->parents[u]) == (-1)) { // fixed to implement optemizations
            if((graph->parents[u]) < 0 ){
                
                // add the destination vertex to the queue 
                enArrayQueueDelayed(sharedFrontierQueue, u);
                mf +=  -(graph->parents[u]);
                graph->parents[u] = v;  

            }
        }

	} 

	

	Stop(timer);
	printf("| %-15u | %-15u | %-15f | \n",graph->iteration, processed_nodes, Seconds(timer));
	free(timer);
	return mf;
}

// bottom-up-step(graph, sharedFrontierQueue, next, parents)
// 	for v ∈ vertices do
// 		if parents[v] = -1 then
// 			for u ∈ neighbors[v] do
// 				if u ∈ sharedFrontierQueue then
// 				parents[v] ← u
// 				next ← next ∪ {v}
// 				break
// 				end if
// 			end for
// 		end if
// 	end for

__u32 bottomUpStepGraphAdjArrayList(struct GraphAdjArrayList* graph, struct ArrayQueue* sharedFrontierQueue){


	__u32 v;
	__u32 u;
	__u32 j;
	

	#if DIRECTED
		__u32  in_degree;
		struct Edge* inNodes;
	#else
		__u32 out_degree;
		struct Edge* outNodes;
	#endif

	__u32 processed_nodes = sharedFrontierQueue->tail - sharedFrontierQueue->head;
    __u32 nf = 0; // number of vertices in sharedFrontierQueue

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	for(v=0 ; v < graph->num_vertices ; v++){

    		#if DIRECTED // will look at the other neighbours if directed by using inverese edge list

	    		if(graph->parents[v] < 0){ // optmization

	    			inNodes = graph->parent_array[v].inNodes;
	    			in_degree = graph->parent_array[v].in_degree;

		    		for(j = 0 ; j < in_degree ; j++){

		    			 u = inNodes[j].dest; // this is the inverse if the src is in sharedFrontierQueue let the vertex update.
		    			 // printf("u: %u \n",u );
		    			 if(isEnArrayQueued(sharedFrontierQueue, u)){
		    			 	// printf("***infrontier u: %u \n",u );
		    			 	graph->parents[v] = u;
		    			 	enArrayQueueDelayed(sharedFrontierQueue, v);
		    			 	nf++;
		    			 	break;
		    			 }
		    			 // else
		    			 // printf("***NOT infrontier u: %u \n",u );
		    		}
		    	}
		    	
		    #else
		    	
				if(graph->parents[v] < 0){ // optmization 

					outNodes = graph->parent_array[v].outNodes;
	    			out_degree = graph->parent_array[v].out_degree;

					// printf("edge_idx: %u \n",edge_idx );
					// printf("graph->vertices[v].out_degree: %u \n",graph->vertices[v].out_degree );
		    		for(j = 0 ; j < out_degree ; j++){

		    			 u = outNodes.dest;
		    			 // printf("u: %u \n",u );
		    			 if(isEnArrayQueued(sharedFrontierQueue, u)){
		    			 	// printf("***infrontier u: %u \n",u );
		    			 	graph->parents[v] = u;
		    			 	enArrayQueueDelayed(sharedFrontierQueue, v);
		    			 	nf++;
		    			 	break;
		    			 }
		    			 // else
		    			 // printf("***NOT infrontier u: %u \n",u );
		    		}

		    	}
    		#endif

		
	}


	Stop(timer);
	printf("| %-15u | %-15u | %-15f | \n",graph->iteration, processed_nodes, Seconds(timer));
	free(timer);
	return nf;
}


// breadth-first-search(graph, source)
// 	sharedFrontierQueue ← {source}
// 	next ← {}
// 	parents ← [-1,-1,. . . -1]
// 		while sharedFrontierQueue 6= {} do
// 			top-down-step(graph, sharedFrontierQueue, next, parents)
// 			sharedFrontierQueue ← next
// 			next ← {}
// 		end while
// 	return parents


void breadthFirstSearchGraphAdjLinkedList(__u32 source, struct GraphAdjLinkedList* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct ArrayQueue* sharedFrontierQueue = newArrayQueue(graph->num_vertices);
	
	// enArrayQueueDelayed(sharedFrontierQueue, source);
	// slideWindowArrayQueue(sharedFrontierQueue);

	

	__u32 mu = graph->num_edges; // number of edges to check from sharedFrontierQueue
	__u32 mf = graph->parent_array[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in sharedFrontierQueue
	__u32 nf_prev = 0; // number of vertices in sharedFrontierQueue
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 14;
	__u32 beta = 24;


	enArrayQueue(sharedFrontierQueue, source);
	graph->parents[source] = source;  

	// graph->vertices[source].visited = 1;
	printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
	while(!isEmptyArrayQueue(sharedFrontierQueue)){ // start while 

		if(mf > (mu/alpha)){


			nf = sizeArrayQueue(sharedFrontierQueue);
			// slideWindowArrayQueue(sharedFrontierQueue);
			

			do{

			nf_prev = nf;
			nf = bottomUpStepGraphAdjLinkedList(graph, sharedFrontierQueue);
			slideWindowArrayQueue(sharedFrontierQueue);

		
			}while(( nf > nf_prev) || // growing;
				   ( nf > (n/beta)));
			
			mf = 1;

		}else{
		
			mu -= mf;
			mf = topDownStepGraphAdjLinkedList(graph, sharedFrontierQueue);
			slideWindowArrayQueue(sharedFrontierQueue);

		}


	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","**", sharedFrontierQueue->tail_next, Seconds(timer));
	printf(" -----------------------------------------------------\n");

	resetParentArray(graph->parents, graph->num_vertices);
	freeArrayQueue(sharedFrontierQueue);
	free(timer);
}


// top-down-step(graph, sharedFrontierQueue, next, parents)
// 	for v ∈ sharedFrontierQueue do
// 		for u ∈ neighbors[v] do
// 			if parents[u] = -1 then
// 				parents[u] ← v
// 				next ← next ∪ {u}
// 			end if
// 		end for
// 	end for

__u32 topDownStepGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct ArrayQueue* sharedFrontierQueue){


	
	__u32 v;
	__u32 u;
	__u32 i;
	__u32 j;
	__u32 processed_nodes = sharedFrontierQueue->tail - sharedFrontierQueue->head;
	__u32 mf = 0;
	__u32 out_degree;
	// struct Edge* outNodes;
	struct AdjLinkedListNode* outNodes;

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	for(i = sharedFrontierQueue->head ; i < sharedFrontierQueue->tail; i++){
		v = sharedFrontierQueue->queue[i];
		// v = deArrayQueue(sharedFrontierQueue);

		outNodes = graph->parent_array[v].outNodes;
		out_degree = graph->parent_array[v].out_degree;

    	for(j = 0 ; j < out_degree ; j++){
        
            // destination vertex id
            u = outNodes->dest;
            outNodes = outNodes->next;
            // if the destination vertex is not yet enqueued
            // if((graph->parents[u]) == (-1)) { // fixed to implement optemizations
            if((graph->parents[u]) < 0 ){
                
                // add the destination vertex to the queue 
                enArrayQueueDelayed(sharedFrontierQueue, u);
                mf +=  -(graph->parents[u]);
                graph->parents[u] = v;  

            }
        }

	} 

	

	Stop(timer);
	printf("| %-15u | %-15u | %-15f | \n",graph->iteration, processed_nodes, Seconds(timer));
	free(timer);
	return mf;
}

// bottom-up-step(graph, sharedFrontierQueue, next, parents)
// 	for v ∈ vertices do
// 		if parents[v] = -1 then
// 			for u ∈ neighbors[v] do
// 				if u ∈ sharedFrontierQueue then
// 				parents[v] ← u
// 				next ← next ∪ {v}
// 				break
// 				end if
// 			end for
// 		end if
// 	end for

__u32 bottomUpStepGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct ArrayQueue* sharedFrontierQueue){


	__u32 v;
	__u32 u;
	__u32 j;
	

	#if DIRECTED
		__u32  in_degree;
		struct AdjLinkedListNode* inNodes;
	#else
		__u32 out_degree;
		struct AdjLinkedListNode* outNodes;
	#endif

	__u32 processed_nodes = sharedFrontierQueue->tail - sharedFrontierQueue->head;
    __u32 nf = 0; // number of vertices in sharedFrontierQueue

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	for(v=0 ; v < graph->num_vertices ; v++){

    		#if DIRECTED // will look at the other neighbours if directed by using inverese edge list

	    		if(graph->parents[v] < 0){ // optmization

	    			inNodes = graph->parent_array[v].inNodes;
	    			in_degree = graph->parent_array[v].in_degree;

		    		for(j = 0 ; j < in_degree ; j++){

		    			 u = inNodes->dest; // this is the inverse if the src is in sharedFrontierQueue let the vertex update.
		    			 inNodes = inNodes->next;
		    			 // printf("u: %u \n",u );
		    			 if(isEnArrayQueued(sharedFrontierQueue, u)){
		    			 	// printf("***infrontier u: %u \n",u );
		    			 	graph->parents[v] = u;
		    			 	enArrayQueueDelayed(sharedFrontierQueue, v);
		    			 	nf++;
		    			 	break;
		    			 }
		    			 // else
		    			 // printf("***NOT infrontier u: %u \n",u );
		    		}
		    	}
		    	
		    #else
		    	
				if(graph->parents[v] < 0){ // optmization 

					outNodes = graph->parent_array[v].outNodes;
	    			out_degree = graph->parent_array[v].out_degree;

					// printf("edge_idx: %u \n",edge_idx );
					// printf("graph->vertices[v].out_degree: %u \n",graph->vertices[v].out_degree );
		    		for(j = 0 ; j < out_degree ; j++){

		    			  u = outNodes->dest;
            			 outNodes = outNodes->next;
		    			 // printf("u: %u \n",u );
		    			 if(isEnArrayQueued(sharedFrontierQueue, u)){
		    			 	// printf("***infrontier u: %u \n",u );
		    			 	graph->parents[v] = u;
		    			 	enArrayQueueDelayed(sharedFrontierQueue, v);
		    			 	nf++;
		    			 	break;
		    			 }
		    			 // else
		    			 // printf("***NOT infrontier u: %u \n",u );
		    		}

		    	}
    		#endif

		
	}


	Stop(timer);
	printf("| %-15u | %-15u | %-15f | \n",graph->iteration, processed_nodes, Seconds(timer));
	free(timer);
	return nf;
}
