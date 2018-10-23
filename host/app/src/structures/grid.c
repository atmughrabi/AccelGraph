#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <omp.h>

#include "grid.h"
#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphConfig.h"
#include "bitmap.h"

void gridPrint(struct Grid *grid){


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Grid Properties");
    printf(" -----------------------------------------------------\n");
    #if WEIGHTED       
                printf("| %-51s | \n", "WEIGHTED");
    #else
                printf("| %-51s | \n", "UN-WEIGHTED");
    #endif

    #if DIRECTED
                printf("| %-51s | \n", "DIRECTED");
    #else
                printf("| %-51s | \n", "UN-DIRECTED");
    #endif
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Vertices (V)");
    printf("| %-51u | \n", grid->num_vertices);
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", grid->num_edges);  
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Number of Partitions (P)");
    printf("| %-51u | \n", grid->num_partitions);  
    printf(" -----------------------------------------------------\n");

    // _u32 i;
    //  for ( i = 0; i < grid->num_vertices; ++i)
    //     {

    //         __u32 begin = getPartitionRangeBegin();
    //         __u32 end = getPartitionRangeEnd();



    //     }

  //   __u32 i;
  //    for ( i = 0; i < (grid->num_partitions*grid->num_partitions); ++i)
  //       {

  //       __u32 x = i % grid->num_partitions;    // % is the "modulo operator", the remainder of i / width;
		// __u32 y = i / grid->num_partitions;
	

  //       printf("| %-11s (%u,%u)   | \n", "Partition: ", y, x);
  //  		printf("| %-11s %-40u  | \n", "Edges: ", grid->partitions[i].num_edges);  
  //  		printf("| %-11s %-40u  | \n", "Vertices: ", grid->partitions[i].num_vertices);  
  //  		edgeListPrint(grid->partitions[i].edgeList);
  //       }


}

void   graphGridResetActivePartitions(struct Grid *grid){

    __u32 totalPartitions = 0;
     totalPartitions = grid->num_partitions * grid->num_partitions;
    __u32 i;

    #pragma omp parallel for default(none) shared(grid,totalPartitions) private(i)
    for (i = 0; i < totalPartitions; ++i){
            grid->activePartitions[i] = 0; 
        }



    }

void   graphGridResetActivePartitionsMap(struct Grid *grid){

    clearBitmap(grid->activePartitionsMap);
    
    }

void   graphGridSetActivePartitionsMap(struct Grid *grid, __u32 vertex){

    __u32 row = getPartitionID(grid->num_vertices,grid->num_partitions, vertex);
    __u32 Partition_idx = 0;
    __u32 i;
    __u32 totalPartitions = 0;
     totalPartitions = grid->num_partitions;

    // #pragma omp parallel for default(none) shared(grid,totalPartitions,row) private(i,Partition_idx)

    for ( i = 0; i < totalPartitions; ++i){

        Partition_idx= (row*totalPartitions)+i;

        if(grid->partitions[Partition_idx].edgeList->num_edges){
         if(!getBit(grid->activePartitionsMap,Partition_idx)){
                setBitAtomic(grid->activePartitionsMap,Partition_idx);
            }
        }
        }
    }

void   graphGridSetActivePartitions(struct Grid *grid, __u32 vertex){

    __u32 row = getPartitionID(grid->num_vertices,grid->num_partitions, vertex);
    __u32 Partition_idx = 0;
    __u32 i;
    __u32 totalPartitions = 0;
     totalPartitions = grid->num_partitions;

    // #pragma omp parallel for default(none) shared(grid,totalPartitions,row) private(i,Partition_idx)
    for ( i = 0; i < totalPartitions; ++i){

        Partition_idx= (row*totalPartitions)+i;
        if(grid->partitions[Partition_idx].edgeList->num_edges){
                grid->activePartitions[Partition_idx] = 1;
            }
        }
    }



struct Grid * gridNew(struct EdgeList* edgeList){

	
	__u32 totalPartitions = 0;

	#if ALIGNED
		struct Grid* grid = (struct Grid*) my_aligned_malloc(sizeof(struct Grid));
	#else
        struct Grid* grid = (struct Grid*) my_malloc( sizeof(struct Grid));
    #endif

    grid->num_edges = edgeList->num_edges;
    grid->num_vertices = edgeList->num_vertices;
    grid->num_partitions = gridCalculatePartitions(edgeList);
    totalPartitions = grid->num_partitions * grid->num_partitions;

    #if ALIGNED
		grid->partitions = (struct Partition*) my_aligned_malloc(totalPartitions * sizeof(struct Partition));
	#else
        grid->partitions = (struct Partition*) my_malloc(totalPartitions * sizeof(struct Partition));
    #endif

    #if ALIGNED
        grid->activePartitions = (__u32*) my_aligned_malloc(totalPartitions * sizeof(__u32));
    #else
        grid->activePartitions = (__u32*) my_malloc(totalPartitions * sizeof(__u32));
    #endif

    #if ALIGNED
        grid->out_degree = (__u32*) my_aligned_malloc(grid->num_vertices * sizeof(__u32));
    #else
        grid->out_degree = (__u32*) my_malloc(grid->num_vertices * sizeof(__u32));
    #endif

    #if ALIGNED
        grid->in_degree = (__u32*) my_aligned_malloc(grid->num_vertices * sizeof(__u32));
    #else
        grid->in_degree = (__u32*) my_malloc(grid->num_vertices * sizeof(__u32));
    #endif

        // grid->activeVertices = newBitmap(grid->num_vertices);
        grid->activePartitionsMap = newBitmap(totalPartitions);

        __u32 i;
        #pragma omp parallel for default(none) private(i) shared(totalPartitions,grid)
        for (i = 0; i < totalPartitions; ++i)
        {

		 grid->partitions[i].num_edges = 0;
		 grid->partitions[i].num_vertices = 0;	/* code */
         grid->activePartitions[i] = 0;
        
        
        }


        #pragma omp parallel for default(none) private(i) shared(grid)
        for (i = 0; i < grid->num_vertices ; ++i)
        {

        grid->out_degree[i] = 0;
        grid->in_degree[i] = 0;
        
        }


      

    grid = gridPartitionSizePreprocessing(grid, edgeList);
    grid = gridPartitionsMemoryAllocations(grid);
    grid = gridPartitionEdgePopulation(grid, edgeList);

    return grid;
}



void  gridFree(struct Grid *grid){
	__u32 totalPartitions = grid->num_partitions * grid->num_partitions;
	__u32 i;

	for (i = 0; i < totalPartitions; ++i){

           freeEdgeList(grid->partitions[i].edgeList);
	}

    freeBitmap(grid->activePartitionsMap);
    free(grid->activePartitions);
    free(grid->out_degree);
    free(grid->in_degree);
	free(grid->partitions);
	free(grid);

}

struct Grid * gridPartitionSizePreprocessing(struct Grid *grid, struct EdgeList* edgeList){

	__u32 i;
	__u32 src;
	__u32 dest;
    __u32 Partition_idx;

	__u32 num_partitions = grid->num_partitions;
	__u32 num_vertices = grid->num_vertices;


	__u32 row;
	__u32 col;

    omp_lock_t lock[num_partitions*num_partitions];

    #pragma omp parallel for
    for (i=0; i<num_partitions*num_partitions; i++){
        omp_init_lock(&(lock[i]));
    }


    #pragma omp parallel for default(none) private(i,row,col,src,dest,Partition_idx) shared(lock,num_vertices, num_partitions,edgeList,grid)
	for(i = 0; i < edgeList->num_edges; i++){

		src  = edgeList->edges_array[i].src;
		dest = edgeList->edges_array[i].dest;

        #pragma omp atomic update
            grid->out_degree[src]++;

        #pragma omp atomic update
            grid->in_degree[dest]++;

        // __sync_fetch_and_add(&grid->out_degree[src],1);
        // __sync_fetch_and_add(&grid->in_degree[dest],1);

		row = getPartitionID(num_vertices, num_partitions, src);
		col = getPartitionID(num_vertices, num_partitions, dest);
        Partition_idx= (row*num_partitions)+col;


        // __sync_fetch_and_add(&grid->partitions[Partition_idx].num_edges,1);
        
        omp_set_lock(&(lock[Partition_idx]));
        {
    		grid->partitions[Partition_idx].num_edges++;
    		grid->partitions[Partition_idx].num_vertices = maxTwoIntegers(grid->partitions[Partition_idx].num_vertices,maxTwoIntegers(src, dest));
        }
        omp_unset_lock((&lock[Partition_idx]));

	}


    #pragma omp parallel for
    for (i=0; i<num_partitions*num_partitions; i++){
        omp_destroy_lock(&(lock[i]));
    }

	return grid;


}


struct Grid * gridPartitionEdgePopulation(struct Grid *grid, struct EdgeList* edgeList){

	__u32 i;
	__u32 src;
	__u32 dest;
	__u32 Partition_idx;

	__u32 num_partitions = grid->num_partitions;
	__u32 num_vertices = grid->num_vertices;

	__u32 row;
	__u32 col;

    omp_lock_t lock[num_partitions*num_partitions];

    #pragma omp parallel for
    for (i=0; i<num_partitions*num_partitions; i++){
        omp_init_lock(&(lock[i]));
    }


    #pragma omp parallel for default(none) private(i,row,col,src,dest,Partition_idx) shared(lock,num_vertices, num_partitions,edgeList,grid)
	for(i = 0; i < edgeList->num_edges; i++){


		src  = edgeList->edges_array[i].src;
		dest = edgeList->edges_array[i].dest;
		row = getPartitionID(num_vertices, num_partitions, src);
		col = getPartitionID(num_vertices, num_partitions, dest);
		Partition_idx= (row*num_partitions)+col;

        omp_set_lock(&(lock[Partition_idx]));
        {
		grid->partitions[Partition_idx].edgeList->edges_array[grid->partitions[Partition_idx].num_edges] = edgeList->edges_array[i];
		grid->partitions[Partition_idx].num_edges++;  
        }
        omp_unset_lock((&lock[Partition_idx]));
	
    }


    #pragma omp parallel for
    for (i=0; i<num_partitions*num_partitions; i++){
        omp_destroy_lock(&(lock[i]));
    }

	return grid;

}


struct Grid * gridPartitionsMemoryAllocations(struct Grid *grid){

	__u32 i;
	__u32 totalPartitions = grid->num_partitions*grid->num_partitions;
	
    #pragma omp parallel for default(none) private(i) shared(totalPartitions,grid)
	 for ( i = 0; i < totalPartitions; ++i)
        {

            grid->partitions[i].edgeList = newEdgeList(grid->partitions[i].num_edges);
            grid->partitions[i].edgeList->num_vertices = grid->partitions[i].num_vertices;
            grid->partitions[i].num_edges = 0;

        }

	return grid;


}

__u32 gridCalculatePartitions(struct EdgeList* edgeList){
	//epfl everything graph
	__u32 num_vertices  = edgeList->num_vertices;
	__u32 num_Paritions = (num_vertices * 8 / 1024) / 20;
	if(num_Paritions > 1000) 
		num_Paritions = 256;
	if(num_Paritions == 0 ) 
		num_Paritions = 4;

	return num_Paritions;

}



inline __u32 getPartitionID(__u32 vertices, __u32 partitions, __u32 vertex_id) {
        
        __u32 partition_size = vertices / partitions;

        if (vertices % partitions == 0) {

                return vertex_id / partition_size;
        }

        partition_size += 1;

        __u32 split_point = vertices % partitions * partition_size;

        return (vertex_id < split_point) ? vertex_id / partition_size : (vertex_id - split_point) / (partition_size - 1) + (vertices % partitions);
}

__u32 getPartitionRangeBegin(__u32 vertices, __u32 partitions, __u32 partition_id) {
        
        __u32 split_partition = vertices % partitions;
        __u32 partition_size = vertices / partitions + 1;

        if (partition_id < split_partition) {
				__u32 begin = partition_id * partition_size;
				return begin;
        }
        __u32 split_point = split_partition * partition_size;
        __u32 begin = split_point + (partition_id - split_partition) * (partition_size - 1);
  
        return begin;
}

__u32 getPartitionRangeEnd(__u32 vertices, __u32 partitions, __u32 partition_id) {
        
        __u32 split_partition = vertices % partitions;
        __u32 partition_size = vertices / partitions + 1;

        if (partition_id < split_partition) {
                 __u32 end = (partition_id + 1) * partition_size;
                return  end;
        }
        __u32 split_point = split_partition * partition_size;
        __u32 end = split_point + (partition_id - split_partition + 1) * (partition_size - 1);

        return  end;
}