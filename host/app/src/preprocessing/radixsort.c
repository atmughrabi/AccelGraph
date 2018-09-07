#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <omp.h>

#include "radixsort.h"
#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphConfig.h"
#include "timer.h"

// A function to do counting sort of edgeList according to
// the digit represented by exp
// The parallel version has the following pseudo code
// parallel_for part in 0..K-1
//   for i in indexes(part)
//     bucket = compute_bucket(a[i])
//     Cnt[part][bucket]++

// base = 0
// for bucket in 0..R-1
//   for part in 0..K-1
//     Cnt[part][bucket] += base
//     base = Cnt[part][bucket]

// parallel_for part in 0..K-1
//   for i in indexes(part)
//     bucket = compute_bucket(a[i])
//     out[Cnt[part][bucket]++] = a[i]
void radixSortCountSortEdgesBySource (struct Edge** sorted_edges_array, struct EdgeList* edgeList, __u32 radix, __u32 buckets, __u32* buckets_count){

	struct Edge* temp_edges_array = NULL; 
    __u32 num_edges = edgeList->num_edges;
    __u32 t = 0;
    __u32 o = 0;
    __u32 u = 0;
    __u32 i = 0;
    __u32 j = 0;
    __u32 P = numThreads;  // 32/8 8 bit radix needs 4 iterations
    __u32 t_id = 0;
    __u32 offset_start = 0;
    __u32 offset_end = 0;
    __u32 base = 0;

    #pragma omp parallel default(none) shared(sorted_edges_array,edgeList,radix,buckets,buckets_count,num_edges) firstprivate(t_id, P, offset_end,offset_start,base,i,j,t,u,o) 
    {
        P = omp_get_num_threads();
        t_id = omp_get_thread_num();
        offset_start = t_id*(num_edges/P);


        if(t_id == (P-1)){
            offset_end = offset_start+(num_edges/P) + (num_edges%P) ;
        }
        else{
            offset_end = offset_start+(num_edges/P);
        }
        

        //HISTOGRAM-KEYS 
        for(i=0; i < buckets; i++){ 
            buckets_count[(t_id*buckets)+i] = 0;
        }

       
        for (i = offset_start; i < offset_end; i++) {      
            u = edgeList->edges_array[i].src;
            t = (u >> (radix*8)) & 0xff;
            buckets_count[(t_id*buckets)+t]++;
        }


        #pragma omp barrier


        //SCAN BUCKETS
        if(t_id == 0){

        for(i=0; i < buckets; i++){
             for(j=0 ; j < P; j++){
             t = buckets_count[(j*buckets)+i];
             buckets_count[(j*buckets)+i] = base;
             base += t;
         }
        }

        }

        #pragma omp barrier

        //RANK-AND-PERMUTE
        for (i = offset_start; i < offset_end; i++) {       /* radix sort */
            u = edgeList->edges_array[i].src;
            t = (u >> (radix*8)) & 0xff;
            o = buckets_count[(t_id*buckets)+t];
            (*sorted_edges_array)[o] = edgeList->edges_array[i];
            buckets_count[(t_id*buckets)+t]++;

        }

    }

    temp_edges_array = *sorted_edges_array;
    *sorted_edges_array = edgeList->edges_array;
    edgeList->edges_array = temp_edges_array;
    
}

// This algorithm coded in accordance to Zagha et al paper 1991

struct EdgeList* radixSortEdgesBySource (struct EdgeList* edgeList){

	    // printf("*** START Radix Sort Edges By Source *** \n");

    // struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

    __u32 radix = 4;  // 32/8 8 bit radix needs 4 iterations
    __u32 P = numThreads;  // 32/8 8 bit radix needs 4 iterations
    __u32 buckets = 256; // 2^radix = 256 buckets
    __u32 num_edges = edgeList->num_edges;
    __u32* buckets_count = NULL;

    omp_set_num_threads(P);
   
    __u32 j = 0; //1,2,3 iteration

    struct Edge* sorted_edges_array = newEdgeArray(num_edges);

    #if ALIGNED
        buckets_count = (__u32*) my_aligned_alloc(P * buckets * sizeof(__u32));
    #else
        buckets_count = (__u32*) my_malloc(P * buckets * sizeof(__u32));
    #endif

    for(j=0 ; j < radix ; j++){
        radixSortCountSortEdgesBySource (&sorted_edges_array, edgeList, j, buckets, buckets_count);
    }

    free(buckets_count);
    free(sorted_edges_array);

    return edgeList;

}



struct EdgeList* radixSortEdgesBySourceAndDestination (struct EdgeList* edgeList){

	// printf("*** START Radix Sort Edges By Source And Destination *** \n");

	// struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

	__u32 count = edgeList->num_edges;
	__u32 mIndex[8][256] = { 0 };
	__u32 * pmIndex;
	__u32 i, j, m, n;
	__u32 u;


    struct Edge* sorted_edges_array = newEdgeArray(count);


	 for (i = 0; i < count; i++) {       /* generate histograms */
		u = edgeList->edges_array[i].dest;
        mIndex[7][(u >> 0)  & 0xff]++;
        mIndex[6][(u >> 8)  & 0xff]++;
        mIndex[5][(u >> 16) & 0xff]++;
        mIndex[4][(u >> 24) & 0xff]++;

        u = edgeList->edges_array[i].src;
        mIndex[3][(u >> 0)  & 0xff]++;
        mIndex[2][(u >> 8)  & 0xff]++;
        mIndex[1][(u >> 16) & 0xff]++;
        mIndex[0][(u >> 24) & 0xff]++;



    }

    for (j = 0; j < 4; j++) {           /* convert to indices generate prefixsum */
        pmIndex = mIndex[j];
        n = 0;
        for (i = 0; i < 256; i++) {
            m = pmIndex[i];
            pmIndex[i] = n;
            n += m;
        }
    }

     for (j = 4; j < 8; j++) {           /* convert to indices generate prefixsum */
        pmIndex = mIndex[j];
        n = 0;
        for (i = 0; i < 256; i++) {
            m = pmIndex[i];
            pmIndex[i] = n;
            n += m;
        }
    }

     for (i = 0; i < count; i++) {       /* radix sort */
        u = edgeList->edges_array[i].dest;
        sorted_edges_array[mIndex[7][(u >> 0) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].dest;
        edgeList->edges_array[mIndex[6][(u >> 8) & 0xff]++] = sorted_edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = edgeList->edges_array[i].dest;
        sorted_edges_array[mIndex[5][(u >> 16) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].dest;
        edgeList->edges_array[mIndex[4][(u >> 24) & 0xff]++] = sorted_edges_array[i];
    }

    for (i = 0; i < count; i++) {       /* radix sort */
        u = edgeList->edges_array[i].src;
        sorted_edges_array[mIndex[3][(u >> 0) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[2][(u >> 8) & 0xff]++] = sorted_edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = edgeList->edges_array[i].src;
        sorted_edges_array[mIndex[1][(u >> 16) & 0xff]++] = edgeList->edges_array[i];
    }
    for (i = 0; i < count; i++) {
        u = sorted_edges_array[i].src;
        edgeList->edges_array[mIndex[0][(u >> 24) & 0xff]++] = sorted_edges_array[i];
    }

    freeEdgeArray(sorted_edges_array);

	return edgeList;
}




struct EdgeList* radixSortEdgesBySourceOptimizedParallel (struct EdgeList* edgeList){
	// printf("*** START Radix Sort Edges By Source *** \n");

	// struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

	__u32 radix = 4;  // 32/8 8 bit radix needs 4 iterations
	__u32 buckets = 256; // 2^radix = 256 buckets
	__u32 num_edges = edgeList->num_edges;
    __u32* vertex_count = NULL;


	__u32 t4 = 0, t3 = 0, t2 = 0, t1 = 0;
	__u32 o4 = 0, o3 = 0, o2 = 0, o1 = 0;
	__u32 u = 0;
	__u32 i = 0;


    struct Edge* sorted_edges_array = newEdgeArray(num_edges);

	#if ALIGNED
		vertex_count = (__u32*) my_aligned_alloc( radix * buckets * sizeof(__u32));
	#else
        vertex_count = (__u32*) my_malloc( radix * buckets * sizeof(__u32));
    #endif

    // omp_set_dynamic(0);     // Explicitly disable dynamic teams
    omp_set_num_threads(numThreads);

    printf("numthreads %d\n", numThreads);

    // #pragma omp parallel for default(none) private (x,i) shared(step,num_steps) reduction (+:sum)

    #pragma omp parallel for default(none) private(i) shared(radix,buckets,vertex_count)
    for(i=0; i < (radix * buckets); i++){

        vertex_count[i] = 0;

    }

     #pragma omp parallel for default(none) private(i,t4,t3,t2,t1,u) shared(edgeList,buckets,num_edges) reduction(+:vertex_count[:radix * buckets])
	 for (i = 0; i < num_edges; i++) {       /* generate histograms */
        u = edgeList->edges_array[i].src;
        t4 = (u >> 0)  & 0xff;
        t3 = (u >> 8)  & 0xff;
        t2 = (u >> 16) & 0xff;
        t1 = (u >> 24) & 0xff;
        vertex_count[3*buckets + t4]++;
        vertex_count[2*buckets + t3]++;
        vertex_count[1*buckets + t2]++;
        vertex_count[0*buckets + t1]++;

    }


    // #pragma omp parallel for default(none) private(i) firstprivate(t4,t3,t2,t1,o1,o2,o3,o4) shared(edgeList,buckets,vertex_count)
    for(i=0; i< buckets; i++){ /* convert to indices generate prefixsum */

    	t4 = o4 + vertex_count[3*buckets + i];
        t3 = o3 + vertex_count[2*buckets + i];
        t2 = o2 + vertex_count[1*buckets + i];
        t1 = o1 + vertex_count[0*buckets + i];

        vertex_count[3*buckets + i] = o4;
        vertex_count[2*buckets + i] = o3;
        vertex_count[1*buckets + i] = o2;
        vertex_count[0*buckets + i] = o1;

        o4 = t4;
        o3 = t3;
        o2 = t2;
        o1 = t1;
    }

  

    
    for (i = 0; i < num_edges; i++) {       /* radix sort */
        u = edgeList->edges_array[i].src;
        t4 = (u >> 0)  & 0xff;
            sorted_edges_array[vertex_count[3*buckets + t4]] = edgeList->edges_array[i];
            vertex_count[3*buckets + t4]++;
        
    }

    
    for (i = 0; i < num_edges; i++) {
        u = sorted_edges_array[i].src;
        t3 = (u >> 8)  & 0xff;
        edgeList->edges_array[vertex_count[2*buckets + t3]] = sorted_edges_array[i];
        vertex_count[2*buckets + t3]++;
    }
 
   
    for (i = 0; i < num_edges; i++) {
        u = edgeList->edges_array[i].src;
        t2 = (u >> 16) & 0xff;
        sorted_edges_array[vertex_count[1*buckets + t2]] = edgeList->edges_array[i];
        vertex_count[1*buckets + t2]++;
    }


    for (i = 0; i < num_edges; i++) {
        u = sorted_edges_array[i].src;
        t1 = (u >> 24) & 0xff;
        edgeList->edges_array[vertex_count[0*buckets + t1]] = sorted_edges_array[i];
        vertex_count[0*buckets + t1]++;
    }


    


    free(vertex_count);
	freeEdgeArray(sorted_edges_array);

	return edgeList;

} 

struct EdgeList* radixSortEdgesBySourceOptimized (struct EdgeList* edgeList){

    // printf("*** START Radix Sort Edges By Source *** \n");

    // struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number

    __u32 radix = 4;  // 32/8 8 bit radix needs 4 iterations
    __u32 buckets = 256; // 2^radix = 256 buckets
    __u32 num_edges = edgeList->num_edges;
    __u32* vertex_count = NULL;


    __u32 t4 = 0, t3 = 0, t2 = 0, t1 = 0;
    __u32 o4 = 0, o3 = 0, o2 = 0, o1 = 0;
    __u32 u = 0;
    __u32 i = 0;


    struct Edge* sorted_edges_array = newEdgeArray(num_edges);

    #if ALIGNED
        vertex_count = (__u32*) my_aligned_alloc( radix * buckets * sizeof(__u32));
    #else
        vertex_count = (__u32*) my_malloc( radix * buckets * sizeof(__u32));
    #endif

    for(i=0; i < (radix * buckets); i++){

        vertex_count[i] = 0;

    }


     for (i = 0; i < num_edges; i++) {       /* generate histograms */
        u = edgeList->edges_array[i].src;
        t4 = (u >> 0)  & 0xff;
        t3 = (u >> 8)  & 0xff;
        t2 = (u >> 16) & 0xff;
        t1 = (u >> 24) & 0xff;
        vertex_count[3*buckets + t4]++;
        vertex_count[2*buckets + t3]++;
        vertex_count[1*buckets + t2]++;
        vertex_count[0*buckets + t1]++;

    }


    for(i=0; i< buckets; i++){ /* convert to indices generate prefixsum */

        t4 = o4 + vertex_count[3*buckets + i];
        t3 = o3 + vertex_count[2*buckets + i];
        t2 = o2 + vertex_count[1*buckets + i];
        t1 = o1 + vertex_count[0*buckets + i];

        vertex_count[3*buckets + i] = o4;
        vertex_count[2*buckets + i] = o3;
        vertex_count[1*buckets + i] = o2;
        vertex_count[0*buckets + i] = o1;

        o4 = t4;
        o3 = t3;
        o2 = t2;
        o1 = t1;
    }


    for (i = 0; i < num_edges; i++) {       /* radix sort */
        u = edgeList->edges_array[i].src;
        t4 = (u >> 0)  & 0xff;
        sorted_edges_array[vertex_count[3*buckets + t4]++] = edgeList->edges_array[i];
    }

    for (i = 0; i < num_edges; i++) {
        u = sorted_edges_array[i].src;
        t3 = (u >> 8)  & 0xff;
        edgeList->edges_array[vertex_count[2*buckets + t3]++] = sorted_edges_array[i];
    }

    for (i = 0; i < num_edges; i++) {
        u = edgeList->edges_array[i].src;
        t2 = (u >> 16) & 0xff;
        sorted_edges_array[vertex_count[1*buckets + t2]++] = edgeList->edges_array[i];
    }

    for (i = 0; i < num_edges; i++) {
        u = sorted_edges_array[i].src;
        t1 = (u >> 24) & 0xff;
        edgeList->edges_array[vertex_count[0*buckets + t1]++] = sorted_edges_array[i];
    }



    free(vertex_count);
    freeEdgeArray(sorted_edges_array);

    return edgeList;

} 



