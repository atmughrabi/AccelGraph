#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "timer.h"
#include "mymalloc.h"
#include "boolean.h"
#include "arrayqueue.h"
#include "BFS.h"
#include "vertex.h"



void bfs(__u32 source, struct Graph* graph){


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
        	
        	printf("| %-15u | %-15u | %-15f | \n",iteration, discovered_nodes_Iter_1, Seconds(timer));
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

}



// breadth-first-search(graph, source)
// 	frontier ← {source}
// 	next ← {}
// 	parents ← [-1,-1,. . . -1]
// 		while frontier 6= {} do
// 			top-down-step(graph, frontier, next, parents)
// 			frontier ← next
// 			next ← {}
// 		end while
// 	return parents

void breadthFirstSearch(__u32 source, struct Graph* graph){

	
	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	struct ArrayQueue* frontier = newArrayQueue(graph->num_vertices);
	
	// enArrayQueueDelayed(frontier, source);
	// slideWindowArrayQueue(frontier);

	

	__u32 mu = graph->num_edges; // number of edges to check from frontier
	__u32 mf = graph->vertices[source].out_degree; // number of edges from unexplored verticies
	__u32 nf = 0; // number of vertices in frontier
	__u32 nf_prev = 0; // number of vertices in frontier
	__u32 n = graph->num_vertices; // number of nodes
	__u32 alpha = 15;
	__u32 beta = 18;


	enArrayQueue(frontier, source);
	graph->parents[source] = source;  

	// graph->vertices[source].visited = 1;
	printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
	while(!isEmptyArrayQueue(frontier)){ // start while 

		if(mf > (mu/alpha)){


			nf = sizeArrayQueue(frontier);
			// slideWindowArrayQueue(frontier);
			

			do{

			nf_prev = nf;
			nf = bottomUpStep(graph, frontier);
			slideWindowArrayQueue(frontier);

		
			}while(( nf > nf_prev) || // growing;
				   ( nf > (n/beta)));
			
			mf = 1;

		}else{
		
			mu -= mf;
			mf = topDownStep(graph, frontier);
			slideWindowArrayQueue(frontier);

		}


	} // end while
	Stop(timer);
	printf(" -----------------------------------------------------\n");
	printf("| %-15s | %-15u | %-15f | \n","**", frontier->tail_next, Seconds(timer));
	printf(" -----------------------------------------------------\n");
}


// top-down-step(graph, frontier, next, parents)
// 	for v ∈ frontier do
// 		for u ∈ neighbors[v] do
// 			if parents[u] = -1 then
// 				parents[u] ← v
// 				next ← next ∪ {u}
// 			end if
// 		end for
// 	end for

__u32 topDownStep(struct Graph* graph, struct ArrayQueue* frontier){


	
	__u32 v;
	__u32 u;
	__u32 i;
	__u32 j;
	__u32 edge_idx;
	__u32 processed_nodes = frontier->tail - frontier->head;
	__u32 mf = 0;

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	for(i = frontier->head ; i < frontier->tail; i++){
		v = frontier->queue[i];
		// v = deArrayQueue(frontier);
		edge_idx = graph->vertices[v].edges_idx;

    	for(j = edge_idx ; j < (edge_idx + graph->vertices[v].out_degree) ; j++){
        
            // destination vertex id
            u = graph->sorted_edges_array[j].dest;
            
            // if the destination vertex is not yet enqueued
            // if((graph->parents[u]) == (-1)) { // fixed to implement optemizations
            if((graph->parents[u]) < 0 ){
                
                // add the destination vertex to the queue 
                enArrayQueueDelayed(frontier, u);
                mf +=  -(graph->parents[u]);
                graph->parents[u] = v;  

            }
        }

	} 

	

	Stop(timer);
	printf("| %-15u | %-15u | %-15f | \n",frontier->iteration, processed_nodes, Seconds(timer));

	return mf;
}

// bottom-up-step(graph, frontier, next, parents)
// 	for v ∈ vertices do
// 		if parents[v] = -1 then
// 			for u ∈ neighbors[v] do
// 				if u ∈ frontier then
// 				parents[v] ← u
// 				next ← next ∪ {v}
// 				break
// 				end if
// 			end for
// 		end if
// 	end for

__u32 bottomUpStep(struct Graph* graph, struct ArrayQueue* frontier){


	__u32 v;
	__u32 u;
	__u32 j;
	

	#if DIRECTED
		__u32 out_degree_inverse;
		__u32 edge_idx_inverse;
	#else
		__u32 edge_idx;
		__u32 out_degree;
	#endif

	__u32 processed_nodes = frontier->tail - frontier->head;
    __u32 nf = 0; // number of vertices in frontier

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);

	for(v=0 ; v < graph->num_vertices ; v++){

    		#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
	    		out_degree_inverse = graph->inverse_vertices[v].out_degree;

	    		if(graph->parents[v] < 0){ // optmization

	    			edge_idx_inverse = graph->inverse_vertices[v].edges_idx;

		    		for(j = edge_idx_inverse ; j < (edge_idx_inverse + out_degree_inverse) ; j++){

		    			 u = graph->inverse_sorted_edges_array[j].dest;
		    			 // printf("u: %u \n",u );
		    			 if(isEnArrayQueued(frontier, u)){
		    			 	// printf("***infrontier u: %u \n",u );
		    			 	graph->parents[v] = u;
		    			 	enArrayQueueDelayed(frontier, v);
		    			 	nf++;
		    			 	break;
		    			 }
		    			 // else
		    			 // printf("***NOT infrontier u: %u \n",u );
		    		}
		    	}
		    	
		    #else
		    	// printf("\n v: %u \n",v );
				// if(graph->parents[v] == (-1)){
				// out_degree = -(graph->parents[v]);
				out_degree = graph->vertices[v].out_degree;

				if(graph->parents[v] < 0){ // optmization 
					edge_idx = graph->vertices[v].edges_idx;

					// printf("edge_idx: %u \n",edge_idx );
					// printf("graph->vertices[v].out_degree: %u \n",graph->vertices[v].out_degree );
		    		for(j = edge_idx ; j < (edge_idx + out_degree) ; j++){
		    			 u = graph->sorted_edges_array[j].dest;
		    			 // printf("u: %u \n",u );
		    			 if(isEnArrayQueued(frontier, u)){
		    			 	// printf("***infrontier u: %u \n",u );
		    			 	graph->parents[v] = u;
		    			 	enArrayQueueDelayed(frontier, v);
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
	printf("| %-15u | %-15u | %-15f | \n",frontier->iteration, processed_nodes, Seconds(timer));

	return nf;
}


void topDownStep_original(struct Graph* graph, struct ArrayQueue* frontier){

	__u32 v;
	__u32 u;
	// __u32 i;
	__u32 edge_idx;
	__u32 processed_nodes = frontier->tail - frontier->head;

	// for(i = frontier->head ; i < frontier->tail; i++){

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
	Start(timer);
	while(!isEmptyArrayQueueCurr(frontier)){
		// v = frontier->queue[i];
		v = deArrayQueue(frontier);
		edge_idx = graph->vertices[v].edges_idx;

        if(edge_idx == NO_OUTGOING_EDGES) {
            continue;
        }

        while(graph->sorted_edges_array[edge_idx].src == v) {
            
            // destination vertex id
            u = graph->sorted_edges_array[edge_idx].dest;
            
            // if the destination vertex is not yet enqueued
            // if(!isEnArrayQueued(frontier, u)) {
            if((graph->parents[u]) < 0 ){                
                // add the destination vertex to the queue 
                enArrayQueueDelayed(frontier, u);
                // graph->vertices[u].visited = 1;
                 graph->parents[u] = v;
               
            }

            edge_idx++;
        }

	} 
	Stop(timer);
	printf("| %-15u | %-15u | %-15f | \n",frontier->iteration, processed_nodes, Seconds(timer));
}



